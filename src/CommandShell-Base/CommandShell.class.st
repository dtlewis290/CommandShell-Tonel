"
I am a command shell, similar to /bin/sh, with a simple command line user interface. I collaborate with process proxies to provide command execution, and I provide a limited set of built in commands similar to those in /bin/sh. My built in commands are implemented in Smalltalk, and any other commands are passed to process proxies to be executed either internally as Smalltalk ""doIt"" expressions, or externally as commands passed to the external operating system. I am similar to a TranscriptStream (some methods are copied directly from TranscriptStream), but I also know how to accept lines of command input, parse them, and hand them off to process proxies for execution.

Three types of commands may be executed from a CommandShell: internal ""builtin"" commands implemented in Smalltalk; internal Smalltalk ""doIt"" commands; and external commands. Internal commands (builtin commands or doIt commands) may be freely mixed with external operating system commands in a command pipeline. See CommandShell class>>commandProcessing for more information.

Each command line is first evaluated as a Smalltalk expression, and is subject to further parsing only if the Smalltalk evaluation fails. In practice, this permits complete Smalltalk expressions to be evaluated easily without conflicting with shell syntax, and allows Smalltalk and unix shell commands to be freely mixed.

Simple command scripting is supported (method category 'command scripting'). Any mix of internal and external commands may be included in a script. Conditional branching is supported based on command exit status.

Open a new shell window with ""CommandShell open"". Type 'help' followed by <return> or <enter> for help on builtin commands.

Things that work reasonably well:
- Simple command execution for running command line programs or starting
  X programs.
- Command pipelines. Built in commands can be mixed with external
  commands, as in ""help sqsh | wc -l"".
- Command IO redirection with '<',  '>', '>>', '2>', and '2>>'.
- Command history and command history recall.
- Background command execution, as in ""xterm&"".
- <ctl-C> to interrupt a running external command.
- <ctl-D> to indicate end of file in terminal input.

Limitations include:
- Dumb tty only. Do not try to run vi.
- Standard Unix shell syntax is not completely implemented.

Race conditions are possible for certain command pipelines. See CommandShell class>>raceConditions for more information.

"
Class {
	#name : #CommandShell,
	#superclass : #Model,
	#instVars : [
		'outputStream',
		'errorStream',
		'shellSyntax',
		'environment',
		'builtinCommands',
		'commandHistory',
		'historyIndex',
		'promptString',
		'promptStringTwo',
		'foregroundProxies',
		'backgroundProxies',
		'backgroundPipelines',
		'commandLineProcesses',
		'backgroundMessageQueue',
		'keyboardConnector',
		'activeController',
		'safeToExit',
		'readSyncSemaphore'
	],
	#category : 'CommandShell-Base'
}

{ #category : #'instance creation' }
CommandShell class >> command: aCommandString [
	"Evaluate aCommandString in the context of a CommandShell, using a
	CommandShellTranscript to display the results."

	"CommandShell command: 'help'"
	"CommandShell command: 'ls'"

	| cs w |
	cs := self new.
	w := cs openLabel: self defaultWindowName.
	w scheduleToEvaluate: [w nextPutAll: aCommandString; cr].
	w processCommand: aCommandString.
	^ w

]

{ #category : #documentation }
CommandShell class >> commandProcessing [
	"Explanation of the command parsing and evaluation."

	"CommandShell new pipeline: 'CommandShell commandProcessing! | edit'"

	^
'CommandShell behaves similarly to a Unix command shell. One or more Morphic or MVC views can be opened on an instance of CommandShell. Command lines are accepted in the view, passed to the CommandShell instance (the model), and the results are displayed in the view(s). The overall behavior can be thought of as a Transcript acting like an xterm window, and the CommandShell acting like a /bin/sh shell.

A command line is first evaluated as a Smalltalk expression if possible. If this evaluation fails, either as a result of a sytax error or a runtime error, it is assumed to be a command string with syntax similar to that of a Unix command shell.

The command line is parsed by CommandShell to break command lines into elements of a command pipeline. All further parsing, such as file name expansion, is performed by an instance of ShellSyntax.

Three types of commands may be executed from a CommandShell:
1) Internal "builtin" commands are implemented in Smalltalk, and behave similarly to the shell builtin commands of a typical Unix command shell. See protocol category "shell builtins" for the implementation of these builtin shell commands.
2) Internal "doIt" commands are simple Smalltalk expression strings, terminated by a $! character, which are evaluated as Smalltalk expressions, and which recognize the tokens "stdin", "stdout", and "stderr" as temporary variables in the doIt expression. An internal doIt command is evaluated such that it may be incorporated into a command pipeline with access to the stdin/stdout/stderr streams used in the command pipeline. In the current implementation, a doIt command may not include a $| character, which has meaning both for Smalltalk syntax and for Unix command line processor syntax.
3) External commands. Any command expression not recognized as a shell builtin or as a doIt expression is passed to an external process proxy for execution by the external operating system, with stdin/stdout/stderr incorporated into the command pipeline.

Internal and external commands can be freely mixed in a command pipeline, with results which should be familiar to users of Unix command shells. Pipes are implemented as instances of OSPipe or InternalPipe, and are capable of passing streams of characters from one process proxy to the next. All commands (internal or external) evaluate to strings, such that their results can either be passed through a pipe to the next command proxy in a pipeline, or displayed in the terminal window view if the proxy represents the last command in a command pipeline. Error messages (also strings) are written to an errorPipelineStream which is shared by all proxies in a command pipeline, such that any error messages are accumulated for the entire command pipeline.'
]

{ #category : #'version dependent' }
CommandShell class >> defaultPathString [

	^ self useFileSystem
		ifTrue: [(((Smalltalk at: #Path) perform: #workingDirectory) perform: #asFileReference) pathString]
		ifFalse: [(Smalltalk at: #FileDirectory) default pathName]

]

{ #category : #defaults }
CommandShell class >> defaultWindowName [

	^ 'Squeak Shell'
]

{ #category : #'version dependent' }
CommandShell class >> deleteFileNamed: fileName [
	"Delete the file with the given name."

	self useFileSystem
		ifTrue: [ | file |
			file := fileName perform: #asFileReference.
			(file respondsTo: #ensureDeleted)
				ifTrue: [ file perform: #ensureDeleted ]
				ifFalse: [ file perform: #delete ] ]
		ifFalse: [ (Smalltalk at: #FileDirectory) default
				deleteFileNamed: fileName ]

]

{ #category : #'version dependent' }
CommandShell class >> deleteFileNamed: fileName inDirectory: directoryOrFileReference [
	"Delete the file with the given name in the given directory."

	^ self useFileSystem
		ifTrue: [ | f |
			(f := directoryOrFileReference files
				detect: [ :e | e basename = fileName ]
				ifNone: [  ]) notNil
				ifTrue: [ f delete ] ]
		ifFalse: [ directoryOrFileReference deleteFileNamed: fileName ]
]

{ #category : #'version dependent' }
CommandShell class >> dirPathFor: path [
	"Return the directory part the given name."

	^ self useFileSystem
		ifTrue: [ (path perform: #asFileReference) parent fullName ]
		ifFalse: [(Smalltalk at: #FileDirectory) perform: #dirPathFor: with: path]

]

{ #category : #'version dependent' }
CommandShell class >> directoryEntryNames: path [

	^ self useFileSystem
		ifTrue: [ (path perform: #asFileReference) children collect: [:e | e perform: #basename] ]
		ifFalse: [ ((Smalltalk at: #FileDirectory) on: path) entries collect: [:e | e name] ]

]

{ #category : #'version dependent' }
CommandShell class >> directoryExists: path [
	"Answer true if a directory of the given name exists. The given name may
	be either a full path name or a local directory within this directory."

	^ self useFileSystem
		ifTrue: [ (path perform: #asFileReference) exists ]
		ifFalse: [ (Smalltalk at: #FileDirectory) default directoryExists: path ]

]

{ #category : #'version dependent' }
CommandShell class >> directoryForPath: path [

	^ self useFileSystem
		ifTrue: [path perform: #asFileReference]
		ifFalse: [(Smalltalk at: #FileDirectory) on: path]

]

{ #category : #'version dependent' }
CommandShell class >> directoryNamesInPath: path [

	^ self useFileSystem
		ifTrue: [ (path perform: #asFileReference) children	
					select: [:e | e isDirectory ]
					thenCollect: [:e | e perform: #basename] ]
		ifFalse: [ ((Smalltalk at: #FileDirectory) on: path) entries
					select: [:e | e isDirectory ]
					thenCollect: [:e | e name] ]

]

{ #category : #'version dependent' }
CommandShell class >> entryName: directoryEntry [
	"Answer the name of a directory entry."

	^ self useFileSystem
		ifTrue: [ directoryEntry basename ]
		ifFalse: [ directoryEntry name ]

]

{ #category : #'version dependent' }
CommandShell class >> fileExists: path [
	"Answer true if a file of the given name exists. The given name may be
	either a full path name or a local file within this directory."

	^ self useFileSystem
		ifTrue: [ (path perform: #asFileReference) exists ]
		ifFalse: [ (Smalltalk at: #FileDirectory) default fileExists: path ]

]

{ #category : #'version dependent' }
CommandShell class >> fileExists: fileName inDirectory: directoryOrFileReference [
	"Answer true if a file of the given name exists in this directory."

	^ self useFileSystem
		ifTrue: [ (directoryOrFileReference entries
					detect: [:e | e basename = fileName] ifNone: []) notNil ]
		ifFalse: [ directoryOrFileReference fileExists: fileName ]

]

{ #category : #'version dependent' }
CommandShell class >> fileExists: fileName inPath: path [
	"Answer true if a file of the given name exists in the directory named by path."

	^ self useFileSystem
		ifTrue: [ self fileExists: fileName inDirectory: (path perform: #asFileReference) ]
		ifFalse: [ self fileExists: fileName inDirectory: ((Smalltalk at: #FileDirectory) on: path) ]

]

{ #category : #'version dependent' }
CommandShell class >> fileNamed: fileName inDirectory: directoryOrFileReference [
	"Open the file with the given name in this directory for writing."

	^ self useFileSystem
		ifTrue: [ | f |
			(f := directoryOrFileReference files
				detect: [ :e | e basename = fileName ]
				ifNone: [  ]) notNil
				ifTrue: [ f writeStream ] ]
		ifFalse: [ directoryOrFileReference fileNamed: fileName ]
]

{ #category : #'version dependent' }
CommandShell class >> fullNameFor: fileName [
	"Return a corrected, fully-qualified name for the given file name."

	^ self useFileSystem
		ifTrue: [ (fileName perform: #asFileReference) perform: #fullName ]
		ifFalse: [ (Smalltalk at: #FileDirectory) default fullNameFor: fileName ]

]

{ #category : #documentation }
CommandShell class >> htmlOverview [
	"A general overview"

	^
'<html><head><title>Introduction to CommandShell</title></head>
<body>
<h3>CommandShell</h3>
 CommandShell is a Smalltalk implementation of a command processor shell and terminal
 window. It is intended to behave like to a simple terminal window (like xterm) running
 a Unix command shell (like /bin/sh). It lacks some elements of Unix shell syntax, and
 does not provide terminal emulation, but it adds some nice Smalltalk enhancements such
 as a text editor which works in a command pipeline, and the ability to evalute Smalltalk
 expressions in a command pipeline with Unix commands.

<h3>How to use CommandShell</h3>
  Evaluate "CommandShell open" or, if you have loaded the change set to put CommandShell
  in your world menu, just select "Squeak Shell" from the "open..." menu entry.
  To use the command shell window, enter commands on the command line (after
  the "$ " command prompt, followed by cr to accept the command. The "help" command
  gives some clues as to what can be done. In general, just try any command which
  you might otherwise enter into a Unix shell or xterm window. Then try some of
  the Smalltalk features such as mixing Smalltalk expressions with Unix commands, and
  piping commands into Smalltalk editors.

<h3>Basic Concepts</h3>
<ul><li><h4>  Commands</h4>
    Smalltalk uses objects and messages, with expressions arranged in a natural
    Noun-Verb-Predicate sentence structure, similar to that of some spoken languages.
    In contrast, many other computer systems use a style in which users issue
    a command to the system, in which the "command" (a verb) is followed by various
    (predicate) modifiers. In the case of a traditional command-line interface, such
    as a Unix shell, the command is usualy the name of a program, and the modifiers
    are parameters passed to the program to influence its behavior. CommandShell attempts
    to provide a command line interface for executing commands within Squeak, in
    a style and environment which is comforable for someone accustomed to the
    Smalltalk style of expression.
<p>
<li><h4>  Process Proxies</h4>
    A command line user interface, such as a Unix shell or a "DOS window" in
    Windows, revolves around the notion of executing programs from user commands.
    When Squeak is hosted in another operating system, it is useful to be able to
    execute an external program from a command line expression. A process proxy
    is an object which represents the evaluation of such an external command
    in a command line environment.
<p>
    From the point of view of Squeak, a process proxy might just as well represent
    the evaluation of a Smalltalk expression in the context of a command line
    environment. Thus a process proxy can be an object which represents the execution
    of an external program or an internal Smalltalk expression. It is created from a
    command line expression, and provides a representation of certain aspects of the
    external (or internal) process execution, such as process run state, exit status, and
    the input, output and error streams for the process.
<p>
    External process proxies are used to evaluate programs in the external operating
    system (this requires the OSProcess change set in addition to CommandShell). Internal
    process proxies are used to evaluate "built in" commands for a command shell,
    such as the "cd" command to change the working directory for the command shell.
    Internal proxies are also used for evaluating "doIt" expressions within a command
    pipeline. In this case, the variables "stdin", "stdout", and "stderr" are pre-defined
    such that the doIt expression can directly access the input, output and error
    pipes for the internal process proxy (in other words, the doIt expression
    "stdout nextPutAll: ''Hello world'' !" will write ''Hello world'' on the output pipe
    of the proxy).
<p>
<li><h4> Pipelines</h4>
    Powerful computing systems may be built upon simple design metaphors. In
    Smalltalk, the concept of objects communicating through messages is generalized
    and extended to produce the Squeak system. In Unix systems, the metaphor of a
    pipe with data flowing between two programs is generalized to produce a mechanism
    for connecting small programs to produce complex systems. The command line shells
    for Unix support this metaphor by providing syntax for connecting two or more
    commands together into more complex command pipelines.
<p>
    CommandShell provides a framework for connecting several process proxies into a
    command pipeline, using command syntax similar to that of a Unix shell. Since the
    process proxies are implemented in Smalltalk, the "programs" in a command pipeline
    may consist of process proxies representing external programs, or of proxies representing
    the evaluation of internal Smalltalk expressions. The objects which flow through
    the pipes in a command pipeline are assumed to be characters, such that the external
    commands can operate on the streams of characters in the usual way, and the internal
    Smalltalk commands read and write streams of characters.
<p>
    Just as programs (or internal expressions) are represented by process proxies, the
    pipes which interconnect two process proxies are represented by pipe objects. The
    pipe may be either an OSPipe (a proxy representing a Unix system FIFO pipe) or an
    InternalPipe (a Smalltalk object which behaves similarly to an OSPipe). The combination
    of process proxies and pipes is a command pipeline, which may be created and
    evaluated from a command line expression using conventional Unix shell syntax.
</ul>
<h3>Command Line Syntax</h4>
    A command or command pipeline may be created from a string expression, and
    evaluated using Unix shell syntax. CommandShell accepts command line strings and
    does some high level processing to set up process proxy execution. For most of the
    command parsing, it relies on a ShellSyntax object to do the syntax evaluation.
    In particular, a real Unix shell interprets command line parameters in the context of the
    Unix file system, expanding "wildcard" characters and searching for files in the context
    of a "current working directory" location in the file system tree. A CommandShell,
    collaborating with an instance of ShellSyntax, implements this syntax parsing
    and evaluation in Smalltalk.

<h3>Command Execution</h4>
    Beginning with a command line (which may represent a pipeline of several
    commands), a CommandShell first attempts to treat the entire command line as
    a Smalltalk expression. The command line string is used to create an instance of
    PipeableEvaluator (a kind of process process). If the expression is successfully
    compiled and evaluated in the PipeableEvaluator, the command line is executed
    just as if it were an external Unix command, with the result of the evaluation
    written as a string to the output stream of the process proxy.
<p>
    If the complete command line cannot be treated as a Smalltalk expression,
    CommandShell assumes that it must be a Unix style command pipeline. If the
    command line is a comment (starting with ''#'') it is discarded; otherwise it
    is broken down into a series of process proxies connected by pipes, with
    command line parameters and other aspects of the command line parsing handled
    by a ShellSyntax object.
<p>
    The process proxies in the command pipeline may represent internal or external
    commands. CommandShell parses the command line to create the proxies by breaking
    the command pipeline into segments (separated by the "|" pipe character), with
    different kinds of process proxy created according to the following priorities:
<ul><li>
      If the command segment is a simple Smalltalk expression terminated by "!", it
      is treated as a "doIt" expression, evaluated in a PipeableEvaluator proxy. This
      kind of simple doIt expression is limited to commands with characters which
      are unambiguous in a shell command. For example, "|" has special meaning in
      a command line, and cannot be used in a doIt expression (command line quoting
      and escape characters have not yet been implemented in the CommandShell syntax).
<li>
      If the command segment is not a doIt expression, CommandShell checks to see
      if it matches one of several "shell builtin" commands. These are special commands
      implemented in class ShellBuiltin and evaluated in a PipeableEvaluator proxy.
      They behave analogously to shell builtin commands in a conventional Unix shell.
      A number of commands such as "cd" and "pwd" are implemented as internal builtin
      commands, rather than relying on Unix external equivalents. In addition, other
      builtin commands such as "edit" do things which are useful in Squeak and have
      no real equivalent in Unix (the "edit" builtin opens an editor within Squeak, taking
      its input from files or directly from the output of a command pipeline such as
      "Smalltalk ! | edit" or "who | edit").
<li>
      If the command segment is not a shell builtin command, it is assumed to be an
      external command. It this case, the command line segment is fully parsed, then
      used to create an external OS process proxy to run the external command. The
      external process proxy responds to a #value message by running the external
      program, with output and error written to pipes connected to the command
      pipeline.
<li>
      Finally, if no external program can be found to execute the command, an error
      message is provided to the command window, and no command is evaluated.
</ul>
    Once the command proxy pipeline has been created, the individual process proxies
    are evaluated in such a way that they appear to execute in parallel, with each
    proxy reading its input from a pipe connected to its predecessor in the pipeline,
    and writing its output to a pipe connected to its successor in the pipeline. An
    additional error pipe is shared by all process proxies in the pipeline, such that
    any error output is accumulated in the shared error pipe stream.
<p>
    A command shell can obtain the output and error of a complex command pipeline
    simply by evaluating the last process proxy in the chain, and reading up to the
    end of its output and error pipes. Since a process proxy knows its run state, and
    a pipe is not "at end" until a process proxy closes one end of the pipe, the pipeline
    can be constructed in such a way that the command shell is assured that all process
    proxies have completed their evaluation when the output of the last proxy is read
    up to the end of the pipe.
<p>
    As the last process proxy in a command pipeline is evaluated, CommandShell reads
    its output and error pipes, and displays the text in the View or Morph which it uses
    as its terminal window. When complete, it issues a new prompt string, and waits for
    another command line to be entered by the user.
<p>
<h3>Exercise for the Reader:</h4>
Which one of the following five command lines will generate
an error, and why?
<ol><li>
  $ stdout nextPutAll: ''hello world''
<li>
  $ stdout nextPutAll: ''hello world''; cr
<li>
  $ stdout nextPutAll: ''hello world''!
<li>
  $ stdout nextPutAll: ''hello world''; cr!
<li>
  $ stdout nextPutAll: ''hello world''!; stdout cr!
</ol>
<h3>Answer:</h4>
The fourth command will generate an error.
<ul><li>
  Line one is evaluated as a complete Smalltalk expression, and succeeds.
<li>
  Line two is evaluated as a complete Smalltalk expression, and succeeds.
<li>
  Line three is evaluated as a pipeline after failing evaluation as a complete Smalltalk
  expression. It succeeds as a pipeline with one internal doIt proxy, and produces
  the same output as line one.
<li>
  Line four cannot be evaluated as a complete Smalltalk expression. The ";" token
  causes the command line to be evaluated as two pipelines. The expression for the
  first pipeline does not have a trailing "!" token, so it is assumed to be an external
  command, and fails. The second pipeline is evaluated as a doIt on the string ''cr!'',
  which fails as an invalid Smalltalk expression. The error messages for both failures
  are accumulated on the shared error pipe, and are displayed in the terminal window.
<li>
  Line five is evaluated successfully as two pipelines, each consisting of one doIt
  proxy. The output is the same as for line two.
</ul></body></html>
'
]

{ #category : #'class initialization' }
CommandShell class >> initialize [
	"CommandShell initialize"

	| preferencesClass |
	ShellSyntax new isPharo5Update50558AndLater
		ifFalse: [ Smalltalk addToStartUpList: self ]
		ifTrue:
			[ (Smalltalk at: #SessionManager) default
				perform: #registerToolClassNamed:
				with: ThisOSProcess name ].
	(Smalltalk hasClassNamed: #Preferences)
		ifTrue:
			[ preferencesClass := Smalltalk at: #Preferences.
			(preferencesClass respondsTo: #setWindowColorFor:to:)
				ifTrue:
					[ preferencesClass
						setWindowColorFor: #CommandShell
						to: (Color colorFrom: self windowColorSpecification pastelColor) ]
				ifFalse: [  ]	"Squeak"	"Pharo images use some other preferences protocol" ].	"Pharo deprecates Preference in favor of pragma registration mechanism"
	Smalltalk
		at: #TheWorldMenu
		ifPresent:
			[ :class | 
			class class methodDict
				at: #registerOpenCommand:
				ifPresent:
					[ :method | 
					(method hasLiteral: #deprecated:)
						ifTrue:
							[  ]
						ifFalse:
							[ class unregisterOpenCommand: 'Squeak shell'.	"if previously registered"
							class
								registerOpenCommand:
									{'Squeak Shell'.
									{CommandShell.
									#open}} ]	"n.b.  use #hasLiteral: rather than #sendsSelector: for Squeak 3.8"	"Pharo issues deprecation and tells you to do it their way. Ignore the warning." ] ]
]

{ #category : #'version testing' }
CommandShell class >> isMorphic [
	"Squeak traditionally used #isMorphic to distinguish between Morphic
	and MVC user interfaces. In newer Squeak images, the current project
	knows its active user interface, so requests are vectored through the
	current project. Pharo images pretend to be unaware of the fact that
	they are running Morphic, refusing to respond to #isMorphic. This 
	implementation does reasonable things in any of the above scenarios."

	^(Smalltalk respondsTo: #isMorphic) not or: [Smalltalk isMorphic]
]

{ #category : #'version dependent' }
CommandShell class >> localNameFor: path [
	"Return the local part the given name."

	^ self useFileSystem
		ifTrue: [ (path perform: #asFileReference) perform: #basename ]
		ifFalse: [(Smalltalk at: #FileDirectory) perform: #localNameFor: with: path]

]

{ #category : #'VM building' }
CommandShell class >> makeVmIn: buildDirectoryPathName [
	"Rebuild the virtual machine and plugins in the buildDirectoryPathName
	directory. If the build is successful, save the image and restart using the
	new VM. This assumes that the currently executing VM is either located in,
	or linked to, the buildDirectoryPathName directory."

	"CommandShell makeVmIn: CommandShell defaultPathString, CommandShell pathSeparator, 'build'"

	| shell |
	shell := self new.
	shell open.
	^ shell makeVmIn: buildDirectoryPathName

]

{ #category : #'instance creation' }
CommandShell class >> open [
	"CommandShell open"

	^ self new open
]

{ #category : #'instance creation' }
CommandShell class >> openLabel: aString [

	"CommandShell openLabel: self defaultWindowName"

	^ self new openLabel: aString

]

{ #category : #'instance creation' }
CommandShell class >> openWithHelp [
	"CommandShell openWithHelp"

	self open processCommand: 'help'

]

{ #category : #documentation }
CommandShell class >> overview [
	"A general overview"

	"CommandShell new pipeline: 'CommandShell overview! | edit'"

	| rs ws |
	rs := ReadStream on: self htmlOverview.
	ws := WriteStream on: String new.
	[rs atEnd]
		whileFalse:
			[ws nextPutAll: (rs upTo: $<).
			rs upTo: $>].
	^ ws contents

]

{ #category : #'version dependent' }
CommandShell class >> pathNameDelimiter [

	^ self useFileSystem
		ifTrue: [(Smalltalk at: #DiskStore) current perform: #delimiter]
		ifFalse: [(Smalltalk at: #FileDirectory) pathNameDelimiter]

]

{ #category : #'version dependent' }
CommandShell class >> pathNameForDirectory: directoryOrFileReference [
	"Return the full name of this directory."

	^ self useFileSystem
		ifTrue: [directoryOrFileReference fullName]
		ifFalse: [ directoryOrFileReference pathName ]

]

{ #category : #'version dependent' }
CommandShell class >> pathSeparator [

	^ self useFileSystem
		ifTrue: [((Smalltalk at: #DiskStore) current perform: #delimiter) asString]
		ifFalse: [(Smalltalk at: #FileDirectory) slash]

]

{ #category : #'proxy creation' }
CommandShell class >> pipeableProxyFor: commandString [ 
	"Create a new proxy for a PipeJunction. The proxy may be any type
	of PipeJunction, such as a PipeableOSProcess or ExpressionEvaluator.
	Send #value to evaluate the newly created proxy."

	"(CommandShell pipeableProxyFor: 'ls -l') value upToEndOfFile"
	"(CommandShell pipeableProxyFor: 'Array new: 4 !') value upToEndOfFile"
	"(CommandShell pipeableProxyFor: 'help') value upToEndOfFile"

	^ self new
		pipeableProxyFor: commandString
		input: nil
		output: nil
		error: nil
		predecessorProxy: nil
]

{ #category : #'proxy creation' }
CommandShell class >> pipeline: aCommand [
	"Find the individual commands in a command pipeline string, and evaluate
	them as a command pipeline. Answer a ProxyPipeline collection of processes
	in the pipeline."

	"(CommandShell pipeline: 'ps | grep ps | wc') upToEndOfFile"
	"(CommandShell pipeline: 'ls NOSUCHFILE * | dd | cat') errorUpToEndOfFile"
	"(CommandShell pipeline: 'ls NOSUCHFILE * | dd | cat') upToEndOfFile"

	^ self new pipeline: aCommand

]

{ #category : #documentation }
CommandShell class >> raceConditions [

	"CommandShell new pipeline: 'CommandShell raceConditions! | edit'"

	^
'It may be possible to hang the Squeak VM in an IO race condition when doing certain command pipelines. These conditions have been largely eliminated for Unix platforms through the use of nonblocking pipes in conjunction with asynchronous IO or polling processes on the Smalltalk side of the pipes. However, these notes are provided to describe possible deadlock scenarios.

Note that nonblocking OS pipes are not yet available on Windows. Command pipelines with external OS processes on Windows are not supported. Blocking on read or write to an OSPipe in Windows will definitely lock the VM.

Two kinds of deadlock are possible. In both cases, deadlock occurs when the single-threaded Squeak VM is blocked on a read or write to an OS pipe, and the blocked condition can only be cleared by another process running in the blocked VM.

1) Block on write. The Squeak VM can block on a write to an OS pipe if the external process at the other end of the pipe does not keep up with reading it. One internal process proxy writes on an pipe to an external process proxy, and fills the pipe up to some capacity limit, after which the write blocks. The external proxy is writing its output to another internal process proxy in the command pipeline, which never executes because the VM is still blocked trying to write to the full pipe.

2) Block on read. The Squeak VM can block on a read from an OS pipe if the external process writing to the pipe never closes the pipe. The internal proxy will post a read on the output pipe from the external command. If the external command has exited, the read will return with a (possibly empty) string. However, if the external command either does not exit, or exits without Squeak being notified, the read on the output pipe will block indefinitely.

2a) In the case where the external command exits while the Squeak VM is blocked on a read, Squeak is unable to respond to the notification of the external process exiting. The process stays in a zombie state, the pipes therefore never get closed, and the VM stays in a blocked condition.

Here are things to try if a deadlock occurs:

Squeak will be blocked and will not respond to the mouse or keyboard. Open a command shell outside of Squeak (perhaps an xterm, or log in to another virtual terminal on Linux or FreeBSD). Using the "ps" command, find the Squeak VM process and its subprocesses. Kill the subprocess. In many cases this will free up the deadlock, and Squeak will come back to life. If this does not work, then you will probably find that one of the processes which you just killed is now in a "zombie" state, which means that the Squeak VM is deadlocked in such a way that it cannot recognize that its child process exited (and therefore cannot properly close the associated file handles). In this case, if your operating system supports a /proc file system, you may be able to break things free by emptying the pipes. On Linux, go to /proc/<pidOfTheSqueakVMProcess>/fd/ and do "cat" commands on all the pipe files in this directory. If none of this works, you are just plain stuck, and you will need to kill your Squeak session and recover anything valuable from the changes log.'
]

{ #category : #'system startup' }
CommandShell class >> startUp: resuming [
	"A CommandShell may be running external processes in background, and waiting
	for those processes to complete. If the Squeak image is stopped and restarted, the
	background processes are no longer children of the Squeak process, and there is
	no way to receive notification when the processes exit. This would result in leftover
	Smalltalk processes associated with the CommandShell waiting forever for the
	external processes to exit. The simplest way to prevent this is to terminate all
	the Smalltalk processes unconditionally after an image restart."

	resuming ifTrue: [self allSubInstances do: [:e | e startUpInNewSession]]

]

{ #category : #'class initialization' }
CommandShell class >> unload [
	Smalltalk at: #TheWorldMenu ifPresent: [ :class |
		class class methodDict at: #unregisterOpenCommandWithReceiver: ifPresent: [ :method |
			(method hasLiteral: #deprecated:) "n.b.  use #hasLiteral: rather than #sendsSelector: for Squeak 3.8"
				ifFalse: [ class unregisterOpenCommandWithReceiver: self ] ] ]
]

{ #category : #'version dependent' }
CommandShell class >> useFileSystem [
	"If true use FileSystem, otherwise use traditional FileDirectory. See senders
	for methods with file system dependencies."

	^ Smalltalk hasClassNamed: #FileReference
]

{ #category : #'version testing' }
CommandShell class >> versionString [

	"CommandShell versionString"

	^'4.6.20'
]

{ #category : #'window color' }
CommandShell class >> windowColorSpecification [
	"Answer a WindowColorSpec object that declares my preference"

	| windowColorSpec |
	windowColorSpec := Smalltalk
				at: #WindowColorSpec
				ifAbsent: [^ self error: 'this image does not support WindowColorSpec'].
	^ windowColorSpec
		classSymbol: self name
		wording: 'Squeak Shell'
		brightColor: (Color lightGray lighter paler)
		pastelColor: (Color lightGray lighter lighter paler paler)
		helpMessage: 'CommandShell window for evaluating Smalltalk and OS commands'
]

{ #category : #'version dependent' }
CommandShell class >> withBlanksTrimmed: aString [

	^ (aString respondsTo: #withBlanksTrimmed)
		ifFalse: [aString perform: #trimBoth "Pharo"]
		ifTrue: [aString perform: #withBlanksTrimmed]

]

{ #category : #accessing }
CommandShell >> activeController [
	"In Morphic, alway nil. In MVC, the controller which most recently invoked
	a command."

	^ activeController
]

{ #category : #accessing }
CommandShell >> activeController: aController [
	"In Morphic, alway nil. In MVC, the controller which most recently invoked
	a command."

	activeController := aController
]

{ #category : #accessing }
CommandShell >> backgroundMessageQueue [
	"When a background pipeline completes, it places a message in this queue.
	The message will be displayed the next time the user accepts a line of
	text (presses CR)."

	^ backgroundMessageQueue ifNil: [backgroundMessageQueue := OrderedCollection new]

]

{ #category : #accessing }
CommandShell >> backgroundMessageQueue: anObject [
	"Set the value of backgroundMessageQueue"

	backgroundMessageQueue := anObject
]

{ #category : #'event handling' }
CommandShell >> backgroundPipelineComplete: aPipeline commandIndex: index [
	"This message is sent when aPipeline has completed evaluation.
	Ensure that the output and error event handlers have had a chance
	to completely empty the pipes prior to cleaning things up."

	self waitUntilPipesAreEmpty: aPipeline.
	aPipeline closePipes; release.
	self backgroundMessageQueue addLast:
		((WriteStream on: String new)
			nextPutAll: '[', index asString, ']+ Done                     ';
			nextPutAll: aPipeline commandLine;
			cr;
			contents).
	self backgroundProxies removeAll: aPipeline.
	self unRegisterBackgroundPipeline: aPipeline at: index.
	self notifyRestorePrompt

]

{ #category : #accessing }
CommandShell >> backgroundPipelines [
	"The pipelines which are currently being evaluated in background. This
	collection is used to keep track of the background command lines by giving
	each background pipeline an index number corresponding to its position in
	this collection. New pipelines are inserted at the first available nil position
	in the collection, and the collection is expanded as needed."

	^ backgroundPipelines ifNil: [backgroundPipelines := OrderedCollection new]


]

{ #category : #accessing }
CommandShell >> backgroundPipelines: anObject [
	"Set the value of backgroundPipelines"

	backgroundPipelines := anObject
]

{ #category : #accessing }
CommandShell >> backgroundProxies [
	"All of my process proxies that are being evaluated in the background."

	backgroundProxies ifNil: [backgroundProxies := OrderedCollection new].
	^ backgroundProxies
]

{ #category : #accessing }
CommandShell >> backgroundProxies: aCollection [
	"All of my process proxies that are being evaluated in the background."

	backgroundProxies := aCollection

]

{ #category : #'process proxy creation' }
CommandShell >> builtinCommandProxyFor: aCommandString input: in output: out error: err [
	"Answer a PipeableEvaluator on a built in command, or nil."

	"CommandShell new initialize builtinCommandProxyFor: 'help' input: nil output: nil error: nil"

	| args command commandAndArgs |
	^ (self isBuiltInCommand: aCommandString)
		ifTrue:
			[commandAndArgs := self shellSyntax
									programNameAndArgumentsFrom: aCommandString
									inDirectoryPath: nil
									findExecutable: false.
			command := self builtinCommands at: commandAndArgs first.
			args := commandAndArgs last.
			^ ShellBuiltinEvaluator
				command: command
				withArguments: args
				shell: self
				pipeFrom: in
				pipeTo: out
				errorPipelineStream: err]
		ifFalse: [nil]

]

{ #category : #accessing }
CommandShell >> builtinCommands [

	^ builtinCommands ifNil: [builtinCommands := Dictionary new]
]

{ #category : #accessing }
CommandShell >> builtinCommands: aCommandDictionary [

	builtinCommands := aCommandDictionary
]

{ #category : #testing }
CommandShell >> canAccessOSProcess [
	"True if OSProcess is in the image and if the OSProcess plugin is functioning properly"

	"CommandShell new canAccessOSProcess"

	| osp |
	^ (osp := Smalltalk at: #OSProcess ifAbsent: []) notNil and: [osp accessor canAccessSystem]

]

{ #category : #accessing }
CommandShell >> characterLimit [
	"Tell the views how much to retain on screen"
	^ 20000
]

{ #category : #'input character filtering' }
CommandShell >> checkSttyFor: characterValue [
	"Check for interrupt characters and such. Consume interrupt character and
	answer nil, otherwise answer characterValue."

	(self isInterrupt: characterValue)
		ifTrue:
			[self changed: #interruptCharacter.
			^ nil].
	(self isEndOfFile: characterValue)
		ifTrue:
			[self doEndOfFile.
			^ nil].
	^ characterValue
]

{ #category : #'initialize-release' }
CommandShell >> clearSemaphore [

	[self readSyncSemaphore isEmpty] whileFalse: [readSyncSemaphore terminateProcess].
	readSyncSemaphore signal

]

{ #category : #evaluation }
CommandShell >> command: aCommandString [
	"Evaluate aCommandString. Answer a collection of evaluated pipelines,
	or nil if nothing was done."

	"CommandShell new command: 'ls -l | cat'"
	"CommandShell new open; command: 'ls -l | cat'"
	"CommandShell new open; command: 'who'"
	"CommandShell new open; command: 'who&'"
	"CommandShell new open; command: 'sol'"
	"CommandShell new command: 'sol'"

	^self command: aCommandString echo: true

]

{ #category : #evaluation }
CommandShell >> command: aCommandString echo: showCommand [
	"Evaluate aCommandString. Answer a collection of evaluated pipelines,
	or nil if nothing was done. If showCommand is true, update dependent
	views in order to display the command."

	showCommand ifTrue: [self changed: aCommandString].
	^ self evaluatePipelines: (self evaluateOrMakePipelinesFrom: aCommandString)

]

{ #category : #'command scripting' }
CommandShell >> command: aCommandString onFailureDo: aBlockWithZeroOrOneParameter [
	"Evaluate aCommandString. On failure, answer the result of evaluating
	aBlockWithOneParameter with the collection of evaluated pipelines as
	its parameter. Otherwise, answer a collection of evaluated pipelines or
	nil if nothing was done."

	"CommandShell new open;
		command: 'who'
		onFailureDo: [:p | 'the proxy pipeline collection which failed was ', p printString]"
	"CommandShell new open;
		command: 'ls NOSUCHFILE'
		onFailureDo: [:p | 'the proxy pipeline collection that failed was ', p printString]"
	"CommandShell new open;
		command: 'ls NOSUCHFILE'
		onFailureDo: ['the command failed']"

	| pipelines |
	pipelines := self command: aCommandString.
	(pipelines anySatisfy: [:p | p succeeded not])
		ifTrue:
			[(aBlockWithZeroOrOneParameter numArgs == 0)
				ifTrue: [^ aBlockWithZeroOrOneParameter value]
				ifFalse: [^ aBlockWithZeroOrOneParameter value: pipelines]]
		ifFalse: [^ pipelines]


]

{ #category : #accessing }
CommandShell >> commandHistory [
	"Automatically trim the history list, and answer the resulting list."

	| trimIncrement |
	trimIncrement := 1.	"Could be a larger number to copy the collection less often"
	commandHistory isNil
		ifTrue:
			[commandHistory := OrderedCollection new]
		ifFalse:
			[(commandHistory size > (self historyDepth * 2 + (trimIncrement * 2) - 2))
				ifTrue:
					[commandHistory := commandHistory
						copyFrom: (trimIncrement * 2 + 1) to: commandHistory size]].
	^ commandHistory
]

{ #category : #accessing }
CommandShell >> commandLineProcesses [
	"The Smalltalk processes associated with currently executing command lines. Keep
	track of them here so that they can be conveniently terminated if something gets
	out of whack and needs cleaning up."

	commandLineProcesses ifNil: [commandLineProcesses := OrderedCollection new].
	^ commandLineProcesses

]

{ #category : #accessing }
CommandShell >> commandLineProcesses: anObject [
	"Set the value of commandLineProcesses"

	commandLineProcesses := anObject
]

{ #category : #'event handling' }
CommandShell >> copyAllErrorFrom: aProxy [
	"An event driven data source may send this message to cause its available
	error stream characters to be processed."

	| s |
	self readSyncSemaphore critical:
		[s := aProxy errorUpToEnd.
		s isEmpty ifFalse:
			[[self errorStream nextPutAll: s]
				on: Error
				do: [:ex | ex retryUsing:
						["If the error pipe overflows we get an unhandled error,
						so wait a while and retry the write."
						(Delay forMilliseconds: self pollingDelayTime) wait.
						self errorStream nextPutAll: s]]]]

]

{ #category : #'event handling' }
CommandShell >> copyAllOutputFrom: aProxy [
	"An event driven data source may send this message to cause its available
	characters to be processed."

	| s |
	self readSyncSemaphore critical:
		[s := aProxy upToEnd.
		s isEmpty ifFalse:
			[[self outputStream nextPutAll: s]
				on: Error
				do: [:ex | ex retryUsing:
						["If the output pipe overflows we get an unhandled error,
						so wait a while and retry the write."
						(Delay forMilliseconds: self pollingDelayTime) wait.
						self outputStream nextPutAll: s]]]]

]

{ #category : #'event handling' }
CommandShell >> copyErrorToEofFrom: aProxy [
	"An event driven data source may send this message to cause its available
	error stream characters to be processed."

	| s |
	self readSyncSemaphore critical:
		[s := aProxy errorUpToEndOfFile.
		s isEmpty ifFalse:
			[[self errorStream nextPutAll: s]
				on: Error
				do: [:ex | ex retryUsing:
						["If the error pipe overflows we get an unhandled error,
						so wait a while and retry the write."
						(Delay forMilliseconds: self pollingDelayTime) wait.
						self errorStream nextPutAll: s]]]]

]

{ #category : #'event handling' }
CommandShell >> copyOutputToEofFrom: aProxy [
	"An event driven data source may send this message to cause its available
	characters to be processed."

	| s |
	self readSyncSemaphore critical:
		[s := aProxy upToEndOfFile.
		s isEmpty ifFalse:
			[[self outputStream nextPutAll: s]
				on: Error
				do: [:ex | ex retryUsing:
						["If the output pipe overflows we get an unhandled error,
						so wait a while and retry the write."
						(Delay forMilliseconds: self pollingDelayTime) wait.
						self outputStream nextPutAll: s]]]]

]

{ #category : #defaults }
CommandShell >> defaultBuiltinCommands [

	^ #(cd: clear: copyToError: copyToOutput: edit: snapshot: exit: fc: help: history: inspect: pwd: sls: sqsh: type:)

]

{ #category : #defaults }
CommandShell >> defaultPromptString [

	^ '$ '
]

{ #category : #defaults }
CommandShell >> defaultPromptStringTwo [

	^ '> '
]

{ #category : #'input character filtering' }
CommandShell >> doEndOfFile [
	"EOF character detected, close stdin to pipeline."

	| pipelineInput |
	(pipelineInput := self keyboardConnector)
		ifNotNil: [pipelineInput closeWriter]

]

{ #category : #'input character filtering' }
CommandShell >> doInterrupt [
	"Interrupt character detected, do interrupt stuff."

	| msgStrm children answer |
	children := self externalChildren collect: [:e | e processProxy].
	(children size > 0)
		ifTrue:
			[msgStrm := WriteStream on: String new.
			(children size > 1)
				ifTrue: [msgStrm nextPutAll: 'kill processes']
				ifFalse: [msgStrm nextPutAll: 'kill process'].
			children do: [:e | msgStrm nextPutAll: ' ', e pid printString, ' (', e programName, ')'].
			msgStrm nextPut: $?.
			self readSyncSemaphore critical:
				[self pauseStProcesses.
				answer := self confirm: msgStrm contents.
				self unpauseStProcesses.
				answer ifTrue:
					[children reverseDo: [:e | e sigkill].
					self terminateStProcesses]]]

]

{ #category : #'process proxy creation' }
CommandShell >> doItProxyFor: aCommandString input: in output: out error: err [
	"Answer a PipeableEvaluator on a doIt command, or nil."

	"CommandShell new doItProxyFor: '#thisIsADoIt ! ' input: nil output: nil error: nil"

	^ (self shellSyntax isDoItCommand: aCommandString)
		ifTrue: [self evaluationProxyFor: (self shellSyntax doItStringFrom: aCommandString)
					input: in
					output: out
					error: err]

]

{ #category : #'command history' }
CommandShell >> editCommand: aString [

	^ UIManager default
		request: 'edit command'
		initialAnswer: aString
]

{ #category : #'input character filtering' }
CommandShell >> endOfFileCharacterValue [
	"<ctl>-D"

	^ 4
]

{ #category : #accessing }
CommandShell >> environment [

	^ environment ifNil:
		[environment := (Smalltalk at: #OSProcess ifPresent:
			[:osp | osp thisOSProcess environment deepCopy]) ifNil: [Dictionary new]].

]

{ #category : #accessing }
CommandShell >> environment: anObject [
	"Set the value of environment"

	environment := anObject
]

{ #category : #accessing }
CommandShell >> errorStream [
	"Answer the value of errorStream"

	^ errorStream ifNil: [errorStream := WriteStream on: String new]
]

{ #category : #accessing }
CommandShell >> errorStream: anObject [
	"Set the value of errorStream"

	errorStream := anObject
]

{ #category : #'command line parsing' }
CommandShell >> evaluateOrMakePipelinesFrom: aCommandString [
	"Convert aCommandString into a structured collection of process proxies,
	possibly after evaluating aCommandString as Smalltalk."

	"CommandShell new evaluateOrMakePipelinesFrom: 'who | cat | wc; ps -aef | cat& pwd | cat'"
	"CommandShell new evaluateOrMakePipelinesFrom: 'Array new: 10' "

	| process |
	"Ignore trivial case of a single word starting with $#"
	(self isOneWordCommentString: aCommandString)
		ifTrue:
			[^ #()]
		ifFalse:
			[process := self tryEvaluatingAsSmalltalk: aCommandString.
			(process exitStatus == #success)
				ifTrue: "aCommandString was successfully evaluated as a Smalltalk expression"
					[self outputStream nextPutAll: process upToEnd.
					self errorStream nextPutAll: process errorUpToEnd.
					self saveInHistoryList: aCommandString.
					^ #()]
				ifFalse: "Treat aCommandString as a command pipeline"
					[^ self pipelineCollectionFrom: aCommandString]]

]

{ #category : #evaluation }
CommandShell >> evaluatePipeline: aPipeline [
	"Evaluate aPipeline with event handlers to process output and error data."

	"CommandShell new evaluatePipeline: 
			(CommandShell new
				pipelineCollectionFrom: 'ls NOSUCHFILE * | cat | dd | cat | wc; ps -aef | cat& pwd | cat') first"

	| index |
	self registerOutputEventsFor: aPipeline.
	self registerErrorEventsFor: aPipeline.
	aPipeline background
		ifTrue:
			[index := self registerBackgroundPipeline: aPipeline.
			self registerBackgroundCompletionEventsFor: aPipeline
				commandIndex: index.
			self backgroundProxies addAll: aPipeline.
			aPipeline value.
			"Print the index of the background process."
			self errorStream nextPutAll: '[', index asString, '] '.
			aPipeline last isExternalProcess ifTrue:
				[aPipeline last processProxy pid printOn: self errorStream].
			self errorStream cr; nextPut: Character lf]
		ifFalse:
			[self keyboardConnector: aPipeline pipeToInput.
			self registerForegroundCompletionEventsFor: aPipeline.
			self foregroundProxies addAll: aPipeline.
			aPipeline value].
	^ aPipeline

]

{ #category : #evaluation }
CommandShell >> evaluatePipelines: aPipelineCollection [
	"Evaluate the process proxies in aPipelineCollection, and process their output and error
	streams. Answer aPipelineCollection."

	| lastForegroundPipeline completionSemaphore |
	lastForegroundPipeline := nil.
	aPipelineCollection isEmpty ifFalse:
		[lastForegroundPipeline := aPipelineCollection reversed
			detect: [:p | p background not]
			ifNone: [].
		lastForegroundPipeline ifNotNil: [self registerPromptEventFor: lastForegroundPipeline].
		aPipelineCollection do: [:pipeline |
			completionSemaphore := Semaphore new.
			pipeline background
				ifTrue: [completionSemaphore signal "no wait"]
				ifFalse: [pipeline when: #complete send: #signal to: completionSemaphore].
			self evaluatePipeline: pipeline.
			completionSemaphore wait]].
	lastForegroundPipeline ifNil: [self notifyPrompt].
	self resetSafeToExitFlag.
	^ aPipelineCollection

]

{ #category : #'process proxy creation' }
CommandShell >> evaluationProxyFor: aCommandString input: in output: out error: err [
	"Answer a PipeableEvaluator on a doIt command, or nil."

	"CommandShell new evaluationProxyFor: 'Smalltalk' input: nil output: nil error: nil"
	"CommandShell new evaluationProxyFor: 'BOGUS' input: nil output: nil error: nil"

	| proxy |
	proxy := ExpressionEvaluator
				command: aCommandString
				pipeFrom: in
				pipeTo: out
				errorPipelineStream: err.
	^ proxy

]

{ #category : #'input character filtering' }
CommandShell >> filterAndForward: aCharacter [
	"Filter aCharacter, taking special action if needed. If a child process is active,
	forward aCharacter to the child and answer nil. Otherwise answer aCharacter."

	^ (self checkSttyFor: aCharacter asciiValue) ifNotNil:
		[keyboardConnector isNil
			ifTrue:
				[aCharacter]
			ifFalse:
				[keyboardConnector closed
					ifTrue:
						[aCharacter]
					ifFalse:
						[keyboardConnector nextPut: aCharacter; flush.
						nil]]]
]

{ #category : #'input character filtering' }
CommandShell >> filterAndForwardEvent: keyboardEvent [ 
	"Filter keyboardEvent, taking special action if needed. If a child process
	is active, forward keyboardEvent to the child and answer nil. Otherwise
	answer keyboardEvent."

	(keyboardConnector isNil or: [keyboardConnector closed])
		ifTrue: [^ keyboardEvent]
		ifFalse: [keyboardConnector
					nextPut: keyboardEvent keyValue asCharacter;
					flush.
			^ nil]
]

{ #category : #'event handling' }
CommandShell >> foregroundPipelineComplete: aPipeline [
	"This message is sent when aPipeline has completed evaluation.
	Ensure that the output and error event handlers have had a chance
	to completely empty the pipes prior to cleaning things up."

	self waitUntilPipesAreEmpty: aPipeline.
	aPipeline closePipes; release.
	self keyboardConnector: nil.
	[self foregroundProxies removeAll: aPipeline]
		on: Error
		do: ["exit command may cause the collection to be eliminated, hence an error"]

]

{ #category : #accessing }
CommandShell >> foregroundProxies [
	"All of my process proxies that are being evaluated in the foreground."

	^ foregroundProxies ifNil: [foregroundProxies := OrderedCollection new]

]

{ #category : #accessing }
CommandShell >> foregroundProxies: aCollection [
	"All of my process proxies that are being evaluated in the foreground."

	foregroundProxies := aCollection

]

{ #category : #'command history' }
CommandShell >> historyAt: anInteger [

	| bufferSize index |
	bufferSize := commandHistory size / 2.
	(anInteger > 0)
		ifTrue:
			[index := bufferSize + 1 - historyIndex + anInteger * 2]
		ifFalse:
			[index := bufferSize + anInteger * 2].
	((index > commandHistory size) | (index < 1))
		ifTrue: [^ '']
		ifFalse: [^ commandHistory at: index]

]

{ #category : #defaults }
CommandShell >> historyDepth [
	"Number of commands to retain in the command history list"

	^ 100
]

{ #category : #accessing }
CommandShell >> historyIndex [

	historyIndex ifNil: [historyIndex := 1].
	^ historyIndex

]

{ #category : #'working directory' }
CommandShell >> home [
	"Home directory. Use the environment variable, and set it in #initialize."

	^ self environment at: #HOME

]

{ #category : #'command scripting' }
CommandShell >> if: aCommandStringOrScript then: successBlock else: failureBlock [
	"Evaluate aCommandStringOrScript, then evaluate successBlock or failureBlock
	depending on the exit status of the command or script. The blocks may use
	either zero or one argument. If a single argument is used, the collection of
	evaluated pipelines is passed to the block as an argument."

	"CommandShell new open;
		if: 'who'
		then: ['the command succeeded']
		else: ['the command failed']"
	"CommandShell new
		if: 'who
			ls NOSUCHFILE
			pwd'
		then: ['the script succeeded']
		else: ['the script failed']"
	"CommandShell new
		if: 'who
			ls NOSUCHFILE
			pwd'
		then: [:p | 'the script succeeded ', p printString]
		else: [:p | 'the script failed ', p printString]"

	| pipelines |
	pipelines := self script: aCommandStringOrScript
		onFailureDo: [:p | (failureBlock numArgs == 0)
						ifTrue: [^ failureBlock value]
						ifFalse: [^ failureBlock value: p]].
	(successBlock numArgs == 0)
		ifTrue: [^ successBlock value]
		ifFalse: [^ successBlock value: pipelines]

]

{ #category : #'initialize-release' }
CommandShell >> initialize [

	self installCommands.
	self setHomeDirectory

]

{ #category : #'initialize-release' }
CommandShell >> installCommand: aShellBuiltin [

	self builtinCommands at: aShellBuiltin name put: aShellBuiltin
]

{ #category : #'initialize-release' }
CommandShell >> installCommands [

	self installCommands: self defaultBuiltinCommands

]

{ #category : #'initialize-release' }
CommandShell >> installCommands: aCommandArray [

	self builtinCommands: (ShellBuiltin commandDictionaryFor: self commands: aCommandArray)

]

{ #category : #'input character filtering' }
CommandShell >> interruptCharacterValue [
	"<ctl>-C"

	^ 3
]

{ #category : #defaults }
CommandShell >> invalidCommandMessage [

	^ 'invalid command', Character cr asString
]

{ #category : #testing }
CommandShell >> isBuiltInCommand: aCommandString [
	"Answer true if aCommandString can be evaluated as a built in command."

	"CommandShell new initialize isBuiltInCommand: 'help this should answer true'"
	"CommandShell new initialize isBuiltInCommand: 'this should answer false'"

	^ self builtinCommands includesKey: (aCommandString copyUpTo: Character space)
]

{ #category : #'input character filtering' }
CommandShell >> isEndOfFile: anInteger [

	^ anInteger == self endOfFileCharacterValue

]

{ #category : #testing }
CommandShell >> isExcludedFromHistory: commandString [
	"Answer true if commandString should not be remembered in the history list. The 'fc'
	and 'history' commands should be excluded."

	^ ('fc*' match: commandString)
		or: ['history*' match: commandString]
]

{ #category : #testing }
CommandShell >> isExternalProcess [
	"Answer true if the process which I represent is an external OSProcess. For protocol
	compatibility with PipeJunction."

	^ false
]

{ #category : #'input character filtering' }
CommandShell >> isInterrupt: anInteger [

	^ anInteger == self interruptCharacterValue

]

{ #category : #testing }
CommandShell >> isOneWordCommentString: aCommandString [
	"Answer true if aCommandString is one word beginning with $#, or if it is an empty string."

	"CommandShell new isOneWordCommentString: '#oneWordComment'"
	"CommandShell new isOneWordCommentString: ' #oneWordComment'"
	"CommandShell new isOneWordCommentString: ' #oneWordComment '"
	"CommandShell new isOneWordCommentString: '#three word comment'"
	"CommandShell new isOneWordCommentString: 'not a comment'"
	"CommandShell new isOneWordCommentString: 'notAComment'"
	"CommandShell new isOneWordCommentString: ''"

	| s |
	s := CommandShell withBlanksTrimmed: aCommandString.
	^ s isEmpty
		or: [(s first == self shellSyntax commentChar)
			and: [(Scanner new scanTokens: s) size == 1]]

]

{ #category : #accessing }
CommandShell >> keyboardConnector [
	"If nil, then my views should behave normally. If a WriteStream, then my
	views should attempt to forward all keyboard inputs to the WriteStream.
	This is to permit the keyboard to be connected to an externally executing
	process, then reconnected to its normal functions when the external process
	is complete."


	^ keyboardConnector
]

{ #category : #accessing }
CommandShell >> keyboardConnector: aWriteStreamOrNil [
	"If nil, then my views should behave normally. If a WriteStream, then my
	views should attempt to forward all keyboard inputs to the WriteStream.
	This is to permit the keyboard to be connected to an externally executing
	process, then reconnected to its normal functions when the external process
	is complete."

	keyboardConnector := aWriteStreamOrNil

]

{ #category : #'VM building' }
CommandShell >> makeVmIn: buildDirectoryPathName [
	"Rebuild the virtual machine and plugins in the buildDirectoryPathName
	directory. If the build is successful, save the image and restart using the
	new VM. This assumes that the currently executing VM is either located in,
	or linked to, the buildDirectoryPathName directory."

	"CommandShell makeVmIn: CommandShell defaultPathString, CommandShell pathSeparator, 'build'"

	self canAccessOSProcess
		ifFalse:
			[^ self notify: 'OSProcess not available or OSProcess plugin not functioning'].
	self if: 'cd ', buildDirectoryPathName
		then:
			[self if: 'make'
				then:
					[self script: 'echo make completed successfully, restarting VM; OSProcess quitAndRestart !']
				else:
					[self script: 'echo make failed']]
		else:
			[self script: 'echo cannot change directory to ', buildDirectoryPathName]

]

{ #category : #'command prompt' }
CommandShell >> notifyAlternatePrompt [
	"Display $PS2"

	self changed: #alternatePrompt
]

{ #category : #'command prompt' }
CommandShell >> notifyPrompt [
	"Display $PS1"

	self changed: #prompt
]

{ #category : #'command prompt' }
CommandShell >> notifyRestorePrompt [
	"Restore last prompt display"

	self changed: #restorePrompt
]

{ #category : #'initialize-release' }
CommandShell >> open [

	| tty |
	tty := CommandShellTranscript commandShell: self.
	tty open.
	^ tty


]

{ #category : #'initialize-release' }
CommandShell >> openLabel: aString [ 

	| tty |
	tty := CommandShellTranscript commandShell: self.
	tty openLabel: aString.
	^ tty


]

{ #category : #accessing }
CommandShell >> outputStream [
	"Answer the value of outputStream"

	^ outputStream ifNil: [outputStream := WriteStream on: String new]
]

{ #category : #accessing }
CommandShell >> outputStream: anObject [
	"Set the value of outputStream"

	outputStream := anObject
]

{ #category : #'process proxy creation' }
CommandShell >> pipeableProxyFor: aCommandString input: in output: out error: err predecessorProxy: lastProxy [
	"Answer a proxy for an external OS process, or for an internal builtin command,
	or for an evaluation string. The proxy is suitable for use in a command pipeline,
	possibly mixing internal and external commands."

	"(CommandShell new pipeableProxyFor: '#''this is a doIt'' ! ' input: nil output: nil error: nil predecessorProxy: nil) value upToEnd"
	"(CommandShell new pipeableProxyFor: 'help' input: nil output: nil error: nil predecessorProxy: nil) value upToEnd"
	"(CommandShell new pipeableProxyFor: 'cat /etc/hosts' input: nil output: nil error: nil predecessorProxy: nil) value upToEnd"

	| errorPipelineStream cmd |
	errorPipelineStream := lastProxy ifNotNil: [lastProxy errorPipeForNextProxy].
	^ (((self doItProxyFor: aCommandString						"try entire line as a Smalltalk expression"
			input: in
			output: out
			error: (err ifNil: [errorPipelineStream]))
		ifNil: [self builtinCommandProxyFor: aCommandString	"is it a shell builtin?"
				input: in
				output: out
				error: (err ifNil: [errorPipelineStream])])
			ifNil: [self processProxyFor: aCommandString			"then it must be an external command"
					input: in
					output: out
					error: err
					predecessorProxy: lastProxy])
				ifNil: [cmd := (aCommandString findTokens: ' ') first.		"otherwise create evaluator to print error message"
					self evaluationProxyFor: 'stderr nextPutAll: ''sqsh: ', cmd, ': command not found''; cr. self fail'
						input: in
						output: out
						error: err]

]

{ #category : #evaluation }
CommandShell >> pipeline: aCommand [
	"Find the individual commands in a command pipeline string, and execute them
	as a command pipeline. Answer a ProxyPipeline collection of processes in the pipeline."

	"(CommandShell new pipeline: 'ps | grep ps | wc') last output"
	"CommandShell new pipeline: 'ls NOSUCHFILE * | dd | cat'"

	| sema pipeline |
	sema := Semaphore new.
	pipeline := ProxyPipeline fromString: aCommand shell: self.
	pipeline when: #complete send: #signal to: sema.
	pipeline value.
	sema wait.
	^ pipeline

]

{ #category : #'command line parsing' }
CommandShell >> pipelineCollectionFrom: aCommandString [
	"Break aCommandString into individual pipeline command strings, and answer a
	collection of process proxy pipelines."

	"CommandShell new pipelineCollectionFrom: 'who | cat | wc; ps -aef | cat& pwd | cat'"

	| str pipelineCollection tokens strm cmd cmdWithTerm pipeline lastProxy |
	str := CommandShell withBlanksTrimmed: aCommandString.
	pipelineCollection := OrderedCollection new.
	(self shellSyntax isComment: str)
		ifFalse:
			[tokens := str findTokens: ';&' keep: ';&'.
			strm := ReadStream on: tokens.
			[strm atEnd]
				whileFalse:
					[cmd := CommandShell withBlanksTrimmed: strm next.
					(self shellSyntax isComment: cmd)
						ifFalse:
							[strm atEnd
								ifTrue:
									[((cmd size == 1) and: [((cmd at: 1) == $;) | ((cmd at: 1) == $&)])
										ifTrue:
											["Special case, user has entered ';<cr>' or '&<cr>'"
											cmd := cmdWithTerm := '']
										ifFalse:
											[cmdWithTerm := cmd]]
								ifFalse:
									[cmdWithTerm := cmd, strm peek].
							self saveInHistoryList: cmdWithTerm.
							(cmdWithTerm size > 0)
								ifTrue:
									[pipeline := ProxyPipeline fromString: cmd shell: self.
									pipeline background:
										(strm next = self shellSyntax noWaitToken).
									lastProxy := pipeline last.
									lastProxy ifNil:
										[self inform: 'cannot access system'.
										^ nil].
									lastProxy outputPipeForNextProxy
										ifNotNil:
											[lastProxy setNonBlockingOutput].
									pipelineCollection add: pipeline]]]].
	^ pipelineCollection

]

{ #category : #defaults }
CommandShell >> pollingDelayTime [
	"For various polling loops, number of milliseconds to delay"

	^ 50

]

{ #category : #evaluation }
CommandShell >> processCommand: aCommandString [
	"Evaluate aCommandString in a separate Smalltalk process. This permits the
	user interface to remain responsive."

	^self processCommand: aCommandString echo: true

]

{ #category : #evaluation }
CommandShell >> processCommand: aCommandString echo: showCommand [
	"Evaluate aCommandString in a separate Smalltalk process. This permits the
	user interface to remain responsive. If showCommand is true, update dependent
	views in order to display the command."

	self commandLineProcesses add:
		([self command: aCommandString echo: showCommand.
		self commandLineProcesses
				remove: Processor activeProcess
				ifAbsent: []] forkAt: Processor userBackgroundPriority)

]

{ #category : #accessing }
CommandShell >> processProxies [
	"All of my process proxies."

	^ self foregroundProxies, self backgroundProxies

]

{ #category : #'process proxy creation' }
CommandShell >> processProxyFor: aCommandString input: in output: out error: err predecessorProxy: lastProxy [
	"Answer a proxy for an external OS command process. Note that the sender is
	responsible for closing the input pipe. Under certain conditions, reading up to
	end on a proxy can deadlock the VM if the input pipe remains open."

	"CommandShell new processProxyFor: '/bin/sh' input: nil output: nil error: nil predecessorProxy: nil"

	| input newInputPipe errorPipelineStream p proxy |
	self canAccessOSProcess
		ifFalse:
			["Answer a doIt proxy with an error message. Call it this way to make sure that
			the error streams get wired up correctly"
			p := self pipeableProxyFor: 'String new: 0 ! '
					input: in
					output: out
					error: err
					predecessorProxy: lastProxy.
			p errorPipelineStream nextPutAll:
				'cannot access system to run ''', aCommandString, '''', Character cr asString.
			^ p].
	((in isNil or: [lastProxy isNil]) or: [in isPipe not])
		ifTrue:
			[input := in]
		ifFalse:
			["Input from a command pipeline"
			(in isKindOf: InternalPipe)
				ifTrue:
					["The input stream is not an external OS pipe. Need to create one,
					and move the contents of the in stream into the new OSPipe prior
					to starting the external OS process."
					newInputPipe := PipeJunction externalPipeClass blockingPipe.
					lastProxy replaceOutputStreamWith: newInputPipe writer.
					input := newInputPipe reader]
				ifFalse:
					[input := in reader]].
	errorPipelineStream := lastProxy ifNotNil: [lastProxy errorPipeForNextProxy].
	proxy := PipeableOSProcess
		commandNoEvaluate: aCommandString
		environment: self environment
		workingDir: self workingDirectory
		input: input
		output: out
		error: err
		errorPipelineStream: errorPipelineStream
		shellSyntax: self shellSyntax.
	(proxy isNil and: [newInputPipe notNil])
		ifTrue: [newInputPipe closeReader]. "replacement pipe will not be read, so close its output"
	^ proxy

]

{ #category : #accessing }
CommandShell >> promptString [
	"The primary command prompt string, equivalent to $PS1 in a Unix shell"

	^ promptString ifNil: [promptString := self defaultPromptString]

]

{ #category : #accessing }
CommandShell >> promptString: aString [
	"The primary command prompt string, equivalent to $PS1 in a Unix shell"

	promptString := aString

]

{ #category : #accessing }
CommandShell >> promptStringTwo [
	"The secondary command prompt string, equivalent to $PS2 in a Unix shell"

	^ promptStringTwo ifNil: [promptStringTwo := self defaultPromptStringTwo]

]

{ #category : #accessing }
CommandShell >> promptStringTwo: aString [
	"The secondary command prompt string, equivalent to $PS2 in a Unix shell"

	promptStringTwo := aString

]

{ #category : #'event handling' }
CommandShell >> promptWhenComplete: aPipeline [

	self waitUntilPipesAreEmpty: aPipeline.
	self notifyPrompt
]

{ #category : #accessing }
CommandShell >> readSyncSemaphore [
	"Used in MVC to pause the screen output when presenting a dialogue to the user"

	readSyncSemaphore ifNil: [readSyncSemaphore := Semaphore forMutualExclusion].
	^ readSyncSemaphore
]

{ #category : #accessing }
CommandShell >> readSyncSemaphore: aSemaphore [
	"Used in MVC to pause the screen output when presenting a dialogue to the user"

	readSyncSemaphore := aSemaphore
]

{ #category : #'process proxy creation' }
CommandShell >> redirectedPipeableProxyFor: aCommandString predecessorProxy: lastProxy [
	"Answer a proxy for an external OS process, or for an internal builtin command,
	or for an evaluation string. The proxy is suitable for use in a command pipeline,
	possibly mixing internal and external commands."

	"(CommandShell new redirectedPipeableProxyFor: '#''this is a doIt'' ! '
							predecessorProxy: nil) value upToEnd"
	"(CommandShell new redirectedPipeableProxyFor: 'help'
							predecessorProxy: nil) value upToEnd"
	"(CommandShell new redirectedPipeableProxyFor: 'cat /etc/hosts'
							predecessorProxy: nil) value upToEnd"

	| redirectedCommand nextProxy input |
	redirectedCommand := self shellSyntax
								redirectIOFor: aCommandString
								inDirectoryPath: self workingDirectory.
	lastProxy isNil
		ifTrue:
			[input := redirectedCommand at: 2]
		ifFalse:
			[(redirectedCommand at: 2) isNil
				ifTrue:
					[input := lastProxy outputPipeForNextProxy]
				ifFalse:
					[lastProxy replaceOutputStreamWith: nil.
					input := redirectedCommand at: 2]].
	nextProxy := self pipeableProxyFor: (redirectedCommand at: 1)
		input: input
		output: (redirectedCommand at: 3)
		error: (redirectedCommand at: 4)
		predecessorProxy: lastProxy.
	^ nextProxy handleRedirectedOutputOf: lastProxy

]

{ #category : #'event registration' }
CommandShell >> registerBackgroundCompletionEventsFor: aPipeline commandIndex: index [
	"When an event driven pipeline is complete, it will trigger #complete."

	aPipeline when: #complete
		send: #backgroundPipelineComplete:commandIndex:
		to: self
		withArguments: {aPipeline . index}


]

{ #category : #evaluation }
CommandShell >> registerBackgroundPipeline: aPipeline [
	"Register aPipeline and answer an index number identifier."

	| index |
	aPipeline background
		ifTrue:
			["Find available slot in registry, expanding if needed"
			index := self backgroundPipelines identityIndexOf: nil.
			(index > 0)
				ifTrue:
					[self backgroundPipelines at: index put: aPipeline.
					^ index]
				ifFalse:
					[self backgroundPipelines addLast: aPipeline.
					^ backgroundPipelines size]]
		ifFalse:
			[self error: 'expected a background pipeline']

]

{ #category : #'event registration' }
CommandShell >> registerErrorEventsFor: aPipeline [
	"When an event driven PipeJunction has error data available, it will
	trigger #errorDataReady."

	aPipeline when: #errorDataReady
		send: #copyAllErrorFrom:
		to: self
		with: aPipeline

]

{ #category : #'event registration' }
CommandShell >> registerForegroundCompletionEventsFor: aPipeline [
	"When an event driven pipeline is complete, it will trigger #complete."

	aPipeline when: #complete
		send: #foregroundPipelineComplete:
		to: self
		with: aPipeline

]

{ #category : #'event registration' }
CommandShell >> registerOutputEventsFor: aPipeline [
	"When an event driven PipeJunction has new data available, it will
	trigger #outputDataReady."

	aPipeline when: #outputDataReady
		send: #copyAllOutputFrom:
		to: self
		with: aPipeline

]

{ #category : #'event registration' }
CommandShell >> registerPromptEventFor: aPipeline [

	aPipeline when: #complete
		send: #promptWhenComplete:
		to: self
		with: aPipeline

]

{ #category : #'initialize-release' }
CommandShell >> release [

	self startUpInNewSession.
	^ super release
]

{ #category : #evaluation }
CommandShell >> resetSafeToExitFlag [
	"When all foreground and background proxies are complete, the safeToExit
	flag may be set to true. The flag is set false when a snaphot command is
	evaluated, and is checked by any command which would cause Squeak to
	exit. This prevents Squeak from automatically exiting when restarting the
	image."

	[[self foregroundProxies isEmpty not or: [self backgroundProxies isEmpty not]]
		whileTrue: [(Delay forMilliseconds: self pollingDelayTime * 2) wait].
	self safeToExit: true] forkAt: Processor userBackgroundPriority

]

{ #category : #accessing }
CommandShell >> safeToExit [
	"This is a guard variable to prevent the user from running a command line containing both
	a snapshot command and an exit command. This prevents the user from entering a command
	such as 'snapshot; exit' which would cause the image to immediately exit when next restarted."

	^ safeToExit ifNil: [safeToExit := true]

]

{ #category : #accessing }
CommandShell >> safeToExit: trueOrFalse [
	"This is a guard variable to prevent the user from running a command line containing both
	a snapshot command and an exit command. This prevents the user from entering a command
	such as 'snapshot; exit' which would cause the image to immediately exit when next restarted."

	safeToExit := trueOrFalse

]

{ #category : #'command history' }
CommandShell >> saveInHistoryList: aCommandString [

	((aCommandString size == 0) or: [self isExcludedFromHistory: aCommandString])
		ifFalse:
			[self commandHistory add: self historyIndex printString; add: aCommandString.
			historyIndex := historyIndex + 1]

]

{ #category : #'command support' }
CommandShell >> scheduleToEvaluate: aBlock [
	"Evaluate aBlock, typically to create a new scheduled window. Make it work in
	both Morphic and MVC. In Morphic, just evaluate aBlock, but in MVC, put it in
	a queue for evaluation within a control loop. This method may be sent from
	a process running independent of MVC controller scheduling.
	
	Newer Squeak images implement #addDeferredUIMessage in the current
	project, eliminating the need for an #isMorphic test. This mechanism is not
	available for older images or for Pharo."

	CommandShell isMorphic
		ifTrue: [WorldState addDeferredUIMessage: aBlock]
		ifFalse: [(Smalltalk at: #ScheduledControllers) activeController addDeferredUIMessage: aBlock]
]

{ #category : #'command scripting' }
CommandShell >> script: aScriptString [
	"A script is a String containing a list of commands separated by Character cr.
	Evaluate each command string in the array until a failure is encountered.
	Answer the last collection of pipelines to have been evaluated."

	"CommandShell new open; 
		script: 'who
				help
				ls -l NOSUCHFILE
				help'"

	^ self script: aScriptString onFailureDo: [:p | p]


]

{ #category : #'command scripting' }
CommandShell >> script: aScriptString onFailureDo: aBlockWithZeroOrOneParameter [
	"A script is a String containing a list of commands separated by Character cr.
	Evaluate each command in aScriptString until a failure is encountered.
	On failure, answer the result of evaluating aBlockWithOneParameter with
	the collection of evaluated pipelines as its parameter. Otherwise, answer the
	last collection of pipelines to have been evaluated."

	"CommandShell new open; 
		script: 'who
				help
				ls -l NOSUCHFILE
				help'
		onFailureDo: [:p | 'the pipeline collection that failed was ', p printString]"
	"CommandShell new open; 
		script: 'who
				help
				ls
				help'
		onFailureDo: [:p | 'the pipeline collection that failed was ', p printString]"
	"CommandShell new open; 
		script: 'who
				help
				ls -l NOSUCHFILE
				help'
		onFailureDo: ['the pipeline collection failed']"

	| commandStream pipelines |
	commandStream := ReadStream on:
						(aScriptString
							copyReplaceAll: Character lf asString
							with: Character cr asString).
	pipelines := nil.
	[commandStream atEnd]
		whileFalse:
			[pipelines := self
				command: commandStream nextLine
				onFailureDo:
					[:p | (aBlockWithZeroOrOneParameter numArgs == 0)
						ifTrue: [^ aBlockWithZeroOrOneParameter value]
						ifFalse: [^ aBlockWithZeroOrOneParameter value: p]]].
	^ pipelines


]

{ #category : #'command scripting' }
CommandShell >> scriptDoAll: aScriptString [
	"A script is a String containing a list of commands separated by Character cr.
	Evaluate each command in aScriptString. Ignore failures and force evaluation of
	all commands in the script. Answer the last pipeline collection to have been
	evaluated."

	"CommandShell new open; 
		scriptDoAll: 'who
				help
				ls -l NOSUCHFILE
				help'"

	| commandStream lastPipelineCollection |
	commandStream := ReadStream on:
						(aScriptString
							copyReplaceAll: Character lf asString
							with: Character cr asString).
	[commandStream atEnd]
		whileFalse:
			[lastPipelineCollection := self command: commandStream nextLine].
	^ lastPipelineCollection


]

{ #category : #'initialize-release' }
CommandShell >> setHomeDirectory [

	self environment.
	^ environment at: #HOME put: CommandShell defaultPathString

]

{ #category : #accessing }
CommandShell >> shellSyntax [
	"A pluggable instance of a command processing syntax"

	^ shellSyntax ifNil: [shellSyntax := ShellSyntax new]
]

{ #category : #accessing }
CommandShell >> shellSyntax: aSyntax [
	"A pluggable instance of a command processing syntax"

	shellSyntax := aSyntax
]

{ #category : #'command support' }
CommandShell >> splitPipelineCommands: aCommand [
	"Answer a list of the individual commands in a command pipeline string,
	delimited by the pipe character."

	^ self shellSyntax splitPipelineCommands: aCommand

]

{ #category : #'initialize-release' }
CommandShell >> startUpInNewSession [
	"Do this if the image has been restarted, in which case all external process
	references are invalid."

	self clearSemaphore.
	self terminateCommandLineProcesses.
	foregroundProxies := backgroundProxies := backgroundPipelines := nil.
	self keyboardConnector: nil

]

{ #category : #'initialize-release' }
CommandShell >> terminateCommandLineProcesses [

	(self commandLineProcesses reject: [:e | e == Processor activeProcess])
		do: [:p | p terminate].
	commandLineProcesses := nil

]

{ #category : #'command line parsing' }
CommandShell >> tryEvaluatingAsSmalltalk: aCommandString [
	"Attempt to treat aCommandString as a Smalltalk expression running in an
	evaluation process. Evaluate the proxy and set exit status to reflect failure
	on either the expression compilation or the runtime evaluation. Answer the
	process proxy."

	"CommandShell new tryEvaluatingAsSmalltalk: 'this expression should fail in the compiler'"
	"CommandShell new tryEvaluatingAsSmalltalk: '#this expressionShouldFailInRuntimeEvaluation'"
	"CommandShell new tryEvaluatingAsSmalltalk: '#thisIsAValidSymbolExpression'"
	"CommandShell new tryEvaluatingAsSmalltalk: 'Smalltalk'"
	"CommandShell new tryEvaluatingAsSmalltalk: '#oneWordCommentShouldFail'"

	| process |
	process := self evaluationProxyFor: aCommandString input: nil output: nil error: nil.
	process value.
	process closeErrorPipeline. "Last process in pipeline, so it can be closed."
	^ process
]

{ #category : #evaluation }
CommandShell >> unRegisterBackgroundPipeline: aPipeline at: index [

	(self backgroundPipelines at: index) == aPipeline
		ifTrue: [self backgroundPipelines at: index put: nil]
		ifFalse: [self error: 'inconsistent registry']

]

{ #category : #evaluation }
CommandShell >> waitForCommand: aCommandString [
	"Evaluate aCommandString in a separate Process, and signal completionSemaphore
	when complete. Answer a collection of evaluated pipelines, or nil if nothing was done."

	| sema pipelines lastPipeline |
	self changed: aCommandString.
	pipelines := self evaluateOrMakePipelinesFrom: aCommandString.
	pipelines isEmpty ifFalse:
		[lastPipeline := pipelines last.
		lastPipeline isComplete ifFalse:
			[sema := Semaphore new.
			lastPipeline when: #complete
				send: #signal
				to: sema.
			[self evaluatePipelines: pipelines] forkAt: Processor userBackgroundPriority.
			lastPipeline isComplete ifFalse: [sema wait].
			self waitUntilPipesAreEmpty: lastPipeline]].
	^ pipelines

]

{ #category : #'event handling' }
CommandShell >> waitUntilPipesAreEmpty: aPipeline [
	"Some other Smalltalk process may be updating the pipes, or we may be
	waiting for data in an external OS pipe to be read into the image. Wait
	for these to reach completion."

	[aPipeline pipesAreEmpty] whileFalse: [(Delay forMilliseconds: 100) wait]

]

{ #category : #'working directory' }
CommandShell >> workingDirectory [

	^ self shellSyntax workingDirectory
		ifNil:
			[shellSyntax workingDirectory: CommandShell defaultPathString; workingDirectory]
]

{ #category : #'working directory' }
CommandShell >> workingDirectory: aPathString [

	self shellSyntax workingDirectory: aPathString

]
