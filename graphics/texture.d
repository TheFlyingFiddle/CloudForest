module graphics.texture;

import graphics.errors;
import graphics.context;
import graphics.enums;
import graphics.buffer;
import std.traits : Flag;
import derelict.opengl3.gl3;

final class Sampler 
{
	package const uint glName;
	this()
	{
		uint glName;
		glGenSamplers(1, &glName);
		this.glName = glName;
	}

	void wrapT(WrapMode mode) @property
		out { assertNoGLError(); }
	body
	{
		glSamplerParameteri(glName, SamplerParam.wrapT, mode);
	}

	void wrapR(WrapMode mode) @property
		out { assertNoGLError(); }
	body
	{
		glSamplerParameteri(glName, SamplerParam.wrapR, mode);
	}

	void wrapS(WrapMode mode) @property
		out { assertNoGLError(); }
	body
	{
		glSamplerParameteri(glName, SamplerParam.wrapS, mode);
	}

	void minFilter(TextureMinFilter filter) @property
	{
		glSamplerParameteri(glName, SamplerParam.minFilter, filter);
	}

	void magFilter(TextureMagFilter filter) @property
	{
		glSamplerParameteri(glName, SamplerParam.magFilter, filter);
	}

	void minLod(float min) @property
	{
		glSamplerParameterf(glName, SamplerParam.minLod, min);
	}

	void maxLod(float max) @property
	{
		glSamplerParameterf(glName, SamplerParam.maxLod, max);
	}

	void compareMode(CompareMode mode)  @property
	{
		glSamplerParameteri(glName, SamplerParam.compareMode, mode);
	}

	void compareFunc(CompareFunc func) @property
	{
		glSamplerParameteri(glName, SamplerParam.compareMode, func);
	}

	bool deleted() @property
	{
		return glIsSampler(glName) == GL_FALSE;
	}

	void destroy() 
		in { assertNotDeleted(this); }
		out { assertNoGLError(); }
	body
	{
		glDeleteSamplers(1, &glName);
	}
}

class Texture
{
	uint glName;

	this(uint glName) {
		this.glName = glName;
	}

	abstract TextureTarget target() @property;

	static uint create()
	{
		uint glName;
		glGenTextures(1, &glName);
		return glName;
	}

	bool deleted() @property
	{
		return glIsTexture(glName) == GL_FALSE;
	}

	void destory() 
		in { assertNotDeleted(this); }
		out { assertNoGLError(); }
	body
	{
		glDeleteTextures(1, &glName);
	}
}

final class Texture1D : Texture
{
	const uint height;
	this(uint glName, uint height) {
		super(glName);	
		this.height = height;
	}

	override TextureTarget target() @property
	{
		return TextureTarget.texture1D; 
	}

	static Texture1D create(ColorFormat format, ColorType type, 
									InternalFormat internalFormat, uint width, 
									void[] data, Flag!"generateMipMaps" flag)
		out { assertNoGLError(); }
	body
	{
		auto texture = new Texture1D(Texture.create(), width);
		Context.textures[0] = texture;

		glTexImage1D(texture.target, 0, internalFormat, width, 0, format, type, data.ptr);
		glTexParameteri(texture.target, TextureParameter.baseLevel, 0);
		if(!flag)
			glTexParameteri(texture.target, TextureParameter.maxLevel, 0);
		else 
			glGenerateMipmap(texture.target);


		return texture;
	}
}

final class Texture2D : Texture
{
	public const uint width, height;
	this(uint glName, uint width, uint height) {
		super(glName);	
		this.width = width;
		this.height = height;
	}

	override TextureTarget target() @property 
	{ 
		return TextureTarget.texture2D; 
	}

	static Texture2D create(ColorFormat format, ColorType type, 
									InternalFormat internalFormat,
									uint width, uint height, void[] data,
									Flag!"generateMipMaps" flag) 	
		out { assertNoGLError(); } 
	body
	{
		auto texture = new Texture2D(Texture.create(), width, height);
		
		Context.textures[0] = texture;
		glTexImage2D(texture.target, 0, internalFormat, width, height, 0, format, type, data.ptr);
		
		glTexParameteri(texture.target, TextureParameter.baseLevel, 0);
		if(!flag)
			glTexParameteri(texture.target, TextureParameter.maxLevel, 0);
		else 
			glGenerateMipmap(texture.target);

		
		return texture;
	}
	static T[] getData(T)(uint offset, uint count, T[] output = null) 
	{
		assert(0);
	}
}

final class TextureCube : Texture
{
	const uint width, height;
	this(uint glName, uint width, uint height) {
		super(glName);	
		this.width = width;
		this.height = height;
	}

	override TextureTarget target() @property
	{ 
		return TextureTarget.textureCube; 
	}

	static TextureCube create(ColorFormat format, ColorType type, 
									InternalFormat internalFormat,
									uint width, uint height, 
									void[][] data ,
									Flag!"generateMipMaps" flag) 	 	
		in { assert(data.length == 6); }
		out { assertNoGLError(); } 
	body
	{
		auto texture = new TextureCube(Texture.create(), width, height);
		Context.textures[0] = texture;
	

		foreach(i, face; data) {
			glTexImage2D(texture.target, 0, internalFormat, width, height, 0, format, type, face.ptr);
		}

		glTexParameteri(texture.target, TextureParameter.baseLevel, 0);
		if(!flag)
			glTexParameteri(texture.target, TextureParameter.maxLevel, 0);
		else 
			glGenerateMipmap(texture.target);

		return texture;
	}
}

final class Texture3D : Texture
{
	const uint width, height, depth;
	this(uint glName, uint width, uint height, uint depth) {
		super(glName);	
		this.width = width;
		this.height = height;
		this.depth = depth;
	}

	override TextureTarget target() @property
	{ 
		return TextureTarget.texture3D;
	}

	static Texture3D create(ColorFormat format, ColorType type, 
									InternalFormat internalFormat,
									uint width, uint height,uint depth, void[] data ,
									Flag!"generateMipMaps" flag) 	
	out { assertNoGLError(); } 
	body
	{
		//I am not sure if this is correct. Will have to check laterz.
		auto texture = new Texture3D(Texture.create(), width, height, depth);

		Context.textures[0] = texture;
		glTexImage3D(texture.target, 0, internalFormat, width, height, depth, 0, format, type, data.ptr);

		glTexParameteri(texture.target, TextureParameter.baseLevel, 0);
		if(!flag)
			glTexParameteri(texture.target, TextureParameter.maxLevel, 0);
		else 
			glGenerateMipmap(texture.target);

		return texture;
	}
}

final class Texture2DArray : Texture 
{
	const uint width, height, layers;
	this(uint glName, uint width, uint height, uint layers) {
		super(glName);	
		this.width = width;
		this.height = height;
		this.layers = layers;
	}

	override TextureTarget target() @property 
	{ 
		return TextureTarget.texture2DArray; 
	}

	static Texture2DArray create(ColorFormat format, ColorType type, 
									InternalFormat internalFormat,
									uint width, uint height, 
									void[][] data ,
									Flag!"generateMipMaps" flag) 		
		out { assertNoGLError(); } 
	body
	{
		auto texture = new Texture2DArray(Texture.create(), width, height, data.length);

		Context.textures[0] = texture;

		glTexImage3D(texture.target, 0, internalFormat, width, height, data.length, 0, format, type, null);
		foreach(depth, layer; data) {
			glTexImage3D(texture.target, 0, internalFormat, width, height, depth, 0, format, type, layer.ptr);
		}

		glTexParameteri(texture.target, TextureParameter.baseLevel, 0);
		if(!flag)
			glTexParameteri(texture.target, TextureParameter.maxLevel, 0);
		else 
			glGenerateMipmap(texture.target);

		return texture;
	}
}

final class MultisampleTexture2D : Texture
{
	const uint samples, width, height;

	this(uint glName, uint samples, uint width, uint height) {
		super(glName);	
		this.width = width;
		this.height = height;
		this.samples = samples;
	}

	override TextureTarget target() @property 
	{
		return TextureTarget.texture2DMultisample;
	}

	static MultisampleTexture2D create(InternalFormat internalFormat,
										  uint samples ,uint width, uint height,
										  Flag!"fixedSampleLocations" flag) 	
	out { assertNoGLError(); } 
	body
	{
		auto texture = new MultisampleTexture2D(Texture.create(), samples, width, height);

		Context.textures[0] = texture;
		glTexImage2DMultisample(texture.target, samples, internalFormat, width, height, flag == flag.yes);
		return texture;
	}
}

final class MultisampleTexture2DArray : Texture
{
	const uint samples, width, height, layers;

	this(uint glName, uint samples, uint width, uint height, uint layers) {
		super(glName);	
		this.width = width;
		this.height = height;
		this.samples = samples;
		this.layers = layers;
	}


	override TextureTarget target() @property 
	{ 
		return TextureTarget.texture2DMultisampleArray;
	}

	static MultisampleTexture2DArray create(InternalFormat internalFormat,
												  uint samples,uint width, uint height, uint layers,
												  Flag!"fixedSampleLocations" flag) 	
	out { assertNoGLError(); } 
	body
	{
		auto texture = new MultisampleTexture2DArray(Texture.create(), samples, width, height, layers);

		Context.textures[0] = texture;
		glTexImage3DMultisample(texture.target, samples, internalFormat, width, height, layers, flag == flag.yes);
		return texture;
	}
}

final class BufferTexture : Texture
{
	
	this(uint glName) {
		super(glName);	
	}

	override TextureTarget target() @property 
	{ 
		return TextureTarget.textureBuffer;
	}

	static BufferTexture create(TextureBuffer buffer, InternalFormat format) 
	{
		auto texture = new BufferTexture(Texture.create());
		Context.textures[0] = texture;

		glTexBuffer(texture.target, format, buffer.glName);
		return texture;
	}

}


//TexSub image
void texSubImage(uint target, uint mipLevel, uint x, uint width, ColorFormat format, ColorType type, void[] data)
{
	glTexSubImage1D(target, mipLevel, x, width, format, type, data.ptr);
}

void texSubImage(uint target, uint mipLevel, uint x, uint y,
						 uint width, uint height, ColorFormat format, ColorType type, void[] data)
{
	glTexSubImage2D(target, mipLevel, x, y, width, height, format, type, data.ptr);
}

void texSubImage(uint target, uint mipLevel, uint x, uint y, uint z,
						 uint width, uint height, uint depth, ColorFormat format, ColorType type, void[] data)
{
	glTexSubImage3D(target, mipLevel, x, y, z, width, height, depth, format, type, data.ptr);
}

//Compressed Tex image
void compressedTexImage(uint target, uint mipLevel, InternalFormat internalFormat,
								uint width, uint imageSize, void[] data) 
{
	glCompressedTexImage1D(target, mipLevel, internalFormat, width, 0,imageSize, data.ptr);
}

void compressedTexImage(uint target, uint mipLevel, InternalFormat internalFormat,
								uint width, uint height, uint imageSize, void[] data) 
{
	glCompressedTexImage2D(target,mipLevel, internalFormat, width, height, 0,imageSize, data.ptr);
}

void compressedTexImage(uint target, uint mipLevel, InternalFormat internalFormat,
								uint width, uint height, uint depth, uint imageSize, void[] data) 
{
	glCompressedTexImage3D(target,mipLevel, internalFormat, width, height ,depth, 0, imageSize, data.ptr);
}

//CompressedSub Tex image
void compressedSubTexImage(uint target, uint mipLevel, InternalFormat internalFormat,
								   uint x, uint width, 
								   uint imageSize, void[] data) 
{
	glCompressedTexSubImage1D(target, mipLevel, x, width, internalFormat, imageSize, data.ptr);
}

void compressedSubTexImage(uint target, uint mipLevel, InternalFormat internalFormat,
								    uint x, uint y, uint width, uint height, uint imageSize, void[] data) 
{
	glCompressedTexSubImage2D(target, mipLevel, x, y, width, height, internalFormat, imageSize, data.ptr);
}

void compressedSubTexImage(uint target, uint mipLevel, InternalFormat internalFormat,
									 uint x, uint y, uint z, uint width, uint height,uint depth, uint imageSize, void[] data) 
{
	glCompressedTexSubImage3D(target, mipLevel, x, y, z, width, height, depth, internalFormat, imageSize, data.ptr);
}
