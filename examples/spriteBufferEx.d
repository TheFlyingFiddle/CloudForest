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
		buffer = new SpriteBuffer(131072, BufferHint.streamDraw);
		
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

		gl.viewport = uint4(0,0, 512,512);
	}

	override void reshape(int w, int h) { }
	int time = 0;
	override void render(double time2) 
	{
		gl.clearColor(Color(0xFFae1182));
		gl.clear(ClearFlags.color);

		gl.enable(Capability.blend);
		gl.blendState = BlendState.nonPremultiplied;

		buffer.addText(font, "HELLO WORLD!", float2(200,200), Color.white,
							float2.one, float2.zero, 1f);
		buffer.addFrame(Frame(font.page), float2.zero);
		buffer.flush();

		mat4 proj = mat4.CreateOrthographic(0, 512,512,0,1,-1);
		buffer.draw(proj);
		buffer.clear();
	}
}