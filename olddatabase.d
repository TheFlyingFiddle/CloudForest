module entity.olddatabase;

private string createArrays(T...)()
{
	string s;

	foreach(i, t;T) {
		static if(i % 3 == 0)
			s ~= t.stringof ~ "[] ";
		else static if(i % 3 == 2)
			s ~= t ~ ";";
	}

	return s;
}

class OldDatabase(T...) if(T.length % 3 == 0)
{
	mixin(createArrays!T);
	bool[] free;
	size_t count;
	
	this(size_t size) 
	{
		this.count = size;
		initArrays(size);
	}

	void initArrays(size_t size)
	{
		free.length = size;
		free[] = true;
		
		foreach(i, t;T) {
			static if(i % 3 == 2)
				mixin(t ~ ".length") = size;
		}

		foreach(i; 0 .. size)
			setToDefault(i);
	}

	private void add(Prefab)(Prefab p) 
	{
		size_t index = freeIndex();
		foreach(i, m; p.tupleof)	{
			enum name = Prefab.tupleof[i].stringof[Prefab.stringof.length + 3 .. $];
			mixin(name ~ "[index]") = m;
		}
	}

	private void add(U...)() if(U.length % 2 == 0)
	{
		size_t index = freeIndex();
		foreach(i, t;U) {
			static if(i % 2 == 0) {
				mixin(t ~ "[index]") = U[i + 1];
			}
		}
	}

	void remove(size_t index)
	{
		free[index] = true;
		setToDefault(index);
	}

	size_t freeIndex()
	{
		foreach(i, f; free) if(f) return i;
		throw new Exception("Database full");
	}

	void setToDefault(size_t index)
	{	
		foreach(i, t;T) {
			static if(i % 3 == 2)
				mixin(t ~ "[index]") =  T[i -1];
		}
	}	
}


template isDatabase(T)
{
	static if(is(T t == OldDatabase!U, U...))
		enum isDatabase = true;
	else
		enum isDatabase = false;
}

import math.vector;
unittest
{
	alias OldDatabase!(float2, float2.zero, "position",
						 float2, float2.zero, "velocity",
						 float2, float2.zero, "acceleration") DB;

	auto db = new DB(100_000);
	auto pos = new PosSystem!(DB)();

	struct Sheep
	{
		float2 position = float2(10, 10);
		float2 velocity = float2(12, 12);
		float2 acceleration = float2(1,1);
	}

	foreach(i; 0 .. db.count) {
		db.add!(Sheep)(Sheep());
	}

	import std.stdio;
	writeln("OLD BENCHMARK______________________________________________");
	//benchmark(db, pos);
}

void benchmark(DB,P)(DB d, P p)
{
	import std.datetime;
	ulong sum;
	foreach(i; 0 .. 100) 
	{
		auto times = benchmark!({ p.process(d); })(60)[0].msecs;
		sum += times;
		std.stdio.writeln(times);
	}
	
	std.stdio.writeln("Avg time: ", sum / 100);
}

class PosSystem(T) if(isDatabase!T)
{
	void process(T db)
	{
		for(int i = 0; i < db.count; i++) {
			db.velocity[i] += db.acceleration[i];
			db.position[i] += db.velocity[i];
		}
	}
}