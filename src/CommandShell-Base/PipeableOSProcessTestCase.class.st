"
Tests for PipeableOSProcess. A PipeableOSProcess provides a proxy for an external OS process with stdin, stdout, and stderr pipes connected by the proxy to the external process.
"
Class {
	#name : #PipeableOSProcessTestCase,
	#superclass : #TestCase,
	#instVars : [
		'procDir'
	],
	#category : #'CommandShell-Tests'
}

{ #category : #private }
PipeableOSProcessTestCase >> isNumberOfOpenFiles: anInteger [
	"Answer true if the number of open file handles is anInteger. Wait a little
	bit if necessary to clean up stale references, but give up after a few tries."

	| loops milliseconds |
	loops := 10.
	milliseconds := 50.
	(1 to: loops)
		detect:
			[:i | (self numberOfOpenFiles == anInteger)
				ifFalse:
					[(Delay forMilliseconds: milliseconds) wait].
			self numberOfOpenFiles == anInteger]
		ifNone:
			["This causes the failure to appear as an error rather than a
			failure in the test runner. This kind of problem can be appear
			intermittently, and is different from a functional failure of
			a method."
			self error:
				self numberOfOpenFiles printString,
				' files are open, expected ', anInteger printString].
	^ self numberOfOpenFiles == anInteger

]

{ #category : #private }
PipeableOSProcessTestCase >> numberOfOpenFiles [
	"Answer the number of files currently open for this OS process. This works
	only on a system with a /proc filesystem and file descriptors located in a
	directory called /proc/<pid>/fd. On other systems, just answer 0."

	"UnixProcessTestCase new numberOfOpenFiles"

	| d |
	^ (d := self procDir) isNil
		ifTrue: [0]
		ifFalse: [d entries size]
]

{ #category : #private }
PipeableOSProcessTestCase >> procDir [
	"Assuming that we have a /proc file system as on Linux (otherwise answer nil)"

	| path d |
	^ procDir ifNil:
		[path := '/proc/' , OSProcess thisOSProcess pid printString, '/fd'.
		d := FileDirectory on: path.
		(d directoryExists: path) ifTrue: [procDir := d]]

]

{ #category : #'testing-process proxy' }
PipeableOSProcessTestCase >> testCommandEcho [

	"(PipeableOSProcessTestCase selector: #testCommandEcho) debug"

	| p result |
	p := PipeableOSProcess command: '/bin/echo this is a test'.
	result := p output.
	self assert: ('this is a test*' match: result)
]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkHeadlessSqueak [

	"(PipeableOSProcessTestCase selector: #testForkHeadlessSqueak) debug"

	| openFileCount child |
	openFileCount := self numberOfOpenFiles.
	child := PipeableOSProcess forkHeadlessSqueakAndDoThenQuit:
		[OSProcess thisOSProcess stdOut
			nextPutAll: 'hello from headless Squeak child'].
	self should: child upToEndOfFile = 'hello from headless Squeak child'.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkHeadlessSqueak2 [

	"(PipeableOSProcessTestCase selector: #testForkHeadlessSqueak2) debug"

	| openFileCount child response in |
	openFileCount := self numberOfOpenFiles.
	child := PipeableOSProcess forkHeadlessSqueakAndDoThenQuit:
		[(Delay forMilliseconds: 100) wait. "wait for data to arrive"
		in := OSProcess thisOSProcess stdIn upToEnd.
		OSProcess thisOSProcess stdOut nextPutAll: in].
	child nextPutAll: 'hello'.
	child pipeToInput close.
	response := child upToEndOfFile.
	self should: response = 'hello'.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkHeadlessSqueakReadAndWriteReferenceStream [
	"Fork a connected Squeak child. The child reads one object through a
	ReferenceStream on its standard input, and writes it to a ReferenceStream
	on its standard output. The parent Squeak reads the object through a
	ReferenceStream on the output stream of the child proxy."

	"(PipeableOSProcessTestCase selector: #testForkHeadlessSqueakReadAndWriteReferenceStream) debug"

	| openFileCount child refStream inputStream result s anObject objectStreamToChild |
	openFileCount := self numberOfOpenFiles.
	child := PipeableOSProcess forkSqueakAndDoThenQuit:
		["First set standard input to blocking. This avoids a delay to wait for
		data to be available, but note that it is dangerous to do this unless you
		are certain that you know in advance that the correct number of characters
		will be available on the input. If this is not the case, then the VM will block
		on the read and lock up the child squeak process."
		OSProcess thisOSProcess stdIn setBlocking.
		inputStream := ReferenceStream on: OSProcess thisOSProcess stdIn.
		anObject := inputStream next. "read one object expected to have been sent by parent"
		refStream := ReferenceStream on: OSProcess thisOSProcess stdOut.
		refStream nextPut: anObject "echo the object back to the parent Squeak"].
	objectStreamToChild := ReferenceStream on: child pipeToInput writer.
	objectStreamToChild nextPut: Smalltalk. "send a complex object to the child"
	s := RWBinaryOrTextStream with: child pipeFromOutput upToEndOfFile.
	s reset.
	inputStream := ReferenceStream on: s.
	result := inputStream next.
	self assert: result = Smalltalk. "another instance of the system dictionary same as original"
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkHeadlessSqueakReferenceStream [
	"Fork a connected Squeak child with no user interface. The child sends a complex
	object through a ReferenceStream on its standard output, and the parent Squeak
	reads the object through a ReferenceStream on the output stream of the child proxy."

	"(PipeableOSProcessTestCase selector: #testForkHeadlessSqueakReferenceStream) debug"

	| openFileCount child refStream inputStream result s |
	openFileCount := self numberOfOpenFiles.
	child := PipeableOSProcess forkHeadlessSqueakAndDoThenQuit:
		[refStream := ReferenceStream on: OSProcess thisOSProcess stdOut.
		refStream nextPut: Smalltalk].
	s := RWBinaryOrTextStream with: child pipeFromOutput upToEndOfFile.
	s reset.
	inputStream := ReferenceStream on: s.
	result := inputStream next.
	self assert: result = Smalltalk.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkSqueak [

	"(PipeableOSProcessTestCase selector: #testForkSqueak) debug"

	| openFileCount child response in |
	openFileCount := self numberOfOpenFiles.
	child := PipeableOSProcess forkSqueakAndDoThenQuit:
		[(Delay forMilliseconds: 100) wait. "wait for data to arrive"
		in := OSProcess thisOSProcess stdIn upToEnd.
		OSProcess thisOSProcess stdOut nextPutAll: in].
	child nextPutAll: 'hello'.
	child pipeToInput close.
	response := child upToEndOfFile.
	self should: response = 'hello'.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkSqueakReadAndWriteReferenceStream [
	"Fork a connected Squeak child. The child reads one object through a
	ReferenceStream on its standard input, and writes it to a ReferenceStream
	on its standard output. The parent Squeak reads the object through a
	ReferenceStream on the output stream of the child proxy."

	"(PipeableOSProcessTestCase selector: #testForkSqueakReadAndWriteReferenceStream) debug"

	| openFileCount child refStream inputStream result s anObject objectStreamToChild |
	openFileCount := self numberOfOpenFiles.
	child := PipeableOSProcess forkSqueakAndDoThenQuit:
		["First set standard input to blocking. This avoids a delay to wait for
		data to be available, but note that it is dangerous to do this unless you
		are certain that you know in advance that the correct number of characters
		will be available on the input. If this is not the case, then the VM will block
		on the read and lock up the child squeak process."
		OSProcess thisOSProcess stdIn setBlocking.
		inputStream := ReferenceStream on: OSProcess thisOSProcess stdIn.
		anObject := inputStream next. "read one object expected to have been sent by parent"
		refStream := ReferenceStream on: OSProcess thisOSProcess stdOut.
		refStream nextPut: anObject "echo the object back to the parent Squeak"].
	objectStreamToChild := ReferenceStream on: child pipeToInput writer.
	objectStreamToChild nextPut: Smalltalk. "send a complex object to the child"
	s := RWBinaryOrTextStream with: child pipeFromOutput upToEndOfFile.
	s reset.
	inputStream := ReferenceStream on: s.
	result := inputStream next.
	self assert: result = Smalltalk. "another instance of the system dictionary same as original"
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkSqueakReferenceStream [
	"Fork a connected Squeak child. The child sends a complex object through a
	ReferenceStream on its standard output, and the parent Squeak reads the
	object through a ReferenceStream on the output stream of the child proxy."

	"(PipeableOSProcessTestCase selector: #testForkSqueakReferenceStream) debug"

	| openFileCount child refStream inputStream result s |
	openFileCount := self numberOfOpenFiles.
	child := PipeableOSProcess forkSqueakAndDoThenQuit:
		[refStream := ReferenceStream on: OSProcess thisOSProcess stdOut.
		refStream nextPut: Smalltalk].
	s := RWBinaryOrTextStream with: child pipeFromOutput upToEndOfFile.
	s reset.
	inputStream := ReferenceStream on: s.
	result := inputStream next.
	self assert: result = Smalltalk.
	self should: [self isNumberOfOpenFiles: openFileCount]

]
