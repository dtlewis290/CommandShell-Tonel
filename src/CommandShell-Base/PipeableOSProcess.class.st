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
		'pipeFromError',
		'processProxy',
		'keepInitialStdOutOpen',
		'keepInitialStdErrOpen',
		'accessProtect'
	],
	#category : #'CommandShell-Piping'
}

{ #category : #examples }
PipeableOSProcess class >> addTwoPlusTwoInChildSqueak [
	"Fork a headless child Squeak. Send three objects to the child, and read one object
	returned from the child. The child Squeak uses the three objects to compute a result,
	which it sends back to its parent Squeak before exiting."

	"PipeableOSProcess addTwoPlusTwoInChildSqueak"

	| childBlock in out rcv op param result childProxy writer sum s inputStream |
	"Create block to be evaluated in a Squeak child process."
	childBlock := ["First set standard input to blocking. This avoids a delay to wait for
		data to be available, but note that it is dangerous to do this unless you
		are certain that you know in advance that the correct number of characters
		will be available on the input. If this is not the case, then the VM will block
		on the read and lock up the child squeak process."
		OSProcess thisOSProcess stdIn setBlocking.
		in := ReferenceStream on: OSProcess thisOSProcess stdIn.
		out := ReferenceStream on: OSProcess thisOSProcess stdOut.
		"read three objects"
		rcv := in next.
		op := in next.
		param := in next.
		"add two plus two"
		result := rcv perform: op with: param.
		"answer the result"
		out nextPut: result].
	"Fork a child Squeak that will evaluate the childBlock then exit"
	childProxy := PipeableOSProcess forkHeadlessSqueakAndDoThenQuit: childBlock.
	"Write three objects to the child Squeak process"
	writer := ReferenceStream on: childProxy pipeToInput writer.
	writer nextPut: 2.
	writer nextPut: #+.
	writer nextPut: 2.
	"Read the result object from the child Squeak process"
	s := RWBinaryOrTextStream with: childProxy pipeFromOutput upToEndOfFile.
	s reset.
	inputStream := ReferenceStream on: s.
	sum := inputStream next.
	"show result of 2 + 2 evaluated in the child Squeak"
	self inform: '2 + 2 equals ', sum asString.
	^ sum

]

{ #category : #utility }
PipeableOSProcess class >> bash [
	"Start a Gnu bash command interpreter (enhanced Unix shell)"

	"self bash"
	"self bash exec: 'ls'; exec: 'who'; close; upToEnd"

	self externalProxyClass ifNotNilDo:
		[:proxyClass | ^ self command: proxyClass bashShellPath].
	^ self notify: 'OSProcess not available'

]

{ #category : #utility }
PipeableOSProcess class >> canAccessOSProcess [
	"True if OSProcess is in the image and if the OSProcess plugin is functioning properly"

	"self canAccessOSProcess"

	| osp |
	^ (osp := Smalltalk at: #OSProcess ifAbsent: []) notNil and: [osp accessor canAccessSystem]

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
PipeableOSProcess class >> command: aString environment: anEnvironmentDictionary workingDir: pathString input: inputStream output: outputStream error: errorStream errorPipelineStream: anErrorWriteStream [

	"(PipeableOSProcess command: 'ls -l hosts NOSUCHFILE' environment: nil workingDir: '/etc' input: nil output: nil error: nil errorPipelineStream: (InternalPipe nonBlockingPipe nextPutAll: 'this is the error stream '; yourself)) output"

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

	"(PipeableOSProcess command: 'ls -l hosts NOSUCHFILE' environment: nil workingDir: '/etc' input: nil output: nil error: nil errorPipelineStream: (InternalPipe nonBlockingPipe nextPutAll: 'this is the error stream '; yourself) shellSyntax: nil) output"

	| nameAndArgs proxyClass |
	nameAndArgs := aSyntaxProcessor isNil
		ifTrue:
			[(proxyClass := self externalProxyClass) isNil
				ifTrue:
					[Array with: aString with: Array new]
				ifFalse:
					[Array
						with: proxyClass defaultShellPath
						with: (Array with: '-c' with: aString)]]
		ifFalse:
			[aSyntaxProcessor
				programNameAndArgumentsFrom: aString
				inDirectoryPath: pathString
				findExecutable: true].
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
PipeableOSProcess class >> commandNoEvaluate: aString environment: anEnvironmentDictionary workingDir: pathString input: inputStream output: outputStream error: errorStream errorPipelineStream: anErrorWriteStream shellSyntax: aSyntaxProcessor [
	"Set up the command but do not actually fork the child process."

	"PipeableOSProcess commandNoEvaluate: 'ls -l hosts NOSUCHFILE' environment: nil workingDir: '/etc' input: nil output: nil error: nil errorPipelineStream: (InternalPipe nonBlockingPipe nextPutAll: 'this is the error stream '; yourself) shellSyntax: nil"

	| nameAndArgs proxyClass |
	nameAndArgs := aSyntaxProcessor isNil
		ifTrue:
			[(proxyClass := self externalProxyClass) isNil
				ifTrue:
					[Array with: aString with: Array new]
				ifFalse:
					[Array
						with: proxyClass defaultShellPath
						with: (Array with: '-c' with: aString)]]
		ifFalse:
			[aSyntaxProcessor
				programNameAndArgumentsFrom: aString
				inDirectoryPath: pathString
				findExecutable: true].
	^ nameAndArgs ifNotNil:
		[self new: (nameAndArgs at: 1)
			arguments: (nameAndArgs at: 2)
			environment: anEnvironmentDictionary
			descriptors: (Array with: inputStream with: outputStream with: errorStream)
			workingDir: pathString
			errorPipelineStream: anErrorWriteStream]


]

{ #category : #'process proxy classes' }
PipeableOSProcess class >> externalProxyClass [

	"self externalProxyClass"

	^ Smalltalk at: #ExternalOSProcess ifPresent: [:eosp | eosp concreteClass]

]

{ #category : #'instance creation' }
PipeableOSProcess class >> forkAndExec: executableFile arguments: arrayOfStrings environment: stringDictionary descriptors: arrayOf3Streams workingDir: pathString errorPipelineStream: anErrorStream [
	"Run a program in an external OS process, and answer an instance of myself
	which represents the external process."

	"PipeableOSProcess forkAndExec: '/bin/ls' arguments: #('-ls' 'hosts' 'NOSUCHFILE') environment: nil descriptors: nil workingDir: '/etc' errorPipelineStream: (InternalPipe nonBlockingPipe nextPutAll: 'this is the error stream '; yourself)"

	^ self canAccessOSProcess
		ifTrue:
			[(self new: executableFile
			arguments: arrayOfStrings
			environment: stringDictionary
			descriptors: arrayOf3Streams
			workingDir: pathString
			errorPipelineStream: anErrorStream) value; yourself]
		ifFalse:
			[self notify: 'OSProcess not available or OSProcess plugin not functioning']

]

{ #category : #'instance creation' }
PipeableOSProcess class >> forkHeadlessSqueakAndDoThenQuit: aBlock [
	"Start a new headless Squeak running in a child OS process. The new instance is a
	clone of this image except for the return value of this method. It does not reload the
	image file from disk. The child image evaluates aBlock."

	"| child |
	child := PipeableOSProcess forkHeadlessSqueakAndDoThenQuit:
		[OSProcess thisOSProcess stdOut
			nextPutAll: 'hello from headless Squeak child ',
				OSProcess thisOSProcess pid asString].
	child upToEndOfFile"
	
	^ self forkSqueakAndDoThenQuit: aBlock
		errorPipelineStream: InternalPipe nonBlockingPipe
		headless: true

]

{ #category : #'instance creation' }
PipeableOSProcess class >> forkSqueakAndDoThenQuit: aBlock [
	"Start a new instance of Squeak running in a child OS process. The new instance is a
	clone of this image except for the return value of this method. It does not reload the
	image file from disk. The child image evaluates aBlock."

	"PipeableOSProcess forkSqueakAndDoThenQuit:
		[Object inform: 'Hi, I am the child Squeak process. Click OK to exit the child Squeak.']"
	
	^ self forkSqueakAndDoThenQuit: aBlock
		errorPipelineStream: InternalPipe nonBlockingPipe
		headless: false


]

{ #category : #'instance creation' }
PipeableOSProcess class >> forkSqueakAndDoThenQuit: aBlock errorPipelineStream: anErrorStream headless: headless [
	"Start a new instance of Squeak running in a child OS process. The new instance is a
	clone of this image except for the return value of this method. It does not reload the
	image file from disk. The child image evaluates aBlock."

	| pp proc parentVmProcess blockWithRedirection |
	pp := super new.
	pp createPipes.
	pp pipeFromOutput setBufferedReader.
	blockWithRedirection := [
		pp pipeToInput reader setNonBlocking.
		OSProcess thisOSProcess redirectStdInTo: pp pipeToInput reader.
		OSProcess thisOSProcess redirectStdOutTo: pp pipeFromOutput writer.
		OSProcess thisOSProcess redirectStdErrTo: pp pipeFromError writer.
		aBlock value].	
	parentVmProcess := OSProcess thisOSProcess.
	proc := headless
				ifTrue: [parentVmProcess forkHeadlessSqueakAndDoThenQuit: blockWithRedirection]
				ifFalse: [parentVmProcess forkSqueakAndDoThenQuit: blockWithRedirection].
	proc pid = parentVmProcess pid
		ifTrue: ["child Squeak - this branch is never reached"]
		ifFalse: ["parent Squeak - set the child Squeak as the process proxy"
			pp errorPipelineStream: anErrorStream.
			pp initialize.
			^ pp processProxy: proc]

]

{ #category : #'instance creation' }
PipeableOSProcess class >> new: executableFile arguments: arrayOfStrings environment: stringDictionary descriptors: arrayOf3Streams workingDir: pathString errorPipelineStream: anErrorStream [
	"Prepare to run a program in an external OS process, and answer an instance of
	myself which will represent the external process."

	"PipeableOSProcess new: '/bin/ls' arguments: #('-ls' 'hosts' 'NOSUCHFILE') environment: nil descriptors: nil workingDir: '/etc' errorPipelineStream: (InternalPipe nonBlockingPipe nextPutAll: 'this is the error stream '; yourself)"

	"PipeableOSProcess new: 'sol' arguments: nil environment: nil descriptors: nil workingDir: nil errorPipelineStream: (InternalPipe nonBlockingPipe nextPutAll: 'this is the error stream '; yourself)"

	| pp proc s |
	pp := super new.
	proc := self externalProxyClass ifNotNilDo:
		[:proxyClass |
		proxyClass
			programName: executableFile
			arguments: arrayOfStrings
			initialEnvironment: stringDictionary].
	proc ifNil: [^ self notify: 'OSProcess not available'].
	arrayOf3Streams isNil
		ifTrue:
			[pp createPipes.
			proc initialStdIn: pp pipeToInput reader.
			proc initialStdOut: pp pipeFromOutput writer.
			proc initialStdErr: pp pipeFromError writer]
		ifFalse:
			[(s := (arrayOf3Streams at: 1)) isNil
				ifTrue:
					[pp createInputPipe.
					proc initialStdIn: pp pipeToInput reader]
				ifFalse:
					[proc initialStdIn: s].
			(s := (arrayOf3Streams at: 2)) isNil
				ifTrue:
					[pp createOutputPipe.
					proc initialStdOut: pp pipeFromOutput writer]
				ifFalse:
					[proc initialStdOut: s].
			(s := (arrayOf3Streams at: 3)) isNil
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

	self externalProxyClass ifNotNilDo:
		[:proxyClass | 
		^ self
			forkAndExec: proxyClass remoteShellPath
			arguments: (Array with: remoteSystemName with: 'sh')
			environment: nil
			descriptors: nil
			workingDir: nil
			errorPipelineStream: nil].
	^ self notify: 'OSProcess not available'



]

{ #category : #examples }
PipeableOSProcess class >> remoteShellExample: remoteUnixHostName [
	"Start a shell on another computer using rsh, and answer the the output
	of some commands on the remote host. You must have security access to
	the remote system in order for this to work."

	"PipeableOSProcess remoteShellExample: 'minnow.cc.gatech.edu'"
	"PipeableOSProcess remoteShellExample: 'micron'"
	"PipeableOSProcess remoteShellExample: 'localhost'"

	| rsh output |
	rsh :=  self remoteShell: remoteUnixHostName.
	rsh exec: 'echo remote host name is '.
	rsh exec: 'hostname'.
	rsh exec: 'exit'.
	output := rsh output.
	rsh close.
	rsh succeeded
		ifTrue: [self notify: output]
		ifFalse: [self notify: 'remote shell failed with error message: ', rsh errorUpToEnd].
	^ rsh

]

{ #category : #utility }
PipeableOSProcess class >> shell [
	"Start a Unix shell"

	"self shell"
	"self shell exec: 'ls'; exec: 'who'; close; upToEnd"

	self externalProxyClass ifNotNilDo:
		[:proxyClass | ^ self command: proxyClass defaultShellPath].
	^ self notify: 'OSProcess not available'

]

{ #category : #examples }
PipeableOSProcess class >> tkExample [
	"Start an interactive Tk shell and send it some commands to display a user interface."

	"PipeableOSProcess tkExample"

	| wish |
	wish :=  self wish.
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

	"self waitForCommand: 'echo sleeping...; sleep 3; echo I just slept for three seconds'"

	| proc d |
	d := Delay forMilliseconds: 50.
	proc := self command: aCommandString.
	proc ifNil: [self class noAccessorAvailable].
	[proc isComplete] whileFalse: [d wait].
	^ proc

]

{ #category : #utility }
PipeableOSProcess class >> wish [
	"Start a Tk/Tcl command interpreter"

	"self shell"

	self externalProxyClass ifNotNilDo:
		[:proxyClass | ^ self command: proxyClass tkShellPath].
	^ self notify: 'OSProcess not available'

]

{ #category : #utility }
PipeableOSProcess class >> xon: remoteSystem command: aCommandString [
	"Convenience method for running an X program on a remote system and displaying its window
	on the local display."

	"self xon: 'someRemoteHost' command: 'xeyes'"

	^ self command: 'xon ', remoteSystem, ' ', aCommandString

]

{ #category : #utility }
PipeableOSProcess class >> xterm: aCommandString [
	"Convenience method for running a command in an external xterm window"

	"self xterm: 'top -d 2'"

	^ self command: 'xterm -T ''', aCommandString, ''' -e ', aCommandString
]

{ #category : #examples }
PipeableOSProcess class >> xtermExample [
	"Open an external xterm window running a 'top' command. Works on unix
	X window platforms."

	"self xtermExample"

	^ self xterm: 'top -d 2'
]

{ #category : #'command pipelines - private' }
PipeableOSProcess >> addToErrorPipeline: aString [

	(aString isNil or: [aString isEmpty])
		ifFalse: [self errorPipelineStream nextPutAll: aString]
]

{ #category : #testing }
PipeableOSProcess >> atEnd [
	"True after processing is complete and all available data has been read 
	from the output pipe."

	^ pipeFromOutput isNil or: [pipeFromOutput atEnd]

]

{ #category : #'initialize - release' }
PipeableOSProcess >> closeOutput [

	self pipeFromOutput ifNotNilDo: [:p | p removeDependent: self; close]

]

{ #category : #'initialize - release' }
PipeableOSProcess >> closePipeInputs [
	"Close all pipe endpoints not used after process termination."

	super closePipeInputs.
	pipeFromError ifNotNil: [pipeFromError closeWriter]

]

{ #category : #'initialize - release' }
PipeableOSProcess >> closePipes [
	"Replace the output and error pipe streams with internal pipes, and close
	all input and output pipes."

	| output out err |
	self keepInitialStdOutOpen
		ifTrue:
			["The pipe stream will be closed by the next process in the command pipeline"
			pipeFromOutput ifNotNilDo: [:p | p triggerDataReady]]
		ifFalse:
			[(output := self pipeFromOutput)
				ifNotNil:
					[accessProtect critical:
						[self pipeFromOutput: InternalPipe new.
						out := output upToEnd.
						out isEmpty ifFalse:
							[self pipeFromOutput nextPutAll: out.
							self triggerOutputDataReady].
						self pipeFromOutput closeWriter.
						output removeDependent: self; close]]].
	(pipeFromError) ifNotNil:
		[accessProtect critical:
			[err := pipeFromError upToEnd.
			err isEmpty ifFalse:
				[self addToErrorPipeline: err.
				self triggerEvent: #errorDataReady].
			pipeFromError removeDependent: self; close]].
	self keepInitialStdErrOpen ifTrue: [self processProxy initialStdErr close].
	self pipeToInput ifNotNil: [pipeToInput close]

]

{ #category : #updating }
PipeableOSProcess >> complete [

	super complete.
	self updateErrorPipelineStreamToEndOfFile
]

{ #category : #'initialize - release' }
PipeableOSProcess >> createErrorPipe [
	"Create a pipe for the error stream from the child process."

	self pipeFromError: PipeJunction externalPipeClass nonBlockingPipe

]

{ #category : #'initialize - release' }
PipeableOSProcess >> createInputPipe [
	"Create a pipe for input to the child process."

	self pipeToInput: PipeJunction externalPipeClass blockingPipe

]

{ #category : #'initialize - release' }
PipeableOSProcess >> createOutputPipe [
	"Create a pipe for output from the child process. The pipe should later be set
	to nonBlocking mode only if necessary to provent Squeak VM deadlocks."

	self pipeFromOutput: PipeJunction externalPipeClass blockingPipe

]

{ #category : #'initialize - release' }
PipeableOSProcess >> createPipes [

	pipeToInput ifNil: [self createInputPipe].
	pipeFromOutput ifNil: [self createOutputPipe].
	pipeFromError ifNil: [self createErrorPipe]

]

{ #category : #'event handling' }
PipeableOSProcess >> enableErrorStreamTriggers [
	"Set the error stream to be event driven if possible, and answer true
	if event driven output is supported, otherwise false."

	pipeFromError ifNotNilDo: [:err | ^ err setBufferedReader].
	^ false
]

{ #category : #'event handling' }
PipeableOSProcess >> enableEventTriggers [
	"Set the output and error streams to be event driven if possible, and 
	answer true if event driven output is supported, otherwise false."

	^ self enableOutputStreamTriggers and: [self enableErrorStreamTriggers]

]

{ #category : #'command pipelines' }
PipeableOSProcess >> errorPipelineContents [

	^ self errorHasBeenRedirected
		ifTrue: ['' "stderr has been redirected to a file"]
	 	ifFalse: [self errorPipelineStream contents]
]

{ #category : #accessing }
PipeableOSProcess >> errorPipelineStream: aStream [
	"Accumulates the error output of commands in a command pipeline. Overridden
	to eliminate setting self as a dependent of the error pipeline stream."

	errorPipelineStream := aStream

]

{ #category : #streaming }
PipeableOSProcess >> errorUpToEnd [
	"Answer all available characters from the error stream of my external process."

	^ accessProtect critical: [super errorUpToEnd]

]

{ #category : #streaming }
PipeableOSProcess >> errorUpToEndOfFile [
	"Answer all available characters from the error stream. Block and
	continue reading until end of file is detected."

	self updateErrorPipelineStreamToEndOfFile.
	^ errorPipelineStream upToEnd

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

{ #category : #streaming }
PipeableOSProcess >> flush [
	"Flush output to the standard input stream of my external process."

	pipeToInput ifNotNilDo: [:p | p flush]
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
	d := Delay forMilliseconds: 200.
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

	accessProtect := Semaphore forMutualExclusion.
	^ super initialize

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

	^ keepInitialStdErrOpen ifNil: [keepInitialStdErrOpen := false]
]

{ #category : #accessing }
PipeableOSProcess >> keepInitialStdErrOpen: trueOrFalse [
	"True if stderr has been redirected and the handle must be kept open in case
	a predecessor in a command pipeline might have more error messages to write
	to the redirected error stream."

	keepInitialStdErrOpen := trueOrFalse
]

{ #category : #accessing }
PipeableOSProcess >> keepInitialStdOutOpen [
	"If false, close the output pipe when the child exits. If true, do not close the output pipe.
	This should be set true for an output pipe connected to another process in a pipeline,
	where it is assumed that the next process will close the pipe when it is done reading
	from it. Otherwise, the default behavior is to close the output pipe after transferring its
	contents to a Smalltalk stream."

	^ keepInitialStdOutOpen ifNil: [keepInitialStdOutOpen := false]

]

{ #category : #accessing }
PipeableOSProcess >> keepInitialStdOutOpen: trueOrFalse [
	"If false, close the output pipe when the child exits. If true, do not close the output pipe.
	This should be set true for an output pipe connected to another process in a pipeline,
	where it is assumed that the next process will close the pipe when it is done reading
	from it. Otherwise, the default behavior is to close the output pipe after transfering its
	contents to a Smalltalk stream."

	keepInitialStdOutOpen := trueOrFalse

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
	s := accessProtect critical: [pipeFromOutput ifNotNil: [pipeFromOutput next]].
	^ s
]

{ #category : #streaming }
PipeableOSProcess >> next: count [
	"Answer up to count characters from the output stream of my external process,
	or an empty string if no data is available."

	| s |
	s := accessProtect critical: [pipeFromOutput ifNotNil: [pipeFromOutput next: count]].
	^ s
]

{ #category : #streaming }
PipeableOSProcess >> nextFromError: count [
	"Answer up to count characters from the error stream of my external process,
	or an empty string if no data is available. All characters are routed through
	the errorPipelineStream, so that they are concatenated with any preceeding
	error message text (possibly from a preceeding process in a command pipeline)."

	self updateErrorPipelineStream.
	^ self errorHasBeenRedirected
		ifTrue: [nil]
		ifFalse: [self errorPipelineStream next: count]

]

{ #category : #private }
PipeableOSProcess >> notifyError [
	"Display a notifier if child exited with non-zero status, or if any of its predecessors
	in a command pipeline left error text in the errorPipeline."

	| errText |
	self isComplete ifTrue: [
		errText := self errorPipelineContents.
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
							self processProxy programName, ' exit status ',
							processProxy exitStatus printString]]]

]

{ #category : #'shell support' }
PipeableOSProcess >> nullStream [

	^ FileStream oldFileNamed: '/dev/null'

]

{ #category : #accessing }
PipeableOSProcess >> pipeFromError [

	^ pipeFromError
]

{ #category : #accessing }
PipeableOSProcess >> pipeFromError: aPipeStream [

	(pipeFromError := aPipeStream)
		ifNotNilDo: [:p | p addDependent: self]

]

{ #category : #testing }
PipeableOSProcess >> pipesAreEmpty [
	"True after processing is complete and all available data has been read 
	from the output pipe and the error pipe. Note: uses error handling 
	rather than testing for pipe closed to avoid race condition."

	^ (self atEndOfFile
			and: [pipeFromError isNil
					or: [pipeFromError atEndOfFile]])
		and: [errorPipelineStream atEnd]
]

{ #category : #'command pipelines - private' }
PipeableOSProcess >> prepareOutputForInternalReader [
	"Output stream will be used directly by a Smalltalk process. Set output stream
	characteristics accordingly."

	super prepareOutputForInternalReader.
	self setKeepInitialStdOutOpen.
	self pipeFromError ifNotNilDo: [:err | err setNonBlocking]

]

{ #category : #'command pipelines - private' }
PipeableOSProcess >> prepareOutputForPipe [
	"Output stream will be used by another process proxy as input. Set output stream
	characteristics accordingly."

	super prepareOutputForPipe.
	self setKeepInitialStdOutOpen; setBlockingOutput

]

{ #category : #printing }
PipeableOSProcess >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: ' on '.
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
	processProxy := aProxy
]

{ #category : #'initialize - release' }
PipeableOSProcess >> release [

	self processProxy release.
	self pipeFromError release.
	^ super release
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

{ #category : #testing }
PipeableOSProcess >> requiresNonBlockingInput [
	"A PipeJunction managed by Squeak may be subject to deadlocks associated with
	reading or writing an OSPipe. A PipeableOSProcess relies on the external operating
	system to provide process scheduling, so it will not block the Squeak VM when it
	is blocked on a read or a write."

	^ false
]

{ #category : #private }
PipeableOSProcess >> setBlockingOutput [
	"Set the pipe from the child stdout to blocking mode. This is the normal
	mode for a pipe, although for Squeak we set pipe outputs to nonblocking
	to protect ourselves from blocking the Squeak VM when reading from
	a pipe. Unix command pipelines use the normal blocking behavior, and
	let the operating system timeslice the processes to keep the rest of the
	world from hanging on a blocked read."

	Smalltalk at: #OSProcess ifPresent:
		[:osp | pipeFromOutput ifNotNil: [osp accessor setBlocking: self pipeFromOutput reader ioHandle]]

]

{ #category : #'command pipelines' }
PipeableOSProcess >> setKeepInitialStdErrOpen [
	"Send this message if stderr has been redirected and the handle must be kept open in
	case a predecessor in a command pipeline might have more error messages to write
	to the redirected error stream."

	self keepInitialStdErrOpen: true
]

{ #category : #'command pipelines' }
PipeableOSProcess >> setKeepInitialStdOutOpen [
	"When child exits, do not close the output pipe. This is for an output pipe connected to
	another process in a pipeline, where it is assumed that the next process will close
	the pipe when it is done reading from it."

	self keepInitialStdOutOpen: true
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

	| d |
	Smalltalk at: #OSProcess ifPresent:
		[:osp |
		d := Dictionary new.
		d at: #initialStdIn put: (osp accessor unixFileNumber: processProxy initialStdIn ioHandle).
		d at: #initialStdOut put: (osp accessor unixFileNumber: processProxy initialStdOut ioHandle).
		d at: #initialStdErr put: (osp accessor unixFileNumber: processProxy initialStdErr ioHandle).
		d at: #'pipeToInput writer'
			put: (osp accessor unixFileNumber: pipeToInput writer ioHandle).
		d at: #'pipeFromOutput reader'
			put: (osp accessor unixFileNumber: pipeFromOutput reader ioHandle).
		d at: #'pipeFromError reader'
			put: (osp accessor unixFileNumber: pipeFromError reader ioHandle).
		^ d].
	^ nil

]

{ #category : #streaming }
PipeableOSProcess >> upToEnd [
	"Answer all available characters from the output of my external process."

	^ accessProtect critical: [super upToEnd]

]

{ #category : #streaming }
PipeableOSProcess >> upToEndOfFile [
	"Answer all available characters from the output stream. Block and
	continue reading until end of file is detected."

	^ accessProtect critical: [super upToEndOfFile]

]

{ #category : #updating }
PipeableOSProcess >> update: aParameter [
	"Clean up after processProxy exits. Remove myself as a dependent of processProxy,
	and close pipes."

	(aParameter == pipeFromError)
		ifTrue:
			[accessProtect critical: [self addToErrorPipeline: pipeFromError upToEnd].
			^ self changed: self errorPipelineStream].

	(aParameter == #runState)
		ifTrue:
			[processProxy isComplete
				ifTrue:
					[self pipeFromError
						ifNotNilDo: [:err | self addToErrorPipeline: err upToEnd].
					self complete.
					self changed: aParameter]
				ifFalse:
					[^ self]].

	^ super update: aParameter

]

{ #category : #'event handling' }
PipeableOSProcess >> updateErrorPipelineStream [
	"Ensure that all available error output is placed into errorPipelineStream."

	accessProtect critical:
		[pipeFromError ifNotNilDo: [:err | self addToErrorPipeline: err upToEnd]].

]

{ #category : #'event handling' }
PipeableOSProcess >> updateErrorPipelineStreamToEndOfFile [
	"Move all error output up to end of file to the errorPipelineStream."

	accessProtect
		critical: [self pipeFromError
				ifNotNilDo: [:p |
					errorPipelineStream nextPutAll: p upToEndOfFile.
					p close]]
]

{ #category : #evaluating }
PipeableOSProcess >> value [
	"Start the external process"

	| p |
	self errorHasBeenRedirected ifTrue: [self handlePrecedingError].
	accessProtect critical:
		[p := processProxy ifNotNil: [processProxy value].
		"The external child process now owns its own copy of the pipe handles. We no
		longer need our copies of these handles, so close the ones that are not needed."
		p ifNotNil:
			[self keepInitialStdOutOpen ifFalse: [p closeInitialStdOut].
			self keepInitialStdErrOpen ifFalse: [p closeInitialStdErr]]]

]

{ #category : #'command pipelines' }
PipeableOSProcess >> | anotherCommandString [
	"Pipe my output to another external process, where the other external process
	executes anotherCommandString."

	"(PipeableOSProcess command: 'ps') | 'grep squeak' | 'cut -c16-100'"

	self setKeepInitialStdOutOpen.
	self setBlockingOutput.
	^ self species
			command: anotherCommandString
			pipeFrom: pipeFromOutput reader
			errorPipelineStream: self errorPipelineStream

]
