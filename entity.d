module entity.entity;

import std.typecons;
import std.stdio;
import std.typetuple;

import entity.database;
import entity.physicssystem;

////////////////////////////////////////////////
///	Every component can be represented by 
///	an int representing the type
///	and an int for the index in the database.
////////////////////////////////////////////////
struct Component
{
	uint type;
	uint index;
}

/////////////////////////////////////////////////////////////////
///	Component type parameters will be accessible fast
///	Components added during runtime will be accessed by hashmap
/////////////////////////////////////////////////////////////////
struct Entity
{
	int id;
	Component[] components;
	bool hasComponent(T)() 
	{
		assert(0,"not yet implemented");
	}
}

unittest
{
	auto db = new DataBase!(TransformationComponent, BoundsComponent);
	writeln("SUCCESS");
	readln();
}