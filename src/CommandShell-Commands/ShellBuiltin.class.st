"
A shell builtin command, intended to be invoked by a CommandShell.

A builtin command consists of:
 name - a String identifier, used by the CommandShell to identify and invoke the commmand.
 helpString - a String to describe the function of the command.
 procedure - a BlockContext with parameters to be passed by the CommandShell.

Commands are implemented in instance methods. To create a new command, write a
new command implementation method and a new help method for the command. Write
a new class side instance creation method patterned after one of the existing commands
and install the instance creation method in an instance of CommandShell with
CommandShell>>installCommand:.

A command implementation is a method which receives six paramaters. The parameters are
to be interpreted as follows:
	- First parameter: The EvaluatorProxy which is evaluating the command. If a command fails,
	  send #fail to this object.
	- Second parameter: The CommandShell from which the command was evaluated. Use this
	  for any additional parsing which may be required in the command implementation.
	- Third parameter: The input stream for the command.
	- Forth parameter: The output stream for the command.
	- Fifth parameter: The error stream for the command.
	- Sixth parameter: An array of optional command arguments.

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
	#category : #'CommandShell-Commands'
}

{ #category : #'instance creation' }
ShellBuiltin class >> cd: commandShell [
	"Define command to set the current working directory. Answer an empty string
	or #invalidCommand."

	^ self name: 'cd'
		help: #cdHelp
		procedure: #cdCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> clear: commandShell [
	"Define command to clear the terminal display screen. Answer a string or an invalid
	command message."

	^ self name: 'clear'
		help: #clearHelp
		procedure: #clearCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'command dictionary creation' }
ShellBuiltin class >> commandDictionaryFor: aCommandShell commands: commandNameArray [
	"Answer a Dictionary of ShellBuiltin instances suitable for use by a CommandShell"

	"ShellBuiltin commandDictionaryFor: CommandShell new commands: #(cd: clear: copyToError: copyToOutput: edit: exit: fc: help: history: inspect: pwd: sls: sqsh: type:)"

	^ commandNameArray
		inject: Dictionary new
		into:
			[:d :cmd | | b |
			b := self perform: cmd with: aCommandShell.
			d at: b name put: b; yourself]
]

{ #category : #'instance creation' }
ShellBuiltin class >> copyToError: commandShell [
	"Define command to copy the contents of (argArray at: 1) or stdin onto
	stderr. This command exists only for purposes of testing stdin and pipelines
	for PipeableEvaluator proxies."

	^ self name: 'copyToError'
		help: nil
		procedure: #copyToErrorCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> copyToOutput: commandShell [
	"Define command to  copy the contents of (argArray at: 1) or stdin onto
	stdout. This command exists only for purposes of testing stdin and pipelines
	for PipeableEvaluator proxies."

	^ self name: 'copyToOutput'
		help: nil
		procedure: #copyToOutputCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> edit: commandShell [
	"Define command to open an editor on each of the named files."

	^ self name: 'edit'
		help: #editHelp
		procedure: #editCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> exit: commandShell [
	"Define command to exit the shell window. Answer a string or an invalid
	command message."

	^ self name: 'exit'
		help: #exitHelp
		procedure: #exitCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> fc: commandShell [
	"Define 'fix command' command. If argArray is emply, answer the last
	command in the history list. If there is one argument, interpret it as an
	integer index into the history list. Otherwise answer an invalid command
	message."

	^ self name: 'fc'
		help: #fcHelp
		procedure: #fcCommand:shell:input:output:error:arguments:
		needsPrompt: false

]

{ #category : #'instance creation' }
ShellBuiltin class >> help: commandShell [
	"Define command to display help messages."

	^ self name: 'help'
		help: #helpHelp
		procedure: #helpCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> history: commandShell [
	"Define command to display the command history list."

	^ self name: 'history'
		help: #historyHelp
		procedure: #historyCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> inspect: commandShell [
	"Define command to open a Smalltalk inspector on the contents of stdin, or the
	file(s) named on the command line."

	^ self name: 'inspect'
		help: #inspectHelp
		procedure: #inspectCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #private }
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

{ #category : #'instance creation' }
ShellBuiltin class >> pwd: commandShell [
	"Define command to answer the current working directory (a string) or an
	invalid command message."

	^ self name: 'pwd'
		help: #pwdHelp
		procedure: #pwdCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> sls: commandShell [
	"Define command to for a simple directory contents lister"

	^ self name: 'sls'
		help: #slsHelp
		procedure: #slsCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> snapshot: commandShell [
	"Define command to save the Squeak image."

	^ self name: 'snapshot'
		help: #snapshotHelp
		procedure: #snapshotCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> sqsh: commandShell [
	"Define command to open a new shell window."

	^ self name: 'sqsh'
		help: #sqshHelp
		procedure: #sqshCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> ttyExit: commandShell [
	"Define command to exit the Squeak shell and quit Squeak without saving the image."

	^ self name: 'exit'
		help: #ttyExitHelp
		procedure: #ttyExitCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #'instance creation' }
ShellBuiltin class >> type: commandShell [
	"Define command to answer how each name would be interpreted if used as a
	command name."

	^ self name: 'type'
		help: #typeHelp
		procedure: #typeCommand:shell:input:output:error:arguments:
		needsPrompt: true

]

{ #category : #private }
ShellBuiltin >> canAccessOSProcess [
	"True if OSProcess is in the image and if the OSProcess plugin is functioning properly"

	"self canAccessOSProcess"

	| osp |
	^ (osp := Smalltalk at: #OSProcess ifAbsent: []) notNil and: [osp accessor canAccessSystem]

]

{ #category : #implementations }
ShellBuiltin >> cdCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Set the current working directory. Answer an empty string or #invalidCommand."

	| newPath path arg pathCwd p |
	argArray size == 0
		ifTrue:
			[newPath := commandShell home]
		ifFalse:
			[argArray size == 1
				ifTrue:
					[path := argArray at: 1.
					(path = commandShell shellSyntax pathStringAboveRoot)
						ifTrue:
							[newPath := commandShell shellSyntax pathAboveRoot]
						ifFalse:
							[pathCwd := commandShell shellSyntax getCwdForPath: path.
							arg := (path = FileDirectory slash)
								ifTrue: [path]
								ifFalse: [commandShell shellSyntax
												firstExpandedArgument: path
												inDirectoryPath: pathCwd].
							newPath := arg isEmpty
								ifTrue: [arg]
								ifFalse:
									[p := commandShell shellSyntax newDirPath: arg from: pathCwd.
									p ifNotNil: [FileDirectory default fullNameFor: p]]]]
				ifFalse:
					[myProxy fail.
					^ commandShell invalidCommandMessage]].
	newPath isNil
		ifTrue:
			["No directory found with this name"
			myProxy fail.
			stderr nextPutAll: argArray first, ': No such file or directory'; nextPut: Character lf]
		ifFalse:
			[(commandShell workingDirectory ~= newPath)
				ifTrue:
					[(newPath isEmpty or: [commandShell shellSyntax isDirectoryPath: newPath])
						ifTrue:
							[commandShell workingDirectory: newPath.
							commandShell changed: #relabel.
							commandShell environment ifNotNil:
								[commandShell environment at: #PWD put: commandShell workingDirectory]]
						ifFalse:
							["File of this name exists, but is not a directory"
							myProxy fail.
							stderr nextPutAll: newPath, ': not a directory'; nextPut: Character lf]]]

]

{ #category : #'help messages' }
ShellBuiltin >> cdHelp [

	^ 'cd [path] - change default directory'
]

{ #category : #implementations }
ShellBuiltin >> clearCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Clear the terminal display screen. Answer a string or an invalid command message."

	argArray size == 0 ifFalse:
		[myProxy fail.
		^ commandShell invalidCommandMessage].
	commandShell startUpInNewSession.
	commandShell changed: #clearText

]

{ #category : #'help messages' }
ShellBuiltin >> clearHelp [

	^ 'clear - clear screen'

]

{ #category : #implementations }
ShellBuiltin >> copyToErrorCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Copy the contents of (argArray at: 1) or stdin onto stderr. This
	command exists only for purposes of testing stdin and pipelines
	for PipeableEvaluator proxies."

	| fs |
	(argArray isNil or: [argArray size == 0])
		ifTrue:
			[stdin ifNotNil: [self copyUntilDoneFrom: stdin to: stderr]]
		ifFalse:
			[argArray do:
				[:file |
				(FileDirectory default fileExists: file)
					ifTrue:
						[fs := FileStream readOnlyFileNamed: file.
						fs ifNotNil:
							[self copyUntilDoneFrom: fs to: stderr.
							fs close]]]]

]

{ #category : #implementations }
ShellBuiltin >> copyToOutputCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Copy the contents of (argArray at: 1) or stdin onto stdout. This
	command exists only for purposes of testing stdin and pipelines
	for PipeableEvaluator proxies."

	| fs |
	(argArray isNil or: [argArray size == 0])
		ifTrue:
			[stdin ifNotNil: [self copyUntilDoneFrom: stdin to: stdout]]
		ifFalse:
			[argArray do:
				[:file |
				(FileDirectory default fileExists: file)
					ifTrue:
						[fs := FileStream readOnlyFileNamed: file.
						fs ifNotNil:
							[self copyUntilDoneFrom: fs to: stdout.
							fs close]]]]

]

{ #category : #private }
ShellBuiltin >> copyUntilDoneFrom: aPipe to: aStream [
	"Copy the contents of aPipe to aStream, where aPipe is the output of a process
	proxy. Whenever new data is available, aPipe will trigger #dataReady. This
	method responds to the #dataReady events until the end of the pipe is reached.
	It is possible for the #atEnd check to give a false negative, so a timeout alarm
	is used to prevent deadlock conditions."

	| sema s |
	sema := Semaphore new.
	aPipe when: #dataReady send: #signal to: sema.
	[aPipe atEndOfFile] whileFalse:
		[self timeoutAfter: 200 notifying: sema.
		sema wait. "Wait for data available"
		[(s := aPipe next: 10000) isEmpty] whileFalse:
			[aStream nextPutAll: s; flush]].
	aPipe release.
	^ aStream

]

{ #category : #private }
ShellBuiltin >> dirEntryString: aDirectoryEntry [
	"Code lifted from Lex Spoon's FileList>>fileNameFormattedFrom:sizePad:"

	"self new dirEntryString: FileDirectory default entries first"

	| folderString nameStr dateStr sizeStr |
	folderString := ' [...]'.
	nameStr := aDirectoryEntry isDirectory
		ifTrue: [aDirectoryEntry name , folderString]
		ifFalse: [aDirectoryEntry name].
	dateStr := ((Date fromSeconds: aDirectoryEntry modificationTime )
					printFormat: #(3 2 1 $. 1 1 2)) , ' ' ,
				(String streamContents: [:s |
					(Time fromSeconds: aDirectoryEntry modificationTime \\ 86400)
						print24: true on: s]).
	sizeStr := aDirectoryEntry fileSize asStringWithCommas.
	^ nameStr , '    (' , dateStr , ' ' , sizeStr , ')'

]

{ #category : #implementations }
ShellBuiltin >> editCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Open an editor on each of the named files."

	| controllers inputString expandedName |
	(argArray isNil or: [argArray size == 0])
		ifTrue:
			["When taking input from a command pipeline, the input must be
			read into inputString now. This is because, in MVC, the CrLfFileEditor
			is scheduled to be created later, and the input pipe will be closed by
			the caller of this method before the CrLfFileEditor ever has a chance
			to read it."
			inputString := stdin isNil
				ifTrue:
					['']
				ifFalse:
					[(self copyUntilDoneFrom: stdin to: (WriteStream on: String new)) contents
						replaceAll: Character lf with: Character cr].
			commandShell scheduleToEvaluate:
				[CrLfFileEditor
					openOn: inputString
					withLabel: (commandShell commandHistory isEmpty
									ifTrue: ['']
									ifFalse: [commandShell commandHistory last])
					inDirectory: (FileDirectory on: commandShell workingDirectory)
					defaultFileName: 'buffer.txt']]
		ifFalse:
			[controllers := argArray collect:
				[:arg |
				"Expand arguments to convert them to full pathnames as expected by CrLfFileEditor"
				expandedName := commandShell shellSyntax
									firstExpandedArgument: arg
									inDirectoryPath: commandShell shellSyntax workingDirectory.
				CrLfFileEditor fileNamed: expandedName withLabel: arg].
			CommandShell isMorphic
				ifFalse:
					[controllers
						inject: nil
						into:
							[:prev :c |
							prev ifNotNil:
								[c addDeferredUIMessage: [prev open]].
							c].
					commandShell scheduleToEvaluate: [controllers last open]]
				ifTrue:
					[controllers do: [:e |
						WorldState addDeferredUIMessage: [e openInWorld]]]]

]

{ #category : #'help messages' }
ShellBuiltin >> editHelp [

	^ 'edit [files...] - edit the contents of stdin or the named files'

]

{ #category : #implementations }
ShellBuiltin >> exitCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Exit the shell window. Answer a string or an invalid command message."

	argArray size == 0 ifFalse:
		[myProxy fail.
		^ commandShell invalidCommandMessage].
	commandShell changed: #exit

]

{ #category : #'help messages' }
ShellBuiltin >> exitHelp [

	^ 'exit - exit shell and close window'
]

{ #category : #implementations }
ShellBuiltin >> fcCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Fix command. If argArray is emply, answer the last command in the
	history list. If there is one argument, interpret it as an integer index
	into the history list. Otherwise answer an invalid command message."

	| index cmd |
	commandShell commandHistory ifNotNil:
		[commandShell scheduleToEvaluate:
			[argArray size == 0
				ifTrue:
					[cmd := commandShell editCommand: (commandShell historyAt: 0)]
				ifFalse:
					[[index := (argArray at: 1) asNumber]
								on: Error
								do: [:ex | index := nil].
					cmd := commandShell editCommand:
							(index isNil
								ifTrue: ['']
								ifFalse: [commandShell historyAt: index])].
					commandShell notifyPrompt.
					cmd isEmpty ifFalse:
						[commandShell outputStream nextPutAll: cmd; cr; flush; processCommand: cmd echo: false]]]

]

{ #category : #'help messages' }
ShellBuiltin >> fcHelp [

	^ 'fc [i] - "fix command", command number i from history list, or -i, or the last command'

]

{ #category : #implementations }
ShellBuiltin >> helpCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [

	| topic command cacheStream |
	argArray size == 0
		ifTrue:
			[cacheStream := WriteStream on: ''.
			(commandShell builtinCommands
				collect: [:c | c helpSelector] thenSelect: [:s | s notNil])
					asArray sort do:
						[:sel | cacheStream nextPutAll: (self perform: sel);
								nextPut: Character lf].
			cacheStream
				nextPutAll: 'simple Smalltalk expression! evaluates a simple expression as a doIt';
				nextPut: Character lf;
				nextPutAll: '<ctl-C> to interrupt a running program';
				nextPut: Character lf;
				nextPutAll: '<ctl-D> to end input to a running program';
				nextPut: Character lf.
			stdout nextPutAll: cacheStream contents]
		ifFalse:
			[topic := argArray at: 1.
			command := commandShell builtinCommands at: topic ifAbsent: [^ self].
			command helpSelector ifNotNil:
				[stdout nextPutAll: (self perform: command helpSelector); nextPut: Character lf]]

]

{ #category : #'help messages' }
ShellBuiltin >> helpHelp [

	^ 'help - help on sqsh commands'

]

{ #category : #accessing }
ShellBuiltin >> helpSelector [

	^ helpSelector
]

{ #category : #accessing }
ShellBuiltin >> helpSelector: aSymbol [

	helpSelector := aSymbol
]

{ #category : #implementations }
ShellBuiltin >> historyCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Display the command history list."

	| ws rs |
	ws := WriteStream on: Character lf asString.
	rs := ReadStream on: commandShell commandHistory.
	[rs atEnd]
		whileFalse: [ws nextPutAll: rs next.
			ws nextPutAll: ' '.
			ws nextPutAll: rs next.
			rs atEnd
				ifFalse: [ws nextPut: Character lf]].
	stdout nextPutAll: (ws contents, Character lf asString)

]

{ #category : #'help messages' }
ShellBuiltin >> historyHelp [

	^ 'history - display command history list'

]

{ #category : #private }
ShellBuiltin >> imageName [ 
	"After Squeak version 3.6, #imageName was moved to SmalltalkImage "

	^ ((Smalltalk classNamed: 'SmalltalkImage')
		ifNil: [^ Smalltalk imageName]) current imageName
]

{ #category : #implementations }
ShellBuiltin >> inspectCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Open a Smalltalk inspector on the contents of stdin, or the file(s) named on the
	command line."

	| fs inputString pathName |
	(argArray isNil or: [argArray size == 0])
		ifTrue:
			[stdin ifNotNil:
				["When taking input from a command pipeline, the input must be
				read into inputString now. This is because, in MVC, the inspector
				is scheduled to be created later, and the input pipe will be closed by
				the caller of this method before the deferred block ever has a
				chance to read it."
				inputString := stdin ifNotNil:
					[(self copyUntilDoneFrom: stdin to: (WriteStream on: String new)) contents
						replaceAll: Character lf with: Character cr].
				commandShell scheduleToEvaluate: [inputString inspect]]]
		ifFalse:
			[argArray isEmpty
				ifTrue:
					[commandShell scheduleToEvaluate: [nil inspect]]
				ifFalse:
					[argArray do:
						[:e |
						pathName := commandShell shellSyntax
							firstExpandedArgument: e
							inDirectoryPath: commandShell shellSyntax workingDirectory.
						fs := (FileDirectory default fileExists: pathName)
							ifTrue: [FileStream readOnlyFileNamed: pathName]
							ifFalse: [nil].
						fs isNil
							ifTrue:
								[commandShell scheduleToEvaluate: [nil inspect]]
							ifFalse:
								[commandShell scheduleToEvaluate:
									[(fs contentsOfEntireFile
									replaceAll: Character lf
									with: Character cr) inspect.
									fs close]]]]]

]

{ #category : #'help messages' }
ShellBuiltin >> inspectHelp [

	^ 'inspect [files...] - open an inspector on the contents of stdin or the named files'

]

{ #category : #accessing }
ShellBuiltin >> name [

	^ name
]

{ #category : #accessing }
ShellBuiltin >> name: aString [

	name := aString
]

{ #category : #accessing }
ShellBuiltin >> needsPrompt [
	"True if the command should be followed by a prompt"

	^ needsPrompt ifNil: [needsPrompt := true]
]

{ #category : #accessing }
ShellBuiltin >> needsPrompt: trueOrFalse [
	"True if the command should be followed by a prompt"

	needsPrompt := trueOrFalse
]

{ #category : #evaluating }
ShellBuiltin >> performWith: argumentArray evaluator: aPipeableEvaluator shell: aCommandShell input: inputStream output: outputStream error: errorStream [

	self perform: self procedureSelector
		withArguments: (Array
			with: aPipeableEvaluator
			with: aCommandShell
			with: inputStream
			with: outputStream
			with: errorStream
			with: argumentArray).
	aPipeableEvaluator complete

]

{ #category : #printing }
ShellBuiltin >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: ' for '.
	self name printOn: aStream.
]

{ #category : #accessing }
ShellBuiltin >> procedureSelector [

	^ procedureSelector
]

{ #category : #accessing }
ShellBuiltin >> procedureSelector: aSymbol [

	procedureSelector := aSymbol
]

{ #category : #implementations }
ShellBuiltin >> pwdCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Answer the current working directory (a string) or an invalid command message."

	| directoryString |
	directoryString := commandShell workingDirectory.
	directoryString isEmpty ifTrue: [directoryString := self nullDirectoryString].
	argArray size == 0 ifFalse:
		[myProxy fail.
		^ commandShell invalidCommandMessage].
	stdout nextPutAll: directoryString; nextPut: Character lf

]

{ #category : #'help messages' }
ShellBuiltin >> pwdHelp [

	^ 'pwd - print current working directory'

]

{ #category : #implementations }
ShellBuiltin >> slsCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Simple directory contents lister"

	| filePatterns d entries names dirs files entry linesToPrint lineCount cacheStream |

	"A small value of linesToPrint will prevent an ExternalCommandShell from
	overdriving is stdout stream. Maybe. A larger value allows faster updates to
	an interactive CommandShell display."
	linesToPrint := 16.

	(argArray isNil or: [argArray size == 0])
		ifTrue:
			["Contents of current directory."
			filePatterns := Array with: '*']
		ifFalse:
			["List named files"
			filePatterns := argArray].
	d := FileDirectory on: commandShell workingDirectory.
	entries := d entries.
	names := Set new.
	filePatterns do: [:pat | names addAll: (commandShell shellSyntax glob: pat inDirectory: d)].
	dirs := OrderedCollection new.
	files := OrderedCollection new.
	names asArray sort do:
		[:n |
		entry := entries detect: [:e | e name = n].
		entry isDirectory
			ifTrue: [dirs add: entry]
			ifFalse: [files add: entry]].

	linesToPrint := 5.
	lineCount := 1.
	cacheStream := WriteStream on: ''.
	dirs do:	[:dir |
		lineCount := lineCount + 1.
		cacheStream nextPutAll: (self dirEntryString: dir); nextPut: Character lf.
		(lineCount > linesToPrint) ifTrue:
			[stdout nextPutAll: cacheStream contents.
			cacheStream := WriteStream on: ''.
			lineCount := 1]].
	files do: [:file |
		lineCount := lineCount + 1.
		cacheStream nextPutAll: (self dirEntryString: file); nextPut: Character lf.
		(lineCount > linesToPrint) ifTrue:
			[stdout nextPutAll: cacheStream contents.
			cacheStream := WriteStream on: ''.
			lineCount := 1]].
	stdout nextPutAll: cacheStream contents.
]

{ #category : #'help messages' }
ShellBuiltin >> slsHelp [

	^ 'sls [filepatterns] - list current directory contents'

]

{ #category : #private }
ShellBuiltin >> snapshot: save andQuit: quit [
	"After Squeak version 3.6, #snapshot:andQuit: was moved to SmalltalkImage "

	^ ((Smalltalk classNamed: 'SmalltalkImage')
		ifNil: [^ Smalltalk snapshot: save andQuit: quit]) current snapshot: save andQuit: quit
]

{ #category : #implementations }
ShellBuiltin >> snapshotCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Save the image"

	| s |
	Smalltalk at: #WorldState ifPresent:
		[:ws |
		s := Semaphore new.
		commandShell safeToExit: false.
		stdout nextPutAll: self imageName; nextPut: Character lf.
		ws addDeferredUIMessage:
			[self snapshot: true andQuit: false.
			s ifNotNil: [s signal] "s is nil when resuming after snapshot"].
		s ifNotNil: [s wait]]

]

{ #category : #'help messages' }
ShellBuiltin >> snapshotHelp [

	^ 'snapshot - save the Squeak image'
]

{ #category : #implementations }
ShellBuiltin >> sqshCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Open a new shell window."

	| ws |
	argArray size == 0
		ifTrue:
			[commandShell scheduleToEvaluate: [commandShell class open]]
		ifFalse:
			[ws := WriteStream on: String new.
			argArray inject: true into:
				[:first :each |
				first ifFalse: [ws nextPut: Character space].
				ws nextPutAll: each.
				false].
			commandShell scheduleToEvaluate: [commandShell class openLabel: ws contents]]

]

{ #category : #'help messages' }
ShellBuiltin >> sqshHelp [

	^ 'sqsh [title] - open new shell window'

]

{ #category : #private }
ShellBuiltin >> timeoutAfter: milliseconds notifying: sema [
	"Under certain conditions it is possible to receive a false negative on
	and end of file check (for example, closing the writer end of a pipe
	from Squeak, and immediately checking for end of file on the reader
	in the same Squeak method). If looping while waiting on end of file,
	this timeout method can be used to prevent a deadlock condition."

	[(Delay forMilliseconds: milliseconds) wait.
	sema signal] fork
]

{ #category : #implementations }
ShellBuiltin >> ttyExitCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Exit an ExternalCommandShell by quitting Squeak. The image is not saved and the shutdown
	list is not processed."

	commandShell safeToExit
		ifTrue: [Smalltalk quitPrimitive]
		ifFalse: [stderr nextPutAll: 'cannot exit in same command line with snapshot'; nextPut: Character lf]

]

{ #category : #'help messages' }
ShellBuiltin >> ttyExitHelp [

	^ 'exit - exit shell and quit Squeak without saving image'
]

{ #category : #implementations }
ShellBuiltin >> typeCommand: myProxy shell: commandShell input: stdin output: stdout error: stderr arguments: argArray [
	"Answer how each name would be interpreted if used as a command name."

	| results exe |
	argArray size == 0
		ifTrue:
			[^ '']
		ifFalse:
			[results := WriteStream on: Array new.
			argArray do:
			[:arg |
			(commandShell isBuiltInCommand: arg)
				ifTrue:
					[results nextPut: arg, ' is a shell builtin']
				ifFalse:
					[self canAccessOSProcess
					 	ifFalse:
							[self inform:
								((Smalltalk hasClassNamed: #OSProcess)
									ifTrue: [(Smalltalk at: #OSProcess) accessor class name]
									ifFalse: [commandShell class name]), ' cannot access system'.
							stdout nextPutAll: 'cannot access system'; nextPut: Character lf.
							^ self].
					exe := commandShell shellSyntax findExecutablePathFor: arg inDirectoryPath: commandShell workingDirectory.
					(commandShell shellSyntax isExecutable: exe) ifFalse: [exe := nil].
					exe isNil
						ifTrue: [results nextPut: arg, ': not found']
								ifFalse: [results nextPut: arg, ' is ', exe]]].
				results contents do: [:e | stdout nextPutAll: e; nextPut: Character lf]]

]

{ #category : #'help messages' }
ShellBuiltin >> typeHelp [

	^ 'type [names...] - indicate how each name would be interpreted if used as a command'

]
