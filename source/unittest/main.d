module main;

import core.stdc.stdio;
import core.stdc.stdlib;

import std.stdio;

import rcr.reloadablemodule : ReloadableModule;
import rcr.reloadablemodule_msvc;
import rcr.functions;
import rcr.globals;

import test;

int main()
{
    // $matodo only debug dll is being loaded right now
    // $matodo this needs to be atomic
	ReloadableModule_MSVC testModule = new ReloadableModule_MSVC("C:\\Program Files (x86)\\Microsoft Visual Studio 14.0\\VC\\vcvarsall.bat", 
																 "..\\..\\..\\..\\..\\RuntimeCodeReload.sln", 
																 "..\\..\\..\\..\\..\\_bin\\UnitTest_ReloadableModule\\x64\\Debug\\",  
																 "UnitTest_ReloadableModule_d.dll",  
																 "UnitTest_ReloadableModule", 
                                                                 "Debug");
    testModule.requestReload(ReloadableModule.ReloadFlag.eCompileAndReload);
    testModule.processReload();
    g_reloadableModules["UnitTest_ReloadableModule"] = testModule;

    writeln(testFunction(1,2));

    testModule.requestReload(ReloadableModule.ReloadFlag.eCompileAndReload);
    testModule.processReload();

    writeln(testFunction(1,2));
    //writeln(TEST2(1,2));

    return 0;
}