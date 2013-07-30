module examples.triangleExample;

import example;
import graphics.all;
import math.vector;

class TriangleExample : Example
{
	private Context gl;
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

		float triangle[9] = [0.0f, 0.0f, 0.0f,
								   1.0f, 0.0f, 0.0f,
									0.0f, 1.0f, 0.0f];
		
		vertexBuffer.bufferData(triangle);
		vertexArray.bindAttribute!float3(program.attribute["position"], 0, 0);
	}

	override void reshape(int w, int h) { }
	override void render(double time) 
	{
		gl.program = program;
		gl.vertexArray = vertexArray;


		gl.clearColor(Color(0, 1, 1f, 1));
		gl.clear(ClearFlags.color);
		gl.drawArrays(PrimitiveType.triangles, 0, 3);
	}
}

static string vertSource = 
"
#version 330
in vec3 position;
void main(void)
{
	gl_Position = vec4(position, 1.0);
}
";

static string fragSource = 
"
#version 330
out vec4 fragColor;
void main()
{
	gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
";