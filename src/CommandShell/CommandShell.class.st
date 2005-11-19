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
	#superclass : #WriteStream,
	#instVars : [
		'shellSyntax',
		'environment',
		'builtinCommands',
		'commandHistory',
		'historyIndex',
		'keyboardConnector',
		'allMyChildren',
		'activeController',
		'readSyncSemaphore',
		'commandLineProcesses',
		'stProcesses',
		'timeWasterProcess'
	],
	#category : #CommandShell
}

{ #category : #'instance creation' }
CommandShell class >> command: aCommandString [

	"CommandShell command: 'help'"

	^ self new openLabel: self defaultWindowName command: aCommandString

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

{ #category : #defaults }
CommandShell class >> defaultWindowName [

	^ 'Squeak Shell'
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
  in your world menu, just select "squeak shell" from the "open..." menu entry.
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
    As the command pipeline is created from the command line string, each process
    proxy sends a #value message to its predecessor cause it to be evaluated (internal
    process proxies) or to create and run its external program (external process proxies).
    The chain of process proxies is connected by pipes for the connected input and
    output streams, and has a single shared pipe to collect error streams from all
    the process proxies.
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

	Smalltalk addToStartUpList: self after: ImageSegment

]

{ #category : #'instance creation' }
CommandShell class >> new [

	^ (self on: (String new: 1000)) initialize
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

{ #category : #documentation }
CommandShell class >> overview [
	"A general overview"

	"CommandShell new pipeline: 'CommandShell overview! | edit'"

	| rs ws |
	rs _ ReadStream on: self htmlOverview.
	ws _ WriteStream on: String new.
	[rs atEnd]
		whileFalse:
			[ws nextPutAll: (rs upTo: $<).
			rs upTo: $>].
	^ ws contents

]

{ #category : #documentation }
CommandShell class >> raceConditions [

	"CommandShell new pipeline: 'CommandShell raceConditions! | edit'"

	^
'It may be possible to hang the Squeak VM in an IO race condition when doing certain command pipelines. These conditions have been largely (completely?) eliminated for Unix platforms through the use of nonblocking pipes in conjunction with polling processes on the Smalltalk side of the pipes. However, these notes are provided to describe possible deadlock scenarios.

Note that nonblocking OS pipes are not yet available on Windows. Command pipelines with external OS processes on Windows are not supported. Blocking on read or write to an OSPipe in Windows will definitely lock the VM.

The overall scenario is as follows: From a Squeak Shell, enter a command pipeline with an internal command proxy, piped to an external command proxy, piped to another internal command proxy. 

Two kinds of deadlock are possible. In both cases, deadlock occurs when the single-threaded Squeak VM is blocked on a read or write to an OS pipe, and the blocked condition can only be cleared by another process running in the blocked VM.

1) Block on write. The Squeak VM can block on a write to an OS pipe if the external process at the other end of the pipe does not keep up with reading it. One internal process proxy writes on an pipe to an external process proxy, and fills the pipe up to some capacity limit, after which the write blocks. The external proxy is writing its output to another internal process proxy in the command pipeline, which never executes because the VM is still blocked trying to write to the full pipe.

2) Block on read. The Squeak VM can block on a read from an OS pipe if the external process writing to the pipe never closes the pipe. The internal proxy will post a read on the output pipe from the external command. If the external command has exited, the read will return with a (possibly empty) string. However, if the external command either does not exit, or exits without Squeak being notified, the read on the output pipe will block indefinitely.

2a) In the case where the external command exits while the Squeak VM is blocked on a read, Squeak is unable to respond to the notification of the external process exiting. The process stays in a zombie state, the pipes therefore never get closed, and the VM stays in a blocked condition.

Here are things to try if a deadlock occurs:

Squeak will be blocked and will not respond to the mouse or keyboard. Open a command shell outside of Squeak (perhaps an xterm, or log in to another virtual terminal on Linux or FreeBSD). Using the "ps" command, find the Squeak VM process and its subprocesses. Kill the subprocess. In many cases this will free up the deadlock, and Squeak will come back to life. If this does not work, then you will probably find that one of the processes which you just killed is now in a "zombie" state, which means that the Squeak VM is deadlocked in such a way that it cannot recognize that its child process exited (and therefore cannot properly close the associated file handles). In this case, if your operating system supports a /proc file system, you may be able to break things free by emptying the pipes. On Linux, go to /proc/<pidOfTheSqueakVMProcess>/fd/ and do "cat" commands on all the pipe files in this directory. If none of this works, you are just plain stuck, and you will need to kill your Squeak session and recover anything valuable from the changes log.

Notes:
In the current implemention, the following command line will deadlock the VM.
$ who | copyToOutput | copyToOutput | copyToOutput | cat | copyToOutput | copyToOutput

The condition can be resolved by killing the "cat" command from outside of Squeak. The deadlock occurs because the "copyToOutput" command are shell builtins which have delays built into a loop of execution. The delays prevent another deadlock condition (overflowing the output pipe, resulting in a block on write deadlock). However, the delays also permit the "cat" command to complete execution prior to the preceding "copyToOutput" commands. The "copyToOutput" command after the "cat" will block on read, and the preceding "copyToOutput" commands are prevented from completing. The input to "cat" is never closed, so "cat" continues executing, and the Squeak VM stays blocked on a read indefinitely.

Race conditions which are now prevented in this implementation:
Fixed one race condition as follows:
  "$ ls -lR / | copyToOutput | cat"

This formerly resulted in the following race condition:
  1) The "ls -lR" external process generates a large output string.
  2) The "copyToOutput" internal doIt command pipes the large output string to an external "cat" command, and blocks on the write when the OS pipe is full.
  3) The output of "cat" should be read by a Smalltalk process associated with a CommandShell, but...
  4) The output of "cat" is not read, because we are still blocking on the write to the input of "cat".
  5) ==> deadlock

The CommandShell>>copyToOutput:input:output:error method (one of the shell builtin commands) now prevents this race condition by explicitly forcing updates of "OSProcess thisOSProcess updateActiveChildren".

However, this still permitted the race condition to occur when interrupting the command line with a <ctl>C. Interrupt character processing now prevents this race condition by pausing all background processes in CommandShell>>doInterrupt.
'
]

{ #category : #'system startup' }
CommandShell class >> startUp [
	"A CommandShell may be running external processes in background, and waiting
	for those processes to complete. If the Squeak image is stopped and restarted, the
	background processes are no longer children of the Squeak process, and there is
	no way to receive notification when the processes exit. This would result in leftover
	Smalltalk processes associated with the CommandShell waiting forever for the
	external processes to exit. The simplest way to prevent this is to terminate all
	the Smalltalk processes unconditionally after an image restart."

	self allInstances do: [:e | e terminateStProcesses]

]

{ #category : #'version testing' }
CommandShell class >> versionString [

	"CommandShell versionString"

	^'3.0.3'
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

	activeController _ aController
]

{ #category : #accessing }
CommandShell >> allMyChildren [

	allMyChildren ifNil: [allMyChildren _ OrderedCollection new].
	^ allMyChildren
]

{ #category : #'command processing' }
CommandShell >> background: aProxy [
	"Run aProxy, and write output and error without waiting for command completion.
	Restore the command prompt if background process has written anything."

	| sema hist |
	sema _ Semaphore new.
	hist _ (self historyIndex - 1) printString.
	self nextPutAll: '[', hist, '] '.
	(aProxy respondsTo: #pid)
		ifTrue:
			[aProxy pid printOn: self.
			self nextPut: Character space].
	self cr.
	self stProcesses add:
		([self runProxy: aProxy signaling: sema.
		self stProcesses
				remove: Processor activeProcess
				ifAbsent: []] forkAt: Processor userBackgroundPriority).
	self stProcesses add:
		[sema wait.
		self nextPutAll: '[', hist, ']+ Done '.
		(aProxy respondsTo: #programName)
			ifTrue: [self nextPutAll: '			',
						(FileDirectory default localNameFor: aProxy programName),
						' '].
		self cr.
		self restorePrompt.
		self stProcesses
			remove: Processor activeProcess
			ifAbsent: []] fork.
	^ aProxy

]

{ #category : #'stream extensions' }
CommandShell >> bs [
	self position > 0 ifTrue: [^ self skip: -1].
	self changed: #bs
]

{ #category : #'process proxy creation' }
CommandShell >> builtinCommandProxyFor: aCommandString input: inputStream output: outputStream error: errorStream [
	"Answer a PipeableEvaluator on a built in command, or nil."

	"CommandShell new initialize builtinCommandProxyFor: 'help' input: nil output: nil error: nil"

	| tokens args c commandBlock proxy |
	^ (self isBuiltInCommand: aCommandString)
		ifTrue:
			[tokens _ aCommandString findTokens: ' '.
			tokens size == 0 ifTrue: [self error: 'expected one or more tokens'].
			args _ (tokens copyFrom: 2 to: tokens size) asArray.
			c _ self builtinCommands at: tokens first.
			"The command proxy will pass arguments to commandBlock at runtime"
			commandBlock _
				[:input :output :error :arguments |
				c class perform: c procedureSelector
					withArguments: (Array
						with: self
						with: input
						with: output
						with: error
						with: arguments)].
			proxy _ (self expressionEvaluatorClass
							block: commandBlock
							pipeFrom: inputStream
							pipeTo: outputStream
							errorPipelineStream: errorStream
							withArgs: args).
			proxy needsPrompt: c needsPrompt.
			^ proxy]
		ifFalse: [nil]

]

{ #category : #accessing }
CommandShell >> builtinCommands [

	^ builtinCommands ifNil: [builtinCommands _ Dictionary new]
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
			[self doInterrupt.
			^ nil].
	(self isEndOfFile: characterValue)
		ifTrue:
			[self doEndOfFile.
			^ nil].
	^ characterValue
]

{ #category : #'stream extensions' }
CommandShell >> clear [
	"Clear all characters and redisplay the view"
	self changed: #clearText.
	self reset
]

{ #category : #'initialize-release' }
CommandShell >> clearSemaphore [

	[self readSyncSemaphore isEmpty] whileFalse: [readSyncSemaphore terminateProcess].
	readSyncSemaphore signal

]

{ #category : #'model protocol' }
CommandShell >> codePaneMenu: aMenu shifted: shifted [
	"Note that unless we override perform:orSendTo:, PluggableTextController will respond
	to all menu items"

	^ StringHolder basicNew codePaneMenu: aMenu shifted: shifted

]

{ #category : #'command scripting' }
CommandShell >> command: aCommandString [
	"Evaluate aCommandString. This is similar to #doCommandsInString, except
	that the evaluation is done in the current process. When all processing is
	complete, answer the last process proxy in the command pipeline, or nil if
	nothing was done."

	"CommandShell new command: 'ls -l | cat'"
	"CommandShell new open; command: 'ls -l | cat'"
	"CommandShell new open; command: 'who'"

	| lastProcess |
	(self isOneWordCommentString: aCommandString)
		ifTrue: "Ignore trivial case of a single word starting with $#"
			[self cr; prompt; flush.
			[^ nil]]
		ifFalse:
			[self show: aCommandString.
			lastProcess _ self tryEvaluatingAsSmalltalk: aCommandString.
			(lastProcess exitStatus == #success)
				ifTrue: "aCommandString was successfully evaluated as a Smalltalk expression"
					[self saveInHistoryList: aCommandString.
					self cr.
					self processOutput: lastProcess count: nil.
					self processError: lastProcess count: nil.
					self prompt; flush]
				ifFalse: "Treat aCommandString as a command pipeline"
					[lastProcess _ self doCommandsInString: aCommandString
									ifTrue: [self prompt; flush]]].
	^ lastProcess

]

{ #category : #'command scripting' }
CommandShell >> command: aCommandString onFailureDo: aBlockWithOneParameter [
	"Evaluate aCommandString. On failure, answer the result of evaluating
	aBlockWithOneParameter with the last proxy to have been evaluated as
	its parameter. Otherwise, answer the last process proxy to have been
	evaluated."

	"CommandShell new open;
		command: 'who'
		onFailureDo: [:p | 'the proxy which failed was ', p printString]"

	"CommandShell new open;
		command: 'ls NOSUCHFILE'
		onFailureDo: [:p | 'the proxy which failed was ', p printString]"

	| lastProxy |
	lastProxy _ self command: aCommandString.
	lastProxy succeeded ifFalse: [^ aBlockWithOneParameter value: lastProxy].
	^ lastProxy


]

{ #category : #accessing }
CommandShell >> commandHistory [
	"Automatically trim the history list, and answer the resulting list."

	| trimIncrement |
	trimIncrement _ 1.	"Could be a larger number to copy the collection less often"
	commandHistory isNil
		ifTrue:
			[commandHistory _ OrderedCollection new]
		ifFalse:
			[(commandHistory size > (self historyDepth * 2 + (trimIncrement * 2) - 2))
				ifTrue:
					[commandHistory _ commandHistory
						copyFrom: (trimIncrement * 2 + 1) to: commandHistory size]].
	^ commandHistory
]

{ #category : #accessing }
CommandShell >> commandLineProcesses [
	"The Smalltalk processes associated with currently executing command lines. Keep
	track of them here so that they can be conveniently terminated if something gets
	out of whack and needs cleaning up."

	commandLineProcesses ifNil: [commandLineProcesses _ Set new].
	^ commandLineProcesses

]

{ #category : #defaults }
CommandShell >> commandProcessorClass [
	"Proxy for external command processing"

	^ PipeableOSProcess

]

{ #category : #defaults }
CommandShell >> commentChar [

	^ $#
]

{ #category : #'command support' }
CommandShell >> dirEntryString: aDirectoryEntry [
	"Code lifted from Lex Spoon's FileList>>fileNameFormattedFrom:sizePad:"

	"CommandShell new dirEntryString: FileDirectory default entries first"

	| folderString nameStr dateStr sizeStr |
	folderString _ ' [...]'.
	nameStr _ (aDirectoryEntry at: 4)
		ifTrue: [aDirectoryEntry first , folderString]
		ifFalse: [aDirectoryEntry first].
	dateStr _ ((Date fromSeconds: (aDirectoryEntry at: 3) )
					printFormat: #(3 2 1 $. 1 1 2)) , ' ' ,
				(String streamContents: [:s |
					(Time fromSeconds: (aDirectoryEntry at: 3) \\ 86400)
						print24: true on: s]).
	sizeStr _ (aDirectoryEntry at: 5) asStringWithCommas.
	^ nameStr , '    (' , dateStr , ' ' , sizeStr , ')'

]

{ #category : #'command processing' }
CommandShell >> doCommandsInString: aCommandString [
	"Process all the commands in aCommandString and issue a new command
	prompt based on the result of the evaluation. All of the processing runs in
	a separate Smalltalk process to prevent blocking the user interface. In MVC,
	schedule the prompt to be displayed during the control loop of aController.
	Keep track of the forked process in while it is running."

	| process |
	(self isOneWordCommentString: aCommandString)
		ifTrue: "Ignore trivial case of a single word starting with $#"
			[self cr; prompt; flush]
		ifFalse:
			[process _ self tryEvaluatingAsSmalltalk: aCommandString.
			(process exitStatus == #success)
				ifTrue: "aCommandString was successfully evaluated as a Smalltalk expression"
					[self saveInHistoryList: aCommandString.
					self cr.
					self processOutput: process count: nil.
					self processError: process count: nil.
					self prompt; flush]
				ifFalse: "Treat aCommandString as a command pipeline"
					[process _
						[self doCommandsInString: aCommandString ifTrue: [self prompt; flush].
						self commandLineProcesses
								remove: Processor activeProcess
								ifAbsent: []] fixTemps fork.
			self commandLineProcesses add: process]]

]

{ #category : #'command processing' }
CommandShell >> doCommandsInString: aCommandString ifTrue: aBlock [
	"Process all the commands in aCommandString, then conditionally evaluate aBlock.
	Answer the last proxy in the pipeline of process proxies."

	| str tokens strm cmd cmdWithTerm detach proxies childSemaphore doIt lastProxy |
	str _ aCommandString withBlanksTrimmed.
	doIt _ false.
	self cr; flush.
	(self shellSyntax isComment: str)
		ifTrue:
			[doIt _ true]
		ifFalse:
			[tokens _ str findTokens: ';&' keep: ';&'.
			strm _ ReadStream on: tokens.
			[strm atEnd]
				whileFalse:
					[cmd _ strm next withBlanksTrimmed.
					(self shellSyntax isComment: cmd)
						ifFalse:
							[strm atEnd
								ifTrue:
									[((cmd size == 1) and: [((cmd at: 1) == $;) | ((cmd at: 1) == $&)])
										ifTrue:
											["Special case, user has entered ';<cr>' or '&<cr>'"
											cmd _ cmdWithTerm _ '']
										ifFalse:
											[cmdWithTerm _ cmd]]
								ifFalse:
									[cmdWithTerm _ cmd, strm peek].
							self saveInHistoryList: cmdWithTerm.
							(cmdWithTerm size > 0)
								ifTrue:
									[detach _ (strm next = self noWaitToken).
									proxies _ self pipeline: cmd.
									lastProxy _ proxies last.
									lastProxy isNil
										ifTrue:
											[self show: 'cannot access system'; cr.
											^ self].
									lastProxy outputPipeForNextProxy
										ifNotNil:
											[lastProxy setNonBlockingOutput].
									self allMyChildren addAll: proxies.
									detach
										ifTrue:
											[self background: lastProxy]
										ifFalse:
											[childSemaphore _ Semaphore new.
											"Connect stdin from keyboard to the external process."
											self keyboardConnector: proxies first pipeToInput.
											self foreground: lastProxy
												signaling: childSemaphore.
											childSemaphore wait.
											self keyboardConnector: nil].
									doIt _ lastProxy needsPrompt.
									lastProxy errorPipelineStream close.
									self allMyChildren removeAll: proxies]]]].
	doIt ifTrue: [aBlock value].
	^ lastProxy

]

{ #category : #'input character filtering' }
CommandShell >> doEndOfFile [
	"EOF character detected, close stdin to pipeline."

	| firstChild |
	firstChild _ self allMyChildren first.
	firstChild ifNotNil: [firstChild pipeToInput close]

]

{ #category : #'input character filtering' }
CommandShell >> doInterrupt [
	"Interrupt character detected, do interrupt stuff."

	| msgStrm children answer |
	children _ self externalChildren collect: [:e | e processProxy].
	(children size > 0)
		ifTrue:
			[msgStrm _ WriteStream on: String new.
			(children size > 1)
				ifTrue: [msgStrm nextPutAll: 'kill processes']
				ifFalse: [msgStrm nextPutAll: 'kill process'].
			children do: [:e | msgStrm nextPutAll: ' ', e pid printString, ' (', e programName, ')'].
			msgStrm nextPut: $?.
			self readSyncSemaphore critical:
				[self pauseStProcesses.
				answer _ self confirm: msgStrm contents.
				self unpauseStProcesses.
				answer ifTrue:
					[children reverseDo: [:e | e sigkill].
					self terminateStProcesses]]]

]

{ #category : #'process proxy creation' }
CommandShell >> doItProxyFor: aCommandString input: inputStream output: outputStream error: errorStream [
	"Answer a PipeableEvaluator on a doIt command, or nil."

	"CommandShell new doItProxyFor: '#thisIsADoIt ! ' input: nil output: nil error: nil"

	^ (self isDoItCommand: aCommandString)
		ifTrue: [self evaluationProxyFor: (self doItStringFrom: aCommandString)
					input: inputStream
					output: outputStream
					error: errorStream]

]

{ #category : #'command support' }
CommandShell >> doItStringFrom: aCommandString [
	"Answer a string which can be evaluated as Smalltalk doIt, or nil."

	"CommandShell new doItStringFrom: 'this should answer a string!'"
	"CommandShell new doItStringFrom: 'this should answer a string!   '"
	"CommandShell new doItStringFrom: 'this should answer nil'"

	| s |
	s _ aCommandString withoutTrailingBlanks.
	s last == $!
		ifTrue: [^ aCommandString copyUpToLast: $!]
		ifFalse: [^ nil]
]

{ #category : #'command history' }
CommandShell >> editCommand: aString [

	^ FillInTheBlank
		request: 'edit command'
		initialAnswer: aString
]

{ #category : #'stream extensions' }
CommandShell >> endEntry [
	"Display all the characters since the last endEntry, and reset the stream"
	self changed: #appendEntry.
	self reset
]

{ #category : #'input character filtering' }
CommandShell >> endOfFileCharacterValue [
	"<ctl>-D"

	^ 4
]

{ #category : #accessing }
CommandShell >> environment [

	environment ifNil:
		[(Smalltalk hasClassNamed: #OSProcess)
			ifTrue: [environment _ (Smalltalk at: #OSProcess) thisOSProcess environment deepCopy]].
	^ environment
]

{ #category : #'process proxy creation' }
CommandShell >> evaluationProxyFor: aCommandString input: inputStream output: outputStream error: errorStream [
	"Answer a PipeableEvaluator on a doIt command, or nil."

	"CommandShell new evaluationProxyFor: 'Smalltalk' input: nil output: nil error: nil"
	"CommandShell new evaluationProxyFor: 'BOGUS' input: nil output: nil error: nil"

	| proxy |
	proxy _ self expressionEvaluatorClass
							command: aCommandString
							pipeFrom: inputStream
							pipeTo: outputStream
							errorPipelineStream: errorStream.
	proxy needsPrompt: true.
	^ proxy

]

{ #category : #defaults }
CommandShell >> expressionEvaluatorClass [
	"Proxy for internal command processing"

	^ PipeableEvaluator

]

{ #category : #accessing }
CommandShell >> externalChildren [

	^ self allMyChildren select: [:p | p isExternalProcess]

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

{ #category : #'stream extensions' }
CommandShell >> flush [
	self endEntry
]

{ #category : #'command processing' }
CommandShell >> foreground: aProxy signaling: aSemaphore [
	"Evaluate aProxy, write output and error, and signal aSemaphore when
	complete. The semaphore can be used to determine when a new command
	line prompt may be issued."

	^ self runProxy: aProxy signaling: aSemaphore
]

{ #category : #'command history' }
CommandShell >> historyAt: anInteger [

	| bufferSize index |
	bufferSize _ commandHistory size / 2.
	(anInteger > 0)
		ifTrue:
			[index _ bufferSize + 1 - historyIndex + anInteger * 2]
		ifFalse:
			[index _ bufferSize + anInteger * 2].
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

	historyIndex ifNil: [historyIndex _ 1].
	^ historyIndex

]

{ #category : #'command support' }
CommandShell >> home [
	"Home directory. Could change this to use the environment."

	^ FileDirectory default pathName
]

{ #category : #'command scripting' }
CommandShell >> if: aCommandStringOrScript then: successBlock else: failureBlock [
	"Evaluate aCommandStringOrScript, then evaluate successBlock or failureBlock
	depending on the exit status of the command or script."

	"CommandShell new open;
		if: 'who'
		then: ['the command succeeded']
		else: ['the command failed']"

	"CommandShell new open;
		if: 'who
			ls NOSUCHFILE
			pwd'
		then: ['the script succeeded']
		else: ['the script failed']"

	(self script: aCommandStringOrScript) succeeded
		ifTrue: [^ successBlock value]
		ifFalse: [^ failureBlock value]



]

{ #category : #'initialize-release' }
CommandShell >> initialize [

	self installCommands

]

{ #category : #'initialize-release' }
CommandShell >> installCommand: aShellBuiltin [

	self builtinCommands at: aShellBuiltin name put: aShellBuiltin
]

{ #category : #'initialize-release' }
CommandShell >> installCommands [

	self installCommand: (ShellBuiltin cd: self).
	self installCommand: (ShellBuiltin clear: self).
	self installCommand: (ShellBuiltin copyToError: self).
	self installCommand: (ShellBuiltin copyToOutput: self).
	self installCommand: (ShellBuiltin edit: self).
	self installCommand: (ShellBuiltin exit: self).
	self installCommand: (ShellBuiltin fc: self).
	self installCommand: (ShellBuiltin help: self).
	self installCommand: (ShellBuiltin history: self).
	self installCommand: (ShellBuiltin inspect: self).
	self installCommand: (ShellBuiltin pwd: self).
	self installCommand: (ShellBuiltin sls: self).
	self installCommand: (ShellBuiltin sqsh: self).
	self installCommand: (ShellBuiltin type: self).

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

{ #category : #'command support' }
CommandShell >> isADirectory: aPathString [

	| fullPath localName entry |
	^ (('*', FileDirectory slash) match: aPathString) or:
		[fullPath _ FileDirectory default fullNameFor: aPathString.
		localName _ FileDirectory localNameFor: fullPath.
		entry _ (FileDirectory on: (FileDirectory dirPathFor: fullPath)) entries
			detect: [:e | e name = localName] ifNone: [nil].
		entry notNil and: [entry isDirectory]]

]

{ #category : #testing }
CommandShell >> isBuiltInCommand: aCommandString [
	"Answer true if aCommandString can be evaluated as a built in command."

	"CommandShell new initialize isBuiltInCommand: 'help this should answer true'"
	"CommandShell new initialize isBuiltInCommand: 'this should answer false'"

	^ self builtinCommands includesKey: (aCommandString upTo: Character space)
]

{ #category : #testing }
CommandShell >> isDoItCommand: aCommandString [
	"Answer true if aCommandString should be evaluated as Smalltalk doIt."

	"CommandShell new isDoItCommand: 'this should answer true!'"
	"CommandShell new isDoItCommand: 'this should answer true!   '"
	"CommandShell new isDoItCommand: 'this should answer false'"

	^ aCommandString withoutTrailingBlanks last == $!
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
CommandShell >> isExternalCommand: aCommandString [
	"Answer true if aCommandString should be evaluated as an external process."

	"CommandShell new isExternalCommand: 'help this should answer false'"
	"CommandShell new isExternalCommand: 'this should answer false!'"
	"CommandShell new isExternalCommand: 'echo ''this should answer true'''"

	^ ((self isBuiltInCommand: aCommandString) or: [self isDoItCommand: aCommandString]) not
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
	s _ aCommandString withBlanksTrimmed.
	^ s isEmpty
		or: [(s first == $#)
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

	keyboardConnector _ aWriteStreamOrNil

]

{ #category : #'model protocol' }
CommandShell >> labelString [

	| directoryString |
	directoryString _ self workingDirectory.
	directoryString isEmpty ifTrue: [directoryString _ self nullDirectoryString].
	^ self class defaultWindowName, ': ', directoryString

]

{ #category : #'command support' }
CommandShell >> newDirPath: aPath from: initialPath [
	"Answer a path string for a change directory command. Change from initialPath
	(usually the current working directory) to the new path, where aPath may be
	either an absolute path name (fully specified from the root) or a relative path
	name (relative to initialPath)."

	"CommandShell new cdTo: 'b?n' from: '/usr'"
	"CommandShell new cdTo: '..' from: '/usr/bin'"
	"CommandShell new cdTo: '.././bin' from: '/usr/bin'"
	"CommandShell new cdTo: '../../../../..' from: '/usr/bin'"
	"CommandShell new cdTo: '../../../../../usr' from: '/usr/bin'"

	^ (self shellSyntax
			expandedPathsFrom: aPath
			beginningAt: initialPath)
				at: 1
				ifAbsent: [nil]


]

{ #category : #defaults }
CommandShell >> noWaitToken [
	"This character at the end of a command string means execute as detached process."

	^ '&'
]

{ #category : #'command support' }
CommandShell >> nullDirectoryString [
	"String to display when the current directory is one level above the file system root."

	^ '[]'
]

{ #category : #'initialize-release' }
CommandShell >> open [

	^ self openLabel: self class defaultWindowName
]

{ #category : #'initialize-release' }
CommandShell >> openAsMorphLabel: labelString [ 
	"Build a morph viewing this stream"

	| window textMorph |
	window _ (SystemWindow labelled: labelString) model: self.
	textMorph _ ShellWindowMorph
					on: self
					text: nil
					accept: nil
					readSelection: nil
					menu: #codePaneMenu:shifted:.
	textMorph acceptOnCR: true.
	window addMorph: textMorph frame: (0@0 corner: 1@1).
	self prompt.
	self changed: #relabel.
	^ window
]

{ #category : #'initialize-release' }
CommandShell >> openLabel: aString [ 
	"Open a window on this stream. This is copied from the corresponding method in
	TranscriptStream."

	| topView codeView |
	Smalltalk isMorphic ifTrue: [^ (self openAsMorphLabel: aString) openInWorld].

	topView _ StandardSystemView new.
	topView model: self;
			controller: DeferredActionStandardSystemController new;
			borderWidth: 1;
			label: aString;
			minimumSize: 100 @ 50.
	codeView _ ShellWindowView
					on: self
					text: nil
					accept: nil
					readSelection: nil
					menu: #codePaneMenu:shifted:.
	codeView window: (0@0 extent: 200@200).
	topView addSubView: codeView.
	topView controller addDeferredUIMessage: [self changed: #relabel].
	topView controller open

]

{ #category : #'initialize-release' }
CommandShell >> openLabel: aString command: commandString [
	"Open a window on this stream. This is copied from the corresponding method in
	TranscriptStream."

	"CommandShell new openLabel: self defaultWindowName command: 'help'"

	| topView codeView m |
	Smalltalk isMorphic
		ifTrue:
			[m _ (self openAsMorphLabel: aString) openInWorld.
			m model command: commandString.
			^m].

	topView _ StandardSystemView new.
	topView model: self;
			controller: DeferredActionStandardSystemController new;
			borderWidth: 1;
			label: aString;
			minimumSize: 100 @ 50.
	codeView _ ShellWindowView
					on: self
					text: nil
					accept: nil
					readSelection: nil
					menu: #codePaneMenu:shifted:.
	codeView window: (0@0 extent: 200@200).
	topView addSubView: codeView.
	self activeController: topView controller.
	topView controller addDeferredUIMessage: [self changed: #relabel].
	topView controller addDeferredUIMessage: [self command: commandString] fixTemps.
	topView controller open

]

{ #category : #'stream extensions' }
CommandShell >> pastEndPut: anObject [
	"If the stream reaches its limit, just output the contents and reset."
	self endEntry.
	^ self nextPut: anObject
]

{ #category : #'input character filtering' }
CommandShell >> pauseStProcesses [
	"Prevent my Smalltalk processes from being scheduled."

	"Set all my stProcesses to a very low priority"
	(self stProcesses reject: [:e | e == Processor activeProcess])
		do: [:p | p priority: Processor systemBackgroundPriority].

	"Start a process at slightly higher priority to prevent the low priority processes
	from being scheduled. Ack! Pffft! What a hack."
	timeWasterProcess _ [ProcessorScheduler idleProcess] newProcess.
	timeWasterProcess priority: Processor userBackgroundPriority.
	timeWasterProcess resume

]

{ #category : #'model protocol' }
CommandShell >> perform: selector orSendTo: otherTarget [
	"Selector was just chosen from a menu by a user.  If can respond, then
	perform it on myself. If not, send it to otherTarget, presumably the
	editPane from which the menu was invoked."

	(self respondsTo: selector)
		ifTrue: [^ self perform: selector]
		ifFalse: [^ otherTarget perform: selector]
]

{ #category : #defaults }
CommandShell >> pipeCharToken [
	"The command pipeline character"

	^ '|'
]

{ #category : #'command processing' }
CommandShell >> pipeProxy: aCommandProxy toCommand: aCommand [
	"Find the individual commands in a command pipeline string, and execute
	them as a command pipeline with aCommandProxy as the first member of
	the pipeline of proxies. Answer a collection of processes in the pipeline."

	^ self pipeProxy: aCommandProxy toCommandList: (self splitPipelineCommands: aCommand)

]

{ #category : #'command processing' }
CommandShell >> pipeProxy: aCommandProxy toCommandList: anArrayOfCommandStrings [
	"Using the individual commands in a command pipeline string, execute them
	as a command pipeline. Each process proxy in the pipeline (except the last)
	runs in a separate Smalltalk process. In most cases, this has no impact on
	the behavior of the command pipeline; however, if one or more of the proxies
	is an internal PipeableEvaluator, this permits the internal proxy to explicitly
	yield the processor and avoid possible IO race conditions.
	Answer a collection of processes in the pipeline."

	| processes nextProxy |
	processes _ OrderedCollection new.
	processes add: aCommandProxy.
	anArrayOfCommandStrings
			inject: aCommandProxy
			into: [:prev :next | prev isNil ifFalse:
					[prev prepareOutputForPipe.
					nextProxy _ self redirectedPipeableProxyFor: next predecessorProxy: prev.
					processes add: nextProxy.
					self stProcesses add:
						[prev value.
						self stProcesses remove: Processor activeProcess ifAbsent: []] fixTemps fork.
					Processor yield.
					nextProxy]].
	processes last value.
	^ processes

]

{ #category : #'process proxy creation' }
CommandShell >> pipeableProxyFor: aCommandString input: inputStream output: outputStream error: errorStream predecessorProxy: lastProxy [
	"Answer a proxy for an external OS process, or for an internal builtin command,
	or for an evaluation string. The proxy is suitable for use in a command pipeline,
	possibly mixing internal and external commands."

	"(CommandShell new pipeableProxyFor: '#''this is a doIt'' ! ' input: nil output: nil error: nil predecessorProxy: nil) value upToEnd"
	"(CommandShell new pipeableProxyFor: 'help' input: nil output: nil error: nil predecessorProxy: nil) value upToEnd"
	"(CommandShell new pipeableProxyFor: 'cat /etc/hosts' input: nil output: nil error: nil predecessorProxy: nil) value upToEnd"

	| errorPipelineStream |
	errorPipelineStream _ lastProxy ifNotNil: [lastProxy errorPipelineStream].
	^ ((self doItProxyFor: aCommandString
			input: inputStream
			output: outputStream
			error: (errorStream ifNil: [errorPipelineStream]))
		ifNil: [self builtinCommandProxyFor: aCommandString
				input: inputStream
				output: outputStream
				error: (errorStream ifNil: [errorPipelineStream])])
			ifNil: [self processProxyFor: aCommandString
					input: inputStream
					output: outputStream
					error: errorStream
					predecessorProxy: lastProxy]

]

{ #category : #'command processing' }
CommandShell >> pipeline: aCommand [
	"Find the individual commands in a command pipeline string, and execute them
	as a command pipeline. Each process proxy in the pipeline (except the last)
	runs in a separate Smalltalk process. In most cases, this has no impact on
	the behavior of the command pipeline; however, if one or more of the proxies
	is an internal PipeableEvaluator, this permits the internal proxy to explicitly
	yield the processor and avoid possible IO race conditions.
	Answer a collection of processes in the pipeline."

	| commands firstProxy |
	commands _ self splitPipelineCommands: aCommand.
	firstProxy _ self redirectedPipeableProxyFor: commands first predecessorProxy: nil.
	^ self pipeProxy: firstProxy toCommandList: (commands copyAfter: commands first)

	"(CommandShell new pipeline: 'ps') last output"
	"(CommandShell new pipeline: 'ps | grep ps | wc') last output"

	"The following examples will only work in Morphic"
	"CommandShell new doCommandsInString: 'who | edit'"
	"CommandShell new doCommandsInString: 'who | wc | edit'"
	"CommandShell new doCommandsInString: 'who | cat | dd | cat | dd | edit'"
	"CommandShell new doCommandsInString: 'who | stdout nextPutAll: stdin upToEnd! | edit'"
	"CommandShell new doCommandsInString: 'help | edit'"
	"CommandShell new doCommandsInString: 'help | cat | edit'"
	"CommandShell new doCommandsInString: 'help | stdout nextPutAll: stdin upToEnd! | cat | edit'"
	"CommandShell new doCommandsInString: 'stdout nextPutAll: ''Hello world!'' ! | edit'"
	"CommandShell new doCommandsInString:
		'stdout nextPutAll: ''Hello world!'' ! | copyToOutput | edit'"
	"CommandShell new doCommandsInString: 'stdout nextPutAll: ''Hello world!'' ! | cat | edit'"
	"CommandShell new doCommandsInString:
		'stdout nextPutAll: ''Hello world!'' ! | cat | copyToOutput | dd | cat | edit'"
	"CommandShell new doCommandsInString: 'help > /tmp/delete.me | edit'"
	"CommandShell new doCommandsInString: 'help | cat < /etc/hosts | edit'"
	"CommandShell new doCommandsInString: 'cat < /etc/hosts | edit'"

]

{ #category : #'command support' }
CommandShell >> processError: aProxy count: num [
	"Process up to num error stream characters if available. If num is nil,
	process all available characters"

	| str |
	self readSyncSemaphore critical:
		[num isNil
			ifTrue: [str _ aProxy errorUpToEnd]
			ifFalse: [str _ aProxy nextFromError: num].
		(str notNil and: [str size > 0])
			ifTrue:
				[self show: (str replaceAll: Character lf with: Character cr); flush]]
]

{ #category : #'command support' }
CommandShell >> processOutput: aProxy count: num [
	"Process up to num output characters if available. If num is nil, process all
	available characters"

	| str |
	self readSyncSemaphore critical:
		[num isNil
			ifTrue: [str _ aProxy upToEnd]
			ifFalse: [str _ aProxy next: num].
		(str notNil and: [str size > 0])
			ifTrue:
				[self show: (str replaceAll: Character lf with: Character cr); flush]]
]

{ #category : #'process proxy creation' }
CommandShell >> processProxyFor: aCommandString input: inputStream output: outputStream error: errorStream predecessorProxy: lastProxy [
	"Answer a proxy for an external OS command process."

	"CommandShell new processProxyFor: '/bin/sh' input: nil output: nil error: nil predecessorProxy: nil"

	| input newInputPipe errorPipelineStream p |
	((Smalltalk hasClassNamed: #OSProcess) and: [(Smalltalk at: #OSProcess) accessor canAccessSystem])
		ifFalse:
			["Answer a doIt proxy with an error message. Call it this way to make sure that
			the error streams get wired up correctly"
			p _ self pipeableProxyFor: 'String new: 0 ! '
					input: inputStream
					output: outputStream
					error: errorStream
					predecessorProxy: lastProxy.
			p errorPipelineStream nextPutAll:
				'cannot access system to run ''', aCommandString, '''', Character cr asString.
			^ p].
	((inputStream isNil or: [lastProxy isNil]) or: [inputStream isKindOf: FileStream])
		ifTrue:
			[input _ inputStream]
		ifFalse:
			["Input from a command pipeline"
			((Smalltalk hasClassNamed: #OSPipe) and: [inputStream isKindOf: (Smalltalk at: #OSPipe)])
				ifTrue:
					[input _ inputStream reader]
				ifFalse:
					["The inputStream is not an OS pipe. Need to create one, and move
					the contents of inputStream into the new OSPipe prior to starting
					the external OS process."
					(Smalltalk hasClassNamed: #OSPipe)
						ifTrue:
							[newInputPipe _ (Smalltalk at: #OSPipe) blockingPipe.
							lastProxy replaceOutputStreamWith: newInputPipe writer.
							input _ newInputPipe reader]
						ifFalse:
							[input _ nil]]].
	"If the input stream is nil, provide an OSPipe and close the writer end. If this is not
	done, the default behavior will be to provide an OSPipe with the input still open,
	which could lead to the external command waiting indefinitely for input."
	input ifNil:
		[(Smalltalk hasClassNamed: #OSPipe)
			ifTrue:
				[newInputPipe _ (Smalltalk at: #OSPipe) blockingPipe.
				newInputPipe writer close.
				input _ newInputPipe reader]
			ifFalse:
				[input _ nil]].
	errorPipelineStream _ lastProxy ifNotNil: [lastProxy errorPipelineStream].
	^ self commandProcessorClass
		commandNoEvaluate: aCommandString
		environment: self environment
		workingDir: self workingDirectory
		input: input
		output: outputStream
		error: errorStream
		errorPipelineStream: errorPipelineStream
		shellSyntax: self shellSyntax

]

{ #category : #'command support' }
CommandShell >> prompt [

	self show: self promptString; restoreSelectionMarker
]

{ #category : #defaults }
CommandShell >> promptString [

	^ '$ '
]

{ #category : #accessing }
CommandShell >> readSyncSemaphore [
	"Used in MVC to pause the screen output when presenting a dialogue to the user"

	readSyncSemaphore ifNil: [readSyncSemaphore _ Semaphore forMutualExclusion].
	^ readSyncSemaphore
]

{ #category : #accessing }
CommandShell >> readSyncSemaphore: aSemaphore [
	"Used in MVC to pause the screen output when presenting a dialogue to the user"

	readSyncSemaphore _ aSemaphore
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
	redirectedCommand _ self shellSyntax
								redirectIOFor: aCommandString
								inDirectoryPath: self workingDirectory.
	lastProxy isNil
		ifTrue:
			[input _ redirectedCommand at: 2]
		ifFalse:
			[(redirectedCommand at: 2) isNil
				ifTrue:
					[input _ lastProxy outputPipeForNextProxy]
				ifFalse:
					[lastProxy replaceOutputStreamWith: nil.
					input _ redirectedCommand at: 2]].
	nextProxy _ self pipeableProxyFor: (redirectedCommand at: 1)
		input: input
		output: (redirectedCommand at: 3)
		error: (redirectedCommand at: 4)
		predecessorProxy: lastProxy.
	^ nextProxy

]

{ #category : #'initialize-release' }
CommandShell >> release [

	self terminateStProcesses.
	self terminateCommandLineProcesses.
	self clearSemaphore.
	^ super release
]

{ #category : #'command support' }
CommandShell >> restorePrompt [
	"May be called following completion of a background process which might have written
	output beyond the current prompt position. Should restore user edited text beyond the
	command prompt, but for now simply reissue the prompt and let the user figure out
	what to do about it."

	^ self prompt
]

{ #category : #'command support' }
CommandShell >> restoreSelectionMarker [
	"Restore selection marker in MVC"

	| c |
	Smalltalk isMorphic
		ifFalse:
			[c _ self activeController.
			self scheduleToEvaluate: [c initializeSelection] fixTemps]

]

{ #category : #'command processing' }
CommandShell >> runProxy: aProxy signaling: aSemaphore [
	"Run aProxy, updating the output and error streams, and signaling aSemaphore
	when complete."

	| loopDelay chunkSize proj mvc |
	"These values for loopDelay and chunkSize provide reasonable performance."
	loopDelay _ Delay forMilliseconds: 100.
	chunkSize _ 1920.
	proj _ Project current.
	mvc _ proj world isKindOf: ControlManager.
	[aProxy isComplete]
		whileFalse:
			["In MVC, pause the output if user switches to another project. If this
			is not done, the view will be repainted right on top of the Morphic world."
			mvc ifTrue:
				[[proj == Project current] whileFalse: [(Delay forSeconds: 1) wait]].
			loopDelay wait.
			self processOutput: aProxy count: chunkSize.
			self processError: aProxy count: chunkSize].
	self processOutput: aProxy count: nil.
	self processError: aProxy count: nil.
	aSemaphore ifNotNil: [aSemaphore signal].
	 ^ aProxy
]

{ #category : #'command history' }
CommandShell >> saveInHistoryList: aCommandString [

	((aCommandString size == 0) or: [self isExcludedFromHistory: aCommandString])
		ifFalse:
			[self commandHistory add: self historyIndex printString; add: aCommandString.
			historyIndex _ historyIndex + 1]

]

{ #category : #'command support' }
CommandShell >> scheduleToEvaluate: aBlock [
	"Evaluate aBlock, typically to create a new scheduled window. Make it work in
	both Morphic and MVC. In Morphic, just evaluate aBlock, but in MVC, put it in
	a queue for evaluation within a control loop. This method may be sent from
	a process running independent of MVC controller scheduling."

	Smalltalk isMorphic
		ifTrue: [WorldState addDeferredUIMessage: aBlock]
		ifFalse: [self activeController ifNotNil: [activeController addDeferredUIMessage: aBlock]]
]

{ #category : #'command scripting' }
CommandShell >> script: aScriptString [
	"A script is a String containing a list of commands separated by Character cr.
	Evaluate each command string in the array until a failure is encountered.
	Answer the last process proxy to have been evaluated."

	"CommandShell new open; 
		script: 'who
				help
				ls -l NOSUCHFILE
				help'"

	^ self script: aScriptString onFailureDo: [:p | p]


]

{ #category : #'command scripting' }
CommandShell >> script: aScriptString onFailureDo: aBlockWithOneParameter [
	"A script is a String containing a list of commands separated by Character cr.
	Evaluate each command in aScriptString until a failure is encountered.
	On failure, answer the result of evaluating aBlockWithOneParameter with
	the last proxy to have been evaluated as its parameter. Otherwise, answer the
	last process proxy to have been evaluated."

	"CommandShell new open; 
		script: 'who
				help
				ls -l NOSUCHFILE
				help'
		onFailureDo: [:p | 'the proxy which failed was ', p printString]"

	| commandStream lastProxy |
	commandStream _ ReadStream on:
						(aScriptString
							copyReplaceAll: Character lf asString
							with: Character cr asString).
	[commandStream atEnd]
		whileFalse:
			[lastProxy _ self command: commandStream nextLine.
			(lastProxy notNil and: [lastProxy succeeded not])
				ifTrue:
					[^ aBlockWithOneParameter value: lastProxy]].
	^ lastProxy


]

{ #category : #'command scripting' }
CommandShell >> scriptDoAll: aScriptString [
	"A script is a String containing a list of commands separated by Character cr.
	Evaluate each command in aScriptString. Ignore failures and force evaluation of
	all commands in the script. Answer the last process proxy to have been evaluated."

	"CommandShell new open; 
		scriptDoAll: 'who
				help
				ls -l NOSUCHFILE
				help'"

	| commandStream lastProxy |
	commandStream _ ReadStream on:
						(aScriptString
							copyReplaceAll: Character lf asString
							with: Character cr asString).
	[commandStream atEnd]
		whileFalse:
			[lastProxy _ self command: commandStream nextLine].
	^ lastProxy


]

{ #category : #accessing }
CommandShell >> shellSyntax [
	"A pluggable instance of a command processing syntax"

	^ shellSyntax ifNil: [shellSyntax _ ShellSyntax new]
]

{ #category : #accessing }
CommandShell >> shellSyntax: aSyntax [
	"A pluggable instance of a command processing syntax"

	shellSyntax _ aSyntax
]

{ #category : #'stream extensions' }
CommandShell >> show: anObject [  "TextCollector compatibility"
	self nextPutAll: anObject asString; endEntry
]

{ #category : #'command support' }
CommandShell >> splitPipelineCommands: aCommand [
	"Answer a list of the individual commands in a command pipeline string,
	delimited by the pipe character."

	^ (aCommand findTokens: self pipeCharToken) collect: [:e | e withBlanksTrimmed]

]

{ #category : #accessing }
CommandShell >> stProcesses [
	"The Smalltalk processes associated with process proxies."

	stProcesses ifNil: [stProcesses _ OrderedCollection new].
	^ stProcesses

]

{ #category : #'initialize-release' }
CommandShell >> terminateCommandLineProcesses [
	"Terminate all but the currently active process"

	(self commandLineProcesses reject: [:e | e == Processor activeProcess])
		do: [:p | p terminate].
	commandLineProcesses _ nil

]

{ #category : #'initialize-release' }
CommandShell >> terminateStProcesses [
	"Terminate all but the currently active process"

	(self stProcesses reject: [:e | e == Processor activeProcess])
		do: [:p | p terminate].
	stProcesses _ nil

]

{ #category : #accessing }
CommandShell >> timeWasterProcess [

	^ timeWasterProcess
]

{ #category : #'command processing' }
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
	process _ self evaluationProxyFor: aCommandString input: nil output: nil error: nil.
	process value.
	process closeOutput.
	process closeErrorPipeline. "Last process in pipeline, so it can be closed."
	^ process
]

{ #category : #'input character filtering' }
CommandShell >> unpauseStProcesses [
	"Permit my Smalltalk processes to be scheduled."

	(self stProcesses reject: [:e | e == Processor activeProcess])
		do: [:p | p priority: Processor userSchedulingPriority; resume].
	timeWasterProcess ifNotNil: [timeWasterProcess terminate]

]

{ #category : #'working directory' }
CommandShell >> workingDirectory [

	^ self shellSyntax workingDirectory
		ifNil:
			[shellSyntax workingDirectory: FileDirectory default pathName; workingDirectory]
]

{ #category : #'working directory' }
CommandShell >> workingDirectory: aPathString [

	self shellSyntax workingDirectory: aPathString

]
