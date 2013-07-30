module font;

import std.algorithm;
import std.string;
import std.conv;
import std.path;
import std.typecons;
import math.vector;
import utils.image;
import graphics.enums;
import graphics.texture;

class CharInfo 
{
	protected float _advance;
	protected float4 _textureCoords;
	protected float4 _srcRect;
	protected float2 _offset;

	@property float advance() const { return _advance; } 
	@property float4 textureCoords() const { return _textureCoords; }
	@property float4 srcRect() const { return _srcRect; }
	@property float2 offset() const { return _offset; }

	this() {}

	protected void fix(Texture2D page)
	{
		this._textureCoords = this._srcRect;
		this._textureCoords.x /= (page.width);
		this._textureCoords.z /= (page.width);
		this._textureCoords.y /= (page.height);
		this._textureCoords.w /= (page.height);
	}
}

class Font
{
	int tabSpaceCount = 4;
	enum wchar unkownCharValue = '\u00A5';

	immutable string face;
	immutable float size;
	immutable float lineHeight;
	CharInfo unkownChar;
	private Texture2D _page;
	private CharInfo[] chars;

	@property Texture2D page() { return this._page; }

	this(string face, float size, float lineHeight, Texture2D page, CharInfo[] chars)
	{
		this.face = face;
		this.size = size;
		this.lineHeight = lineHeight;
		this._page = page;
		this.chars = chars;

		if(chars[unkownCharValue] is null)
			throw new Exception("Unkown character missing! :D");

		this.unkownChar = chars[unkownCharValue];
	}

	CharInfo opIndex(wchar c) 
	{
		if(chars[c] !is null)
			return chars[c];
		return unkownChar;
	}

	float2 messureString(string toMessure)
	{
		float2 size = float2.zero;
		float cursorX = 0;

		foreach(i, elem; toMessure)
		{
			char c = elem;
			if(c == '\r') //Ignore windows bullshit
				continue;

			if (c == '\n')
			{
				size.y += this.lineHeight;
				if (cursorX > size.x)
					size.x = cursorX;

				cursorX = 0;
				continue;
			}
			else if (c == '\t')
			{
				CharInfo ci = this[' '];
				cursorX += ci.advance * tabSpaceCount;
				continue;
			}

			CharInfo info = this[c];
			if (info is null)
			{
				info = this.unkownChar;
			}

			if (i != toMessure.length - 1)
				cursorX += info.advance;
			else
				cursorX += info.srcRect.w;
		}

		if (cursorX > size.x)
			size.x = cursorX;

		size.y += this.size;
		return size;
	}


	static Font load(string fontPath) 
	{
		string face;
		float size;
		float lineHeight;
		Texture2D page;
		CharInfo[] chars = new CharInfo[100];
		int id;

		auto loader = new PngLoader();
		uint width, height;
		auto imageData = loader.load(setExtension(fontPath, ".png"), width, height);
		page = Texture2D.create(ColorFormat.rgba, 
										ColorType.ubyte_, 
										InternalFormat.rgba8,
										width, height, imageData,
										No.generateMipMaps);

		foreach(line; std.stdio.File(fontPath).byLine())
		{
			foreach(word; splitter(strip(line)))
			{	
				std.stdio.writeln(word);
				if(word.length >= 2 && word[0 .. 2] == "id") {
					id = to!int(word[3 .. $]);
					if(chars.length <= id)
						chars.length = id + 1;
					chars[id] = new CharInfo();
				} else if(word.length >= 7 && word[0 .. 7] == "xoffset") {
					chars[id]._offset.x = to!float(word[8 .. $]); 
				} else if(word.length >= 7 && word[0 .. 7] == "yoffset") {
					chars[id]._offset.y = -to!float(word[8 .. $]); 
				}  else if(word.length >= 8 && word[0 .. 8] == "xadvance") {
					chars[id]._advance = to!float(word[9 .. $]); 
				} else if(word[0 .. 1] == "x") {
					chars[id]._srcRect.x = to!float(word[2 .. $]);
				} else if(word[0 .. 1] == "y") {
					chars[id]._srcRect.y = page.height - to!float(word[2 .. $]);
				} else if(word.length >= 4 && word[0 .. 4] == "face") {
					face = word[6 .. $ - 1].idup;
					std.stdio.writeln(face);
				} else if (word.length >= 4 && word[0 .. 4] == "size") {
					size = to!float(word[5 .. $]);
					std.stdio.writeln(size);
				} else if(word.length >= 5 && word[0 .. 5] == "width") {
					chars[id]._srcRect.w = to!float(word[6 .. $]);
				}  else if(word.length >= 6 && word[0 .. 6] == "height") {
					chars[id]._srcRect.y -= to!float(word[7 .. $]);
					chars[id]._srcRect.w = to!float(word[7 .. $]);
				} else if (word.length >= 4 && word[0 .. 4] == "chnl") {
					chars[id].fix(page);
				}  else if (word.length >= 10 && word[0 .. 10] == "lineHeight") {
					lineHeight = to!float(word[11 .. $]);
					std.stdio.writeln(lineHeight);
				} 
			}
		}
		return new Font(face, size, lineHeight, page, chars);
	}

	unittest {
		//	Font.load("C:/Users/Lukas/Desktop/test.fnt");
	}
}