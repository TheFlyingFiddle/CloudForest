module examples.blobEx;

import graphics.all;
import example;
import math.vector;
import derelict.opengl3.gl3;


class BlobEx : Example
{
	private Context gl;
	private Program program;
	private VertexArray vertexArray;
	private VertexBuffer vertexBuffer;
	private UniformBuffer uniformBuffer;

	struct BlobSettings
	{
		float4 innerColor;
		float4 outerColor;
		float innerRadius;
		float outerRadius;
		float padding0, padding1;
	}

	this() 
	{
		auto vs = new Shader(ShaderType.vertex,vertSource);
		auto fs = new Shader(ShaderType.fragment,fragSource);	
		program = new Program(vs, fs);
		
		vertexArray	  = new VAO();
		vertexBuffer  = new VBO(BufferHint.staticDraw);
		uniformBuffer = new UBO(BufferHint.staticDraw);

		gl.vao		= vertexArray;
		gl.vbo   = vertexBuffer;
		gl.ubo  = uniformBuffer;

		float2 triangle[4] = [float2(-1f,-1f), 
							  		 float2(-1f, 1f),
									 float2( 1f,-1f),
									 float2( 1f, 1f)];

		

		vertexBuffer.bufferData(triangle);
		vertexArray.bindAttribute!float2(program.attribute["position"], 0, 0);

		uniformBuffer.initialize(uniformBuffer.alignment * 2);
		auto bufferedUniform = uniformBuffer.uniform!BlobSettings(0, BlobSettings(float4(0,1,0,1), float4(0,0,1,1), 0.15f, 0.85f));

		gl.bufferUniform[1] = bufferedUniform;

		bufferedUniform.bindBlock(program.block("BlobSettings"));
	}


	override void reshape(int w, int h) { }
	override void render(double time) 
	{
		gl.program = program;
		gl.vao = vertexArray;

		program.validate();

		gl.clearColor(Color(0, 1, 1f, 1));
		gl.clear(ClearFlags.color);
		gl.drawArrays(PrimitiveType.triangleStrip, 0, 4);
	}
}


enum vertSource = 
"#version 330
in vec2 position;
out vec2 vertCoord;
void main(void)
{
	vertCoord = position;
		gl_Position = vec4(position, 0, 1.0);
}";

enum fragSource = 
"#version 330

layout(std140) uniform BlobSettings {
vec4 innerColor;
vec4 outerColor;
float innerRadius;
float outerRadius;
float pad0, pad1;
};

in vec2 vertCoord;
void main()
{
	float dx = vertCoord.x;
		float dy = vertCoord.y;
		float dist = sqrt(dx * dx + dy * dy);
		gl_FragColor = mix(innerColor, outerColor,
		smoothstep(innerRadius, outerRadius, dist));
}";