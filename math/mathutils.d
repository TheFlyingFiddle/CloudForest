module math.mathutils;

template isInteger(T)
{
	enum isInteger =	is(T==ubyte)	||	is(T==byte)		||
							is(T==ushort)	||	is(T==ushort)	||
							is(T==uint)		||	is(T==int)		||
							is(T==ulong)	||	is(T==long);
}