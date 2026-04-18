module Traffic
  class Scene::MainMenu < GSDL::Scene
    def initialize
      super(:main_menu)

      hud = GSDL::HUD.new
      hud << GSDL::HUDText.new(
        # font: GSDL::Font.default(24.0_f32),
        text: "TRAFFIC traffic",
        anchor: GSDL::Anchor::TopCenter,
        offset_y: 24,
        origin: {0.5_f32, 0_f32},
        color: GSDL::ColorScheme.get(:main),
        align: GSDL::Font::Align::Center
      )

      self.hud = hud
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Escape)
        exit_with_transition
      end
    end

    def draw(draw : GSDL::Draw)
      # manually draw HUD
      hud.try &.draw(draw)
    end
  end
end
