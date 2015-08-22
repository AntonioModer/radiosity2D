--[[
HELP:
	+ diagLowPowTypeDist = boolean
TODO:
	+ 
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

local function givele(self, to, diag, lowPow, diagLowPowTypeDist, forcibly)										-- give light energy
		
	if config.debug.on then
		w.imdDebug:mapPixel(function(x, y, r, g, b, a)
			return 0, 0, 0, 0
		end)
		w.imdDebug:setPixel(self.x, self.y, 0, 0, 255, 200)
		w.imdDebug:setPixel(to.x, to.y, 0, 0, 255, 100)
		w.imDebug:refresh()
		
--		love.timer.sleep(0.1)
		love.updateScreen()		
	end
	
	self.giveled = self.giveled+1
	if not forcibly then																									-- если принудительно указываем, то не сравниваем
		if (not (self.le > to.le)) or self.le == to.le then return false end
	end
	-- если с расстоянием свет не должен теряться (lowPow=nil or 0...) - значит это directonal свет; иначе point или spot
	local lowPow = lowPow																									-- lower power
	if diag and diagLowPowTypeDist then
		lowPow = math.nSA(math.dist(self.x,self.y, to.x,to.y)*lowPow, 0.001)					-- lowPow or math.nSA(math.dist(self.x,self.y, to.x,to.y)*lowPow, 0.01)
	end
	
	if not diag then
--		self.le = self.le - lowPow
--		to.le = to.le+lowPow
		
		to.le = self.le - lowPow
	else
		if w.diag then
--			self.le = self.le - lowPow									-- if turn of this diagonals, then light will draw like rotaded box in 90 deg; otherwise not rotaded box
--			to.le = to.le+lowPow
			
			to.le = self.le - lowPow
		else
			return false
		end
	end
	
	if config.debug.on then
		w.imdDebug:setPixel(to.x, to.y, 0, 0, 255, 150)
		w.imDebug:refresh()
		
--		love.timer.sleep(0.1)
		love.updateScreen()		
	end				
	
end
	
return givele