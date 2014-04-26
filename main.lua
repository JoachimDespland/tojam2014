function love.load()
	mode_success = love.window.setMode( 1280, 720, {vsync=true, fullscreen=false})

	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	image = love.graphics.newImage("tiles.png")
	fillSprites()
	canvas = love.graphics.newCanvas(512, 512)

	-- world variables
	airdensity = 0.001225
	waterdensity = 1
	gravity = 70
	waterline = 180

	--puffin variables
	flypower = 0.005
	swimpower = 0.005
	swimspeed = 100
	flyspeed = 100
	swimlift = 0.0002
	flylift = 0.00015

	-- variables component tables
	physics = {}
	draw = {}
	puffins = {}

	-- create a puffin and add it to component tables
	puffin = {
		px = 160, 
		py = 0, 
		vx = 0, 
		vy = 0, 
		mass = 0.5, 
		density = 0.6, 
		sprite = 1, 
		drag = 0.001,
		movex = 0,
		movey = 0
	}	
	table.insert(draw, puffin)
	table.insert(physics, puffin)
	table.insert(puffins, puffin)

	-- create a test object and add it to component tables
	object = {px = 260, py = 190, vx = 0, vy = 0, mass = 0.5, density = 600, sprite = 2, drag = 0.1}	
	table.insert(draw, object)
	--table.insert(physics, object)
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

		--water/air variables
		local fluiddensity = 0
		local movepower = 0
		local movespeed = 0
		local movelift = 0
		if (v.py < waterline) then 
			fluiddensity = airdensity
			movepower = flypower
			movespeed = flyspeed
			movelift = flylift
		else 
			fluiddensity = waterdensity
			movepower = swimpower
			movespeed = swimspeed
			movelift = swimlift
		end

		--buoyancy
		local volume = v.mass / v.density
		v.ay = v.ay - (fluiddensity*volume*gravity)/v.mass


		local velocityx = v.vx
		local velocityy = v.vy

		--lift
		local speed = math.sqrt(velocityx*velocityx+velocityy*velocityy)
		local side = velocityy * v.movex - velocityx * v.movey
		local dotproduct = (velocityx/speed) * v.movex + (velocityy/speed) * v.movey
		if side ~= 0 and dotproduct > -0.3 then
			local theta = -speed*movelift*(side/math.abs(side))
			local cs = math.cos(theta);
			local sn = math.sin(theta);

			v.vx = velocityx * cs - velocityy * sn;
			v.vy = velocityx * sn + velocityy * cs;
		end

		--drag
		local drag = (fluiddensity*v.drag)/v.mass

		v.vx = v.vx/(1+drag)
		v.vy = v.vy/(1+drag)

		--fly/swim
		if v.movex ~= 0 or v.movey ~= 0 then

			--propelling
			local relvx = velocityx - movespeed*v.movex
			local relvy = velocityy - movespeed*v.movey

			local scalar = (relvx * v.movex + relvy * v.movey)

			if scalar < 0 then
				local projx = scalar*v.movex
				local projy = scalar*v.movey

				local rejx = v.movex - projx
				local rejy = v.movey - projy

				v.vx = v.vx + projx/(1+movepower) - projx
				v.vy = v.vy + projy/(1+movepower) - projy
			end
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
			v.movey = 1
		elseif love.keyboard.isDown( "up" ) then
			v.movey = -1
		else v.movey = 0
		end

		if love.keyboard.isDown( "right" ) then
			v.movex = 1
		elseif love.keyboard.isDown( "left" ) then
			v.movex = -1
		else v.movex = 0
		end

		local norm = math.sqrt(v.movex*v.movex+v.movey*v.movey)
		if (norm ~= 0) then
			v.movex = v.movex/norm
			v.movey = v.movey/norm
		end
	end
end