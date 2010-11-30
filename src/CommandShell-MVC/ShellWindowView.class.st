"
I am a simple teletype shell session view, providing a view on an instance of CommandShell.
"
Class {
	#name : #ShellWindowView,
	#superclass : #PluggableTextView,
	#category : #'CommandShell-MVC'
}

{ #category : #initialization }
ShellWindowView >> defaultControllerClass [ 

	^ TtyPluggableTextController

]

{ #category : #initialization }
ShellWindowView >> initialize [

	super initialize.
	self controller acceptOnCr: true
]

{ #category : #testing }
ShellWindowView >> isCollapsed [
	"Gross hack for starting up a new window. I don't understand why I did this. Aack! Pfft!"

	^ true
]

{ #category : #initialization }
ShellWindowView >> on: anObject text: getTextSel accept: setTextSel readSelection: getSelectionSel menu: getMenuSel [

	super on: anObject text: getTextSel accept: setTextSel readSelection: getSelectionSel menu: getMenuSel.
	self model prompt

]

{ #category : #updating }
ShellWindowView >> update: something [

	(something == #doCommand)
		ifTrue:
			[^ controller accept].
	(something == #clear)
		ifTrue:
			[^ self changeText: Text new].
	(something == #exit)
		ifTrue:
			[self topView controller
				addDeferredUIMessage:
					[controller controlTerminate.
					self topView controller closeAndUnschedule.
					ScheduledControllers restore]].
	^ super update: something

]
