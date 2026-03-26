# Changelog

## 0.0.1

- Fix biome register example.
- Increase wind particle size.
- Improve docs slightly.
- Update to better screenshot.

## 0.0.0

* Provides a **location-based wind system** with direction and speed.
* Wind **slowly rotates** over time, completing configurable oscillations (e.g., ~2 switches per in‑game day).
* **Perlin noise** introduces minor natural variation for both direction and speed.
* **Biome influence**: modders can register biome-specific factors (`wind.register_biome`) to scale local wind speed.
* **Altitude attenuation**: wind weakens below sea level, gradually vanishing toward `MIN_Y`.
* Offers a **Wind:add()** helper to apply wind force to objects considering their density.
