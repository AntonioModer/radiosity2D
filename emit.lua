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

w.iEmits = 0															-- iterations
w.iEmitsPast = 0

local function drawCell(cell)
	if cell.le > 255 then
		w.imd:setPixel(cell.x, cell.y, 255, 255, 255, 255)
	elseif cell.le < 0 then
		w.imd:setPixel(cell.x, cell.y, 0, 0, 0, 255)
	else
		w.imd:setPixel(cell.x, cell.y, cell.le , cell.le , cell.le , 255)			
	end
end

--[[
HELP:
	+ ldir - table; light directions, описывает направления излучения света
		+ examples: {1, 2, 3, 4, 5, 6, 7, 8}; {2, 4, 6, 8}
	+ obsType = 'absorb' or 'reflective'; def = 'reflective'
		+ 'absorb' is NOT DONE !!!
	+ losesE - loses energy when obsType is absorb
	+ method = 'give' or 'take'; def='give'
TODO:
	+ ldir доделать
	+ простое переключение 2-х способов: givele и takele
--]]
local function emit(cell, ldir, lowPow, method, obsType, losesE)
	if not cell.on then return false end
	
	if config.debug.on then
		w.imdDebug:mapPixel(function(x, y, r, g, b, a)
			return 0, 0, 0, 0
		end)
		w.imdDebug:setPixel(cell.x, cell.y, 0, 0, 255, 200)
		w.imDebug:refresh()
		
--		love.timer.sleep(0.1)
		love.updateScreen()		
	end
	
	method = method or 'give'
	
	if method == 'take' then
		if cell.le > 0 then return false end			-- for takele
	else
		if cell.le == 0 then return false end			-- for givele
	end
	
	if method == 'give' then
		-- оптимизация
		-- если нету, то долго считаем, может даже и бесконечно
		-- если есть, то появляются артефакты и не до-расчитывается свет
		-- при takele отключаем
		local max = 8												-- чем больше, тем мягче тени, и больше расчетов
		if not w.diag then max = 4 end
		if cell.giveled >= max then return false end
	end

	local ccc;													-- current compute cell
	local lowPow = lowPow or 2											-- lower power; 0...; def=2	
	local losesE = losesE or 50
	
	-- при столкновении с препятствием свет теряет энергию (поверхность дифузная и полглощает свет)
	-- если свет не теряет энергию, то он полность отражается от поверхности (поверхность-зеркало)
	-- можно сделать прозрачные препятствия
	-- TODO: -NO проверка ccc.on перенести в givele()
	-- тут описаны направления и последовательность перемещения света
	-- TODO: + параметры для указания направления света
	-- TODO: + сначала провести расчеты, а затем рисовать пиксели
	--[[
		O O O
		O x O
		O O O
		
		последовательность:
		1 2 3
		8 x 4
		7 6 5
		
		x - light emited cell
		O - give light energy to this cell
	--]]
	
	-- compute
	local diagLowPowTypeDist = true
	for i=1, #ldir do
		if ldir[i] == 1 and w.diag and w[cell.x-1] then  
			ccc = w[cell.x-1][cell.y-1]
			if ccc then
				if ccc.on then
					if method == 'take' then
						cell:takele(ccc, true, lowPow, diagLowPowTypeDist)
					else
						cell:givele(ccc, true, lowPow, diagLowPowTypeDist)
						drawCell(ccc)
					end
				elseif obsType == 'absorb' then
					cell.le = cell.le - losesE
				end
			end
		end
		
		if ldir[i] == 2 and w[cell.x] then  
			ccc = w[cell.x][cell.y-1]
			if ccc then
				if ccc.on then
					if method == 'take' then
						cell:takele(ccc, false, lowPow, diagLowPowTypeDist)
					else
						cell:givele(ccc, false, lowPow, diagLowPowTypeDist)
						drawCell(ccc)
					end
				elseif obsType == 'absorb' then
					cell.le = cell.le - losesE
				end
			end
		end
		
		if ldir[i] == 3 and w.diag and w[cell.x+1] then  
			ccc = w[cell.x+1][cell.y-1]
			if ccc then
				if ccc.on then
					if method == 'take' then
						cell:takele(ccc, true, lowPow, diagLowPowTypeDist)
					else
						cell:givele(ccc, true, lowPow, diagLowPowTypeDist)
						drawCell(ccc)
					end
				elseif obsType == 'absorb' then
					cell.le = cell.le - losesE
				end
			end
		end
		
		if ldir[i] == 4 and w[cell.x+1] then  
			ccc = w[cell.x+1][cell.y]
			if ccc then
				if ccc.on then
					if method == 'take' then
						cell:takele(ccc, false, lowPow, diagLowPowTypeDist)
					else
						cell:givele(ccc, false, lowPow, diagLowPowTypeDist)
						drawCell(ccc)
					end
				elseif obsType == 'absorb' then
					cell.le = cell.le - losesE
				end
			end
		end
		
		if ldir[i] == 5 and w.diag and w[cell.x+1] then  
			ccc = w[cell.x+1][cell.y+1]
			if ccc then
				if ccc.on then
					if method == 'take' then
						cell:takele(ccc, true, lowPow, diagLowPowTypeDist)
					else
						cell:givele(ccc, true, lowPow, diagLowPowTypeDist)
						drawCell(ccc)
					end
				elseif obsType == 'absorb' then
					cell.le = cell.le - losesE
				end
			end
		end
		
		if ldir[i] == 6 and w[cell.x] then  
			ccc = w[cell.x][cell.y+1]
			if ccc then
				if ccc.on then
					if method == 'take' then
						cell:takele(ccc, false, lowPow, diagLowPowTypeDist)
					else
						cell:givele(ccc, false, lowPow, diagLowPowTypeDist)
						drawCell(ccc)
					end
				elseif obsType == 'absorb' then
					cell.le = cell.le - losesE
				end
			end
		end
		
		if ldir[i] == 7 and w.diag and w[cell.x-1] then  
			ccc = w[cell.x-1][cell.y+1]
			if ccc then
				if ccc.on then
					if method == 'take' then
						cell:takele(ccc, true, lowPow, diagLowPowTypeDist)
					else
						cell:givele(ccc, true, lowPow, diagLowPowTypeDist)
						drawCell(ccc)
					end
				elseif obsType == 'absorb' then
					cell.le = cell.le - losesE
				end
			end
		end
		
		if ldir[i] == 8 and w[cell.x-1] then  
			ccc = w[cell.x-1][cell.y]
			if ccc then
				if ccc.on then
					if method == 'take' then
						cell:takele(ccc, false, lowPow, diagLowPowTypeDist)
					else
						cell:givele(ccc, false, lowPow, diagLowPowTypeDist)
						drawCell(ccc)
					end
				elseif obsType == 'absorb' then
					cell.le = cell.le - losesE
				end
			end
		end
		
		if method == 'take' then
			drawCell(cell)				-- for takele
		end
		
		w.im:refresh()
		
	end
	
	
	w.iEmits = w.iEmits+1
	
end

return emit