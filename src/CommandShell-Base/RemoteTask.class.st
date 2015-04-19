"
RemoteTask do: [2 + 2]

A RemoteTask represents a block to be evaluated in a headless Squeak child process. The results of evaluating the block are returned to the sender through a reference stream on an OS pipe. Asynchronous event notification may be used to signal completion of remote processing.

The block is evaluated in a remote headless image beginning with a clone of the sender image at the time of the message send. All side effects of evaluating the task block are localized to the remote image, and have no effect on the sending image. The result object may be an object of any complexity, such as a dictionary or array of result values.

On a unix system, the creation of child Squeak images is a relatively light weight operation, so tasks of varying degrees of complexity can be assigned to remote tasks with only moderate overhead.


"
Class {
	#name : #RemoteTask,
	#superclass : #Object,
	#instVars : [
		'task',
		'childProxy',
		'completionBlock',
		'aioHandler'
	],
	#classVars : [
		'HeadlessChild',
		'Materializer',
		'Serializer',
		'SerializingStrategy'
	],
	#category : #'CommandShell-Piping'
}

{ #category : #evaluating }
RemoteTask class >> do: aBlock [
	"Start a remote task and read the result object. The image will be blocked
	on read until completion of the remote task."

	"RemoteTask do: [2 + 2]"

	^(self new task: aBlock) value
]

{ #category : #evaluating }
RemoteTask class >> do: taskBlock whenComplete: aOneArgumentBlock [
	"Evaluate taskBlock in an image running in a separate OS process.
	Set the completion block, a block that takes result object as its single argument.
	Start remote processing with an AIO event notifier. Completion of the remote task
	will result in a changed notification from the event notifier, which will activate the
	completion block. The completion block is expected to do something useful with
	the result of the remote task."

	"n.b. Inspect the RemoteTask to prevent it being garbage collected and finalized
	before processing is complete"

	"(RemoteTask do: [2 + 2] whenComplete: [ :result | result inspect ]) inspect"
	"(RemoteTask do: [(Delay forSeconds: 3) wait. 2 + 2] whenComplete: [ :result | result inspect ]) inspect"

	^ self new task: taskBlock whenComplete: aOneArgumentBlock
]

{ #category : #finalization }
RemoteTask class >> finalize: aRemoteTask [

	aRemoteTask finalize
]

{ #category : #'class initialization' }
RemoteTask class >> headlessChild: boolean [
	"If true (default), the child process is headless. Set to false to allow debugging in
	the child Squeak image"

	"RemoteTask headlessChild:true"
	"RemoteTask headlessChild:false" "for debugging the child image"

	HeadlessChild := boolean
]

{ #category : #'class initialization' }
RemoteTask class >> initialize [
	"Initilialize the serialization strategy. Assume that if Magma is loaded in this image,
	that the Magma serializer is preferred. If Fuel is present, use that. Otherwise use the
	simple and effective default of a Squeak ReferenceStream."

	"RemoteTask initialize"

	"RemoteTask useReferenceStreamSerializer"
	"RemoteTask useFuelSerializer"
	"RemoteTask useMagmaSerializer"

	self headlessChild: true.

	(Smalltalk hasClassNamed: #MaObjectSerializer)
		ifTrue: [^self useMagmaSerializer].

	(Smalltalk hasClassNamed: #FLSerializer)
		ifTrue: [^ self useFuelSerializer].

	self useReferenceStreamSerializer.

]

{ #category : #examples }
RemoteTask class >> parallelPerformance [
	"Compare performance of three tasks run in parallel versus the equivalent serial
	processing. Results will vary depending on availability of CPU cores. On a quad core
	machine, the parallel processing should complete in well under half the time of the
	equivalent serial job."

	"RemoteTask parallelPerformance"

	| parallelExecutionTime results sema task1 task2 task3 serialExecutionTime p1 p2 p3 |
	parallelExecutionTime := Time millisecondsToRun: [
		results := Array new: 3.
		sema := Semaphore new.
		task1 := [(100000000000000000000000000000 to: 100000000000000000000000019999)
					select: [:f | f isPrime] thenCollect: [:s | s asString]].
		task2 := [(100000000000000000000000020000 to: 100000000000000000000000039999)
					select: [:f | f isPrime] thenCollect: [:s | s asString]].
		task3 := [(100000000000000000000000040000 to: 100000000000000000000000059999)
					select: [:f | f isPrime] thenCollect: [:s | s asString]].
		"n.b. assign to variables to prevent RemoteTask from being finalized"
		p1 := RemoteTask do: task1 whenComplete: [:result |  results at: 1 put: result. sema signal].
		p2 := RemoteTask do: task2 whenComplete: [:result | results at: 2 put: result. sema signal].
		p3 := RemoteTask do: task3 whenComplete: [:result |  results at: 3 put: result. sema signal].
		sema wait; wait; wait.
		results].

	serialExecutionTime :=  Time millisecondsToRun: [
		(100000000000000000000000000000 to: 100000000000000000000000019999)
					select: [:f | f isPrime] thenCollect: [:s | s asString].
		(100000000000000000000000020000 to: 100000000000000000000000039999)
					select: [:f | f isPrime] thenCollect: [:s | s asString].
		(100000000000000000000000040000 to: 100000000000000000000000059999)
					select: [:f | f isPrime] thenCollect: [:s | s asString]].

	^ { #parallelExecutionTime -> parallelExecutionTime . #serialExecutionTime -> serialExecutionTime }

]

{ #category : #examples }
RemoteTask class >> threeParallelTasks [
	"Find all primes in a range of large integers. Divide the problem into
	three tasks running the three child images, and return the results to
	the supervisory image. Answer a tasks array and a results array, where
	the results array will be populated on completion of the tasks."

	"RemoteTask threeParallelTasks"

	| p1 p2 p3 results task1 task2 task3 |
	results := Array new: 3.
	task1 := [(100000000000000000000000000000
					to: 100000000000000000000000019999)
				select: [:f | f isPrime] thenCollect: [:s | s asString]].
	task2 := [(100000000000000000000000020000
					to: 100000000000000000000000039999)
				select: [:f | f isPrime] thenCollect: [:s | s asString]].
	task3 := [(100000000000000000000000040000
					to: 100000000000000000000000059999)
				select: [:f | f isPrime] thenCollect: [:s | s asString]].
	"n.b. Assign task to a variable to prevent RemoteTask from being finalized"
	p1 := RemoteTask do: task1 whenComplete: [:result | results at: 1 put: result].
	p2 := RemoteTask do: task2 whenComplete: [:result | results at: 2 put: result].
	p3 := RemoteTask do: task3 whenComplete: [:result | results at: 3 put: result].
	^ { #tasks -> { p1 . p2 . p3 } . #results -> results }
]

{ #category : #'class initialization' }
RemoteTask class >> useFuelSerializer [
	"RemoteTask useFuelSerializer"

	Serializer := (Smalltalk at: #FLSerializer ifAbsent: [self error: 'Fuel not installed']) newDefault.
	Materializer := (Smalltalk at: #FLMaterializer) newDefault..
	^SerializingStrategy := #fuel
]

{ #category : #'class initialization' }
RemoteTask class >> useMagmaSerializer [
	"RemoteTask useMagmaSerializer"

	Serializer := (Smalltalk at: #MaObjectSerializer ifAbsent: [self error: 'Magma serializer not installed']) new.
	Materializer := Serializer.
	^SerializingStrategy := #magma
]

{ #category : #'class initialization' }
RemoteTask class >> useReferenceStreamSerializer [
	"RemoteTask useReferenceStreamSerializer"

	Serializer := (Smalltalk at: #ReferenceStream).
	Materializer := Serializer.
	^SerializingStrategy := #referenceStream
]

{ #category : #finalization }
RemoteTask >> finalize [
	"If garbage collected before remote processing is complete, the AIO
	handler process should be terminated and the external process should
	be stopped. When evaluating a #do:whenComplete: a reference should
	be maintained to the RemoteTask in order to avoid this finalization."

	aioHandler ifNotNilDo: [:aio | aio close].
	childProxy ifNotNilDo: [:child | child terminate]
]

{ #category : #serializing }
RemoteTask >> getResult [
	"Materialize the result, reading serialized data from standard input"

	SerializingStrategy = #referenceStream
		ifTrue: [^(Materializer on: childProxy pipeFromOutput reader) next].

	SerializingStrategy = #fuel
		ifTrue: [^(Materializer materializeFrom: childProxy pipeFromOutput reader binary) root].

	SerializingStrategy = #magma
		ifTrue: [^Materializer objectFromStream: childProxy pipeFromOutput reader].

	self error: 'undefined strategy ', SerializingStrategy asString

]

{ #category : #serializing }
RemoteTask >> put: result [
	"Serialize the result and write to standard output"

	SerializingStrategy = #referenceStream
		ifTrue: [ ^ (Serializer on: OSProcess thisOSProcess stdOut) nextPut: result].

	SerializingStrategy = #fuel
		ifTrue: [ ^ Serializer serialize: result on: OSProcess thisOSProcess stdOut binary].

	SerializingStrategy = #magma
		ifTrue: [ ^Serializer object: result toStream: OSProcess thisOSProcess stdOut].

	self error: 'undefined strategy ', SerializingStrategy asString

]

{ #category : #finalization }
RemoteTask >> registerForFinalization [
	
	self toFinalizeSend: #finalize:
		to: self class
		with: self copy

]

{ #category : #evaluating }
RemoteTask >> result [
	"Answer the result of a previously started task. The child Squeak sends one
	result object back to its parent Squeak before exiting."

	^self getResult

]

{ #category : #evaluating }
RemoteTask >> start [
	"Fork a headless child Squeak to evaluate my task."

	| childBlock result |

	self registerForFinalization.

	"Create block to be evaluated in a Squeak child process."
	childBlock := ["First set standard input to blocking. This avoids a delay to wait for
		data to be available, but note that it is dangerous to do this unless you
		are certain that you know in advance that the correct number of characters
		will be available on the input. If this is not the case, then the VM will block
		on the read and lock up the child squeak process."
		result := [self task value]
					on: Exception
					do: [:e |
						HeadlessChild ifFalse: [ e halt; resume ].
						result := 'remote task execution failed: ', e printString].
		OSProcess thisOSProcess stdIn setBlocking.
		self put: result.
		OSProcess thisOSProcess stdOut flush; close].
	"Fork a child Squeak that will evaluate the childBlock then exit"
	childProxy := PipeableOSProcess
					forkSqueakAndDoThenQuit: childBlock
					errorPipelineStream: InternalPipe nonBlockingPipe
					headless: HeadlessChild
					bufferedOutput: false
					outputNotifier: aioHandler

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
RemoteTask >> task: taskBlock whenComplete: aOneArgumentBlock [
	"Evaluate taskBlock in an image running in a separate OS process.
	Set the completion block, a block that takes result object as its single argument.
	Start remote processing with an AIO event notifier. Completion of the remote task
	will result in a changed notification from the event notifier, which will activate the
	completion block. The completion block is expected to do something useful with
	the result of the remote task."

	"n.b. Inspect the RemoteTask to prevent it being garbage collected and finalized
	before processing is complete"

	"(RemoteTask new task: [2 + 2] whenComplete: [ :result | result inspect]) inspect"
	"(RemoteTask new task: [(Delay forSeconds: 3) wait. 2 + 2] whenComplete: [ :result | result inspect]) inspect"

	task := taskBlock.
	completionBlock := aOneArgumentBlock.
	aioHandler ifNotNil: [aioHandler close].
	aioHandler := AioEventHandler new.
	aioHandler addDependent: self.
	self start

]

{ #category : #updating }
RemoteTask >> update: anObject [
	"An event handler has indicated availability of data on the pipe from
	the remote process. Begin reading data until the entire result object
	is received. The remote process will exit when complete, but possibly
	not until data has been read from the pipe, as it may block on write
	until the pipe has been serviced."

	(anObject isKindOf: AioEventHandler)
		ifTrue: [[completionBlock
						ifNotNil: [completionBlock value: self result]]
					ensure: [anObject close]]
]

{ #category : #evaluating }
RemoteTask >> value [
	"Start a remote task and read the result object. The child Squeak sends one
	result object back to its parent Squeak before exiting."

	"(RemoteTask new task: [2 + 2]) value"

	self start.
	^self result

]
