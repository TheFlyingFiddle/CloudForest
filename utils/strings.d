module utils.strings;

import std.string;

template unCapitalize(string str)
{
	enum unCapitalize = str[0..1].toLower~str[1..$];
}