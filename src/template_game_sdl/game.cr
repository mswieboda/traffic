require "./scene/start"

module TemplateGameSDL
  class Game < GSDL::Game
    def initialize
      super(
        title: "TemplateGameSDL",
        logical_width: 1280,
        logical_height: 768,
        fullscreen: true,
      )
    end

    def init
      GSDL::Game.push(Scene::Start.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_textures
      [{"player", "gfx/player.png"}]
    end
  end
end
