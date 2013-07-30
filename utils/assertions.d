module utils.assertions;
import std.string;

void assertElementEquals(T, R)(T expected, T actual, string file = __FILE__, int line = __LINE__)
{
	//This is harder
	assert(false);
}

void assertEquals(T)(T expected, T actual, string file = __FILE__, int line = __LINE__)
{
	assert(expected == actual, format("\nExpected: %s\nActual: %s in file %s on line %s", 
												 expected, actual, file, line));
}

void assertRefEquals(T)(T expected, T actual, string file = __FILE__, int line = __LINE__)
{
	assert(expected is actual, format("Expected: %s\n Actual: %s in file %s on line %s", 
												 expected, actual, file, line));
}

void assertNotNull(T)(T obj, string file = __FILE__, int line = __LINE__) if(is(T == class))
{	
	assert(obj, format("Object cannot be null. in file %s on line %s", file, line));
}

void assertThrows(T)(void delegate(void) throwing,  string file = __FILE__, int line = __LINE__) if(is(T : Throwable))
{
	bool flag = false;
	try 
	{
		throwing();
	} catch(T thrown) {
		flag = true;
	} catch(Throwable thrown) {
		assert(false, format("Expected an exception of type %s but got one of type %s in file %s at line s%", 
									T.stringof, typeof(thrown).stringof, file, line)); 
	} 
	
	assert(flag, format("Expected an exception but none was thrown in file %s at line %s", file, line));
}

void assertNotImplemented(lazy const(char)[] feature = null, string file = __FILE__, int line = __LINE__)
{
	if(feature)
		assert(false, format("Feature %s is not yet implemented", feature()));
	else 
		assert(false, "Not yet implemented!");
}