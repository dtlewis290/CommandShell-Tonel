"
CommandShellTranscript is a user interface for a ComandShell. It behaves like a simple teletype text terminal.
"
Class {
	#name : #CommandShellTranscript,
	#superclass : #WriteStream,
	#instVars : [
		'cliShell',
		'lastPromptString',
		'activeController'
	],
	#category : #CommandShell
}

{ #category : #'instance creation' }
CommandShellTranscript class >> commandShell: cliShell [

	| ttyDisplay |
	ttyDisplay := self new cliShell: cliShell.
	cliShell outputStream: ttyDisplay; errorStream: ttyDisplay.
	cliShell addDependent: ttyDisplay.
	^ ttyDisplay

]

{ #category : #defaults }
CommandShellTranscript class >> defaultWindowName [

	^ 'Squeak Shell'
]

{ #category : #'instance creation' }
CommandShellTranscript class >> new [

	^ (self on: (String new: 1000)) initialize
]

{ #category : #'instance creation' }
CommandShellTranscript class >> open [
	"CommandShell open"

	^ self new open
]

{ #category : #'instance creation' }
CommandShellTranscript class >> openLabel: aString [

	"CommandShell openLabel: self defaultWindowName"

	^ self new openLabel: aString

]

{ #category : #'window color' }
CommandShellTranscript class >> windowColorSpecification [
	"Answer a WindowColorSpec object that declares my preference"

	^ WindowColorSpec
		classSymbol: self name
		wording: 'Squeak Shell'
		brightColor: (Color lightGray lighter paler)
		pastelColor: (Color lightGray lighter lighter paler paler)
		helpMessage: 'CommandShell window for evaluating Smalltalk and OS commands'
]

{ #category : #accessing }
CommandShellTranscript >> activeController [
	"In Morphic, alway nil. In MVC, the controller that most recently invoked
	a command."

	^ activeController
]

{ #category : #accessing }
CommandShellTranscript >> activeController: aController [
	"In Morphic, alway nil. In MVC, the controller that most recently invoked
	a command."

	activeController _ aController
]

{ #category : #'stream extensions' }
CommandShellTranscript >> bs [
	self position > 0 ifTrue: [^ self skip: -1].
	self changed: #bs
]

{ #category : #accessing }
CommandShellTranscript >> characterLimit [
	"Tell the views how much to retain on screen"
	^ 20000
]

{ #category : #'stream extensions' }
CommandShellTranscript >> clear [
	"Clear all characters and redisplay the view"
	self changed: #clearText.
	self reset
]

{ #category : #accessing }
CommandShellTranscript >> cliShell [
	"Answer the value of cliShell"

	^ cliShell
]

{ #category : #accessing }
CommandShellTranscript >> cliShell: commandShell [
	"Set the value of cliShell"

	cliShell _ commandShell
]

{ #category : #'initialize-release' }
CommandShellTranscript >> close [

	super close.
	self changed: #exit
]

{ #category : #'model protocol' }
CommandShellTranscript >> codePaneMenu: aMenu shifted: shifted [
	"Note that unless we override perform:orSendTo:, PluggableTextController will respond
	to all menu items"

	^ StringHolder basicNew codePaneMenu: aMenu shifted: shifted

]

{ #category : #'input character filtering' }
CommandShellTranscript >> confirmBeforeKilling: externalProxies [
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

{ #category : #'input character filtering' }
CommandShellTranscript >> doInterruptCharHandler [
	"Interrupt character detected, do interrupt stuff."

	self confirmBeforeKilling: (self cliShell foregroundProxies
		select: [:e | e isExternalProcess]
		thenCollect: [:r | r processProxy]).
	self confirmBeforeKilling: (self cliShell backgroundProxies
		select: [:e | e isExternalProcess]
		thenCollect: [:r | r processProxy]).

]

{ #category : #'stream extensions' }
CommandShellTranscript >> endEntry [
	"Display all the characters since the last endEntry, and reset the stream"
	self changed: #appendEntry.
	self reset
]

{ #category : #'input character filtering' }
CommandShellTranscript >> filterAndForward: aCharacter [
	"Filter aCharacter, taking special action if needed. If a child process is active,
	forward aCharacter to the child and answer nil. Otherwise answer aCharacter."

	^ self cliShell filterAndForward: aCharacter
]

{ #category : #'stream extensions' }
CommandShellTranscript >> flush [
	self endEntry
]

{ #category : #accessing }
CommandShellTranscript >> keyboardConnector [

	^ self cliShell keyboardConnector
]

{ #category : #'model protocol' }
CommandShellTranscript >> labelString [

	| directoryString |
	directoryString _ self cliShell workingDirectory.
	directoryString isEmpty ifTrue: [directoryString _ self cliShell shellSyntax nullDirectoryString].
	^ self class defaultWindowName, ': ', directoryString

]

{ #category : #accessing }
CommandShellTranscript >> lastPromptString [
	"Answer the value of lastPromptString"

	^ lastPromptString ifNil: [lastPromptString := self cliShell promptString]
]

{ #category : #accessing }
CommandShellTranscript >> lastPromptString: anObject [
	"Set the value of lastPromptString"

	lastPromptString _ anObject
]

{ #category : #'stream extensions' }
CommandShellTranscript >> nextPut: anObject [ 

	self cliShell scheduleToEvaluate:
		[super nextPut: anObject]
]

{ #category : #'stream extensions' }
CommandShellTranscript >> nextPutAll: characters [
	"Convert line terminators to cr. Note that #nextPut: does not do this conversion."

	self cliShell scheduleToEvaluate:
		[characters isEmpty ifFalse:
			[super nextPutAll: (characters copyReplaceAll: String lf with: String cr).
			self flush]]
]

{ #category : #'initialize-release' }
CommandShellTranscript >> open [

	^ self openLabel: self class defaultWindowName
]

{ #category : #'initialize-release' }
CommandShellTranscript >> openAsMorphLabel: labelString [ 
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
CommandShellTranscript >> openLabel: aString [ 
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
	topView controller addDeferredUIMessage:
		[self changed: #relabel.
		self prompt].
	topView controller open.

]

{ #category : #'stream extensions' }
CommandShellTranscript >> pastEndPut: anObject [
	"If the stream reaches its limit, just output the contents and reset."
	self endEntry.
	^ self nextPut: anObject
]

{ #category : #'model protocol' }
CommandShellTranscript >> perform: selector orSendTo: otherTarget [
	"Selector was just chosen from a menu by a user.  If can respond, then
	perform it on myself. If not, send it to otherTarget, presumably the
	editPane from which the menu was invoked."

	(self respondsTo: selector)
		ifTrue: [^ self perform: selector]
		ifFalse: [^ otherTarget perform: selector]
]

{ #category : #evaluation }
CommandShellTranscript >> processCommand: aCommandString [
	"Evaluate aCommandString in a separate Smalltalk process. This permits the
	user interface to remain responsive."

	^ self cliShell processCommand: aCommandString

]

{ #category : #'command prompt' }
CommandShellTranscript >> prompt [

	self cliShell scheduleToEvaluate:
		[self show: self cliShell promptString.
		self restoreSelectionMarker]
]

{ #category : #'command prompt' }
CommandShellTranscript >> promptString [
	"Dependents call this when restoring the prompt string display"

	self flag: #FIXME. "change the dependents to call #lastPromptString"
	^ self lastPromptString
]

{ #category : #'command prompt' }
CommandShellTranscript >> promptTwo [

	self show: self cliShell promptStringTwo.
	self restoreSelectionMarker
]

{ #category : #'command prompt' }
CommandShellTranscript >> restorePrompt [

	self flag: #FIXME. "remember last prompt string and redisplay it"
	self prompt
]

{ #category : #'command prompt' }
CommandShellTranscript >> restoreSelectionMarker [
	"Restore selection marker in MVC"

	| c |
	Smalltalk isMorphic
		ifFalse:
			[c _ self activeController.
			self cliShell scheduleToEvaluate: [c initializeSelection] fixTemps]

]

{ #category : #'stream extensions' }
CommandShellTranscript >> show: anObject [  "TextCollector compatibility"
	self nextPutAll: anObject asString; endEntry
]

{ #category : #updating }
CommandShellTranscript >> update: event [

	event == #prompt	"display $PS1"
		ifTrue: [^ self prompt].
	event == #alternatePrompt	"display $PS2"
		ifTrue: [^ self promptTwo].
	event == #restorePrompt	"restore last prompt display"
		ifTrue: [self flag: #FIXME. ^ self prompt].
	event == #exit
		ifTrue: [^ self close].
	event == #clearText
		ifTrue: [^ self clear; restorePrompt].
	event == #interruptCharacter
		ifTrue: [^ self doInterruptCharHandler].
	event == #relabel
		ifTrue: [^ self changed: event].
	self error: ['unexpected event']
]
