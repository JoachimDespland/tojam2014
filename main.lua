function love.load()
	mode_success = love.window.setMode( 1280, 720, {vsync=true, fullscreen=true})

	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	image = love.graphics.newImage("puffin_sprite_sm.png")
	jelly_image = love.graphics.newImage("jelly_sprite_sm_line.png")
	fish_image = love.graphics.newImage("fish.png")

	bg0 = love.graphics.newImage("Background_Skyback.png")
	print(bg0)
	bg1 = love.graphics.newImage("Background_Clouds.png")
	bg2 = love.graphics.newImage("Background_Clouds Front.png")
	bg3 = love.graphics.newImage("Background_Cliffs Back.png")
	bg31 = love.graphics.newImage("Background_Underwater Cliffs Back.png")
	bg4 = love.graphics.newImage("Background_Cliffs.png")
	bg4a = love.graphics.newImage("Background_Seaweed_Rocks.png")
	bg5 = love.graphics.newImage("Background_Water back.png")

	ambient = love.audio.newSource("ambient_ocean_v2.mp3")
	ambient:setLooping(true)
	ambient:setVolume(0.75)
	ambient:play()


	fillSprites()
	canvas = love.graphics.newCanvas(1024, 1024)

	-- world variables
	airdensity = 0.001225
	waterdensity = 1
	gravity = 200
	waterline = 180
	looparound = 3000

	--puffin variables
	flypower = 0.03
	swimpower = 0.03
	swimspeed = 108
	flyspeed = 108
	swimlift = 0.0002
	flylift = 0.00015
	flapthreshold = 5
	turnthreshold = 3

	-- variables component tables
	physics = {}
	draw = {}
	drawjelly = {}
	drawfish = {}
	puffins = {}
	animations = {}
	points = {}
	bubbles = {}
	fishes = {}

	-- create a puffin and add it to component tables
	puffin = {
		--sprite
		sprite = 0, 
		line = 0,

		--physics
		px = 180, 
		py = 60, 
		vx = 0, 
		vy = 0, 
		mass = 0.5, 
		density = 0.5, 
		waterdrag = 0.001,
		airdrag = 0.2,

		--puffin
		movex = 0,
		movey = 0,
		left = false,
		underwater = false,
		splash1 = love.audio.newSource("splash_out_v3.wav", "static"),
		splash2 = love.audio.newSource("splash_in_v1.wav", "static"),
		gulp = love.audio.newSource("gulp_v1.wav", "static"),
		slap = love.audio.newSource("jelly_slap_v7.wav"),


		--animation
		animstate = 0,
		animspeed = 10,
		animstart = 0,
		animcount = 4,
		animloop = false,
	}	
	table.insert(draw, puffin)
	table.insert(physics, puffin)
	table.insert(puffins, puffin)
	table.insert(animations, puffin)


	for i = 0, 15 , 1 do
		createFish(9)
	end
	for i = 0, 15 , 1 do
		createFish(7)
	end
	for i = 0, 15 , 1 do
		createFish(5)
	end
	for i = 0, 10, 1 do
		createFish(11)
	end
	for i = 0, 5 , 1 do
		createFish(15)
	end
	for i = 0, 5 , 1 do
		createFish(13)
	end


	for i = 0, 30 , 1 do
		createJelly()
	end

	camera = 0
end

function createJelly()
	object = {
		sprite = 0,
		line = 0, 
		px = math.random(-looparound,looparound),
		py = math.random(waterline,waterline*2),
		vx = 0, 
		vy = 0, 
		mass = 1, 
		density = 1, 
		waterdrag = 0.05,
		airdrag = 0.05,

		movey = 5,

		animstate = math.random(0,14),
		animspeed = 10,
		animstart = 0,
		animcount = 14,
		animloop = true,
	}	
	table.insert(drawjelly, object)
	table.insert(physics, object)
	table.insert(animations, object)
end

function createFish(t)
	local speed
	local animcount
	local mindepth
	
	if t == 11 then
		speed = 17+math.random(-5,5)
		frames = 8
		mindepth = 1/2
	elseif t == 15 then
		speed = 25+math.random(-5,5)
		frames = 6
		mindepth = 4/5
	elseif t == 21 then
		speed = 20+math.random(-5,5)
		frames = 4
		mindepth = 1/3
	else
		speed = 13+math.random(-5,5)
		frames = 4
		mindepth = 0
	end

	if (math.random(0,1) > 0.5) then
		speed = -speed
	end

	local fish = {
		--sprite
		sprite = 0, 
		line = t,

		--physics
		px = math.random(-looparound,looparound),
		py = math.random(waterline+16+waterline*mindepth,waterline*2-8),
		vx = 0,
		vy = 0,
		mass = 0.5, 
		density = 1.0, 
		waterdrag = 0.01,
		airdrag = 0.2,

		--fish
		movex = speed,
		movey = 0,
		fishtype = t,

		--animation
		animstate = math.random(0,frames),
		animspeed = 10,
		animstart = 0,
		animcount = frames,
		animloop = true,
	}
	table.insert(drawfish, fish)
	table.insert(physics, fish)
	table.insert(fishes, fish)
	table.insert(animations, fish)	
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
	doFish(dt)
	doAnimations(dt)
end

function doBubbles(x,y,velx,vely,wid,n)
	for variable = 0, n, 1 do
		local bubble = {
			px = x+math.random(-wid/8,wid/8)*math.random(-wid/8,wid/8), 
			py = y, 
			vx = math.random(-wid,wid)*math.random(-wid,wid)
			+math.random(-velx*0.07,velx*0.07)*math.random(-velx*0.07,velx*0.07), 
			vy = math.abs(math.random(-vely*0.07,vely*0.07)*math.random(-vely*0.07,vely*0.07)), 
			mass = 0.01, 
			density = 0.5, 
			waterdrag = 0.00066,
			airdrag = 0.001,
		}
		table.insert(bubbles, bubble)
	end
end


function doSplash(x,y,velx,vely,wid,n)
	for variable = 0, n, 1 do
		local point = {
			px = x+math.random(-wid/8,wid/8)*math.random(-wid/8,wid/8), 
			py = y, 
			vx = math.random(-wid,wid)*math.random(-wid,wid)
			+math.random(-velx*0.07,velx*0.07)*math.random(-velx*0.07,velx*0.07), 
			vy = -math.abs(math.random(-vely*0.07,vely*0.07)*math.random(-vely*0.07,vely*0.07)), 
			mass = 0.0001, 
			density = 0.8, 
			waterdrag = 0.001,
			airdrag = 0.001,
		}
		table.insert(points, point)
	end
end

function drawPoints()
	love.graphics.setPointStyle("rough")
	love.graphics.setPointSize(1)
	for k,v in pairs(points) do
		love.graphics.point( camera+v.px, v.py )
		if v.py > waterline then 
			points[k] = nil
		end
	end

	for k,v in pairs(bubbles) do
		love.graphics.point( camera+v.px, v.py )
		if v.py < waterline then 
			bubbles[k] = nil
		end
	end
end

function drawSprites()
	love.graphics.draw(bg0,0,0)

	love.graphics.draw(bg1,math.floor(camera*0.1)%640,0)
	love.graphics.draw(bg1,math.floor(camera*0.1)%640-640,0)

	love.graphics.draw(bg2,math.floor(camera*0.2)%640,0)
	love.graphics.draw(bg2,math.floor(camera*0.2)%640-640,0)

	love.graphics.draw(bg3,math.floor(camera*0.4)%640,0)
	love.graphics.draw(bg3,math.floor(camera*0.4)%640-640,0)

	love.graphics.draw(bg31,math.floor(camera*0.6)%640,0)
	love.graphics.draw(bg31,math.floor(camera*0.6)%640-640,0)

	love.graphics.draw(bg4,math.floor(camera*0.8)%640,0)
	love.graphics.draw(bg4,math.floor(camera*0.8)%640-640,0)
	love.graphics.draw(bg4a,math.floor(camera*0.8)%640,0)
	love.graphics.draw(bg4a,math.floor(camera*0.8)%640-640,0)
	
	love.graphics.draw(bg5,math.floor(camera)%640-640,0)	
	love.graphics.draw(bg5,math.floor(camera)%640,0)	

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

	for k,v in pairs(drawfish) do
		love.graphics.draw(
			fish_image,
			love.graphics.newQuad(v.sprite*16,v.line*16, 16,16, 128,384),
			camera+v.px-8,v.py-8
		)
	end

	drawPoints()
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

	function physicfun(v)

		while v.px > -camera+320+looparound do
			v.px = v.px-2*looparound
		end
		while v.px < -camera+320-looparound do
			v.px = v.px+2*looparound
		end

		--acceleration
		v.ax = 0
		v.ay = gravity

		--water/air variables
		local fluiddensity = 0
		local movepower = 0
		local movespeed = 0
		local movelift = 0
		local drag = 0
		if (v.py < waterline) then 
			fluiddensity = airdensity
			drag = (fluiddensity*v.airdrag)/v.mass
		else 
			fluiddensity = waterdensity
			drag = (fluiddensity*v.waterdrag)/v.mass
		end

		--buoyancy
		local volume = v.mass / v.density
		v.ay = v.ay - (fluiddensity*volume*gravity)/v.mass

		--drag
		v.vx = v.vx/(1+drag)
		v.vy = v.vy/(1+drag)

		--velocity
		v.vx = v.vx+v.ax*dt
		v.vy = v.vy+v.ay*dt

		--position
		v.px = v.px+v.vx*dt
		v.py = v.py+v.vy*dt
	end

	for k,v in pairs(physics) do
		physicfun(v)
	end

	for k,v in pairs(points) do
		physicfun(v)
	end

	for k,v in pairs(bubbles) do
		physicfun(v)
	end

end

function doFish(dt)
	for k,v in pairs(fishes) do
		v.vx = v.vx + (v.movex-v.vx)
		if (v.movex > 0) then v.line = v.fishtype+1 end
	end
	for k,v in pairs(drawjelly) do
		if (v.py > 300) then
			v.movey = -5
		end
		if (v.py < 200) then
			v.movey = 5
		end
		v.animspeed = v.animspeed + ((15 -v.movey*0.5)-v.animspeed)*0.04
		v.vy = v.vy + (v.movey-v.vy)*0.05

		for k2,v2 in next,drawjelly,k do
			local dx = v.px-v2.px
			local dy = v.py-v2.py

			local dvx = v.vx-v2.vx
			local dvy = v.vy-v2.vy

			local dist = math.sqrt(dx*dx+dy*dy)
			local nx = dx/dist
			local ny = dy/dist

			local vn = dvx*nx+dvy*ny

			if dist < 14 and vn < 0 then

				local impulse = -30+2*vn/(1/v.mass+1/v2.mass)

				local ix = nx*impulse
				local iy = ny*impulse

				v.vx = v.vx - ix/v.mass
				v.vy = v.vy - iy/v.mass

				v2.vx = v2.vx + ix/v2.mass
				v2.vy = v2.vy + iy/v2.mass

				v2.px = v.px-nx*15
				v2.py = v.py-ny*15

				v.animspeed = 85
				v2.animspeed = 85
			end
		end
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
		if (v.py < waterline) then
			if (v.line == 0 or v.line == 1) and v.vy < 0 then
				v.vy = v.vy + (-flyspeed-v.vy)*flypower
			end
		else
			if true then
				if true then -- v.movex == 0 and v.movey == 0 then
					v.movex = v.vx/speed
					v.movey = v.vy/speed
				end

				if swimspeed > speed then
					v.vx = v.vx + (v.movex*swimspeed-v.vx)*swimpower*math.abs(v.movex)
					v.vy = v.vy + (v.movey*swimspeed-v.vy)*swimpower*math.abs(v.movey)
				end
			end
		end

		if v.left == true and v.vx > turnthreshold then v.left = false end
		if v.left == false and v.vx < -turnthreshold then v.left = true end

		function glide() 
			v.animloop = true
			v.animcount = 8
			if v.line < 8 then v.animstate = 8 end

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
			elseif angle < 2*math.pi*9/32 then
				if (v.left) then v.line = 13
				else v.line = 12 end
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
			elseif angle < 2*math.pi*25/32 then
				if (v.left) then v.line = 21
				else v.line = 22 end
			elseif angle < 2*math.pi*27/32 then
				v.line = 23
			elseif angle < 2*math.pi*29/32 then
				v.line = 24
			elseif angle < 2*math.pi*31/32 then
				v.line = 25
			end
		end

		function fly()
			v.animcount = 4
			v.animspeed = 10
			v.animloop = true
			if v.line ~= 0 and v.line ~=1 then v.animstate = 0 end
			if v.left == true then 
				v.line = 1
			else 
				v.line = 0 
			end
		end

		--fix threshold to transition state
		if (v.py < waterline) then
			if v.vy > flapthreshold then 
				glide()
			elseif v.vy < -flyspeed then 
				glide()
			else 
				fly()
			end
		else 
			glide() 
		end

		--splash
		if (v.py < waterline and v.underwater == true) then 
			v.underwater = false
			v.vy = math.min(v.vy, -100)
			doSplash(v.px,waterline-0.1,v.vx,v.vy,8,200)
			v.splash1:play()
		elseif (v.py > waterline and v.underwater == false) then
			v.underwater = true
			doSplash(v.px,waterline-0.1,v.vx,v.vy,8,200)			
			doBubbles(v.px,waterline+0.1,v.vx,v.vy,8,200)
			v.splash2:play()
		end		


		--fish collision
		for k2,v2 in pairs(fishes) do
			local dx = v.px-v2.px
			local dy = v.py-v2.py

			if dx*dx+dy*dy < 128 then
				v.gulp:play()
				v2.px = v2.px+looparound
			end
		end

		--jellyfish collision
		for k2,v2 in pairs(drawjelly) do
			local dx = v.px-v2.px
			local dy = v.py-v2.py

			local dvx = v.vx-v2.vx
			local dvy = v.vy-v2.vy

			local dist = math.sqrt(dx*dx+dy*dy)
			local nx = dx/dist
			local ny = dy/dist

			local vn = dvx*nx+dvy*ny

			if dist < 14 and vn < 0 then

				v.slap:play()

				local impulse = -30+2*vn/(1/v.mass+1/v2.mass)

				local ix = nx*impulse
				local iy = ny*impulse

				v.vx = v.vx - ix/v.mass
				v.vy = v.vy - iy/v.mass

				v2.vx = v2.vx + ix/v2.mass
				v2.vy = v2.vy + iy/v2.mass

				v2.px = v.px-nx*15
				v2.py = v.py-ny*15

				v2.animspeed = 85
			end
		end
	end
end