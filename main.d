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
import input;
import window;

import core.sys.windows.windows;

static this()
{
	if(!runModuleUnitTests())
	{

	}
}

void main(string[] argv)
{
	try {
		loadSharedLibs();
		auto window = openWindow();

		glfwSetCharCallback(window._glfwWindow, &unicodeCallback);
		Context.initialize();

		gl.enable(Capability.blend);
		gl.blendState = BlendState.nonPremultiplied;
		gl.enable(Capability.multisample);

		Example[] examples;
		//examples ~= new TriangleExample();
		//examples ~= new RectangleExample();
		//examples ~= new NewtonExample();
		//examples ~= new MandelbrotExample();
		//examples ~= new BlobEx();
		//examples ~= new TextureExample();
		//examples ~= new ParticleSystem();
		//examples ~= new SpriteBufferExample();
		examples ~= new GUIExample(window.mouseState, window.keyboardState, window.clipboard);

		int activeExample = examples.length - 1;	
		bool wasPressed = false;
		
		window.onUpdate =
		{
			if(!wasPressed && glfwGetKey(window._glfwWindow, GLFW_KEY_N) == GLFW_PRESS)
				activeExample = (activeExample + 1) % examples.length;

			wasPressed = glfwGetKey(window._glfwWindow, GLFW_KEY_N) == GLFW_PRESS;
		};

		window.onRender =
		{
			examples[activeExample].render(0);
		};

		window.run(WindowMode.pollEvents);

		//window.close();
		glfwTerminate();

	} catch(Throwable e) {
		std.stdio.writeln(e);
		std.stdio.readln();
	}
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
	//glfwWindowHint(GLFW_DECORATED, GL_FALSE);

	auto window = new Window(1280, 720, "Cloud Forest!");

	//Load the opengl driver for the window.
	DerelictGL3.reload();
	return window;
}