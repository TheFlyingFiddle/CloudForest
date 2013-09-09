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


struct ButtonStateStyle
{
	Frame frame;
	Color color;
}

class ButtonStyle
{
	ButtonStateStyle down;
	ButtonStateStyle normal;
	ButtonStateStyle highlight;

	Color textColor;
	Font font;
	float2 textPadding;

	float4 iconDim;
	Color	 iconColor;

	float4 iconRect(float4 rect) 
	{
		return float4(rect.x + rect.w * iconDim.x,
						  rect.y + rect.w * iconDim.y,
						  rect.z * iconDim.z,
						  rect.w * iconDim.w);
	}

	float4 paddedRect(float4 rect)
	{
		return rect + float4(textPadding.x,
									textPadding.y,
									0, 0);
	}
}

class ToggleStyle
{
	Frame toggleFrame;
	Frame untoggleFrame;

	Color color;
	Color textColor;
	Font font;
	
	float4 textPadding;

	Frame frame(bool isToggled)
	{		
		return isToggled ? toggleFrame : untoggleFrame;
	}	

	float4 textRect(float4 rect) 
	{
		return float4(rect.x + textPadding.x + rect.w,
						  rect.y + textPadding.y,
						  rect.z - textPadding.x - textPadding.z - rect.w,
						  rect.w - textPadding.y - textPadding.w);
	}
}

class TextfieldStyle
{
	Frame background;
	Color	backgroundColor;

	Color textColor;
	Font  font;

	Frame cursorFrame;
	Color	cursorColor;

	float4 textPadding;
	float4 paddedRect(float4 rect)
	{
		return float4(rect.x + textPadding.x,
						  rect.y + textPadding.y,
						  rect.z - textPadding.x - textPadding.z,
						  rect.w - textPadding.y - textPadding.w);
	}
}	

class SliderStyle
{
	Frame activeFrame;
	Frame inactiveFrame;
	
	ButtonStateStyle normal;
	ButtonStateStyle highlight;
	
	Color activeColor;
	Color inactiveColor;
}

class LabelStyle
{
	Font font;
	Color textColor;
}

struct GUIStyle
{
	ButtonStyle		 button;
	ButtonStyle		 toolbar;
	ToggleStyle		 toggle;
	TextfieldStyle  textfield;
	SliderStyle		 vslider;
	SliderStyle		 hslider;
	LabelStyle		 label;
	
	this(ButtonStyle    button, 
		  ButtonStyle    toolbar,
		  ToggleStyle    toggle,
		  TextfieldStyle textfield,
		  SliderStyle	  vslider,
		  SliderStyle	  hslider,
		  LabelStyle	  label)
	{
		this.button    = button;
		this.toolbar   = toolbar;
		this.toggle		= toggle;
		this.textfield	= textfield;
		this.vslider	= vslider;
		this.hslider	= hslider;
		this.label		= label;
	}
}

				
class GUI
{
	private GUIStyle			style;

	private static Sampler	sampler;
	private SpriteBuffer		buffer;

	private Frame checkBoxFrame;
	private Frame unCheckBoxFrame;

	private MouseEventState		mouseState;
	private KeyboardEventState      keyState;

	uint focus = -1;
	uint numControl = 0;
	int2 textCursor;

	this(GUIStyle style, SpriteBuffer buffer = null)
	{
		this.style = style;
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

	void label(float4 rect, const (char)[] text, LabelStyle style = null) 
	{
		style = (style) ? style : this.style.label;
		this.buffer.addText(style.font, text, float2(rect.x, rect.y), style.textColor);
	}

	bool button(float4 rect, const (char)[] text = null, Frame icon = Frame.init, ButtonStyle style = null)
	{
		handleButton(rect, text, icon, style);
		return wasPressed(rect);
	}

	bool repeatButton(float4 rect, const (char)[] text = null, Frame icon = Frame.init, ButtonStyle style = null)
	{
		handleButton(rect, text, icon, style);
		return isPressed(rect);
	}

	void handleButton(float4 rect, const (char)[] text = null, Frame icon = Frame.init, ButtonStyle style = null)
	{
		style = (style) ? style : this.style.button;

		ButtonStateStyle state;
		if(isFocused() || isHover(rect)) {
			state = style.highlight;
		} else if(isPressed(rect)) {
			state = style.down;
		} else {
			state = style.normal;
		}

		this.buffer.addFrame(state.frame, rect, state.color);

		if(icon.texture) 
			this.buffer.addFrame(state.frame, style.iconRect(rect), style.iconColor);

		if(text)
			this.buffer.addText(style.font, text, style.paddedRect(rect), style.textColor);

		handleFocus(rect);
	}


	bool toggle(float4 rect, bool isChecked, const (char)[] text = null, ToggleStyle style = null)
	{
		style = (style) ? style : this.style.toggle;

		auto pressed = wasPressed(rect);
		isChecked	 = pressed ? !isChecked : isChecked;

		auto buttonRect = rect.xyww;
		this.buffer.addFrame(style.frame(isChecked), buttonRect, style.color);
		if(text)
			this.buffer.addText(style.font, text, style.textRect(rect), style.textColor);

		handleFocus(rect);
		return isChecked;
	}

	string textField(float4 rect, string text, TextfieldStyle style = null)
	{
		style = (style) ? style : this.style.textfield;
			
		if(wasPressed(rect)) 
		{
			float2 offset = mouseState.newLoc - rect.xy;
			textCursor.x = messureUntil(style.font, text, offset.x);
			focus = numControl;
		}
		
		auto t = text;

		if(isFocused) {

			if(keyState.charInput.length > 0) 
			{
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

				textCursor.x = clamp!int(textCursor.x - 1, 0, cast(int)t.length);
			}

			if(keyState.wasPressed(Key.left)) 
			{
				textCursor.x = clamp!int(textCursor.x - 1, 0, cast(int)t.length);
			} 

			if(keyState.wasPressed(Key.right)) 
			{
				textCursor.x = clamp!int(textCursor.x + 1, 0, cast(int)t.length);
			} 
		}

		this.buffer.addFrame(style.background, rect, style.backgroundColor);
		this.buffer.addText(style.font, t, style.paddedRect(rect), style.textColor);

		if(isFocused)
		{
			float2 pos = style.font.messureString(t[0 .. textCursor.x]) + style.textPadding.xy;
			this.buffer.addFrame(style.cursorFrame, float4(pos.x + rect.x, rect.y, 1, rect.w), style.cursorColor);
		}

		numControl++;
		return t;
	}

	/+//Will not remove but will wait and see if needed.
	uint combobox(float4 rect, uint selected, string[] items)
	{
		this.buffer.addFrame(pixel, rect, Color(0xFF55FF96));
		this.buffer.addText(font, items[selected], rect.xy, Color.black);

		if(isFocused)
		{
			foreach(i, item; items)
			{
				rect.y -= rect.w;

				auto c = (i % 2 == 0) ? Color(0xFF95FF55) : Color(0xFF55FF95); 
				this.buffer.addFrame(pixel, rect, c);
				this.buffer.addText(font, item, rect, Color.black);
				
				if(wasPressed(rect)) 
				{
					focus = -1;
					selected = i;
				}
			}
		} else {
			focus = wasPressed(rect) ? numControl : focus;
		}

		numControl++;
		return selected;
	}+/

	uint messureUntil(Font font, string toMessure, float maxWidth)
	{
		float2 cursor = float2.zero;
		foreach(uint i, wchar c; toMessure) 
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

		return cast(int)toMessure.length;
	}


	uint toolbar(float4 rect, uint selected, string[] tools, ButtonStyle style = null)
	{
		style = (style) ? style : this.style.toolbar;
		uint spacing = 4;
		uint outSel = -1;
		foreach(uint i, tool;tools)
		{
			ButtonStateStyle state;
			if(i == selected) {
				state = style.down;
			} else if(isHover(rect))  {
				state = style.highlight;
			} else {
				state = style.normal;
			}

			this.buffer.addFrame(state.frame, rect, state.color);
			this.buffer.addText(style.font, tool, style.paddedRect(rect), style.textColor);

			if(wasPressed(rect)) {
				outSel = i;
			}

			handleFocus(rect);
			rect.x += rect.z + spacing;
		}
		
		if(outSel != -1)
			return outSel;

		return selected;
	}



	float hslider(float4 rect, float value, float min = 0, float max = 100, SliderStyle style = null)
	{
		style = (style) ? style : this.style.hslider;

		this.buffer.addFrame(style.activeFrame, rect, style.activeColor);

		value = setSliderValue(rect, mouseState.newLoc.x - rect.x, rect.z, value, min, max);
		float4 innerRect = 
				 float4(clamp(rect.x + rect.z * ((value - min) / (max - min)) - rect.w / 2, rect.x, rect.x + rect.z - rect.w),
						  rect.y,
						  rect.w,
						  rect.w);
		
		if(isHover(innerRect)) {
			this.buffer.addFrame(style.highlight.frame,  innerRect, style.highlight.color);
		} else {
			this.buffer.addFrame(style.normal.frame,  innerRect, style.normal.color);
		}

		handleFocus(rect);
		return value;
	}

	float vslider(float4 rect, float value, float min = 0, float max = 100, SliderStyle style = null)
	{
		style = (style) ? style : this.style.vslider;

		this.buffer.addFrame(style.activeFrame, rect, style.activeColor);

		value = setSliderValue(rect, mouseState.newLoc.y - rect.y, rect.w, value, min, max);
		float4 innerRect = 
			float4(rect.x,
					 clamp(rect.y + rect.w * ((value - min) / (max - min)) - rect.z / 2, rect.y, rect.y + rect.w - rect.z),
					 rect.z,
					 rect.z);

		if(isHover(innerRect)) {
			this.buffer.addFrame(style.highlight.frame,  innerRect, style.highlight.color);
		} else {
			this.buffer.addFrame(style.normal.frame,  innerRect, style.normal.color);
		}

		handleFocus(rect);
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
		return value;
	}

	public void draw(ref mat4 transform)
	{
		gl.sampler[0] = sampler;
		this.buffer.flush();
		this.buffer.draw(transform);
		this.buffer.clear();

		this.numControl = 0;
	}

	private void handleFocus(float4 rect)
	{
		focus = wasPressed(rect) ? numControl : focus;
		numControl++;
	}

	bool isFocused()
	{
		return focus == numControl;
	}

	bool isHover(float4 rect)
	{
		return pointInRect(rect, mouseState.newLoc);
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

	private bool isPressed(float4 rect)
	{
		return mouseDownIn(rect) && isHover(rect);
	}

	private bool mouseDownIn(float4 rect) 
	{
		return mouseState.down[MouseButton.left].inState && 
				 pointInRect(rect, mouseState.down[MouseButton.left].loc);
	}

	private bool pointInRect(float4 rect, float2 point) 
	{
		return rect.x < point.x && rect.x + rect.z > point.x &&
				 rect.y < point.y && rect.y + rect.w > point.y;
	}
}