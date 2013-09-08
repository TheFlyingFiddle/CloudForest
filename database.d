module entity.database;

private string createArrays(T...)()
{
	string s;
	foreach(t; T) 
		s ~= t.stringof ~ "[] _" ~ array!t ~ ";\n";
	return s;
}

template array(T)
{
	enum array = "_" ~ T.stringof ~ "Array";
}

class Database(T...)
{
	mixin(createArrays!T);
	bool[] free;
	
	this(size_t size) 
	{
		initArrays(size);
	}

	void initArrays(size_t size)
	{
		free.length = size;
		free[] = true;
		foreach(t; T)  
			mixin(array!t ~ ".length = size;");
		
		foreach(i; 0 .. size)
			setToDefault(i);
	}

	U[] items(U)()
	{
		mixin("return " ~ array!U ~ ";");
	}

	void add(U...)(U u)
	{
		size_t index = freeIndex();
		foreach(i, t;U) 
			mixin(array!t ~ "[index] = u[i];");
	}

	size_t freeIndex()
	{
		foreach(i, f; free) if(f) return i;
		throw new Exception();
	}
	
	void remove(size_t index)
	{
		free[index] = true;
		setToDefault(index);
	}

	void setToDefault(size_t index)
	{
		foreach(t;T) 
			mixin(array!t ~ "[index] = "~ t.stringof ~ ".default;");
	}	
}

template isDatabase(T)
{
	static if(is(T t == Database!U, U...))
		enum isDatabase = true;
	else
		enum isDatabase = false;
}

class PosSystem(T) if(isDatabase!T) : ISystem 
{
	Position[] pos;
	Velocity[] velo;
	Acceleration[] acc;

	this(T database) 
	{
		pos   = database.items!Position;
		velo  = database.items!Velocity;
		acc	= database.items!Acceleration; 
	}

	void process()
	{
		velo[] += acc[];
		pos[]  += velo[];
	}
}


struct Position
{
	float2 data;
}

struct Velocity
{
	float2 data;
}

struct Acceleration
{
	float2 data; 
}