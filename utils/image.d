module utils.image;

import std.file, std.stdio;

struct BmpHeader {
	ubyte[2] id;
	align(1) 
	{
		uint fileSize;
		uint reserved;
		uint offset;
		uint infoHeaderLength;
		uint width;
		uint height;
		ushort planes;
		ushort bitsPerPixel;
		uint compressionType;
		uint sizOfPicture;
		uint horizontalRes;
		uint verticalRes;
		uint numberOfUsedColors;
		uint numberOfImportantColors;
	}
}

struct BmpLoader {

	static void[] load(string file, out uint width, out uint height) 
	{
		BmpHeader h;
		void[] bytes = read(file);
		h = *cast(BmpHeader*)&bytes[0];
		assert(h.id == ['B','M']);

		width = h.width;
		height = h.height;

		return bytes[h.offset .. (h.width * h.height * (h.bitsPerPixel / 8))];
	}
}


align(1) {
	struct PngHeader
	{
		ubyte transmissionByte;
		ubyte[3] pngSignature;
		ubyte[2] dosLineEnding;
		ubyte dosEndOfFile;
		ubyte unixLineEnd;
	}
}


struct LoadPng 
{
	static void[] load(string file, out uint width, out uint height) 
	{
		void[] bytes = read(file);
		PngHeader h = *cast(PngHeader*)bytes.ptr;
		
		assert(h.transmissionByte == 0x89);
		assert(h.pngSignature == "PNG");
		assert(h.dosLineEnding == [0x0D,0x0A]);
		assert(h.dosEndOfFile == 0x1A);
		assert(h.unixLineEnd == 0x0A);

		writeln(h);
		return null;
	}

}