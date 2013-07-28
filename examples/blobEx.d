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
	}

	this() 
	{
		auto vs = Shader.create(ShaderType.vertex,vertSource);
		auto fs = Shader.create(ShaderType.fragment,fragSource);	
		program = Program.create(vs, fs);
		
		vertexArray		= VAO.create();
		vertexBuffer	= VBO.create(BufferHint.staticDraw);
		uniformBuffer  = UBO.create(BufferHint.staticDraw);

		gl.vertexArray		= vertexArray;
		gl.vertexBuffer   = vertexBuffer;
		gl.uniformBuffer  = uniformBuffer;

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


	//	uint buffer;
	//	glGenBuffers(1, &buffer);
	//	glBindBuffer(GL_UNIFORM_BUFFER, buffer);
		
	// int loc = block.uniforms["innerColor"].offset / 4;
	//	auto data = new float[block.size / 4];
	//	data[loc .. loc + 4] = [0f, 1f, 0f, 1f];
	//	loc = block.uniforms["outerColor"].offset / 4;
	//	data[loc .. loc + 4] = [0f, 0f, 1f, 1f];
	//	loc = block.uniforms["innerRadius"].offset / 4;
	//	data[loc] = 0.15f;
	//	loc = block.uniforms["outerRadius"].offset / 4;
	//	data[loc] = 0.85f;

	//	glBufferData(GL_UNIFORM_BUFFER, block.size, cast(void*)data.ptr, GL_DYNAMIC_DRAW);

	//	glBindBufferBase(GL_UNIFORM_BUFFER, block.index, buffer);
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