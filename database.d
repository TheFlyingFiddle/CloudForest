module entity.database;
import std.exception;

class Database
{
	struct Row
	{
		TypeInfo tInfo;
		string   name;
		void[]	data;

		void* ptr(size_t index)
		{
			return &data.ptr[index * tInfo.tsize];
		}

	}

	private size_t count;
	
	private Row[] rows;
	private void[][] defaultData;
	private bool[] free;

	this(size_t count) 
	{ 
		this.count = count; 
		free.length = count;
		free[] = true;
	}

	void addRow(T)(string name, T def)
	{
		enforce(std.algorithm.find!((a)=>a.name == name)(rows).length == 0, "Row already has row associated with name "~name);

		void[] p = [def];
		T[] rowArr = new T[](count);
		rowArr[] = def;
		auto row = Row(typeid(T), name, cast(void[])rowArr);
		rows ~= row;
		defaultData ~= p;
	}

	size_t add(P)(P p)
	{
		size_t index = nextFree();
		foreach(i, m; p.tupleof)	{
			enum name = P.tupleof[i].stringof[P.stringof.length + 3 .. $];
			auto row = findRow(name);
			typeof(P.tupleof[i])* data = cast(typeof(P.tupleof[i])*)row.ptr(index);
			*data = m;
		}
		return index;
	}

	size_t addPrefab(Prefab prefab)
	{
		import std.c.string;
		auto index = nextFree();
		foreach(data;prefab.data)
		{
			auto row = rows[data.id];
			memcpy(row.ptr(index), data.data.ptr, row.tInfo.tsize);
		}
		return index;
	}

	size_t nextFree()
	{
		foreach(i,b;free) {
			if (b) { 
				free[i] = false;
				return i;
			}
		}
		throw new Exception("Database is full");
	}

	void removeCollumn(size_t index)
	{
		import std.c.string;
		foreach(i; 0 .. rows.length)
		{
			Row row = rows[i];
			void* to = row.ptr(index);
			void* from = defaultData[i].ptr;
			memcpy(to, from, row.tInfo.tsize); 
		}
		free[index] = true;
	}

	T[] row(T)(string m)
	{
		Row row = findRow(m);
		if (typeid(T) == row.tInfo)
			return cast(T[]) row.data;
		throw new Exception("Type mismatch between "~T.stringof~" and row "~m~"(Of type "~row.tInfo.toString~")");
	}

	Row findRow(string name)
	{
		foreach(row;rows){
			if(row.name == name)
				return row;
		}
		throw new Exception("No row with name "~name);
	}

	size_t findIndex(string name)
	{
		foreach(i, row;rows){
			if(row.name == name)
				return i;
		}
		throw new Exception("No row with name "~name);
	}

	Prefab createPrefab()
	{
		return new Prefab(this);
	}

}

class Prefab
{
	struct Data
	{
		string name;
		size_t id;
		void[] data;
	}
	Data[] data;
	Database db;

	private this(Database db)
	{
		this.db = db;
	}

	void add(T)(T t, string name)
	{
		auto row = db.findRow(name);
		enforce(std.algorithm.find!((a)=>a.name == name)(data).length == 0,
				  "Prefab already has data associated with name "~name);
		enforce(row.tInfo == typeid(T), "Type mismatch for row "~name~".
				  Found: "~T.stringof~". 
				  Expected: "~row.tInfo.toString);
		data ~= Data(name, db.findIndex(name), cast(void[])([t]));
	}

	void remove(string name)
	{
		auto index = std.algorithm.countUntil!((a)=>a.name == name)(data);
		data = std.algorithm.remove(data, index);
	}

	size_t instantiate()
	{
		return db.addPrefab(this);
	}
}

unittest
{
	import std.stdio;
	import math.vector;
	import std.exception;
	auto db = new Database(8);
	
	db.addRow("position", float2(float.infinity,float.infinity));
	db.addRow("velocity", float2(0,0));
	db.addRow("health", 0);

	assertThrown(db.addRow("health",2));

	struct Frog
	{
		float2 position;
		float2 velocity;
		int health;
	}

	foreach(i;0..4){
		db.add(Frog(float2(i,i), float2(1,1), 100));
	}
	
	auto prefab = db.createPrefab;

	assertThrown(prefab.add(float3(1,2,3), "position"));

	prefab.add(float2(2,10), "position");
	prefab.add(float2(1,2), "velocity");
	prefab.add(1230, "health");

	db.addPrefab(prefab);

	prefab.instantiate;

	assertThrown(prefab.add(0,"blargh"));

	db.removeCollumn(3);
	db.removeCollumn(5);
	db.addPrefab(prefab);

	assertThrown(db.row!float3("position"));

	assertThrown(db.row!float2("mnarglbhlarghl"));

	writeln(db.row!float2("position"));
	writeln(db.row!float2("velocity"));
	writeln(db.row!int("health"));
}

unittest
{
	import math.vector;
	import std.random;
	auto db = new Database(100_000);

	db.addRow("position", float2(200,2000));
	db.addRow("velocity", float2(0,0));
	db.addRow("acceleration", float2(0,0));

	foreach(i;0..100_000)
	{
		if(uniform(0,100) < 50)
			db.add(Struts(float2(1,2),float2(1,4),float2(56,3)));
	}

	auto ps = new PosSystem(db);

	import std.stdio;
	writeln("NEW BENCHMARK______________________________________________");
	benchmark(ps, db);

	auto db2 = new Database(100_000);

	db2.addRow("strutsar", Struts(float2(1,2),float2(3,4),float2(5,6)));

	foreach(i;0..100_000)
	{
		if(uniform(0,100) < 50)
			db2.add(Strutsy(Struts(float2(1,2),float2(1,4),float2(56,3))));
	}

	auto ps2 = new PosSystem2(db2);

	benchmark(ps2, db2);
	
}

struct Struts
{
	import math.vector;
	float2 position;
	float2 velocity;
	float2 acceleration;
}

struct Strutsy
{
	Struts strutsar;
}

void benchmark(PS)(PS ps, Database db)
{
	import std.datetime;
	ulong sum;
	foreach(i; 0 .. 100) 
	{
		auto times = benchmark!({ ps.process(0, db.count, db.free); })(1000)[0].nsecs;
		sum += times;
		std.stdio.writeln(times / 1000_000_000.0f);
	}

	std.stdio.writeln("Avg time: ", sum / (100 * 1000));
}

void sysfor(size_t start, size_t end, bool[] free, void delegate(size_t i) p)
{
	for(size_t i = start; i < end; i++)
	{
		if(free[i])
			p(i);
	}
}

class PosSystem
{
	import math.vector;
	float2[] positions;
	float2[] velocities;
	float2[] accelerations;

	this(Database db)
	{
		positions		= db.row!float2("position");
		velocities		= db.row!float2("velocity");
		accelerations	= db.row!float2("acceleration");
	}

	void process(size_t start, size_t end, bool[] free)
	{
		for(size_t i = start; i < end; i++)
		{
			if(free[i]) continue;

			velocities[i] += accelerations[i];
			positions[i] += velocities[i];
		}
	} 

/*	void process(size_t start, size_t end, bool[] free)
	{
		sysfor(start, end, free, (i)
		{
			velocities[i] += accelerations[i];
			positions[i] += velocities[i];

		});
	} */
}

class PosSystem2
{
	import math.vector;
	Struts[] strutsar;

	this(Database db)
	{
		strutsar = db.row!Struts("strutsar");
	}

	void process(size_t start, size_t end, bool[] free)
	{
		for(size_t i = start; i < end; i++)
		{

			auto struts = &strutsar[i];
			struts.velocity += struts.acceleration;
			struts.position += struts.velocity;
		}
	}
}