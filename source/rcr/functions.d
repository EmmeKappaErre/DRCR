module rcr.functions;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
template ParametersNames(uint ParamsCount)
{
    import std.conv;
    string[] impl(int i)
    {
        if(i < ParamsCount)
            return ["param" ~ to!string(i)] ~ impl(i + 1);
        else
            return [];
    }
    enum string[] ParametersNames = impl(0);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
string mergeStringArrays(string[] arr1, string[] arr2)
{
    import std.range;
    import std.algorithm;
    assert(arr1.length == arr2.length);
    return zip(arr1, arr2)
              .map!(tuple => tuple[0] ~ " " ~ tuple[1])
              .reduce!((a,b) => a ~ ", " ~ b);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
template ReloadableFunction(string sourceModule, ReturnType, string name, Args...)
{
    import std.meta;
    import std.traits;
    import std.algorithm;

	enum StringOf(T) = T.stringof;
    enum functionParamsTypes = [staticMap!(StringOf, Args)];    // e.g. int, float, double
    enum functionParamsNames = ParametersNames!(Args.length);   // e.g. param0, param1, param2

    enum functionArgsDefinition = mergeStringArrays(functionParamsTypes, functionParamsNames);
    enum functionArgsInvocation = functionParamsNames.
                                  reduce!((a,b) => a ~ ", " ~ b);
    enum functionAliasType    = name ~ "_" ~ ReturnType.stringof ~ "_" ~ functionParamsTypes.reduce!((a,b) => a ~ "_" ~ b);

	string __trampoline()
	{
		string result = "";
		result ~= "alias extern(C) " ~ReturnType.stringof ~ " function(" ~ functionArgsDefinition ~ ") " ~ functionAliasType ~ ";\n";
        result ~= "pragma (inline,true) extern(C) " ~ ReturnType.stringof ~ " " ~ name ~ "(" ~ functionArgsDefinition ~ ")\n";
		result ~= "{\n";
		result ~= "    import rcr.globals;\n";
        result ~= "    import core.sys.windows.winbase;\n";
		result ~= "    void* handle = g_reloadableModules[\"" ~ sourceModule ~ "\"].handle();\n";
		result ~= "    " ~ functionAliasType ~ " fp = cast(" ~ functionAliasType ~ ")GetProcAddress(handle, \"" ~ name ~ "\");\n";
		result ~= "    return fp(" ~ functionArgsInvocation ~ ");\n";
		result ~= "}\n";
		return result;
	}

	version(RCR_ENABLED)
	{
		enum ReloadableFunction = __trampoline();
	}
	else
	{
		enum ReloadableFunction = "extern(C) " ~ ReturnType.stringof ~ " " ~ name ~ "(" ~ functionArgsDefinition ~ ");";
	}
}