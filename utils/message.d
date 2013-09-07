module utils.message;
import std.conv;


private string createFields(T...)()
{
	string fields;

	foreach(i, type; T)
	{
		fields ~= "T[" ~ to!string(i) ~ "][] _" ~ type.stringof ~ ";\n";
	}

	return fields;
}


final class MessageBus(T...)
{
	mixin(createFields!T());	

	void opOpAssign(string op, M)(M msg) if(op == "~")
	{
		mixin("_" ~ M.stringof ~ "~= msg;");
	}

	M[] messages(M)()  @property
	{
		mixin("return _" ~ M.stringof ~ ";");
	}

	void clear()
	{
		foreach(type;T) 
			mixin("_" ~ type.stringof ~ ".length = 0;");
	}
}

unittest 
{
	struct A { int a; }
	struct B { int b; }
	struct C { int c; }
	struct D { int d; }

	auto bus = new MessageBus!(A,B,C,D)();

	bus ~= A(1);
	bus ~= A(2);
	bus ~= B(1);
	bus ~= B(10);
	bus ~= D(3);
	bus ~= D(32);

	assert(bus.messages!A[0] == A(1));
	assert(bus.messages!A[1] == A(2));
	assert(bus.messages!B[1] == B(10));
	assert(bus.messages!D[0] == D(3));

	bus.clear();

	assert(bus.messages!B().length == 0);
}