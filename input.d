module input;
import math.vector;
import derelict.glfw3.glfw3;

struct ButtonState
{
	float2 loc;
	bool inState;
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

	void reset()
	{
		scrollDelta = float2.zero;
		changed[] = false;

		oldLoc = newLoc;
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


enum KeyModifier
{
	control = GLFW_MOD_CONTROL,
	shift	  = GLFW_MOD_SHIFT,
	alt	  = GLFW_MOD_ALT,

	controlAlt	 = control | alt,
	controlShift = control | shift,
	shiftAlt		 = shift   | alt,
	controlAltShift = control | alt | shift
}


class KeyboardEventState 
{
	dstring					  charInput;
	KeyModifier				  modifier;
	KeyState[Key.max + 1]  keys;
	bool[Key.max + 1]		  changed;

	bool wasReleased(Key key) 
	{
		return changed[key] && keys[key] == KeyState.released;
	}

	bool wasPressed(Key key)
	{
		bool p = changed[key] && keys[key] == KeyState.pressed;
		return p;
	}

	bool isDown(Key key) 
	{
		return keys[key] == KeyState.pressed;
	}

	bool isUp(Key key) 
	{
		return keys[key] == KeyState.released;
	}

	void reset()
	{
		charInput.length = 0;
		changed[] = false;
	}
}


enum KeyState
{
	pressed = GLFW_PRESS,
	released = GLFW_RELEASE
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
