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
	@property mat3 matrix();
	@property void matrix(mat3 newMat);
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

	private tc[] tComps;
	private bc[] bComps;
	private BTC[] comps;

	override void registerComponent(IComponent comp)
	{
		if(is(comp : tc) && is(comp : bc))
		{
			tComps ~= cast(tc) comp;
			bComps ~= cast(bc) comp;
		}
		else
			writeln("fail");
		writeln(comp, tComps,bComps);
		writeln(is(comp:tc));
	}



	override void process()
	{	
		//Buffers
		float2[MAX_VERTICES] aWorldSpace;
		float2[MAX_VERTICES] aNormals;
		float2[MAX_VERTICES] bWorldSpace;
		float2[MAX_VERTICES] bNormals;
		auto slice = comps;
		foreach(i;0..comps.length)
		{
			auto a = slice[i];
			uint aLength = a.vertices.length;
			//load bufferdata
			loadWorldSpace(aLength, a, aWorldSpace[0..aLength]);
			loadNormals(aLength, aNormals[0..aLength], aWorldSpace[0..aLength]);
			
			slice=slice[1..$];
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
						writeln(a," ",b," JUST COLLIDED");
					}
				}
			}
		}
	}

	private static loadWorldSpace(uint aLength, BTC a, float2[] worldSpaceBuffer)
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
		auto aTransform = mat3(1,0,2,
									  0,1,2,
									  0,0,1);
		float2[] aVerts = [float2(1f,1f),float2(0f,1f),
							 	 float2(0f,0f),float2(0f,1f)];

		auto bTransform = mat3(1,0,9,
									  0,1,9,
									  0,0,1);
		float2[] bVerts = [float2(1f,1f),float2(0f,1f),
									float2(0f,0f),float2(0f,1f)];
		auto a = new class BTC {
			@property float2 position(){return float2.init;}
			@property void position(float2){}
			@property float2 scale(){return float2.init;}
			@property void scale(float2 newScale){}
			@property float rotation(){return float.init;}
			@property void rotation(float newRot){}
			@property mat3 matrix(){return aTransform;}
			@property void matrix(mat3 newMat){}

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
			@property mat3 matrix(){return bTransform;}
			@property void matrix(mat3 newMat){}

			@property float2[] vertices(){return bVerts;}
			@property void vertices(float2[] newVerts){}
		};

		aTransform = mat3(1,0,-4,
								0,1,-2,
								0,0,1);
		aVerts = [float2(1f,1f),float2(0f,1f),
		float2(0f,0f),float2(0f,1f)];

		bTransform = mat3(1,0,-3,
									  0,1,-3,
									  0,0,1);
		bVerts = [float2(1f,1f),float2(0f,1f),
		float2(0f,0f),float2(0f,1f)];
		auto v = new class BTC {
			@property float2 position(){return float2.init;}
			@property void position(float2){}
			@property float2 scale(){return float2.init;}
			@property void scale(float2 newScale){}
			@property float rotation(){return float.init;}
			@property void rotation(float newRot){}
			@property mat3 matrix(){return aTransform;}
			@property void matrix(mat3 newMat){}

			@property float2[] vertices(){return aVerts;}
			@property void vertices(float2[] newVerts){}
		};

		auto u = new ASDF;
		auto pS = new CollisionSystem;
		pS.registerComponent(u);
		pS.registerComponent(v);
		pS.registerComponent(a);
		pS.registerComponent(b);
		pS.process();
		writeln("done");	
	}

	interface vBTC : bc, tc {}


}

class ASDF : tc, bc
{
	@property float2 position(){return float2.init;}
	@property void position(float2){}
	@property float2 scale(){return float2.init;}
	@property void scale(float2 newScale){}
	@property float rotation(){return float.init;}
	@property void rotation(float newRot){}
	@property mat3 matrix(){return mat3.identity;}
	@property void matrix(mat3 newMat){}

	@property float2[] vertices(){return [float2.init];}
	@property void vertices(float2[] newVerts){}
}