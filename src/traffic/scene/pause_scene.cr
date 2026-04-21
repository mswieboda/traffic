module Traffic
  class PauseScene < GSDL::Scene
    @start_button : GSDL::Button
    @start_play_button : GSDL::Button
    @title : GSDL::Text
    @sub_title : GSDL::RichText
    @intro_text : GSDL::Text
    @background : GSDL::Box

    def initialize
      super(:pause)
      @z_index = 2000

      cw = GSDL::Game.width // 2
      ch = GSDL::Game.height // 2

      @title = GSDL::Text.new(
        font: GSDL::Font.default(32.0_f32),
        text: "GAME OVER",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32 - 100,
        origin: {0.5_f32, 1_f32},
        color: GSDL::Color::White,
        z_index: @z_index
      )

      @sub_title = GSDL::RichText.new(
        font: GSDL::Font.default(48.0_f32),
        text: "You got <c:red>XXX</c>",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32 - 100,
        origin: {0.5_f32, 0_f32},
        scale: {0.5_f32, 0.5_f32},
        color: GSDL::Color::White,
        z_index: @z_index
      )

      @start_button = GSDL::Button.new(
        font: GSDL::Font.default(48.0_f32),
        text: "exit",
        x: cw,
        y: ch - 32,
        padding_x: 32,
        padding_y: 16,
        origin: {0.5_f32, 0.5_f32},
        scale: {0.5_f32, 0.5_f32},
        on_click: ->(s : String) {
          GSDL::Game.quit!
        },
        z_index: @z_index + 100,
        draw_relative_to_camera: false,
      )

      @intro_text = GSDL::Text.new(
        font: GSDL::Font.default(20.0_f32),
        text: "To play the game, do XYZ\nBlah Blah Blah\nEtc etc.",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32 - 100,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::White,
        z_index: @z_index,
        align: GSDL::Font::Align::Center
      )

      @start_play_button = GSDL::Button.new(
        font: GSDL::Font.default(48.0_f32),
        text: "start",
        x: cw,
        y: ch + 64,
        padding_x: 32,
        padding_y: 16,
        origin: {0.5_f32, 0.5_f32},
        scale: {0.5_f32, 0.5_f32},
        on_click: ->(s : String) {
          GSDL::Game.paused = false
        },
        z_index: @z_index + 100,
        draw_relative_to_camera: false,
      )

      @background = GSDL::Box.new(
        x: 0,
        y: 0,
        width: GSDL::Game.width,
        height: GSDL::Game.height,
        color: GSDL::Color.new(0, 0, 0, 128),
        z_index: @z_index - 1
      )
    end

    def update(dt : Float32)
      if GSDL::Data.true?("game_over")
        update_game_over(dt)
      else
        update_intro(dt)
      end
    end

    private def update_game_over(dt : Float32)
      @start_button.update(dt)

      if GSDL::Input.action?(:menu)
        GSDL::Game.quit!
        return
      end

      # NEXT Button Hover Effect
      if GSDL::Mouse.in?(@start_button.screen_x, @start_button.screen_y, @start_button.screen_width, @start_button.screen_height)
        @start_button.color = GSDL::ColorScheme.get(:ui_hover)
      else
        @start_button.color = GSDL::ColorScheme.get(:ui_text)
      end
    end

    private def update_intro(dt : Float32)
      @start_play_button.update(dt)

      if GSDL::Input.action?(:menu)
        GSDL::Keys.clear # so it doesn't exit from Play scene immediately after
        GSDL::Game.paused = false
        return
      end

      if GSDL::Mouse.in?(@start_play_button.screen_x, @start_play_button.screen_y, @start_play_button.screen_width, @start_play_button.screen_height)
        @start_play_button.color = GSDL::ColorScheme.get(:ui_hover)
      else
        @start_play_button.color = GSDL::ColorScheme.get(:ui_text)
      end
    end

    def draw(draw : GSDL::Draw)
      @background.draw(draw)
      if GSDL::Data.true?("game_over")
        @title.draw(draw)
        total = GSDL::Data.get("total_escorted").as_i
        @sub_title.text = "You got <c:red>#{total}</c>"
        @sub_title.draw(draw)
        @start_button.draw(draw)
      else
        @intro_text.draw(draw)
        @start_play_button.draw(draw)
      end
    end
  end
end
