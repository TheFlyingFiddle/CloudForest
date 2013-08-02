module entity.physicssystem;

import math.vector;
import math.matrix;
import entity.system;
import std.stdio;

alias IVelocityComponent vc;
alias ITransformationComponent tc;
alias IBoundsComponent bc;

interface IVelocityComponent:IComponent
{
	@property float2 velocity();
	@property void velocity(float2 newVel);
}

interface ITransformationComponent:IComponent
{
	@property float2 position();
	@property void position(float2);
	@property float2 scale();
	@property void scale(float2 newScale);
	@property float rotation();
	@property void rotation(float newRot);
	@property mat2 matrix();
	@property void matrix(mat2 newMat);
}

class PositionUpdateSystem : ISystem
{
	interface VTC : tc,vc 
	{}

	private VTC[] comps;
	override void registerComponent(IComponent comp) 
	{
		if(is(comp:IVelocityComponent) && is(comp:ITransformationComponent))
			comps~=cast(VTC)comp;
	}

	override void process()
	{
		foreach(comp;comps)
		{
			comp.position += comp.velocity;
		}
	}
}

enum MAX_VERTICES = 16;

/// Vertices are right-facing (counter-clockwise)
interface IBoundsComponent
{
	@property float2[] vertices();
	@property void vertices(float2[] newVerts);
}

class CollisionSystem : ISystem
{
	interface BTC : tc, bc
	{}

	private BTC[] comps;
	override void registerComponent(IComponent comp)
	{
		if(is(comp:ITransformationComponent) && is(comp:IBoundsComponent))
			comps ~= cast(BTC)comp;
	}

	override void process()
	{	}

	private bool collides(BTC a, BTC b)
	{
		return SET(a,b);
	}
	
	//Calculating normals again and again==waste?looool
	///Detect collisions using the separating axis theorem
	static private bool SET(BTC a, BTC b)
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
			float aMin = -float.max;
			float aMax =  float.max;
			foreach(i;0..aLength)
			{
				float proj = aWorldSpace[i].dot(normal);
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

			if(aMin>bMax||bMin>aMax)
				return false;
		}

		//Could not prove there was no collision, so there was.
		return true;
	}

	interface IBoundsComponent
	{
		@property float2[] vertices();
		@property void vertices(float2[] newVerts);
	}

	interface ITransformationComponent:IComponent
	{
		@property float2 position();
		@property void position(float2);
		@property float2 scale();
		@property void scale(float2 newScale);
		@property float rotation();
		@property void rotation(float newRot);
		@property mat2 matrix();
		@property void matrix(mat2 newMat);
	}

	unittest
	{
		mat2 aTransform = mat2.scale(2);
		float2[] aVerts = [float2(1f,1f),float2(0f,1f),
							 	 float2(0f,0f),float2(0f,1f)];

		mat2 bTransform = mat2.scale(3);
		float2[] bVerts = [float2(99f,100f),float2(100f,90f),
								 float2(90f,100f),float2(100f,99f)];
		auto a = new class BTC {
			@property float2 position(){return float2.init;}
			@property void position(float2){}
			@property float2 scale(){return float2.init;}
			@property void scale(float2 newScale){}
			@property float rotation(){return float.init;}
			@property void rotation(float newRot){}
			@property mat2 matrix(){return aTransform;}
			@property void matrix(mat2 newMat){}

			@property float2[] vertices(){return aVerts;}
			@property void vertices(float2[] newVerts){}
		};

		auto b = new class BTC {
			@property float2 position(){return float2.init;}
			@property void position(float2){}
			@property float2 scale(){return float2.init;}
			@property void scale(float2 newScale){}
			@property float rotation(){return float.init;}
			@property void rotation(float newRot){}
			@property mat2 matrix(){return bTransform;}
			@property void matrix(mat2 newMat){}

			@property float2[] vertices(){return bVerts;}
			@property void vertices(float2[] newVerts){}
		};
		writeln(aVerts);
		writeln(bVerts);
		writeln(a.vertices);
		writeln(b.vertices);
		assert(SET(a,b));
	}
}