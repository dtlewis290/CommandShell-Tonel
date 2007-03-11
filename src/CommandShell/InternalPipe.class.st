"
I am a first-in, first-out queue with streaming behavior. I behave similarly to an OSPipe,
but am implemented in the Smalltalk image rather than with external OS pipes. I can
behave either as a blocking pipe or as a nonblocking pipe, similar to an OS pipe with
its reader end set in blocking or nonblocking mode.
"
Class {
	#name : #InternalPipe,
	#superclass : #Stream,
	#instVars : [
		'queue',
		'writerClosed',
		'nonBlockingMode'
	],
	#category : #CommandShell
}

{ #category : #'instance creation' }
InternalPipe class >> blockingPipe [

	"InternalPipe blockingPipe"

	^ super basicNew initialize setBlocking

]

{ #category : #'instance creation' }
InternalPipe class >> new [

	"InternalPipe new"

	^ self blockingPipe
]

{ #category : #'instance creation' }
InternalPipe class >> nonBlockingPipe [

	"InternalPipe nonBlockingPipe"

	^ super basicNew initialize setNonBlocking

]

{ #category : #examples }
InternalPipe class >> testPipe [

	"InternalPipe testPipe inspect"

	| pipe result |
	pipe _ self new.
	pipe nextPutAll: 'string to send through an InternalPipe'.
	result _ pipe upToEnd.
	pipe close.
	^ result

]

{ #category : #testing }
InternalPipe >> atEnd [
	"Answer whether the receiver can access any more objects."

	^ self writerClosed and: [queue size == 0]

]

{ #category : #finalization }
InternalPipe >> close [

	self closeWriter; closeReader
]

{ #category : #finalization }
InternalPipe >> closeReader [
	"Nothing to do. This is for OSPipe compatibility."

]

{ #category : #finalization }
InternalPipe >> closeWriter [
	"Set the writerClosed flag, and add a trailing nil to the pipe to mimic the
	behaviour of an external pipe which blocks until the writer end is closed.
	Writing a trailing nil the the queue has the side effect of waking up any
	process which is blocked waiting on the queue, which will receive the nil
	as an indication that the pipe has been closed."

	self writerClosed: true.
	self nextPut: nil
]

{ #category : #testing }
InternalPipe >> closed [

	^ self writerClosed
]

{ #category : #accessing }
InternalPipe >> contents [
	"Answer contents of the pipe, and return the contents to the pipe so it can still be read."

	"InternalPipe new nextPutAll: 'hello'; contents"

	| s |
	s _ self next: queue size.
	self nextPutAll: s.
	^ s
]

{ #category : #'character writing' }
InternalPipe >> cr [
	"Append a return character to the receiver."

	self queue nextPut: Character cr
]

{ #category : #'initialize-release' }
InternalPipe >> initialize [

	self queue

]

{ #category : #accessing }
InternalPipe >> next [
	"Answer the next object accessible by the receiver."

	(self nonBlockingMode and: [queue size == 0])
		ifTrue: [^ nil]
		ifFalse: [^ queue next]

]

{ #category : #accessing }
InternalPipe >> next: anInteger [ 
	"Answer the next anInteger elements of my collection."

	| strm c |
	strm _ WriteStream on: ''.
	(1 to: anInteger) do:
		[:index |
		self atEnd
			ifTrue: [^ strm contents]
			ifFalse:
				[(c _ self next) ifNil: [^ strm contents].
				strm nextPut: c]].
	^ strm contents

]

{ #category : #accessing }
InternalPipe >> nextPut: anObject [ 
	"Insert the argument, anObject, as the next object accessible by the 
	receiver. Answer anObject."

	^ queue nextPut: anObject
]

{ #category : #accessing }
InternalPipe >> nextPutAll: aCollection [ 
	"Append the elements of aCollection to the sequence of objects accessible 
	by the receiver. Answer aCollection."

	aCollection do: [:e | queue nextPut: e]

]

{ #category : #accessing }
InternalPipe >> nonBlockingMode [

	^ nonBlockingMode ifNil: [nonBlockingMode _ false]

]

{ #category : #accessing }
InternalPipe >> nonBlockingMode: trueOrFalse [

	nonBlockingMode _ trueOrFalse

]

{ #category : #accessing }
InternalPipe >> peek [

	^ queue peek

]

{ #category : #accessing }
InternalPipe >> queue [

	^ queue ifNil: [queue _ SharedQueue new]

]

{ #category : #'initialize-release' }
InternalPipe >> setBlocking [
	"For compatibility with OSPipe"

	self nonBlockingMode: false
]

{ #category : #'initialize-release' }
InternalPipe >> setNonBlocking [
	"For compatibility with OSPipe"

	self nonBlockingMode: true
]

{ #category : #accessing }
InternalPipe >> size [
	"An InternalPipe may contain a trailing nil if it has been closed. This should
	not be counted as part of the pipe size, so use #contents to determine the size
	after stripping any trailing nil."

	"InternalPipe new nextPutAll: 'hello'; size"

	^ self closed
		ifTrue: [self contents size]
		ifFalse: [self queue size]

]

{ #category : #accessing }
InternalPipe >> upToEnd [
	"Answer the remaining elements in the pipe"

	| strm c |
	strm _ WriteStream on: ''.
	[self atEnd] whileFalse:
		[c _ self next.
		c isNil
			ifTrue: [^ strm contents]
			ifFalse: [strm nextPut: c]].
	^ strm contents
]

{ #category : #accessing }
InternalPipe >> writerClosed [

	^ writerClosed ifNil: [writerClosed _ false]

]

{ #category : #accessing }
InternalPipe >> writerClosed: trueOrFalse [

	writerClosed _ trueOrFalse

]
