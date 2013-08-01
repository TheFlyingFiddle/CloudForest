module examples.guiEx;

import font;
import gui;
import example;
import math.matrix, math.vector;
import graphics.all;
import utils.image;
import frame;

class GUIExample : Example
{
	private GUI gui;
	private Font font;

	this(MouseEventState mouseState, KeyboardEventState keyState) 
	{
		auto pngLoader = new PngLoader();

		auto image = pngLoader.load("resources/Checkbox.png");
		pngLoader = new PngLoader();
		auto image2 = pngLoader.load("resources/Uncheckbox.png");

		auto tex0 = Texture2D.create(image, InternalFormat.rgba8);
		auto tex1 = Texture2D.create(image2, InternalFormat.rgba8);

		font = Font.load("resources/Metro.fnt");
		gui = new GUI(font, Frame(tex0), Frame(tex1));
		gui.mouseEventState = mouseState;
		gui.keyEventState	  = keyState;
	}

	float f0 = 0;
	float f1 = 50;
	float f2 = 100;
	bool t = false;

	string[] tools = ["A", "MONKEY", "CAR", "IS", "BIG", "VERY", "BIG"];
	string doodle;
	string doodle1;
	uint selected = 0;

	override void reshape(int w, int h) { }
	override void render(double time) 
	{
		gl.clearColor(Color.black);
		gl.clear(ClearFlags.color);

		if(gui.repeatButton(float4(100,100,100,50), "0000")) 
			std.stdio.writeln("Hello sir dude! 0000");

		if(gui.button(float4(100,250,100,50), "1111")) 
			std.stdio.writeln("Hello sir dude! 1111");

		if(gui.button(float4(250,100,100,50), "2222")) 
			std.stdio.writeln("Hello sir dude! 2222");

		if(gui.button(float4(250,250,100,50), "3333")) 
			std.stdio.writeln("Hello sir dude! 3333");

		f0 = gui.hslider(float4(100,50,200,10), f0);
		f1 = gui.vslider(float4(20,100,10,200), f1);

		gui.label(float4(250,310, 200, 20), "I AM SLIDER DERP DERP");

		selected = gui.toolbar(float4(20, 450, 60, 40), selected, tools);

		auto o = t;
		t = gui.toggle(float4(100,325,32,32), t, "I AM A STUPID COMBO BOX");
		if(t != o) 
			std.stdio.writeln("noo");

		doodle = gui.textField(float4(100, 400, 200, 32), doodle);
		doodle1 = gui.textField(float4(100, 360, 200, 32), doodle1);

		mat4 proj = mat4.CreateOrthographic(0, 512,512,0,1,-1);
		gui.draw(proj);
	}
}