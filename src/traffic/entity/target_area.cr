module Traffic
  class TargetArea < GSDL::Entity
    property type : NodeType

    def initialize(@type, x : Float32, y : Float32, ox : Float32 = 0.0_f32, oy : Float32 = 0.0_f32)
      @x = x
      @y = y
      @origin = {0.5_f32, 0.5_f32}
      
      asset = case @type
              when .target_ambulance? then "hospital"
              when .target_police?    then "precinct"
              when .target_vip?       then "penthouse"
              else "hospital" # fallback
              end
      
      # Visual Sprite
      sprite = GSDL::Sprite.new(asset, origin: {0.5_f32, 0.5_f32})
      sprite.x = ox * TileSize
      sprite.y = oy * TileSize
      add_child(sprite)

      # Pulse animation logic could be added here
    end

    def draw(draw : GSDL::Draw)
      super(draw)
      
      # Add neon glow under/around it
      color = case @type
              when .target_ambulance? then GSDL::Color.new(255, 50, 50, 100) # Neon Red
              when .target_police?    then GSDL::Color.new(50, 50, 255, 100) # Neon Blue
              when .target_vip?       then GSDL::Color.new(255, 255, 50, 100) # Neon Yellow
              else GSDL::Color::White
              end
      
      # Simple pulse logic based on time
      pulse = (Math.sin((GSDL.ticks / 1000.0) * 4.0).to_f32 + 1.0_f32) / 2.0_f32
      glow_size = TileSize * (1.2_f32 + pulse * 0.2_f32)
      
      GSDL::Box.new(
        width: glow_size,
        height: glow_size,
        x: self.x - (glow_size / 2),
        y: self.y - (glow_size / 2),
        color: color,
        z_index: -11 # behind roads
      ).draw(draw)
    end
  end
end

