"
I evaluate Smalltalk expressions taken from my pipeToInput, and print the results of the evaluation on my pipeFromOutput. I may append error messages to my errorPipelineStream. I provide a framework for pipelines of expressions, possibly combined in the same pipeline with ExternalOSProcess proxies executing external operating system commands.

My evaluationBlock may be supplied directly, or can be compiled from an expression string. If compiled from an expression string, the names 'stdin', 'stdout', 'stderr', and 'args' are used to refer to the input stream, output stream, error stream, and an array of arguments. If any of these names are used in the expression string, then the evaluation block will be compiled in such as way as to connect these names with their corresponding streams or argument array.

"
Class {
	#name : #PipeableEvaluator,
	#superclass : #PipeJunction,
	#instVars : [
		'runState',
		'expression',
		'evaluationBlock',
		'extraArguments',
		'needsPrompt',
		'exitStatus',
		'outputHasBeenRedirected'
	],
	#category : #CommandShell
}

{ #category : #'instance creation' }
PipeableEvaluator class >> block: aSimpleBlock [

	"(PipeableEvaluator block: [#'This block answers a symbol as String']) value upToEnd"

	^ self block: aSimpleBlock
		pipeFrom: nil

]

{ #category : #'instance creation' }
PipeableEvaluator class >> block: aSimpleBlock pipeFrom: inputStream [

	"(PipeableEvaluator
		block: [:input | input contents]
		pipeFrom: (ReadStream on: 'Here is some input text'))
			value upToEnd"

	^ self block: aSimpleBlock pipeFrom: inputStream errorPipelineStream: (WriteStream on: String new)
]

{ #category : #'instance creation' }
PipeableEvaluator class >> block: aSimpleBlock pipeFrom: inputStream errorPipelineStream: errorStream [

	^ self block: aSimpleBlock pipeFrom: inputStream pipeTo: nil errorPipelineStream: errorStream
]

{ #category : #'instance creation' }
PipeableEvaluator class >> block: aSimpleBlock pipeFrom: inputStream pipeTo: outputStream errorPipelineStream: errorStream [

	^ self block: aSimpleBlock pipeFrom: inputStream pipeTo: outputStream errorPipelineStream: errorStream withArgs: nil

]

{ #category : #'instance creation' }
PipeableEvaluator class >> block: aBlock pipeFrom: inputStream pipeTo: outputStream errorPipelineStream: errorStream withArgs: anArrayOfOtherArguments [

	"(PipeableEvaluator
		block: [:in :out :err :stuff |
				out nextPutAll: in contents; cr.
				err nextPutAll: 'hello stderr'.
				stuff do: [:e | out nextPutAll: e; cr]]
		pipeFrom: (ReadStream on: 'Here is some input text')
		pipeTo: nil
		errorPipelineStream: nil
		withArgs: #(arg1 arg2 arg3))
			value upToEnd"

	^ super new
		evaluationBlock: aBlock;
		pipeToInput: inputStream;
		pipeFromOutput: outputStream;
		errorPipelineStream: errorStream;
		extraArguments: anArrayOfOtherArguments;
		notYetRunning;
		initialize
]

{ #category : #'instance creation' }
PipeableEvaluator class >> command: aString [

	"(PipeableEvaluator command: '''Hello world!''') value upToEnd"

	^ self command: aString pipeFrom: nil errorPipelineStream: nil

]

{ #category : #'instance creation' }
PipeableEvaluator class >> command: aString pipeFrom: inputStream errorPipelineStream: errorStream [

	"(PipeableEvaluator
		command: 'stdout nextPutAll: stdin upToEnd'
		pipeFrom: (ReadStream on: 'Here is some input text')
		errorPipelineStream: (WriteStream on: ''))
			value upToEnd"

	^ self command: aString pipeFrom: inputStream pipeTo: nil errorPipelineStream: errorStream
]

{ #category : #'instance creation' }
PipeableEvaluator class >> command: aString pipeFrom: inputStream pipeTo: outputStream errorPipelineStream: errorStream [

	"(PipeableEvaluator
		command: 'stdout nextPutAll: stdin contents'
		pipeFrom: (ReadStream on: 'Here is some input text')
		pipeTo: nil
		errorPipelineStream: (WriteStream on: ''))
			value upToEnd"

	^ super new
		expression: aString;
		pipeToInput: inputStream;
		pipeFromOutput: outputStream;
		errorPipelineStream: errorStream;
		notYetRunning;
		initialize
]

{ #category : #'instance creation' }
PipeableEvaluator class >> command: aString pipeFrom: inputStream pipeTo: outputStream errorPipelineStream: errorStream withArgs: anArrayOfOtherArguments [

	"(PipeableEvaluator
		command: 'stdout nextPutAll: stdin contents; cr. ',
				'stderr nextPutAll: ''hello stderr''. ',
				'args do: [:arg | stdout nextPutAll: arg; cr]'
		pipeFrom: (ReadStream on: 'Here is some input text')
		pipeTo: nil
		errorPipelineStream: (WriteStream on: '')
		withArgs: #(this is a test))
			value upToEnd"

	^ super new
		expression: aString;
		pipeToInput: inputStream;
		pipeFromOutput: outputStream;
		errorPipelineStream: errorStream;
		extraArguments: anArrayOfOtherArguments;
		notYetRunning;
		initialize
]

{ #category : #defaults }
PipeableEvaluator class >> defaultSyntaxClass [

	^ ShellSyntax
]

{ #category : #evaluating }
PipeableEvaluator >> addTreeLeaves: treeOfSymbols to: aCollection [
	"Flatten a tree of Symbols built by a Scanner."

	treeOfSymbols do: [:e |
		(e isKindOf: Array)
			ifTrue: [self addTreeLeaves: e to: aCollection]
			ifFalse: [aCollection add: e]].
	^ aCollection
]

{ #category : #evaluating }
PipeableEvaluator >> blockString [
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
			[tokens _ self addTreeLeaves: (Scanner new scanTokens: expression) to: OrderedCollection new.
			(tokens includes: #args)
				ifTrue:
					[prefix _ '[:stdin :stdout :stderr :args | ']
				ifFalse:
					[(tokens includes: #stderr)
						ifTrue:
							[prefix _ '[:stdin :stdout :stderr | ']
						ifFalse:
							[(tokens includes: #stdout)
								ifTrue:
									[prefix _ '[:stdin :stdout | ']
								ifFalse:
									[(tokens includes: #stdin)
										ifTrue:
											[prefix _ '[:stdin | ']
										ifFalse:
											[prefix _ '[']]]].
			^ prefix, self expression, ']']

]

{ #category : #evaluating }
PipeableEvaluator >> blockValue [
	"Evaluate my evaluationBlock. For a smart block, answer self. For a dumb
	block, answer the result of evaluating it. Heuristic: If the block receives
	two or more arguments, then assume that it was smart enough to write
	output to stdout. Otherwise, assume that it was a dumb block."

	| nArgs |
	self evaluationBlock ifNil: [^ nil].
	nArgs _ evaluationBlock numArgs.
	(nArgs == 0)
		ifTrue: "dumb block"
			[^ evaluationBlock value]
		ifFalse:
			[(nArgs == 1)
				ifTrue: "dumb block"
					[^ evaluationBlock value: self pipeToInput]
				ifFalse:
					[(nArgs == 2)
						ifTrue: "smart block"
							[evaluationBlock
								value: self pipeToInput
								value: self pipeFromOutput]	
						ifFalse:
							[(nArgs == 3)
								ifTrue: "smart block"
									[evaluationBlock
										value: self pipeToInput
										value: self pipeFromOutput
										value: self errorPipelineStream]
								ifFalse:
									[(nArgs == 4)
										ifTrue: "smart block"
											[evaluationBlock
												value: self pipeToInput
												value: self pipeFromOutput
												value: self errorPipelineStream
												value: self extraArguments]
										ifFalse: "really stupid block"
											[self error: 'expected block with 4 or fewer arguments'. ^ nil]]]]]

]

{ #category : #testing }
PipeableEvaluator >> canProvideOutputPipe [
	"Answer false if output has been redirected to a file and cannot be accessed by
	the next process proxy in a command pipeline."

	^ self outputHasBeenRedirected not

]

{ #category : #evaluating }
PipeableEvaluator >> closePipes [

	pipeFromOutput ifNotNil: [pipeFromOutput close].
	pipeToInput ifNotNil: [pipeToInput close].
	self errorHasBeenRedirected ifTrue: [errorPipelineStream close]

]

{ #category : #evaluating }
PipeableEvaluator >> compile [
	"Compile my expression into a block with zero to four parameters. The parameters,
	if present, correspond to my pipeToInput, pipeFromOutput, errorPipelineStream, and
	an array of extra parameters (in that order). By convention, these are named 'stdin',
	'stdout', 'stderr', and 'args' within my expression string.

	If the compilation fails due to a syntax error (compile time failure, not run time
	failure), put an error message on the standard error stream and answer a block
	which evaluates to a null string."

	evaluationBlock ifNil:
		[evaluationBlock _ self handleCompileErrorFor:
			[Compiler evaluate: self blockString
					for: self
					notifying: self
					logged: false]]

]

{ #category : #'setting run state' }
PipeableEvaluator >> complete [
	"Evaluation has been completed."

	self runState: #complete

]

{ #category : #testing }
PipeableEvaluator >> errorHasBeenRedirected [
	"Answer true if the error output has been redirected to an external file
	and is not available to be read as error output of a pipeline."

	^ self errorPipelineStream isKindOf: FileStream

]

{ #category : #streaming }
PipeableEvaluator >> errorUpToEnd [
	"Answer all available characters from my error stream. If evaluation
	has not happened yet, do it now."

	self isComplete ifFalse: [self value].
	^ (errorPipelineStream isNil or: [self errorHasBeenRedirected])
		ifTrue:
			['']
		ifFalse:
			[errorPipelineStream upToEnd]

]

{ #category : #accessing }
PipeableEvaluator >> evaluationBlock [
	"Answer the block to be evaluated, possibly compiling it from the expression string."

	evaluationBlock ifNil: [self compile].
	^ evaluationBlock
]

{ #category : #accessing }
PipeableEvaluator >> evaluationBlock: aBlock [
	"The block to be evaluated, possibly compiled from the expression string."

	evaluationBlock _ aBlock
]

{ #category : #accessing }
PipeableEvaluator >> exitStatus [

	exitStatus ifNil: [self success].
	^ exitStatus
]

{ #category : #accessing }
PipeableEvaluator >> exitStatus: aSymbol [

	exitStatus _ aSymbol
]

{ #category : #accessing }
PipeableEvaluator >> expression [

	^ expression
]

{ #category : #accessing }
PipeableEvaluator >> expression: aString [

	expression _ aString
]

{ #category : #accessing }
PipeableEvaluator >> extraArguments [
	"Any additional arguments for my evaluationBlock, to be passed in an Array."

	^ extraArguments
]

{ #category : #accessing }
PipeableEvaluator >> extraArguments: anArray [
	"Any additional arguments for my evaluationBlock, to be passed in an Array."

	extraArguments _ anArray
]

{ #category : #evaluating }
PipeableEvaluator >> fail [

	self exitStatus: #fail
]

{ #category : #'error handling' }
PipeableEvaluator >> handleCompileErrorFor: aBlock [
	"Evaluate aBlock. On error, put a message onto the error stream and declare failure."

	^ [aBlock value]
		on: Error
		do: [:e |
			self errorPipelineStream
				nextPutAll: 'Compiler: invalid Smalltalk expression', Character lf asString.
			self fail.
			nil]

]

{ #category : #'error handling' }
PipeableEvaluator >> handleRuntimeErrorFor: aBlock [
	"Evaluate aBlock. On error, put a message onto the error stream and declare failure."

	^ [aBlock value]
		on: Error
		do: [:e |
			self errorPipelineStream nextPutAll: e description; nextPut: Character lf.
			self fail]

]

{ #category : #'initialize - release' }
PipeableEvaluator >> initialize [
	"If pipeFromOutput has been set, then the output stream is being redirected.
	Set a flag to indicate this, otherwise open new a pipe stream to use for output."

	pipeFromOutput isNil
		ifTrue: [self ensurePipeFromOutput]
		ifFalse: [self outputHasBeenRedirected: true]

]

{ #category : #testing }
PipeableEvaluator >> isComplete [

	^ self runState == #complete
]

{ #category : #testing }
PipeableEvaluator >> isNotYetRunning [

	^ self runState == #notYetRunning
]

{ #category : #accessing }
PipeableEvaluator >> needsPrompt [
	"Answer true if a shell will want to issue a prompt after evaluating me."

	needsPrompt ifNil: [needsPrompt _ true].
	^ needsPrompt

]

{ #category : #accessing }
PipeableEvaluator >> needsPrompt: aBoolean [
	"True if a shell will want to issue a prompt after evaluating me."

	needsPrompt _ aBoolean

]

{ #category : #streaming }
PipeableEvaluator >> next [

	^ pipeFromOutput next

]

{ #category : #streaming }
PipeableEvaluator >> next: count [

	^ pipeFromOutput next: count

]

{ #category : #streaming }
PipeableEvaluator >> nextFromError: count [

	^ errorPipelineStream next: count

]

{ #category : #streaming }
PipeableEvaluator >> nextPut: aCharacter [
	"Write aCharacter to the standard input stream of my process."

	| readPosition |
	readPosition _ pipeToInput position.
	pipeToInput setToEnd nextPut: aCharacter.
	pipeToInput position: readPosition.
	^ pipeToInput

]

{ #category : #streaming }
PipeableEvaluator >> nextPutAll: aCollection [
	"Write aCollection to the standard input stream of my process."

	| readPosition |
	readPosition _ pipeToInput position.
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
	s _ aStream contents.
	self errorPipelineStream
		nextPutAll: (s copyFrom: 1 to: (aPosition - 1));
		nextPutAll: aString;
		nextPutAll: (s copyFrom: aPosition to: s size);
		cr


]

{ #category : #'command pipelines' }
PipeableEvaluator >> output [
	"Answer output contents."

	^ self outputHasBeenRedirected
		ifTrue: ['']
		ifFalse: [self pipeFromOutput upToEnd]

]

{ #category : #'command pipelines' }
PipeableEvaluator >> outputAndError [
	"Answer an array with output and error contents. If standard error has been
	redirected to a file, answer a null string as the error message."

	| out err |
	out _ self output.
	(self errorHasBeenRedirected)
		ifTrue: [err _ '']
		ifFalse: [err _ errorPipelineStream contents].
	^ Array with: out with: err
]

{ #category : #accessing }
PipeableEvaluator >> outputHasBeenRedirected [
	"True if pipeFromOutput has been redirected to a FileStream"

	^ outputHasBeenRedirected ifNil: [outputHasBeenRedirected _ false]
]

{ #category : #accessing }
PipeableEvaluator >> outputHasBeenRedirected: trueOrFalse [
	"True if pipeFromOutput has been redirected to a FileStream"

	outputHasBeenRedirected _ trueOrFalse
]

{ #category : #'command pipelines' }
PipeableEvaluator >> outputPipeForNextProxy [

	^ self outputHasBeenRedirected
		ifTrue: [nil]
		ifFalse: [pipeFromOutput]

]

{ #category : #accessing }
PipeableEvaluator >> pid [
	"A PipeableEvaluator does not have a pid, so answer nil. This is for
	compatability in a Unix process pipeline."

	^ nil
]

{ #category : #'command pipelines' }
PipeableEvaluator >> prepareOutputForPipe [
	"Output stream will be used by another process proxy as input. Set output stream
	characteristics accordingly."

]

{ #category : #printing }
PipeableEvaluator >> printOn: aStream [

	super printOn: aStream.
	self isComplete
		ifTrue: [aStream nextPutAll: ' (complete)']
		ifFalse: [aStream nextPutAll: ' (notYetRunning)']
]

{ #category : #'command pipelines' }
PipeableEvaluator >> replaceOutputStreamWith: anotherStream [
	"Sender is not happy with the kind of output stream we are using. Replace
	pipeFromOutput with anotherStream, and copy the current contents of pipeFromOutput
	to the new stream."

	| oldOutputStream |
	oldOutputStream _ self pipeFromOutput.
	self pipeFromOutput: anotherStream.
	oldOutputStream ifNotNil:
		[anotherStream ifNotNil:
			[anotherStream nextPutAll: oldOutputStream contents].
		oldOutputStream close]

]

{ #category : #accessing }
PipeableEvaluator >> runState [

	^ runState

]

{ #category : #accessing }
PipeableEvaluator >> runState: aSymbol [

	runState _ aSymbol.
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

{ #category : #'command pipelines' }
PipeableEvaluator >> setNonBlockingOutput [
	"Check first to make sure process is not complete because pipeFromOutput will not respond
	to #setNonBlocking after the process has exited."

	self isComplete ifFalse: [pipeFromOutput setNonBlocking]
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

{ #category : #streaming }
PipeableEvaluator >> upToEnd [
	"Answer all available characters from my output. If evaluation has not
	happened yet, do it now."

	self isComplete ifFalse: [self value].
	^ self pipeFromOutput isNil
		ifTrue:
			['']
		ifFalse:
			[pipeFromOutput upToEnd]

]

{ #category : #evaluating }
PipeableEvaluator >> value [
	"Evaluate my evaluationBlock. If the block evaluates to anything other
	than self, then print the result on pipeFromOutput as output. Otherwise,
	assume that the block was smart enough to have written its own output.
	For a block which does not write its own output, add a trailing <cr> after
	the evaluation if needed. Answer self as the result of the evaluation."

	| result resultString |
	self success. "Hope for the best, send #fail if something goes wrong"
	self isNotYetRunning ifTrue:
		[self ensurePipeFromOutput.
		self running.
		self evaluationBlock notNil
			ifTrue:
				[result _ self handleRuntimeErrorFor: [self blockValue].
				(result == self)
					ifFalse:
						[resultString _ result asString.
						pipeFromOutput nextPutAll: resultString.
						(resultString isEmpty not and:
							[(resultString last ~= Character cr) and:
								[resultString last ~= Character lf]])
						ifTrue: [pipeFromOutput nextPut: Character cr]]]
			ifFalse:
				[self fail].
		self closePipes.
		self complete]

]

{ #category : #'command pipelines' }
PipeableEvaluator >> | anotherCommandString [
	"Pipe my output to another evaluator, where the other evaluator evaluates
	anotherCommandString."

	"((PipeableEvaluator command: 'Smalltalk')
		| 'stdout nextPutAll: stdin upToEnd'
		| 'stdout nextPutAll: stdin upToEnd') upToEnd"

	"(PipeableEvaluator command: 'BOGUS')
		| 'stdout nextPutAll: stdin upToEnd'
		| 'stdout nextPutAll: stdin upToEnd'"

	"((PipeableEvaluator command: '(true == false) not')
		| 'stdout nextPutAll: stdin upToEnd'
		| 'stdout nextPutAll: stdin upToEnd') upToEnd"

	| new |
	new _ self species
			command: anotherCommandString
			pipeFrom: self pipeFromOutput
			errorPipelineStream: self errorPipelineStream.
	self value.
	^ new

]
