"
A shell builtin command, intended to be invoked by a CommandShell.

A builtin command consists of:
 name - a String identifier, used by the CommandShell to identify and invoke the commmand.
 helpString - a String to describe the function of the command.
 procedure - a BlockContext with parameters to be passed by the CommandShell.

Commands are implemented in class methods. To create a new command, write a new
command implementation method and a corresponding instance creation method patterned
after one of the existing commands, and install the instance creation method in an
instance of CommandShell with CommandShell>>installCommand:.
"
Class {
	#name : #ShellBuiltin,
	#superclass : #Object,
	#instVars : [
		'name',
		'procedureSelector',
		'helpSelector',
		'needsPrompt'
	],
	#category : #CommandShell
}

{ #category : #'command definition' }
ShellBuiltin class >> cd: commandShell [
	"Define command to set the current working directory. Answer an empty string
	or #invalidCommand."

	^ self name: 'cd'
		help: #cdHelp
		procedure: #cdCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> cdCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Set the current working directory. Answer an empty string or #invalidCommand."

	| newPath path arg pathCwd p |
	argArray size == 0
		ifTrue:
			[newPath _ commandShell home]
		ifFalse:
			[argArray size == 1
				ifTrue:
					[path _ argArray at: 1.
					(path = commandShell shellSyntax pathStringAboveRoot)
						ifTrue:
							[newPath _ commandShell shellSyntax pathAboveRoot]
						ifFalse:
							[pathCwd _ commandShell shellSyntax getCwdForPath: path.
							arg _ (path = FileDirectory slash)
								ifTrue: [path]
								ifFalse: [commandShell shellSyntax
												expandArgument: path
												inDirectoryPath: pathCwd].
							newPath _ arg isEmpty
								ifTrue: [arg]
								ifFalse:
									[p _ commandShell newDirPath: arg from: pathCwd.
									p ifNotNil: [FileDirectory default fullNameFor: p]]]]
				ifFalse:
					[^ commandShell invalidCommandMessage]].
	newPath isNil
		ifTrue:
			["No directory found with this name"
			stderr nextPutAll: argArray first, ': no such file or directory'; nextPut: Character lf]
		ifFalse:
			[(commandShell workingDirectory ~= newPath)
				ifTrue:
					[(newPath isEmpty or: [commandShell isADirectory: newPath])
						ifTrue:
							[commandShell workingDirectory: newPath.
							commandShell changed: #relabel.
							commandShell environment ifNotNil:
								[commandShell environment at: #PWD put: commandShell workingDirectory]]
						ifFalse:
							["File of this name exists, but is not a directory"
							stderr nextPutAll: newPath, ': not a directory'; nextPut: Character lf]]]

]

{ #category : #'help messages' }
ShellBuiltin class >> cdHelp [

	^ 'cd [path] - change default directory'
]

{ #category : #'command definition' }
ShellBuiltin class >> clear: commandShell [
	"Define command to clear the terminal display screen. Answer a string or an invalid
	command message."

	^ self name: 'clear'
		help: #clearHelp
		procedure: #clearCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> clearCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Clear the terminal display screen. Answer a string or an invalid command message."

	argArray size == 0 ifFalse: [^ commandShell invalidCommandMessage].
	commandShell terminateStProcesses. "Terminate any running Smalltalk processes"
	commandShell terminateCommandLineProcesses. "Terminate any running Smalltalk processes"
	commandShell changed: #clearText

]

{ #category : #'help messages' }
ShellBuiltin class >> clearHelp [

	^ 'clear - clear screen'

]

{ #category : #private }
ShellBuiltin class >> copyAllFrom: aPipe to: aStream [
	"Copy the contents of aPipe to aStream, where aPipe is the output of a
	process proxy. Do the copy in chunks, and between chunks force an
	update to the run status of external child processes. Answer aStream
	when done.

	This method is intended to be used by internal commands which need to
	read input from an external OSPipe, and which could deadlock if the
	pipe is set to blocking mode.

	This method synchronizes the evaluation of process proxies by forcing
	a wait for the first available character on aPipe. All pipes will supply
	at least one character, or a nil when empty. It is safe to block waiting
	for the first character as long as the pipe is being written by a proxy
	which will close the pipe when it exits."

	| d chunkSize s |
	d _ Delay forMilliseconds: 200.
	chunkSize _ 100000.
	"FIXME: The following delay is required only for Squeak 3.7 and 3.8. Squeak 3.6
	(and earlier) and Squeak 3.9 (and later) do not need it."
	(Delay forMilliseconds: 100) wait. "Wait to allow sync with external processes"
	aPipe peek. "Force a wait for the first character prior to setting nonblocking mode"
	[aPipe setNonBlocking] on: Error do: []. "Set nonblocking mode if input is a pipe"
	[aPipe atEnd] whileFalse:
		[s _ aPipe next: chunkSize.
		s isNil
			ifTrue:
				[(Smalltalk hasClassNamed: #OSProcess)
					ifTrue: [(Smalltalk at: #OSProcess) thisOSProcess updateActiveChildren]]
			ifFalse:
				[aStream nextPutAll: s].
		d wait].
	^ aStream

]

{ #category : #'command definition' }
ShellBuiltin class >> copyToError: commandShell [
	"Define command to copy the contents of (argArray at: 1) or stdin onto
	stderr. This command exists only for purposes of testing stdin and pipelines
	for PipeableEvaluator proxies."

	^ self name: 'copyToError'
		help: nil
		procedure: #copyToErrorCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> copyToErrorCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Copy the contents of (argArray at: 1) or stdin onto stderr. This
	command exists only for purposes of testing stdin and pipelines
	for PipeableEvaluator proxies."

	| anyOutput fs |
	(argArray isNil or: [argArray size == 0])
		ifTrue:
			[stdin ifNotNil: [self copyAllFrom: stdin to: stderr]]
		ifFalse:
			[anyOutput _ false.
			(self expandArguments: argArray commandShell: commandShell) do:
				[:file |
					(FileDirectory default fileExists: file)
						ifTrue:
							[fs _ FileStream readOnlyFileNamed: file.
							fs ifNotNil:
								[anyOutput _ true.
								self copyAllFrom: fs to: stderr.
								fs close]].
			anyOutput ifTrue: [stderr nextPut: Character lf]]]

]

{ #category : #'command definition' }
ShellBuiltin class >> copyToOutput: commandShell [
	"Define command to  copy the contents of (argArray at: 1) or stdin onto
	stdout. This command exists only for purposes of testing stdin and pipelines
	for PipeableEvaluator proxies."

	^ self name: 'copyToOutput'
		help: nil
		procedure: #copyToOutputCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> copyToOutputCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Copy the contents of (argArray at: 1) or stdin onto stdout. This
	command exists only for purposes of testing stdin and pipelines
	for PipeableEvaluator proxies."

	| anyOutput fs |
	(argArray isNil or: [argArray size == 0])
		ifTrue:
			[stdin ifNotNil: [self copyAllFrom: stdin to: stdout]]
		ifFalse:
			[anyOutput _ false.
			(self expandArguments: argArray commandShell: commandShell) do:
				[:file |
					(FileDirectory default fileExists: file)
						ifTrue:
							[fs _ FileStream readOnlyFileNamed: file.
							fs ifNotNil:
								[anyOutput _ true.
								self copyAllFrom: fs to: stdout.
								fs close]].
			anyOutput ifTrue: [stdout nextPut: Character lf]]]

]

{ #category : #'command definition' }
ShellBuiltin class >> edit: commandShell [
	"Define command to open an editor on each of the named files."

	^ self name: 'edit'
		help: #editHelp
		procedure: #editCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> editCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Open an editor on each of the named files."

	| controllers inputString |
	(argArray isNil or: [argArray size == 0])
		ifTrue:
			["When taking input from a command pipeline, the input must be
			read into inputString now. This is because, in MVC, the CrLfFileEditor
			is scheduled to be created later, and the input pipe will be closed by
			the caller of this method before the CrLfFileEditor ever has a chance
			to read it."
			inputString _ stdin isNil
				ifTrue:
					['']
				ifFalse:
					[(self copyAllFrom: stdin to: (WriteStream on: String new)) contents
						replaceAll: Character lf with: Character cr].
			commandShell scheduleToEvaluate:
				[(CrLfFileEditor
					openOn: inputString
					withLabel: (commandShell commandHistory isEmpty
									ifTrue: ['']
									ifFalse: [commandShell commandHistory last])
					inDirectory: (FileDirectory on: commandShell workingDirectory)
					defaultFileName: 'buffer.txt') openInWorld] fixTemps]
		ifFalse:
			[controllers _ (self expandArguments: argArray commandShell: commandShell)
								collect:
									[:file | CrLfFileEditor fileNamed: file].
			Smalltalk isMorphic
				ifFalse:
					[controllers
						inject: nil
						into:
							[:prev :c |
							prev ifNotNil:
								[c addDeferredUIMessage: [prev open] fixTemps].
							c].
					commandShell scheduleToEvaluate: [controllers last open]]
				ifTrue:
					[controllers do:
						[:e | commandShell scheduleToEvaluate: [e openInWorld] fixTemps]]]

]

{ #category : #'help messages' }
ShellBuiltin class >> editHelp [

	^ 'edit [files...] - edit the contents of stdin or the named files'

]

{ #category : #'command definition' }
ShellBuiltin class >> exit: commandShell [
	"Define command to exit the shell window. Answer a string or an invalid
	command message."

	^ self name: 'exit'
		help: #exitHelp
		procedure: #exitCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> exitCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Exit the shell window. Answer a string or an invalid command message."

	argArray size == 0 ifFalse: [^ commandShell invalidCommandMessage].
	commandShell changed: #exit

]

{ #category : #'help messages' }
ShellBuiltin class >> exitHelp [

	^ 'exit - exit shell and close window'
]

{ #category : #private }
ShellBuiltin class >> expandArguments: argArray commandShell: aCommandShell [
	"The builtin command is simulating an external command, and needs to expand
	the argument list in the context of a file system. Answer the expanded list of
	arguments."

	^ aCommandShell shellSyntax
		expandedFileNames: argArray
		inDirectoryPath: aCommandShell workingDirectory
]

{ #category : #'command definition' }
ShellBuiltin class >> fc: commandShell [
	"Define 'fix command' command. If argArray is emply, answer the last
	command in the history list. If there is one argument, interpret it as an
	integer index into the history list. Otherwise answer an invalid command
	message."

	^ self name: 'fc'
		help: #fcHelp
		procedure: #fcCommand:input:output:error:arguments:
		needsPrompt: false

]

{ #category : #implementations }
ShellBuiltin class >> fcCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Fix command. If argArray is emply, answer the last command in the
	history list. If there is one argument, interpret it as an integer index
	into the history list. Otherwise answer an invalid command message."

	| index cmd |
	commandShell commandHistory ifNotNil:
		[commandShell scheduleToEvaluate:
			[argArray size == 0
				ifTrue:
					[cmd _ commandShell editCommand: (commandShell historyAt: 0)]
				ifFalse:
					[[index _ (argArray at: 1) asNumber]
								on: Error
								do: [:ex | index _ nil].
					cmd _ commandShell editCommand:
							(index isNil
								ifTrue: ['']
								ifFalse: [commandShell historyAt: index])].
					commandShell prompt.
					cmd isEmpty ifFalse:
						[commandShell show: cmd; doCommandsInString: cmd]]]

]

{ #category : #'help messages' }
ShellBuiltin class >> fcHelp [

	^ 'fc [i] - "fix command", command number i from history list, or -i, or the last command'

]

{ #category : #'command definition' }
ShellBuiltin class >> help: commandShell [
	"Define command to display help messages."

	^ self name: 'help'
		help: #helpHelp
		procedure: #helpCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> helpCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [

	| topic command |
	argArray size == 0
		ifTrue:
			[(commandShell builtinCommands collect: [:c | c helpSelector] thenSelect: [:s | s notNil])
				asSortedArray do:
					[:sel | stdout nextPutAll: (self perform: sel); nextPut: Character lf].
			stdout
				nextPutAll: 'simple Smalltalk expression! evaluates a simple expression as a doIt';
				nextPut: Character lf;
				nextPutAll: '<ctl-C> to interrupt a running program';
				nextPut: Character lf;
				nextPutAll: '<ctl-D> to end input to a running program';
				nextPut: Character lf]
		ifFalse:
			[topic _ argArray at: 1.
			command _ commandShell builtinCommands at: topic ifAbsent: [^ self].
			command helpSelector ifNotNil:
				[stdout nextPutAll: (self perform: command helpSelector); nextPut: Character lf]]

]

{ #category : #'help messages' }
ShellBuiltin class >> helpHelp [

	^ 'help - help on sqsh commands'

]

{ #category : #'command definition' }
ShellBuiltin class >> history: commandShell [
	"Define command to display the command history list."

	^ self name: 'history'
		help: #historyHelp
		procedure: #historyCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> historyCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Display the command history list."

	| ws rs |
	ws _ WriteStream on: Character cr asString.
	rs _ ReadStream on: commandShell commandHistory.
	[rs atEnd]
		whileFalse: [ws nextPutAll: rs next.
			ws nextPutAll: ' '.
			ws nextPutAll: rs next.
			rs atEnd
				ifFalse: [ws cr]].
	stdout nextPutAll: (ws contents, Character cr asString)

]

{ #category : #'help messages' }
ShellBuiltin class >> historyHelp [

	^ 'history - display command history list'

]

{ #category : #'command definition' }
ShellBuiltin class >> inspect: commandShell [
	"Define command to open a Smalltalk inspector on the contents of stdin, or the
	file(s) named on the command line."

	^ self name: 'inspect'
		help: #inspectHelp
		procedure: #inspectCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> inspectCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Open a Smalltalk inspector on the contents of stdin, or the file(s) named on the
	command line."

	| files fs inputString |
	(argArray isNil or: [argArray size == 0])
		ifTrue:
			[stdin ifNotNil:
				["When taking input from a command pipeline, the input must be
				read into inputString now. This is because, in MVC, the inspector
				is scheduled to be created later, and the input pipe will be closed by
				the caller of this method before the deferred block ever has a
				chance to read it."
				inputString _ stdin ifNotNil:
					[(self copyAllFrom: stdin to: (WriteStream on: String new)) contents
						replaceAll: Character lf with: Character cr].
				commandShell scheduleToEvaluate: [inputString inspect]]]
		ifFalse:
			[files _ self expandArguments: argArray commandShell: commandShell.
			(files size == 0)
				ifTrue:
					[commandShell scheduleToEvaluate: [nil inspect]]
				ifFalse:
					[files do:
						[:e |
						fs _ (FileDirectory default fileExists: e)
							ifTrue: [FileStream readOnlyFileNamed: e]
							ifFalse: [nil].
						fs isNil
							ifTrue:
								[commandShell scheduleToEvaluate: [nil inspect]]
							ifFalse:
								[commandShell scheduleToEvaluate:
									[(fs contentsOfEntireFile
									replaceAll: Character lf
									with: Character cr) inspect.
									fs close] fixTemps]]]]

]

{ #category : #'help messages' }
ShellBuiltin class >> inspectHelp [

	^ 'inspect [files...] - open an inspector on the contents of stdin or the named files'

]

{ #category : #'instance creation' }
ShellBuiltin class >> name: aString help: helpSelector procedure: procedureSelector needsPrompt: trueOrFalse [
	"Command definition methods use this method to create instances representing
	shell builtin commands. The commands are installed in a CommandShell, and
	later evaluated in the context of a PipeableEvaluator."

	^ self new
		name: aString;
		helpSelector: helpSelector;
		procedureSelector: procedureSelector;
		needsPrompt: trueOrFalse

]

{ #category : #'command definition' }
ShellBuiltin class >> pwd: commandShell [
	"Define command to answer the current working directory (a string) or an
	invalid command message."

	^ self name: 'pwd'
		help: #pwdHelp
		procedure: #pwdCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> pwdCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Answer the current working directory (a string) or an invalid command message."

	| directoryString |
	directoryString _ commandShell workingDirectory.
	directoryString isEmpty ifTrue: [directoryString _ commandShell nullDirectoryString].
	argArray size == 0 ifFalse: [^ commandShell invalidCommandMessage].
	stdout nextPutAll: directoryString; cr

]

{ #category : #'help messages' }
ShellBuiltin class >> pwdHelp [

	^ 'pwd - print current working directory'

]

{ #category : #'command definition' }
ShellBuiltin class >> sls: commandShell [
	"Define command to for a simple directory contents lister"

	^ self name: 'sls'
		help: #slsHelp
		procedure: #slsCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> slsCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Simple directory contents lister"

	| filePatterns d entries names dirs files entry |
	(argArray isNil or: [argArray size == 0])
		ifTrue:
			["Contents of current directory."
			filePatterns _ Array with: '*']
		ifFalse:
			["List named files"
			filePatterns _ argArray].
	d _ FileDirectory on: commandShell workingDirectory.
	entries _ d entries.
	names _ Set new.
	filePatterns do: [:pat | names addAll: (commandShell shellSyntax glob: pat inDirectory: d)].
	dirs _ OrderedCollection new.
	files _ OrderedCollection new.
	names asSortedArray do:
		[:n |
		entry _ entries detect: [:e | e name = n].
		entry isDirectory
			ifTrue: [dirs add: entry]
			ifFalse: [files add: entry]].
	dirs do: [:e | stdout nextPutAll: (commandShell dirEntryString: e); nextPut: Character cr].
	files do: [:e | stdout nextPutAll: (commandShell dirEntryString: e); nextPut: Character cr]

]

{ #category : #'help messages' }
ShellBuiltin class >> slsHelp [

	^ 'sls [filepatterns] - list current directory contents'

]

{ #category : #'command definition' }
ShellBuiltin class >> sqsh: commandShell [
	"Define command to open a new shell window."

	^ self name: 'sqsh'
		help: #sqshHelp
		procedure: #sqshCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> sqshCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Open a new shell window."

	| ws |
	argArray size == 0
		ifTrue:
			[commandShell scheduleToEvaluate: [commandShell class open]]
		ifFalse:
			[ws _ WriteStream on: String new.
			argArray inject: true into:
				[:first :each |
				first ifFalse: [ws nextPut: Character space].
				ws nextPutAll: each.
				false].
			commandShell scheduleToEvaluate: [commandShell class openLabel: ws contents] fixTemps]

]

{ #category : #'help messages' }
ShellBuiltin class >> sqshHelp [

	^ 'sqsh [title] - open new shell window'

]

{ #category : #'command definition' }
ShellBuiltin class >> type: commandShell [
	"Define command to answer how each name would be interpreted if used as a
	command name."

	^ self name: 'type'
		help: #typeHelp
		procedure: #typeCommand:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #implementations }
ShellBuiltin class >> typeCommand: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Answer how each name would be interpreted if used as a command name."

	| results exe |
	argArray size == 0
		ifTrue:
			[^ '']
		ifFalse:
			[results _ WriteStream on: Array new.
			argArray do:
			[:arg |
			(commandShell isBuiltInCommand: arg)
				ifTrue:
					[results nextPut: arg, ' is a shell builtin']
				ifFalse:
					[((Smalltalk hasClassNamed: #OSProcess)
							and: [(Smalltalk at: #OSProcess) accessor canAccessSystem])
					 	ifFalse:
							[self inform: 
								((Smalltalk hasClassNamed: #OSProcess)
									ifTrue: [(Smalltalk at: #OSProcess) accessor class name]
									ifFalse: [commandShell class name]), ' cannot access system'.
							stdout nextPutAll: 'cannot access system'; cr.
							^ self].
					exe _ commandShell shellSyntax findExecutablePathFor: arg inDirectoryPath: commandShell workingDirectory.
					(commandShell shellSyntax isExecutable: exe) ifFalse: [exe _ nil].
					exe isNil
						ifTrue: [results nextPut: arg, ': not found']
								ifFalse: [results nextPut: arg, ' is ', exe]]].
				results contents do: [:e | stdout nextPutAll: e; cr]]

]

{ #category : #'help messages' }
ShellBuiltin class >> typeHelp [

	^ 'type [names...] - indicate how each name would be interpreted if used as a command'

]

{ #category : #accessing }
ShellBuiltin >> helpSelector [

	^ helpSelector
]

{ #category : #accessing }
ShellBuiltin >> helpSelector: aSymbol [

	helpSelector _ aSymbol
]

{ #category : #accessing }
ShellBuiltin >> name [

	^ name
]

{ #category : #accessing }
ShellBuiltin >> name: aString [

	name _ aString
]

{ #category : #accessing }
ShellBuiltin >> needsPrompt [
	"True if the command should be followed by a prompt"

	^ needsPrompt ifNil: [needsPrompt _ true]
]

{ #category : #accessing }
ShellBuiltin >> needsPrompt: trueOrFalse [
	"True if the command should be followed by a prompt"

	needsPrompt _ trueOrFalse
]

{ #category : #accessing }
ShellBuiltin >> procedureSelector [

	^ procedureSelector
]

{ #category : #accessing }
ShellBuiltin >> procedureSelector: aSymbol [

	procedureSelector _ aSymbol
]
