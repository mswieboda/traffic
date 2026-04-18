module TemplateGameSDL
  class Scene::Start < GSDL::Scene
    @sprite : GSDL::AnimatedSprite
    @text : GSDL::Text

    def initialize
      transition_in = GSDL::FadeTransition.new(
        direction: GSDL::TransitionDirection::In,
        duration: 0.75_f32,
        started: true
      )
      transition_out = GSDL::FadeTransition.new(
        direction: GSDL::TransitionDirection::Out,
        duration: 0.5_f32
      )

      super(:start, transition_in: transition_in, transition_out: transition_out)

      @sprite = GSDL::AnimatedSprite.new("player", width: 128, height: 128, origin: {0.5_f32, 0.5_f32})
      @sprite.center(width: GSDL::Game.width, height: GSDL::Game.height + 300)
      @sprite.add("fire", (0..3).to_a, 12)
      @sprite.play("fire")

      color = GSDL::Color.new(g: 255, a: 255)
      @text = GSDL::Text.new(text: "TemplateGameSDL!", color: color)
      @text.center(width: GSDL::Game.width, height: GSDL::Game.height - 300)

      # tween sprite to start
      tween = @sprite.tween
      tween.add_sequence([
        {
          :duration => 0.8,
          :rotation => 0.0,
          :scale => {2.0_f32, 2.0_f32},
          :easing => :ease_in_out
        },
        {
          :duration => 1.5,
          :rotation => -180.0,
          :scale => {0.75_f32, 0.75_f32},
        },
        {
          :duration => 0.5,
          :rotation => 270.0,
          :scale => {0.1_f32, 0.1_f32},
          :easing => :ease_in
        },
        {
          :duration => 1.0,
          :rotation => 0.0,
          :scale => {1_f32, 1_f32},
          :easing => :ease_out
        }
      ])
      tween.start(loop: true)
    end

    def update(dt : Float32)
      @sprite.update(dt)

      if GSDL::Keys.just_pressed?(GSDL::Keys::Escape)
        transition_out.start
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Tab)
        # active_object.tweens.clear
        @sprite.flash
      end
    end

    def draw(draw : GSDL::Draw)
      @sprite.draw(draw)
      @text.draw(draw)
    end
  end
end
