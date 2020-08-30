"
I add a keyboard hook to a TextMorphForEditView to allow filtering of keystrokes for a simple tty terminal emulator. This class in no longer required for recent Squeak, but older versions such as Squeak 3.8 require it.
"
Class {
	#name : #TtyTextMorphForEditView,
	#superclass : #TextMorphForEditView,
	#category : #'CommandShell-Morphic'
}

{ #category : #editing }
TtyTextMorphForEditView >> keyStroke: evt [

	(self editView model filterAndForwardEvent: evt)
		ifNotNil: [^ super keyStroke: evt]

]
