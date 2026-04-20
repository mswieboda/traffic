require "./vehicle"

module Traffic
  class VehiclePriority < Vehicle
    property type : PriorityType = PriorityType::Ambulance
    @time_to_destination : Float32 = 0.0_f32

    def initialize(direction : GSDL::Direction, x : Int32 | Float32, y : Int32 | Float32, @type = PriorityType::Ambulance)
      super(direction, x, y)
      @time_to_destination = 60.0_f32
    end

    def priority? : Bool
      true
    end

    def skips_red_lights? : Bool
      true
    end

    def base_speed_range : Range(Float32, Float32)
      (400.0_f32)..(550.0_f32)
    end

    def select_target(graph : NodeGraph)
      # Priority logic: Hospital, Police, etc.
      type_node = case @type
                  when .ambulance? then NodeType::TargetAmbulance
                  when .police?    then NodeType::TargetPolice
                  when .vip?       then NodeType::TargetVIP
                  else NodeType::Exit
                  end

      targets = graph.nodes.select { |n| n.type == type_node }

      # Fallback to random exit if no specific target found or 30% of the time
      if targets.empty? || Random.rand < 0.3
        targets = graph.nodes.select(&.type.exit?)
      end

      @target_node = targets.empty? ? nil : targets.sample
    end

    def asset_prefix : String
      "ambulance"
    end

    def v_dims : Tuple(Int32, Int32)
      {32, 64}
    end

    def setup_animations(sprite : GSDL::AnimatedSprite, kind : Symbol)
      sprite.add("idle", [0, 0, 1, 2, 1, 2, 1, 2, 1, 2], fps: 6)
      sprite.add("blink_right", [0], fps: 0)
      sprite.add("blink_left", [0], fps: 0)
      sprite.add("brake", [0], fps: 0)
      sprite.add("brake_blink_right", [0], fps: 0)
      sprite.add("brake_blink_left", [0], fps: 0)
      sprite.play("idle")
    end

    def update_special_behavior(dt : Float32, intersections : Array(Intersection), all_vehicles : Array(Vehicle))
      decay_rate = 1.0_f32
      decay_rate = is_waiting_on_wreck?(all_vehicles) ? 10.0_f32 : 3.0_f32 if @waiting
      @time_to_destination -= dt * decay_rate
      @time_to_destination = 0.0_f32 if @time_to_destination < 0
    end

    def draw_status_overlay(draw : GSDL::Draw, th : Float32, cam_x : Float32, cam_y : Float32)
      # Priority-specific status (e.g. destination time) can be added here if needed
    end
  end
end
