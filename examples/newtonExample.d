module examples.newtonExample;

import example;
import graphics.all;
import math.vector;

class NewtonExample : Example
{
	private Context gl;
	private Shader vs, fs;
	private Program program;
	private VertexArray vertexArray;
	private VertexBuffer vertexBuffer;

	this() 
	{
		auto vs = Shader.create(ShaderType.vertex,vertSource);
		auto fs = Shader.create(ShaderType.fragment,fragSource);	
		program = Program.create(vs, fs);
		vertexArray = VertexArray.create();
		vertexBuffer = VertexBuffer.create(BufferHint.staticDraw);

		gl.program = program;
		gl.vertexArray = vertexArray;
		gl.vertexBuffer = vertexBuffer;

		float triangle[8] = [-1,-1, 
									 -1, 1,
									  1,-1, 
									  1, 1];

		vertexBuffer.bufferData(triangle);
		vertexArray.bindAttribute!float2(program.attribute["position"], 0, 0);

		auto color1 = program.uniform["color1"],
			  color2 = program.uniform["color2"];

		color1.set(float3(0.2f, 0.02f, 0.05f));
		color2.set(float3(1.0f, 0.95f, 0.98f));

	}

	override void reshape(int w, int h) { }
	int time = 0;
	override void render(double time2) 
	{
		gl.program = program;
		gl.vertexArray = vertexArray;

		program.validate();

		gl.clearColor(Color(0, 0, 0, 0));
		gl.clear(ClearFlags.color);
		gl.drawArrays(PrimitiveType.triangleStrip, 0, 4);
	}
}

enum vertSource = 
"#version 330
in vec2 position;
out vec2 vertCoord;
void main(void)
{
	vertCoord = position;
	gl_Position = vec4(position, 0, 1.0);
}";

enum fragSource =
"#version 330
in vec2 vertCoord;
uniform vec3 color1, color2;
out vec4 fragColor;

vec2 f(in vec2 n)  {
	return vec2( n.x * n.x * n.x - 3.0 *n.x*n.y*n.y - 1,
					-n.y*n.y*n.y + 3.0*n.x*n.x*n.y);
}

vec2 df(in vec2 n) {
	return 3.0 * vec2(n.x * n.x - n.y * n.y,
	2.0 * n.x * n.y);
}

vec2 cdiv(vec2 a, vec2 b) {
	float d = dot(b, b);
	if(d == 0.0) return a;
	else return vec2((a.x * b.x + a.y * b.y) / d,
						  (a.y * b.x - a.x*b.y) / d);
}

void main()
{
	vec2 z =  vertCoord;
	int i, max = 128;
	for(i = 0; i != max; i++) {
		vec2 zn = z - cdiv(f(z), df(z));
		if(distance(zn,z) < 0.00001) break;
		z = zn;
	}

	fragColor = vec4(mix( color1, color2, float(i) / float(max)), 1.0f);
}";