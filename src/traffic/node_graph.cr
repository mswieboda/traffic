module Traffic
  enum NodeType
    Intersection
    Exit
    TargetAmbulance
    TargetPolice
    TargetVIP
  end

  class Node
    property x : Float32
    property y : Float32
    property type : NodeType
    property connections = Array(Node).new

    def initialize(@x, @y, @type)
    end

    def distance_to(other : Node)
      distance_to(other.x, other.y)
    end

    def distance_to(ox : Float32, oy : Float32)
      Math.sqrt((@x - ox)**2 + (@y - oy)**2)
    end
  end

  class NodeGraph
    property nodes = Array(Node).new

    def build(map : GSDL::TileMap, intersections : Array(Intersection))
      @nodes.clear

      # 1. Add Intersection Nodes
      intersections.each do |inter|
        # Center of intersection (2x2 tiles)
        @nodes << Node.new(inter.x + TileSize, inter.y + TileSize, NodeType::Intersection)
      end

      # 2. Add Target Nodes from Object Layer
      map.layers.each do |layer|
        if layer.is_a?(GSDL::ObjectGroup)
          layer.objects.each do |obj|
            type = case obj.type
                   when "TargetAmbulance" then NodeType::TargetAmbulance
                   when "TargetPolice"    then NodeType::TargetPolice
                   when "TargetVIP"       then NodeType::TargetVIP
                   else next
                   end
            @nodes << Node.new(obj.x, obj.y, type)
          end
        end
      end

      # 3. Add Exit Nodes at Map Edges
      # North/South
      (0...map.map_width_tiles).each do |tx|
        if is_road?(map, tx, 0)
          @nodes << Node.new(tx * TileSize + (TileSize / 2), -TileSize, NodeType::Exit)
        end
        if is_road?(map, tx, map.map_height_tiles - 1)
          @nodes << Node.new(tx * TileSize + (TileSize / 2), map.height + TileSize, NodeType::Exit)
        end
      end
      # East/West
      (0...map.map_height_tiles).each do |ty|
        if is_road?(map, 0, ty)
          @nodes << Node.new(-TileSize, ty * TileSize + (TileSize / 2), NodeType::Exit)
        end
        if is_road?(map, map.map_width_tiles - 1, ty)
          @nodes << Node.new(map.width + TileSize, ty * TileSize + (TileSize / 2), NodeType::Exit)
        end
      end

      puts "NodeGraph: Built #{@nodes.size} nodes."

      # 4. Connect Nodes
      conn_count = 0
      @nodes.each do |node_a|
        @nodes.each do |node_b|
          next if node_a == node_b
          next if node_a.connections.includes?(node_b)

          if connected_by_road?(map, node_a, node_b)
            node_a.connections << node_b
            node_b.connections << node_a # Assuming two-way roads for now
            conn_count += 1
          end
        end
      end
      puts "NodeGraph: Created #{conn_count} connections."
    end

    private def is_road?(map, tx, ty)
      tile = map.tile_at(tx, ty)
      return false unless tile
      gid = tile.local_tile_id + 1 # Tileset gid
      # Based on tiles.png: 1,2 (H road), 3,4 (V road), 5-16 (Intersections)
      gid >= 1 && gid <= 16
    end

    private def connected_by_road?(map, a, b)
      # Check if aligned
      dx = (a.x - b.x).abs
      dy = (a.y - b.y).abs
      # Lenient threshold to handle 2-tile wide roads and offsets
      threshold = TileSize + 2.0_f32

      if dx < threshold
        # Vertical connection
        min_y = Math.min(a.y, b.y)
        max_y = Math.max(a.y, b.y)
        # Scan along Y
        y = min_y + TileSize
        while y < max_y
          return false unless is_road_at?(map, a.x, y)
          y += TileSize
        end
        return true
      elsif dy < threshold
        # Horizontal connection
        min_x = Math.min(a.x, b.x)
        max_x = Math.max(a.x, b.x)
        # Scan along X
        x = min_x + TileSize
        while x < max_x
          return false unless is_road_at?(map, x, a.y)
          x += TileSize
        end
        return true
      end

      false
    end

    private def is_road_at?(map, x, y)
      tx = (x // TileSize).to_i
      ty = (y // TileSize).to_i
      is_road?(map, tx, ty)
    end
  end
end
