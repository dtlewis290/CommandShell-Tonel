"
RemoteTask do: [2 + 2]

A RemoteTask represents a block to be evaluated in a headless Squeak child process. The results of evaluating the block are returned to the sender through a reference stream on an OS pipe.

The block is evaluated in a remote headless image beginning with a clone of the sender image at the time of the message send. All side effects of evaluating the task block are localized to the remote image, and have no effect on the sending image. The result object may be an object of any complexity, such as a dictionary or array of result values.

On a unix system, the creation of child Squeak images is a relatively light weight operation, so tasks of varying degrees of complexity can be assigned to remote tasks with only moderate overhead.


"
Class {
	#name : #RemoteTask,
	#superclass : #Object,
	#instVars : [
		'task',
		'childProxy'
	],
	#category : #'CommandShell-Piping'
}

{ #category : #evaluating }
RemoteTask class >> do: aBlock [
	"Start a remote task and read the result object."

	"RemoteTask do: [2 + 2]"

	^(self task: aBlock) value
]

{ #category : #evaluating }
RemoteTask class >> start: aBlock [
	"Create a remote task and start evaluation. Do not read the result object."

	^(self task: aBlock) start
]

{ #category : #'instance creation' }
RemoteTask class >> task: aBlock [

	^ self new task: aBlock
]

{ #category : #evaluating }
RemoteTask >> result [
	"Answer the result of a previously started task. The child Squeak sends one
	result object back to its parent Squeak before exiting."

	| s responseObject responseStream |
	"Read the result object from the child Squeak process"
	s := RWBinaryOrTextStream with: childProxy pipeFromOutput upToEndOfFile.
	s reset.
	responseStream := ReferenceStream on: s.
	responseObject := responseStream next.
	s close.
	^ responseObject

]

{ #category : #evaluating }
RemoteTask >> start [
	"Fork a headless child Squeak to evaluate my task."

	| childBlock out result |
	"Create block to be evaluated in a Squeak child process."
	childBlock := ["First set standard input to blocking. This avoids a delay to wait for
		data to be available, but note that it is dangerous to do this unless you
		are certain that you know in advance that the correct number of characters
		will be available on the input. If this is not the case, then the VM will block
		on the read and lock up the child squeak process."
		OSProcess thisOSProcess stdIn setBlocking.
		out := ReferenceStream on: OSProcess thisOSProcess stdOut.
		result := [self task value]
					on: Exception
					do: [:e | result := 'remote task execution failed: ', e printString].
		out nextPut: result].
	"Fork a child Squeak that will evaluate the childBlock then exit"
	childProxy := PipeableOSProcess forkHeadlessSqueakAndDoThenQuit: childBlock

]

{ #category : #accessing }
RemoteTask >> task [
	"Answer the value of task"

	^ task
]

{ #category : #accessing }
RemoteTask >> task: anObject [
	"Set the value of task"

	task := anObject
]

{ #category : #evaluating }
RemoteTask >> value [
	"Start a remote task and read the result object. The child Squeak sends one
	result object back to its parent Squeak before exiting."

	"(RemoteTask task: [2 + 2]) value"

	self start.
	^self result

]
