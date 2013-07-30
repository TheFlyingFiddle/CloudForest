module frame;

import graphics.texture;
import math.vector;

struct Frame
{
	Texture2D texture;
	float4 coords;

	@property uint2 dim() const { return uint2(texture.width, texture.height); } 

	this(Texture2D texture)
	{
		this.texture = texture;
		this.coords = float4(0,0,1,1);
	}

	this(Texture2D texture, float4 coords)
	{
		this.texture = texture;
		this.coords = float4(coords.x / texture.width,
									coords.y / texture.height,
									coords.z / texture.width,
									coords.w / texture.height);
	}
}