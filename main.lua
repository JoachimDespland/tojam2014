function love.load()
	mode_success = love.window.setMode( 1280, 720, {vsync=true, fullscreen=true})

	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	image = love.graphics.newImage("tiles.png")
	fillSprites()
	canvas = love.graphics.newCanvas(512, 512)

	-- world variables
	airdensity = 1.225
	waterdensity = 1000
	airdrag = 1
	waterdrag = 10
	gravity = 50
	waterline = 180

	--puffin variables
	airspower = 1
	swimpower = 1
	swimspeed = 1
	airspeed = 1

	-- variables component tables
	physics = {}
	draw = {}
	puffins = {}

	-- create a puffin and add it to component tables
	puffin = {
		px = 160, 
		py = 160, 
		vx = 0, 
		vy = 0, 
		mass = 0.5, 
		density = 600, 
		sprite = 1, 
		drag = 0.0001,
		movex = 1,
		movey = 0
	}	
	table.insert(draw, puffin)
	table.insert(physics, puffin)
	table.insert(puffins, puffin)

	-- create a test object and add it to component tables
	object = {px = 260, py = 190, vx = 0, vy = 0, mass = 0.5, density = 600, sprite = 2, drag = 0.00001}	
	table.insert(draw, object)
	table.insert(physics, object)
end

function fillSprites()
	local px = image:getHeight()
	local py = image:getWidth()

	sprites = {
	love.graphics.newQuad(64,0,16,16,px,py),
	love.graphics.newQuad(64+16,0,16,16,px,py),
	love.graphics.newQuad(64+32,0,16,16,px,py),
	love.graphics.newQuad(64+48,0,16,16,px,py)}
end

function love.update(dt)
	doPhysics(dt)
	doPuffins()
end

function drawSprites()
	for k,v in pairs(draw) do
		love.graphics.draw(image, sprites[v.sprite],v.px,v.py)
	end
end

function love.draw()
	canvas:renderTo(love.graphics.clear)
	canvas:renderTo(drawSprites)
	love.graphics.draw(canvas,0,0,0,2)
end

function doPhysics(dt)
	for k,v in pairs(physics) do

		--acceleration
		v.ax = 0
		v.ay = gravity

		--fluid density
		local fluiddensity = 0
		if (v.py < waterline) then 
			fluiddensity = airdensity
		else 
			fluiddensity = waterdensity
		end

		--buoyancy
		local volume = v.mass / v.density
		v.ay = v.ay - (fluiddensity*volume*gravity)/v.mass


		--drag
		local speed = math.sqrt(v.vx*v.vx+v.vy*v.vy)
		local drag = (fluiddensity*speed*speed*v.drag)/v.mass
		if (speed ~= 0) then
			v.ax = v.ax - (v.vx/speed)*drag
			v.ay = v.ay - (v.vy/speed)*drag
		end

		--velocity
		v.vx = v.vx+v.ax*dt
		v.vy = v.vy+v.ay*dt

		--position
		v.px = v.px+v.vx*dt
		v.py = v.py+v.vy*dt
	end
end

function doPuffins()
	for k,v in pairs(puffins) do
		if love.keyboard.isDown( "down" ) then
			v.ay = v.ay+10
		end
		if love.keyboard.isDown( "up" ) then
			v.ay = v.ay-10
		end
		if love.keyboard.isDown( "right" ) then
			v.ax = v.ax+10
		end
		if love.keyboard.isDown( "left" ) then
			v.ax = v.ax-10
		end
	end
end