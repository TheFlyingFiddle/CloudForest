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
import frame;

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

	protected void fix(Frame page, float size)
	{
		this._offset.y = size - _srcRect.w - _offset.y;

		this._textureCoords.x = page.coords.x + (this._srcRect.x / page.texture.width);
		this._textureCoords.y = page.coords.y + (this._srcRect.y / page.texture.height);
		this._textureCoords.z = page.coords.x + (this._srcRect.z  + this.srcRect.x) / page.texture.width;
		this._textureCoords.w = page.coords.y + (this._srcRect.w  + this.srcRect.y) / page.texture.height;
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
	private Frame _page;
	private CharInfo[] chars;

	@property Texture2D page() { return this._page.texture; }

	this(string face, float size, float lineHeight, Frame page, CharInfo[] chars)
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
		if(cast(uint)c < chars.length && chars[c] !is null)
			return chars[c];
		return unkownChar;
	}

	float2 messureString(T)(const (T)[] toMessure)
		if(is(T == char) || is(T == wchar) || is(T == dchar))
	{
		float2 cursor = float2(0,0);

		foreach(wchar c; toMessure)
		{
			if(c == '\r') continue;

			auto cc = cursor;
			if(c == ' ') {
				CharInfo spaceInfo = this[' '];
				cursor.x += spaceInfo.advance;
				continue;
			}	else if(c == '\n') {
				cursor.y -= lineHeight;
				cursor.x = 0;
				continue;
			} else if(c == '\t') {
				CharInfo spaceInfo = this[' '];
				cursor.x += spaceInfo.advance * tabSpaceCount;
				continue;
			}
			CharInfo info = this[c];
			cursor.x += (info.advance);
		}

		cursor.y += this.size;
		return cursor;
	}


	static Font load(string fontPath, Frame page) 
	{
		string face;
		float size;
		float lineHeight;
		CharInfo[] chars = new CharInfo[100];
		int id;

		foreach(line; std.stdio.File(fontPath).byLine())
		{
			foreach(word; splitter(strip(line)))
			{	
				if(word.length >= 2 && word[0 .. 2] == "id") {
					id = to!int(word[3 .. $]);
					if(chars.length <= id)
						chars.length = id + 1;
					chars[id] = new CharInfo();
				} else if(word.length >= 7 && word[0 .. 7] == "xoffset") {
					chars[id]._offset.x = to!float(word[8 .. $]); 
				} else if(word.length >= 7 && word[0 .. 7] == "yoffset") {
					chars[id]._offset.y = to!float(word[8 .. $]); 
				}  else if(word.length >= 8 && word[0 .. 8] == "xadvance") {
					chars[id]._advance = to!float(word[9 .. $]); 
				} else if(word[0 .. 1] == "x") {
					chars[id]._srcRect.x = to!float(word[2 .. $]);
				} else if(word[0 .. 1] == "y") {
					chars[id]._srcRect.y = page.srcRect.w - to!float(word[2 .. $]);
				} else if(word.length >= 4 && word[0 .. 4] == "face") {
					face = word[6 .. $ - 1].idup;
				} else if (word.length >= 4 && word[0 .. 4] == "size") {
					size = to!float(word[5 .. $]);
				} else if(word.length >= 5 && word[0 .. 5] == "width") {
					chars[id]._srcRect.z = to!float(word[6 .. $]);
				}  else if(word.length >= 6 && word[0 .. 6] == "height") {
					chars[id]._srcRect.y -= to!float(word[7 .. $]);
					chars[id]._srcRect.w = to!float(word[7 .. $]);
				} else if (word.length >= 4 && word[0 .. 4] == "chnl") {
					chars[id].fix(page, lineHeight);
				}  else if (word.length >= 10 && word[0 .. 10] == "lineHeight") {
					lineHeight = to!float(word[11 .. $]);
				} 
			}
		}
		return new Font(face, size, lineHeight, page, chars);
	}

	unittest {
		//	Font.load("C:/Users/Lukas/Desktop/test.fnt");
	}
}