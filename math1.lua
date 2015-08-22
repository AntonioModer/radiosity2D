--[[
version 0.0.1
--]]

--[[
C - Data Type

Type 			Storage size 		Value range 				Precision
double 			8 byte 				2.3E-308 to 1.7E+308 		15 decimal places
-------------------------------------------------------------------------------------
Lua number = double

max number is 1.79e+308
min number is 9.9e-323
----------------------------------------
print(math.huge == 1.79e+309)	--> true
--]]

--[[
print(string.format("%e", 100000000000000))   --> 1.000000e+014
print(string.format("%f", 100000000000000))   --> 100000000000000.000000

print(string.format("%e", 100000000000000.5)) --> 1.000000e+014
print(string.format("%f", 100000000000000.5)) --> 100000000000000.500000
--]]

--[[
-- simple FIFO example
tab = {}
table.insert(tab, 1)																				-- добавляет значение в конец таблицы tab
var = table.remove(tab, 1)																			-- Удаляет из table элемент в позиции 1, сдвигая вниз остальные элементы, если это необходимо. Возвращает значение удаленного элемента
--]]

--[[
-- example
if math.fmod(x, 16) ~= 0 then																		-- координата x кратна 16 (деление без остатка)
end
--]]

--[[
version 1.0.0
HELP:
	+ возвращает число с указанной точность, returns number with a specified accuracy
	+ return lower number
	+ также смотри math.stickToEdge()
EXAMPLE:
	print(math.nSA(0.123456789, 1))				--> 0
	print(math.nSA(0.123456789, 0.1))			--> 0.1
	print(math.nSA(0.123456789, 0.000000001))	--> 0.123456789
	print(math.nSA(31, 64))						--> 0
	print(math.nSA(65, 64))						--> 64
--]]
function math.nSA(x, accuracy)																		-- number specified accuracy
	if accuracy == 0.000000001 then																	-- anti bug
		accuracy = 0.0000000001
	end
	return x - (x % accuracy)
end

-- return the integral part of x --
-- examples:
--  print(nIP(0.23))				--> 0
function math.nIP(x)
	local integral, fractional = math.modf(x)
	return integral
end

-- return the fractional part of x --
-- examples:
--  print(nFP(0.23))				--> 0
function math.nFP(x)
	local integral, fractional = math.modf(x)
	return fractional
end

-- определяет четное число или нет
-- return true/false
function math.even(x)
    return x%2 == 0
end

-- Returns 1 if number is positive, -1 if it's negative, or 0 if it's 0.
function math.sign(n) 
	return n>0 and 1 or n<0 and -1 or 0 
end

--[[
version 2.0.0
HELP:
	+!!! не нужна, вместо этой функции использовать math.nSA()
	+ stick to edge
	+ return lower (left-buttom) coordinate
	+ coordinate - x or y
--]]
function math.stickToEdge(coordinate, step)
	-- v1
--	local math = math
--	if math.fmod(coordinate, step) ~= 0 then																	-- координата кратна step (деление без остатка)
--		if (math.ceil(coordinate/step)*step) < step then
--			return (math.ceil(coordinate/step)*step)-step
--		else
--			return (math.floor(coordinate/step)*step)
--		end
--	end
--	return coordinate

	-- v2
--	return math.floor( coordinate / step ) * step

	-- v3	
	return coordinate - (coordinate % step)
end

-- Returns the distance between two points. 
function math.dist(x1,y1, x2,y2)
	return ((x2-x1)^2+(y2-y1)^2)^0.5 
end