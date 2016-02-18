"
On some platforms it is possible to use OSProcess to read and write the standard input, output and error streams. In that case, ExternalCommandShell allows Squeak to be used as a traditional text mode command shell.

When used in a headless Squeak image, ExternalCommandShell behaves like a traditional Unix command shell, except that it has the ability to evaluate Smalltalk expressions as well as other programs and commands. On a Unix system running a Squeak shell in a headless image, the Smalltalk display can be opened by entering the command ""UnixProcess recapitate"" at the Squeak shell prompt.

ExternalCommandShell has one instance, which is accessible as ""ExternalCommandShell inSmalltalk"". The shell can be stopped with ""ExternalCommandShell stop"" and restarted with ""ExternalCommandShell start"". If the shell is running when Squeak is shut down, it will be automatically be restarted when the image is restarted.

"
Class {
	#name : #ExternalCommandShell,
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
	#category : #'CommandShell-UI'
}

{ #category : #'instance creation' }
ExternalCommandShell class >> default [

	^ ExternalShell
]

{ #category : #'class initialization' }
ExternalCommandShell class >> initialize [
	"If OSProcess is in this  image, it important that #startup be send to
	ThisOSProcess before it is sent to ExternalCommandShell. Therefore ensure
	that ExternalCommandShell appears after ThisOSProcess in the system
	startup list."

	"ExternalCommandShell initialize"

	ExternalShell
		ifNotNil: [ ExternalShell stop.
			ExternalShell := nil ].
	(SystemVersion current perform: #highestUpdate) >= 50558
		ifTrue:
			[ (Smalltalk at: #SessionManager) default perform: #registerToolClassNamed: with: self ]
		ifFalse: [ Smalltalk addToStartUpList: self ]
]

{ #category : #'instance creation' }
ExternalCommandShell class >> new [

	self notify: self name, ': Only one instance of ExternalCommandShell or any of its subclasses should exist in the image. Use #inSmalltalk to obtain the singleton instance.'.
	self shouldNotImplement
]

{ #category : #'instance creation' }
ExternalCommandShell class >> onTty [
	"Answer a singleton instance. When called the first time, the shell is created
	and its evaluation loop is started. Subsequent calls answer the singleton
	instance, which may or may not be running. Use the #stop and #start messages
	to control the shell once it has been created."

	"ExternalCommandShell onTty"

	^ ExternalShell ifNil: [ExternalShell := self basicNew initialize].
]

{ #category : #'class initialization' }
ExternalCommandShell class >> open [

	self start
]

{ #category : #'system startup' }
ExternalCommandShell class >> shutDown: quitting [
	"System is going down. Stop input processing so we will not try to 
	refer to invalid IO streams when the image is restarted. If OSProcess
	is in this  image, it important that #startup be send to ThisOSProcess
	before it is sent to ExternalCommandShell. Therefore ensure that
	ExternalCommandShell appears after ThisOSProcess in the system startup
	list."

	| shell |
	quitting
		ifTrue: [(shell := self default)
			ifNotNil: [shell shutdownInOldSession]]

]

{ #category : #'start-stop' }
ExternalCommandShell class >> start [

	"ExternalCommandShell start"
	"ExternalCommandShell stop"

	^ self onTty start
]

{ #category : #'system startup' }
ExternalCommandShell class >> startUp: resuming [

	| shell |
	resuming ifTrue:
		[(shell := self default)
			ifNotNil: [shell startUpInNewSession]]
]

{ #category : #'start-stop' }
ExternalCommandShell class >> stop [

	"ExternalCommandShell stop"
	"ExternalCommandShell start"

	^ self onTty stop
]

{ #category : #accessing }
ExternalCommandShell >> cliShell [
	"Answer the value of cliShell"

	^ cliShell
]

{ #category : #accessing }
ExternalCommandShell >> cliShell: anObject [
	"Set the value of cliShell"

	cliShell := anObject
]

{ #category : #'interrupt handling' }
ExternalCommandShell >> confirm: queryString [
	"Put up a yes/no menu with caption queryString. Answer true if the 
	response is yes, false if no."

	self flag: #FIXME. "bypass the dialog and assume true"

	self cliShell backgroundMessageQueue addLast: queryString, ' (yes)', Character lf asString.
	^ true

]

{ #category : #'input character filtering' }
ExternalCommandShell >> confirmBeforeKilling: externalProxies [
	"Interrupt character detected, do interrupt stuff."

	| msgStrm |
	(externalProxies size > 0)
		ifTrue:
			[msgStrm := WriteStream on: String new.
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
ExternalCommandShell >> defaultBuiltinCommands [
	"The commands which make sense in a headless tty environment"

	^ #(cd: copyToError: copyToOutput: snapshot: ttyExit: help: history: pwd: sls: type:)

]

{ #category : #'input processing' }
ExternalCommandShell >> disableInputProcessing [

	self inputStream removeDependent: self; disableEventHandling
]

{ #category : #'interrupt handling' }
ExternalCommandShell >> doInterruptCharHandler [
	"Interrupt character detected, do interrupt stuff."

	self confirmBeforeKilling: (self cliShell foregroundProxies
		select: [:e | e isExternalProcess]
		thenCollect: [:r | r processProxy]).
	self confirmBeforeKilling: (self cliShell backgroundProxies
		select: [:e | e isExternalProcess]
		thenCollect: [:r | r processProxy]).

]

{ #category : #'command history' }
ExternalCommandShell >> editCommand: aString [

	self flag: #FIXME. "should interact with tty"
	^ super editCommand: aString
]

{ #category : #'input processing' }
ExternalCommandShell >> enableInputProcessing [

	self inputStream addDependent: self; enableEventHandling
]

{ #category : #'input processing' }
ExternalCommandShell >> handleInput: str [ 

	| rs line |
	self lineBuffer nextPutAll: str.
	[self lineBuffer contents includes: Character lf]
		whileTrue: [rs := ReadStream on: lineBuffer contents.
			self lineBuffer: nil.
			line := rs upTo: Character lf.
			self cliShell command: line echo: false.
			self lineBuffer nextPutAll: rs upToEnd]
]

{ #category : #'initialize-release' }
ExternalCommandShell >> initialize [

	super initialize.
	self cliShell: (CommandShell new
			installCommands: self defaultBuiltinCommands;
			promptString: 'sqsh> ';
			addDependent: self;
			yourself).
	self setStdioStreams


]

{ #category : #accessing }
ExternalCommandShell >> inputStream [

	^ inputStream
]

{ #category : #accessing }
ExternalCommandShell >> inputStream: externalStream [

	inputStream := externalStream
]

{ #category : #accessing }
ExternalCommandShell >> isRunning [
	"True if my evaluation loop should be running. This instance variable supports
	restarting the evaluation loop after an image restart."

	^ isRunning ifNil: [isRunning := false]

]

{ #category : #accessing }
ExternalCommandShell >> isRunning: trueOrFalse [
	"True if my evaluation loop should be running. This instance variable supports
	restarting the evaluation loop after an image restart."

	isRunning := trueOrFalse

]

{ #category : #accessing }
ExternalCommandShell >> lineBuffer [
	"Answer the value of lineBuffer"

	^ lineBuffer ifNil: [lineBuffer := WriteStream on: String new]
]

{ #category : #accessing }
ExternalCommandShell >> lineBuffer: anObject [
	"Set the value of lineBuffer"

	lineBuffer := anObject
]

{ #category : #printing }
ExternalCommandShell >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: (self isRunning ifTrue: [' (running)'] ifFalse: [' (stopped)'])

]

{ #category : #'command prompt' }
ExternalCommandShell >> prompt [

	self cliShell outputStream nextPutAll: self cliShell promptString.

]

{ #category : #'command prompt' }
ExternalCommandShell >> promptString [
	"Dependents call this when restoring the prompt string display"

	self flag: #FIXME. "change the dependents to call #lastPromptString"
	^ self lastPromptString
]

{ #category : #'command prompt' }
ExternalCommandShell >> promptTwo [

	self cliShell outputStream nextPutAll: self cliShell promptStringTwo

]

{ #category : #'initialize-release' }
ExternalCommandShell >> release [

	cliShell ifNotNil: [cliShell removeDependent: self].
	super release

]

{ #category : #'command prompt' }
ExternalCommandShell >> restorePrompt [

	self flag: #FIXME. "remember last prompt string and redisplay it"
	self prompt
]

{ #category : #'initialize-release' }
ExternalCommandShell >> setNonblockingInput [

	Smalltalk at: #OSProcess ifPresent:
		[:osp | osp thisOSProcess stdIn setNonBlocking]

]

{ #category : #'initialize-release' }
ExternalCommandShell >> setStdioStreams [

	Smalltalk
		at: #OSProcess
		ifPresent: [:osp | 
			self inputStream: osp thisOSProcess stdIn
				asBufferedAsyncFileReadStream disableEventHandling.
			self cliShell outputStream: osp thisOSProcess stdOut.
			self cliShell errorStream: osp thisOSProcess stdErr]
]

{ #category : #'initialize-release' }
ExternalCommandShell >> shutdownInOldSession [
	"The VM is about to shut down."

	self disableInputProcessing.
	self stopHandlingInterruptSignal

]

{ #category : #accessing }
ExternalCommandShell >> sigIntHandler [
	"The interrupt handler process, for catching <ctl>C from the keyboard."

	^ sigIntHandler ifNil: [sigIntHandler := self sigIntHandlerProcess]
]

{ #category : #accessing }
ExternalCommandShell >> sigIntHandler: aProcess [
	"The interrupt handler process, for catching <ctl>C from the keyboard."

	sigIntHandler := aProcess
]

{ #category : #'interrupt handling' }
ExternalCommandShell >> sigIntHandlerProcess [
	"The interrupt handler process, for catching <ctl>C from the keyboard."

	^ [[self sigIntSema isNil
		ifTrue:
			[(Delay forMilliseconds: 1000) wait]
		ifFalse:
			[self sigIntSema wait.
			self doInterruptCharHandler]] repeat] fork


]

{ #category : #accessing }
ExternalCommandShell >> sigIntSema [
	"A Smalltalk Semaphore which will be signalled when an external SIGINT signal is
	received from the operating system."

	^ sigIntSema
]

{ #category : #accessing }
ExternalCommandShell >> sigIntSema: aSemaphore [
	"A Smalltalk Semaphore which will be signalled when an external SIGINT signal is
	received from the operating system."

	sigIntSema := aSemaphore

]

{ #category : #'initialize-release' }
ExternalCommandShell >> start [

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
ExternalCommandShell >> startHandlingInterruptSignal [
	"Whenever a SIGINT is received, forward it to my sigIntSema."

	| sema |
	sigIntHandler ifNotNil: [sigIntHandler terminate. self sigIntHandler: nil].
	Smalltalk at: #OSProcess
		ifPresent:
			[:osp |
			osp accessor handlesOsSignals ifTrue:
				[sema := osp accessor forwardSignal: osp accessor primSigIntNumber.
				sema ifNotNil: [self sigIntSema: sema].
				self sigIntHandler]]

]

{ #category : #'initialize-release' }
ExternalCommandShell >> startUpInNewSession [
	"Image has been restarted, so the references to standard input, output
	and error are no longer valid. Reinitialize to make things right."

	self setNonblockingInput.
	self setStdioStreams.
	self isRunning
		ifTrue: [self stop; start]
]

{ #category : #'initialize-release' }
ExternalCommandShell >> stop [

	self disableInputProcessing.
	self stopHandlingInterruptSignal.
	cliShell ifNotNil: [cliShell removeDependent: self].
	self isRunning: false
]

{ #category : #'interrupt handling' }
ExternalCommandShell >> stopHandlingInterruptSignal [
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
ExternalCommandShell >> update: event [

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
	"Treat anything other than the symbols above as a string to be displayed on
	the command line in the view"
	self show: event asString; cr.

]
