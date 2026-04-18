module Traffic
  class Scene::Play < GSDL::Scene
    def initialize
      super(:main_menu)
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Escape)
        exit_with_transition
      end
    end

    def draw(draw : GSDL::Draw)
    end
  end
end
