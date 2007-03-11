"
I am a connector junction for input, output, and error pipelines. I obtain input from an input pipeline and, after possibly performing some kind of operation on the input objects, I send output to an output pipeline. I may also append objects onto an error pipeline.

My subclasses implement the operations on the objects which pass through a pipe junction.

In general, input pipes are connected to output pipes in a serial fashion, and error pipelines are shared by one or more instances of my subclasses.

"
Class {
	#name : #PipeJunction,
	#superclass : #Object,
	#instVars : [
		'pipeToInput',
		'pipeFromOutput',
		'errorPipelineStream'
	],
	#category : #CommandShell
}

{ #category : #'initialize - release' }
PipeJunction >> closeErrorPipeline [

	errorPipelineStream ifNotNil: [errorPipelineStream close]

]

{ #category : #'initialize - release' }
PipeJunction >> closeOutput [

	pipeFromOutput ifNotNil: [pipeFromOutput close]

]

{ #category : #'initialize - release' }
PipeJunction >> ensurePipeFromOutput [
	"Make sure that an output pipe is provided."

	^ pipeFromOutput ifNil: [pipeFromOutput _ InternalPipe new]

]

{ #category : #accessing }
PipeJunction >> errorPipelineStream [
	"Accumulates the error output of commands in a command pipeline."

	errorPipelineStream isNil ifTrue: [errorPipelineStream _ InternalPipe nonBlockingPipe].
	^ errorPipelineStream

]

{ #category : #accessing }
PipeJunction >> errorPipelineStream: aStream [
	"Accumulates the error output of commands in a command pipeline."

	errorPipelineStream _ aStream

]

{ #category : #testing }
PipeJunction >> isExternalProcess [
	"Answer true if the process which I represent is an external OSProcess."

	^ false
]

{ #category : #'command pipelines' }
PipeJunction >> outputPipeForNextProxy [

	^ pipeFromOutput
]

{ #category : #accessing }
PipeJunction >> pipeFromOutput [

	^ pipeFromOutput
]

{ #category : #accessing }
PipeJunction >> pipeFromOutput: aPipeStream [

	pipeFromOutput _ aPipeStream
]

{ #category : #accessing }
PipeJunction >> pipeToInput [

	^ pipeToInput
]

{ #category : #accessing }
PipeJunction >> pipeToInput: aPipeStream [

	pipeToInput _ aPipeStream
]
