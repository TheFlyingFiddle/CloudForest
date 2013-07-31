module main;

import std.stdio;

public import derelict.opengl3.gl3;
public import derelict.glfw3.glfw3;
public import derelict.util.exception;
import example, examples.all;
import graphics.all;
import utils.image;
import core.runtime;

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
		Context.initialize();
		writeln(Context.getInteger(GL_MAX_ARRAY_TEXTURE_LAYERS));

		Example[] examples = [ new TriangleExample()] ;
		examples ~= new RectangleExample();
		examples ~= new NewtonExample();
		examples ~= new MandelbrotExample();
		examples ~= new BlobEx();
		examples ~= new TextureExample();
		examples ~= new ParticleSystem();
	 	examples ~= new SpriteBufferExample();


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
		}

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

	auto window = glfwCreateWindow(512, 512, "Cloud Forest!", null, null);
	if (!window) throw new Exception("Window failed to create");
	glfwMakeContextCurrent(window);

	//Load the opengl driver for the window.
	DerelictGL3.reload();
	return window;
}