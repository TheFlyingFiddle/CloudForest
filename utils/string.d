module utils.string;
public import std.utf;
import math.vector;

//Module that makes it possible to edit character strings
//without making a copy every time.

private static dchar[] buffer;
private size_t fillBuffer(in char[] str, uint startIndex)
{
	if(buffer.length < str.count + startIndex)
		buffer.length = str.count + startIndex;

	size_t s = 0;
	foreach(dchar c; str) {
		buffer[s + startIndex] = c;		
		s++;
	}
	return s;
}

void encodeString(ref char[] to, dchar[] buffer)
{
	to.length = 0;
	foreach(dchar c; buffer)
		encode(to, c);
}

void remove(ref char[] str, uint index)
{	
	auto size = fillBuffer(str, 0);
	foreach(i; index .. size - 1) 
		buffer[i] = buffer[i + 1];

	encodeString(str, buffer[0 .. size - 1]);
}

void remove(ref char[] str, uint2 range)
{
	auto size = fillBuffer(str, 0);
	foreach(i; range.x .. size - (range.y - range.x))
		buffer[i] = buffer[i + (range.y - range.x)];

	encodeString(str, buffer[0 .. size - (range.y - range.x)]);
}

void insert(ref char[] str, string toInsert, size_t index)
{
	auto size = fillBuffer(str, 0);
	auto insertSize = std.utf.count(toInsert);

	if(buffer.length < size + insertSize) {
		buffer.length = size + insertSize;

	}

	foreach_reverse(i; index + insertSize .. size + insertSize) 
		buffer[i] = buffer[i - toInsert.length];

	fillBuffer(toInsert, index);
	encodeString(str, buffer[0 .. size + insertSize]);
}

void freeBuffer()
{
	if(buffer.length > 0) {
		core.memory.GC.free(buffer.ptr);
		buffer.length = 0;
	}
}
