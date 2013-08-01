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
	private VBO	vbo;
	private VAO vao;

	private static Program program;

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
		vbo		 = new VBO(hint);
		vertices  = new Vertex[size];
		textures  = new Texture2D[size];
		vao		 = new VAO();
		elements  = 0;

		gl.vbo = vbo;
		vbo.initialize(size * Vertex.sizeof);


		if(program is null) {
			auto gShader = new Shader(ShaderType.geometry, gs),
				  vShader = new Shader(ShaderType.vertex, vs),
			     fShader = new Shader(ShaderType.fragment, fs);
			
			program = new Program(gShader, vShader, fShader);

			gl.program = program;
			program.uniform["sampler"] = 0;

			gShader.destroy();
			vShader.destroy();
			fShader.destroy();
		}


		gl.vao = vao;
		vao.bindAttributesOfType!Vertex(program);
	}

	
	SpriteBuffer addFrame(Frame frame,
								 float4 rect,
								 Color color = Color.white,
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

		vertices[elements] = Vertex(rect,
											 coords,
											 origin,
											 color,
											 rotation);

		textures[elements++] = frame.texture;
		return this;
	}

	SpriteBuffer addFrame(Frame frame, 
								 float2 pos,
								 Color color = Color.white,
								 float2 scale = float2(1,1),
								 float2 origin = float2(0,0), 
								 float rotation = 0,
								 bool mirror = false)
	{
		if(elements > vertices.length)
			throw new Exception("SpriteBuffer full");

		float4 coords = frame.coords;
		if(mirror) {
			swap(coords.x, coords.z);
		}

		float2 dim = float2(frame.dim.x * scale.x, frame.dim.x * scale.y);
		vertices[elements] = Vertex(float4(pos.x, pos.y, dim.x, dim.y),
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
						 float2 scale = float2(1,1),
						 float2 origin = float2(0,0), 
								float rotation = 0)
	{
		if(elements + text.length > vertices.length)
			throw new Exception("SpriteBuffer full");

		textures[elements .. elements + text.length] = font.page;
		
		float2 cursor = float2(0,0);
		foreach(wchar c; text)
		{
			auto cc = cursor;
			if(c == ' ') {
				CharInfo spaceInfo = font[' '];
				cursor.x += spaceInfo.advance * scale.x;
				continue;
			}	else if(c == '\n') {
				cursor.y -= font.lineHeight * scale.y;
				cursor.x = -origin.x * scale.x;
				continue;
			} else if(c == '\t') {
				CharInfo spaceInfo = font[' '];
				cursor.x += spaceInfo.advance * font.tabSpaceCount * scale.x;
				continue;
			}

			CharInfo info = font[c];
			float4 ppos = float4(pos.x + info.offset.x,
									   pos.y + info.offset.y,
									   scale.x * info.srcRect.z, 
									   scale.y * info.srcRect.w);
			
			vertices[elements++] = Vertex(ppos, 
												 info.textureCoords,
												 float2(-origin.x - cursor.x,
														  -origin.y - cursor.y ),
												 color,
												 rotation);

			cursor.x += info.advance * scale.x;
		}
		return this;
	}


	SpriteBuffer flush()
	{
		gl.vbo = vbo;
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

		gl.vao		= vao;
		gl.program	= program;

		program.uniform["transform"] = transform;
		Texture2D texture = textures[0];
		
		uint count = 1;
		uint offset = 0;
		foreach(i; 1 .. elements)
		{
			if(textures[i] != texture)	 {
				gl.textures[0] = texture;
				gl.drawArrays(PrimitiveType.points, offset, count);
				count = 1; offset = i;
				texture = textures[i];
				continue;
			}
			count++;
		}
		
		gl.textures[0] = textures[elements - 1];
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
	vec4	pos;
	vec4  texCoord;
	vec4  color;
	vec2  origin;
	float rotation;
} vertex;

void main() 
{
	vertex.pos		 = pos;
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
	vec4 pos;
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

vec4 calcPos(in vec2 pos, in vec2 origin, in float sinus, in float cosinus)
{
	pos.x += origin.x * cosinus - origin.y * sinus;
	pos.y += origin.x * sinus   + origin.y * cosinus;
	return vec4(pos, 0 , 1);
}

void emitCorner(in vec2 pos, in vec2 origin, in vec2 coord, in float sinus, in float cosinus)
{
	gl_Position		  = transform * calcPos(pos, origin, sinus, cosinus);
	vertOut.color	  = vertex[0].color;
	vertOut.texCoord = coord;
	EmitVertex();
}

void main()
{
	float sinus   = sin(vertex[0].rotation),
			cosinus = cos(vertex[0].rotation);

	vec4 pos		  = vertex[0].pos;
	vec4 texCoord = vertex[0].texCoord;
	vec2 origin   = -vertex[0].origin;
	
	emitCorner(pos.xy, origin							  , texCoord.xy, sinus, cosinus);
	emitCorner(pos.xy, origin + vec2(0, pos.w)	  , texCoord.xw, sinus, cosinus);
	emitCorner(pos.xy, origin + vec2(pos.z, 0)	  , texCoord.zy, sinus, cosinus);
	emitCorner(pos.xy, origin + vec2(pos.z, pos.w) , texCoord.zw, sinus, cosinus);
}
";

enum fs =
"#version 330


in vertData {
	vec4 color;
	vec2 texCoord;
} vertIn;

out vec4 fragColor;

uniform sampler2D sampler;

void main()
{
	fragColor = texture2D(sampler, vertIn.texCoord) * vertIn.color;
}
";