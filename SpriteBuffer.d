module SpriteBuffer;

import graphics.buffer;
import graphics.vertex;
import graphics.color;
import graphics.program;
import graphics.shader;
import graphics.context;
import graphics.enums;
import graphics.texture;
import math.vector;
import math.matrix;

import std.algorithm;
import frame;
import font;

final class SpriteBuffer 
{
	private VBO		 vbo;
	private VAO		 vao;
	private Program program;

	private Vertex[]	  vertices;
	private Texture2D[] textures;


	private struct Vertex
	{
		float4	pos;
		float4	texCoord;
		float2   origin;
		Color		color;
		float		rotation;
	}

	private uint elements;


	this(uint size, BufferHint hint = BufferHint.streamDraw) 
	{
		size	    = size;
		vao		 = new VAO();
		vbo		 = new VBO(hint);
		vertices  = new Vertex[size];
		textures  = new Texture2D[size];
		elements  = 0;

		gl.vertexBuffer = vbo;
		vbo.initialize(size * Vertex.sizeof);

		auto gShader = new Shader(ShaderType.geometry, gs),
			  vShader = new Shader(ShaderType.vertex, vs),
			  fShader = new Shader(ShaderType.fragment, fs);

		program = new Program(gShader, vShader, fShader);
		gl.program = program;
		program.uniform["sampler"] = 0;

		gShader.destroy();
		vShader.destroy();
		fShader.destroy();

		gl.vertexArray = vao;
		vao.bindAttributesOfType!Vertex(program);

	}

	
	SpriteBuffer addFrame(Frame frame, 
								 float2 pos,
								 Color color = Color.white,
								 float2 scale = float2.one,
								 float2 origin = float2.zero, 
								 float rotation = 0,
								 bool mirror = false)
	{
		if(elements > vertices.length)
			throw new Exception("SpriteBuffer full");

		float4 coords = frame.coords;
		if(mirror) {
			swap(coords.x, coords.z);
		}
		
		vertices[elements] = Vertex(float4(pos.x, pos.y, scale.x, scale.y),
										  coords,
										  origin,
										  color,
										  rotation);

		textures[elements++] = frame.texture;
		return this;
	}

	SpriteBuffer addText(Font font,
								const (char)[] text, 
								float2 pos,
								Color color = Color.white,
								float2 scale = float2.one,
								float2 origin = float2.zero,
								float rotation = 0)
	{
		if(elements + text.length > vertices.length)
			throw new Exception("SpriteBuffer full");

		textures[elements .. elements + text.length] = font.page;

		float2 cursor = float2.zero;
		foreach(wchar c; text)
		{
			if(c == ' ') 
				continue;
			else if(c == '\n') {
				cursor.y -= font.lineHeight * scale.y;
				cursor.x = -origin.x * scale.x;
				continue;
			} else if(c == '\t') {
				CharInfo spaceInfo = font[' '];
				cursor.x += spaceInfo.advance * font.tabSpaceCount * scale.x;
				continue;
			}

			CharInfo info = font[c];
			float4 pos = float4(pos.x + cursor.x,
									  pos.y + cursor.y,
									  scale.x, scale.y);
			
			vertices[elements++] = Vertex(pos, 
												 info.textureCoords,
												 origin,
												 color,
												 rotation);

			cursor.x += info.advance * scale.x;
		}
		return this;
	}


	SpriteBuffer flush()
	{
		gl.vertexBuffer = vbo;
		vbo.bufferSubData(vertices[0 .. elements], 0);
		return this;
	}

	SpriteBuffer clear()
	{
		this.elements = 0;
		return this;
	}

	SpriteBuffer draw(ref mat4 transform)
	{
		if(elements == 0) return this;

		gl.vertexBuffer = vbo;
		gl.vertexArray  = vao;
		gl.program		 = program;

		program.uniform["transform"] = transform.transpose;

		//gl.blendState	 = blendState;
		
		Texture2D texture = textures[0];
		
		uint count = 1;
		uint offset = 0;
		foreach(i; 1 .. elements)
		{
			if(textures[i] != texture)	 {
				gl.textures[0] = texture;
				gl.drawArrays(PrimitiveType.points, offset, count);
				count = 1; offset = i;
				continue;
			}
			count++;
		}
		
		gl.textures[0] = textures[$ - 1];
		gl.drawArrays(PrimitiveType.points, offset, count);
		return this;
	}
}


enum vs =
"#version 330
in vec4  pos;
in vec4  texCoord;
in vec4  color;
in vec2  origin;
in float rotation;

out vertexAttrib
{ 
	vec4  texCoord;
	vec4  color;
	vec2  origin;
	float rotation;
} vertex;

void main() 
{
	gl_Position	    = pos;
	vertex.texCoord = texCoord;
	vertex.color	 = color;
	vertex.origin   = origin;
	vertex.rotation = rotation;
}
";

enum gs =
"#version 330
layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

in vertexAttrib
{
	vec4 texCoord;
	vec4 color;
	vec2 origin;
	float rotation;
} vertex[1];

out vertData 
{
	vec4 color;
	vec2 texCoord;
} vertOut;

uniform mat4 transform;

vec4 calcPos(in vec2 pos, in float sinus, in float cosinus)
{
	pos.x += vertex[0].origin.x * cosinus - vertex[0].origin.y * sinus;
	pos.y += vertex[0].origin.x * sinus   + vertex[0].origin.y * cosinus;
	return vec4(pos, 0 , 1);
}

void emitCorner(in vec2 pos, in vec2 coord, in float sinus, in float cosinus)
{
	vertOut.texCoord = vertex[0].texCoord;
	vertOut.color	  = vertex[0].color;
	gl_Position		  = transform * calcPos(pos, sinus, cosinus);
	EmitVertex();
}

void main()
{
	float sinus   = sin(vertex[0].rotation),
			cosinus = cos(vertex[0].rotation);

	vec4 pos = gl_in[0].gl_Position;
	vec4 texCoord = vertex[0].texCoord;
	
	emitCorner(pos.xy, texCoord.xy, sinus, cosinus);
	emitCorner(pos.xw, texCoord.xw, sinus, cosinus);
	emitCorner(pos.zw, texCoord.zw, sinus, cosinus);
	emitCorner(pos.zy, texCoord.zy, sinus, cosinus);
	EndPrimitive();
}
";

enum fs =
"#version 330

in vec4 color;
in vec2 texCoord;

out vec4 fragColor;

uniform sampler2D sampler;

void main()
{
	fragColor = texture2D(sampler, texCoord) * color;
}
";