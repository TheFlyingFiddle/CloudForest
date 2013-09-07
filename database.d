module entity.database;


import std.conv;
import std.stdio;
import std.range;
import std.traits;
import std.algorithm;
import std.string;
import math.mathutils;
import utils.strings;
import utils.assertions;
import entity.system;
import entity.physicssystem;
import entity.entity;

interface IDataBase
{
	T* alloc(T)(T comp = T.init);
}

template allImplements(iFace, Types...)
{
	static if (Types.length == 0)
	{
		enum allImplements = true;
	}
	else static if (is(Types[0]:iFace))
	{
		enum allImplements = allImplements!(iFace, Types[1..$]);
	}
	else
	{
		enum allImplements = false;
	}
}

class DataBase(ComponentTypes...) : IDataBase
{
	mixin(buildComponentArrays!(ComponentTypes)());
	mixin(buildComponentMapTemplate!(ComponentTypes)());
	mixin(buildOpIndex!(ComponentTypes)());
	

	///Builds a template which more or less is a compile-time map from simple names to types. Ex: position => IPositionComponent
	private static string buildComponentMapTemplate(Types...)()
	{
		string templateCode = 
			"public template ComponentType(string name)
			{";
		foreach(type;Types)
		{
			templateCode ~= text(
				"static if (name == ",CompSimpleName!type,")
				{
					enum ComponentType = ", type,";
				} 
				else ");
		}
		templateCode ~= 
					"{ static assert(false, \"No component type registered for name \"~name); }
			}";
		return templateCode;
	}

	///Builds a template which more or less is a compile-time map from simple names to types. Ex: position => IPositionComponent
	private static string buildComponentMapTemplate(Types...)()
	{
		string templateCode = 
			"public template TypeIndex(T)
			{";
		foreach(i,type;Types)
		{
			templateCode ~= text(
				"static if (is(T == ",type,")
				{
					enum TypeIndex = ", i,";
				}
				else ");
		}
		templateCode ~= 
					"{ static assert(false, \"No component type registered for name \"~name); }
			}";
		return templateCode;
	}

	private static string buildComponentArrays(Types...)()
	{
		string toReturn = "";
		foreach(type;Types)
		{
			auto name = fullyQualifiedName!type;
			toReturn ~= text(name,"[] ",CompSimpleName!(type)~"Comps",";");
		}
		return toReturn;
	}	


	private static string buildOpDispatch(Types...)()
	{
		string templateCode = "private auto opDispatch(string m)(uint index)
			{";
		foreach(i,type;Types)
		{
			templateCode ~= text(
				"if (index == ",i,")
				{
					return ", arrayName!type,";
				} 
				else ");
		}
		templateCode ~= text(
			"{assert(false, text(\"Component type index out of bounds: \",index,
													\"\n Max index was: \", ",Types.length,"));}
			}");
		return templateCode;
	}

	private template arrayName(T)
	{
		enum arrayName = CompSimpleName!T ~ "Comps";
	}

	T* alloc(T)(T comp = T.init)
	{
		mixin(text(arrayName!T," ~= comp;\n",
					  "return &",arrayName!T,"[$];"));
	}

	auto getComponentPointer()(Component comp)
	{
		return &(this[comp.type][comp.index]);
	}

	T* getPropertyPointer(ComponentType)(int index)
	{
		return mixin(text("this.",CompSimpleName!ComponentType,"[",index,"]"));
	}

	public template TypeId(T)
		if (staticIndexOf(T, ComponentTypes)>=0)
	{
		
	}
}

unittest
{
	auto db = new DataBase!(BoundsComponent, TransformationComponent)();
	auto bPtr = db.alloc!BoundsComponent();
	assertEquals(*bPtr, BoundsComponent.init);
	readln();
}

///Gets a simple name for any component. Ex: IPositionComponent => position
public template CompSimpleName(Type)
{
	enum fullName = Type.stringof;
	enum CompSimpleName = unCapitalize!(fullName
													[0..$-"Component".length] //Remove "Component" from the end
													);
}

unittest
{
	struct TestComponent { }
	assertEquals(CompSimpleName!TestComponent, "test");
}