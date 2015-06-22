#RozettiCodeCoverage

This little (for now at least) project aims to provide a free and practical way of *estimating* C++ unit test code coverage. 

The approach is *currently* based around [OpenCppCoverage](http://opencppcoverage.codeplex.com), the only thing this project adds is a PowerShell 
script that parses the XML output and produces 
[a very simple text file](http://github.com/rozetti/RozettiCodeCoverage/blob/master/sample_test_coverage.txt)
listing the blocks of code that were not touched by a
test suite. 

##Up-front caveats

I say "*estimating*" because if the compiled product of any part of a line of source code executes, at any point during the test 
run, the whole line is considered 
'covered'. This can be misleading for at least two reasons:

First, consider a `for` loop such as

```
  for (int i = 0; i < 10; ++i) 
  {
    if (some_external_influence) break;
    
    nine_char_long_array[i] = 0;
  },
```
which might go around a few times and exit, showing 100% coverage, without ever testing the false branch of the condition (which 
in this case leads to a buffer overrun). 

Second, a block of code might be reachable from many places within a class, this system will only tell you that code was executed
*at some point* during the run.

Either of these issues can lead to dangerous over-confidence, which I had to learn this the hard way.

I say "*currently*" because the result is not actually all that good and (with the
greatest respect to its author) I hope to replace OpenCppCoverage with a statically linkable module that I can integrate
with Google Test to provide a report which is less of an estimate. That said, the result is much better than nothing, 
particularly if (like me) you are integrating externally sourced code with TDD-produced code which has 100% coverage. This makes 
it relatively easy to find the un-covered holes (such as edge-case null checks that return from a function early) and create 
tests to protect them.

##Usage

Note: so far I have only run this script from inside a Visual Studio 2015 RC solution folder. I can't immediately think of a 
reason why it would not work anywhere that OpenCppCoverage works (which implies Windows), although if you are not using Visual
Studio you might need to tweak folder settings in the script.

I detail below how I have this set up for my [RozettiCore](http://github.com/rozetti/RozettiCore) project, which is also 
on GitHub. Probably the best way to see how it works is to check out that repo and try it.

The basic process is this:

1. Install [OpenCppCoverage](http://opencppcoverage.codeplex.com).

2. Copy [RozettiCodeCoverage.ps1](http://github.com/rozetti/RozettiCodeCoverage/blob/master/scripts/RozettiCodeCoverage.ps1) 
script from this repo into the root of your solution folder.

3. Edit the script (using notepad.exe, for example) and change the variables at the top of the file to reflect the
specifics of your project. It is designed to be self-explanitory.

4. Build the project.

5. Run the script, for example by right-clicking on it and choosing "Run with PowerShell".

6. If all goes well, the tests will run and you will find a file called 
[test_coverage.txt](http://github.com/rozetti/RozettiCodeCoverage/blob/master/sample_test_coverage.txt) in the solution
folder. Details about how to interpret this file are given below.

##The Report File

The report lists every source file found in the $SOURCES_FOLDER folder, whose filename or path contains
the string $SOURCES_FILTER. For each file you are given an estimate of the code coverage percentage (from 0% to 100%),
and a list of line number ranges for the blocks of source code that were not executed during the run. 

For now you have to manually match up the line numbers to the source, but I hope to produce a VS plugin that will 
highlight the un-covered code.
