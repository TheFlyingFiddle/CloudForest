module examples.rectangleExample;

import example;
import graphics.all;
import math.vector;

class RectangleExample : Example
{
	private Context gl;
	private Shader vs, fs;
	private Program program;
	private VertexArray vertexArray;
	private VertexBuffer vertexBuffer;

	this() 
	{
		auto vs = new Shader(ShaderType.vertex,vertSource);
		auto fs = new Shader(ShaderType.fragment,fragSource);	
		program = new Program(vs, fs);

		vertexArray	  = new VAO();
		vertexBuffer  = new VBO(BufferHint.staticDraw);

		gl.program = program;
		gl.vertexArray = vertexArray;
		gl.vertexBuffer = vertexBuffer;

		float triangle[20] = [-1,-1, 1, 1, 1, 
									 -1, 1, 1, 0, 0,
									  1,-1, 0, 1, 0,
									  1, 1, 0, 0, 1];

		vertexBuffer.bufferData(triangle);
		vertexArray.bindAttribute!float2(program.attribute["position"], float2.sizeof + float3.sizeof, 0);
		vertexArray.bindAttribute!float3(program.attribute["color"], float2.sizeof + float3.sizeof, float2.sizeof);
	}


	override void reshape(int w, int h) { }
	override void render(double time) 
	{
		gl.program = program;
		gl.vertexArray = vertexArray;

		program.validate();

		gl.clearColor(Color(0, 1, 1f, 1));
		gl.clear(ClearFlags.color);
		gl.drawArrays(PrimitiveType.triangleStrip, 0, 4);
	}
}

enum vertSource =
"#version 330
in vec2 position;
in vec3 color;
out vec3 vertColor;
void main(void)
{
	vertColor = color;
		gl_Position = vec4(position, 0, 1.0);
}";

enum fragSource = 
"#version 330
in vec3 vertColor;
out vec4 fragColor;
void main()
{
	fragColor = vec4(vertColor, 1.0);
}";