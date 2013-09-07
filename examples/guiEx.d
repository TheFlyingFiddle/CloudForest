module examples.guiEx;

import font;
import example;
import math.matrix, math.vector;
import graphics.all;
import utils.image;
import frame;
import input;
import window;
import textureatlas;

import ui.gui;
import ui.button;
import ui.pannel;
import ui.renderer;
import ui.common;
import math.rect;

class GUIExample : Example
{
	private GUI gui;
	private Sampler sampler;

	this(MouseEventState mouseState, KeyboardEventState keyState, Clipboard clipboard) 
	{
		gui = new GUI(new GUIRenderer(), Rect(0,0, 1280, 720), mouseState, keyState);
		sampler = new Sampler();
		sampler.minFilter = TextureMinFilter.nearest;
		sampler.magFilter = TextureMagFilter.nearest;

		auto textureAtlas = TextureAtlas.load("resources/CoolSheet");
		auto font = Font.load("resources/Frooty.fnt", textureAtlas["Frooty"]);
		auto pixel = textureAtlas["pixel"];

		Color normal	 = Color(0xFF888888);
		Color highlight = Color(0xFFcccccc);
		Color down		 = Color(0xFF444444);
		Color textColor = Color(0xFFFFFFFF);

		
		ButtonSettings bs;
		bs.text = "Hello";

		ButtonStyle style;
		style.normal  = ColoredFrame(normal, pixel);
		style.hover   = ColoredFrame(highlight, pixel);
		style.focused = ColoredFrame(down, pixel);
		style.pressed = ColoredFrame(Color(0xFFaacc11), pixel);
		style.textStyle = TextStyle(textColor, font);

		auto panelID = gui.c!Pannel(Rect(500, 200, 400, 400), ColoredFrame(Color(0xFF13a2ce), pixel));

		auto buttonID = gui.c!Button(panelID, Rect(200,100,100,30), bs, style);
		gui.click(buttonID, &hurdur);
		gui.mouseEnter(buttonID, () { std.stdio.writeln("Mouse Enter"); });
		gui.mouseExit(buttonID, () { std.stdio.writeln("Mouse Exit"); });
		gui.mouseStay(buttonID, () { std.stdio.writeln("Mouse Stay"); });
		gui.keyPress(buttonID, (Key k, KeyModifier m) => std.stdio.writeln("Key was pressed ", k, " with modifiers ", m) );
		gui.keyRelease(buttonID, (k, m) => std.stdio.writeln("Key was released ", k, " with modifiers ", m) );

		gui.c!Button(Rect(200,600,100,30), bs, style);
	}

	void hurdur()
	{
		std.stdio.writeln("Hurr durr pbur bur");
	}


	override void reshape(int w, int h) { }
	override void render(double time) 
	{
		import std.stdio;

		gl.clearColor(Color.black);
		gl.clear(ClearFlags.color);
		gl.sampler[0] = sampler;

		gui.process();
		mat4 proj = mat4.CreateOrthographic(0, 1280,720,0,1,-1);
		gui.render(proj); 
	}
}