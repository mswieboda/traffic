module Traffic
  enum IntersectionSignal
    GreenNS
    YellowNS
    GreenEW
    YellowEW
  end

  class Intersection < GSDL::Sprite
    property state : IntersectionSignal = IntersectionSignal::GreenNS
    @timer : Float32 = 0.0
    @tile_x : Int32
    @tile_y : Int32

    def initialize(@tile_x, @tile_y)
      # Position in pixels based on tile coordinates
      px = @tile_x * 64
      py = @tile_y * 64
      
      # The signal sprite will be drawn twice, but for now let's just make it a composite or something.
      # Actually, let's just use GSDL::Draw to draw the signal indicator.
      # But the user asked for a 16x64 signal graphic.
      
      # We'll place two signals: one for NS (vertical) and one for EW (horizontal).
      # For now, let's just place one and see how it looks.
      super("signal", px + 64 - 20, py + 2)
      @state = IntersectionSignal::GreenNS
    end

    def update(dt : Float32)
      if @state == IntersectionSignal::YellowNS || @state == IntersectionSignal::YellowEW
        @timer -= dt
        if @timer <= 0
          next_state
        end
      end
    end

    def next_state
      case @state
      when IntersectionSignal::YellowNS
        @state = IntersectionSignal::GreenEW
      when IntersectionSignal::YellowEW
        @state = IntersectionSignal::GreenNS
      else
        # No auto-transition from Green for now
      end
    end

    def toggle
      case @state
      when IntersectionSignal::GreenNS
        @state = IntersectionSignal::YellowNS
        @timer = 3.0
      when IntersectionSignal::GreenEW
        @state = IntersectionSignal::YellowEW
        @timer = 3.0
      else
        # Transitioning, ignore
      end
    end

    def clicked?(mx, my)
      px = @tile_x * 64
      py = @tile_y * 64
      mx >= px && mx < px + 64 && my >= py && my < py + 64
    end

    def draw(draw : GSDL::Draw)
      # NS Signal (Vertical)
      draw.texture(
        texture: GSDL::TextureManager.get("signal"),
        dest_rect: GSDL::FRect.new(x: x, y: y, w: 16, h: 64),
        z_index: z_index
      )
      
      # EW Signal (Horizontal - rotated 90 degrees)
      # Place it at the bottom-left of the intersection tile
      ew_x = @tile_x * 64 + 2
      ew_y = @tile_y * 64 + 64 - 20
      draw.texture_rotated(
        texture: GSDL::TextureManager.get("signal"),
        dest_rect: GSDL::FRect.new(x: ew_x, y: ew_y, w: 16, h: 64),
        angle: 90.0,
        z_index: z_index
      )
      
      # Highlight the active light
      glow_color = GSDL::Color.new(red: 255, green: 255, blue: 255, alpha: 180)
      
      # NS Glow
      case @state
      when IntersectionSignal::GreenNS
        draw.circle_fill(x + 8, y + 52, 6, glow_color, z_index + 1)
      when IntersectionSignal::YellowNS
        draw.circle_fill(x + 8, y + 32, 6, glow_color, z_index + 1)
      when IntersectionSignal::GreenEW, IntersectionSignal::YellowEW
        draw.circle_fill(x + 8, y + 12, 6, glow_color, z_index + 1)
      end
      
      # EW Glow (Need to calculate rotated positions)
      # For EW (rotated 90 deg clockwise around center of 16x64):
      # Original (8, 12) -> ?
      # If rotated around center (8, 32):
      # Center is (8, 32). 
      # Red (8, 12) is (0, -20) relative to center. Rotated 90 deg: (+20, 0) -> (28, 32)
      # Yellow (8, 32) is (0, 0) -> (8, 32)
      # Green (8, 52) is (0, +20) -> (-20, 0) -> (-12, 32)
      # Wait, rotation is around dest_rect center by default in many SDL wrappers.
      
      # Actually, let's just use simple offsets for EW glow for now.
      # EW signal is horizontal at (ew_x, ew_y) rotated 90 deg.
      # Width becomes 64, Height 16? 
      # In SDL3, rotation is around center of dest_rect.
      # dest_rect is (ew_x, ew_y, 16, 64). Center is (ew_x+8, ew_y+32).
      
      case @state
      when IntersectionSignal::GreenEW
        # Green is on
        draw.circle_fill(ew_x + 8 - 20, ew_y + 32, 6, glow_color, z_index + 1)
      when IntersectionSignal::YellowEW
        # Yellow is on
        draw.circle_fill(ew_x + 8, ew_y + 32, 6, glow_color, z_index + 1)
      when IntersectionSignal::GreenNS, IntersectionSignal::YellowNS
        # Red is on for EW
        draw.circle_fill(ew_x + 8 + 20, ew_y + 32, 6, glow_color, z_index + 1)
      end
    end
  end
end
