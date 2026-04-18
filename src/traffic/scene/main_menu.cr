require "./play"

module Traffic
  class Scene::MainMenu < GSDL::Scene
    @start_button : GSDL::Button

    def initialize
      super(:main_menu)

      hud = GSDL::HUD.new
      hud << GSDL::HUDText.new(
        font: GSDL::Font.default(96.0_f32),
        text: "TRAFFIC",
        anchor: GSDL::Anchor::TopCenter,
        offset_y: 192,
        origin: {0.5_f32, 0_f32},
        scale: {0.5_f32, 0.5_f32},
        color: GSDL::ColorScheme.get(:main),
        align: GSDL::Font::Align::Center
      )

      cw = GSDL::Game.width // 2
      ch = GSDL::Game.height // 2

      @start_button = GSDL::Button.new(
        font: GSDL::Font.default(32.0_f32),
        text: "start",
        x: cw,
        y: ch - 32,
        padding_x: 32,
        padding_y: 16,
        origin: {0.5_f32, 0.5_f32},
        scale: {0.5_f32, 0.5_f32},
        on_click: ->(s : String) {
          GSDL::Game.switch(Scene::Play.new)
        }
      )

      self.hud = hud
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Escape)
        exit_with_transition
      end

      # Button Hover Effect
      if GSDL::Mouse.in?(@start_button.draw_x, @start_button.draw_y, @start_button.draw_width, @start_button.draw_height)
        @start_button.color = GSDL::ColorScheme.get(:ui_hover)
      else
        @start_button.color = GSDL::ColorScheme.get(:ui_text)
      end

      @start_button.update(dt)
    end

    def draw(draw : GSDL::Draw)
      @start_button.draw(draw)

      # manually draw HUD
      hud.try &.draw(draw)
    end
  end
end
