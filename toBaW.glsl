vec4 effect(vec4 color, Image texture, vec2 texCoord, vec2 screenCoord) {
	vec4 pixel = Texel(texture, texCoord);										// This is the current pixel color
	
	pixel.r = pixel.b;
	pixel.g = pixel.b;
	
	return pixel;
}