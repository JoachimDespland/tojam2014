function love.load()
	mode_success = love.window.setMode( 1280, 720, {vsync=true, fullscreen=true})

	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	image = love.graphics.newImage("puffin_sprite_sm.png")
	jelly_image = love.graphics.newImage("jelly_sprite_sm_line.png")

	bg0 = love.graphics.newImage("Background_Skyback.png")
	print(bg0)
	bg1 = love.graphics.newImage("Background_Clouds.png")
	bg2 = love.graphics.newImage("Background_Clouds Front.png")
	bg3 = love.graphics.newImage("Background_Cliffs Back.png")
	bg4 = love.graphics.newImage("Background_Cliffs.png")
	bg5 = love.graphics.newImage("Background_Water back.png")

	fillSprites()
	canvas = love.graphics.newCanvas(1024, 1024)

	-- world variables
	airdensity = 0.001225
	waterdensity = 1
	gravity = 70
	waterline = 180

	--puffin variables
	flypower = 0.25
	swimpower = 0.25
	swimspeed = 50
	flyspeed = 50
	swimlift = 0.0002
	flylift = 0.00015
	flapthreshold = 20
	turnthreshold = 0

	-- variables component tables
	physics = {}
	draw = {}
	drawjelly = {}
	puffins = {}
	animations = {}

	-- create a puffin and add it to component tables
	puffin = {
		--sprite
		sprite = 0, 
		line = 0,

		--physics
		px = 160, 
		py = 0, 
		vx = 0, 
		vy = 0, 
		mass = 0.5, 
		density = 0.6, 
		drag = 0.001,

		--puffin
		flaptimer = 0,
		flapkey = false,
		flapnext = false,
		movex = 0,
		movey = 0,
		left = false,

		--animation
		animstate = 0,
		animspeed = 10,
		animstart = 0,
		animcount = 4,
		animloop = true,
	}	
	table.insert(draw, puffin)
	table.insert(physics, puffin)
	table.insert(puffins, puffin)
	table.insert(animations, puffin)

	-- create a test object and add it to component tables
	object = {
		sprite = 0,
		line = 0, 
		px = 260, 
		py = 0, 
		vx = 0, 
		vy = 0, 
		mass = 2, 
		density = 0.8, 
		drag = 0.1,

		animstate = 0,
		animspeed = 10,
		animstart = 0,
		animcount = 14,
		animloop = true,
	}	
	table.insert(drawjelly, object)
	table.insert(physics, object)
	table.insert(animations, object)

	object2 = {
		sprite = 0,
		line = 0, 
		px = 290, 
		py = 100, 
		vx = 0, 
		vy = 0, 
		mass = 2, 
		density = 0.8, 
		drag = 0.1,

		animstate = 0,
		animspeed = 10,
		animstart = 0,
		animcount = 14,
		animloop = true,
	}	
	table.insert(drawjelly, object2)
	table.insert(physics, object2)
	table.insert(animations, object2)

	object3 = {
		sprite = 0,
		line = 0, 
		px = 360, 
		py = 50, 
		vx = 0, 
		vy = 0, 
		mass = 2, 
		density = 0.8, 
		drag = 0.1,

		animstate = 0,
		animspeed = 10,
		animstart = 0,
		animcount = 14,
		animloop = true,
	}	
	table.insert(drawjelly, object3)
	table.insert(physics, object3)
	table.insert(animations, object3)


	camera = 0
end

function fillSprites()
	local px = image:getHeight()
	local py = image:getWidth()

	sprites = {
		love.graphics.newQuad(64,0,16,16,px,py),
		love.graphics.newQuad(64+16,0,16,16,px,py),
		love.graphics.newQuad(64+32,0,16,16,px,py),
		love.graphics.newQuad(64+48,0,16,16,px,py)
	}
end

function love.update(dt)

	if love.keyboard.isDown( "escape" ) then love.event.quit() end

	camera=-puffin.px+320
	doPhysics(dt)
	doPuffins(dt)
	doAnimations(dt)
end

function drawSprites()
	love.graphics.draw(bg0,0,0)

	love.graphics.draw(bg1,(camera*0.1)%640,0)
	love.graphics.draw(bg1,(camera*0.1)%640-640,0)

	love.graphics.draw(bg2,(camera*0.2)%640,0)
	love.graphics.draw(bg2,(camera*0.2)%640-640,0)

	love.graphics.draw(bg3,(camera*0.4)%640,0)
	love.graphics.draw(bg3,(camera*0.4)%640-640,0)

	love.graphics.draw(bg4,(camera*0.8)%640,0)
	love.graphics.draw(bg4,(camera*0.8)%640-640,0)
	
	for k,v in pairs(draw) do
		love.graphics.draw(
			image, 
			love.graphics.newQuad(v.sprite*16,v.line*16, 16,16, 128,416),
			camera+v.px-8,v.py-8
		)
	end

	for k,v in pairs(drawjelly) do
		love.graphics.draw(
			jelly_image, 
			love.graphics.newQuad(v.sprite*16,v.line*16, 16,16, 224,16),
			camera+v.px-8,v.py-8
		)
	end

	love.graphics.draw(bg5,camera%640-640,0)	
	love.graphics.draw(bg5,camera%640,0)	
end

function love.draw()
	canvas:renderTo(drawSprites)

	love.graphics.draw(canvas,0,0,0,2)
end

function doAnimations(dt)
	for k,v in pairs(animations) do
		v.animstate = v.animstate + dt*v.animspeed
		v.sprite = v.animstart+math.floor(v.animstate)
		if v.sprite >= v.animstart+v.animcount then
			if v.animloop then
				v.sprite = v.sprite - v.animcount
				v.animstate = v.animstate - v.animcount
			else
				v.sprite = v.animstart + v.animcount-1
			end
		end
	end
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
		else 
			fluiddensity = waterdensity
		end

		--buoyancy
		local volume = v.mass / v.density
		v.ay = v.ay - (fluiddensity*volume*gravity)/v.mass

		--drag
		local drag = (fluiddensity*v.drag)/v.mass

		v.vx = v.vx/(1+drag)
		v.vy = v.vy/(1+drag)

		--velocity
		v.vx = v.vx+v.ax*dt
		v.vy = v.vy+v.ay*dt

		--position
		v.px = v.px+v.vx*dt
		v.py = v.py+v.vy*dt
	end
end

function doPuffins(dt)
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

		--------------------------
		local velocityx = v.vx
		local velocityy = v.vy

		if (v.py < waterline) then 
			movelift = flylift
		else 
			movelift = swimlift
		end		

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

		--fly/swim-------------
		if love.keyboard.isDown( "z" ) then
			if v.flapkey == false and v.flaptimer < 0.2 then
				v.flapnext = true
			end
			v.flapkey = true
		else
			v.flapkey = false
		end

		if v.flaptimer > 0 then
			v.flaptimer = v.flaptimer - dt
		end

		if (v.py < waterline) then
			if v.flapnext and v.flaptimer <= 0 then
				v.flaptimer = 0.5
				print "flap"
				v.flapnext = false

				v.vy = v.vy + (-flyspeed-v.vy)*flypower
			end
		else
			if v.flapnext and v.flaptimer <= 0 then
				v.flaptimer = 0.5
				print "swim"
				v.flapnext = false

				if v.movex == 0 and v.movey == 0 then
					v.movex = v.vx/speed
					v.movey = v.vy/speed
				end

				v.vx = v.vx + (v.movex*swimspeed-v.vx)*swimpower*math.abs(v.movex)
				v.vy = v.vy + (v.movey*swimspeed-v.vy)*swimpower*math.abs(v.movey)
			end
		end

		if v.left == true and v.vx > turnthreshold then v.left = true end
		if v.left == false and v.vx < -turnthreshold then v.left = true end

		function glide() 
			angle = math.atan2(v.vy/speed,v.vx/speed)
			if (angle < 0) then angle = angle + math.pi*2 end

			if angle < 2*math.pi/32 or angle > 2*math.pi*31/32 then
				v.line = 8
			elseif angle < 2*math.pi*3/32 then
				v.line = 9
			elseif angle < 2*math.pi*5/32 then
				v.line = 10
			elseif angle < 2*math.pi*7/32 then
				v.line = 11
			elseif angle < 2*math.pi*8.1/32 then
				v.line = 12
			elseif angle < 2*math.pi*9/32 then
				v.line = 13
			elseif angle < 2*math.pi*11/32 then
				v.line = 14
			elseif angle < 2*math.pi*13/32 then
				v.line = 15
			elseif angle < 2*math.pi*15/32 then
				v.line = 16
			elseif angle < 2*math.pi*17/32 then
				v.line = 17
			elseif angle < 2*math.pi*19/32 then
				v.line = 18
			elseif angle < 2*math.pi*21/32 then
				v.line = 19
			elseif angle < 2*math.pi*23/32 then
				v.line = 20
			elseif angle < 2*math.pi*24.1/32 then
				v.line = 21
			elseif angle < 2*math.pi*25/32 then
				v.line = 22
			elseif angle < 2*math.pi*27/32 then
				v.line = 23
			elseif angle < 2*math.pi*29/32 then
				v.line = 24
			elseif angle < 2*math.pi*31/32 then
				v.line = 25
			end
		end

		if (v.py < waterline) then
			if v.vy > flapthreshold then 
				glide()
			elseif v.vy < -flyspeed then 
				glide()
			else 
				if left then v.line = 1
				else v.line = 0
				end
			end
		else glide()
		end
	end
end