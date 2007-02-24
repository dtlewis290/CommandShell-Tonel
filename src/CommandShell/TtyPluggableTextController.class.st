"
I add keyboard hooks to a PluggableTextController to allow filtering of keystrokes for a simple tty terminal emulator.
"
Class {
	#name : #TtyPluggableTextController,
	#superclass : #PluggableTextController,
	#instVars : [
		'acceptOnCr',
		'callbackQueue',
		'closed',
		'readSyncSemaphore'
	],
	#category : #CommandShell
}

{ #category : #'menu messages' }
TtyPluggableTextController >> accept [
	"Evaluate command in a separate process. The separate process will
	send #addDeferredUIMessage: to generate a new prompt when complete."

	self model
		activeController: self;
		cr;
		flush;
		processCommand: self commandLineInput asString
]

{ #category : #accessing }
TtyPluggableTextController >> acceptOnCr [
	"If true, notify my view to accept whenever a <cr> is input"

	acceptOnCr ifNil: [acceptOnCr _ false].
	^ acceptOnCr
]

{ #category : #accessing }
TtyPluggableTextController >> acceptOnCr: trueOrFalse [
	"If true, notify my view to accept whenever a <cr> is input"

	acceptOnCr _ trueOrFalse
]

{ #category : #callbacks }
TtyPluggableTextController >> addDeferredUIMessage: aBlock [
	"Enqueue aBlock for later execution in my control loop."

	self callbackQueue nextPut: aBlock
]

{ #category : #accessing }
TtyPluggableTextController >> callbackQueue [
	"A queue of blocks to be evaluated. Asynchronously executing processes
	can place a block in this queue, and the block will later be evaluated
	in my control loop."

	^ callbackQueue ifNil: [callbackQueue _ SharedQueue new]
]

{ #category : #accessing }
TtyPluggableTextController >> closed [
	"True after user enters an 'exit' command"

	closed ifNil: [closed _ false].
	^ closed

]

{ #category : #accessing }
TtyPluggableTextController >> closed: trueOrFalse [
	"True after user enters an 'exit' command"

	closed _ trueOrFalse

]

{ #category : #'command input' }
TtyPluggableTextController >> commandLineInput [

	^ (self text copyFrom: self positionAfterPromptString to: self text size) asString.

]

{ #category : #'control defaults' }
TtyPluggableTextController >> controlActivity [

	[self callbackQueue isEmpty]
		whileFalse:
			[callbackQueue next value].
	^ super controlActivity
]

{ #category : #'typing support' }
TtyPluggableTextController >> dispatchOnCharacter: char with: typeAheadStream [
	"Carry out the action associated with this character, if any.
	Type-ahead is passed so some routines can flush or use it."

	char ifNil: [^ char].
	(((char == Character cr) and: [self acceptOnCr]) and: [model keyboardConnector isNil])
		ifTrue:
			[sensor keyboard.  "consume enter key".
			self accept.
			ScheduledControllers searchForActiveController].
	(model filterAndForward: char) isNil
		ifTrue:
			[sensor keyboard.  "consume enter key".
			^ true]
		ifFalse:
			[^ super dispatchOnCharacter: char with: typeAheadStream]

]

{ #category : #'command input' }
TtyPluggableTextController >> positionAfterPromptString [
	"Answer the index of the first character after the last prompt string in my text. If
	not found, then assume that the contents of the text are all intended to be command
	input."

	(1 to: (self text size - model promptString size))
		reverseDo: [:i |
			((self text findString: model promptString startingAt: i) ~= 0)
				ifTrue: [^ i + model promptString size]].
	^ 0

]

{ #category : #'control defaults' }
TtyPluggableTextController >> startUp [

	self closed ifFalse: [^ super startUp]
]
