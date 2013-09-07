module window;

import math.vector;
import input;
import derelict.glfw3.glfw3;
import std.traits : Flag, Yes, No;

static Window[GLFWwindow*] windows;
enum WindowMode
{
	pollEvents,
	waitEvents
}

extern (C) void windowPosCallback(GLFWwindow* glfwWindow, int x, int y)
{
	auto window = windows[glfwWindow];
	window.posChanged(float2(x,y));
}

extern (C) void windowSizeCallback(GLFWwindow* glfwWindow, int width, int height)
{
	auto window = windows[glfwWindow];
	window.sizeChanged(float2(width, height));
}

extern (C) void windowCloseCallback(GLFWwindow* glfwWindow)
{
	auto window = windows[glfwWindow];
	window.closing();
}

extern (C) void windowRefreshCallback(GLFWwindow* glfwWindow)
{
	auto window = windows[glfwWindow];
	window.refresh();
}

extern (C) void windowFocusCallback(GLFWwindow* glfwWindow, int focus)
{
	auto window = windows[glfwWindow];
	window.focusChanged(focus == 1);
}

extern (C) void windowIconifyCallback(GLFWwindow* glfwWindow, int iconify)
{
	auto window = windows[glfwWindow];
	window.iconifyChanged(iconify == 1);
}

extern (C) void mouseButtonCallback(GLFWwindow* glfwWindow, int button, int action, int mods)
{
	auto window = windows[glfwWindow];
	auto state = window.mouseState;

	state.changed[button] = true;
	if(action == GLFW_PRESS)
	{
		if(state.changed[button]) {
			state.down[button] = ButtonState(state.newLoc, true);
			state.up[button].inState = false;
		}
	} else {
		if(state.changed[button]) {
			state.down[button].inState = false;
			state.up[button] = ButtonState(state.newLoc, true);
		}
	}

}

extern (C) void mouseCursorPosCallback(GLFWwindow* glfwWindow, double x, double y)
{
	auto window = windows[glfwWindow];
	auto state = window.mouseState;
	state.newLoc = float2(x, window.height - y);
}


extern (C) void scrollCallback(GLFWwindow* glfwWindow, double x, double y)
{
	auto window = windows[glfwWindow];
	window.mouseState.scrollDelta = float2(x, y);
}

extern (C) void unicodeCallback(GLFWwindow* glfwWindow, uint unicode)
{
	auto window = windows[glfwWindow];
	dchar c = unicode;
	window.keyboardState.charInput ~= c;
}

extern (C) void keyCallback(GLFWwindow* glfwWindow, int key, int scancode, int action, int modifiers)
{
	auto window = windows[glfwWindow];
	auto state = window.keyboardState;
	state.modifier = cast(KeyModifier)modifiers;

	switch(action) 
	{
		case GLFW_RELEASE :
			state.keys[key]	 = KeyState.released;
			state.changed[key] = true;
			break;
		case GLFW_PRESS :
			state.keys[key]	 = KeyState.pressed;
			state.changed[key] = true;
			break;
		case GLFW_REPEAT :
			state.changed[key] = true;
			break;
		default:
			assert(false, "Unrecognized key!");
			break;
	}
} 

final class Clipboard
{
	Window owner;
	this(Window window)
	{
		this.owner = window;
	}

	string text() @property
	{
		return std.conv.to!string(glfwGetClipboardString(owner._glfwWindow));
	}

	void text(in const(char)[] value) @property
	{
		import std.string;
		glfwSetClipboardString(owner._glfwWindow, value.toStringz);
	}
}

final class Window
{
	GLFWwindow* _glfwWindow;
	KeyboardEventState keyboardState;
	MouseEventState mouseState;
	Clipboard clipboard;

	private void delegate() _onPosCahnged;
	private void delegate() _onSizeChanged;
	private void delegate() _onClose;
	private void delegate() _onFocusChanged;
	private void delegate() _onIconifyChanged;
	private void delegate() _onRefresh;
	private void delegate() _onUpdate;
	private void delegate() _onRender;

	int width() @property
	{
		int width, height;
		glfwGetFramebufferSize(_glfwWindow, &width, &height);
		return width;
	}

	int height() @property
	{	
		int width, height;
		glfwGetFramebufferSize(_glfwWindow, &width, &height);
		return height;
	}

	int2 size() @property
	{
		int width, height;
		glfwGetFramebufferSize(_glfwWindow, &width, &height);
		return int2(width, height);
	}

	void size(int2 size) @property
	{
		glfwSetWindowSize(_glfwWindow, size.x, size.y);
	}

	int2 framebufferSize() @property
	{
		int width, height;
		glfwGetWindowSize(_glfwWindow, &width, &height);
		return int2(width, height);
	}
	
	bool shouldClose() @property
	{
		return glfwWindowShouldClose(_glfwWindow) == 1;
	}

	this(int width, int height, const (char)[] title, Flag!"makeCurrent" flag = Yes.makeCurrent, GLFWmonitor* monitor = null, Window share = null)
	{
		_glfwWindow = glfwCreateWindow(width, height, title.ptr, monitor, (share) ? share._glfwWindow : null);	
		if(flag) {
			glfwMakeContextCurrent(_glfwWindow);
		}

		windows[_glfwWindow] = this;

		glfwSetMouseButtonCallback(_glfwWindow, &mouseButtonCallback);
		glfwSetCursorPosCallback(_glfwWindow,   &mouseCursorPosCallback);
		glfwSetKeyCallback(_glfwWindow,			 &keyCallback);
		glfwSetCharCallback(_glfwWindow,			 &unicodeCallback);
		glfwSetScrollCallback(_glfwWindow,		 &scrollCallback);

		glfwSetWindowPosCallback(_glfwWindow,		&windowPosCallback);
		glfwSetWindowSizeCallback(_glfwWindow,		&windowSizeCallback);
		glfwSetWindowCloseCallback(_glfwWindow,	&windowCloseCallback);
		glfwSetWindowRefreshCallback(_glfwWindow, &windowRefreshCallback);
		glfwSetWindowFocusCallback(_glfwWindow,	&windowFocusCallback);
		glfwSetWindowIconifyCallback(_glfwWindow, &windowIconifyCallback);

		this.keyboardState = new KeyboardEventState();
		this.mouseState	 = new MouseEventState();
		this.clipboard     = new Clipboard(this);

	}


	void run(WindowMode mode)
	{
		while(!shouldClose)
		{
			pollEvents(mode);

			if(_onUpdate)
				_onUpdate();

			if(_onRender)
				_onRender();

			swapBuffers();
		}
	}

	void focusChanged(bool hasFocus)
	{

	}

	void iconifyChanged(bool isIconify)
	{

	}
	
	void posChanged(float2 newPos)
	{
		
	}

	void sizeChanged(float2 newPos)
	{

	}

	void refresh()
	{

	}

	void closing()
	{

	}

	void onUpdate(void delegate() update) @property
	{
		this._onUpdate = update;
	}

	void onRender(void delegate() render) @property
	{	
		this._onRender = render;
	}	

	void pollEvents(WindowMode mode)
	{
		mouseState.reset();
		keyboardState.reset();

		if(mode == WindowMode.pollEvents)  {
			glfwPollEvents();
		} else if(mode == WindowMode.waitEvents) {
			glfwWaitEvents();
		}
	}

	void swapBuffers()
	{
		glfwSwapBuffers(_glfwWindow);
	}

	void destroy()
	{
		glfwDestroyWindow(_glfwWindow);
	}
}