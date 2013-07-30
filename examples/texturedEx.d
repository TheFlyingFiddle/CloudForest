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
	private Texture2D texture;
	private Sampler sampler;

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

		float triangle[8] = [-1,-1, 
									-1, 1,
								 	 1,-1, 
									 1, 1];

		vertexBuffer.bufferData(triangle);
		vertexArray.bindAttribute!float2(program.attribute["position"], 0, 0);

		uint width, height;
		auto png = new PngLoader();
		auto data = png.load("resources/PngTest.png", width, height);
		texture = Texture2D.create(ColorFormat.rgba, 
											ColorType.ubyte_, 
											InternalFormat.rgba8,
											width, height, data,
											No.generateMipMaps);

		sampler = new Sampler();

		sampler.minFilter = TextureMinFilter.nearest;
		sampler.magFilter = TextureMagFilter.nearest;

	}

	override void reshape(int w, int h) { }
	int time = 0;
	override void render(double time2) 
	{
		gl.program = program;
		gl.vao = vertexArray;

		auto i = std.random.uniform(0, gl.getInteger(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS));
		gl.textures[i] = texture;
		gl.sampler[i] = sampler;


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