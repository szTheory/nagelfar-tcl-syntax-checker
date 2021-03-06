.. highlightlang:: tcl

.. |nbsp| unicode:: 0xA0
   :trim:

Object Orientation
==================

Introduction
------------

The main problem with checking OO-style code is lines like this:

.. code:: tcl

 $obj dosomething $arg

Since Nagelfar does not know the command, it does not know the syntax
for it, and specially if an argument is a code block, it will not know
that it should check into it.

Basically what is needed is types.  If the type of $obj is known it
can be checked.
By introducing return types of commands and types of variables, code
like this becomes checkable:

.. code:: tcl

 set w [frame .f]
 $w configure -apa hej

First Example
^^^^^^^^^^^^^

If you have a command ``myCmd`` that returns an object which has a ``foreach``
loop method, the following are the basic steps needed to get going.

.. code:: tcl

 set o [myCmd stuff]
 $o foreach x {
     puts $x
 }

First give your object type a name. It should be prefixed with the magic
string "_obj,". Let's call it "myObj".

Define a return type to ``myCmd`` with the object type.

``##nagelfar return myCmd _obj,myObj``

Define this object type as a command with a sub-command (a.k.a method)

``##nagelfar syntax _obj,myObj s x*``

Define the list of valid sub-commands.

``##nagelfar subcmd _obj,myObj foreach configure dostuff``

Define the syntax for a specific subcommand.

``##nagelfar syntax _obj,myObj\ foreach n c``

Explicitly Named Object
^^^^^^^^^^^^^^^^^^^^^^^

It is possible that myCmd instead of returning the object takes an explicitly
named object name as argument.

.. code:: tcl

 myCmd t1
 t1 dostuff

The critical definition uses the define command (dc) token:

.. code:: tcl

 ##nagelfar syntax myCmd dc=_obj,myObj

Defining it manually for that instance is also possible by doing the copy
that is built into the "dc=" token.

.. code:: tcl

 ##nagelfar copy _obj,myObj t1

Objects in parameters
^^^^^^^^^^^^^^^^^^^^^

Sometimes it is necessary to declare a variable as an object:

.. code:: tcl

 proc testingwithproc {ob} {
     ##nagelfar vartype ob _obj,myObj
     $ob dostuff
 }

 ##nagelfar syntax testingwithproc2 x(_obj,myObj)
 proc testingwithproc2 {ob} {
     $ob dostuff
 }

Implicit variables
^^^^^^^^^^^^^^^^^^

Some OO systems make instance variables "magically" show up in a method's
scope. Nagelfar needs to be told about this per object type using inline
directive "implicitvarns".

Example for a Snit object:

.. code:: tcl

 ##nagelfar syntax pdf4tcl::pdf4tcl dc=_obj,pdf4tcl p*
 ##nagelfar return pdf4tcl::pdf4tcl _obj,pdf4tcl

 ##nagelfar implicitvarns snit::type::pdf4tcl::pdf4tcl self\ _obj,pdf4tcl pdf

 snit::type pdf4tcl::pdf4tcl {
     variable pdf
     ...
 }

Details
-------

Class Definition
^^^^^^^^^^^^^^^^

In order to automatically extract as much as possible from coded class
definitions, base info about how a class definition works is needed.
This is typically only done when setting up info for an OO system,
not for a single object.

A class definition is resolved in a virtual namespace where
commands like "constructor" and "method" can be recognised.
It is denoted by the "cn" syntax token. It typically
comes after the "define object", "do", token.

The virtual namespace is named after the calling
command and its arguments.  Examples:

.. code:: tcl

 ##nagelfar syntax itcl::class do cn
 itcl::class Test { ... }

Virtual namespace: itcl::class::Test

.. code:: tcl

 ##nagelfar syntax snit::type do cn
 snit::type pdf4tcl::pdf4tcl { ... }

Virtual namespace: snit::type::pdf4tcl::pdf4tcl

.. code:: tcl

 ##nagelfar syntax oo:class\ create do cn
 oo::class create Account { ... }

Virtual namespace: oo::class\ create::Account

Since name resolution works up the namespaces, class definition subcommands
can be defined in the top virtual namespace for the class definition:

.. code:: tcl

 ##nagelfar syntax itcl::class::constructor cv
 ##nagelfar syntax itcl::class::method dm
 ##nagelfar syntax snit::type::constructor cv
 ##nagelfar syntax snit::type::method dm
 ##nagelfar syntax oo::class\ create::constructor cv
 ##nagelfar syntax oo::class\ create::method dm


OO Systems
----------

Different common OO systems needs different handling.
Nagelfar has some built in knowledge about some of them that simplifies
using them.

For now, see the "ootest" directory in Nagelfar's source for some notes.

TclOO
^^^^^

Included in any 8.6+ database.

To be written...

Snit
^^^^

Included in packagedb/snitdb.tcl.

Each object definition typically needs annotation for instance variables
and options. Example of a Snit object's annotation:

.. code:: tcl

 ##nagelfar syntax pdf4tcl::pdf4tcl dc=_obj,pdf4tcl p*
 ##nagelfar return pdf4tcl::pdf4tcl _obj,pdf4tcl
 ##nagelfar option pdf4tcl::pdf4tcl -file
 ##nagelfar option _obj,pdf4tcl\ configure -file
  
 ##nagelfar implicitvarns snit::type::pdf4tcl::pdf4tcl self\ _obj,pdf4tcl pdf
  
 snit::type pdf4tcl::pdf4tcl {
     variable pdf
     option -file      -default "" -readonly 1
     constructor {args} {
         $self configurelist $args
     }
     destructor {
         $self finish
         close $pdf(ch)
     }
     method cleanup {} {
         $self destroy
     }
     method finish {} {
         $self RequireVersion a
     }
     method RequireVersion {version} {
         $self finish
         if {$version > $pdf(version)} {
             set pdf(version) $version
         }
     }
 }


ITcl
^^^^

To be written...

TDBC
^^^^

To be written...
