Class {
	#name : #RemoteTaskManager,
	#superclass : #Object,
	#instVars : [
		'pending',
		'active',
		'completed',
		'maxActive',
		'accessProtect'
	],
	#category : #'CommandShell-RemoteTask'
}

{ #category : #'instance creation' }
RemoteTaskManager class >> new: taskSize [
	^self new maxActive: taskSize
]

{ #category : #examples }
RemoteTaskManager class >> searchForPrimes [
	"Search for prime numbers in the first 100 million positive integers"

	"RemoteTaskManager searchForPrimes"

	| supervisor blocks intervals |
	supervisor := RemoteTaskManager new: 4.

	"intervals to be searched for primes"
	intervals := Array streamContents: [ :strm | | s |
		s := (1 to: 1e8) readStream.
		[ s atEnd ] whileFalse: [ strm nextPut: (s next: 10000000) ] ] .

	"blocks to be evaluated remotely"
	blocks := intervals collect: [:interval |
		[ OrderedCollection streamContents: [ :strm |
				interval do: [ :e | e isPrime ifTrue: [strm nextPut: e]]]] ].

	"submit tasks for remote evaluation"
	intervals with: blocks do: [:interval :block |
		supervisor submit: block taskIdentifier: 'seaching for primes in ', interval asString ].

	^supervisor
]

{ #category : #accessing }
RemoteTaskManager >> active [
	^active

]

{ #category : #accessing }
RemoteTaskManager >> completed [
	^completed


]

{ #category : #'initialize-release' }
RemoteTaskManager >> initialize [

	accessProtect := Mutex new.
	pending := OrderedCollection new.
	active := OrderedCollection new.
	completed := OrderedCollection new.
	self maxActive: 6.
]

{ #category : #accessing }
RemoteTaskManager >> maxActive: poolSize [
	maxActive := poolSize

]

{ #category : #accessing }
RemoteTaskManager >> pending [
	^pending

]

{ #category : #accessing }
RemoteTaskManager >> results [
	"All currently available results keyed by task"

	^ accessProtect critical: [ Dictionary withAll: completed ].
]

{ #category : #private }
RemoteTaskManager >> startReadyJobs [

	accessProtect critical: [
		[ pending isEmpty not and: [ active size < maxActive ] ]
			whileTrue: [ | task |
				task := pending removeFirst.
				active add: task.
				task start  ] ].



]

{ #category : #'job control' }
RemoteTaskManager >> submit: block taskIdentifier: anObject [

	| task |
	accessProtect critical: [
		task := RemoteTask
			new task: block
			whenComplete: nil
			taskIdentifier: anObject.
		task setCompletionBlock: [ :result |
			completed add: (active remove: task) -> result.
			self startReadyJobs ].
		pending add: task ].
	self startReadyJobs.


]
