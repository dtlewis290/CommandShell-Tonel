"
I provide a context in which a Smalltalk expression can be evaluated as an element of a command pipeline.
"
Class {
	#name : #ExpressionEvaluator,
	#superclass : #PipeableEvaluator,
	#instVars : [
		'expression',
		'evaluationBlock'
	],
	#category : #'CommandShell-Piping'
}

{ #category : #'instance creation' }
ExpressionEvaluator class >> block: aBlock [

	"(self block: [#'This block answers a symbol as String']) value upToEnd"

	^ self basicNew block: aBlock

]

{ #category : #'instance creation' }
ExpressionEvaluator class >> command: aString [

	"(self command: '''Hello world!''') value upToEnd"

	^ self basicNew command: aString

]

{ #category : #'instance creation' }
ExpressionEvaluator class >> command: aString pipeFrom: inputStream errorPipelineStream: errorStream [

	"(self command: 'stdout nextPutAll: stdin upToEnd'
		pipeFrom: (ReadStream on: 'Here is some input text')
		errorPipelineStream: InternalPipe nonBlockingPipe)
			value upToEnd"

	^ self command: aString pipeFrom: inputStream pipeTo: nil errorPipelineStream: errorStream
]

{ #category : #'instance creation' }
ExpressionEvaluator class >> command: aString pipeFrom: inputStream pipeTo: outputStream errorPipelineStream: errorStream [

	"(self command: 'stdout nextPutAll: stdin contents'
		pipeFrom: (ReadStream on: 'Here is some input text')
		pipeTo: nil
		errorPipelineStream: InternalPipe nonBlockingPipe)
			value upToEnd"

	^ super new
		expression: aString;
		pipeToInput: inputStream;
		pipeFromOutput: outputStream;
		errorPipelineStream: errorStream;
		notYetRunning;
		initialize
]

{ #category : #evaluating }
ExpressionEvaluator >> addTreeLeaves: treeOfSymbols to: aCollection [
	"Flatten a tree of Symbols built by a Scanner."

	treeOfSymbols do: [:e |
		(e isKindOf: Array)
			ifTrue: [self addTreeLeaves: e to: aCollection]
			ifFalse: [aCollection add: e]].
	^ aCollection
]

{ #category : #'initialize - release' }
ExpressionEvaluator >> block: aBlock [

	self evaluationBlock: aBlock.
	self initialize.
	self prepareOutputForInternalReader

]

{ #category : #evaluating }
ExpressionEvaluator >> blockString [
	"Answer source code for a block to execute my expression. Attempt to give it the correct
	number of parameters based on scanning expression for use of #args, #stderr, #stdout,
	and #stdin tokens."

	"PipeableEvaluator new expression: 'stdout nextPutAll: (args at: 4)'; blockString"
	"PipeableEvaluator new expression: 'stderr nextPutAll: stdin contents'; blockString"
	"PipeableEvaluator new expression: 'stdout nextPutAll: stdin contents'; blockString"
	"PipeableEvaluator new expression: 'stdin contents'; blockString"
	"PipeableEvaluator new expression: '#HelloWorld'; blockString"

	| tokens prefix |
	self expression isNil
		ifTrue:
			[^ '[]']
		ifFalse:
			[tokens := self addTreeLeaves: (Scanner new scanTokens: expression) to: OrderedCollection new.
			(tokens includes: #args)
				ifTrue:
					[prefix := '[:stdin :stdout :stderr :args | ']
				ifFalse:
					[(tokens includes: #stderr)
						ifTrue:
							[prefix := '[:stdin :stdout :stderr | ']
						ifFalse:
							[(tokens includes: #stdout)
								ifTrue:
									[prefix := '[:stdin :stdout | ']
								ifFalse:
									[(tokens includes: #stdin)
										ifTrue:
											[prefix := '[:stdin | ']
										ifFalse:
											[prefix := '[']]]].
			^ prefix, self expression, ']']

]

{ #category : #evaluating }
ExpressionEvaluator >> blockValue [
	"Evaluate my evaluationBlock. For a smart block, answer self. For a dumb
	block, answer the result of evaluating it. Heuristic: If the block receives
	two or more arguments, then assume that it was smart enough to write
	output to stdout. Otherwise, assume that it was a dumb block."

	| nArgs |
	self evaluationBlock ifNil: [^ nil].
	nArgs := evaluationBlock numArgs.
	(nArgs == 0)
		ifTrue: "dumb block"
			[^ evaluationBlock value]
		ifFalse:
			[(nArgs == 4)
				ifTrue: "smart block"
					[evaluationBlock
						value: self pipeToInput
						value: self pipeFromOutput
						value: self errorPipelineStream
						value: self argumentArray]
				ifFalse:
					[(nArgs == 3)
						ifTrue: "smart block"
							[evaluationBlock
								value: self pipeToInput
								value: self pipeFromOutput
								value: self errorPipelineStream]
						ifFalse:
							[(nArgs == 2)
								ifTrue: "smart block"
									[evaluationBlock
										value: self pipeToInput
										value: self pipeFromOutput]	
								ifFalse:
									[(nArgs == 1)
										ifTrue: "dumb block"
											[^ evaluationBlock value: self pipeToInput]
										ifFalse: "really stupid block"
											[self error: 'expected block with 4 or fewer arguments'.
											^ nil]]]]]

]

{ #category : #'initialize - release' }
ExpressionEvaluator >> command: aString [

	self expression: aString.
	self initialize.
	self prepareOutputForInternalReader

]

{ #category : #evaluating }
ExpressionEvaluator >> compile [
	"Compile my expression into a block with zero to four parameters. The parameters,
	if present, correspond to my pipeToInput, pipeFromOutput, errorPipelineStream, and
	an array of extra parameters (in that order). By convention, these are named 'stdin',
	'stdout', 'stderr', and 'args' within my expression string.

	If the compilation fails due to a syntax error (compile time failure, not run time
	failure), put an error message on the standard error stream and answer a block
	which evaluates to a null string."

	evaluationBlock ifNil:
		[evaluationBlock :=
			[Compiler evaluate: self blockString
					for: self
					notifying: self
					logged: false]
				on: Exception
				do: [:e |
					self errorPipelineStream
						nextPutAll: 'Compiler: invalid Smalltalk expression ', self blockString;
						nextPut: Character lf.
					self fail.
					nil]]

]

{ #category : #accessing }
ExpressionEvaluator >> evaluationBlock [
	"Answer the block to be evaluated, possibly compiling it from the expression string."

	evaluationBlock ifNil: [self compile].
	^ evaluationBlock
]

{ #category : #accessing }
ExpressionEvaluator >> evaluationBlock: aBlock [
	"The block to be evaluated, possibly compiled from the expression string."

	evaluationBlock := aBlock
]

{ #category : #accessing }
ExpressionEvaluator >> expression [

	^ expression
]

{ #category : #accessing }
ExpressionEvaluator >> expression: aString [

	expression := aString
]

{ #category : #printing }
ExpressionEvaluator >> printOn: aStream [

	super printOn: aStream.
	self expression isNil
		ifTrue:
			[self evaluationBlock isNil
				ifTrue:
					[aStream nextPutAll: ' for '.
					self evaluationBlock printOn: aStream]
				ifFalse:
					[aStream nextPutAll: ' for a '.
					self evaluationBlock class printOn: aStream]]
		ifFalse:
			[aStream nextPutAll: ' for '.
			self expression printOn: aStream]

]

{ #category : #evaluating }
ExpressionEvaluator >> value [
	"Evaluate my evaluationBlock. If the block evaluates to anything other
	than self, then print the result on pipeFromOutput as output. Otherwise,
	assume that the block was smart enough to have written its own output.
	For a block which does not write its own output, add a trailing line
	terminator after the evaluation if needed. Answer self as the result of
	the evaluation."

	| result resultString |
	self success. "Hope for the best, send #fail if something goes wrong"
	self isNotYetRunning ifTrue:
		[self ensurePipeFromOutput.
		self running.
		self evaluationBlock notNil
			ifTrue:
				[result := [self blockValue]
					on: Error
					do: [:e |
						self errorPipelineStream nextPutAll: e description; nextPut: Character lf.
						self fail].
				(result == self)
					ifFalse:
						[resultString := result asString.
						pipeFromOutput nextPutAll: resultString.
						(resultString isEmpty not and:
							[(resultString last ~= Character cr) and:
								[resultString last ~= Character lf]])
							ifTrue: [pipeFromOutput nextPut: Character lf]]]
			ifFalse:
				[self fail].
		self complete]

]
