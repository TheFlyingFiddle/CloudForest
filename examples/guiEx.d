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

	this(MouseEventState mouseState, KeyboardEventState keyState) 
	{

		auto style = createGUIStyle();

		gui = new GUI(style);
		gui.mouseEventState = mouseState;
		gui.keyEventState	  = keyState;
	}

	float f0 = 0;
	float f1 = 50;
	float f2 = 100;
	bool t = false;

	string[] tools = ["A", "MONKEY", "CAR", "IS", "BIG", "VERY", "BIG"];
	string[] items = ["Item1", "Item2", "Item3", "Item4"];
	uint selectedItem = 0;
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

		if(gui.button(float4(100,250,100,50), "11011")) 
			std.stdio.writeln("Hello sir dude! 1111");

		if(gui.button(float4(250,100,100,50), "22202")) 
			std.stdio.writeln("Hello sir dude! 2222");

		if(gui.button(float4(250,250,100,50), "33033")) 
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
		//doodle1 = gui.textField(float4(100, 360, 200, 32), doodle1);
//
		//selectedItem = gui.combobox(float4(370, 250, 100, 32), selectedItem,  items); 


		mat4 proj = mat4.CreateOrthographic(0, 512,512,0,1,-1);
		gui.draw(proj);
	}


	auto createGUIStyle()
	{
		Color[1] color = [Color.white];
		auto pixel = Frame(Texture2D.create(ColorFormat.rgba,
												 ColorType.ubyte_,
												 InternalFormat.rgba8,
												 1,1, cast(void[])color, Flag!"generateMipMaps".no ));
		auto font = Font.load("resources/Metro.fnt");

		Color normal	 = Color(0xFF888888);
		Color highlight = Color(0xFFcccccc);
		Color down		 = Color(0xFF444444);
		Color textColor = Color(0xFFFFFFFF);

		ButtonStyle bstyle = new ButtonStyle();
		bstyle.down		    = ButtonStateStyle(pixel, down);
		bstyle.highlight   = ButtonStateStyle(pixel, highlight);
		bstyle.normal      = ButtonStateStyle(pixel, normal);
		bstyle.textColor   = textColor;
		bstyle.font		    = font;
		bstyle.iconDim	    = float4(0.25f,0.25f,0.5f,0.5f);
		bstyle.textPadding = float2(5, 5);
		bstyle.iconColor	 = Color.white;

		auto pngLoader = new PngLoader();
		auto image = pngLoader.load("resources/Checkbox.png");
		auto image2 = pngLoader.load("resources/Uncheckbox.png");
		auto tex0 = Texture2D.create(image, InternalFormat.rgba8);
		auto tex1 = Texture2D.create(image2, InternalFormat.rgba8);

		ToggleStyle toggle   = new ToggleStyle();
		toggle.toggleFrame	= Frame(tex0);
		toggle.untoggleFrame = Frame(tex1);
		toggle.color			= normal;
		toggle.textColor		= textColor;
		toggle.textPadding	= float2(5,5);
		toggle.font				= font;

		TextfieldStyle textfield   = new TextfieldStyle();
		textfield.background		   = pixel;
		textfield.backgroundColor	= normal;
		textfield.textColor			= textColor;
		textfield.font					= font;
		textfield.textPadding		= float2(5,5);
		textfield.cursorColor		= Color.black;
		textfield.cursorFrame		= pixel;

		SliderStyle	slider	= new SliderStyle();
		slider.activeFrame   = pixel;
		slider.inactiveFrame = pixel;
		slider.activeColor	= normal;
		slider.inactiveColor	= normal;
		slider.normal			= ButtonStateStyle(pixel, down);
		slider.highlight		= ButtonStateStyle(pixel, highlight);

		return GUIStyle(bstyle, bstyle, toggle, textfield, slider, slider);
	}
}