local shader
local temp_image
local elapsed_time = 0
local stars = {color = {1, 1, 1}}
local love = love
local flux = require("flux")

local function rand3()
	return math.random(), math.random(), math.random(), math.random()
end

function stars.load()
	local noiseimg = love.image.newImageData(512, 512)
	noiseimg:mapPixel(rand3)
	noiseimg = love.graphics.newImage(noiseimg)
	noiseimg:setFilter("nearest", "nearest")
	noiseimg:setWrap("repeat", "repeat")
	
	temp_image = love.graphics.newImage(love.image.newImageData(864, 486))
	shader = love.graphics.newShader [[
	// Expanding stars code
	// https://www.shadertoy.com/view/MdB3Dt
	#define MAX_MOVEMENT_SPEED 0.16
	#define MIN_RADIUS 0.01
	#define MAX_RADIUS 0.3
	#define STAR_COUNT 80
	#define PI 3.14159265358979323
	#define TWOPI 6.283185307

	#define RADIUS_SEED 1337.0
	#define START_POS_SEED 2468.0
	#define THETA_SEED 1675.0
	#define iResolution love_ScreenSize
	extern float iTime;
	extern vec3 backgroundColor;
	extern sampler2D noiseImage;
	const vec3 starColor = vec3(1.0, 1.0, 1.0);
	const vec4 fullWhite = vec4(1.0, 1.0, 1.0, 1.0);

	float rand(float s1, float s2)
	{
		//return fract(mod(sin(dot(vec2(s1, s2), vec2(12.9898, 78.233))) * 43758.5453, TWOPI));
		//return dot(texture2D(noiseImage, vec2(fract(s1 * 0.9898), fract(s2 * s1 * 0.233))), vec4(1.0, 1.0, 1.0, 1.0));
		return dot(texture2D(noiseImage, vec2(s1 * 0.9898, s2 * 0.233)), fullWhite);
		//return dot(texture2D(noiseImage, vec2(s1, s2)), fullWhite);
	}

	float saturate(float v)
	{
		return clamp(v, 0.0, 1.0);
	}

	vec2 cartesian(vec2 p)
	{
		return vec2(p.x * cos(p.y), p.x * sin(p.y));
	}

	vec3 renderBackground(vec2 uv, float aspect)
	{
		vec2 center = vec2(0.0);
		float dist = length(uv - center);
		vec3 col = saturate(1.0 / (dist + 1.5)) * backgroundColor;
		return col;
	}

	vec3 renderStars(vec2 uv, float aspect)
	{
		vec3 col = vec3(0.0);
		float maxDistance = aspect;

		for (int i = 0; i < STAR_COUNT; ++i) {
			// setup radius
			float radiusrand = rand(float(i), RADIUS_SEED);
			float rad = MIN_RADIUS + radiusrand * (MAX_RADIUS - MIN_RADIUS);
			
			// compute star position
			float startr = rand(float(i), START_POS_SEED) * maxDistance;
			float speed = radiusrand * MAX_MOVEMENT_SPEED;
			float r = mod(startr + iTime * speed, max(1.0, maxDistance));
			float theta = rand(float(i), THETA_SEED) * TWOPI;
			vec2 pos = cartesian(vec2(r, theta));
			pos.x *= aspect;
			
			// blending/effects
			float dist = length(uv - pos);
			float distFromStarCenter = dist / rad;
			float distTraveled = r / maxDistance;
			float shape = saturate(1.0 / (50.0 * (1.0 / distTraveled) * distFromStarCenter) - 0.05);
			
			col += starColor * step(dist, rad) * shape;
		}
		return col;
	}

	void mainImage(out vec4 fragColor, in vec2 fragCoord )
	{
		float aspect = iResolution.x / iResolution.y;
		vec2 uv = -1.0 + 2.0 * (fragCoord.xy / iResolution.xy);
		uv.x *= aspect;
		
		vec3 col = renderBackground(uv, aspect);
		col += renderStars(uv, aspect);
		
		fragColor = vec4(col.xyz, 1.0);
	}
	
	vec4 effect(vec4 c, Image tex, vec2 tc, vec2 sc)
	{
		vec4 fc;
		mainImage(fc, sc);
		return fc;
	}
	]]
	shader:send("backgroundColor", stars.color)
	shader:send("noiseImage", noiseimg)
	
	stars.flux = flux.group()
end

function stars.update(deltaT)
	elapsed_time = elapsed_time + deltaT
	stars.flux:update(deltaT)
	shader:send("iTime", elapsed_time * 0.125)
	shader:send("backgroundColor", stars.color)
end

function stars.draw()
	love.graphics.push("all")
	love.graphics.origin()
	love.graphics.setShader(shader)
	love.graphics.draw(temp_image)
	love.graphics.pop()
end

function stars.setColorTransition(r, g, b)
	stars.flux:to(stars.color, 2.5, {r, g, b}):ease("linear")
end
love.handlers.stars_setcolor = stars.setColorTransition

return stars.load() or stars
