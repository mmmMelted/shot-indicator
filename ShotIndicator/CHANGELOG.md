# Changelog

## 1.0.1
- Checked against game version 0.2.1.0: works unchanged (the AI firing code it hooks didn't change). Version bump only.

## 1.0.0
- First release.
- PUBG-style red glow at the top of the screen showing which way AI gunfire is coming from, placed by the shooter's
  direction relative to your view (edges = 90 degrees left / right); arrows on the edge for shots from behind.
- Follows the shooter as you turn, fades out after 2 seconds; one marker per shooter.
- Normal shots from up to 250 m, suppressed shots from 60 m; settings in rtv_shotindicator.cfg.
