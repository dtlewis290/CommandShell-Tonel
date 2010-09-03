"
A collection of connected PipeJunctions, representing external OS processes or internal evaluators. This class exists primarily to make the functioning of a collection of command pipelines, some of which may be evaluated as asynchronous ""background"" processes, easier to understand.

Events triggered by my proxies are handled and forwarded in such a way that a client (such as a CommandShell) will receive events from a ProxyPipeline as if it were an individual PipeJunction.

The user of a ProxyPipeline is responsible for closing the external resources associated with the proxies by sending either #closePipes or #finalize.
"
Class {
	#name : #ProxyPipeline,
	#superclass : #OrderedCollection,
	#instVars : [
		'commandLine',
		'background',
		'completionSemaphore',
		'completionWatcher'
	],
	#category : #'CommandShell-Piping'
}

{ #category : #'command processing' }
ProxyPipeline class >> command: aCommandString [
	"Evaluate a new instance created from aCommandString. Sender is responsible
	for closing the pipes with #closePipes or #finalize."

	"ProxyPipeline command: 'ls | cat | wc'"
	"ProxyPipeline command: 'ls NOSUCHFILE * | cat | wc'"
	"ProxyPipeline command: 'ls | copyToOutput | wc'"
	"ProxyPipeline command: ''"

	^ self command: aCommandString shell: CommandShell new

]

{ #category : #'command processing' }
ProxyPipeline class >> command: aCommandString shell: aCommandShell [
	"Evaluate a new instance created from aCommandString using aCommandShell.
	Sender is responsible for closing the pipes #closePipes or #finalize."

	"ProxyPipeline command: 'ls | cat | wc' shell: CommandShell new"
	"ProxyPipeline command: 'ls NOSUCHFILE * | cat | wc' shell: CommandShell new"
	"ProxyPipeline command: 'ls | copyToOutput | wc' shell: CommandShell new "
	"ProxyPipeline command: '' shell: CommandShell new"

	^ (self fromString: aCommandString shell: aCommandShell) value

]

{ #category : #'instance creation' }
ProxyPipeline class >> fromString: aCommandString shell: aCommandShell [
	"Answer a new instance created from aCommandString using aCommandShell."

	"ProxyPipeline fromString: 'ls | cat | wc' shell: CommandShell new"
	"ProxyPipeline fromString: 'ls NOSUCHFILE * | cat | wc' shell: CommandShell new"
	"ProxyPipeline fromString: 'ls | copyToOutput | wc' shell: CommandShell new "
	"ProxyPipeline fromString: '' shell: CommandShell new"

	^ super new fromString: aCommandString shell: aCommandShell

]

{ #category : #testing }
ProxyPipeline >> atEnd [

	^ self last atEnd

]

{ #category : #accessing }
ProxyPipeline >> background [
	"Answer true if this pipeline should be evaluated in the background."

	^ background ifNil: [background := false]
]

{ #category : #accessing }
ProxyPipeline >> background: trueOrFalse [

	background := trueOrFalse
]

{ #category : #'initialize - release' }
ProxyPipeline >> close [
	"Close input pipe to first proxy in the pipeline. The proxies are not
	finalized, this simply closes the input stream to allow normal processing
	to proceed to completion."

	self isEmpty ifFalse: [self first close]

]

{ #category : #'initialize - release' }
ProxyPipeline >> closePipes [

	| p |
	self do: [:e | e closePipes].
	self unregisterEvents.
	(p := self pipeFromOutput) ifNotNil: [p close]

]

{ #category : #accessing }
ProxyPipeline >> commandLine [
	"Command line string from which this pipeline was constructed"

	^ commandLine
]

{ #category : #accessing }
ProxyPipeline >> commandLine: aString [
	"Command line string from which this pipeline was constructed"

	commandLine := aString
]

{ #category : #accessing }
ProxyPipeline >> completionSemaphore [
	"Answer the value of completionSemaphore. This semaphore is signaled
	when the last proxy completes. Subsequent cleanup is preformed by a
	process waiting on the semaphore. Completion notification is often triggered
	by the grimReaperProcess, so the separate pipeline cleanup prevents
	those activities from being processed in the context of the grimReaperProcess."

	^ completionSemaphore ifNil: [completionSemaphore := Semaphore new]
]

{ #category : #accessing }
ProxyPipeline >> completionWatcher [
	"A process that waits for notification that the last proxy has completed,
	and performs any necessary cleanup. Completion notification is often
	triggered by the grimReaperProcess, so the separate pipeline cleanup
	prevents those activities from being processed in the context of the
	grimReaperProcess."

	^ completionWatcher
]

{ #category : #accessing }
ProxyPipeline >> completionWatcher: anObject [
	"Set the value of completionWatcher"

	completionWatcher := anObject
]

{ #category : #accessing }
ProxyPipeline >> errorPipelineStream [
	"Accumulates the error output of commands in a command pipeline."

	self isEmpty
		ifTrue: [^ nil]
		ifFalse: [^ self last errorPipelineStream]
]

{ #category : #streaming }
ProxyPipeline >> errorUpToEnd [
	"Answer all available characters from the error stream shared by my proxies."

	^ self last errorUpToEnd

]

{ #category : #streaming }
ProxyPipeline >> errorUpToEndOfFile [
	"Answer all available characters from the error stream. Block and
	continue reading until end of file is detected."

	^ self last errorUpToEndOfFile

]

{ #category : #finalization }
ProxyPipeline >> finalize [

	self closePipes.
	^ super finalize

]

{ #category : #streaming }
ProxyPipeline >> flush [
	"Flush output to the standard input stream of my first proxy."

	^ self first flush
]

{ #category : #'initialize - release' }
ProxyPipeline >> fromString: aCommandString shell: aCommandShell [ 
	"Initialize a new instance created from aCommandString using aCommandShell. "

	self commandLine: aCommandString.
	(aCommandShell splitPipelineCommands: aCommandString)
		inject: nil
		into: [:prevProxy :command | 
			| nextProxy |
			nextProxy := aCommandShell
				redirectedPipeableProxyFor: command
				predecessorProxy: prevProxy.
			prevProxy
				ifNotNil: [prevProxy prepareOutputFor: nextProxy.
					prevProxy canProvideOutputPipe
						ifFalse: [nextProxy closeWriter]].
			self add: nextProxy].
	self isEmpty
		ifFalse: [self last prepareOutputFor: self; addDependent: self]
]

{ #category : #'event handling' }
ProxyPipeline >> handleCompletionWhenSignaled: aSemaphore [
	"Answer a process that will complete processing the the last proxy has
	signaled its completion."

	| lastProxy proc |
	proc := [aSemaphore wait.
		self waitForAllToComplete.
		(lastProxy := self last)
			ifNotNil: [lastProxy closeErrorPipeline.
					self triggerEvent: #complete]] newProcess.
	^ proc resume
]

{ #category : #'event handling' }
ProxyPipeline >> handleRunstateChange [

	| lastProxy |
	(lastProxy := self last)
		ifNotNil: [lastProxy isComplete
					ifTrue: [self completionSemaphore signal]]
]

{ #category : #testing }
ProxyPipeline >> isComplete [
	"True if all proxies are complete. The proxies may report their completion events
	out of sequence, so test all the proxies (not just the last one in the pipeline)."

	^ self noneSatisfy: [:proxy | proxy isComplete not]

]

{ #category : #testing }
ProxyPipeline >> isExternalProcess [
	"Answer true if the process which I represent is an external OSProcess. For protocol
	compatibility with PipeJunction."

	^ false
]

{ #category : #testing }
ProxyPipeline >> needsPrompt [

	^ self last needsPrompt
]

{ #category : #streaming }
ProxyPipeline >> next [

	^ self last next

]

{ #category : #streaming }
ProxyPipeline >> next: count [

	^ self last next: count

]

{ #category : #streaming }
ProxyPipeline >> nextFromError: count [
	"Answer up to count characters from the error pipeline stream, or an empty string
	if no data is available. All characters are routed through the errorPipelineStream,
	which is shared by all my proxies."

	^ self last next: count

]

{ #category : #streaming }
ProxyPipeline >> nextPut: aCharacter [
	"Write aCharacter to the standard input stream of my first proxy."

	^ self first nextPut: aCharacter
]

{ #category : #streaming }
ProxyPipeline >> nextPutAll: characters [
	"Write characters to the standard input stream of my first proxy."

	^ self first nextPutAll: characters
]

{ #category : #streaming }
ProxyPipeline >> output [

	^ self last output
]

{ #category : #accessing }
ProxyPipeline >> pipeFromOutput [
	"The output from the last proxy in the pipeline, if any"

	self isEmpty
		ifTrue: [^ nil]
		ifFalse: [^ self last pipeFromOutput]
]

{ #category : #accessing }
ProxyPipeline >> pipeToInput [
	"The input to the first proxy in the pipeline, if any"

	self isEmpty
		ifTrue: [^ nil]
		ifFalse: [^ self first pipeToInput]
]

{ #category : #testing }
ProxyPipeline >> pipesAreEmpty [
	"True after processing is complete and all available data has been read from
	the output pipe and the errorPipelineStream pipe."

	^ self isComplete and: [self last pipesAreEmpty]

]

{ #category : #printing }
ProxyPipeline >> printOn: aStream [

	self background
		ifTrue: [aStream nextPutAll: 'a background ']
		ifFalse: [aStream nextPutAll: 'a foreground '].
	aStream nextPutAll: self class name, ' for "', self commandLine asString, '"'
]

{ #category : #'initialize - release' }
ProxyPipeline >> release [

	self do: [:proxy | proxy release].
	^ super release
]

{ #category : #testing }
ProxyPipeline >> succeeded [
	"Answer true if all proxies succeeded, otherwise false"

	self detect: [:proxy | proxy succeeded not] ifNone: [^ true].
	^ false

]

{ #category : #'initialize - release' }
ProxyPipeline >> unregisterEvents [

	self isEmpty ifFalse: [self last removeDependent: self]

]

{ #category : #streaming }
ProxyPipeline >> upToEnd [
	"Answer all available characters from the output stream."

	^ self last upToEnd

]

{ #category : #streaming }
ProxyPipeline >> upToEndOfFile [
	"Answer all available characters from the output stream. Block and
	continue reading until end of file is detected."

	^ self last upToEndOfFile

]

{ #category : #updating }
ProxyPipeline >> update: aParameter [

	aParameter == self pipeFromOutput
		ifTrue: [^ self triggerEvent: #outputDataReady].
	aParameter == self errorPipelineStream
		ifTrue: [^ self triggerEvent: #errorDataReady].
	aParameter == #runState
		ifTrue: [^ self handleRunstateChange].
	self error: 'unexpected parameter'


]

{ #category : #evaluation }
ProxyPipeline >> value [
	"Initiate evaluation of each member of the pipeline, and answer the
	last proxy in the pipeline. Evaluation may proceed asynchronously, and
	the sender should wait for the last proxy to complete its evalation in order
	to obtain complete output and error contents from the pipeline."

	"(ProxyPipeline command: 'ls | cat | wc' shell: CommandShell new) value"

	self completionWatcher: (self handleCompletionWhenSignaled: self completionSemaphore).
	self do: [:proxy | proxy value]

]

{ #category : #'event handling' }
ProxyPipeline >> waitForAllToComplete [
	"In some cases the last proxy in a pipeline may complete before some
	of the others. In particular, if one proxy has redirected its output to
	a file, the next proxy will see a nil input stream, and may quickly
	complete its processing before its predecessor proxies have finished
	writing to the file. Time out with an error if pipeline fails to complete
	after 10 seconds."

	(1 to: 100) do: [:e |
		self isComplete ifTrue: [^ self].
		(Delay forMilliseconds: 100) wait].
	self error: 'pipeline did not complete evaluation'


]
