module examples.mandelbrotExample;

import example;
import graphics.all;
import math.vector;

class MandelbrotExample : Example
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
		gl.vao = vertexArray;
		gl.vbo = vertexBuffer;

		float[16] screenRect = [-1,-1, -1.5, -0.5, 
								      -1, 1, -1.5,  1.0,
									    1,-1,  0.5f,-0.5f,
									    1, 1,  0.5f, 1.0f];

		vertexBuffer.bufferData(screenRect);
		vertexArray.bindAttribute!float2(program.attribute["position"], float2.sizeof * 2, 0);
		vertexArray.bindAttribute!float2(program.attribute["coord"], float2.sizeof * 2, float2.sizeof);

		float4[5] colorMap = [ float4(0.4f, 0.2f, 1.0f, 0.0f),
									  float4(1.0f, 0.92f, 0.2f, 0.30f),
									  float4(1.0f, 1.0f, 1.0f, 0.95f),
									  float4(1.0f, 1.0f, 1.0f, 0.98f),
									  float4(0.1f, 0.1f, 0.1f, 1.0f)];

		
		program.uniform["clrs"] = colorMap;
	}


	override void reshape(int w, int h) { }
	override void render(double time) 
	{
		gl.program = program;
		gl.vao = vertexArray;

		gl.clearColor(Color(0, 1, 1f, 1));
		gl.clear(ClearFlags.color);
		gl.drawArrays(PrimitiveType.triangleStrip, 0, 4);
	}
}


enum vertSource = 
"#version 330
in vec2 position;
in vec2 coord;
out vec2 vertCoord;
void main(void)
{
	vertCoord = coord;
	gl_Position = vec4(position, 0, 1.0);
}";

enum fragSource = 
"#version 330
in vec2 vertCoord;
out vec4 fragColor;

const int nclr = 5;
uniform vec4 clrs[5];

void main()
{
	vec2 z = vec2(0.0, 0.0);
	vec2 c = vertCoord;
	int i = 0, max = 128;
	while((i != max) && (distance(z, c) < 2.0f)) 
	{
		vec2 zn = vec2( z.x * z.x - z.y * z.y + c.x,
		2.0 * z.x * z.y + c.y);
		z = zn;
		++i;
	}

	float a = sqrt(float(i) / float(max));
	for(i = 0; i != (nclr - 1); ++i) {
	if(a >= clrs[i].a && a < clrs[i + 1].a) 
		{
		float m = (a - clrs[i].a) / (clrs[i + 1].a - clrs[i].a);
		fragColor = vec4(mix(clrs[i].rgb, clrs[i + 1].rgb, m), 1.0);
		break;
		}
	}
}";