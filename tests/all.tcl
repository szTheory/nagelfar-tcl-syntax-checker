#!/bin/sh
#----------------------------------------------------------------------
# $Revision$
#----------------------------------------------------------------------
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

set thisScript [file normalize [file join [pwd] [info script]]]
set thisDir    [file dirname $thisScript]

package require tcltest
namespace import tcltest::*
tcltest::configure -verbose "body error" -singleproc 1
#tcltest::configure -file oo*
#tcltest::configure -match gui-6*

testConstraint runin86 [expr {[info commands oo::class] ne ""}]
#testConstraint knownbug 1
#testConstraint benchmark 1

if {$argc > 0} {
    eval tcltest::configure $argv
}

proc createTestFile {scr {filetype 0}} {
    # Trick to allow body to include backslash-newline
    set scr [string map [list "%%\n" "\\\n"] $scr]
    if {$filetype == 2} {
        set ch [open _testfile_.plugin.tcl w]
    } elseif {$filetype == 3} {
        set ch [open _testfile_.plugin2.tcl w]
    } elseif {$filetype == 1} {
        set ch [open _testfile_.syntax w]
    } else {
        set ch [open _testfile_ w]
    }
    puts -nonewline $ch $scr
    close $ch
}

proc execTestFile {args} {
    set xx(-fn) _testfile_
    set xx(-flags) {}
    array set xx $args
    set fn $xx(-fn)
    array unset xx -fn
    set flags $xx(-flags)
    array unset xx -flags
    
    set file nagelfar.tcl
    if {[file exists ${file}_i]} {
        set file ${file}_i
    }
    set code [catch {eval [list exec [info nameofexecutable] $file $fn] \
            [array get xx] $flags} res] ;#2>@ stderr
    if {$code && [llength $::errorCode] >= 3} {
        set code [lindex $::errorCode 2]
    }
    # Simplify result by shortening standard result
    regsub {Checking file _testfile_\n?} $res "%%" res
    regsub {Parsing file _testfile_.syntax\n?} $res "xx" res
    regsub {\s*child process exited abnormally\s*} $res "" res
    file delete -force _testfile_.syntax
    return -code $code $res
}    

# Helper while designing tests, to see runtime errors
proc evalTestFile {} {
    set xx(-fn) _testfile_
    set fn $xx(-fn)
    interp create -safe _apa
    interp expose _apa source
    catch {_apa eval source $fn} r
    interp delete _apa
    return $r
}

proc execTestFileInstrument {args} {
    set xx(-flags) {}
    array set xx $args
    lappend xx(-flags) -instrument

    set res [list [execTestFile {*}[array get xx]]]

    set i [lsearch $xx(-flags) -idir]
    if {$i >= 0} {
        incr i
        set ifile [lindex $xx(-flags) $i]/_testfile__i
    } else {
        set ifile _testfile__i
    }
    set ch [open $ifile r]
    set data [read $ch]
    close $ch
    file delete $ifile
    foreach {item lineNo} [regexp -inline -all {_testfile_,(\d+)} $data] {
        lappend res $lineNo
    }

    return $res
}    

proc cleanupTestFile {} {
    file delete -force _testfile_
    file delete -force _testfile2_
    file delete -force _testfile_.syntax
    file delete -force _testfile_.plugin.tcl
    file delete -force _testfile_.plugin2.tcl
}

tcltest::testsDirectory $thisDir
tcltest::runAllTests

cleanupTestFile
tcltest::cleanupTests
