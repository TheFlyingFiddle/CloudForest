module examples.guiEx;

import font;
import gui;
import example;
import math.matrix, math.vector;
import graphics.all;

class GUIExample : Example
{
	private GUI gui;
	private Font font;

	this(MouseEventState state) 
	{
		font = Font.load("resources/Metro.fnt");
		gui = new GUI(font);
		gui.mouseEventState = state;
	}

	float f0 = 0;
	float f1 = 50;
	float f2 = 100;
	override void reshape(int w, int h) { }
	override void render(double time) 
	{
		gl.clearColor(Color.white);
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

		mat4 proj = mat4.CreateOrthographic(0, 512,512,0,1,-1);
		gui.draw(proj);
	}
}