"
I am a connector junction for input, output, and error pipelines. I obtain input from an input pipeline and, after possibly performing some kind of operation on the input objects, I send output to an output pipeline. I may also append objects onto an error pipeline.

My subclasses implement the operations on the objects which pass through a pipe junction.

In general, input pipes are connected to output pipes in a serial fashion, and error pipelines are shared by one or more instances of my subclasses.

"
Class {
	#name : #PipeJunction,
	#superclass : #Model,
	#instVars : [
		'pipeToInput',
		'pipeFromOutput',
		'errorPipelineStream'
	],
	#category : #'CommandShell-Piping'
}

{ #category : #defaults }
PipeJunction class >> externalPipeClass [
	"If external pipes are not supported, use an internal pipe instead"

	"self externalPipeClass"

	^ Smalltalk
		at: #ExternalPipe
		ifAbsent: [Smalltalk
			at: #OSPipe "Older versions of OSProcess"
			ifAbsent: [InternalPipe]]

]

{ #category : #testing }
PipeJunction >> atEnd [
	"True after processing is complete and all available data has been read from
	the output pipe."

	^ pipeFromOutput atEnd and: [self isComplete]

]

{ #category : #testing }
PipeJunction >> atEndOfFile [
	"True after processing is complete and all available data has been read
	from the output pipe. Uses feof() to test for the end of file flag, which
	will have been set by a previous read operation."

	^ pipeFromOutput isNil
		or: [pipeFromOutput atEndOfFile
				and: [self isComplete]]
]

{ #category : #testing }
PipeJunction >> canProvideOutputPipe [
	"If a subclass is not able to provide pipe output, it may answer false.
	This may happen if output has been redirected to a file."

	^ self pipeFromOutput notNil
]

{ #category : #'initialize - release' }
PipeJunction >> close [
	"Close pipe to proxy input."

	pipeToInput ifNotNil: [pipeToInput close]

]

{ #category : #'initialize - release' }
PipeJunction >> closeErrorPipeline [

	self errorPipelineStream ifNotNilDo: [:p | p close]

]

{ #category : #'initialize - release' }
PipeJunction >> closeOutput [

	self pipeFromOutput ifNotNilDo: [:p | p close]

]

{ #category : #'initialize - release' }
PipeJunction >> closePipeInputs [
	"Close all pipe endpoints not used after process termination."

	pipeToInput
		ifNotNil: [pipeToInput close].
	pipeFromOutput ifNotNil:
		[pipeFromOutput isPipe
			ifTrue: [pipeFromOutput closeWriter]
			ifFalse: [pipeFromOutput close]]

]

{ #category : #'initialize - release' }
PipeJunction >> closePipes [

	self closeOutput.
	pipeToInput ifNotNil: [pipeToInput close].
	self errorHasBeenRedirected ifTrue: [errorPipelineStream close]

]

{ #category : #'initialize - release' }
PipeJunction >> closeWriter [
	"No further input expected"

	(self pipeToInput notNil and: [pipeToInput isPipe])
		ifTrue: [pipeToInput closeWriter]

]

{ #category : #'event handling' }
PipeJunction >> complete [
	"Evaluation has been completed. Perform any necessary cleanup."

	^ self closePipeInputs

]

{ #category : #'event handling' }
PipeJunction >> enableErrorStreamTriggers [
	"Set the error stream to be event driven if possible, and answer true
	if event driven output is supported, otherwise false."

	^ false
]

{ #category : #'event handling' }
PipeJunction >> enableEventTriggers [
	"Set the output stream to be event driven if possible, and answer true if
	event driven output is supported, otherwise false. See #update: for event
	triggering logic."

	^ self enableOutputStreamTriggers

]

{ #category : #'event handling' }
PipeJunction >> enableOutputStreamTriggers [
	"Set the output stream to be event driven if possible, and answer true
	if event driven output is supported, otherwise false."

	(pipeFromOutput notNil and: [pipeFromOutput isPipe])
		ifTrue: [^ pipeFromOutput setBufferedReader]
		ifFalse: [^ false]


]

{ #category : #'initialize - release' }
PipeJunction >> ensurePipeFromOutput [
	"Make sure that an output pipe is provided."

	^ self pipeFromOutput ifNil: [self pipeFromOutput: InternalPipe new]

]

{ #category : #testing }
PipeJunction >> errorHasBeenRedirected [
	"Answer true if the error output has been redirected to an external file
	and is not available to be read as error output of a pipeline."

	^ self errorPipelineStream isPipe not

]

{ #category : #'command pipelines' }
PipeJunction >> errorPipeForNextProxy [

	^ self errorHasBeenRedirected
		ifTrue: [nil]
		ifFalse: [self errorPipelineStream]

]

{ #category : #accessing }
PipeJunction >> errorPipelineStream [
	"Accumulates the error output of commands in a command pipeline."

	errorPipelineStream isNil ifTrue: [errorPipelineStream := InternalPipe nonBlockingPipe].
	^ errorPipelineStream

]

{ #category : #accessing }
PipeJunction >> errorPipelineStream: aStream [
	"Accumulates the error output of commands in a command pipeline."

	errorPipelineStream := aStream

]

{ #category : #streaming }
PipeJunction >> errorUpToEnd [
	"Answer all available characters from my error stream."

	^ (errorPipelineStream isNil or: [self errorHasBeenRedirected])
		ifTrue: ['']
		ifFalse: [errorPipelineStream upToEnd]

]

{ #category : #streaming }
PipeJunction >> errorUpToEndOfFile [
	"Answer all available characters from the error stream. Block and
	continue reading until end of file is detected."

	^ (errorPipelineStream isNil or: [self errorHasBeenRedirected])
		ifTrue: ['']
		ifFalse: [errorPipelineStream upToEndOfFile]

]

{ #category : #streaming }
PipeJunction >> flush [
	"Flush output to the standard input stream of my external process. If no
	external process is involved, do nothing."

]

{ #category : #'event handling' }
PipeJunction >> handleRedirectedOutputOf: predecessorProxy [
	"If the output of predecessorProxy (in a pipeline) has been redirected,
	this pipe junction will not know when predecessorProxy has completed
	unless it requests notification. The pipe to input of this pipe junction should
	not be closed until predecessorProxy is complete, so close the pipe when the
	completion event occurs."

	predecessorProxy ifNotNil:
		[(predecessorProxy canProvideOutputPipe not
			and: [self inputHasBeenRedirected not]) ifTrue:
				[self pipeToInput ifNotNilDo:
					[:inputPipe |
					predecessorProxy
						when: #complete
						send: #close
						to: inputPipe writer]]]

]

{ #category : #'initialize - release' }
PipeJunction >> initialize [

	(self requiresNonBlockingInput and: [pipeToInput isKindOf: OSPipe])
		ifTrue:[pipeToInput setNonBlocking]
			

]

{ #category : #testing }
PipeJunction >> inputHasBeenRedirected [
	"Answer true if the input stream has been redirected to an external file."

	^ self pipeToInput notNil and: [pipeToInput isPipe not]

]

{ #category : #testing }
PipeJunction >> isComplete [

	^ self subclassResponsibility

]

{ #category : #testing }
PipeJunction >> isExternalProcess [
	"Answer true if the process which I represent is an external OSProcess."

	^ false
]

{ #category : #streaming }
PipeJunction >> next [

	^ pipeFromOutput next

]

{ #category : #streaming }
PipeJunction >> next: count [

	^ pipeFromOutput next: count

]

{ #category : #streaming }
PipeJunction >> nextFromError: count [
	"Answer up to count characters from the error pipeline stream, or an empty string
	if no data is available. All characters are routed through the errorPipelineStream,
	so that they are concatenated with any preceeding error message text (possibly from
	a preceeding process in a command pipeline)."

	^ errorPipelineStream next: count

]

{ #category : #streaming }
PipeJunction >> nextPut: aCharacter [
	"Write aCharacter to the standard input stream of my external process."

	^ pipeToInput nextPut: aCharacter
]

{ #category : #streaming }
PipeJunction >> nextPutAll: characters [
	"Write characters to the standard input stream of my external process."

	^ pipeToInput nextPutAll: characters
]

{ #category : #'command pipelines' }
PipeJunction >> output [
	"Wait for process completion, and answer all available output."

	"((PipeableOSProcess command: 'ps') | 'grep squeak' | 'cut -c16-100') output"

	^ (self isNotYetRunning not and: [self canProvideOutputPipe])
		ifTrue: [(self outputOn: (WriteStream on: '')) contents]
		ifFalse: ['']

]

{ #category : #'command pipelines' }
PipeJunction >> outputAndError [
	"Answer an array with output and error contents. If standard error has been
	redirected to a file, answer a null string as the error message."

	"((PipeableOSProcess command: 'ps') | 'NoSuchCommand; grep squeak' | 'cut -c16-100') outputAndError"

	| out err |
	out := self output.
	(self errorHasBeenRedirected)
		ifTrue: [err := '']
		ifFalse: [err := errorPipelineStream contents].
	^ Array with: out with: err
]

{ #category : #'command pipelines' }
PipeJunction >> outputOn: aStream [
	"Wait for process completion, writing all available output on aStream"

	| d |
	d := nil.
	[self isComplete] whileFalse:
		[(d ifNil: [d := Delay forMilliseconds: 50]) wait.
		aStream nextPutAll: self upToEnd].
	aStream nextPutAll: self upToEndOfFile.
	^ aStream

]

{ #category : #'command pipelines' }
PipeJunction >> outputPipeForNextProxy [

	^ self canProvideOutputPipe
		ifTrue: [pipeFromOutput]
		ifFalse: [nil]

]

{ #category : #accessing }
PipeJunction >> pipeFromOutput [

	^ pipeFromOutput
]

{ #category : #accessing }
PipeJunction >> pipeFromOutput: aPipeStream [

	(pipeFromOutput := aPipeStream)
		ifNotNilDo: [:p | p addDependent: self]

]

{ #category : #accessing }
PipeJunction >> pipeToInput [

	^ pipeToInput
]

{ #category : #accessing }
PipeJunction >> pipeToInput: aPipeStream [

	pipeToInput := aPipeStream
]

{ #category : #testing }
PipeJunction >> pipesAreEmpty [
	"True after processing is complete and all available data has been read 
	from the output pipe and the errorPipelineStream pipe."

	^ self atEndOfFile
		and: [self errorHasBeenRedirected
				or: [errorPipelineStream atEnd]]
]

{ #category : #'initialize - release' }
PipeJunction >> prepareOutputFor: aPipeJunction [
	"External process proxies are independent of the Smalltalk image and do
	not require event driven input. Internal proxies will prefer to request
	event notification."

	aPipeJunction isExternalProcess
		ifTrue: [self prepareOutputForPipe]
		ifFalse: [self prepareOutputForInternalReader]

]

{ #category : #'command pipelines - private' }
PipeJunction >> prepareOutputForInternalReader [
	"Output stream will be used directly by a Smalltalk process. Set output 
	stream characteristics accordingly."

	self canProvideOutputPipe
		ifTrue: [pipeFromOutput setNonBlocking].
	self enableEventTriggers
]

{ #category : #'command pipelines - private' }
PipeJunction >> prepareOutputForPipe [
	"Output stream will be used by another process proxy as input. Set output stream
	characteristics accordingly. The output stream will be owned by the next process
	in a pipeline, but the error stream is shared by all processes in the pipeline, and
	can be event driven."

	Smalltalk
		at: #AioEventHandler
		ifPresent: [:aio | aio aioPluginPresent
				ifTrue: [self enableErrorStreamTriggers]]
]

{ #category : #'initialize - release' }
PipeJunction >> release [
	"The input pipe may be released, but the output and error pipes may
	still be in use."

	self pipeToInput release.
	^ super release
]

{ #category : #'command pipelines' }
PipeJunction >> replaceOutputStreamWith: anotherStream [
	"Sender is not happy with the kind of output stream we are using. Replace
	pipeFromOutput with anotherStream, and copy the current contents of pipeFromOutput
	to the new stream."

	| oldOutputStream |
	oldOutputStream := self pipeFromOutput.
	oldOutputStream removeDependent: self. "Break old dependency"
	self pipeFromOutput: anotherStream. "Restores the dependency automatically"
	oldOutputStream ifNotNil:
		[anotherStream ifNotNil:
			[anotherStream nextPutAll: oldOutputStream contents].
		oldOutputStream close]

]

{ #category : #testing }
PipeJunction >> requiresNonBlockingInput [
	"A PipeJunction managed by Squeak may be subject to deadlocks associated with
	reading or writing an OSPipe. Answer true if the input pipe must function in
	nonBlocking mode in order to prevent deadlocks. This method exists simply to
	make the requirement explicit."

	^ true
]

{ #category : #'initialize - release' }
PipeJunction >> resetStdioStreams [
	"After an image restart, call this method to reset to the correct input, output
	and error streams if they are attached to standard input, output or error."

	Smalltalk at: #OSProcess ifPresent:
		[:osp |
		((self pipeToInput respondsTo: #isStdIn) and: [pipeToInput isStdIn])
			ifTrue: [self pipeToInput: osp thisOSProcess stdIn].
		((self pipeToInput respondsTo: #isStdOut) and: [pipeToInput isStdOut])
			ifTrue: [self pipeToInput: osp thisOSProcess stdOut].
		((self pipeToInput respondsTo: #isStdErr) and: [pipeToInput isStdErr])
			ifTrue: [self pipeToInput: osp thisOSProcess stdErr]]

]

{ #category : #'initialize - release' }
PipeJunction >> setNonBlockingOutput [
	"Check first to make sure process is not complete because pipeFromOutput will not respond
	to #setNonBlocking after the process has exited."

	self isComplete ifFalse: [pipeFromOutput setNonBlocking]
]

{ #category : #'event handling' }
PipeJunction >> triggerComplete [

	self triggerEvent: #complete

]

{ #category : #'event handling' }
PipeJunction >> triggerErrorDataReady [

	self triggerEvent: #errorDataReady.
	Processor yield

]

{ #category : #'event handling' }
PipeJunction >> triggerOutputDataReady [

	self triggerEvent: #outputDataReady.
	Processor yield

]

{ #category : #streaming }
PipeJunction >> upToEnd [
	"Answer all available characters from the output stream."

	^ (self pipeFromOutput notNil and: [self canProvideOutputPipe])
		ifTrue: [pipeFromOutput upToEnd]
		ifFalse: ['']

]

{ #category : #streaming }
PipeJunction >> upToEndOfFile [
	"Answer all available characters from the output stream. Block and
	continue reading until end of file is detected."

	^ (self pipeFromOutput notNil and: [self canProvideOutputPipe])
		ifTrue: [pipeFromOutput upToEndOfFile]
		ifFalse: ['']

]

{ #category : #updating }
PipeJunction >> update: aParameter [

	^ self changed: aParameter

]

{ #category : #'event handling' }
PipeJunction >> updateErrorPipelineStream [
	"Ensure that all available error output is placed into errorPipelineStream."

]
