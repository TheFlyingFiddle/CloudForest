module examples.texturedEx;

import example;
import graphics.all;
import math.vector;
import utils.image;
import derelict.opengl3.gl3;

class TextureExample : Example
{
	private Context gl;
	private Shader vs, fs;
	private Program program;
	private VertexArray vertexArray;
	private VertexBuffer vertexBuffer;
	private Texture texture;

	this() 
	{
		auto vs = Shader.create(ShaderType.vertex,vertSource);
		auto fs = Shader.create(ShaderType.fragment,fragSource);	
		program = Program.create(vs, fs);
		vertexArray = VertexArray.create();
		vertexBuffer = VertexBuffer.create(BufferHint.staticDraw);

		gl.program = program;
		gl.vertexArray = vertexArray;
		gl.vertexBuffer = vertexBuffer;

		float triangle[8] = [-1,-1, 
									-1, 1,
								 	 1,-1, 
									 1, 1];

		vertexBuffer.bufferData(triangle);
		vertexArray.bindAttribute!float2(program.attribute["position"], 0, 0);

		uint width, height;
		auto data = BmpLoader.load("resources/particles.bmp", width, height);
		texture = Texture2D.create(ColorFormat.bgr, 
											ColorType.ubyte_, 
											InternalFormat.rgba8,
											width, height, data,
											No.generateMipMaps);


	}

	override void reshape(int w, int h) { }
	int time = 0;
	override void render(double time2) 
	{
		gl.program = program;
		gl.vertexArray = vertexArray;

		auto i = std.random.uniform(0, gl.getInteger(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS));
		std.stdio.writeln(i);
		gl.textures[i] = texture;
		program.uniform["sampler"] = i;


		program.validate();

		gl.clearColor(Color(0, 0, 0, 0));
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
	vertCoord = vec2((position.x + 1.0f) / 2.0f, (position.y + 1.0f) / 2.0f);
	gl_Position = vec4(position, 0, 1.0);
}";

enum fragSource = 
"#version 330
uniform sampler2D sampler;
in vec2 vertCoord;

void main() 
{
	gl_FragColor = texture2D(sampler, vertCoord);
}";