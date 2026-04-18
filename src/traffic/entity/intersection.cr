module Traffic
  enum IntersectionSignal
    GreenNS
    GreenNSLeft
    YellowNS
    GreenEW
    GreenEWLeft
    YellowEW
  end

  class Intersection < GSDL::Sprite
    property state : IntersectionSignal = IntersectionSignal::GreenNS
    getter tile_x : Int32
    getter tile_y : Int32
    @state_timer : GSDL::Timer
    @switch_interval : Time::Span
    @tile_x : Int32
    @tile_y : Int32

    def initialize(@tile_x, @tile_y, switch_seconds : Int32 = 10) # Default reduced to 10s
      # Position in pixels based on top-left tile of 2x2 intersection
      px = @tile_x * TileSize
      py = @tile_y * TileSize

      @switch_interval = switch_seconds.seconds
      super("signal", px + IntersectionSize - 20, py + 2)
      @state = IntersectionSignal::GreenNS
      @state_timer = GSDL::Timer.new(@switch_interval)
      @state_timer.start
    end

    def update(dt : Float32)
      if @state_timer.done?
        case @state
        when IntersectionSignal::GreenNS
          @state = IntersectionSignal::GreenNSLeft
          @state_timer.duration = 10.seconds
          @state_timer.restart
        when IntersectionSignal::GreenNSLeft
          @state = IntersectionSignal::YellowNS
          @state_timer.duration = 3.seconds
          @state_timer.restart
        when IntersectionSignal::YellowNS
          @state = IntersectionSignal::GreenEW
          @state_timer.duration = @switch_interval
          @state_timer.restart
        when IntersectionSignal::GreenEW
          @state = IntersectionSignal::GreenEWLeft
          @state_timer.duration = 10.seconds
          @state_timer.restart
        when IntersectionSignal::GreenEWLeft
          @state = IntersectionSignal::YellowEW
          @state_timer.duration = 3.seconds
          @state_timer.restart
        when IntersectionSignal::YellowEW
          @state = IntersectionSignal::GreenNS
          @state_timer.duration = @switch_interval
          @state_timer.restart
        end
      end
    end

    def toggle
      puts "Intersection at (#{@tile_x}, #{@tile_y}) forced change!"
      
      case @state
      when .green_ns?, .green_ns_left?
        @state = IntersectionSignal::YellowNS
        @state_timer.duration = 3.seconds
        @state_timer.restart
      when .green_ew?, .green_ew_left?
        @state = IntersectionSignal::YellowEW
        @state_timer.duration = 3.seconds
        @state_timer.restart
      else
        # Already yellow/transitioning, ignore
      end
    end


    def clicked?(mx, my)
      px = @tile_x * TileSize
      py = @tile_y * TileSize
      mx >= px && mx < px + IntersectionSize && my >= py && my < py + IntersectionSize
    end

    def draw(draw : GSDL::Draw)
      px = @tile_x * TileSize
      py = @tile_y * TileSize

      cam_x = GSDL::Game.camera.x
      cam_y = GSDL::Game.camera.y
      zoom = GSDL::Game.camera.zoom
      
      old_scale_x, old_scale_y = draw.current_scale_x, draw.current_scale_y
      draw.scale = zoom

      # Reduced alpha debug box
      draw.rect_fill(
        GSDL::FRect.new(px - cam_x, py - cam_y, IntersectionSize, IntersectionSize),
        GSDL::Color.new(0, 100, 255, 20),
        100
      )

      # Determine Tints
      color_green      = GSDL::Color.new(100, 255, 100)
      color_magenta    = GSDL::Color.new(255, 0, 255) # For Left Turn
      color_yellow     = GSDL::Color.new(255, 255, 100)
      color_red        = GSDL::Color.new(255, 100, 100)

      ns_tint = color_red
      ew_tint = color_red

      case @state
      when .green_ns?
        ns_tint = color_green
      when .green_ns_left?
        ns_tint = color_magenta
      when .yellow_ns?
        ns_tint = color_yellow
      when .green_ew?
        ew_tint = color_green
      when .green_ew_left?
        ew_tint = color_magenta
      when .yellow_ew?
        ew_tint = color_yellow
      end

      # Coordinates
      ns_x = px + (IntersectionSize - 12.0_f32)
      ns_y = py + 16.0_f32
      ew_center_x = px + 24.0_f32
      ew_center_y = py + (IntersectionSize - 4.0_f32)
      ew_rect_x = ew_center_x - 8.0_f32
      ew_rect_y = ew_center_y - 32.0_f32

      # Draw NS Signal (Tinted)
      draw.texture(
        texture: GSDL::TextureManager.get("signal"),
        dest_rect: GSDL::FRect.new(x: ns_x - cam_x, y: ns_y - cam_y, w: 16, h: 64),
        tint: ns_tint,
        z_index: z_index
      )

      # Draw EW Signal (Tinted)
      draw.texture_rotated(
        texture: GSDL::TextureManager.get("signal"),
        dest_rect: GSDL::FRect.new(x: ew_rect_x - cam_x, y: ew_rect_y - cam_y, w: 16, h: 64),
        angle: 90.0,
        center: GSDL::Point.new(8, 32),
        tint: ew_tint,
        z_index: z_index
      )

      draw.scale = {old_scale_x, old_scale_y}
    end
  end
end
