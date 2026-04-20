module Traffic
  enum IntersectionSignal
    GreenNS
    YellowNS
    GreenNSLeft
    YellowNSLeft
    GreenEW
    YellowEW
    GreenEWLeft
    YellowEWLeft
    AllRedNS
    AllRedEW
  end

  class Intersection < GSDL::Entity
    property state : IntersectionSignal = IntersectionSignal::GreenNS
    getter tile_x : Int32
    getter tile_y : Int32

    GreenDuration = 28_f32
    GreenLeftDuration = 5_f32
    YellowDuration = 2_f32
    RedDuration = 1_f32

    @state_timer : GSDL::Timer
    @tile_x : Int32
    @tile_y : Int32
    @signal_nb : TrafficSignal
    @signal_eb : TrafficSignal
    @signal_sb : TrafficSignal
    @signal_wb : TrafficSignal
    @signal_hud : GSDL::AnimatedSprite

    def initialize(@tile_x, @tile_y)
      @x = @tile_x * TileSize
      @y = @tile_y * TileSize
      @state = IntersectionSignal::GreenNSLeft
      @state_timer = GSDL::Timer.new(GreenLeftDuration.seconds)
      @state_timer.start

      # signal gfx
      offset = 12_f32
      origin = {0.5_f32, 1_f32}

      # north-bound
      offset_x = IntersectionSize - offset
      @signal_nb = TrafficSignal.new("traffic-signal-nb", offset_x, offset, origin)

      # east-bound
      offset_x = IntersectionSize - offset
      offset_y = IntersectionSize - offset
      @signal_eb = TrafficSignal.new("traffic-signal-eb", offset_x, offset_y, origin)

      # south-bound
      offset_y = IntersectionSize - offset
      @signal_sb = TrafficSignal.new("traffic-signal-sb", offset, offset_y, origin)

      # west-bound
      @signal_wb = TrafficSignal.new("traffic-signal-wb", offset, offset, origin)

      # signal HUD
      @signal_hud = GSDL::AnimatedSprite.new("traffic-signal-hud", 256, 256)

      @signal_hud.add("GreenNSLeft", [0], fps: 0)
      @signal_hud.add("YellowNSLeft", [1], fps: 0)
      @signal_hud.add("GreenNS", [2], fps: 0)
      @signal_hud.add("YellowNS", [3], fps: 0)
      @signal_hud.add("AllRedNS", [4], fps: 0)
      @signal_hud.add("GreenEWLeft", [5], fps: 0)
      @signal_hud.add("YellowEWLeft", [6], fps: 0)
      @signal_hud.add("GreenEW", [7], fps: 0)
      @signal_hud.add("YellowEW", [8], fps: 0)
      @signal_hud.add("AllRedEW", [9], fps: 0)
      # z-index, intersection tile is -10 so just add a few just in case, -5 is draw_selected_vehicle_path
      @signal_hud.z_index = -8

      add_child(@signal_nb)
      add_child(@signal_eb)
      add_child(@signal_sb)
      add_child(@signal_wb)
      add_child(@signal_hud)

      update_signal_frames
    end

    def update(dt : Float32)
      return unless super(dt)

      if @state_timer.done?
        case @state
        when .green_ns_left?
          @state = IntersectionSignal::YellowNSLeft
          @state_timer.duration = YellowDuration.seconds
        when .yellow_ns_left?
          @state = IntersectionSignal::GreenNS
          @state_timer.duration = GreenDuration.seconds
        when .green_ns?
          @state = IntersectionSignal::YellowNS
          @state_timer.duration = YellowDuration.seconds
        when .yellow_ns?
          @state = IntersectionSignal::AllRedNS
          @state_timer.duration = RedDuration.seconds
        when .all_red_ns?
          @state = IntersectionSignal::GreenEWLeft
          @state_timer.duration = GreenLeftDuration.seconds
        when .green_ew_left?
          @state = IntersectionSignal::YellowEWLeft
          @state_timer.duration = YellowDuration.seconds
        when .yellow_ew_left?
          @state = IntersectionSignal::GreenEW
          @state_timer.duration = GreenDuration.seconds
        when .green_ew?
          @state = IntersectionSignal::YellowEW
          @state_timer.duration = YellowDuration.seconds
        when .yellow_ew?
          @state = IntersectionSignal::AllRedEW
          @state_timer.duration = RedDuration.seconds
        when .all_red_ew?
          @state = IntersectionSignal::GreenNSLeft
          @state_timer.duration = GreenLeftDuration.seconds
        end

        @state_timer.restart
        update_signal_frames
      end
      true
    end

    def update_signal_frames
      case @state
      when .green_ns?
        @signal_nb.show_green
        @signal_sb.show_green
        @signal_eb.show_red
        @signal_wb.show_red
      when .yellow_ns?
        @signal_nb.show_yellow
        @signal_sb.show_yellow
        @signal_eb.show_red
        @signal_wb.show_red
      when .green_ns_left?
        @signal_nb.show_red_turn_green
        @signal_sb.show_red_turn_green
        @signal_eb.show_red
        @signal_wb.show_red
      when .yellow_ns_left?
        @signal_nb.show_red_turn_yellow
        @signal_sb.show_red_turn_yellow
        @signal_eb.show_red
        @signal_wb.show_red
      when .green_ew?
        @signal_nb.show_red
        @signal_sb.show_red
        @signal_eb.show_green
        @signal_wb.show_green
      when .yellow_ew?
        @signal_nb.show_red
        @signal_sb.show_red
        @signal_eb.show_yellow
        @signal_wb.show_yellow
      when .green_ew_left?
        @signal_nb.show_red
        @signal_sb.show_red
        @signal_eb.show_red_turn_green
        @signal_wb.show_red_turn_green
      when .yellow_ew_left?
        @signal_nb.show_red
        @signal_sb.show_red
        @signal_eb.show_red_turn_yellow
        @signal_wb.show_red_turn_yellow
      when .all_red_ns?, .all_red_ew?
        @signal_nb.show_red
        @signal_sb.show_red
        @signal_eb.show_red
        @signal_wb.show_red
      end

      @signal_hud.play(@state.to_s)
    end

    def toggle
      case @state
      when .green_ns?
        puts "Forcing NS Yellow..."
        @state = IntersectionSignal::YellowNS
        @state_timer.duration = YellowDuration.seconds
      when .green_ns_left?
        puts "Forcing NS Left Yellow..."
        @state = IntersectionSignal::YellowNSLeft
        @state_timer.duration = YellowDuration.seconds
      when .green_ew?
        puts "Forcing EW Yellow..."
        @state = IntersectionSignal::YellowEW
        @state_timer.duration = YellowDuration.seconds
      when .green_ew_left?
        puts "Forcing EW Left Yellow..."
        @state = IntersectionSignal::YellowEWLeft
        @state_timer.duration = YellowDuration.seconds
      else
        return
      end

      @state_timer.restart
      update_signal_frames
    end

    def clicked?(mx, my)
      mx >= @x && mx < @x + IntersectionSize && my >= @y && my < @y + IntersectionSize
    end

    def draw(draw : GSDL::Draw)
      super(draw)
    end
  end
end
