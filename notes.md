# Benchmarking using the standard library as a module

For this round of tests I downloaded the latest versions of GCC, Clang and MSVC.
I also compared against the current Ubuntu release of GCC and Clang.

| Compiler |   Version | Module Build | Module Use | Include All |
|----------|-----------|--------------|------------|-------------|
|g++       |16.1.0     |3345ms        |249ms       |1579ms       |
|g++       |15.2.0     |2280ms        |172ms       |877ms        |
|clang     |22.16.6    |2014ms        |52ms        |1545m        |
|clang     |20.1.8     |1491ms        |44ms        |1142ms       |
|MSVC      |19.38.33145|2058ms        |81ms        |1295ms       |

Right now none of the compilers provided submodule support that I saw for the
standard library. That means these are single threaded numbers as there is no
opportunity for parallelism. These are unoptimized builds.
