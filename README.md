Goquery tools
-
Undergraduate computer science project at UOIT, year 2013-2014.  

Disclaimer: 
-

**What follows is an incomplete specification while the language was still heavily under development. There is no warranty that any described feature actually exists. If you have interest in the project and want to read something up-to-date, I would recommend skimming the thesis. **

GoAL: Go Analysis Language
=

The Go analysis language provides a high-level event based way to manipulate the Go AST. Specifically, it provides a domain-specific way of accessing the [go.ast package](http://golang.org/pkg/go/ast/).

Labelled nodes:
-
These Lua functions produce labelled nodes (we will call them **label-nodes**). The label consists of the name of the node, eg 'Fields', and the data consists of the arguments to the function, eg the list of fields as Lua strings. These labelled nodes assemble into a tree, but have no meaning until they bubble up into a *root level function*.


1) Expression nodes
-

Expression nodes evaluate **to arbitrary Go objects**, including possibly any type in GoAL runtime (not in the program you are analyzing!).
A few special variable names exist for members of the [go.ast package](http://golang.org/pkg/go/ast/):

+ type: Return a unique string type representation of the node's .Type member, if it has one.
+ location: Return a location string that will be unique for the node **within its type**.
+ name: Return the name of any string with a .Name node (an alias for Name.Name)
+ receiver: Return the receiver type of a function (alias for Recv.List[0])

**Object access operators** occur in two forms:  

+ **receiver**.**type** "f"
+ **type**(**receiver** "f")
    
The flexibility in syntax makes object expressions easily composable (See **Compose** below).

Additional operators:

+ var: Access a variable, eg var "f" accesses "f". (var "f.receiver") is equivalent to (receiver "f")
+ **Eval** Evaluate to the first expression whose conditions are met.  
    *General form*: **Eval** (Conditions to meet **1**) (expression-node **1**) **...** (**Otherwise**) (expression-node **N**) 
+ **SQLQuery** Returns an SQL query as a loopable object. See **ForAll**.

2) Statement nodes
-
+ **Printf** C-like printf routine. Only '%s' is valid currently.
+ **Load** Load from a database. TODO: Document more
+ **Save** Save to a database. TODO: Document more
+ **SQLPrint** Prints the result of an SQL query.

3) Code conditional nodes
-
+ **IfExists** Evaluate if the expression does not evaluate to a **null** value.  
    *General form*: **IfExists** (object-expression-list)
+ **IfEqual** Evaluate if all the objects are equal, using Go equality rules.  
    *General form*: **IfExists** (object-expression-list)
+ **True**, **False**, **Otherwise** Constants. Note that **Otherwise** is an alias for **True**, for use in **Case** and **Eval** blocks.
+ **And, Or, Xor, NotAnd, NotOr, NotXor, Not**: Standard boolean operators. **Not** only takes one parameter.  
    *General form*: **{boolean op}** (conditional-node-list)

4) Code control labelled nodes
-
+ **Case** Perform the first code block whose conditions are met.  
    *General form*: **Case** (Conditions to meet **1**) (code-node-list **1**) **...** (**Otherwise**) (code-node-list **N**) 
+ **ForAll** Iterate a loopable object. All lists are loopable. Optional entry conditions can be specified before the code nodes.
    *General form*: **ForAll** (new variable, loopable expression) (Optional conditional-node-list) (code-node-list)



Root level functions
-
+ **Event** Used to define an AST analysis event. Optional entry conditions can be specified before the code nodes. These entry conditions can assert things about the variables defined.  
    *General form*: **Event**(Variable definitions and event configuration, see below) (Optional conditional-node-list) (code-node-list)  
    *Example*: **Event**(**FuncDecl** *"f"*) (**Printf** *"Hello World!"*)

    Event takes a list of varied arguments:  
    
    + Expressions of the form eg (**FuncDecl** "f") define new objects. Any type name from the [go.ast package](http://golang.org/pkg/go/ast/) is valid.  
    + You can assign names to multiple nodes at once via eg (FuncDecl.receiver "fd.r") would be the same as defining (FuncDecl "fd") and also setting its receiver to "r".
    + You can optionally specify a **CaseSet** by name. Only one **Event** with the **CaseSet** name will execute.
    + You can optionally specify a **EventSet** by name. **EventSet**s are used by **Analyze** to selectively execute **Event**s.
    + **ForAll** can be embedded, see above.

+ **Analyze**: Evaluate events for a list of files. Passing event sets to execute is optional; the global event set will be executed.  
    *General form*: **Analyze**(**Files** (list of files), (Optional) **EventSets**(list of event sets) )  
    *Example*: **Analyze**(**Files** "example.go")



New functions
-
Goal is extended primarily through Lua.  

Two convenience functions exist to form new functions, the **Compose**, **Inject**, **InjectAll** meta-functions.  
These two related functions can compose any of the nodes above (*whether or not doing so makes sense*!).

+ **Compose**(function **Func1**, function **Func2**)

    Return a new function that applies **Func2** to all parameters, and passes the result to **Func1**.

    *Example*: **GetReceiverName** = **Compose**(**name**, **receiver**)  
    *Example Usage*: **Printf** ("%s\n", **GetReceiverName** "f")

+ **Inject**(function **Func1**, function **Func2**, param N (default first))  
    Return a new function that applies **Func2** to the Nth parameter, and passes the rest of the parameters unchanged to **Func1**.

    *Example*: **IfReceiverExistsAnd** = **Inject**(**And**, **IfReceiverExists**)  
    *Example Usage*: **Case**(**IfRecevierExistsAnd**("r", **True**)) (**Printf** "We have a receiver and true is true!")

+ **InjectAll**(function **Func1**, function **Func2**)  
    Return a new function that applies **Func2** to every parameter, which are then passed in turn to **Func1**.  

    *Example*: **IfReceiverExists** = **InjectAll**(**IfExists**, **Receiver**)  
    *Example Usage*: **Case**(**IfRecevierExists** "r1") (**Printf** "We have a receiver!")  
    The new function takes any amount of objects, and evaluates if all of their receivers are not **null**.  

Note that **Inject** == **Compose** == **InjectAll** for all one-argument **Func1**. The recommended idiom is to always use **Compose** in these cases.

Escaping to Lua
-
For cases where performance is acceptable, you may dynamically context switch between Lua and the GoAL runtime.  
It is very flexible: you can write arbitrary logic in Lua, store data in Lua variables, store data that affects the definition of future events, etc.  
Be warned though, if you are on the fence about performance, the context switch overhead is easy to underestimate.

+ **LuaWrap** Returns a Lua function that, during the running of the event, is passed objects or string objects and returns an object or a string.  

    **Word of Warning:** The AST **can** be modified, since you have access to all Go reflection (thanks to '[luar](https://github.com/stevedonovan/luar/)') but do note it may render **currently running** DSL code incorrect (namely cache coherency) if it deals with the same data.


GoAL Implementation Details
=

The DSL compiler is completely implemented in Lua using these very low level direct wrappings. The Go runtime has no concept of correct code. [The Lua compiler is in one (long) file here](https://github.com/ludamad/goquery/blob/master/src/goal/prelude.lua).
