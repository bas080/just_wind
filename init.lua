local wind = {}

_G.breasy = wind

local modname = core.get_modpath("breasy")
local setting_prefix = modname .. "_"

local global_factor = 10
local almost_zero = 1e-4

local biomes = dofile(modname .. "/biomes.lua")

local wind_particles_setting = setting_prefix .. "wind_particles"

local wind_enabled = core.settings:get_bool(wind_particles_setting, false)

-- constants
local SCALE = 200
local TIME_SCALE = 150
local SEA_LEVEL = 0
local MIN_Y = -20

-- biome registry
local biome_factors = {}

function wind.register_biome(name, def)
	biome_factors[name] = def.factor or 1.0
end

-- Register factors for some biomes.
for biome, def in pairs(biomes) do
	wind.register_biome(biome, def)
end

-- noise setup (reuse, do NOT recreate per call)
local np_dir_x = {
	offset = 0,
	scale = 1,
	spread = { x = 1, y = 1, z = 1 },
	seed = 12345,
	octaves = 3,
	persist = 0.5,
	lacunarity = 2.0,
}

local np_dir_z = {
	offset = 0,
	scale = 1,
	spread = { x = 1, y = 1, z = 1 },
	seed = 54321,
	octaves = 3,
	persist = 0.5,
	lacunarity = 2.0,
}

local np_speed = {
	offset = 0,
	scale = 1,
	spread = { x = 1, y = 1, z = 1 },
	seed = 99999,
	octaves = 3,
	persist = 0.5,
	lacunarity = 2.0,
}

local noise_dir_x = PerlinNoise(np_dir_x)
local noise_dir_z = PerlinNoise(np_dir_z)
local noise_speed = PerlinNoise(np_speed)

local function get_biome_factor(pos)
	local data = core.get_biome_data(pos)
	if not data then
		return 1
	end

	local name = core.get_biome_name(data.biome)
	return biome_factors[name] or 1
end

local function altitude_factor(y)
	if y >= SEA_LEVEL then
		return 1
	end
	if y <= MIN_Y then
		return 0
	end
	return (y - MIN_Y) / (SEA_LEVEL - MIN_Y)
end

local Wind = {}
Wind.__index = Wind

-- main API
function wind.from_vector(vector)
	setmetatable(vector, Wind)
	return vector
end

function wind.get_wind(pos)
	local x = math.round(pos.x) / SCALE
	local z = math.round(pos.z) / SCALE
	local t = core.get_gametime() / TIME_SCALE

	-- speed
	local s = noise_speed:get_3d({ x = x, y = z, z = t })

	local speed = ((s + 1) * 0.5) ^ 1.4

	-- no need to continue if the speed is very low.
	if speed <= almost_zero then
		return wind.from_vector(vector.zero())
	end

	-- direction
	local dx = noise_dir_x:get_3d({ x = x, y = z, z = t })
	local dz = noise_dir_z:get_3d({ x = x, y = z, z = t })

	local dir = vector.normalize(vector.new(dx, 0, dz))

	-- local speed = (s + 1) * 0.5 -- [0,1]

	-- biome influence
	speed = speed * get_biome_factor(pos)

	speed = speed * global_factor

	-- altitude attenuation
	speed = speed * altitude_factor(pos.y)

	local velocity = vector.multiply(dir, speed)

	return wind.from_vector(velocity)
end

-- Experimental: use at your own risk. Might be removed or changed at any time.
function wind.get_occluded_wind(pos)
	local raw = wind.get_wind(pos)

	local is_clear = core.line_of_sight(pos, vector.subtract(pos, raw))
	if is_clear then
		return raw
	else
		return wind.from_vector(vector.zero())
	end
end

local PLAYER_RADIUS = 20
local PARTICLES_PER_STEP = 3

local function rand_offset(r)
	return (math.random() * 2 - 1) * r
end

core.register_chatcommand("wind_toggle", {
	params = "",
	description = "Toggle wind particle effects on/off",
	func = function(name)
		wind_enabled = not wind_enabled
		core.settings:set_bool(wind_particles_setting, wind_enabled)
		core.settings:write()
		return true, "Wind particles are now " .. (wind_enabled and "ON" or "OFF")
	end,
})

core.register_globalstep(function(dtime)
	if not wind_enabled then
		return
	end -- skip if disabled

	for _, player in ipairs(core.get_connected_players()) do
		local pos = player:get_pos()

		for i = 1, PARTICLES_PER_STEP do
			local p = {
				x = pos.x + rand_offset(PLAYER_RADIUS),
				y = pos.y + 1.5 + rand_offset(2),
				z = pos.z + rand_offset(PLAYER_RADIUS),
			}

			local w = wind.get_wind(p)

			core.add_particle({
				pos = p,
				velocity = w,
				expirationtime = 5,
				glow = 3,
				texture = "default_cloud.png",
				alpha = { 0.2, 0 },
				size = 0.1,
				size_tween = { 0, 0.1, 0 },
			})
		end
	end
end)

return wind
