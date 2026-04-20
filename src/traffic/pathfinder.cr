module Traffic
  class Pathfinder
    def self.find_path(start_node : Node, target_node : Node) : Array(Node)
      # A* implementation
      open_set = [start_node]
      came_from = {} of Node => Node

      g_score = Hash(Node, Float32).new(Float32::INFINITY)
      g_score[start_node] = 0.0_f32

      f_score = Hash(Node, Float32).new(Float32::INFINITY)
      f_score[start_node] = heuristic(start_node, target_node)

      while !open_set.empty?
        # Sort to get the one with lowest f_score (manual priority queue)
        open_set.sort_by! { |node| f_score[node] }
        current = open_set.shift

        return reconstruct_path(came_from, current) if current == target_node

        current.connections.each do |neighbor|
          tentative_g_score = g_score[current] + current.distance_to(neighbor)

          if tentative_g_score < g_score[neighbor]
            came_from[neighbor] = current
            g_score[neighbor] = tentative_g_score
            f_score[neighbor] = g_score[neighbor] + heuristic(neighbor, target_node)
            open_set << neighbor unless open_set.includes?(neighbor)
          end
        end
      end

      [] of Node # No path found
    end

    private def self.heuristic(a : Node, b : Node) : Float32
      a.distance_to(b)
    end

    private def self.reconstruct_path(came_from : Hash(Node, Node), current : Node) : Array(Node)
      path = [current]
      while came_from.has_key?(current)
        current = came_from[current]
        path.unshift(current)
      end
      path
    end
  end
end
