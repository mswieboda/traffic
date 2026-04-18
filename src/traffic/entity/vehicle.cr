module Traffic
  enum VehicleType
    Civilian
    Priority
  end

  enum PatienceState
    Patient
    Anxious
    Frustrated
    RoadRage
  end

  class Vehicle < GSDL::Sprite
    include GSDL::Collidable

    property vehicle_type : VehicleType
    property patience_state : PatienceState = PatienceState::Patient
    property speed : Float32
    property? waiting : Bool = false
    property? wrecked : Bool = false
    property time_to_destination : Float32 = 0.0_f32
    property frustration : Float32 = 0.0_f32

    @original_speed : Float32
    @honk_timer : GSDL::Timer
    @rage_cooldown : GSDL::Timer

    def initialize(@vehicle_type, direction : GSDL::Direction, x, y)
      @honk_timer = GSDL::Timer.new(Time::Span.new(seconds: Random.rand(4..8)))
      @honk_timer.start
      @rage_cooldown = GSDL::Timer.new(Time::Span.new(seconds: 10))
      
      @original_speed = case @vehicle_type
                        when VehicleType::Priority
                          @time_to_destination = 60.0_f32
                          Random.rand(400.0_f32..550.0_f32)
                        else
                          Random.rand(200.0_f32..350.0_f32)
                        end
      @speed = @original_speed

      # Determine texture based on direction
      texture_key = case direction
                    when .north? then "car_north"
                    when .south? then "car_south"
                    else "car_east"
                    end

      super(texture_key, x, y)
      self.direction = direction

      # No rotation needed anymore as we use directional assets
      self.rotation = 0.0
    end

    def collision_bounding_box : GSDL::FRect
      # Use intrinsic texture size without transformation
      GSDL::FRect.new(0, 0, width, height)
    end

    def look_ahead_box : GSDL::FRect
      box = collision_box
      look_dist = 24.0_f32

      case self.direction
      when .east?  then GSDL::FRect.new(box.right, box.y, look_dist, box.h)
      when .west?  then GSDL::FRect.new(box.left - look_dist, box.y, look_dist, box.h)
      when .north? then GSDL::FRect.new(box.x, box.y - look_dist, box.w, look_dist)
      when .south? then GSDL::FRect.new(box.x, box.bottom, box.w, look_dist)
      else box # fallback
      end
    end

    def update(dt : Float32, intersections : Array(Intersection), all_vehicles : Array(Vehicle))
      if @vehicle_type == VehicleType::Priority
        decay_rate = 1.0_f32
        if @waiting
          if is_waiting_on_wreck?(all_vehicles)
            decay_rate = 10.0_f32
          else
            decay_rate = 3.0_f32
          end
        end
        @time_to_destination -= dt * decay_rate
        @time_to_destination = 0.0_f32 if @time_to_destination < 0
      end

      return if @wrecked

      update_frustration(dt)

      @waiting = false

      # Check for collisions with other vehicles
      all_vehicles.each do |other|
        next if other == self
        if self.collides?(other)
          @wrecked = true
          other.wrecked = true
          GSDL::AudioManager.get("crash").play
          return
        end
      end

      # Lane-halting logic: look ahead
      look_box = look_ahead_box
      all_vehicles.each do |other|
        next if other == self
        if look_box.overlaps?(other.collision_box)
          @waiting = true
          break
        end
      end

      unless @waiting
        # Intersection check (incorporating red lights into halting)
        # Road Rage vehicles ignore traffic signals
        unless @patience_state == PatienceState::RoadRage
          check_intersections(intersections)
        end
      end

      unless @waiting
        # Basic movement
        dx = 0.0_f32
        dy = 0.0_f32

        case self.direction
        when .east?  then dx = 1.0_f32
        when .west?  then dx = -1.0_f32
        when .north? then dy = -1.0_f32
        when .south? then dy = 1.0_f32
        else # ignore others
        end

        self.x += dx * @speed * dt
        self.y += dy * @speed * dt
      end
    end

    private def update_frustration(dt : Float32)
      if @waiting
        @frustration += dt
        # Frustration Thresholds (Max frustration for RoadRage is now 35.0)
        new_state = if @frustration > 35.0
                      PatienceState::RoadRage
                    elsif @frustration > 20.0
                      PatienceState::Frustrated
                    elsif @frustration > 5.0
                      PatienceState::Anxious
                    else
                      PatienceState::Patient
                    end

        if new_state != @patience_state
          if new_state == PatienceState::RoadRage
            GSDL::AudioManager.get("rage_trigger").play
            @rage_cooldown.start
          end
          @patience_state = new_state
          # Reset honk timer when entering Frustrated
          if new_state == PatienceState::Frustrated
            @honk_timer.restart
          end
        end

        # Honking ONLY when frustrated (Orange)
        if @patience_state == PatienceState::Frustrated && @honk_timer.done?
            GSDL::AudioManager.get("honk").play
            @honk_timer.duration = Time::Span.new(seconds: Random.rand(4..8))
            @honk_timer.restart
        end
      else
        # Gradually calm down when moving
        if @patience_state == PatienceState::RoadRage && @rage_cooldown.running?
          # Do nothing, wait for cooldown
        else
          @frustration -= dt * 0.5
          @frustration = 0.0 if @frustration < 0
        end

        # State transitions during calm down
        if @patience_state == PatienceState::RoadRage && @frustration < 32.0
          @patience_state = PatienceState::Frustrated
        elsif @patience_state == PatienceState::Frustrated && @frustration < 18.0
          @patience_state = PatienceState::Anxious
        elsif @patience_state == PatienceState::Anxious && @frustration < 4.0
          @patience_state = PatienceState::Patient
        end
      end
    end

    private def is_waiting_on_wreck?(all_vehicles : Array(Vehicle)) : Bool
      look_box = look_ahead_box
      all_vehicles.any? do |other|
        next false if other == self
        other.wrecked? && look_box.overlaps?(other.collision_box)
      end
    end

    private def check_intersections(intersections)
      # Detection box in front of the vehicle
      look_ahead = 40.0_f32

      check_x = self.x + width / 2.0_f32
      check_y = self.y + height / 2.0_f32

      case self.direction
      when .east?  then check_x += look_ahead
      when .west?  then check_x -= look_ahead
      when .north? then check_y -= look_ahead
      when .south? then check_y += look_ahead
      else # ignore others
      end

      intersections.each do |inter|
        if inter.clicked?(check_x, check_y)
          case self.direction
          when .north?, .south?
            # Vertical traffic: stop if signal is GreenEW or YellowEW (meaning RedNS)
            if inter.state == IntersectionSignal::GreenEW || inter.state == IntersectionSignal::YellowEW
              @waiting = true
              return
            end
          when .east?, .west?
            # Horizontal traffic: stop if signal is GreenNS or YellowNS (meaning RedEW)
            if inter.state == IntersectionSignal::GreenNS || inter.state == IntersectionSignal::YellowNS
              @waiting = true
              return
            end
          else # ignore others
          end
        end
      end
    end

    def off_screen?
      self.x < -200 || self.x > 2760 || self.y < -200 || self.y > 1600
    end

    def draw(draw : GSDL::Draw)
      old_scale_x = draw.current_scale_x
      old_scale_y = draw.current_scale_y

      draw.scale = GSDL::Game.camera.zoom

      cam_x = GSDL::Game.camera.x
      cam_y = GSDL::Game.camera.y

      flip = self.direction.west? ? GSDL::TileMap::Flip::Horizontal : GSDL::TileMap::Flip::None

      # Determine texture based on direction
      texture_key = case self.direction
                    when .north? then "car_north"
                    when .south? then "car_south"
                    else "car_east"
                    end

      # Draw using directional texture and its actual size
      tex = GSDL::TextureManager.get(texture_key)
      tex_size = tex.size

      draw.texture(
        texture: tex,
        dest_rect: GSDL::FRect.new(x: self.x - cam_x, y: self.y - cam_y, w: tex_size[0], h: tex_size[1]),
        flip: flip,
        tint: @wrecked ? GSDL::Color.new(40, 40, 40, 255) : GSDL::Color::White,
        z_index: z_index
      )

      # Draw frustration bar above the vehicle
      unless @wrecked || @frustration < 1.0
        bar_w = 40.0_f32
        bar_h = 6.0_f32
        bar_x = self.x - cam_x + (tex_size[0] / 2.0_f32) - (bar_w / 2.0_f32)
        bar_y = self.y - cam_y - 12.0_f32

        # Background
        draw.rect_fill(GSDL::FRect.new(bar_x, bar_y, bar_w, bar_h), GSDL::Color.new(30, 30, 30, 150), z_index + 1)

        # Foreground
        percent = Math.min(1.0_f32, @frustration / 35.0_f32)
        color = case @patience_state
                when PatienceState::RoadRage
                  GSDL::Color.new(255, 50, 50, 255) # Red
                when PatienceState::Frustrated
                  GSDL::Color.new(255, 120, 50, 255) # Orange
                when PatienceState::Anxious
                  GSDL::Color.new(255, 255, 50, 255) # Yellow
                else
                  GSDL::Color.new(100, 255, 100, 255) # Green
                end
        draw.rect_fill(GSDL::FRect.new(bar_x, bar_y, bar_w * percent, bar_h), color, z_index + 2)

        # Exclamation mark for Road Rage
        if @patience_state == PatienceState::RoadRage
          # Just a small red box or something as placeholder for "icon"
          draw.rect_fill(GSDL::FRect.new(bar_x + bar_w + 4, bar_y - 4, 8, 14), GSDL::Color.new(255, 0, 0, 255), z_index + 3)
        end
      end

      draw.scale = {old_scale_x, old_scale_y}
    end
  end
end
