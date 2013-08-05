module textureatlas;

import graphics.enums;
import graphics.texture;
import math.vector;
import utils.image;
import frame;
import std.algorithm;
import std.stdio;
import frame;
import std.conv;
import std.string;

struct TextureAtlas
{
	private Frame[string] _frames;

	this(Frame[string] frames)
	{
		this._frames = frames;
	}


	Frame opIndex(string index)
	{
		return _frames[index];
	}

	static TextureAtlas load(string path)
	{
		auto pngLoader = new PngLoader();
		auto image = pngLoader.load(path ~ ".png");
		auto texture = Texture2D.create(image, InternalFormat.rgba8);

		auto frames = loadFrames(path ~ ".txt", texture);

		return TextureAtlas(frames);
	}	

	static auto loadFrames(string path, Texture2D texture) 
	{
		Frame[string] frames;
		foreach(line; std.stdio.File(path, ).byLine(KeepTerminator.no))
			parseFrame(std.string.chomp(line), texture, frames);
		return frames;
	}

	static void parseFrame(const (char)[] line, Texture2D texture, ref Frame[string] frames)
	{
		string name;
		float4 srcRect;
		uint i = 0;
		foreach(s; splitter(line, " "))
		{
			if(i == 0) name = s.idup;
			else if(i == 2) srcRect.x = to!float(s);
			else if(i == 3) srcRect.y = texture.height - to!float(s);
			else if(i == 4) srcRect.z = to!float(s);
			else if(i == 5)
			{
				srcRect.w = to!float(s);
				srcRect.y -= srcRect.w;
			}
	
			i++;
		}

		std.stdio.writeln(name, srcRect);

		frames[name] = Frame(texture, srcRect);
	}
}