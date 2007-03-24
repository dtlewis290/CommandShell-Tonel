Class {
	#name : #ExternalCli,
	#superclass : #Object,
	#instVars : [
		'cliShell',
		'isRunning',
		'inputStream',
		'lineBuffer',
		'sigIntSema',
		'sigIntHandler'
	],
	#classVars : [
		'ExternalShell'
	],
	#category : #CommandShell
}

{ #category : #'instance creation' }
ExternalCli class >> default [

	^ ExternalShell
]

{ #category : #'class initialization' }
ExternalCli class >> initialize [
	"If OSProcess is in this  image, it important that #startup be send to
	ThisOSProcess before it is sent to ExternalCli. Therefore ensure
	that ExternalCli appears after ThisOSProcess in the system
	startup list."

	"ExternalCli initialize"

	ExternalShell ifNotNil:
		[ExternalShell stop.
		ExternalShell _ nil].
	Smalltalk
		addToStartUpList: self
		after: (Smalltalk at: #ThisOSProcess
			ifAbsent: [Smalltalk at: #SmalltalkImage
				ifAbsent: [nil]])

]

{ #category : #'instance creation' }
ExternalCli class >> new [

	self notify: self name, ': Only one instance of ExternalCli or any of its subclasses should exist in the image. Use #inSmalltalk to obtain the singleton instance.'.
	self shouldNotImplement
]

{ #category : #'instance creation' }
ExternalCli class >> onTty [
	"Answer a singleton instance. When called the first time, the shell is created
	and its evaluation loop is started. Subsequent calls answer the singleton
	instance, which may or may not be running. Use the #stop and #start messages
	to control the shell once it has been created."

	"ExternalCli onTty"

	^ ExternalShell ifNil: [ExternalShell _ self basicNew initialize].
]

{ #category : #'class initialization' }
ExternalCli class >> open [

	self start
]

{ #category : #'system startup' }
ExternalCli class >> shutDown: quitting [
	"System is going down. Stop the evaluation loop so it will not try to 
	refer to invalid IO streams when the image is restarted. If OSProcess
	is in this  image, it important that #startup be send to ThisOSProcess
	before it is sent to ExternalCli. Therefore ensure that
	ExternalCli appears after ThisOSProcess in the system startup
	list."

	quitting ifTrue: [self default ifNotNilDo: [:shell | shell shutdownInOldSession]]

]

{ #category : #'start-stop' }
ExternalCli class >> start [

	"ExternalCli start"
	"ExternalCli stop"

	^ self onTty start
]

{ #category : #'system startup' }
ExternalCli class >> startUp: resuming [

	resuming ifTrue:
		[self default ifNotNilDo: [:shell | shell startUpInNewSession]]
]

{ #category : #'start-stop' }
ExternalCli class >> stop [

	"ExternalCli stop"
	"ExternalCli start"

	^ self onTty stop
]

{ #category : #accessing }
ExternalCli >> cliShell [
	"Answer the value of cliShell"

	^ cliShell
]

{ #category : #accessing }
ExternalCli >> cliShell: anObject [
	"Set the value of cliShell"

	cliShell _ anObject
]

{ #category : #'interrupt handling' }
ExternalCli >> confirm: queryString [
	"Put up a yes/no menu with caption queryString. Answer true if the 
	response is yes, false if no."

	self flag: #FIXME. "bypass the dialog and assume true"

	self cliShell backgroundMessageQueue addLast: queryString, ' (yes)', Character lf asString.
	^ true

]

{ #category : #'input character filtering' }
ExternalCli >> confirmBeforeKilling: externalProxies [
	"Interrupt character detected, do interrupt stuff."

	| msgStrm |
	(externalProxies size > 0)
		ifTrue:
			[msgStrm _ WriteStream on: String new.
			(externalProxies size > 1)
				ifTrue: [msgStrm nextPutAll: 'kill processes']
				ifFalse: [msgStrm nextPutAll: 'kill process'].
			externalProxies do: [:e | msgStrm nextPutAll: ' ', e pid printString, ' (', e programName, ')'].
			msgStrm nextPut: $?.
			(self confirm: msgStrm contents)
				ifTrue:
					[externalProxies reverseDo: [:e | e terminate]]]

]

{ #category : #defaults }
ExternalCli >> defaultBuiltinCommands [
	"The commands which make sense in a headless tty environment"

	^ #(cd: copyToError: copyToOutput: snapshot: ttyExit: help: history: pwd: sls: type:)

]

{ #category : #'input processing' }
ExternalCli >> disableInputProcessing [

	self inputStream removeDependent: self; disableEventHandling
]

{ #category : #'interrupt handling' }
ExternalCli >> doInterruptCharHandler [
	"Interrupt character detected, do interrupt stuff."

	self confirmBeforeKilling: (self cliShell foregroundProxies
		select: [:e | e isExternalProcess]
		thenCollect: [:r | r processProxy]).
	self confirmBeforeKilling: (self cliShell backgroundProxies
		select: [:e | e isExternalProcess]
		thenCollect: [:r | r processProxy]).

]

{ #category : #'command history' }
ExternalCli >> editCommand: aString [

	self flag: #FIXME. "should interact with tty"
	^ super editCommand: aString
]

{ #category : #'input processing' }
ExternalCli >> enableInputProcessing [

	self inputStream addDependent: self; enableEventHandling
]

{ #category : #'input processing' }
ExternalCli >> handleInput: str [ 

	| rs line |
	self lineBuffer nextPutAll: str.
	[self lineBuffer contents includes: Character lf]
		whileTrue: [rs _ ReadStream on: lineBuffer contents.
			self lineBuffer: nil.
			line _ rs upTo: Character lf.
			self cliShell command: line.
			self lineBuffer nextPutAll: rs upToEnd]
]

{ #category : #'initialize-release' }
ExternalCli >> initialize [

	super initialize.
	self cliShell: (CommandShell new
			installCommands: self defaultBuiltinCommands;
			promptString: 'sqsh> ';
			addDependent: self;
			yourself).
	self setStdioStreams


]

{ #category : #accessing }
ExternalCli >> inputStream [

	^ inputStream
]

{ #category : #accessing }
ExternalCli >> inputStream: externalStream [

	inputStream _ externalStream
]

{ #category : #accessing }
ExternalCli >> isRunning [
	"True if my evaluation loop should be running. This instance variable supports
	restarting the evaluation loop after an image restart."

	^ isRunning ifNil: [isRunning _ false]

]

{ #category : #accessing }
ExternalCli >> isRunning: trueOrFalse [
	"True if my evaluation loop should be running. This instance variable supports
	restarting the evaluation loop after an image restart."

	isRunning _ trueOrFalse

]

{ #category : #accessing }
ExternalCli >> lineBuffer [
	"Answer the value of lineBuffer"

	^ lineBuffer ifNil: [lineBuffer := WriteStream on: '']
]

{ #category : #accessing }
ExternalCli >> lineBuffer: anObject [
	"Set the value of lineBuffer"

	lineBuffer _ anObject
]

{ #category : #printing }
ExternalCli >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: (self isRunning ifTrue: [' (running)'] ifFalse: [' (stopped)'])

]

{ #category : #'command prompt' }
ExternalCli >> prompt [

	self cliShell outputStream nextPutAll: self cliShell promptString.

]

{ #category : #'command prompt' }
ExternalCli >> promptString [
	"Dependents call this when restoring the prompt string display"

	self flag: #FIXME. "change the dependents to call #lastPromptString"
	^ self lastPromptString
]

{ #category : #'command prompt' }
ExternalCli >> promptTwo [

	self cliShell outputStream nextPutAll: self cliShell promptStringTwo

]

{ #category : #'initialize-release' }
ExternalCli >> release [

	self cliShell ifNotNilDo: [:shell | shell removeDependent: self].
	super release

]

{ #category : #'command prompt' }
ExternalCli >> restorePrompt [

	self flag: #FIXME. "remember last prompt string and redisplay it"
	self prompt
]

{ #category : #'initialize-release' }
ExternalCli >> setNonblockingInput [

	Smalltalk at: #OSProcess ifPresent:
		[:osp | osp thisOSProcess stdIn setNonBlocking]

]

{ #category : #'initialize-release' }
ExternalCli >> setStdioStreams [

	Smalltalk
		at: #OSProcess
		ifPresent: [:osp | 
			self inputStream: osp thisOSProcess stdIn
				asBufferedAsyncFileReadStream disableEventHandling.
			self cliShell outputStream: osp thisOSProcess stdOut.
			self cliShell errorStream: osp thisOSProcess stdErr]
]

{ #category : #'initialize-release' }
ExternalCli >> shutdownInOldSession [
	"The VM is about to shut down."

	self disableInputProcessing.
	self stopHandlingInterruptSignal

]

{ #category : #accessing }
ExternalCli >> sigIntHandler [
	"The interrupt handler process, for catching <ctl>C from the keyboard."

	^ sigIntHandler ifNil: [sigIntHandler _ self sigIntHandlerProcess]
]

{ #category : #accessing }
ExternalCli >> sigIntHandler: aProcess [
	"The interrupt handler process, for catching <ctl>C from the keyboard."

	sigIntHandler _ aProcess
]

{ #category : #'interrupt handling' }
ExternalCli >> sigIntHandlerProcess [
	"The interrupt handler process, for catching <ctl>C from the keyboard."

	^ [[self sigIntSema isNil
		ifTrue:
			[(Delay forMilliseconds: 1000) wait]
		ifFalse:
			[self sigIntSema wait.
			self doInterruptCharHandler]] repeat] fork


]

{ #category : #accessing }
ExternalCli >> sigIntSema [
	"A Smalltalk Semaphore which will be signalled when an external SIGINT signal is
	received from the operating system."

	^ sigIntSema
]

{ #category : #accessing }
ExternalCli >> sigIntSema: aSemaphore [
	"A Smalltalk Semaphore which will be signalled when an external SIGINT signal is
	received from the operating system."

	sigIntSema _ aSemaphore

]

{ #category : #'initialize-release' }
ExternalCli >> start [

	self isRunning ifTrue: [self stop].
	self setNonblockingInput.
	self isRunning: true.
	self startHandlingInterruptSignal.
	self cliShell addDependent: self.
	self cliShell outputStream cr; nextPut: Character lf.
	self cliShell notifyPrompt.
	self enableInputProcessing

]

{ #category : #'interrupt handling' }
ExternalCli >> startHandlingInterruptSignal [
	"Whenever a SIGINT is received, forward it to my sigIntSema."

	| sema |
	sigIntHandler ifNotNil: [sigIntHandler terminate. self sigIntHandler: nil].
	Smalltalk at: #OSProcess
		ifPresent:
			[:osp |
			osp accessor handlesOsSignals ifTrue:
				[sema _ osp accessor forwardSignal: osp accessor primSigIntNumber.
				sema ifNotNil: [self sigIntSema: sema].
				self sigIntHandler]]

]

{ #category : #'initialize-release' }
ExternalCli >> startUpInNewSession [
	"Image has been restarted, so the references to standard input, output
	and error are no longer valid. Reinitialize to make things right."

	self setNonblockingInput.
	self setStdioStreams.
	self isRunning
		ifTrue: [self stop; start]
]

{ #category : #'initialize-release' }
ExternalCli >> stop [

	self disableInputProcessing.
	self stopHandlingInterruptSignal.
	self cliShell ifNotNilDo: [:shell | shell removeDependent: self].
	self isRunning: false
]

{ #category : #'interrupt handling' }
ExternalCli >> stopHandlingInterruptSignal [
	"Revert to prior SIGINT handling behavior in the VM."

	Smalltalk at: #OSProcess
		ifPresent:
			[:osp |
			osp accessor handlesOsSignals
				ifTrue:
					[osp accessor restoreSignal: osp accessor primSigIntNumber].
			self sigIntSema: nil.
			self sigIntHandler terminate.
			self sigIntHandler: nil]

]

{ #category : #updating }
ExternalCli >> update: event [

	event == self inputStream
		ifTrue: [^ self handleInput: event upToEnd].
	event == #prompt	"display $PS1"
		ifTrue: [^ self prompt].
	event == #alternatePrompt	"display $PS2"
		ifTrue: [^ self promptTwo].
	event == #restorePrompt	"restore last prompt display"
		ifTrue: [self flag: #FIXME. ^ self prompt].
	event == #exit
		ifTrue: [^ self close].
	event == #clearText
		ifTrue: [^ self error: 'FIXME'].
	event == #interruptCharacter
		ifTrue: [^ self doInterruptCharHandler].
	self error: ['unexpected event']
]
