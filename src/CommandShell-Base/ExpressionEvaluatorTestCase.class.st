Class {
	#name : #ExpressionEvaluatorTestCase,
	#superclass : #TestCase,
	#instVars : [
		'pipeJunction'
	],
	#category : #'CommandShell-Tests'
}

{ #category : #Running }
ExpressionEvaluatorTestCase >> runAll [

	"self new runAll"

	| result suite |
	suite := TestSuite new.
	suite addTest: (self class selector: #testCommand01).
	suite addTest: (self class selector: #testCommand02).
	suite addTest: (self class selector: #testCommand03).
	suite addTest: (self class selector: #testCommand04).
	suite addTest: (self class selector: #testCommand05).
	suite addTest: (self class selector: #testCommand06).
	suite addTest: (self class selector: #testBlock01).
	suite addTest: (self class selector: #testBlock02).
	suite addTest: (self class selector: #testBlock03).
	result := suite run.
	self should: [result defects size == 0].
	^ result

]

{ #category : #Testing }
ExpressionEvaluatorTestCase >> testBlock01 [
	"Command consisting of the Compiler evaluating a String"

	"(self selector: #testBlock01) run"

	pipeJunction := ExpressionEvaluator block: ['Hello world!'].
	self should: [pipeJunction runState == #notYetRunning].
	self shouldnt: [pipeJunction isComplete].
	self should: [pipeJunction pipeToInput isNil].
	self should: [pipeJunction pipeFromOutput isKindOf: InternalPipe].
	self should: [pipeJunction errorPipelineStream isKindOf: InternalPipe].
	self should: [pipeJunction exitStatus isNil].
	self should: [pipeJunction output isEmpty].
	self should: [pipeJunction errorUpToEnd isEmpty].
	pipeJunction value.
	self should: [pipeJunction runState == #complete].
	self should: [pipeJunction isComplete].
	self should: [pipeJunction exitStatus == #success].
	self should: [pipeJunction succeeded].
	self should: [pipeJunction upToEnd = ('Hello world!', String lf)].
	self should: [pipeJunction errorUpToEnd isEmpty].

]

{ #category : #Testing }
ExpressionEvaluatorTestCase >> testBlock02 [
	"Evaluating an MNU"

	"(self selector: #testBlock02) run"

	pipeJunction := ExpressionEvaluator block: [Smalltalk noSuchMessage].
	self should: [pipeJunction runState == #notYetRunning].
	self shouldnt: [pipeJunction isComplete].
	self should: [pipeJunction pipeToInput isNil].
	self should: [pipeJunction pipeFromOutput isKindOf: InternalPipe].
	self should: [pipeJunction errorPipelineStream isKindOf: InternalPipe].
	self should: [pipeJunction exitStatus isNil].
	self should: [pipeJunction output isEmpty].
	self should: [pipeJunction errorUpToEnd isEmpty].
	pipeJunction value.
	self should: [pipeJunction runState == #complete].
	self should: [pipeJunction isComplete].
	self should: [pipeJunction exitStatus == #fail].
	self shouldnt: [pipeJunction succeeded].
	self should: [pipeJunction upToEnd isEmpty].
	self should: [('MessageNotUnderstood: *noSuchMessage', String lf)
 				match: pipeJunction errorUpToEnd]
]

{ #category : #Testing }
ExpressionEvaluatorTestCase >> testBlock03 [
	"Command consisting of the Compiler evaluating an Array new"

	"(self selector: #testBlock03) run"

	pipeJunction := ExpressionEvaluator block: [Array with: #foo with: #bar].
	self should: [pipeJunction runState == #notYetRunning].
	self shouldnt: [pipeJunction isComplete].
	self should: [pipeJunction pipeToInput isNil].
	self should: [pipeJunction pipeFromOutput isKindOf: InternalPipe].
	self should: [pipeJunction errorPipelineStream isKindOf: InternalPipe].
	self should: [pipeJunction exitStatus isNil].
	self should: [pipeJunction output isEmpty].
	self should: [pipeJunction errorUpToEnd isEmpty].
	pipeJunction value.
	self should: [pipeJunction runState == #complete].
	self should: [pipeJunction isComplete].
	self should: [pipeJunction exitStatus == #success].
	self should: [pipeJunction succeeded].
	self should: [pipeJunction upToEnd = ('#(#foo #bar)', String lf)].
	self should: [pipeJunction errorUpToEnd isEmpty].

]

{ #category : #Testing }
ExpressionEvaluatorTestCase >> testCommand01 [
	"Command consisting of the Compiler evaluating a String"

	"(self selector: #testCommand01) run"

	pipeJunction := ExpressionEvaluator command: '''Hello world!'''.
	self should: [pipeJunction runState == #notYetRunning].
	self shouldnt: [pipeJunction isComplete].
	self should: [pipeJunction pipeToInput isNil].
	self should: [pipeJunction pipeFromOutput isKindOf: InternalPipe].
	self should: [pipeJunction errorPipelineStream isKindOf: InternalPipe].
	self should: [pipeJunction exitStatus isNil].
	self should: [pipeJunction output isEmpty].
	self should: [pipeJunction errorUpToEnd isEmpty].
	pipeJunction value.
	self should: [pipeJunction runState == #complete].
	self should: [pipeJunction isComplete].
	self should: [pipeJunction exitStatus == #success].
	self should: [pipeJunction succeeded].
	self should: [pipeJunction upToEnd = ('Hello world!', String lf)].
	self should: [pipeJunction errorUpToEnd isEmpty].

]

{ #category : #Testing }
ExpressionEvaluatorTestCase >> testCommand02 [
	"Evaluating an MNU"

	"(self selector: #testCommand02) run"

	pipeJunction := ExpressionEvaluator command: 'Smalltalk noSuchMessage'.
	self should: [pipeJunction runState == #notYetRunning].
	self shouldnt: [pipeJunction isComplete].
	self should: [pipeJunction pipeToInput isNil].
	self should: [pipeJunction pipeFromOutput isKindOf: InternalPipe].
	self should: [pipeJunction errorPipelineStream isKindOf: InternalPipe].
	self should: [pipeJunction exitStatus isNil].
	self should: [pipeJunction output isEmpty].
	self should: [pipeJunction errorUpToEnd isEmpty].
	pipeJunction value.
	self should: [pipeJunction runState == #complete].
	self should: [pipeJunction isComplete].
	self should: [pipeJunction exitStatus == #fail].
	self shouldnt: [pipeJunction succeeded].
	self should: [pipeJunction upToEnd isEmpty].
	self should: [('MessageNotUnderstood: *noSuchMessage', String lf)
 				match: pipeJunction errorUpToEnd]


]

{ #category : #Testing }
ExpressionEvaluatorTestCase >> testCommand03 [
	"Command consisting of the Compiler evaluating an Array new"

	"(self selector: #testCommand03) run"

	pipeJunction := ExpressionEvaluator command: 'Array with: #foo with: #bar'.
	self should: [pipeJunction runState == #notYetRunning].
	self shouldnt: [pipeJunction isComplete].
	self should: [pipeJunction pipeToInput isNil].
	self should: [pipeJunction pipeFromOutput isKindOf: InternalPipe].
	self should: [pipeJunction errorPipelineStream isKindOf: InternalPipe].
	self should: [pipeJunction exitStatus isNil].
	self should: [pipeJunction output isEmpty].
	self should: [pipeJunction errorUpToEnd isEmpty].
	pipeJunction value.
	self should: [pipeJunction runState == #complete].
	self should: [pipeJunction isComplete].
	self should: [pipeJunction exitStatus == #success].
	self should: [pipeJunction succeeded].
	self should: [pipeJunction upToEnd = ('#(#foo #bar)', String lf)].
	self should: [pipeJunction errorUpToEnd isEmpty].

]

{ #category : #Testing }
ExpressionEvaluatorTestCase >> testCommand04 [
	"Evaluating an error condition, no such class"

	"(self selector: #testCommand04) run"

	pipeJunction := ExpressionEvaluator command: 'NoSuchClass new'.
	self should: [pipeJunction runState == #notYetRunning].
	self shouldnt: [pipeJunction isComplete].
	self should: [pipeJunction pipeToInput isNil].
	self should: [pipeJunction pipeFromOutput isKindOf: InternalPipe].
	self should: [pipeJunction errorPipelineStream isKindOf: InternalPipe].
	self should: [pipeJunction exitStatus isNil].
	self should: [pipeJunction output isEmpty].
	self should: [pipeJunction errorUpToEnd isEmpty].
	pipeJunction value.
	self should: [pipeJunction runState == #complete].
	self should: [pipeJunction isComplete].
	self should: [pipeJunction exitStatus == #fail].
	self shouldnt: [pipeJunction succeeded].
	self should: [pipeJunction upToEnd isEmpty].
	self should: [pipeJunction errorUpToEnd = ('Compiler: invalid Smalltalk expression [NoSuchClass new]', String lf)].

]

{ #category : #Testing }
ExpressionEvaluatorTestCase >> testCommand05 [
	"Evaluating an error condition"

	"(self selector: #testCommand05) run"

	pipeJunction := ExpressionEvaluator command: 'lowerCaseClassName new'.
	self should: [pipeJunction runState == #notYetRunning].
	self shouldnt: [pipeJunction isComplete].
	self should: [pipeJunction pipeToInput isNil].
	self should: [pipeJunction pipeFromOutput isKindOf: InternalPipe].
	self should: [pipeJunction errorPipelineStream isKindOf: InternalPipe].
	self should: [pipeJunction exitStatus isNil].
	self should: [pipeJunction output isEmpty].
	self should: [pipeJunction errorUpToEnd isEmpty].
	pipeJunction value.
	self should: [pipeJunction runState == #complete].
	self should: [pipeJunction isComplete].
	self should: [pipeJunction exitStatus == #fail].
	self shouldnt: [pipeJunction succeeded].
	self should: [pipeJunction upToEnd isEmpty].
	self should: [pipeJunction errorUpToEnd = ('Compiler: invalid Smalltalk expression [lowerCaseClassName new]', String lf)].

]

{ #category : #Testing }
ExpressionEvaluatorTestCase >> testCommand06 [
	"Evaluating an error condition"

	"(self selector: #testCommand06) run"

	pipeJunction := ExpressionEvaluator command: 'Smalltalk | | bogusSyntax'.
	self should: [pipeJunction runState == #notYetRunning].
	self shouldnt: [pipeJunction isComplete].
	self should: [pipeJunction pipeToInput isNil].
	self should: [pipeJunction pipeFromOutput isKindOf: InternalPipe].
	self should: [pipeJunction errorPipelineStream isKindOf: InternalPipe].
	self should: [pipeJunction exitStatus isNil].
	self should: [pipeJunction output isEmpty].
	self should: [pipeJunction errorUpToEnd isEmpty].
	pipeJunction value.
	self should: [pipeJunction runState == #complete].
	self should: [pipeJunction isComplete].
	self should: [pipeJunction exitStatus == #fail].
	self shouldnt: [pipeJunction succeeded].
	self should: [pipeJunction upToEnd isEmpty].
	self should: [pipeJunction errorUpToEnd = '[Smalltalk | Argument expected ->| bogusSyntax]
'].

]
