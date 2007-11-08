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
	#category : #'CommandShell-Piping'
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
	pipe := self new.
	pipe nextPutAll: 'string to send through an InternalPipe'.
	pipe closeWriter.
	result := pipe upToEnd.
	pipe close.
	^ result

]

{ #category : #finalization }
InternalPipe >> addDummyNilAsEndOfFileIndicatorForBlockingPipe [
	"And add a trailing nil to the pipe to mimic the behaviour of an external pipe
	which blocks until the writer end is closed. Writing a trailing nil the the queue
	has the side effect of waking up any process which is blocked waiting on the
	queue, which will receive the nil as an indication that the pipe has been closed.
	FIXME: This is almost certainly a Bad Idea, so it is encapsulated in its own method."

	self isBlocking ifTrue: [queue nextPut: nil]

]

{ #category : #testing }
InternalPipe >> atEnd [
	"Answer whether the receiver can access any more objects. A nonblocking
	pipe with writer end closed which answers nil is considered to be at end.
	See InternalPipe>>closeWriter. Yes, it is ugly to have a pipe which cannot
	pass a nil object, but this is intended to mimic the behavior of an external
	OS pipe in nonblocking mode."

	^ self writerClosed and:
		[self isBlocking
			ifTrue:
				[(queue size == 0) or:
					[(queue size == 1) and:
						[(queue nextPut: queue next) isNil]]]
			ifFalse:
				[queue size == 0]]

]

{ #category : #testing }
InternalPipe >> atEndOfFile [
	"Answer whether the receiver is at its end based on the result of
	the last read operation. For compatibility with ExternalPipe."

	^ self atEnd

]

{ #category : #accessing }
InternalPipe >> basicNext [
	"Answer the next object accessible by the receiver."

	self nonBlockingMode
		ifFalse:
			[^ queue next]
		ifTrue:
			[queue isEmpty ifTrue: [^ nil] ifFalse: [^ queue next]]

]

{ #category : #accessing }
InternalPipe >> basicNextPut: anObject [ 
	"Insert the argument, anObject, as the next object accessible by the 
	receiver. Answer anObject."

	^ queue nextPut: anObject
]

{ #category : #finalization }
InternalPipe >> close [

	self closeWriter; closeReader
]

{ #category : #finalization }
InternalPipe >> closeReader [
	"Protocol compatibility with OSPipe. No further reads are possible after
	closing the reader, therefore any dependents and events may be released.
	Nothing actually is done, except to release dependents and events."

	self release

]

{ #category : #finalization }
InternalPipe >> closeWriter [
	"Set the writerClosed flag, and add a trailing nil to the pipe to mimic the
	behaviour of an external pipe which blocks until the writer end is closed.
	Writing a trailing nil the the queue has the side effect of waking up any
	process which is blocked waiting on the queue, which will receive the nil
	as an indication that the pipe has been closed."

	self writerClosed ifFalse:
		[self writerClosed: true.
		self addDummyNilAsEndOfFileIndicatorForBlockingPipe.
		self notifyDataReady	"in case someone is waiting on the pipe output"]


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
	s := self next: queue size.
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

{ #category : #testing }
InternalPipe >> isBlocking [
	"Answer true if reader end is set to blocking mode."

	^ self nonBlockingMode not
]

{ #category : #testing }
InternalPipe >> isPipe [

	^ true

]

{ #category : #accessing }
InternalPipe >> next [
	"Answer the next object accessible by the receiver."

	^ self basicNext

]

{ #category : #accessing }
InternalPipe >> next: anInteger [ 
	"Answer the next anInteger elements of my collection."

	| strm c |
	strm := WriteStream on: ''.
	(1 to: anInteger) do: [:index |
		self atEnd
			ifTrue: [^ strm contents]
			ifFalse: [(c := self basicNext) ifNil: [^ strm contents].
					strm nextPut: c]].
	^ strm contents

]

{ #category : #accessing }
InternalPipe >> nextPut: anObject [ 
	"Insert the argument, anObject, as the next object accessible by the 
	receiver. Answer anObject."

	| result |
	result := queue nextPut: anObject.
	self notifyDataReady.
	Processor yield.
	^ result

]

{ #category : #accessing }
InternalPipe >> nextPutAll: aCollection [ 
	"Append the elements of aCollection to the sequence of objects accessible 
	by the receiver. Answer aCollection."

	| result |
	result := aCollection do: [:e | queue nextPut: e].
	self notifyDataReady.
	Processor yield.
	^ result

]

{ #category : #accessing }
InternalPipe >> nonBlockingMode [

	^ nonBlockingMode ifNil: [nonBlockingMode := false]

]

{ #category : #accessing }
InternalPipe >> nonBlockingMode: trueOrFalse [

	nonBlockingMode := trueOrFalse

]

{ #category : #'event driven reader' }
InternalPipe >> notifyDataReady [
	"Whenever new data becomes available, notify any dependents. This method
	exists only to document the event generation mechanism, which is intended
	to be compatible with events generated by an OSPipe."

	self changed

]

{ #category : #accessing }
InternalPipe >> peek [

	^ queue peek

]

{ #category : #accessing }
InternalPipe >> queue [

	^ queue ifNil: [queue := SharedQueue new]

]

{ #category : #'initialize-release' }
InternalPipe >> setBlocking [
	"For compatibility with OSPipe"

	self nonBlockingMode: false
]

{ #category : #'event driven reader' }
InternalPipe >> setBufferedReader [
	"An InternalPipe behaves like an OSPipe with a buffered reader, and is
	capable of generating events when data is available. Answer true to
	indicate that this is the case."

	^ true

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
	strm := WriteStream on: ''.
	[self atEnd] whileFalse:
		[c := self next.
		c isNil
			ifTrue: [^ strm contents]
			ifFalse: [strm nextPut: c]].
	^ strm contents
]

{ #category : #accessing }
InternalPipe >> upToEndOfFile [
	"For compatibility with external pipes"

	^ self upToEnd

]

{ #category : #accessing }
InternalPipe >> writerClosed [

	^ writerClosed ifNil: [writerClosed := false]

]

{ #category : #accessing }
InternalPipe >> writerClosed: trueOrFalse [

	writerClosed := trueOrFalse

]
