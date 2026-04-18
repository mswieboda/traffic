# TemplateGameSDL

## Rename

Currently only works on Mac or Linux.

To use this template, use the rename script, and follow the prompts, to automatically replace all text, and rename all files and folders from the example of `TemplateGameSDL` and `template_game_sdl`.

```
crystal src/rename.cr
```

The rename won't work on Windows until using the command line prompt works, I could in the meantime make a custom batch script, but I probably won't do that for now.

## Installation

1. Install SDL3

follow [sdl3.cr install instructions](https://github.com/mswieboda/sdl3.cr) to get all the available SDL3 packages, image, TTY, mixer

2. Run `shards install`

```
shards install
```

3. Build and Run

```
make build
```

```
make run
```

(`run` will build if needed)

outputs to `build` folder. there are also release make actions, see the `Makefile` for full action list

## Documentation

To see full documentation of GameSDL, and SDL3 (included bindings library) you can run the `crystal docs` command, but specify the lib entry points, in correct order (SDL3 first, GSDL second, because GSDL depends on SDL3):

```
crystal docs lib/sdl3/src/sdl3.cr src/game_sdl.cr
```

or in your game:

```
crystal docs lib/sdl3/src/sdl3.cr lib/game_sdl/src/game_sdl.cr src/your_game_entry_point.cr
```

Unfortunately the `delegate` methods docs will not expand to full method signatures, so you'll need to infer wrapped classes like GSDL::Point that wraps SDL3::FPoint to see those method signatures. Eventually I plan to either document each delegate so the parameters and return types are clear, or fully wrap the methods themselves so it is even more clear.
