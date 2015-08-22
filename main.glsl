/*
	HELP:
		+ 2 действия за проход:
			+ сначало рисуем на matrix
			+ чтобы отобразить конечный результат, русуем на конечной текстуре
		w[x][y].on = true										-- in shader: red color		
		w[x][y].le = 0											-- light energy emit; 0...; in shader: blue color
		+ тут не получиться
*/
/*
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
*/

//extern Image matrix;
//extern Image light, obstacles;
//int iEmits = 1, iEmitsPast = 0;
number textureSize = 128.0-1.0;

/*
	HELP:
		+ тут не получиться отдавать энергию соседней ячейке напрямую
	TODO:
		-+ можно попробовать наоборот: принимать свет с соседних ячеек
*/
number takele(number fromColorB, number toColorB, number lowPow) {
	
	if (fromColorB == toColorB) { return toColorB; }
	if ( !(toColorB < fromColorB) ) { return toColorB; }
	
	toColorB = fromColorB - lowPow;
	
	return toColorB;
}

// for help
//number toNormalizedCoord(number notNormalizedTexCoord, number texSize) {
	//return notNormalizedTexCoord/texSize;
//}

vec4 emit(Image matrix, vec2 cellNormCoord, number lowPow) {
	vec4 cellColor = Texel(matrix, cellNormCoord);
	
	if ( !(cellColor.r > 0.0) ) { return cellColor; }
	if (cellColor.b > 0.0) { return cellColor; }
	
	/*
		compute
		Top-down view
		
		O O O
		O x O
		O O O
		
		последовательность:
		1 2 3
		8 x 4
		7 6 5
		
		x - light emited cell
		O - give light energy to this cell
	*/
	
	vec4 cccColor;																	// current compute cell
	vec2 cccNormCoord;
	vec2 cellMatrixCoord = vec2(textureSize*cellNormCoord.x, textureSize*cellNormCoord.y);
/**/
	// 2
	if (cellMatrixCoord.y-1.0 > -1.0) {
		cccNormCoord = vec2(cellNormCoord.x, (cellMatrixCoord.y-1.0)/textureSize);
		cccColor = Texel(matrix, cccNormCoord);										// [cell.x][cell.y-1]
		if (cccColor.r > 0.0) {														// ccc.on
			cellColor.b = takele(cccColor.b, cellColor.b, lowPow);
		}
	}

	// 4
	if (cellMatrixCoord.x+1.0 < textureSize) {
		cccNormCoord = vec2((cellMatrixCoord.x+1.0)/textureSize, cellNormCoord.y);
		cccColor = Texel(matrix, cccNormCoord);										// [cell.x+1][cell.y]
		if (cccColor.r > 0.0) {														// ccc.on
			cellColor.b = takele(cccColor.b, cellColor.b, lowPow);
		}
	}
	
	// 6
	if (cellMatrixCoord.y+1 < textureSize) {
		cccNormCoord = vec2(cellNormCoord.x, (cellMatrixCoord.y+1.0)/textureSize);
		cccColor = Texel(matrix, cccNormCoord);										// [cell.x][cell.y+1]
		if (cccColor.r > 0.0) {														// ccc.on
			cellColor.b = takele(cccColor.b, cellColor.b, lowPow);
		}
	}

	// 8
	if (cellMatrixCoord.x-1 > -1) {
		cccNormCoord = vec2((cellMatrixCoord.x-1.0)/textureSize, cellNormCoord.y);
		cccColor = Texel(matrix, cccNormCoord);										// [cell.x-1][cell.y]
		if (cccColor.r > 0.0) {														// ccc.on
			cellColor.b = takele(cccColor.b, cellColor.b, lowPow);
		}
	}	 	
/**/
	
	return cellColor;
}

vec4 effect(vec4 color, Image texture, vec2 texCoord, vec2 screenCoord) {
	vec4 pixel = Texel(texture, texCoord);										// This is the current pixel color
	
	pixel = emit(texture, texCoord, 0.02);
	
	return pixel;
}