module examples.spriteBufferEx;

import SpriteBuffer;
import frame;
import font;
import math.matrix;
import graphics.context;
import graphics.texture;
import graphics.enums;
import graphics.color;
import math.vector;

import example;
import utils.image;

class SpriteBufferExample : Example
{
	SpriteBuffer buffer;
	Frame frame;
	Font font;

	this() 
	{
		buffer = new SpriteBuffer(512);
		
		font = Font.load("resources/test.fnt");
		uint width, height;
		auto png = new PngLoader();
		auto data = png.load("resources/PngTest.png", width, height);
		auto texture = Texture2D.create(ColorFormat.rgba, 
											ColorType.ubyte_, 
											InternalFormat.rgba8,
											width, height, data,
											No.generateMipMaps);

		frame = Frame(texture);
	}

	override void reshape(int w, int h) { }
	int time = 0;
	override void render(double time2) 
	{
		gl.clearColor(Color.black);
		gl.clear(ClearFlags.color);

		foreach(i; 0 .. 100) 
		{
			auto x = std.random.uniform(0, 500);
			auto y = std.random.uniform(0, 500);

			buffer.addFrame(frame, float2(x,y));
		}
		
		mat4 proj = mat4.CreateOrthographic(0, 512,512,0,0,0);
		buffer.flush();
		buffer.draw(proj);

		buffer.clear();
	}
}