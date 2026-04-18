module Traffic
  enum VehicleType
    Civilian
    Priority
  end

  class Vehicle < GSDL::Sprite
    include GSDL::Collidable

    property vehicle_type : VehicleType
    property speed : Float32
    property? waiting : Bool = false
    property? wrecked : Bool = false
    property time_to_destination : Float32 = 0.0_f32

    @original_speed : Float32

    def initialize(@vehicle_type, direction : GSDL::Direction, x, y)
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

      @waiting = false

      # Check for collisions with other vehicles
      all_vehicles.each do |other|
        next if other == self
        if self.collides?(other)
          @wrecked = true
          other.wrecked = true
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
        check_intersections(intersections)
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

      draw.scale = {old_scale_x, old_scale_y}
    end
  end
end
