-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function PatchDFiles(projectFile)
   local f = io.open(projectFile, "r")
   local content = f:read("*all")
   f:close()

   -- Find anything that matches <None [stuff].d" and replace with <DCompile [stuff].d"
   content = string.gsub(content, "<(None )(.-(%.d\"))", "<DCompile %2")

   -- Find AdditionalIncludeDirectories and create ImportPaths
   local includeIdx = string.find(content, "<AdditionalIncludeDirectories>")
   while(includeIdx ~= nil) do
      -- Find <AdditionalIncludeDirectories>...</AdditionalIncludeDirectories>
      local includeIdxStart = includeIdx + string.len("<AdditionalIncludeDirectories>")
      local includeIdxEnd = string.find(content, "</AdditionalIncludeDirectories>", includeIdx) - 1

      -- Get the internals and save it in includes
      local includes = string.sub(content,includeIdxStart,includeIdxEnd)
      includes = string.gsub(includes, ";%%%(AdditionalIncludeDirectories%)", "")

      -- Find </ClCompile>
      local ClCompileStart = string.find(content, "</ClCompile>", includeIdxEnd) + string.len("</ClCompile>")

      -- Inject the <DCompile>
      local part1 = string.sub(content,0,ClCompileStart)
      local part2 = string.sub(content,ClCompileStart)
      local injection = "<DCompile><ImportPaths>" .. includes .. "</ImportPaths></DCompile>"
      content = part1 .. injection .. part2

      includeIdx = string.find(content, "<AdditionalIncludeDirectories>", ClCompileStart)
   end

   local f = io.open(projectFile, "w")
   f:write(content)
   f:close()
end

PatchDFiles("_projects/UnitTest/UnitTest.vcxproj")
PatchDFiles("_projects/RCR/RCR.vcxproj")
PatchDFiles("_projects/UnitTest_ReloadableModule/UnitTest_ReloadableModule.vcxproj")