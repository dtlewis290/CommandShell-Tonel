"
I add a keyboard hook to a TextMorphForEditView to allow filtering of keystrokes for a simple tty terminal emulator.
"
Class {
	#name : #TtyTextMorphForEditView,
	#superclass : #TextMorphForEditView,
	#category : #CommandShell
}

{ #category : #editing }
TtyTextMorphForEditView >> keyStroke: evt [

	(self editView model filterAndForwardEvent: evt)
		ifNotNil: [^ super keyStroke: evt]

]
