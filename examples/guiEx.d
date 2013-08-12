module examples.guiEx;

import font;
import gui;
import example;
import math.matrix, math.vector;
import graphics.all;
import utils.image;
import frame;
import input;
import window;
import textureatlas;

class GUIExample : Example
{
	private GUI gui;

	this(MouseEventState mouseState, KeyboardEventState keyState, Clipboard clipboard) 
	{
		auto style = createGUIStyle();
		gui = new GUI(style, mouseState, keyState, clipboard, float4(0,0,1280,720));
	}

	float f0 = 0;
	float f1 = 50;
	float f2 = 100;
	bool t = false;

	string[] tools = ["A", "MONKEY", "CAR", "IS", "BIG", "VERY", "BIG"];
	string[] items = ["Item1", "Item2", "Item3", "Item4", "Item1", "Item2", 
							"Item3", "Item4", "gerte3", "123415", "qweqweqwe", "Item4"];
	uint selectedItem = 0;
	char[] doodle;
	string doodle1;
	uint selected = 0;
	float scrollOffset = 0;
	double number  = 0;
	ulong  number0 = 0;
	float2 vec  = float2.zero;
	float3 vec0 = float3.zero;
	float4 vec1 = float4.zero;

	override void reshape(int w, int h) { }
	override void render(double time) 
	{
		import std.stdio;

		gl.clearColor(Color.black);
		gl.clear(ClearFlags.color);

		if(gui.repeatButton(float4(100,100,100,50), "0000")) 
			writeln("Hello sir dude! 0000");

		if(gui.button(float4(100,250,100,50), "11011")) 
			writeln("Hello sir dude! 1111");

		if(gui.button(float4(250,100,100,50), "22202")) 
			writeln("Hello sir dude! 2222");

		if(gui.button(float4(250,250,100,50), "33033")) 
			writeln("Hello sir dude! 3333");

		if(gui.hslider(float4(100,50,200,10), f0))
			writeln("Horizontal slider value changed! ", f0);

		if(gui.vslider(float4(20,100,10,200), f1))
			writeln("Vertical slider value changed!", f1);

		if(gui.toolbar(float4(20, 450, 60, 40), selected, tools))
			writeln("Toolbar changed!");

		if(gui.textField(float4(100, 400, 200, 32), doodle))
			writeln(doodle);

		if(gui.toggle(float4(100,325,100,50), t, "Boxeru"))
			writeln("Toggle changed! ", t);

		gui.label(float4(250,310, 200, 20), "I AM SLIDER DERP DERP");

		if(gui.listbox(float4(400, 100, 100, 200), selectedItem, scrollOffset, items)) 
			writeln("Selected item changed!", selectedItem, " ", items[selectedItem]);

		if(gui.numberField(float4(100, 500, 200, 32), number)) 
			writeln("Number changed! ",number); 		

		if(gui.numberField(float4(100, 600, 200, 32), number0)) 
			writeln("Number changed! ",number0); 		

		if(gui.vector2Field(float4(600, 420, 300, 32), vec))
			writeln("Vector changed!", vec);

		if(gui.vector3Field(float4(600, 460, 300, 32), vec0)) 
			writeln("Vector3 changed!", vec0);

		if(gui.vector4Field(float4(600, 500, 300, 32), vec1))
			writeln("Vector4 changed!", vec1);

		if(gui.button(float4(600, 380, 300, 32), "Hello"))
			writeln("Random button");

		mat4 proj = mat4.CreateOrthographic(0, 1280,720,0,1,-1);
		gui.draw(proj); 
	}


	auto createGUIStyle()
	{
		auto textureAtlas = TextureAtlas.load("resources/CoolSheet");
		auto font = Font.load("resources/Frooty.fnt", textureAtlas["Frooty"]);

		auto pixel   = textureAtlas["pixel"];
		auto check   = textureAtlas["20130204-Checkbox"];
		auto uncheck = textureAtlas["20130204-Uncheckbox"]; 

		Color normal	 = Color(0xFF888888);
		Color highlight = Color(0xFFcccccc);
		Color down		 = Color(0xFF444444);
		Color textColor = Color(0xFFFFFFFF);

		auto bstyle			 = new ButtonStyle();
		bstyle.down		    = TintedFrame(pixel, down);
		bstyle.highlight   = TintedFrame(pixel, highlight);
		bstyle.normal      = TintedFrame(pixel, normal);
		bstyle.textColor   = textColor;
		bstyle.font		    = font;
		bstyle.iconDim	    = float4(0.25f,0.25f,0.5f,0.5f);
		bstyle.textPadding = float4(5, 5, 5, 5);
		bstyle.iconColor	 = Color.white;

		auto toggle				= new ToggleStyle();
		toggle.toggleFrame	= check;
		toggle.untoggleFrame = uncheck;
		toggle.color			= normal;
		toggle.textColor		= textColor;
		toggle.textPadding	= float4(5,5, 5, 5);
		toggle.font				= font;

		auto textfield					= new TextfieldStyle();
		textfield.background		   = TintedFrame(pixel, normal);
		textfield.cursor				= TintedFrame(pixel, Color.black);
		textfield.textColor			= textColor;
		textfield.font					= font;
		textfield.textPadding		= float4(5,5, 5,5);

		auto	slider			= new SliderStyle();
		slider.active			= TintedFrame(pixel, normal);
		slider.inactive		= TintedFrame(pixel, normal);
		slider.normal			= TintedFrame(pixel, down);
		slider.highlight		= TintedFrame(pixel, highlight);

		auto label		  = new LabelStyle();
		label.font		  = font;
		label.textColor  = textColor;

		auto listBox		  = new ListboxStyle();
		listBox.background  = TintedFrame(pixel, down);
		listBox.stripe0	  = TintedFrame(pixel, highlight);
		listBox.stripe1	  = TintedFrame(pixel, normal);
		listBox.selected	  = TintedFrame(pixel, Color(0xFFFFaaaa));
		listBox.slider		  = slider;
		listBox.font		  = font;
		listBox.textColor	  = textColor;
		listBox.textPadding = float4(5,1, 5,5);
		listBox.sliderSize  = 12;

		return GUIStyle(bstyle, bstyle, toggle, textfield, slider, slider, label, listBox);
	}
}