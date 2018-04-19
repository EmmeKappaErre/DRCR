module test;

import std.stdio;
import rcr.functions;

//pragma(msg, Function!("UnitTest_ReloadableModule", int, "testFunction", double, float));
mixin(ReloadableFunction!("UnitTest_ReloadableModule", int, "testFunction", double, float));
