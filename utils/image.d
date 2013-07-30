module utils.image;

import std.file,
		 std.stdio,
		 std.math,
		 std.algorithm,
		 std.conv,
		 std.zlib,
		 std.stream,
		 std.exception;

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

class Image
{
	const uint width, height;
	ubyte[] data;
	uint channels;

	bool flipCoords;

	this(uint width, uint height, uint channels, bool flipCoords) 
	{
		this.width = width;
		this.height = height;
		this.channels = channels;
		this.flipCoords = flipCoords;
		this.data = new ubyte[width * height * channels];
	}

	auto row() 
	{
		struct RowIndexer
		{
			Image image;
			void opIndexAssign(ubyte[] row, uint index) 
			{
				uint begin;
				if(image.flipCoords) 
					begin = (image.height - index - 1) * image.width * image.channels;
				else 
					begin = index * image.width * image.channels;

				image.data[begin .. begin + row.length] = row[0 .. $];
			}
		}
		return RowIndexer(this);
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
	
	struct PngChunk
	{
		uint size;
		ChunkType type;
		ubyte* data;
	}

}

enum ChunkType
{
	IHDR = 0x49_48_44_52,
	PLTE = 0x50_4C_54_45,
	IDAT = 0x49_44_41_54,
	IEND = 0x49_45_4E_44,
}

align(1) {
	struct PaleteColor
	{
		ubyte red;
		ubyte green;
		ubyte blue;
	}
}

struct Palete
{
	uint size;
	PaleteColor[256] colors;
}


align(1) {
	struct IHDR
	{
		uint width;
		uint height;
		ubyte bitDepth;
		PNGColorType colorType;
		ubyte compressionMethod;
		ubyte filterMethod;
		ubyte interlaceMethod;

		string toString() 
		{
			return std.string.format("IDHR:\nWidth : %s\nHeight : %s\nBit depth: %s"
											 ~ "\nColor Type: %s \nComression method: %s"
											 ~ "\nFilter method: %s \nInterlace method: %s",
											 width, height, bitDepth,
											 colorType, compressionMethod,
											 filterMethod, interlaceMethod);
		}

	} }

enum PNGColorType
{
	grayscale = 0,
	rgb = 2,
	palette = 3,
	grayscaleAlpha = 4,
	rgba = 6
}

struct InterlaceHelper
{
	int[] startingRow  = [ 0, 0, 4, 0, 2, 0, 1 ];
	int[] startingCol  = [ 0, 4, 0, 2, 0, 1, 0 ];
	int[] rowIncrement = [ 8, 8, 8, 4, 4, 2, 2 ];
	int[] colIncrement = [ 8, 8, 4, 4, 2, 2, 1 ];
	int[] blockHeight  = [ 8, 8, 4, 4, 2, 2, 1 ];
	int[] blockWidth   = [ 8, 4, 4, 2, 2, 1, 1 ];

}

class PngLoader 
{
	static Palete palete;

	uint height, width;
	uint channels, bitsPerChannel;
	bool interlaced;
	uint scanLineSize;

	ubyte[] scanline0;
	ubyte[] scanline1;
	uint scanlineCount;

	Image image;
	
	UnCompress uncompressor;
	
	bool iDatAppeared;
	bool paletted;
	bool done;

	private void setup()
	{
		uncompressor = new UnCompress();
		scanline0.length = 0;
		scanline1.length = 0;
		done = false;
		paletted = false;
		iDatAppeared = false;
		interlaced = false;
		scanLineSize = 0;
		channels = 0;
		bitsPerChannel = 0;
		height = 0;
		width = 0;
		palete.size = 0;
		scanlineCount = 0;
	}

	void[] load(const (char)[] file, out uint width, out uint height, bool performValidation = true) 
	{
		ubyte[] bytes = cast(ubyte[])read(file);
		setup();

		ubyte* ptr = bytes.ptr;
		ensureHeader(ptr);

		while(!done) {

			PngChunk chunk = parseChunk(ptr);
			processChunk(chunk);
		}
	
		width = this.width;
		height = this.height;
		return image.data;
	}

	void processChunk(ref PngChunk chunk) 
	{
		alias ChunkType CT;
		switch(chunk.type) 
		{	
			case CT.IHDR:
				processIHDR(chunk);
				break;
			case CT.PLTE:
				processPLTE(chunk);				
				break;
			case CT.IDAT:
				processIDAT(chunk);
				break;
			case CT.IEND:
				processIEND();
				break;
			default:
				writeln("Unknown chunk type");
				break;
		}
	}

	void processIHDR(ref PngChunk chunk) 
	{
		IHDR ihdr = parseIHDR(chunk.data);
		validateIHDR(ihdr, chunk);

		width = ihdr.width;
		height = ihdr.height;
		bitsPerChannel = ihdr.bitDepth;
		interlaced = ihdr.interlaceMethod == 1;
		channels = selectChannels(ihdr);

		scanLineSize = width * channels;
		if(bitsPerChannel < 8) 
			scanLineSize = (scanLineSize + 1 ) / (8 / bitsPerChannel);
		
		//Scan lines are one byte larger to accomodate the filter byte.
		scanLineSize++;
		
		image = new Image(width, height, channels, true);
	}

	void validateIHDR(in IHDR ihdr, in PngChunk chunk)
	{
		enforce(chunk.size == 13);
		alias PNGColorType CT;
		switch(ihdr.bitDepth) 
		{
			case 1 , 2,  4:
				enforce(ihdr.colorType == CT.grayscale || 
						  ihdr.colorType == CT.palette);
				break;
			case 16:
				enforce(ihdr.colorType == CT.grayscale	     || 
						  ihdr.colorType == CT.grayscaleAlpha ||
						  ihdr.colorType == CT.rgb				  ||
						  ihdr.colorType == CT.rgba);
				break;
			case 8:
				break;
			default :
				throw new Exception("IHDR corrupted invalid bitsize");
		}

		enforce(ihdr.compressionMethod == 0);
		enforce(ihdr.filterMethod == 0);
	}

	uint selectChannels(in IHDR ihdr)
	{
		alias PNGColorType CT;
		switch(ihdr.colorType) 
		{
			case CT.grayscale :
				return bitsPerChannel < 8 ? 1 : 2;
			case CT.grayscaleAlpha :
				return bitsPerChannel == 8 ? 2 : 4;
			case CT.rgb :
				return bitsPerChannel == 8 ? 3 : 6;
			case CT.rgba :
				return bitsPerChannel == 8 ? 4 : 8;
			case CT.palette :
				return 1;
			default: 
				throw new Exception("PNG IHDR chunk corrupted " ~ to!string(ihdr));
		}
	}

	void processPLTE(ref PngChunk chunk) 
	{
		if(paletted || iDatAppeared) 
			throw new Exception("PLTE chunk may only appear ONCE befoure any IDAT chunks in a png file!");

		uint size = chunk.size / 3;
		if(chunk.size % 3 != 0 || size > palete.colors.length)
			throw new Exception("PLTE chunc corrupted!");

		palete.size = size;
		foreach(i; 0 .. size) {
			palete.colors[i] = *cast(PaleteColor*)(*chunk.data);
			chunk.data += PaleteColor.sizeof;
		}

		paletted = true;
	}

	void processIDAT(ref PngChunk chunk) 
	{
		iDatAppeared = true;

		auto data = cast(ubyte[])uncompressor.uncompress(chunk.data[0 .. chunk.size]);
		processData(data);
	}


	uint pass = 0;
	uint row, column;
	void processInterlacedData(ubyte[] data) 
	{
		assert(0);
	}


	void processData(ubyte[] data) 
	{	
		uint index, nIndex;
		
		if(scanline0.length > 0) {
			nIndex = index + scanLineSize - scanline0.length;			
			scanline0 ~= data[index .. nIndex];
			processScanLine();
			index = nIndex;
		}

		while(data.length - index > scanLineSize - scanline0.length)
		{
			nIndex = index + scanLineSize - scanline0.length;			
			scanline0 = data[index .. nIndex];

			processScanLine();
			index = nIndex;
		}
		
		scanline0 ~= data[index .. $];
	}

	void processScanLine() 
	{
		auto type = scanline0[0];
		if(type == 0) {
		} else if(type == 1) {
			convertSub();
		} else if(type == 2) {
			convertUp();
		} else if(type == 3) {
			convertAverage();
		} else if(type == 4) {
			convertPaeth();
		}
		
		image.row[scanlineCount++] = scanline0[1 .. $];
		swap(scanline0, scanline1);
		scanline0.clear();
	}

	void convertSub()
	{
		for(size_t i = channels+1; i < scanline0.length; i+=channels)
		{
			scanline0[i .. i + channels] += scanline0[i - channels .. i];
		}
	}

	void convertUp()
	{
		scanline0[] += scanline1[];
	}

	void convertAverage()
	{
		for(size_t i = channels+1; i < scanline0.length; i++)
		{
			scanline0[i] += floor((scanline0[i - channels] + 
								        scanline1[i]) / 2);
		}
	}

	void convertPaeth()
	{
		int paethPredictor(int a, int b, int c) 
		{
			int p  = (a + b - c);
			int pa = abs(p - a);
			int pb = abs(p - b);
			int pc = abs(p - c);

			if(pa <= pb && pa <= pc) return a;
			else if(pb <= pc)			 return b;
			else						    return c;
		}

		for(size_t i = 0; i < scanline0.length; i++)
		{
			ubyte a = i < channels + 1? 0 : scanline0[i - channels];
			ubyte b = scanline1[i];
			ubyte c = i < channels + 1? 0 : scanline1[i - channels];

			scanline0[i] += paethPredictor(a,b,c);
		}
	}

	void processIEND() 
	{
		auto data = cast(ubyte[])uncompressor.flush();
		processData(data);
		done = true;
	}

	IHDR parseIHDR(ref ubyte* bytes)
	{
		IHDR ihdr;
		ihdr.width		        = parseUint(bytes);
		ihdr.height		        = parseUint(bytes);
		ihdr.bitDepth	        = *(bytes++);
		ihdr.colorType			  = cast(PNGColorType)*(bytes++);
		ihdr.compressionMethod = *(bytes++);
		ihdr.filterMethod	     = *(bytes++);
		ihdr.interlaceMethod   = *(bytes++);
		return ihdr;
	}


	void ensureHeader(ref ubyte* bytes) 
	{
		PngHeader h = *cast(PngHeader*)bytes;
		enforce(h.transmissionByte == 0x89);
		enforce(h.pngSignature == "PNG");
		enforce(h.dosLineEnding == [0x0D,0x0A]);
		enforce(h.dosEndOfFile == 0x1A);
		enforce(h.unixLineEnd == 0x0A);

		bytes += PngHeader.sizeof;
	}

	PngChunk parseChunk(ref ubyte* bytes)
	{
		PngChunk chunk;
		chunk.size = parseUint(bytes);
		ubyte* p = bytes;
		chunk.type = cast(ChunkType)parseUint(bytes);		
		chunk.data = bytes;

		bytes += chunk.size;
		
		uint chunkCrc = parseUint(bytes);
		uint crc = crc32(0 , cast(void[])(p[0 .. chunk.size + 4]));
			
		if(chunkCrc != crc) 
			throw new Exception("Corrupted crc");
		
		return chunk;
	}

	static uint parseUint(ref ubyte* bytes) 
	{
		version(LittleEndian) {
			return (*(bytes++) << 24) |
					 (*(bytes++) << 16) |
					 (*(bytes++) << 8) |
					 (*(bytes++));
		} else {
			uint i = *cast(uint*)bytes;
			bytes += uint.sizeof;
			return i;
		}
	}
}