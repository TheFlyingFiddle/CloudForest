module gui;

import graphics.texture;
import graphics.enums;
import SpriteBuffer;
import font;
import derelict.glfw3.glfw3;
import math.vector;
import frame;
import graphics.context;
import graphics.color;
import std.traits;
import math.matrix;
import math.helper;
import std.conv;

struct ButtonState
{
	float2 loc;
	bool inState;
}

enum MouseButton
{	
	left	  = GLFW_MOUSE_BUTTON_1,
	rigth   = GLFW_MOUSE_BUTTON_2,
	middle  = GLFW_MOUSE_BUTTON_3,
	x0		  = GLFW_MOUSE_BUTTON_4,
	x1		  = GLFW_MOUSE_BUTTON_5,
	x2		  = GLFW_MOUSE_BUTTON_6,
	x3		  = GLFW_MOUSE_BUTTON_7,
	x4		  = GLFW_MOUSE_BUTTON_8
}

class MouseEventState
{
	ButtonState[GLFW_MOUSE_BUTTON_LAST]  down;
	ButtonState[GLFW_MOUSE_BUTTON_LAST]  up;
	bool[GLFW_MOUSE_BUTTON_LAST]			 changed;

	float2 oldLoc;
	float2 newLoc;
	float2 scrollDelta;

	this()
	{
		down[] = ButtonState(float2.zero, false);
		up[]	 = ButtonState(float2.zero, true);
		changed[] = false;
		oldLoc = float2.zero;
		newLoc = float2.zero;
		scrollDelta = float2.zero;
	}

	bool wasReleased(MouseButton button) 
	{
		return changed[button] && down[button].inState;
	}

	bool wasPressed(MouseButton button)
	{
		return changed[button] && up[button].inState;
	}

	bool isDown(MouseButton button) 
	{
		return down[button].inState;
	}

	bool isUp(MouseButton button) 
	{
		return up[button].inState;
	}
}

class KeyboardEventState 
{
	dstring					  charInput;
	KeyState[Key.max + 1]  keys;
	bool[Key.max + 1]		  changed;

	bool wasReleased(Key key) 
	{
		return changed[key] && keys[key] == KeyState.released;
	}

	bool wasPressed(Key key)
	{
		return changed[key] && keys[key] == KeyState.pressed;
	}

	bool isDown(Key key) 
	{
		return keys[key] == KeyState.pressed;
	}

	bool isUp(Key key) 
	{
		return keys[key] == KeyState.released;
	}
}

enum KeyState
{
	pressed = GLFW_PRESS,
	released = GLFW_RELEASE
}

enum Key
{
	unknown		  = 0,
	space			  = GLFW_KEY_SPACE,
	apostrophe	  = GLFW_KEY_APOSTROPHE,
	comma			  = GLFW_KEY_COMMA,
	minus			  = GLFW_KEY_MINUS,
	period		  = GLFW_KEY_PERIOD,
	slash			  = GLFW_KEY_SLASH,
	semicolon	  = GLFW_KEY_SEMICOLON,
	equal		     = GLFW_KEY_EQUAL,
	_0			     = GLFW_KEY_0,
	_1			     = GLFW_KEY_1,
	_2			     = GLFW_KEY_2,
	_3			     = GLFW_KEY_3,
	_4			     = GLFW_KEY_4,
	_5			     = GLFW_KEY_5,
	_6			     = GLFW_KEY_6,
	_7			     = GLFW_KEY_7,
	_8			     = GLFW_KEY_8,
	_9			     = GLFW_KEY_9,
	A			     = GLFW_KEY_A,
	B			     = GLFW_KEY_B,
	C			     = GLFW_KEY_C,
	D			     = GLFW_KEY_D,
	E				  = GLFW_KEY_E,
	F				  = GLFW_KEY_F,
	G				  = GLFW_KEY_G,
	H				  = GLFW_KEY_H,
	I				  = GLFW_KEY_I,
	J				  = GLFW_KEY_J,
	K				  = GLFW_KEY_K,
	L				  = GLFW_KEY_L,
	M				  = GLFW_KEY_M,
	N				  = GLFW_KEY_N,
	O				  = GLFW_KEY_O,
	P				  = GLFW_KEY_P,
	Q				  = GLFW_KEY_Q,
	R				  = GLFW_KEY_R,
	S				  = GLFW_KEY_S,
	T				  = GLFW_KEY_T,
	U			     = GLFW_KEY_U,
	V			     = GLFW_KEY_V,
	W			     = GLFW_KEY_W,
	X			     = GLFW_KEY_X,
	Y			     = GLFW_KEY_Y,
	Z			     = GLFW_KEY_Z,
	leftBracket	  = GLFW_KEY_LEFT_BRACKET,
	rightBracket  = GLFW_KEY_RIGHT_BRACKET,
	graveAccent	  = GLFW_KEY_GRAVE_ACCENT,
	world_1		  = GLFW_KEY_WORLD_1,
	world_2		  = GLFW_KEY_WORLD_1,
	escape		  = GLFW_KEY_ESCAPE,
	enter			  = GLFW_KEY_ENTER,
	tab			  = GLFW_KEY_TAB,
	backspace	  = GLFW_KEY_BACKSPACE,
	insert		  = GLFW_KEY_INSERT,
	delete_		  = GLFW_KEY_DELETE,
	right			  = GLFW_KEY_RIGHT,
	left			  = GLFW_KEY_LEFT,
	down			  = GLFW_KEY_DOWN,
	up				  = GLFW_KEY_UP,
	pageUp		  = GLFW_KEY_PAGE_UP,
	pageDown		  = GLFW_KEY_PAGE_DOWN,
	home			  = GLFW_KEY_HOME,
	end			  = GLFW_KEY_END,
	capsLock		  = GLFW_KEY_CAPS_LOCK,
	scrollLock	  = GLFW_KEY_SCROLL_LOCK,
	numLock		  = GLFW_KEY_NUM_LOCK,
	printScreen	  = GLFW_KEY_PRINT_SCREEN,
	pause			  = GLFW_KEY_PAUSE,
	f1				  = GLFW_KEY_F1,
	f2				  = GLFW_KEY_F2,
	f3				  = GLFW_KEY_F3,
	f4				  = GLFW_KEY_F4,
	f5				  = GLFW_KEY_F5,
	f6				  = GLFW_KEY_F6,
	f7				  = GLFW_KEY_F7,
	f8				  = GLFW_KEY_F8,
	f9				  = GLFW_KEY_F9, 
	f10			  = GLFW_KEY_F10,
	f11			  = GLFW_KEY_F11,
	f12			  = GLFW_KEY_F12,
	f13			  = GLFW_KEY_F13,
	f14			  = GLFW_KEY_F14,
	f15			  = GLFW_KEY_F15,
	f16			  = GLFW_KEY_F16,
	f17			  = GLFW_KEY_F17,
	f18			  = GLFW_KEY_F18,
	f19			  = GLFW_KEY_F19,
	f20			  = GLFW_KEY_F20,
	f21		     = GLFW_KEY_F21,
	f22			  = GLFW_KEY_F22,
	f23			  = GLFW_KEY_F23,
	f24			  = GLFW_KEY_F24,
	f25			  = GLFW_KEY_F25,
	numpad0		  = GLFW_KEY_KP_0,
	numpad1		  = GLFW_KEY_KP_1,
	numpad2		  = GLFW_KEY_KP_2,
	numpad3		  = GLFW_KEY_KP_3,
	numpad4		  = GLFW_KEY_KP_4,
	numpad5		  = GLFW_KEY_KP_5,
	numpad6		  = GLFW_KEY_KP_6,
	numpad7		  = GLFW_KEY_KP_7,
	numpad8		  = GLFW_KEY_KP_8,
	numpad9		  = GLFW_KEY_KP_9,
	decimal		  = GLFW_KEY_KP_DECIMAL,
	divide		  = GLFW_KEY_KP_DIVIDE,
	multiply		  = GLFW_KEY_KP_MULTIPLY,
	subtract		  = GLFW_KEY_KP_SUBTRACT,
	add			  = GLFW_KEY_KP_ADD,
	numpadenter	  = GLFW_KEY_KP_ENTER,
	numpadequal	  = GLFW_KEY_KP_EQUAL,
	leftShift	  = GLFW_KEY_LEFT_SHIFT,
	leftControl	  = GLFW_KEY_LEFT_CONTROL,
	leftAlt		  = GLFW_KEY_LEFT_ALT,
	leftSuper	  = GLFW_KEY_LEFT_SUPER,
	rightShift	  = GLFW_KEY_RIGHT_SHIFT,
	rightControl  = GLFW_KEY_RIGHT_CONTROL,
	rightAlt		  = GLFW_KEY_RIGHT_ALT,
	rightSuper	  = GLFW_KEY_RIGHT_SUPER,
	menu			  = GLFW_KEY_MENU,
}

struct GUIProperty
{
	Color normalColor0;
	Color normalColor1;
	Color focusColor0;
	Color focusColor1;
	Color activeColor0;
	Color activeColor1;

	enum defaultButton = 
		GUIProperty(Color(0xFFaaaaFF),
						Color.black,
						Color(0xFFccccFF),
						Color.black,
						Color(0xFF8888FF),
						Color.black);
}



class GUI
{
	private static Frame		pixel;
	private static Sampler	sampler;
	private SpriteBuffer		buffer;
	private Font				font;

	private Frame checkBoxFrame;
	private Frame unCheckBoxFrame;

	private MouseEventState		mouseState;
	private KeyboardEventState      keyState;

	uint focus = -1;
	uint numControl = 0;
	int2 textCursor;

	this(Font font, Frame checkBoxFrame, Frame unCheckBoxFrame, SpriteBuffer buffer = null)
	{
		if(pixel.texture is null) {
			Color[1] color = [Color.white];
			pixel = Frame(Texture2D.create(ColorFormat.rgba,
											 ColorType.ubyte_,
											 InternalFormat.rgba8,
											 1,1, cast(void[])color, Flag!"generateMipMaps".no ));
		}

		this.checkBoxFrame	= checkBoxFrame;
		this.unCheckBoxFrame = unCheckBoxFrame;
		this.font			   = font;
		if(buffer)	
			this.buffer		   = buffer;
		else 
			this.buffer = new SpriteBuffer(512);

		sampler = new Sampler();
		sampler.minFilter = TextureMinFilter.nearest;
		sampler.magFilter = TextureMagFilter.nearest;
	}

	void mouseEventState(MouseEventState state) @property
	{
		this.mouseState = state;
	}

	void keyEventState(KeyboardEventState state) @property
	{
		this.keyState = state;
	}


	void label(float4 rect, const (char)[] text) 
	{
		this.buffer.addText(font, text, float2(rect.x, rect.y), Color.black);
	}

	bool button(float4 rect, const (char)[] text = null, GUIProperty property = GUIProperty.defaultButton)
	{
		auto bColor = selectColor(rect, property);
		this.buffer.addFrame(pixel, rect, bColor);
		if(text)
			this.buffer.addText(font, text, float2(rect.x + 7, rect.y + 7), Color.black);

		focus = wasPressed(rect) ? numControl : focus;
		numControl++;
		return wasPressed(rect);
	}

	bool repeatButton(float4 rect, const (char)[] text = null, GUIProperty property = GUIProperty.defaultButton)
	{
		auto bColor = selectColor(rect, property);
		this.buffer.addFrame(pixel, rect, bColor);
		if(text)
			this.buffer.addText(font, text, float2(rect.x + 7, rect.y + 7), Color.black);


		ButtonState down = mouseState.down[MouseButton.left];

		focus = wasPressed(rect) ? numControl : focus;
		numControl++;
		return down.inState && pointInRect(rect, mouseState.newLoc) && pointInRect(rect, down.loc);
	}

	bool toggle(float4 rect, bool isChecked, const (char)[] text = null)
	{
		auto pressed = wasPressed(rect);
		isChecked	 = pressed ? !isChecked : isChecked;
		auto image   = isChecked ? checkBoxFrame : unCheckBoxFrame;

		this.buffer.addFrame(image, rect);
		if(text)
			this.buffer.addText(font, text, float2(rect.x + 7 + rect.z, rect.y + 7), Color.black);

		focus = wasPressed(rect) ? numControl : focus;
		numControl++;
		return isChecked;
	}

	string textField(float4 rect, string text)
	{
		if(wasPressed(rect)) 
		{
			float2 offset = mouseState.newLoc - rect.xy;
			textCursor.x = messureUntil(text, offset.x);
			focus = numControl;
		}
		
		auto t = text;
		if(isFocused && keyState.charInput.length > 0) {
			auto index = textCursor.x;
			string s = to!string(keyState.charInput);
			t = t[0 .. index] ~ s ~ t[index .. $];
			textCursor.x += s.length;
		}
		

		if(keyState.wasPressed(Key.backspace) && t.length > 0)
		{
			if(textCursor.x == t.length) 
				t = t[0 .. $ - 1];
			else 
				t = t[0 .. textCursor.x] ~ t[textCursor.x + 1 .. $];

			textCursor.x = clamp!int(textCursor.x - 1, 0, t.length);
		}

		if(keyState.wasPressed(Key.left)) 
		{
			textCursor.x = clamp!int(textCursor.x - 1, 0, t.length);
		} 

		if(keyState.wasPressed(Key.right)) 
		{
			textCursor.x = clamp!int(textCursor.x + 1, 0, t.length);
		} 

		this.buffer.addFrame(pixel, rect, Color(0xFFe3ba55));
		this.buffer.addText(font, t, float2(rect.x + 7, rect.y + 7), Color.black);

		if(isFocused) {
			float2 pos = font.messureString(t[0 .. textCursor.x]);
			this.buffer.addFrame(pixel, float4(pos.x + rect.x + 7, rect.y, 1, rect.w), Color.green);
		}

		numControl++;
		return t;
	}

	uint messureUntil(Font font, string toMessure, float maxWidth)
	{
		float2 cursor = float2.zero;
		foreach(i, wchar c; toMessure) 
		{
			auto cc = cursor;
			if(c == ' ') {
				CharInfo spaceInfo = font[' '];
				cursor.x += spaceInfo.advance;
				continue;
			}	else if(c == '\n') {
				cursor.y -= font.lineHeight;
				cursor.x = 0;
				continue;
			} else if(c == '\t') {
				CharInfo spaceInfo = font[' '];
				cursor.x += spaceInfo.advance * font.tabSpaceCount;
				continue;
			}

			CharInfo info = font[c];
			cursor.x += (info.advance);
			
			if(cursor.x >= maxWidth)
				return i; 
		}

		return toMessure.length;
	}


	uint toolbar(float4 rect, uint selected, string[] tools)
	{
		uint spacing = 4;
		uint outSel = -1;
		foreach(i, tool;tools)
		{
			Color c;
			if(i == selected) {
				c = Color(0xFFaaFFaa);
			} else if(pointInRect(rect, mouseState.newLoc))  {
				c = Color(0xFFFFccaa);
			} else {
				c = Color(0xFFaaaaaa);
			}

			this.buffer.addFrame(pixel, rect, c);
			this.buffer.addText(font, tool, float2(rect.x + 7, rect.y + 7), Color.black);

			if(wasPressed(rect)) {
				outSel = i;
			}

			focus = wasPressed(rect) ? numControl : focus;
			rect.x += rect.z + spacing;
		}
		
	
		if(outSel != -1)
			return outSel;

		numControl++;
		return selected;
	}



	float hslider(float4 rect, float value, float min = 0, float max = 100)
	{
		auto box			= Color(0xFF5577FF),
			  innerBox	= Color(0xFFFF7755);

		this.buffer.addFrame(pixel, float2(rect.x, rect.y), box, float2(rect.z, rect.w));

		value = setSliderValue(rect, mouseState.newLoc.x - rect.x, rect.z, value, min, max);
		float4 innerRect = 
				 float4(clamp(rect.x + rect.z * ((value - min) / (max - min)) - rect.w / 2, rect.x, rect.x + rect.z - rect.w),
						  rect.y,
						  rect.w,
						  rect.w);
		
		this.buffer.addFrame(pixel,  innerRect, innerBox);
		
		focus = wasPressed(rect) ? numControl : focus;
		numControl++;
		return value;
	}

	float vslider(float4 rect, float value, float min = 0, float max = 100)
	{
		auto box			= Color(0xFF5577FF),
			  innerBox	= Color(0xFFFF7755);

		this.buffer.addFrame(pixel, float2(rect.x, rect.y), box, float2(rect.z, rect.w));

		value = setSliderValue(rect, mouseState.newLoc.y - rect.y, rect.w, value, min, max);
		float4 innerRect = 
			float4(rect.x,
					 clamp(rect.y + rect.w * ((value - min) / (max - min)) - rect.z / 2, rect.y, rect.y + rect.w - rect.z),
					 rect.z,
					 rect.z);

		this.buffer.addFrame(pixel,  innerRect, innerBox);
		focus = wasPressed(rect) ? numControl : focus;
		numControl++;
		return value;
	}


	float setSliderValue(float4 rect, float pos, float width, float value, float min, float max)
	{
		if(mouseState.isDown(MouseButton.left))
		{
			ButtonState down = mouseState.down[MouseButton.left];
			if(pointInRect(rect, down.loc))
			{
				float tmp = pos;
				tmp /= width;
				tmp *= (max - min) + min;
				
				value = clamp(tmp, min, max);
			}
		}

		focus = wasPressed(rect) ? numControl : focus;
		numControl++;
		return value;
	}


	Color selectColor(float4 loc, GUIProperty property) 
	{
		ButtonState down = mouseState.down[MouseButton.left];
		if(mouseState.isDown(MouseButton.left))
		{
			if(pointInRect(loc, down.loc)) 
			{
				return property.activeColor0;
			}
		} 
		else if(pointInRect(loc, mouseState.newLoc))
		{
			return property.focusColor0;
		}

		return property.normalColor0;
	}

	public void draw(ref mat4 transform)
	{
		gl.sampler[0] = sampler;
		this.buffer.flush();
		this.buffer.draw(transform);
		this.buffer.clear();

		this.numControl = 0;
	}

	bool isFocused()
	{
		return focus == numControl;
	}

	private bool wasPressed(float4 rect) 
	{
		if(mouseState.wasPressed(MouseButton.left))
		{
			ButtonState up   = mouseState.up[MouseButton.left];
			ButtonState down = mouseState.down[MouseButton.left];

			return pointInRect(rect, up.loc) 
				&&  pointInRect(rect, down.loc);
		}
		return false;
	}

	private bool pointInRect(float4 rect, float2 point) 
	{
		return rect.x < point.x && rect.x + rect.z > point.x &&
				 rect.y < point.y && rect.y + rect.w > point.y;
	}
}