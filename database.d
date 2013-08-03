module entity.database;


import std.conv;
import entity.system;
import entity.physicssystem;
import std.stdio;
import std.range;
import std.algorithm;

interface IDataBase
{
	void allocateFor(T:IComponent)(uint space);
	T get(T:IComponent)(uint goid);
}

class DataBase(ComponentTypes...) : IDataBase
{


	void allocateFor(T:IComponent)(uint space)
	{

	
	}

	void lol()
	{
		writeln(iota(ComponentTypes.length).map!(i => ("ComponentTypes["~to!string(i)~"] comps"~to!string(i)~";")).join());
	}

	T get(T:IComponent)(uint goid);
}

unittest
{
	auto db = new DataBase!(IBoundsComponent, ITransformationComponent)();
	writeln(db);db.lol();
	readln();
}