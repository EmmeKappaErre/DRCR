module rcr.reloadablemodule_msvc;

import rcr.reloadablemodule;

private import core.sys.windows.winbase;
private import core.time;
private import std.process;
private import std.stdio;
private import std.file;
private import std.conv;
private import std.path;
private import std.string;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class ReloadableModule_MSVC : ReloadableModule
{
public:
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	this(string	vcvarsallPath,
		 string	solutionFullPath,
		 string	dllSourceDirectory,
		 string	dllName,
		 string	projectName,
         string configuration)
	{
        m_moduleHandle = null;

		m_vcvarsallPath = vcvarsallPath;
		m_solutionFullPath = absolutePath(solutionFullPath);
		m_dllSourceDirectory = dllSourceDirectory;
		m_dllName = dllName;
		m_projectName = projectName;
        m_configuration = configuration;

        // Construct a temporary path - we can use this folder to put our DLL there every time we need to reload it
        auto tempFolderName = to!string(TickDuration.currSystemTick().length);
		m_dllTemporaryDir = buildPath(tempDir(), "RCR", tempFolderName);
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override void processReload()
	{
        if(m_needsReloadProcessing)
        {
            // Release the DLL
            if(m_moduleHandle)
            {
                FreeLibrary(m_moduleHandle);
                m_moduleHandle = null;
            }

            // Make a copy of the dll so that we can override the staging one
            string inUseFolder = to!string(TickDuration.currSystemTick().length);
            string dllDest = buildNormalizedPath(absolutePath(buildPath(m_dllTemporaryDir, inUseFolder, m_dllName)));
            string dllSourceDir = buildNormalizedPath(absolutePath(m_dllTemporaryDir));
            string dllDestDir = buildNormalizedPath(absolutePath(buildPath(m_dllTemporaryDir, inUseFolder)));

            if(!std.file.exists(dllDestDir))
            {
                std.file.mkdir(dllDestDir);
            }

            foreach (string sourceFile; dirEntries(dllSourceDir, SpanMode.shallow))
            {
                if(std.file.isFile(sourceFile))
                {
                    std.file.copy(buildPath(dllSourceDir, baseName(sourceFile)), buildPath(dllDestDir, baseName(sourceFile)));
                }
            }

            // Even if we filed we try to load it, we may just have failed to compile due to code issues but the old dll is actually there
            m_moduleHandle = LoadLibraryA(dllDest.toStringz);

            if (m_moduleHandle == null)
            {
                m_log.error("Failed to load the required DLL; check that the DLL's path is correct and retry.");
                return;
            }

			if (m_onDLLLoadCallback)
			{
				m_onDLLLoadCallback(m_moduleHandle);
			}

			m_needsReloadProcessing = false;
			m_reloading = false;
        }
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override Handle handle()
    {
        return m_moduleHandle;
    }

protected:
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	override bool __compileDLL(ReloadFlag flag)
	{
		if(!exists(m_vcvarsallPath))
		{
            m_log.error("Failed to find Visual Studio MSBuild bat file. Please check the path.");
			return false;
		}

		if(!exists(m_solutionFullPath))
		{
			m_log.error("Failed to find the specified solution. Please check the path.");
			return false;
		}

        bool cleanCompile = flag == ReloadFlag.eCleanCompileAndReload || flag == ReloadFlag.eCleanCompileAndNoReload;

        string platform = "";
		File batchFile = File("_compile.bat", "w"); 
        version(Win32)
        {
            platform = "x86";
            batchFile.writeln("call \""~ m_vcvarsallPath ~ "\" x86");
        }
        else version(Win64)
        {
            platform = "x64";
            batchFile.writeln("call \""~ m_vcvarsallPath ~ "\" x64");
        }
        else
        {
			m_log.error("Unknown platform version.");
            return false;
        }

        batchFile.writeln("MSBuild \""~ m_solutionFullPath ~ "\"" ~
                            " /t:" ~ m_projectName ~ (cleanCompile ? ":Rebuild" : "") ~ 
                            " /p:Configuration=" ~ m_configuration ~
                            " /p:Platform=" ~ platform ~
                            " /p:OutDir=\""~ m_dllTemporaryDir ~ "\\\\\" >> _compilation_output.txt");
        batchFile.close(); 

        auto shell = executeShell("_compile.bat");
        if (shell.status < 0) 
        {
			m_log.error("Failed to run _compile.bat.");
            return false;
        }

        // Read the output and put it to the log
        m_log.log(std.file.readText("_compilation_output.txt"));

        // Remove the temp files
        std.file.remove("_compilation_output.txt");
        std.file.remove("_compile.bat");

        return true;
	}

private:
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string	m_vcvarsallPath;
	string	m_solutionFullPath;
	string	m_dllSourceDirectory;
	string	m_dllName;
	string	m_dllTemporaryDir;
	string	m_projectName;
	string	m_configuration;

    Handle  m_moduleHandle;
}