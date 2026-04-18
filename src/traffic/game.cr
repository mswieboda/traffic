require "./scene/main_menu"

module Traffic
  class Game < GSDL::Game
    def initialize
      super(
        title: "Traffic",
        logical_width: 1280,
        logical_height: 720,
        fullscreen: true,
      )

      # Configure Cyberpunk Color Scheme
      GSDL::ColorScheme.configure(
        ui_bg:      "#050505", # Deep black
        ui_text:    "#99FF33", # Neon Lime
        main:       "#99FF33", # Neon Lime
        alt:        "#FFAA00", # Orange-Yellow (Powered)
        highlight:  "#FF3366", # Pink/Red (Battery)
        success:    "#00FF00", # Pure Lime
        danger:     "#FF3366"  # Red
      )
    end

    def init
      Game.draw.to_sdl.default_texture_scale_mode = LibSDL3::ScaleMode::Nearest
      GSDL::Game.push(Scene::MainMenu.new)
    end

    def load_default_font
      "fonts/Electrolize-Regular.ttf"
    end
  end
end
