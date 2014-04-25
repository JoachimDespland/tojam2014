function fillSprites()
	local px = image:getHeight()
	local py = image:getWidth()

	sprites = {
	love.graphics.newQuad(64,0,16,16,px,py),
	love.graphics.newQuad(64+16,0,16,16,px,py),
	love.graphics.newQuad(64+32,0,16,16,px,py),
	love.graphics.newQuad(64+48,0,16,16,px,py)}
end

function love.load()
	mode_success = love.window.setMode( 1920, 1080, {vsync=true, fullscreen=true})

	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	image = love.graphics.newImage("tiles.png")
	fillSprites()
	canvas = love.graphics.newCanvas(512, 512)

	-- world variables
	airdensity = 1.225
	waterdensity = 1000
	gravity = 50
	waterline = 180

	-- game component tables
	physics = {}
	draw = {}
	puffins = {}

	-- create a puffin and add it to component tables
	puffin = {px = 160, py = 160, vx = 0, vy = 0, ax = 0, ay = 0, mass = 0.5, density = 600, sprite = 1}	
	table.insert(draw, puffin)
	table.insert(physics, puffin)
	table.insert(puffins, puffin)

	-- create a test object and add it to component tables
	object = {px = 260, py = 190, vx = 0, vy = 0, ax = 0, ay = 0, mass = 0.5, density = 600, sprite = 2}	
	table.insert(draw, object)
	table.insert(physics, object)

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
	love.graphics.draw(canvas,0,0,0,3)
end

function doPhysics(dt)
	for k,v in pairs(physics) do

		--velocity
		v.vx = v.vx+v.ax*dt
		v.vy = v.vy+v.ay*dt

		--position
		v.px = v.px+v.vx*dt
		v.py = v.py+v.vy*dt

		--new acceleration
		v.ax = 0
		v.ay = gravity
		local volume = v.mass / v.density
		if (v.py < waterline) then v.ay = v.ay - (airdensity*volume*gravity)/v.mass
		else v.ay = v.ay - (waterdensity*volume*gravity)/v.mass
		end
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