--[[
TODO:
	- при столкновении с препятствием, отдавать часть энергии этому припятствию
	+ to shaders
		+ load matrix, info: light, obstacles
	+ необходимо просчитывать за 2 основных прохода:
		+ 1-й: это свет обычный, лучевой, без отражений, свет теряет энергию по желанию
		+ 2-й: это просчет отражений с учетом засвеченных точек, свет теряет энергию
		+ идея: из карты света просчитать для каждой ячейки очень короткий свет
	-NO использовать углы
	-+ directonal light
	- функции для каждого способа прохода, чтобы не комментировать не нужный
	+ обработка из центра, а не по всей матрице каждый цикл (смотри love.update())
	- замерить скорость выполнения
		- полного выполнения
		- одного цикла	
	+ подсчитать количество операций 
		+ полного выполнения
		+ одного цикла
	- оптимизиция
		- крайние ячейки:
			- self.giveled max будет меньше, чем у не крайних	
		- перенести в .dll и слинковать с помощью luajit.FFI
--]]
--[[
	zlib License

	Copyright (c) 2015 Savoshchanka Anton Aleksandrovich

	This software is provided 'as-is', without any express or implied
	warranty. In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you must not
	   claim that you wrote the original software. If you use this software
	   in a product, an acknowledgement in the product documentation would be
	   appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	   misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
	
	https://github.com/AntonioModer/radiosity2D
--]]


function love.run()
	if love.math then
		love.math.setRandomSeed(os.time())
		for i=1,3 do love.math.random() end
	end

	if love.event then
		love.event.pump()
	end

	if love.load then love.load(arg) end
	if love.timer then love.timer.step() end
	local dt = 0
	
	-- Main loop time
	while true do
		if love.event then
			love.event.pump()
			for e, a, b, c, d in love.event.poll() do
				if e == "quit" then
					if not love.quit or not love.quit() then
						if love.audio then
							love.audio.stop()
						end
						return
					end
				end
				love.handlers[e](a, b, c, d)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end

		-- will pass 0 if love.timer is disabled
		if love.update then love.update(dt) end

		if love.window and love.graphics and love.window.isCreated() then
			love.graphics.clear()
			love.graphics.origin()
			if love.draw then love.draw() end
			love.graphics.present()
		end

		-- For what this delay?; http://www.love2d.org/wiki/Talk:love.run; http://love2d.org/forums/viewtopic.php?f=4&t=76998
--		if love.timer then love.timer.sleep(0.001) end
	end
end

function love.load(arg)
	if arg[#arg] == "-debug" then require("mobdebug").start() end																							-- ZeroBraneStudio debuger
--	love.graphics.setBackgroundColor(0, 255, 0, 255)
	
	require('math1')
	
	function love.updateScreen()
		if love.window and love.graphics and love.window.isCreated() then
			love.graphics.clear()
			love.graphics.origin()
			if love.draw then love.draw() end
			love.graphics.present()
		end		
	end
	
	w = {}															-- world
	w.size = 1024													-- def = 128
--	w.diag = true													-- diagonal; best false
	w.imd = love.image.newImageData(w.size, w.size)					-- light result
	w.imdDebug = love.image.newImageData(w.size, w.size)
	w.imdObs = love.image.newImageData('obstaclesBig.png')
	w.imdLS = love.image.newImageData('lightSourceBig.png')
	w.im = love.graphics.newImage(w.imd)							-- draw light result
	w.im:setFilter('nearest', 'nearest')
	w.imDebug = love.graphics.newImage(w.imdDebug)
	w.imDebug:setFilter('nearest', 'nearest')	
	w.backg = love.graphics.newImage('background.png')
	w.ls = {}														-- light source
	w.ls.x, w.ls.y = w.size/2-1, w.size/2-1
	w.scc = false													-- start compute cell; false or table
	w.ccc = false													-- current compute cell; false or table
	w.i = 0
	w.loadLight = true
	w.loadObs = true
	-- light energy to color = light energy * 2.55
	
	emit = require('emit')
	givele = require('givele')
	takele = require('takele')
	
	for x=0, w.size-1 do											-- matrix
		w[x] = {}
		for y=0, w.size-1 do
			w[x][y] = {}											-- cell
			w[x][y].x = x
			w[x][y].y = y
			w[x][y].on = true										-- in shader: red color
			w[x][y].giveled = 0										-- light energy is gived; number of times; in shader: green color			
			w[x][y].le = 0											-- light energy emit; 0...; in shader: blue color
			w[x][y].givele = givele
			w[x][y].takele = takele
			w[x][y].emit = emit
		end		
	end
	
	-- shader ------------------------------------------------------------------------------------------------------
	w.shader = {}
	w.shader.m = {}													-- matrix
	w.shader.m.imd = love.image.newImageData(w.size, w.size)
	w.shader.m.im = love.graphics.newImage(w.shader.m.imd)
	w.shader.m.im:setFilter('nearest', 'nearest')
	w.shader.main = love.graphics.newShader('main.glsl')
	w.shader.toBaW = love.graphics.newShader('toBaW.glsl')			-- to black and white
	w.shader.canvas = {}
	w.shader.canvas[1] = love.graphics.newCanvas(w.size, w.size, 'hdr')
	w.shader.canvas[1]:setFilter('nearest', 'nearest')
	w.shader.canvas[2] = love.graphics.newCanvas(w.size, w.size, 'hdr')
	w.shader.canvas[2]:setFilter('nearest', 'nearest')
	w.shader.canvas.i = 1
	
	
	-- turn on cells
	w.shader.m.imd:mapPixel(function(x, y, r, g, b, a)
		return 255, 0, 0, 255
	end)	
--	w.shader.m.im:refresh()
	
	-- flash light ----------------------------------------------------------------------------------------------------
	-- TODO + исправить прозрачность, где нету света
	w.iEmits = 1
	-- light texture
	if w.loadLight then
		w.imdLS:mapPixel(function(x, y, r, g, b, a)
			local mr, mg, mb, ma = w.shader.m.imd:getPixel(x, y)
			if r > 0 and g > 0 and b > 0 and a > 0 then
				w.ls.x, w.ls.y = x, y
				w[x][y].le = b*1.0/1.0
				w.imd:setPixel(x, y, b, b, b, 255)
				
				w.shader.m.imd:setPixel(x, y, mr, mg, b, 255)
			else
				w.imd:setPixel(x, y, 0, 0, 0, 255)
				
				w.shader.m.imd:setPixel(x, y, mr, mg, 0, 255)
			end
			return r, g, b, 255
		end)
	else
		-- линии
		-- сверху слева направо 
		for x=0, w.size-1 do
			w.scc = w[x][0]
			w.ls.x, w.ls.y = w.scc.x, w.scc.y
			w.scc.le = 250		
			w.imd:setPixel(w.scc.x, w.scc.y, w.scc.le, w.scc.le, w.scc.le, 255)
		end
--		-- слева сверху вниз
--		for y=0, w.size-1 do
--			w.scc = w[0][y]
--			w.ls.x, w.ls.y = w.scc.x, w.scc.y
--			w.scc.le = 250		
--			w.imd:setPixel(w.scc.x, w.scc.y, w.scc.le, w.scc.le, w.scc.le, 255)
--		end		
		
		-- point
		w.ls.x, w.ls.y = 0, 0
		w.scc = w[w.ls.x][w.ls.y]
		w.scc.le = 250
		w.imd:setPixel(w.scc.x, w.scc.y, w.scc.le, w.scc.le, w.scc.le, 255)
		w.im:refresh()		
	end	
	w.im:refresh()

	
	w.ls.x, w.ls.y = 0, 0
	print("w.ls.x, w.ls.y:", w.ls.x, w.ls.y)
	
	-- obstacles ----------------------------------------
	if w.loadObs then
		w.imdObs:mapPixel(function(x, y, r, g, b, a)
			if r == 0 and g == 0 and b == 0 then
				w[x][y].on = false
				
				local mr, mg, mb, ma = w.shader.m.imd:getPixel(x, y)
				w.shader.m.imd:setPixel(x, y, 0, mg, mb, 255)
			end
			return r, g, b, 255
		end)
	end
	
	w.shader.m.im:refresh()
--	w.shader.main:send('matrix', w.shader.m.im)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setCanvas(w.shader.canvas[w.shader.canvas.i])
	love.graphics.draw(w.shader.m.im)
	love.graphics.setCanvas()
	
	-- compute from center light; for matrix ------------------------------------------------------------
--	emit(w[w.ls.x][w.ls.y])
	w.ls.x, w.ls.y = w.size/2-1, w.size/2-1
	
	w.cfcl = {}						-- compute from center light; for matrix
	w.cfcl.size = 2					-- +2 every step
	w.cfcl.start = {}
	w.cfcl.start.x = w.ls.x-1		-- -1  every step
	w.cfcl.start.y = w.ls.y-1
	
end

function love.keypressed(key)
	if key == ' ' then
		w.imd:mapPixel(function(x, y, r, g, b, a)
			w[x][y].le = 0
			w[x][y].giveled = 0
			return 0, 0, 0, a
		end)
		-- light texture
		if w.loadLight then
			w.imdLS:mapPixel(function(x, y, r, g, b, a)
				if r > 0 and g > 0 and b > 0 then
					w.ls.x, w.ls.y = x, y
					w[x][y].le = b*1.0/1.0
					w.imd:setPixel(x, y, b, b, b, 255)
				end
				return r, g, b, a
			end)
		end	
		w.i = 0
		w.iEmits = 1															-- iterations
		w.iEmitsPast = 0		
		
		-- flash light
--		w.scc = w[w.ls.x][w.ls.y]
--		w.scc.le = 250
--		w.imd:setPixel(w.scc.x, w.scc.y, w.scc.le, w.scc.le, w.scc.le, 255)
--		w.im:refresh()
		
		-- compute from center light; for matrix
--		emit(w[w.ls.x][w.ls.y])
		w.cfcl = {}						-- compute from center light; for matrix
		w.cfcl.size = 2					-- +2 every step
		w.cfcl.start = {}
		w.cfcl.start.x = w.ls.x-1		-- -1  every step
		w.cfcl.start.y = w.ls.y-1	
		
		if config.debug.on then
			w.imdDebug:mapPixel(function(x, y, r, g, b, a)
				return 0, 0, 0, 0
			end)
			w.imDebug:refresh()
		end
	end
end

function love.update(dt)
	
--	emit(w[w.ls.x][w.ls.y])
	
	-- standart
	-- best
	-- если с прошлого раза w.iEmitsPast не изменилась, то свет рассеялся и не нужно выполнять эту операцию
	
--	if not (w.iEmitsPast == w.iEmits) then
--		w.iEmitsPast = w.iEmits
--		for x=0, w.size-1 do--for x=16, 35 do
--			for y=0, w.size-1 do--for y=97, 111 do
--				if 1 then
--					w[x][y]:emit({1, 2, 3, 4, 5, 6, 7, 8}, 5, 'take')
----					w[x][y]:emit({2}, 5, 'take')
----					emitDirectionalLight(w[x][y], {1, 2, 3, 4, 5, 6, 7, 8}, 5)
----					emitDirectionalLight(w[x][y], {8, 7, 6, 5, 4, 1, 3}, 5)
--					w.i = w.i+1
--				end
--			end
--		end
----		w.im:refresh()
--	end
	
	-- standart otherwise
--	for x=w.size-1, 0, -1 do
--		for y=w.size-1, 0, -1 do
--			w[x][y]:emit()
----			w.i = w.i+1
--		end
--	end	
	
	
	-- обработка из центра света, а не по всей матрице каждый цикл
	-- каждый раз увеличиваем размер матрицы, центр которой в центре света
	-- недостатки: появляются резкие линии света, которых нет при стандартном методе; из-за меньшего числа проходов; если свет не по центру, то намного лишние расчеты, т.к. матрица заходит за границы экрана

--	if not (w.iEmitsPast == w.iEmits) then
--		w.iEmitsPast = w.iEmits
--		for x=w.cfcl.start.x, w.cfcl.start.x+w.cfcl.size do
--			for y=w.cfcl.start.y, w.cfcl.start.y+w.cfcl.size do
--				if w[x] and w[x][y] then
--					w[x][y]:emit({1, 2, 3, 4, 5, 6, 7, 8}, 5)
----					w[x][y]:emit({1, 2, 3, 4, 5, 6, 7, 8}, 0, 'absorb', 20)
----					w[x][y]:emit({5}, 0, 'absorb', 20)											-- direct
----					w[x][y]:emit({4, 5, 6}, 0)
--					w.i = w.i+1					
--				end
--			end
--		end
--		w.cfcl.start.x = w.cfcl.start.x-1		-- -1  every step
--		w.cfcl.start.y = w.cfcl.start.y-1	
--		w.cfcl.size = w.cfcl.size+2					-- +2 every step
--	--	print(w.cfcl.start.x)
--	end

	-- test ----------------------------------

end
	
function love.draw()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(w.backg, 0, 0, 0, math.nSA(1024/800, 0.01))
	
	---------------------------------------
	love.graphics.setColor(255, 255, 255, 255)
	
	-- shader
	if w.shader.canvas.i >= 2 then w.shader.canvas.i = 0 end
	w.shader.canvas.i = w.shader.canvas.i + 1
	
	love.graphics.setShader(w.shader.main)
	love.graphics.setCanvas(w.shader.canvas[w.shader.canvas.i])
	
	if w.shader.canvas.i == 1 then
		love.graphics.draw(w.shader.canvas[2])
	else
		love.graphics.draw(w.shader.canvas[1])
	end
--	if love.mouse.isDown('l') then
--		love.graphics.setColor(0, 0, 0, 255)
--		love.graphics.circle('fill', love.mouse.getX()*1.5, love.mouse.getY()*1.5, 10)	
--	end	
	love.graphics.setCanvas()
	love.graphics.setShader()
	
	love.graphics.setShader(w.shader.toBaW)
	love.graphics.draw(w.shader.canvas[w.shader.canvas.i], 0, 0, 0, math.nSA(720/w.size, 0.1))
	love.graphics.setShader()
--	---------
	
	love.graphics.draw(w.im, 0, 0, 0, math.floor(600/w.size))
	love.graphics.draw(w.imDebug, 0, 0, 0, math.floor(600/w.size))
	
--	love.timer.sleep(5)
	---------------------------------------
	
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.print('FPS: '..love.timer.getFPS(), 800, 10)
	love.graphics.print('Press SPACEBAR for reset', 800, 23)
	love.graphics.print('w.i: '..w.i, 800, 34)
	love.graphics.print('w.iEmits: '..w.iEmits, 800, 47)
	love.graphics.print('w.iEmitsPast: '..w.iEmitsPast, 800, 60)
	
end
