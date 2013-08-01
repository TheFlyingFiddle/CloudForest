module main;

import std.stdio;

public import derelict.opengl3.gl3;
public import derelict.glfw3.glfw3;
public import derelict.util.exception;
import example, examples.all;
import graphics.all;
import utils.image;
import core.runtime;
import math.vector;
import gui;
import font;

static this()
{
	if(!runModuleUnitTests())
		readln();
}

void main(string[] argv)
{
	try {
		loadSharedLibs();
		auto window = openWindow();
		glfwSetCharCallback(window, &unicodeCallback);

		Context.initialize();

		MouseEventState	 mouseState = new MouseEventState();
		KeyboardEventState keyState   = new KeyboardEventState();

		gl.enable(Capability.blend);
		gl.blendState = BlendState.nonPremultiplied;

		Example[] examples = [ new TriangleExample()] ;
		examples ~= new RectangleExample();
		examples ~= new NewtonExample();
		examples ~= new MandelbrotExample();
		examples ~= new BlobEx();
		examples ~= new TextureExample();
		examples ~= new ParticleSystem();
	 	examples ~= new SpriteBufferExample();
		examples ~= new GUIExample(mouseState, keyState);


		int activeExample = examples.length - 1;	
		bool wasPressed = false;
		while(!glfwWindowShouldClose(window)
				&& glfwGetKey(window, GLFW_KEY_ESC) != GLFW_PRESS) 
		{
			if(!wasPressed && glfwGetKey(window, GLFW_KEY_N) == GLFW_PRESS)
				activeExample = (activeExample + 1) % examples.length;

			examples[activeExample].render(0);


			wasPressed = glfwGetKey(window, GLFW_KEY_N) == GLFW_PRESS;
			glfwSwapBuffers(window);
			glfwPollEvents();
			fixMouseEventState(window, mouseState);
			fixKeyboardEventState(window, keyState);
		}

	} catch(Throwable e) {
		std.stdio.writeln(e);
		std.stdio.readln();
	}
}

dstring inputs;
extern (C) void unicodeCallback(GLFWwindow* window, uint unicode)
{
	dchar c = unicode;
	inputs ~= c;
}


void fixKeyboardEventState(GLFWwindow* window, KeyboardEventState state)
{
	import std.traits;

	state.charInput = inputs;
	inputs.length = 0;

	foreach(key; EnumMembers!Key)
	{
		if(key == Key.unknown) continue;

		KeyState oldState = state.keys[key];
		state.keys[key] = cast(KeyState)glfwGetKey(window, key);

		if(oldState != state.keys[key]) {
			state.changed[key] = true;
		} else {
			state.changed[key] = false;
		}
	}
}


void fixMouseEventState(GLFWwindow* window, MouseEventState state)
{
	state.oldLoc = state.oldLoc;
	
	double x, y;
	int w,h;
	glfwGetCursorPos(window, &x, &y);
	glfwGetWindowSize(window, &w, &h);	
	state.newLoc = float2(x, w - y);



	if(newDeltha)  {
		state.scrollDelta = scrollDeltha;
		newDeltha = false;
	} else {
		state.scrollDelta = float2.zero;
	}
	
	foreach(i; 0 .. GLFW_MOUSE_BUTTON_LAST)
	{
		int action = glfwGetMouseButton(window, i);
		if(action == GLFW_PRESS)
		{
			state.changed[i] = !state.down[i].inState;
			if(state.changed[i]) {
				state.down[i] = ButtonState(state.newLoc, true);
				state.up[i].inState = false;
			}
		} else {
			state.changed[i] = !state.up[i].inState;
			if(state.changed[i]) {
				state.down[i].inState = false;
				state.up[i] = ButtonState(state.newLoc, true);
			}
		}
	}
}


float2 scrollDeltha = float2.zero;
bool newDeltha = false;
extern (C) void scrollCallback(GLFWwindow* window, double x, double y)
{
	newDeltha = true;
	scrollDeltha = float2(x, y);
}



void loadSharedLibs()
{
	DerelictGL3.load();
	DerelictGLFW3.load();
}

auto openWindow()
{
	if (!glfwInit()) throw new Exception("Failed to initialize GLFW");

	glfwWindowHint(GLFW_SAMPLES, 4);

	auto window = glfwCreateWindow(512, 512, "Cloud Forest!", null, null);
	if (!window) throw new Exception("Window failed to create");
	glfwMakeContextCurrent(window);

	glfwSetScrollCallback(window, &scrollCallback);
	glfwSetInputMode(window, GLFW_STICKY_KEYS, GL_TRUE);

	//Load the opengl driver for the window.
	DerelictGL3.reload();
	return window;
}