"
I evaluate Smalltalk expressions, taking input from my pipeToInput, and print the results of the evaluation on my pipeFromOutput. I may append error messages to my errorPipelineStream. I provide a framework for pipelines of expressions, possibly combined in the same pipeline with ExternalOSProcess proxies executing external operating system commands.

My evaluationBlock may be supplied directly, or can be compiled from an expression string. If compiled from an expression string, the names 'stdin', 'stdout', 'stderr', and 'args' are used to refer to the input stream, output stream, error stream, and an array of arguments. If any of these names are used in the expression string, then the evaluation block will be compiled in such as way as to connect these names with their corresponding streams or argument array.

"
Class {
	#name : #PipeableEvaluator,
	#superclass : #PipeJunction,
	#instVars : [
		'argumentArray',
		'runState',
		'exitStatus',
		'outputHasBeenRedirected'
	],
	#category : #'CommandShell-Piping'
}

{ #category : #accessing }
PipeableEvaluator >> argumentArray [

	^ argumentArray

]

{ #category : #accessing }
PipeableEvaluator >> argumentArray: anArrayOfStrings [

	argumentArray := anArrayOfStrings

]

{ #category : #testing }
PipeableEvaluator >> atEnd [
	"True after processing is complete and all available data has been read from
	the output pipe."

	^ self isComplete
		and: [self outputHasBeenRedirected
				or: [self outputIsExternalStream
					or: [pipeFromOutput atEnd]]]

]

{ #category : #testing }
PipeableEvaluator >> canProvideOutputPipe [
	"Answer false if output has been redirected to a file and cannot be accessed by
	the next process proxy in a command pipeline."

	^ super canProvideOutputPipe and: [self outputHasBeenRedirected not]

]

{ #category : #'setting run state' }
PipeableEvaluator >> complete [
	"Evaluation has been completed. Perform some cleanup and notify
	interested parties."

	self closePipeInputs.
	self runState: #complete.
	self errorHasBeenRedirected
		ifTrue: [self closeErrorPipeline]
]

{ #category : #accessing }
PipeableEvaluator >> errorPipelineStream [
	"Accumulates the error output of commands in a command pipeline."

	errorPipelineStream isNil
		ifTrue:
			[errorPipelineStream := InternalPipe nonBlockingPipe.
			errorPipelineStream addDependent: self].
	^ errorPipelineStream

]

{ #category : #accessing }
PipeableEvaluator >> errorPipelineStream: aStream [
	"Accumulates the error output of commands in a command pipeline."

	errorPipelineStream ifNotNil: [errorPipelineStream removeDependent: self].
	errorPipelineStream := aStream.
	errorPipelineStream ifNotNil: [errorPipelineStream addDependent: self]

]

{ #category : #accessing }
PipeableEvaluator >> exitStatus [

	^ exitStatus
]

{ #category : #accessing }
PipeableEvaluator >> exitStatus: aSymbol [

	exitStatus := aSymbol
]

{ #category : #evaluating }
PipeableEvaluator >> fail [

	self exitStatus: #fail
]

{ #category : #'initialize - release' }
PipeableEvaluator >> initialize [
	"If pipeFromOutput has been set, then the output stream is being redirected.
	Set a flag to indicate this, otherwise open new a pipe stream to use for output."

	pipeFromOutput isNil
		ifTrue: [self ensurePipeFromOutput]
		ifFalse: [self outputHasBeenRedirected: true].
	^ super initialize

]

{ #category : #testing }
PipeableEvaluator >> isComplete [

	^ self runState == #complete
]

{ #category : #testing }
PipeableEvaluator >> isNotYetRunning [

	^ self runState == #notYetRunning
]

{ #category : #streaming }
PipeableEvaluator >> nextPut: aCharacter [
	"Write aCharacter to the standard input stream of my process."

	| readPosition |
	readPosition := pipeToInput position.
	pipeToInput setToEnd nextPut: aCharacter.
	pipeToInput position: readPosition.
	^ pipeToInput

]

{ #category : #streaming }
PipeableEvaluator >> nextPutAll: aCollection [
	"Write aCollection to the standard input stream of my process."

	| readPosition |
	readPosition := pipeToInput position.
	pipeToInput setToEnd nextPutAll: aCollection.
	pipeToInput position: readPosition.
	^ pipeToInput

]

{ #category : #'setting run state' }
PipeableEvaluator >> notYetRunning [
	"Process has not yet entered running state."

	self runState: #notYetRunning

]

{ #category : #'error handling' }
PipeableEvaluator >> notify: aString at: aPosition in: aStream [

	| s |
	s := aStream contents.
	self errorPipelineStream
		nextPutAll: (s copyFrom: 1 to: (aPosition - 1));
		nextPutAll: aString;
		nextPutAll: (s copyFrom: aPosition to: s size);
		cr


]

{ #category : #accessing }
PipeableEvaluator >> outputHasBeenRedirected [
	"True if pipeFromOutput has been redirected to a FileStream"

	^ outputHasBeenRedirected ifNil: [outputHasBeenRedirected := false]
]

{ #category : #accessing }
PipeableEvaluator >> outputHasBeenRedirected: trueOrFalse [
	"True if pipeFromOutput has been redirected to a FileStream"

	outputHasBeenRedirected := trueOrFalse
]

{ #category : #testing }
PipeableEvaluator >> outputIsExternalStream [
	"True if output is being piped to an external proxy, or if output has been
	redirected to a file."

	^ self pipeFromOutput isKindOf: FileStream

]

{ #category : #accessing }
PipeableEvaluator >> pipeFromError [
	"Internal evaluators use the errorPipelineStream directly"

	^ self errorPipelineStream
]

{ #category : #printing }
PipeableEvaluator >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: ' ('; nextPutAll: self runState; nextPut: $)

]

{ #category : #accessing }
PipeableEvaluator >> runState [

	^ runState ifNil: [runState := #notYetRunning]

]

{ #category : #accessing }
PipeableEvaluator >> runState: aSymbol [

	runState := aSymbol.
	self changed: #runState

]

{ #category : #'setting run state' }
PipeableEvaluator >> running [
	"Process is actively running."

	self runState: #running

]

{ #category : #'error handling' }
PipeableEvaluator >> selectFrom: start to: end [

	^ self blockString copyFrom: start to: end
]

{ #category : #'error handling' }
PipeableEvaluator >> selectionInterval [
	"The compiler wants this for some reason."

	^ 1 to: 1
]

{ #category : #testing }
PipeableEvaluator >> succeeded [
	"Answer true if my evaluation completed successfully."

	^ self exitStatus == #success
]

{ #category : #evaluating }
PipeableEvaluator >> success [

	self exitStatus: #success
]

{ #category : #'error handling' }
PipeableEvaluator >> text [
	"The compiler needs this to generate error messages."

	^ Text fromString: self expression
]

{ #category : #'setting run state' }
PipeableEvaluator >> unknownRunState [
	"Unable to determine the current run state of the process."

	self runState: #unknownRunState

]

{ #category : #'command pipelines' }
PipeableEvaluator >> | anotherCommandString [
	"Pipe my output to another evaluator, where the other evaluator evaluates
	anotherCommandString."

	"((ExpressionEvaluator command: 'Smalltalk')
		| 'stdout nextPutAll: stdin upToEnd'
		| 'stdout nextPutAll: stdin upToEnd') upToEnd"

	"(ExpressionEvaluator command: 'BOGUS')
		| 'stdout nextPutAll: stdin upToEnd'
		| 'stdout nextPutAll: stdin upToEnd'"

	"((ExpressionEvaluator command: '(true == false) not')
		| 'stdout nextPutAll: stdin upToEnd'
		| 'stdout nextPutAll: stdin upToEnd') upToEnd"

	| new |
	new := self species
			command: anotherCommandString
			pipeFrom: self pipeFromOutput
			errorPipelineStream: self errorPipelineStream.
	self value.
	^ new

]
