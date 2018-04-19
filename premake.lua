-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function AbsolutePath (path)
  return "\"" .. os.getcwd() .. "/" .. path .. "\""
end
function BinaryRelPath (project, platform, configuration)
  return "_bin/" .. project .. "/" .. platform .. "/" .. configuration .. "/"
end
function ObjsRelPath (project, platform, configuration)
  return "_bin/objs/" .. project .. "/" .. platform .. "/" .. configuration .. "/"
end

-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

workspace "RuntimeCodeReload"
      configurations { "Debug", "Release" }
      platforms { "x64" }
      startproject "UnitTest"

-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--
-- Runtime Code Reload
--
-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
project "RCR"
   ProjectName = "RCR"
   kind "StaticLib"
   language "C++"
   location "_projects/RCR"

   includedirs { 
      AbsolutePath("source/")
   }
   
   files { "source/RCR/**.d" }

   symbols "On"

   filter { "files:**.d" }
      buildaction "Compile"

   filter { "configurations:Debug", "platforms:x64" }
      targetdir (BinaryRelPath(ProjectName, "x64", "Debug"))
      objdir (ObjsRelPath(ProjectName, "x64", "Debug"))
      debugdir (ObjsRelPath(ProjectName, "x64", "Debug"))

   filter { "configurations:Release", "platforms:x64" }
      optimize "On"
      targetdir (BinaryRelPath(ProjectName, "x64", "Release"))
      objdir (ObjsRelPath(ProjectName, "x64", "Debug"))
      debugdir (ObjsRelPath(ProjectName, "x64", "Debug"))

-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--
-- Unit Test Reloadable Module
--
-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
project "UnitTest_ReloadableModule"
   ProjectName = "UnitTest_ReloadableModule"
   kind "SharedLib"
   language "C++"
   location "_projects/UnitTest_ReloadableModule"
   dependson "RCR"

   includedirs { 
      AbsolutePath("source/")
   }

   links {
      "RCR.lib"
   }

   files { 
      "source/UnitTest_ReloadableModule/**.d",
      "source/UnitTest_ReloadableModule/**.di" 
   }

   symbols "On"
   
   filter { "configurations:Debug", "platforms:x64" }
      targetname (ProjectName .. "_d")
      targetdir (BinaryRelPath(ProjectName, "x64", "Debug"))
      objdir (ObjsRelPath(ProjectName, "x64", "Debug"))
      debugdir (ObjsRelPath(ProjectName, "x64", "Debug"))
      libdirs { 
         AbsolutePath(BinaryRelPath("RCR", "x64", "Debug"))
      }

   filter { "configurations:Release", "platforms:x64" }
      optimize "On"
      targetname (ProjectName .. "_r")
      targetdir (BinaryRelPath(ProjectName, "x64", "Release"))
      objdir (ObjsRelPath(ProjectName, "x64", "Release"))
      debugdir (ObjsRelPath(ProjectName, "x64", "Release"))
      libdirs { 
         AbsolutePath(BinaryRelPath("RCR", "x64", "Release"))
      }

-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--
-- Unit Test (Main)
--
-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
project "UnitTest"
   ProjectName = "UnitTest"
   kind "ConsoleApp"
   language "C++"
   location "_projects/UnitTest"
   entrypoint ""
   dependson {"RCR","UnitTest_ReloadableModule"}

   includedirs { 
      AbsolutePath("source/"),
      AbsolutePath("source/unittest/"),
      AbsolutePath("source/unittest_reloadablemodule/public/")
   }

   files { 
      "source/unittest/**.d",
      "source/unittest_reloadablemodule/public/**.di" 
   }

   symbols "On"
   
   filter { "configurations:Debug", "platforms:x64" }
      targetdir (BinaryRelPath(ProjectName, "x64", "Debug"))
      objdir (ObjsRelPath(ProjectName, "x64", "Debug"))
      debugdir (ObjsRelPath(ProjectName, "x64", "Debug"))
      libdirs { 
         AbsolutePath(BinaryRelPath("RCR", "x64", "Debug")),
         AbsolutePath(BinaryRelPath("UnitTest_ReloadableModule", "x64", "Debug")),
         AbsolutePath(ObjsRelPath("UnitTest_ReloadableModule", "x64", "Debug")),
      }
      links {
         "RCR.lib",
         "UnitTest_ReloadableModule_d.lib",
      }
      postbuildcommands { "xcopy " .. AbsolutePath(BinaryRelPath("UnitTest_ReloadableModule", "x64", "Debug") .. "UnitTest_ReloadableModule_d.dll") .. " " ..
                                      AbsolutePath(BinaryRelPath("UnitTest", "x64", "Debug") .. "UnitTest_ReloadableModule_d.dll*") .. " /y /f /k" }

   filter { "configurations:Release", "platforms:x64" }
      optimize "On"
      targetdir (BinaryRelPath(ProjectName, "x64", "Release"))
      objdir (ObjsRelPath(ProjectName, "x64", "Release"))
      debugdir (ObjsRelPath(ProjectName, "x64", "Release"))
      libdirs { 
         AbsolutePath(BinaryRelPath("RCR", "x64", "Release")),
         AbsolutePath(BinaryRelPath("UnitTest_ReloadableModule", "x64", "Release")),
         AbsolutePath(ObjsRelPath("UnitTest_ReloadableModule", "x64", "Release")),
      }
      links {
         "RCR.lib",
         "UnitTest_ReloadableModule_r.lib",
      }
      postbuildcommands { "xcopy " .. AbsolutePath(BinaryRelPath("UnitTest_ReloadableModule", "x64", "Release") .. "UnitTest_ReloadableModule_r.dll") .. " " ..
                                      AbsolutePath(BinaryRelPath("UnitTest", "x64", "Release") .. "UnitTest_ReloadableModule_r.dll*") .. " /y /f /k" }