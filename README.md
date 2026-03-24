# Breasy

A mod that will tell you what the wind is like at a position.

```lua
local wind = dofile(core.get_modpath('breasy')..'/init.lua')

wind.get_wind(pos)

wind.register_biome({
  factor = 0.1 -- 0 till 1+
})
```

Currently the wind is determined by Perlin noise. Wind is 0 below y < 20.

If adopted it can create a more consistent environment where all particles move with the wind.

## Features

* Provides a **location-based wind system** with direction and speed.
* Wind **slowly rotates** over time, completing configurable oscillations (e.g., ~2 switches per in‑game day).
* **Perlin noise** introduces minor natural variation for both direction and speed.
* **Biome influence**: modders can register biome-specific factors (`wind.register_biome`) to scale local wind speed.
* **Altitude attenuation**: wind weakens below sea level, gradually vanishing toward `MIN_Y`.
* Offers a **Wind:add()** helper to apply wind force to objects considering their density.
* Generates **client-side particles** around players to visualize wind flow.
* Designed for **minimal recalculation**: noise objects are reused and speed/direction are stable per location.

This makes it easy for other mods to query wind vectors at any position and integrate effects like particle motion, tree sway, or environmental interactions.

## Usage

### Apply wind to an object velocity

```lua
local current_vel = { x = 0, y = 0, z = 0 }  -- current velocity
local density = 2                             -- heavier objects feel less wind

-- get wind at position and apply to velocity
local new_vel, wind_vec = wind.get_wind(pos):add(current_vel, density)

object:set_velocity(new_vel)
```

### Using wind for particles

```lua
-- get wind vector
local wind_vec = wind.get_wind(pos)

-- apply wind to particle velocity using :add()
local base_vel = { x = 0, y = 0, z = 0 }
local particle_vel, applied_wind = wind_vec:add(base_vel, 1)

minetest.add_particle({
    pos = pos,
    velocity = particle_vel,
    expirationtime = 3,
    size = 0.1,
})
```

### Read magnitude and direction

```lua
local wind_vec = wind.get_wind(pos)

-- magnitude/speed of wind
local speed = vector.length(wind_vec)

-- normalize to get pure direction
vector.normalize(wind_vec)
```

## Debugging

You can toggle the wind particle effects on and off in-game using the chat command:

```text
/wind_toggle
```

Useful when integrating wind into your mod.

## Donate

If you enjoy my work, you can support me here: [💖 Donate](https://liberapay.com/bas080)

Thank you for helping me keep modding and sharing fun with everyone!
