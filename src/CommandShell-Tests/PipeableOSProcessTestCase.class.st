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

	"PipeableOSProcessTestCase new numberOfOpenFiles"

	| d |
	^ (d := self procDir) isNil
		ifTrue: [0]
		ifFalse: [(CommandShell directoryEntryNames: d) size]
]

{ #category : #private }
PipeableOSProcessTestCase >> procDir [
	"Assuming that we have a /proc file system as on Linux (otherwise answer nil)"

	| path |
	^ procDir ifNil:
		[path := '/proc/' , OSProcess thisOSProcess pid printString, '/fd'.
		(CommandShell directoryExists: path) ifTrue: [procDir := path]]

]

{ #category : #'testing-process proxy' }
PipeableOSProcessTestCase >> testCommandEcho [

	"(PipeableOSProcessTestCase selector: #testCommandEcho) debug"

	| p result |
	self shouldnt: [p := PipeableOSProcess command: '/bin/echo this is a test']
		raise: Warning.
	result := p output.
	p closePipes.
	self assert: ('this is a test*' match: result)
]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkHeadlessSqueak [

	"(PipeableOSProcessTestCase selector: #testForkHeadlessSqueak) debug"

	| openFileCount child |
	openFileCount := self numberOfOpenFiles.
	self shouldnt:
			[child := PipeableOSProcess forkHeadlessSqueakAndDoThenQuit:
				[OSProcess thisOSProcess stdOut
					nextPutAll: 'hello from headless Squeak child']]
		raise: Warning.
	self should: child upToEndOfFile = 'hello from headless Squeak child'.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkHeadlessSqueak2 [

	"(PipeableOSProcessTestCase selector: #testForkHeadlessSqueak2) debug"

	| openFileCount child response in |
	openFileCount := self numberOfOpenFiles.
	self shouldnt:
			[child := PipeableOSProcess forkHeadlessSqueakAndDoThenQuit:
				[(Delay forMilliseconds: 100) wait. "wait for data to arrive"
				in := OSProcess thisOSProcess stdIn upToEnd.
				OSProcess thisOSProcess stdOut nextPutAll: in]]
		raise: Warning.
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

	| openFileCount child refStream inputStream result s anObject objectStreamToChild rs |
	rs := Smalltalk at: #ReferenceStream.
	openFileCount := self numberOfOpenFiles.
	anObject := { 1 . 'two' . #three . { 4 } }.
	self shouldnt:
			[ | obj |
				child := PipeableOSProcess forkSqueakAndDoThenQuit:
				["First set standard input to blocking. This avoids a delay to wait for
				data to be available, but note that it is dangerous to do this unless you
				are certain that you know in advance that the correct number of characters
				will be available on the input. If this is not the case, then the VM will block
				on the read and lock up the child squeak process."
				OSProcess thisOSProcess stdIn setBlocking.
				inputStream := rs on: OSProcess thisOSProcess stdIn.
				[ obj := inputStream next. "read one object expected to have been sent by parent" ]
					on: Error
					do: [ :ex | obj := ex printString "copy back to parent process for debugging" ].
				refStream := rs on: OSProcess thisOSProcess stdOut.
				refStream nextPut: obj "echo the object back to the parent Squeak"]]
		raise: Warning.
	objectStreamToChild := rs on: child pipeToInput writer.
	objectStreamToChild nextPut: anObject; flush. "send a complex object to the child"
	s := RWBinaryOrTextStream with: child pipeFromOutput upToEndOfFile.
	s reset.
	inputStream := rs on: s.
	result := inputStream next.
	self assert: anObject equals: result. "n.b. see method comment in testCheckStdinWorksCorrectlyForReferenceStreams"
	self assert: (self isNumberOfOpenFiles: openFileCount).

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkHeadlessSqueakReferenceStream [
	"Fork a connected Squeak child with no user interface. The child sends a complex
	object through a ReferenceStream on its standard output, and the parent Squeak
	reads the object through a ReferenceStream on the output stream of the child proxy."

	"(PipeableOSProcessTestCase selector: #testForkHeadlessSqueakReferenceStream) debug"

	| openFileCount anObject child refStream inputStream result s |
	openFileCount := self numberOfOpenFiles.
	anObject := { 1 . 'two' . #three . { 4 } }.
	self shouldnt:
			[child := PipeableOSProcess forkHeadlessSqueakAndDoThenQuit:
				[refStream := (Smalltalk at: #ReferenceStream) on: OSProcess thisOSProcess stdOut.
				refStream nextPut: anObject]]
		raise: Warning.
	s := RWBinaryOrTextStream with: child pipeFromOutput upToEndOfFile.
	s reset.
	inputStream := (Smalltalk at: #ReferenceStream) on: s.
	result := inputStream next.
	self assert: anObject equals: result.
	self assert: (self isNumberOfOpenFiles: openFileCount).

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkSqueak [

	"(PipeableOSProcessTestCase selector: #testForkSqueak) debug"

	| openFileCount child response in |
	openFileCount := self numberOfOpenFiles.
	self shouldnt:
			[child := PipeableOSProcess forkSqueakAndDoThenQuit:
				[in := OSProcess thisOSProcess stdIn upToEnd.
				OSProcess thisOSProcess stdOut nextPutAll: in]]
		raise: Warning.
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

	| openFileCount child refStream inputStream result s anObject objectStreamToChild rs |
	rs := Smalltalk at: #ReferenceStream.
	openFileCount := self numberOfOpenFiles.
	anObject := { 1 . 'two' . #three . { 4 } }.
	self shouldnt:
			[ | obj |
				child := PipeableOSProcess forkSqueakAndDoThenQuit:
				["First set standard input to blocking. This avoids a delay to wait for
				data to be available, but note that it is dangerous to do this unless you
				are certain that you know in advance that the correct number of characters
				will be available on the input. If this is not the case, then the VM will block
				on the read and lock up the child squeak process."
				OSProcess thisOSProcess stdIn setBlocking.
				inputStream := rs on: OSProcess thisOSProcess stdIn.
				[ obj := inputStream next. "read one object expected to have been sent by parent" ]
					on: Error
					do: [ :ex | obj := ex printString "copy back to parent process for debugging" ].
				refStream := rs on: OSProcess thisOSProcess stdOut.
				refStream nextPut: obj "echo the object back to the parent Squeak"]]
		raise: Warning.
	objectStreamToChild := rs on: child pipeToInput writer.
	objectStreamToChild nextPut: anObject; flush. "send a complex object to the child"
	s := RWBinaryOrTextStream with: child pipeFromOutput upToEndOfFile.
	s reset.
	inputStream := rs on: s.
	result := inputStream next.
	self assert: anObject equals: result. "n.b. see method comment in testCheckStdinWorksCorrectlyForReferenceStreams"
	self assert: (self isNumberOfOpenFiles: openFileCount).

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testForkSqueakReferenceStream [
	"Fork a connected Squeak child. The child sends a complex object through a
	ReferenceStream on its standard output, and the parent Squeak reads the
	object through a ReferenceStream on the output stream of the child proxy."

	"(PipeableOSProcessTestCase selector: #testForkSqueakReferenceStream) debug"

	| openFileCount anObject child refStream inputStream result s |
	openFileCount := self numberOfOpenFiles.
	anObject := { 1 . 'two' . #three . { 4 } }.
	self shouldnt:
			[child := PipeableOSProcess forkSqueakAndDoThenQuit:
				[refStream := (Smalltalk at: #ReferenceStream) on: OSProcess thisOSProcess stdOut.
				refStream nextPut: anObject]]
		raise: Warning.
	s := RWBinaryOrTextStream with: child pipeFromOutput upToEndOfFile.
	s reset.
	inputStream := (Smalltalk at: #ReferenceStream) on: s.
	result := inputStream next.
	self assert: anObject equals: result.
	self assert: (self isNumberOfOpenFiles: openFileCount).

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testStdinReadingReferenceStream [
	"Some virtual machines improperly assume that standard input is attached
	to a tty device, and are hard coded to answer at most one character when
	reading from stdin into a string or byte array. This behavior is incorrect in the
	general case of Unix processes that are expected to communicate through
	OS pipes. In particular, it breaks the ability to read seiralized objects from the
	standard input of a virtual machine process.

	The problem can be demonstrated by serialzing a single string. More complex
	object structures will fail outright when deserializing in the child process."

	"(PipeableOSProcessTestCase selector: #testStdinReadingReferenceStream) debug"

	| openFileCount child refStream inputStream result s anObject objectStreamToChild rs |
	rs := Smalltalk at: #ReferenceStream.
	openFileCount := self numberOfOpenFiles.
	anObject := 'ABCDEFG'.
	self shouldnt:
			[ | obj |
				child := PipeableOSProcess forkSqueakAndDoThenQuit:
					[OSProcess thisOSProcess stdIn setBlocking.
					inputStream := rs on: OSProcess thisOSProcess stdIn.
					[ obj := inputStream next. "read one object expected to have been sent by parent" ]
						on: Error
						do: [ :ex | obj := ex printString "copy back to parent process for debugging" ].
					refStream := rs on: OSProcess thisOSProcess stdOut.
					refStream nextPut: obj "echo the object back to the parent Squeak"] ]
		raise: Warning.
	objectStreamToChild := rs on: child pipeToInput writer.
	objectStreamToChild nextPut: anObject; flush. "send a complex object to the child"
	s := RWBinaryOrTextStream with: child pipeFromOutput upToEndOfFile.
	s reset.
	inputStream := rs on: s.
	result := inputStream next.
	self assert: anObject equals: result. "see comment above, may fail with all but first character set to null"
	self assert: (self isNumberOfOpenFiles: openFileCount).

]

{ #category : #'testing-fork squeak' }
PipeableOSProcessTestCase >> testStdinReadingString [
	"Some virtual machines improperly assume that standard input is attached
	to a tty device, and are hard coded to answer at most one character when
	reading from stdin into a string or byte array. This behavior is incorrect in the
	general case of Unix processes that are expected to communicate through
	OS pipes."

	"(PipeableOSProcessTestCase selector: #testStdinReadingString) debug"

	| openFileCount child result aString|
	openFileCount := self numberOfOpenFiles.
	aString := 'ABCDEFG'.
	self shouldnt:
			[ | obj |
				child := PipeableOSProcess forkSqueakAndDoThenQuit:
					[ OSProcess thisOSProcess stdIn setBlocking.
					[ obj := OSProcess thisOSProcess stdIn next: aString size ]
						on: Error
						do: [ :ex | obj := ex printString "copy back to parent process for debugging" ].
					OSProcess thisOSProcess stdOut nextPutAll: obj asString "echo back to the parent Squeak"] ]
		raise: Warning.
	child pipeToInput writer nextPutAll: aString; flush.
	result := child pipeFromOutput upToEndOfFile.
	self assert: aString equals: result. "see comment above, may fail with truncated string"
	self assert: (self isNumberOfOpenFiles: openFileCount).

]
