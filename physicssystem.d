module entity.physicssystem;

import math.vector;
import math.matrix;
import entity.system;
import entity.entity;
import entity.database;
import utils.assertions;
import std.stdio;

alias VelocityComponent vc;
alias TransformationComponent tc;
alias BoundsComponent bc;

struct VelocityComponent
{
	private float2 _velocity;
	
	@property float2 velocity()
	{
		return _velocity;
	}

	@property void velocity(float2 newVel)
	{
		_velocity = newVel;	
	}
}

struct TransformationComponent
{
	private float2 _position;
	private float2 _scale;
	private float _rotation;
	private mat3 _matrix;
	
	@property float2 position() { return _position; }

	@property void position(float2 newPos)
	{
		_matrix[0,2] = newPos.x;
		_matrix[1,2] = newPos.y;
		_position		= newPos;
	}

	@property float2 scale()
	{
		return _scale;
	}
	
	@property void scale(float2 newScale)
	{
		_scale = newScale;
		updateMatrix();
	}
	
	@property float rotation()
	{
		return _rotation;
	}
	
	@property void rotation(float newRot)
	{
		_rotation = newRot;
		updateMatrix();
	}
	
	@property mat3 matrix()
	{
		return _matrix;
	}

	private void updateMatrix()
	{
		this._matrix =	mat3.CreateMatrix(_position, _scale, _rotation);
	}
}

class PositionUpdateSystem : ISystem
{
	private struct EntityProxy
	{
		TransformationComponent* transComp;
		VelocityComponent* velComp;
	}
	private EntityProxy[] entities;
	private IDataBase db;

	this(IDataBase db)
	{
		this.db = db;
	}
	override void register(Entity entity)
	{
		if(entity.hasComponent!TransformationComponent,
			entity.hasComponent!VelocityComponent)
		{
			entities ~= EntityProxy(db.GetComponentPointer!TransformationComponent,
											db.GetComponentPointer!VelocityComponent);
		}
	}

	override void process()
	{
		foreach(entity;entities)
		{
			entity.position += entity.velocity;
		}
	}
}

mixin template System(ComponentTypes...)
{
	private struct EntityProxy
	{
		mixin(buildComponentPointers(ComponentTypes));
	}
	private EntityProxy[] entities;
	private IDataBase db;

	this(IDataBase db)
	{
		this.db = db;
	}

	override void register(Entity entity)
	{
		mixin(buildRegister(ComponentTypes));
	}

	override void process()
	{
		foreach(entity;entities)
		{
			entity.position += entity.velocity;
		}
	}
}

private static string buildComponentPointers(ComponentTypes...)(ComonentTypes args)
{
	string s;
	foreach(type;ComponentTypes)
	{
		s ~= text(fullyQualifiedName!type,"* ",CompSimpleName!type,";\n");
	}
	return s;
}

private static string buildRegister(ComponentTypes...)(ComonentTypes args)
{
	string s = "if(";
	foreach(type;ComponentTypes)
	{
		s ~= text("entity.hasComponent!",fullyQualifiedName!type,"&&");
	}
	s = s[0..$-"&&".length];
	s ~= "{
				entities ~= EntityProxy(";
	foreach(type;ComponentTypes)
	{
		s ~= "db.GetComponentPointer!"~fullyQualifiedName!type~",";
	}
	s = s[0..$-",".length];
	s ~= ");}";
	if(entity.hasComponent!TransformationComponent,
		entity.hasComponent!VelocityComponent)
	{
		entities ~= EntityProxy(db.GetComponentPointer!TransformationComponent,
										db.GetComponentPointer!VelocityComponent);
	}
}

enum MAX_VERTICES = 16;

/// Vertices are right-facing (counter-clockwise) TODO: How store circles usw?
struct BoundsComponent
{
	private float2[] _vertices;

	@property float2[] vertices()
	{
		return _vertices;
	}
	
	@property void vertices(float2[] newVerts)
	{
		_vertices = newVerts;
	}
}

class CollisionSystem : ISystem
{
	Entity[] entities;
	override void register(Entity entity)
	{
		//Does it have our required components?
		if(entity.hasComponent!BoundsComponent &&
			entity.hasComponent!TransformationComponent)
		{
			entities ~= entity;
		}
	}

	///TODO: Redo. Completely.
	override void process()
	{	
		//Buffers
		float2[MAX_VERTICES] aWorldSpace;
		float2[MAX_VERTICES] aNormals;
		float2[MAX_VERTICES] bWorldSpace;
		float2[MAX_VERTICES] bNormals;
		auto slice = entities;
		foreach(i;0..entities.length)
		{
			auto a = slice[i];
			uint aLength = a.vertices.length;
			//load bufferdata
			loadWorldSpace(aLength, a, aWorldSpace[0..aLength]);
			loadNormals(aLength, aNormals[0..aLength], aWorldSpace[0..aLength]);
			
			slice = slice[1..$];
			foreach(b;slice)
			{
				uint bLength = b.vertices.length;
				//load bufferdata
				loadWorldSpace(bLength, b, bWorldSpace[0..bLength]);
				if(checkCollision(aNormals, aWorldSpace, bWorldSpace, aLength, bLength)) // No need to load b's normals if there was no collision
				{
					loadNormals(bLength, bNormals[0..bLength], bWorldSpace[0..bLength]);
					if(checkCollision(bNormals, aWorldSpace, bWorldSpace, aLength, bLength))
					{
						//Resolve the collision
						writeln(a," ",b," JUST COLLIDED");
					}
				}
			}
		}
	}

	private static loadWorldSpace(uint aLength, Entity a, float2[] worldSpaceBuffer)
	{
		foreach(i;0..aLength)
		{
			worldSpaceBuffer[i] = a.matrix * a.vertices[i];
		}
	}

	private static loadNormals(uint aLength, float2[] normalBuffer, 
										float2[] worldSpaceBuffer)
	{
		foreach(i;0..aLength)
		{
			auto line = worldSpaceBuffer[i] - ((i == 0)?worldSpaceBuffer[aLength-1]:worldSpaceBuffer[i-1]);
			normalBuffer[i] = float2(line.y,-line.x);
		}
	}

	private bool checkCollision(float2[] normalBuffer, 
										 float2[] aWorldSpaceBuffer,
										 float2[] bWorldSpaceBuffer,
										 uint aLength, uint bLength)
	{
		foreach(normal;normalBuffer[0..aLength])
		{
			float aMin, aMax, bMin, bMax;
			minMaxProjections(aMin, aMax, aWorldSpaceBuffer, aLength, normal);
			minMaxProjections(bMin, bMax, bWorldSpaceBuffer, bLength, normal);
			writeln(aMin);
			writeln(aMax);
			writeln(bMin);
			writeln(bMax);
			if(aMin>bMax||bMin>aMax)
				return false;
		}
		return true;
	}

	private void minMaxProjections(out float min, out float max,
				float2[] worldSpaceBuffer,
				uint bufferLength,
				float2 normal)
	{
		min =  float.max;
		max = -float.max;
		foreach(i;0..bufferLength)
		{
			float proj = worldSpaceBuffer[i].dot(normal);
			if(proj<min)
				min = proj;
			if(proj>max)
				max = proj;
		}
	}

	
	//Calculating normals again and again==waste?looool
	///Detect collisions using the separating axis theorem
	static private bool SET(Entity a, Entity b)
	{
		static float2[MAX_VERTICES] aWorldSpace;
		static float2[MAX_VERTICES] bWorldSpace;
		static float2[MAX_VERTICES] aNormals;
		static float2[MAX_VERTICES] bNormals;
		int aLength = a.vertices.length;
		int bLength = b.vertices.length;

		//Transform the vertices from local into world space
		//Use transformation		
		foreach(i,ref vert;a.vertices)
		{
			aWorldSpace[i] = a.matrix * vert;
		}
		foreach(i,ref vert;b.vertices)
		{
			bWorldSpace = b.matrix * vert;
		}

		//Calculate normals
		foreach(i;0..aLength)
		{
			auto line = aWorldSpace[i] - ((i == 0)?aWorldSpace[aLength-1]:aWorldSpace[i-1]);
			aNormals[i] = float2(line.y,-line.x);
		}
		foreach(i;0..bLength)
		{
			auto line = bWorldSpace[i] - ((i == 0)?bWorldSpace[bLength-1]:bWorldSpace[i-1]);
			bNormals[i] = float2(line.y,-line.x);
		}

		//For every projection, generate min/max and try
		foreach(normal;aNormals[0..aLength])
		{
			float aMin =  float.max;
			float aMax =  -float.max;
			foreach(i;0..aLength)
			{
				float proj = aWorldSpace[i].dot(normal);
				if(proj<aMin)
					aMin = proj;
				if(proj>aMax)
					aMax = proj;
			}
			float bMin =  float.max;
			float bMax = -float.max;
			foreach(i;0..aLength)
			{
				float proj = bWorldSpace[i].dot(normal);
				if(proj<bMin)
					bMin = proj;
				if(proj>bMax)
					bMax = proj;
			}

			writeln(aMin);
			writeln(aMax);
			writeln(bMin);
			writeln(bMax);
			if(aMin>bMax||bMin>aMax)
				return false;
		}
		foreach(normal;bNormals[0..bLength])
		{
			float aMin = -float.max;
			float aMax =  float.max;
			foreach(i;0..aLength)
			{
				float proj = aWorldSpace[i].dot(normal);
				writeln(proj);
				if(proj<aMin)
					aMin = proj;
				if(proj>aMax)
					aMax = proj;
			}
			float bMin = -float.max;
			float bMax =  float.max;
			foreach(i;0..aLength)
			{
				float proj = bWorldSpace[i].dot(normal);
				if(proj<bMin)
					bMin = proj;
				if(proj>bMax)
					bMax = proj;
			}
			writeln(aMin);
			writeln(aMax);
			writeln(bMin);
			writeln(bMax);
			if(aMin>bMax||bMin>aMax)
				return false;
		}

		//Could not prove there was no collision, so there was.
		return true;
	}

	unittest
	{
		float2[] aVerts = [float2(1f,1f),float2(0f,1f),
							 		float2(0f,0f),float2(0f,1f)];
		
		float2[] bVerts = [float2(1f,1f),float2(0f,1f),
									float2(0f,0f),float2(0f,1f)];

		float2[] cVerts = [float2(1f,1f),float2(0f,1f),
									float2(0f,0f),float2(0f,1f)];

		float2[] dVerts = [float2(1f,1f),float2(0f,1f),
									float2(0f,0f),float2(0f,1f)];


		auto db = new DataBase!(BoundsComponent, TransformationComponent)();
		auto a = new Entity!(TransformationComponent, BoundsComponent)(db);
		auto b = new Entity!(TransformationComponent, BoundsComponent)(db);
		auto c = new Entity!(TransformationComponent, BoundsComponent)(db);
		auto d = new Entity!(TransformationComponent, BoundsComponent)(db);

		a.vertices = aVerts;
		b.vertices = bVerts;
		c.vertices = cVerts;
		d.vertices = dVerts;

		a.position = float2(1,10);
		b.position = float2(1.5,10);

		auto cS = new CollisionSystem;
		cS.register(a);
		cS.register(b);
		cS.register(c);
		cS.register(d);
		cS.process();
		writeln("done");	
		
		auto e = new Entity!(TransformationComponent, BoundsComponent)(db);
		e.position = float2(2,3);
		assertEquals(e.position, float2(2,3));
		writeln("SUCCESS");
		readln();
	}
}