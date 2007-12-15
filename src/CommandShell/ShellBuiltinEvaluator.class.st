"
I provide the context in which a ShellBuiltin is evaluated as an element of a command pipeline.
"
Class {
	#name : #ShellBuiltinEvaluator,
	#superclass : #PipeableEvaluator,
	#instVars : [
		'shellBuiltin',
		'commandShell'
	],
	#category : #'CommandShell-Piping'
}

{ #category : #'instance creation' }
ShellBuiltinEvaluator class >> command: aShellBuiltin withArguments: argumentArray shell: commandShell pipeFrom: inputStream pipeTo: outputStream errorPipelineStream: errorStream [

	^ super new
		shellBuiltin: aShellBuiltin;
		argumentArray: argumentArray;
		commandShell: commandShell;
		pipeToInput: inputStream;
		pipeFromOutput: outputStream;
		errorPipelineStream: errorStream;
		initialize
]

{ #category : #accessing }
ShellBuiltinEvaluator >> commandShell [

	^ commandShell

]

{ #category : #accessing }
ShellBuiltinEvaluator >> commandShell: aCommandShell [

	commandShell _ aCommandShell

]

{ #category : #testing }
ShellBuiltinEvaluator >> needsPrompt [
	"Answer true if a shell will want to issue a prompt after evaluating me."

	^ self shellBuiltin needsPrompt

]

{ #category : #printing }
ShellBuiltinEvaluator >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: ' on '.
	self shellBuiltin printOn: aStream
]

{ #category : #accessing }
ShellBuiltinEvaluator >> shellBuiltin [

	^ shellBuiltin
]

{ #category : #accessing }
ShellBuiltinEvaluator >> shellBuiltin: aShellBuiltin [

	shellBuiltin _ aShellBuiltin
]

{ #category : #evaluating }
ShellBuiltinEvaluator >> value [

	self isNotYetRunning ifTrue:
		[self success. "Hope for the best, send #fail if something goes wrong"
		self running.
		self ensurePipeFromOutput.
		[self shellBuiltin
				performWith: self argumentArray
				evaluator: self
				shell: self commandShell
				input: self pipeToInput
				output: self pipeFromOutput
				error: self errorPipelineStream] fork]

]
