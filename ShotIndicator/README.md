# Shot Indicator

**See which way gunfire is coming from.** A PUBG-style red marker at the top of the screen.

- Every AI gunshot within earshot lights a soft red glow at the top of the screen (wide at the top, fading downward), placed by where the
  shooter is compared to where you're looking: centre = straight ahead, edges = 90 degrees left or right.
- Shots from behind you show as an arrow on the nearer edge.
- The marker follows the shooter's position as you turn, and fades out after 2 seconds.
- Suppressed shots only show from close by.

## Settings

Edit `%APPDATA%\Road to Vostok\rtv_shotindicator.cfg` (created on first launch):

```
[indicator]
range=250.0              ; metres, normal shots
suppressed_range=60.0    ; metres, suppressed shots
duration=2.0             ; seconds a marker stays
only_shots_at_you=false  ; true = only shots from AI targeting you
```

## Requirements

- Road to Vostok Build 2 ("Nomads", v0.2.0.0).
- [Metro Mod Loader](https://github.com/ametrocavich/vostok-mod-loader) v3.4.1 or newer.

## Install

Drop `ShotIndicator.vmz` into `Road to Vostok/mods/` and check it in the loader window.
To uninstall, delete the file (or uncheck it).

## Compatibility

Single player. Safe for existing saves. Works alongside AI mods (it only listens for AI gunshots).

## Troubleshooting

The log is at `%APPDATA%\Road to Vostok\logs\godot.log` (written when the game closes). Look for
`[ShotIndicator] v1.0.0 loaded`.

## Credits

- Mod by **mmmMelted** ([github.com/mmmMelted](https://github.com/mmmMelted)).
- Built on [Metro Mod Loader](https://github.com/ametrocavich/vostok-mod-loader) by ametrocavich (RTVModLib hooks).
- Made with AI assistance: written with Claude Code (Anthropic, Claude Opus 5.5), tested by mmmMelted.
- No game files or assets are included.

## License

MIT, see `LICENSE` (in the mod folder).
