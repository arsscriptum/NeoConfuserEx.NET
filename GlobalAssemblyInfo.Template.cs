using System.Reflection;

[assembly: AssemblyProduct("Notepad")]
[assembly: AssemblyCompany("Microsoft")]
[assembly: AssemblyCopyright("Copyright (C) Microsoft 2000")]

#if DEBUG

[assembly: AssemblyConfiguration("Debug")]
#else

[assembly: AssemblyConfiguration("Release")]
#endif

[assembly: AssemblyVersion("{{VER}}")]
[assembly: AssemblyFileVersion("{{VER}}")]
[assembly: AssemblyInformationalVersion("{{TAG}}")]