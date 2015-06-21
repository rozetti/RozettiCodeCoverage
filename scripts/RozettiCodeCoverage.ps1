# ******************************************************************************
# RozettiCodeCoverage. Copyright 2015 Conrad Rozetti, crz@rozetti.org.
# ******************************************************************************
# The MIT License (MIT)
#
# Copyright(c) 2015 Conrad Rozetti
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files(the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions :
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ******************************************************************************

# crz: for the time being this project uses OpenCodeCoverage (which is GPLV3'd) to 
# generate coverage data, all this script does is parse the XML output and make it 
# human readable.

#---------------------------------------------------------------------------
# crz: hack these variables to suit your project, this example setup is how I run
# against RozettiCore

$OCC_FOLDER = 'C:\Program Files\OpenCppCoverage'

$SCRIPT_FOLDER = Split-Path -parent $MyInvocation.MyCommand.Definition
$TARGET_FOLDER = "$SCRIPT_FOLDER/debug/"
$TARGET_EXECUTABLE = "rz_core.tests.exe"

$SOURCES_FOLDER = "C:\Users\conrad\Documents\RozettiCore\src"
$SOURCES_FILTER = "rz_core"

$OUTPUT_FILENAME = "coverage.xml"
$REPORT_FILENAME = "../test_coverage.txt"

#---------------------------------------------------------------------------
# crz: probably leave this alone

$OCC = "$OCC_FOLDER\OpenCppCoverage.exe"

$OCC_ARGS = @(
	'--verbose', 
	"--export_type=cobertura:$OUTPUT_FILENAME", 
	"--sources=$SOURCES_FILTER", 
	"--modules=$TARGET_EXECUTABLE", 
	"--", 
	"$TARGET_EXECUTABLE")

#---------------------------------------------------------------------------
# crz: don't hack anything below here

function TestPathOrDie($path, $message)
{
	if (-not (Test-Path $path))
	{
		"ABEND: $message"
		exit 1 # crz: this always returns exit code 0, for some reason
	}
}

function FoundEndOfBadBlock([int]$number, [int]$start, [int]$end) {
	$n = $end - $start + 1
	"`tblock`:$number $start->$end (spanning $n text lines)"
}

TestPathOrDie $OCC_FOLDER "OpenCppCoverage is not installed"
TestPathOrDie $TARGET_FOLDER "Target folder does not exist"
TestPathOrDie "$TARGET_FOLDER\$TARGET_EXECUTABLE" "OpenCppCoverage is not installed"

Push-Location -Path $TARGET_FOLDER

$source_files = (Get-ChildItem $SOURCES_FOLDER\*.* -Include *.cpp)

if (Test-Path $OUTPUT_FILENAME) { Remove-Item $OUTPUT_FILENAME -Force }

& $OCC $OCC_ARGS

$xml = [xml](Get-Content $OUTPUT_FILENAME)
$classes = $xml.SelectNodes('/coverage/packages/package/classes/class')

Start-Transcript -Path $REPORT_FILENAME

$classes | foreach { 
	$all_good = 1
	$filename = $_.name

	$o = $null
	$source_files | foreach {
		if ($_.Name.CompareTo($filename) -eq 0) { 
			$o = $_ 
		} 
	}
	if ($null -ne $o) {
		$source_files = $source_files -ne $o
	}
	 
	$lines = $_.lines.SelectNodes('line')
	$number_of_bad_blocks = 0

	$number_of_lines = ($lines).Count
	if ($number_of_lines -eq 0) {
		"$filename`: no testable lines"
		return
	}

	$number_of_uncovered_lines = ($lines | where { $_.hits -eq 0 } | Measure-Object).Count

	if ($number_of_lines -eq $number_of_uncovered_lines) {
		"$filename`: 0% coverage, none of the $number_of_lines executable lines are covered"
		return
	}

	if ($number_of_uncovered_lines -eq 0) {
		"$filename`: 100% coverage"
		return
	}

	$coverage = [math]::round(100 * (1 - $number_of_uncovered_lines / $number_of_lines), 0)

	"$filename`: $coverage% coverage, $number_of_uncovered_lines of $number_of_lines executable lines are not covered"

	$in_bad_block = $false
	$bad_block_start = 0
	$bad_block_end = 0

	$lines | foreach {
		$bad = $_.hits -eq 0

		if ($bad) {
			if (-not $in_bad_block) {
				$in_bad_block = $true
				$number_of_bad_blocks = ($number_of_bad_blocks + 1)
				$bad_block_start = $_.number
			}

			$bad_block_end = $_.number
		}
		else {
			if ($in_bad_block) {
				$in_bad_block = $false
				FoundEndOfBadBlock $number_of_bad_blocks $bad_block_start $bad_block_end
			}
		}

	}

	if ($in_bad_block) {
		FoundEndOfBadBlock $number_of_bad_blocks $bad_block_start $bad_block_end
	}
}

$source_files | foreach {
	$filename = $_.Name
	"$filename`: 0% coverage, this file was not tested at all"
}

Stop-Transcript

Pop-Location

exit 0

