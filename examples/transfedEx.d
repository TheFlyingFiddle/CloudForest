module examples.transfedEx;

import graphics.all;
import math.vector;
import example;
import std.stdio;
import utils.image;
import derelict.opengl3.gl3;

public class ParticleSystem : Example
{
	enum maxParticles = 500_000;

	Context gl;
	VBO[2] vbos;
	VAO vao;
	Query query;
	Texture texture;
	Program renderp, feedback;

	struct Particle
	{
		float2 pos, velocity;
		float4 color;
	}

	this() 
	{

		glEnable(GL_PROGRAM_POINT_SIZE);

		auto particles = new Particle[maxParticles];
		auto rand = std.random.uniform(0, 1000);
		auto rand2 = std.random.uniform(50, 1000);
		auto s = std.math.sin(rand) / 1000f;
		auto c = std.math.cos(rand2) / 1000f;
		auto rand3 = std.random.uniform(50, 1000);
		particles[rand3] = Particle(float2(-s * rand2,-c * rand2), float2(s,c), float4(0.1f, 1, 1, 1));

		query = new Query();
		vbos[0] = new VBO(BufferHint.streamDraw);
		vbos[1] = new VBO(BufferHint.streamDraw);
		
		gl.vertexBuffer = vbos[0];
		vbos[0].bufferData(particles);
		
		gl.vertexBuffer = vbos[1];
		vbos[1].initialize(vbos[0].size);
		
		vao = new VAO();
		
		auto vs = new Shader(ShaderType.vertex, vertSource);
		auto fs = new Shader(ShaderType.fragment, fragSource);

		feedback = new Program();
		feedback.feedbackVaryings(FeedbackMode.interleavedAttribs,
										  ["position0", "velocity0", "color0"]);
		feedback.link(vs);

		renderp = new Program(vs, fs);
	}

	override void reshape(int w, int h) { }
	override void render(double time) 
	{
		updateParticles(time);
		renderParticles();
	}

	void updateParticles(float time) 
	{
		gl.vertexArray = this.vao;
		gl.program = feedback;

		gl.vertexBuffer = vbos[0];
		vao.bindAttribute!float2(feedback.attribute["position"], Particle.sizeof, 0);
		vao.bindAttribute!float2(feedback.attribute["velocity"], Particle.sizeof, float2.sizeof);
		vao.bindAttribute!float4(feedback.attribute["color"], Particle.sizeof, float4.sizeof);
	
		gl.transformFeedback[0] = vbos[1];

		query.startQuery(QueryTarget.transformFeedbackPrimitivesWritten,
		{
			gl.transformFeedback(PrimitiveType.points,
			{
				gl.drawArrays(PrimitiveType.points, 0, maxParticles);
			});
		});

		std.algorithm.swap(vbos[0], vbos[1]);
	}

	void renderParticles() 
	{
		gl.clear(ClearFlags.color);

		gl.program = renderp;
		gl.vertexArray = vao;
		gl.vertexBuffer = vbos[0];

		vao.bindAttribute!float2(renderp.attribute["position"], Particle.sizeof, 0);
		vao.bindAttribute!float2(renderp.attribute["velocity"], Particle.sizeof, float2.sizeof);
		vao.bindAttribute!float4(feedback.attribute["color"], Particle.sizeof, float4.sizeof);

		gl.drawArrays(PrimitiveType.points, 0, query.result);
	}
}


string vertSource = 
"#version 330
in vec2 position;
in vec2 velocity;
in vec4 color;

out vec2 position0;
out vec2 velocity0;
out vec4 color0;

void main() 
{
	position0 = position + velocity;
	velocity0 = velocity;
	color0 = color;

	if(position0.x < -1 || position0.x > 1) {
		position0.x = -position0.x;
	}	

	if(position0.y < -1 || position0.y > 1) {
		position0.y = -position0.y;
	}	

	gl_PointSize = 1.7f;
	gl_Position = vec4(position, 0, 1);
}";


string fragSource = 
"#version 330 
in vec2 velocity0;
in vec2 position0;
in vec4 color0;

void main()
{
	gl_FragColor = color0; 
}
";
