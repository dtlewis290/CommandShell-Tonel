"
I am a connector junction for input, output, and error pipelines. I collaborate with a process proxy to evaluate an internal or external process, and to move objects through the pipelines as the proxy is evaluated.

From Smalltalk, you can write to my pipeToInput, and read from my pipeFromOutput and pipeFromError streams. I implement simple streaming protocol as a convenience for reading and writing these pipe streams. I support command pipelines with the #| message, with the pipeFromOutput of one instance connected to the pipeToInput of the next instance, and a shared errorPipelineStream collecting error output text for the command pipeline.

All reading and writing should be done with the streaming protocol, rather than by direct access to the pipe streams. This is because the output pipe streams may be silently replaced by simple ReadStreams following the exit of the child process.

Normal exit for the external process may not happen when expected. If the process is writing to the output pipe, it may block on write until enough of its data is read from the pipeFromOutput pipe, after which it will exit normally.
"
Class {
	#name : #PipeableOSProcess,
	#superclass : #PipeJunction,
	#instVars : [
		'processProxy',
		'pipeFromError',
		'closeOutputOnExit',
		'keepInitialStdErrOpen',
		'accessProtect'
	],
	#category : #CommandShell
}

{ #category : #utility }
PipeableOSProcess class >> bash [
	"Start a Gnu bash command interpreter (enhanced Unix shell)"

	"self bash"

	^ self command: self externalProxyClass bashShellPath
]

{ #category : #'external command processing' }
PipeableOSProcess class >> command: aString [

	"(PipeableOSProcess command: '/bin/echo this is a test') output"
	"(PipeableOSProcess command: 'echo this is a test') output"
	"(PipeableOSProcess command: '/bin/noSuchCommand this is a test') output"
	"(PipeableOSProcess command: 'ls -l Sq*log') output"
	"(PipeableOSProcess command: 'ls -l ?q*log') output"
	"(PipeableOSProcess command: '/bogusDirectory/ls -l Sq*log') output"

	^ self command: aString
		environment: nil
		workingDir: nil
		input: nil
		output: nil
		error: nil
		errorPipelineStream: nil
]

{ #category : #'external command processing' }
PipeableOSProcess class >> command: aString environment: anEnvironmentDictionary workingDir: pathString input: inputStream output: outputStream error: errorStream [

	"PipeableOSProcess command: 'sleep 6' environment: nil workingDir: '/etc' input: nil output: nil error: nil"
	"(PipeableOSProcess command: 'ls -l' environment: nil workingDir: '/etc' input: nil output: nil error: nil) output"

	^ self command: aString
		environment: anEnvironmentDictionary
		workingDir: pathString
		input: inputStream
		output: outputStream
		error: errorStream
		errorPipelineStream: nil

]

{ #category : #'external command processing' }
PipeableOSProcess class >> command: aString environment: anEnvironmentDictionary workingDir: pathString input: inputStream output: outputStream error: errorStream errorPipelineStream: anErrorWriteStream [

	"(PipeableOSProcess command: 'ls -l hosts NOSUCHFILE' environment: nil workingDir: '/etc' input: nil output: nil error: nil errorPipelineStream: ((WriteStream on: '') nextPutAll: 'this is the error stream '; yourself)) output"

	^ self command: aString
		environment: anEnvironmentDictionary
		workingDir: pathString
		input: inputStream
		output: outputStream
		error: errorStream
		errorPipelineStream: anErrorWriteStream
		shellSyntax: nil

]

{ #category : #'external command processing' }
PipeableOSProcess class >> command: aString environment: anEnvironmentDictionary workingDir: pathString input: inputStream output: outputStream error: errorStream errorPipelineStream: anErrorWriteStream shellSyntax: aSyntaxProcessor [

	"(PipeableOSProcess command: 'ls -l hosts NOSUCHFILE' environment: nil workingDir: '/etc' input: nil output: nil error: nil errorPipelineStream: ((WriteStream on: '') nextPutAll: 'this is the error stream '; yourself) shellSyntax: nil) output"

	| nameAndArgs defaultPath |
	aSyntaxProcessor isNil
		ifTrue:
			[defaultPath _ self externalProxyClass ifNotNilDo: [:c | c defaultShellPath].
			nameAndArgs _ Array
				with: defaultPath
				with: (Array with: '-c' with: aString)]
		ifFalse:
			[nameAndArgs _ aSyntaxProcessor
				programNameAndArgumentsFrom: aString
				inDirectoryPath: pathString].
	^ self
		forkAndExec: (nameAndArgs at: 1)
		arguments: (nameAndArgs at: 2)
		environment: anEnvironmentDictionary
		descriptors: (Array with: inputStream with: outputStream with: errorStream)
		workingDir: pathString
		errorPipelineStream: anErrorWriteStream


]

{ #category : #'external command processing' }
PipeableOSProcess class >> command: aCommandString pipeFrom: aPipeStream errorPipelineStream: anErrorStream [
	"Run a command in a shell process. Similar to the system(3) call in the standard C library,
	except that aCommandString runs asynchronously in a child process."

	^ self
		command: aCommandString
		environment: nil
		workingDir: nil
		input: aPipeStream
		output: nil
		error: nil
		errorPipelineStream: anErrorStream
]

{ #category : #'external command processing' }
PipeableOSProcess class >> commandNoEvaluate: aString environment: anEnvironmentDictionary workingDir: pathString input: inputStream output: outputStream error: errorStream errorPipelineStream: anErrorWriteStream [
	"Set up the command but do not actually fork the child process."

	"PipeableOSProcess commandNoEvaluate: 'ls -l hosts NOSUCHFILE' environment: nil workingDir: '/etc' input: nil output: nil error: nil errorPipelineStream: ((WriteStream on: '') nextPutAll: 'this is the error stream '; yourself)"

	 ^ self commandNoEvaluate: aString
		environment: anEnvironmentDictionary
		workingDir: pathString
		input: inputStream
		output: outputStream
		error: errorStream
		errorPipelineStream: anErrorWriteStream
		shellSyntax: nil

]

{ #category : #'external command processing' }
PipeableOSProcess class >> commandNoEvaluate: aString environment: anEnvironmentDictionary workingDir: pathString input: inputStream output: outputStream error: errorStream errorPipelineStream: anErrorWriteStream shellSyntax: aSyntaxProcessor [
	"Set up the command but do not actually fork the child process."

	"PipeableOSProcess commandNoEvaluate: 'ls -l hosts NOSUCHFILE' environment: nil workingDir: '/etc' input: nil output: nil error: nil errorPipelineStream: ((WriteStream on: '') nextPutAll: 'this is the error stream '; yourself) shellSyntax: nil"

	| nameAndArgs |
	aSyntaxProcessor isNil
		ifTrue:
			[nameAndArgs _ Array
				with: self externalProxyClass defaultShellPath
				with: (Array with: '-c' with: aString)]
		ifFalse:
			[nameAndArgs _ aSyntaxProcessor
				programNameAndArgumentsFrom: aString
				inDirectoryPath: pathString].
	^ self
		new: (nameAndArgs at: 1)
		arguments: (nameAndArgs at: 2)
		environment: anEnvironmentDictionary
		descriptors: (Array with: inputStream with: outputStream with: errorStream)
		workingDir: pathString
		errorPipelineStream: anErrorWriteStream


]

{ #category : #'process proxy classes' }
PipeableOSProcess class >> externalProxyClass [

	^ (Smalltalk hasClassNamed: #ExternalOSProcess)
		ifTrue: [(Smalltalk at: #ExternalOSProcess) concreteClass]
		ifFalse: [nil]
]

{ #category : #'instance creation' }
PipeableOSProcess class >> forkAndExec: executableFile arguments: arrayOfStrings environment: stringDictionary descriptors: arrayOf3Streams workingDir: pathString errorPipelineStream: anErrorStream [
	"Run a program in an external OS process, and answer an instance of myself
	which represents the external process."

	"PipeableOSProcess forkAndExec: '/bin/ls' arguments: #('-ls' 'hosts' 'NOSUCHFILE') environment: nil descriptors: nil workingDir: '/etc' errorPipelineStream: ((WriteStream on: '') nextPutAll: 'this is the error stream '; yourself)"

	(Smalltalk hasClassNamed: #OSProcess)
		ifFalse:
			[self inform: 'cannot access system'.
			^ nil].
	(Smalltalk at: #OSProcess) accessor canAccessSystem
		ifFalse:
			[self inform: (Smalltalk at: #OSProcess) accessor class name, ' cannot access system'.
			^ nil].
	^ (self new: executableFile
		arguments: arrayOfStrings
		environment: stringDictionary
		descriptors: arrayOf3Streams
		workingDir: pathString
		errorPipelineStream: anErrorStream) value; yourself

]

{ #category : #'instance creation' }
PipeableOSProcess class >> new: executableFile arguments: arrayOfStrings environment: stringDictionary descriptors: arrayOf3Streams workingDir: pathString errorPipelineStream: anErrorStream [
	"Prepare to run a program in an external OS process, and answer an instance of
	myself which will represent the external process."

	"PipeableOSProcess new: '/bin/ls' arguments: #('-ls' 'hosts' 'NOSUCHFILE') environment: nil descriptors: nil workingDir: '/etc' errorPipelineStream: ((WriteStream on: '') nextPutAll: 'this is the error stream '; yourself)"

	| pp proc s |
	pp _ super new.
	self externalProxyClass ifNil: [^ nil].
	proc _ self externalProxyClass
			programName: executableFile
			arguments: arrayOfStrings
			initialEnvironment: stringDictionary.
	arrayOf3Streams isNil
		ifTrue:
			[pp createPipes.
			proc initialStdIn: pp pipeToInput reader.
			proc initialStdOut: pp pipeFromOutput writer.
			proc initialStdErr: pp pipeFromError writer]
		ifFalse:
			[(s _ (arrayOf3Streams at: 1)) isNil
				ifTrue:
					[pp createInputPipe.
					proc initialStdIn: pp pipeToInput reader]
				ifFalse:
					[proc initialStdIn: s].
			(s _ (arrayOf3Streams at: 2)) isNil
				ifTrue:
					[pp createOutputPipe.
					proc initialStdOut: pp pipeFromOutput writer]
				ifFalse:
					[proc initialStdOut: s].
			(s _ (arrayOf3Streams at: 3)) isNil
				ifTrue:
					[pp createErrorPipe.
					proc initialStdErr: pp pipeFromError writer]
				ifFalse:
					[proc initialStdErr: s]].
	pathString ifNotNil: [proc pwd: pathString].
	pp errorPipelineStream: anErrorStream.
	pp initialize.
	proc initialize.
	^ pp processProxy: proc

]

{ #category : #utility }
PipeableOSProcess class >> remoteShell: remoteSystemName [ 
	"Start a remote Unix shell on another computer"

	"self remoteShell: 'localhost'"

	^ self
		forkAndExec: self externalProxyClass remoteShellPath
		arguments: (Array with: remoteSystemName with: 'sh')
		environment: nil
		descriptors: nil
		workingDir: nil
		errorPipelineStream: nil

]

{ #category : #examples }
PipeableOSProcess class >> remoteShellExample: remoteUnixHostName [
	"Start a shell on another computer using rsh, and answer the the output
	of some commands on the remote host. You must have security access to
	the remote system in order for this to work."

	"PipeableOSProcess remoteShellExample: 'micron'"
	"PipeableOSProcess remoteShellExample: 'minnow.cc.gatech.edu'"
	"PipeableOSProcess remoteShellExample: 'localhost'"

	| rsh |
	rsh _  self remoteShell: remoteUnixHostName.
	rsh exec: 'echo remote host name is '.
	rsh exec: 'hostname'.
	rsh exec: 'exit'.
	rsh close.
	^ rsh output


]

{ #category : #utility }
PipeableOSProcess class >> shell [
	"Start a Unix shell"

	"self shell"

	^ self command: self externalProxyClass defaultShellPath
]

{ #category : #examples }
PipeableOSProcess class >> tkExample [
	"Start an interactive Tk shell and send it some commands to display a user interface."

	"PipeableOSProcess tkExample"

	| wish |
	wish _  self wish.
	[wish
		exec: 'button .b1 -text "This is button b1"';
		exec: 'button .b2 -text "This is button b2"';
		exec: 'button .exit -text Exit -command exit';
		exec: 'pack .b1 .b2 .exit'] fork.
	^ wish

]

{ #category : #examples }
PipeableOSProcess class >> unixCommandPipeLine [
	"Run a pipeline of commands in a manner similar to Unix command shell
	usage, and answer the result as a string."

	"PipeableOSProcess unixCommandPipeLine"

	^ ((PipeableOSProcess command: 'ps') | 'grep squeak' | 'cut -c16-100') output
]

{ #category : #utility }
PipeableOSProcess class >> waitForCommand: aCommandString [
	"Run a command in a shell process. Similar to the system(3) call in the standard C library.
	The active Smalltalk process waits for completion of the external command process. This just
	uses a simple polling loop, which is not very elegant but works well enough for most purposes."

	"PipeableOSProcess waitForCommand: 'echo sleeping...; sleep 3; echo I just slept for three seconds'"

	| proc d |
	d _ Delay forMilliseconds: 50.
	proc _ self command: aCommandString.
	proc ifNil: [self class noAccessorAvailable].
	[proc runState == #complete] whileFalse: [d wait].
	^ proc

]

{ #category : #utility }
PipeableOSProcess class >> wish [
	"Start a Tk/Tcl command interpreter"

	^ self command: self tkShellPath
]

{ #category : #utility }
PipeableOSProcess class >> xon: remoteSystem command: aCommandString [
	"Convenience method for running an X program on a remote system and displaying its window
	on the local display."

	"PipeableOSProcess xon: 'micron' command: 'xeyes'"

	^ self command: 'xon ', remoteSystem, ' ', aCommandString

]

{ #category : #utility }
PipeableOSProcess class >> xterm: aCommandString [
	"Convenience method for running a command in an external xterm window"

	"PipeableOSProcess xterm: 'top -d 2'"

	^ self command: 'xterm -T ''', aCommandString, ''' -e ', aCommandString
]

{ #category : #'command pipelines' }
PipeableOSProcess >> addToErrorPipeline: aString [

	(aString notNil
		and: [aString size ~= 0])
			ifTrue:
				[self errorPipelineStream nextPutAll: aString]
]

{ #category : #'child process termination' }
PipeableOSProcess >> close [
	"Close pipe to child stdin."

	pipeToInput ifNotNil: [pipeToInput close]

]

{ #category : #accessing }
PipeableOSProcess >> closeOutputOnExit [

	^ closeOutputOnExit ifNil: [closeOutputOnExit _ true]

]

{ #category : #accessing }
PipeableOSProcess >> closeOutputOnExit: trueOrFalse [

	closeOutputOnExit _ trueOrFalse

]

{ #category : #'child process termination' }
PipeableOSProcess >> closePipes [
	"Replace the output and error pipe streams with internal pipes, and close
	all input and output pipes."

	| output |
	self closeOutputOnExit
		ifTrue:
			[(output _ self pipeFromOutput)
				ifNotNil:
					[accessProtect critical:
						[self pipeFromOutput: InternalPipe new.
						self pipeFromOutput nextPutAll: output upToEnd.
						self pipeFromOutput closeWriter.
						output close]]]
		ifFalse:
			["The pipe stream will be closed by the next process in the command pipeline"].
	(pipeFromError) ifNotNil:
		[accessProtect critical:
			[self addToErrorPipeline: pipeFromError upToEnd.
			pipeFromError close]].
	self keepInitialStdErrOpen ifTrue: [self processProxy initialStdErr close].
	self pipeToInput ifNotNil: [pipeToInput close]

]

{ #category : #'initialize - release' }
PipeableOSProcess >> createErrorPipe [
	"Create a pipe for the error stream from the child process."

	(Smalltalk hasClassNamed: #OSPipe)
		ifTrue:
			[pipeFromError _ (Smalltalk at: #OSPipe) nonBlockingPipe]

]

{ #category : #'initialize - release' }
PipeableOSProcess >> createInputPipe [
	"Create a pipe for input to the child process."

	(Smalltalk hasClassNamed: #OSPipe)
		ifTrue:
			[pipeToInput _ (Smalltalk at: #OSPipe) blockingPipe]

]

{ #category : #'initialize - release' }
PipeableOSProcess >> createOutputPipe [
	"Create a pipe for output from the child process."

	(Smalltalk hasClassNamed: #OSPipe)
		ifTrue:
			[pipeFromOutput _ (Smalltalk at: #OSPipe) nonBlockingPipe]

]

{ #category : #'initialize - release' }
PipeableOSProcess >> createPipes [

	pipeToInput ifNil: [self createInputPipe].
	pipeFromOutput ifNil: [self createOutputPipe].
	pipeFromError ifNil: [self createErrorPipe]

]

{ #category : #testing }
PipeableOSProcess >> errorHasBeenRedirected [
	"Answer true if the error output has been redirected to an external file
	and is not available to be read as error output of a pipeline."

	^ self pipeFromError isNil

]

{ #category : #'command pipelines' }
PipeableOSProcess >> errorPipelineContents [

	^ self errorHasBeenRedirected
		ifTrue: ['' "stderr has been redirected to a file"]
	 	ifFalse: [self errorPipelineStream contents]
]

{ #category : #streaming }
PipeableOSProcess >> errorUpToEnd [
	"Answer all available characters from the error stream of my external process."

	^ accessProtect critical:
		[self addToErrorPipeline: (pipeFromError upToEnd).
		self errorHasBeenRedirected
			ifTrue: ['']
			ifFalse: [self errorPipelineStream upToEnd]]

]

{ #category : #evaluating }
PipeableOSProcess >> exec: aString [
	"Pass aString to the child for execution. Presumably the child is running a
	command processor of some kind, such as a Unix shell."

	processProxy isRunning
		ifTrue:
			[self nextPutAll: aString;
			nextPut: Character lf;
			flush]
		ifFalse: [self notify: 'child process not running']



]

{ #category : #'initialize - release' }
PipeableOSProcess >> finalize [

	processProxy ifNotNil: [processProxy removeDependent: self].
	self close
]

{ #category : #streaming }
PipeableOSProcess >> flush [
	"Flush output to the standard input stream of my external process."

	(pipeToInput notNil and: [pipeToInput closed not])
		ifTrue: [pipeToInput flush]
]

{ #category : #'initialize - release' }
PipeableOSProcess >> handlePrecedingError [
	"The stderr stream has been redirected. If there are any characters in the
	errorPipelineStream, write them to the stderr stream before proceeding. Fork
	a process to keep reading any additional error messages from preceding
	processes, and write them to the redirected error. When done, close the redirected
	error stream (this does not affect the actual external process, which has its own
	file handle on the error stream). A background process is used to copy the
	errorPipelineStream because it is not straightforward to attach all predecessor
	proxies in a command pipeline to the redirected error output. This design is
	kludgy, but it works."

	| d |
	d _ Delay forMilliseconds: 200.
	self setKeepInitialStdErrOpen.
	Processor yield.	"A chance to clean up predecessor proxies in command pipeline"
	errorPipelineStream ifNotNil:
			[processProxy initialStdErr nextPutAll: errorPipelineStream upToEnd.
			[[self isRunning or: [self isNotYetRunning]]
				whileTrue:
					[processProxy initialStdErr nextPutAll: errorPipelineStream upToEnd.
					d wait].
				self keepInitialStdErrOpen ifFalse: [processProxy initialStdErr close]] fork]

]

{ #category : #'initialize - release' }
PipeableOSProcess >> initialize [
	"Semaphore to protect against finalizing the output and error streams
	while they are being read."

	accessProtect _ Semaphore forMutualExclusion

]

{ #category : #testing }
PipeableOSProcess >> isComplete [

	^ processProxy isComplete
]

{ #category : #testing }
PipeableOSProcess >> isExternalProcess [
	"Answer true if the process which I represent is an external OSProcess."

	^ true
]

{ #category : #testing }
PipeableOSProcess >> isNotYetRunning [

	^ processProxy isNotYetRunning
]

{ #category : #testing }
PipeableOSProcess >> isRunning [

	^ processProxy isRunning
]

{ #category : #accessing }
PipeableOSProcess >> keepInitialStdErrOpen [
	"True if stderr has been redirected and the handle must be kept open in case
	a predecessor in a command pipeline might have more error messages to write
	to the redirected error stream."

	^ keepInitialStdErrOpen ifNil: [keepInitialStdErrOpen _ false]
]

{ #category : #accessing }
PipeableOSProcess >> keepInitialStdErrOpen: trueOrFalse [
	"True if stderr has been redirected and the handle must be kept open in case
	a predecessor in a command pipeline might have more error messages to write
	to the redirected error stream."

	keepInitialStdErrOpen _ trueOrFalse
]

{ #category : #'shell support' }
PipeableOSProcess >> needsPrompt [
	"After evaluating the command, a shell will want to issue a prompt"

	^ true

]

{ #category : #streaming }
PipeableOSProcess >> next [
	"Answer the next character from the output stream of my external process,
	or nil if no data is available."

	| s |
	s _ accessProtect critical: [pipeFromOutput ifNotNil: [pipeFromOutput next]].
	^ s
]

{ #category : #streaming }
PipeableOSProcess >> next: count [
	"Answer up to count characters from the output stream of my external process,
	or an empty string if no data is available."

	| s |
	s _ accessProtect critical: [pipeFromOutput ifNotNil: [pipeFromOutput next: count]].
	^ s
]

{ #category : #streaming }
PipeableOSProcess >> nextFromError: count [
	"Answer up to count characters from the error stream of my external process,
	or an empty string if no data is available. All characters are routed through
	the errorPipelineStream, so that they are concatenated with any preceeding
	error message text (possibly from a preceeding process in a command pipeline)."

	accessProtect critical:
		[pipeFromError ifNotNil:
			[self addToErrorPipeline: (pipeFromError next: count)]].
	^ self errorHasBeenRedirected
		ifTrue: [nil]
		ifFalse: [self errorPipelineStream next: count]

]

{ #category : #streaming }
PipeableOSProcess >> nextPut: aCharacter [
	"Write aCharacter to the standard input stream of my external process."

	^ pipeToInput nextPut: aCharacter
]

{ #category : #streaming }
PipeableOSProcess >> nextPutAll: characters [
	"Write characters to the standard input stream of my external process."

	^ pipeToInput nextPutAll: characters
]

{ #category : #private }
PipeableOSProcess >> notifyError [
	"Display a notifier if child exited with non-zero status, or if any of its predecessors
	in a command pipeline left error text in the errorPipeline."

	| errText |
	self isComplete ifTrue: [
		errText _ self errorPipelineContents.
		(errText size ~= 0)
			ifTrue:
				[self inform:
					self programName, ' exit status ',
					processProxy exitStatus printString, ', error message: ',
					errText]
			ifFalse:
				[(processProxy exitStatus ~= 0)
					ifTrue:
						[self inform:
							self programName, ' exit status ',
							processProxy exitStatus printString]]]

]

{ #category : #'shell support' }
PipeableOSProcess >> nullStream [

	^ FileStream oldFileNamed: '/dev/null'

]

{ #category : #'command pipelines' }
PipeableOSProcess >> output [
	"Wait for external process to exit, then answer the contents of its output stream.
	This is intended as notation for completing an external command pipeline."

	"((PipeableProcess command: 'ps') | 'grep squeak' | 'cut -c16-100') output"

	^ self outputWithErrorNotifier: false

]

{ #category : #'command pipelines' }
PipeableOSProcess >> outputAndError [
	"Wait for external process to exit, then answer the contents of its output stream
	and its accumulated error stream. This is intended as notation for completing an
	external command pipeline."

	"((PipeableProcess command: 'ps') | 'NoSuchCommand; grep squeak' | 'cut -c16-100') outputAndError"

	| d s |
	d _ Delay forMilliseconds: 50.
	s _ WriteStream on: ''.
	s nextPutAll: self upToEnd.
	[processProxy runState == #complete]
		whileFalse:
			[d wait.
			s nextPutAll: self upToEnd].
	^ Array with: s contents with: self errorPipelineContents
]

{ #category : #'command pipelines' }
PipeableOSProcess >> outputWithErrorNotifier: aBoolean [
	"Wait for external process to exit, then answer the contents of its output stream.
	This is intended as notation for completing an external command pipeline."

	| d s |
	d _ Delay forMilliseconds: 50.
	s _ WriteStream on: ''.
	s nextPutAll: self upToEnd.
	[self processProxy runState == #complete]
		whileFalse:
			[d wait.
			s nextPutAll: self upToEnd].
	aBoolean ifTrue: [self notifyError].
	^ s contents
]

{ #category : #'command pipelines' }
PipeableOSProcess >> outputWithNotifier [
	"Wait for external process to exit, then answer the contents of its output stream.
	This is intended as notation for completing an external command pipeline."

	"((PipeableProcess command: 'ps') | 'grep squeak' | 'cut -c16-100; SNAFU') outputWithNotifier"
	"((PipeableProcess command: 'ps; SNAFU') | 'grep squeak' | 'cut -c16-100') outputWithNotifier"

	^ self outputWithErrorNotifier: true

]

{ #category : #accessing }
PipeableOSProcess >> pipeFromError [

	^ pipeFromError
]

{ #category : #accessing }
PipeableOSProcess >> pipeFromError: aPipeStream [

	pipeFromError _ aPipeStream
]

{ #category : #'command pipelines' }
PipeableOSProcess >> prepareOutputForPipe [
	"Output stream will be used by another process proxy as input. Set output stream
	characteristics accordingly."

	self setKeepOutputOpen; setBlockingOutput

]

{ #category : #printing }
PipeableOSProcess >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: ' for '.
	self processProxy printOn: aStream

]

{ #category : #accessing }
PipeableOSProcess >> processProxy [
	"An internal evaluation proxy, or an external OS process proxy."

	^ processProxy
]

{ #category : #accessing }
PipeableOSProcess >> processProxy: aProxy [
	"An internal evaluation proxy, or an external OS process proxy. Add myself as
	a dependent of aProxy in order to receive notification when the process run
	state changes."

	aProxy addDependent: self.
	processProxy _ aProxy
]

{ #category : #'command pipelines' }
PipeableOSProcess >> replaceOutputStreamWith: anotherStreamOrNil [
	"Sender is my successor in a command pipeline."

	processProxy isNotYetRunning
		ifFalse:
			[self error: 'too late to change the output now'].
	anotherStreamOrNil isNil
		ifFalse:
			[processProxy initialStdOut: anotherStreamOrNil.
			self pipeFromOutput: nil "Not accessible any more"]
		ifTrue:
			["Sender is my successor in a command pipeline, but does not want to use
			my standard output. Therefore, dump my standard output to the null device."
			pipeFromOutput
				ifNotNil:
					[pipeFromOutput close.
					self pipeFromOutput: nil].
			processProxy initialStdOut: self nullStream]

]

{ #category : #private }
PipeableOSProcess >> setBlockingOutput [
	"Set the pipe from the child stdout to blocking mode. This is the normal
	mode for a pipe, although for Squeak we set pipe outputs to nonblocking
	to protect ourselves from blocking the Squeak VM when reading from
	a pipe. Unix command pipelines use the normal blocking behavior, and
	let the operating system timeslice the processes to keep the rest of the
	world from hanging on a blocked read."

	(Smalltalk hasClassNamed: #OSProcess)
		ifTrue:
			[pipeFromOutput ifNotNil:
				[(Smalltalk at: #OSProcess) accessor
					setBlocking: self pipeFromOutput reader ioHandle]]

]

{ #category : #'command pipelines' }
PipeableOSProcess >> setKeepInitialStdErrOpen [
	"Send this message if stderr has been redirected and the handle must be kept open in
	case a predecessor in a command pipeline might have more error messages to write
	to the redirected error stream."

	self keepInitialStdErrOpen: true
]

{ #category : #'command pipelines' }
PipeableOSProcess >> setKeepOutputOpen [
	"When child exits, do not close the output pipe. This is for an output pipe connected to
	another process in a pipeline, where it is assumed that the next process will close
	the pipe when it is done reading from it."

	closeOutputOnExit _ false
]

{ #category : #'command pipelines' }
PipeableOSProcess >> setNonBlockingOutput [
	"Check first to make sure process is not complete because pipeFromOutput will not respond
	to #setNonBlocking after the process has exited."

	self isComplete ifFalse: [pipeFromOutput setNonBlocking]
]

{ #category : #testing }
PipeableOSProcess >> succeeded [

	^ processProxy succeeded
]

{ #category : #private }
PipeableOSProcess >> unixFileNumbers [
	"Utility method for debugging. Answer the Unix file numbers for the streams
	associated with this instance. This may be useful for debugging file handle
	leaks (files or sockets being opened but never closed).

	When a process proxy is initially set up, it will normally have six file
	numbers associated with it prior to forking the child (two file numbers each
	for stdin, stdout, and stderr). Once the child is forked, the process proxy in
	Squeak will close its copies of the child ends of the pipes, so only three of
	the original six file numbers remain visible to Squeak."

	"(PipeableOSProcess command: 'who') unixFileNumbers"

	"(PipeableOSProcess new: '/bin/ls'
		arguments: #('-ls' 'hosts' 'NOSUCHFILE') environment: nil
		descriptors: nil workingDir: '/etc'
		errorPipelineStream: ((WriteStream on: '')
		nextPutAll: 'this is the error stream '; yourself)) unixFileNumbers"

	| d accessor |
	(Smalltalk hasClassNamed: #OSProcess)
		ifTrue:
			[accessor _ (Smalltalk at: #OSProcess) accessor.
			d _ Dictionary new.
			d at: #initialStdIn put: (accessor unixFileNumber: processProxy initialStdIn ioHandle).
			d at: #initialStdOut put: (accessor unixFileNumber: processProxy initialStdOut ioHandle).
			d at: #initialStdErr put: (accessor unixFileNumber: processProxy initialStdErr ioHandle).
			d at: #'pipeToInput writer'
				put: (accessor unixFileNumber: pipeToInput writer ioHandle).
			d at: #'pipeFromOutput reader'
				put: (accessor unixFileNumber: pipeFromOutput reader ioHandle).
			d at: #'pipeFromError reader'
				put: (accessor unixFileNumber: pipeFromError reader ioHandle).
			^ d]
		ifFalse:
			[^ nil]

]

{ #category : #streaming }
PipeableOSProcess >> upToEnd [
	"Answer all available characters from the output of my external process."

	| s |
	s _ accessProtect critical:
		[pipeFromOutput isNil
			ifTrue: ['']
			ifFalse: [pipeFromOutput upToEnd]].
	^ s
]

{ #category : #updating }
PipeableOSProcess >> update: aParameter [
	"Clean up after processProxy exits. Remove myself as a dependent of processProxy,
	and close pipes."

	super update: aParameter.
	(aParameter == #runState and: [processProxy isComplete])
		ifTrue:
			[processProxy removeDependent: self.
			self closePipes]

]

{ #category : #evaluating }
PipeableOSProcess >> value [
	"Start the external process"

	| p |
	self errorHasBeenRedirected ifTrue: [self handlePrecedingError].
	p _ processProxy ifNotNil: [processProxy value].
	"The external child process now owns its own copy of the pipe handles. We no
	longer need our copies of these handles, so close the ones that are not needed."
	p ifNotNil:
		[p closeInitialStdIn.
		p closeInitialStdOut.
		self keepInitialStdErrOpen ifFalse: [p closeInitialStdErr]].
	^ p
]

{ #category : #'command pipelines' }
PipeableOSProcess >> | anotherCommandString [
	"Pipe my output to another external process, where the other external process
	executes anotherCommandString."

	"Potential timing problem: If this child process exits and completes its #update: before
	receiving the #setKeepOutputOpen message here, the pipeline will not work. It is not
	clear to me if this can actually happen in practice."

	"(PipeableProcess command: 'ps') | 'grep squeak' | 'cut -c16-100'"

	self setKeepOutputOpen.
	self setBlockingOutput.
	^ self species
			command: anotherCommandString
			pipeFrom: pipeFromOutput reader
			errorPipelineStream: self errorPipelineStream

]
