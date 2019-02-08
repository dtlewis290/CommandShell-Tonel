"
I am a simple teletype shell session morph, providing a view on an instance of CommandShell.
"
Class {
	#name : #ShellWindowMorph,
	#superclass : #PluggableTextMorph,
	#category : #'CommandShell-Morphic'
}

{ #category : #'instance creation' }
ShellWindowMorph class >> open [
	"Open a new CommandShell, and answer the instance of ShellWindowMorph which it uses."

	"ShellWindowMorph open"

	^ CommandShell open dependents at: 2
]

{ #category : #'menu commands' }
ShellWindowMorph >> accept [

	self model cr; flush; processCommand: self commandLineInput asString echo: false

]

{ #category : #updating }
ShellWindowMorph >> appendEntry [

	| str |
	"Append the text in the model's writeStream to the editable text. "
	textMorph asText size > model characterLimit ifTrue:
		["Knock off first half of text"
		self selectInvisiblyFrom: 1 to: textMorph asText size // 2.
		self replaceSelectionWith: Text new].
	self selectInvisiblyFrom: textMorph asText size + 1 to: textMorph asText size.
	str := model contents.
	(str size > 0) ifTrue:
		[self replaceSelectionWith: (Text
			string: str
			attribute: (TextFontChange fontNumber: self textStyle defaultFontIndex)).
		self selectInvisiblyFrom: textMorph asText size + 1 to: textMorph asText size.
		model reset]


]

{ #category : #'command input' }
ShellWindowMorph >> commandLineInput [

	^ (self text copyFrom: self positionAfterPromptString to: self text size) asString.


]

{ #category : #'command input' }
ShellWindowMorph >> positionAfterPromptString [
	"Answer the index of the first character after the last prompt string in my text. If
	not found, then assume that the contents of the text are all intended to be command
	input."

	| t loc |
	t := self text.
	(1 to: (t size - model promptString size))
		reverseDo: [:i |
			((loc := t findString: model promptString startingAt: i) ~= 0)
				ifTrue: [^ loc + model promptString size]].
	^ 1

]

{ #category : #'model access' }
ShellWindowMorph >> setText: aText [
	scrollBar setValue: 0.0.
	textMorph
		ifNil: [textMorph := TtyTextMorphForEditView new
						contents: aText wrappedTo: self innerBounds width-6.
				textMorph setEditView: self.
				textMorph setTextStyle: self textStyle.
				scroller addMorph: textMorph]
		ifNotNil: [textMorph newContents: aText].
	self hasUnacceptedEdits: false.
	self setScrollDeltas.
]

{ #category : #'model access' }
ShellWindowMorph >> textStyle [
	"A fixed width font for the text morph"

	^ (TextStyle named: 'DefaultFixedTextStyle')
		ifNil: [TextStyle default]
]

{ #category : #updating }
ShellWindowMorph >> update: something [

	(something == #doCommand)
		ifTrue:
			[^ self accept].
	(something == #exit)
		ifTrue:
			[^ self owner release; delete].
	^ super update: something

]
