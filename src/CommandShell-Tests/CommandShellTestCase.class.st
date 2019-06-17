"
Unit tests for CommandShell. This tests a reasonable range of command line inputs, verifying command execution and IO redirection for internal and external process proxies.

Many of the tests can try to check for unclosed file handles. The #setUp method sets the value of checkFileHandleCount (true or false) to control this. In addition, the #runAll method can separately do a count of open file handles after running all the tests. Unfortunately, there are a couple of problems with this. First, the check makes use of the /proc filesystem on Linux, which will not be available (or may be implemented differently) on other systems. Second, for reasons which I do not quite understand, files may stay open (or perhaps just appear to stay open in the /proc filesystem) after Squeak has apparently closed them. This produces intermittent failures in the unit tests. For these reasons, I recommend running the file handle count checks once or twice to make sure things are working correctly, then turning the checks off in the #setUp method to avoid seeing intermittent errors later on. If anyone figures out what is going on here, please let me know. -dtl
"
Class {
	#name : #CommandShellTestCase,
	#superclass : #TestCase,
	#instVars : [
		'shell',
		'checkFileHandleCount',
		'procDir'
	],
	#classVars : [
		'CheckFileHandleCount',
		'TempResult'
	],
	#category : #'CommandShell-Tests'
}

{ #category : #'class initialization' }
CommandShellTestCase class >> initialize [
	"CommandShellTestCase initialize"
	"CheckFileHandleCount := true"
	"CheckFileHandleCount := false"

	CheckFileHandleCount := true
]

{ #category : #accessing }
CommandShellTestCase class >> tempResult [
	"A global variable for holding the result of an internal process proxy evaluation.
	This is an ugly kludge."

	^ TempResult
]

{ #category : #accessing }
CommandShellTestCase class >> tempResult: anObject [
	"A global variable for holding the result of an internal process proxy evaluation.
	This is an ugly kludge."

	TempResult := anObject
]

{ #category : #accessing }
CommandShellTestCase >> checkFileHandleCount [
	"If true, attempt to count the number of open file handles before and after
	tests. This uses the /proc file system on Linux, and may work on other systems
	which support a /proc file system."

	^ CheckFileHandleCount
]

{ #category : #private }
CommandShellTestCase >> isNumberOfOpenFiles: anInteger [
	"Answer true if the number of open file handles is anInteger. Wait a little
	bit if necessary to clean up stale references, but give up after a few tries."

	| loops milliseconds |
	self checkFileHandleCount ifFalse: [^ true]. "Bypass the test"
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
CommandShellTestCase >> numberOfOpenFiles [
	"Answer the number of files currently open for this OS process. This works
	only on a system with a /proc filesystem and file descriptors located in a
	directory called /proc/<pid>/fd. On other systems, just answer 0."

	"CommandShellTestCase new numberOfOpenFiles"

	| d |
	self checkFileHandleCount ifFalse: [^ 0]. "Bypass the test"
	^ (d := self procDir) isNil
		ifTrue: [0]
		ifFalse: [(CommandShell directoryEntryNames: d) size]
]

{ #category : #accessing }
CommandShellTestCase >> procDir [
	"Assuming that we have a /proc file system as on Linux (otherwise answer nil)"

	| path |
	^ procDir ifNil:
		[path := '/proc/' , OSProcess thisOSProcess pid printString, '/fd'.
		(CommandShell directoryExists: path) ifTrue: [procDir := path]]

]

{ #category : #running }
CommandShellTestCase >> runAll [
	"Functional failures will be reported as failures, and problems with number
	of open file handles will be reported as errors (they can be intermittent and
	possibly bogus). Note: setting checkFileHandleCount to true here forces a
	count check after all the tests are run. The individual tests may or may
	not do the file count check, depending on what is done in the #setUp method."

	"CommandShellTestCase new checkFileHandleCount: true; runAll"
	"CommandShellTestCase new checkFileHandleCount: false; runAll"

	| result suite openFileCount |
	suite := TestSuite new.
	openFileCount := self numberOfOpenFiles.
	suite addTest: (CommandShellTestCase selector: #testPipeline01).
	suite addTest: (CommandShellTestCase selector: #testPipeline02).
	suite addTest: (CommandShellTestCase selector: #testPipeline03).
	suite addTest: (CommandShellTestCase selector: #testPipeline04).
	suite addTest: (CommandShellTestCase selector: #testPipeline05).
	suite addTest: (CommandShellTestCase selector: #testPipeline06).
	suite addTest: (CommandShellTestCase selector: #testPipeline07).
	suite addTest: (CommandShellTestCase selector: #testPipeline08).
	suite addTest: (CommandShellTestCase selector: #testPipeline09).
	suite addTest: (CommandShellTestCase selector: #testPipeline10).
	suite addTest: (CommandShellTestCase selector: #testPipeline11).
	suite addTest: (CommandShellTestCase selector: #testPipeline12).
	suite addTest: (CommandShellTestCase selector: #testPipeline13).
	suite addTest: (CommandShellTestCase selector: #testPipeline14).
	suite addTest: (CommandShellTestCase selector: #testPipeline20).
	suite addTest: (CommandShellTestCase selector: #testPipeline21).
	suite addTest: (CommandShellTestCase selector: #testPipeline22).
	suite addTest: (CommandShellTestCase selector: #testPipeline23).
	suite addTest: (CommandShellTestCase selector: #testPipeline24).
	suite addTest: (CommandShellTestCase selector: #testPipeline25).
	suite addTest: (CommandShellTestCase selector: #testPipeline26).
	suite addTest: (CommandShellTestCase selector: #testPipeline27).
	suite addTest: (CommandShellTestCase selector: #testPipeline28).
	suite addTest: (CommandShellTestCase selector: #testPipeline30).
	suite addTest: (CommandShellTestCase selector: #testPipeline31).
	suite addTest: (CommandShellTestCase selector: #testPipeline32).
	suite addTest: (CommandShellTestCase selector: #testPipeline33).
	suite addTest: (CommandShellTestCase selector: #testPipeline34).
	suite addTest: (CommandShellTestCase selector: #testPipeline35).
	suite addTest: (CommandShellTestCase selector: #testPipeline36).
	suite addTest: (CommandShellTestCase selector: #testPipeline37).
	suite addTest: (CommandShellTestCase selector: #testPipeline38).
	suite addTest: (CommandShellTestCase selector: #testPipeline39).
	suite addTest: (CommandShellTestCase selector: #testPipeline40).
	suite addTest: (CommandShellTestCase selector: #testPipeline41).
	suite addTest: (CommandShellTestCase selector: #testPipeline42).
	suite addTest: (CommandShellTestCase selector: #testPipeline50).
	suite addTest: (CommandShellTestCase selector: #testPipeline51).
	suite addTest: (CommandShellTestCase selector: #testPipeline52).
	suite addTest: (CommandShellTestCase selector: #testPipeline53).
	suite addTest: (CommandShellTestCase selector: #testPipeline60).
	suite addTest: (CommandShellTestCase selector: #testPipeline61).
	suite addTest: (CommandShellTestCase selector: #testPipeline62).
	suite addTest: (CommandShellTestCase selector: #testPipeline63).
	suite addTest: (CommandShellTestCase selector: #testPipeline64).
	suite addTest: (CommandShellTestCase selector: #testPipeline65).
	suite addTest: (CommandShellTestCase selector: #testPipeline66).
	suite addTest: (CommandShellTestCase selector: #testPipeline70).
	suite addTest: (CommandShellTestCase selector: #testPipeline71).
	suite addTest: (CommandShellTestCase selector: #testPipeline72).
	suite addTest: (CommandShellTestCase selector: #testPipeline73).
	suite addTest: (CommandShellTestCase selector: #testPipeline74).
	suite addTest: (CommandShellTestCase selector: #testPipeline80).
	suite addTest: (CommandShellTestCase selector: #testPipeline81).
	suite addTest: (CommandShellTestCase selector: #testPipeline90).
	suite addTest: (CommandShellTestCase selector: #testPipeline91).
	suite addTest: (CommandShellTestCase selector: #testPipeline92).
	suite addTest: (CommandShellTestCase selector: #testPipeline93).
	suite addTest: (CommandShellTestCase selector: #testPipeline94).
	suite addTest: (CommandShellTestCase selector: #testPipeline95).
	result := suite run.
	self should: [result defects size == 0].
	self should: [self isNumberOfOpenFiles: openFileCount].
	^ result

]

{ #category : #running }
CommandShellTestCase >> setUp [

	(self respondsTo: #timeout: ) "Recent Squeak images with test case timeout"
		ifTrue: [self perform: #timeout: with: 10].
	shell := CommandShell new
]

{ #category : #'testing-expression evaluator' }
CommandShellTestCase >> testBangExpression [
	"Bang character forces evaluation as a Smalltalk expression."

	"(CommandShellTestCase selector: #testBangExpression) debug"

	| pipelines procs openFileCount p o |
	openFileCount := self numberOfOpenFiles.
	self assert: shell outputStream contents isEmpty.
	self assert: shell outputStream isEmpty.
	pipelines := shell evaluateOrMakePipelinesFrom: 'Object new printString!'.
	self assert: 1 equals: pipelines size.
	procs := pipelines last.
	p := procs last.
	self assert: p class == ExpressionEvaluator.
	o := procs output.
	self assert: (o isKindOf: String).
	self assert: o isEmpty.
	procs value.
	o := procs output.
	self deny: o isEmpty.
	self assert: shell outputStream isEmpty.
	self assert: (self isNumberOfOpenFiles: openFileCount)

]

{ #category : #'testing-expression evaluator' }
CommandShellTestCase >> testBangExpressionInPipeline [
	"Input from 'who' command is ignored, and the Smalltalk expression should
	still be evaluated in the pipeline."

	"(CommandShellTestCase selector: #testBangExpressionInPipeline) debug"

	| pipelines procs openFileCount p o |
	openFileCount := self numberOfOpenFiles.
	self assert: shell outputStream contents isEmpty.
	self assert: shell outputStream isEmpty.
	pipelines := shell evaluateOrMakePipelinesFrom: 'who | Object new printString!'.
	self assert: 1 equals: pipelines size.
	procs := pipelines last.
	p := procs last.
	self assert: p class == ExpressionEvaluator.
	o := procs output.
	self assert: (o isKindOf: String).
	self assert: o isEmpty.
	procs value.
	o := procs output.
	self deny: o isEmpty.
	self assert: shell outputStream isEmpty.
	self assert: (self isNumberOfOpenFiles: openFileCount)

]

{ #category : #'testing-scripts' }
CommandShellTestCase >> testCommandOnFailure01 [

	"(CommandShellTestCase selector: #testCommandOnFailure01) run"

	| openFileCount result |
	openFileCount := self numberOfOpenFiles.
	result := shell command: 'ls NO/SUCH/FILE' onFailureDo: ['the command failed'].
	self should: [result = 'the command failed'].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-scripts' }
CommandShellTestCase >> testCommandOnFailure02 [

	"(CommandShellTestCase selector: #testCommandOnFailure02) run"

	| openFileCount result |
	openFileCount := self numberOfOpenFiles.
	result := shell command: 'ls' onFailureDo: ['the command failed'].
	self should: [result isKindOf: OrderedCollection].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-scripts' }
CommandShellTestCase >> testCommandOnFailure03 [

	"(CommandShellTestCase selector: #testCommandOnFailure03) run"

	| openFileCount result |
	openFileCount := self numberOfOpenFiles.
	result := shell command: 'ls NO/SUCH/FILE'
				onFailureDo: [:p | 'the command failed ', p printString].
	self should: ['the command failed*' match: result].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testDoCommandsInString1 [

	"(CommandShellTestCase selector: #testDoCommandsInString1) debug"

	| command procs expectedResult savedResult |

	command := 'help help | CommandShellTestCase tempResult: stdin upToEndOfFile !'.
	procs := shell pipeline: 'help help'.
	expectedResult := procs last output.
	self should: [expectedResult size > 10].
	self class tempResult: nil.
	shell command: command.
	(Delay forSeconds: 1) wait.	"Allow the command to run"
	savedResult := self class tempResult.
	self assert: expectedResult size > 10. "not empty"
	self assert: expectedResult = savedResult

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testDoCommandsInString2 [
	"Note, use #upToEndOfFile to allow external process to run to completion"

	"(CommandShellTestCase selector: #testDoCommandsInString2) debug"

	| command procs expectedResult savedResult |

	command := 'who | CommandShellTestCase tempResult: stdin upToEndOfFile !'.
	procs := shell pipeline: 'who'.
	expectedResult := procs last output.
	self should: [expectedResult size > 10].
	self class tempResult: nil.
	shell command: command.
	(Delay forSeconds: 1) wait.	"Allow the command to run"
	savedResult := self class tempResult.
	self assert: expectedResult size > 10. "not empty"
	self assert: expectedResult = savedResult

]

{ #category : #'testing-expression evaluator' }
CommandShellTestCase >> testEvaluateOrMakePipelinesFrom [

	"(CommandShellTestCase selector: #testEvaluateOrMakePipelinesFrom) debug"

	| command result firstPipeline secondPipeline thirdPipeline firstErrorMessage firstOutput openFileCount |

	openFileCount := self numberOfOpenFiles.
	command := 'ls NOSUCHFILE * | cat | dd | cat | wc; ps | cat& pwd | cat'.
	result := shell evaluateOrMakePipelinesFrom: command.
	result do: [:e | e value].
	self assert: result size == 3.
	firstPipeline := result at: 1.
	secondPipeline := result at: 2.
	thirdPipeline := result at: 3.
	firstOutput := firstPipeline output.
	self assert: ('   *' match: firstOutput).
	firstErrorMessage := firstPipeline errorUpToEnd.
	self assert: ('*NOSUCHFILE*' match: firstErrorMessage).
	self deny: secondPipeline output isEmpty.
	self assert: secondPipeline errorUpToEnd isEmpty.
	self deny: thirdPipeline output isEmpty.
	self assert: thirdPipeline errorUpToEnd isEmpty.
	self should: [self isNumberOfOpenFiles: openFileCount]
]

{ #category : #'testing-scripts' }
CommandShellTestCase >> testIfThenElse01 [

	"(CommandShellTestCase selector: #testIfThenElse01) run"

	| openFileCount result |
	openFileCount := self numberOfOpenFiles.
	result := shell
		if: 'who'
		then: ['the command succeeded']
		else: ['the command failed'].
	self should: ['the command succeeded' = result].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-scripts' }
CommandShellTestCase >> testIfThenElse02 [

	"(CommandShellTestCase selector: #testIfThenElse02) run"

	| openFileCount result |
	openFileCount := self numberOfOpenFiles.
	result := shell
		if: 'ls NO/SUCH/FILE'
		then: ['the command succeeded']
		else: ['the command failed'].
	self should: ['the command failed' = result].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-scripts' }
CommandShellTestCase >> testIfThenElse03 [

	"(CommandShellTestCase selector: #testIfThenElse03) run"

	| openFileCount result |
	openFileCount := self numberOfOpenFiles.
	result := shell
		if: 'who
			ls NO/SUCH/FILE
			who'
		then: [:p |
			self should: [p isKindOf: OrderedCollection].
			self should: [p first succeeded].
			self shouldnt: [p second succeeded].
			self should: [p third succeeded].
			'the command succeeded', p printString]
		else: [:p |
			self should: [p isKindOf: OrderedCollection].
			'the command failed ', p printString].
	self should: ['the command failed*' match: result].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-scripts' }
CommandShellTestCase >> testIfThenElse04 [

	"(CommandShellTestCase selector: #testIfThenElse04) run"

	| openFileCount result |
	openFileCount := self numberOfOpenFiles.
	result := shell
		if: 'who'
		then: [:p |
			self should: [p isKindOf: OrderedCollection].
			'the command succeeded', p printString]
		else: [:p |
			self should: [p isKindOf: OrderedCollection].
			'the command failed ', p printString].
	self should: ['the command succeeded*' match: result].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-expression evaluator' }
CommandShellTestCase >> testInvalidBangExpression [
	"Bang forces evaluation as Smalltalk, with compiler error message going
	to error stream."

	"(CommandShellTestCase selector: #testInvalidBangExpression) debug"

	| pipelines procs openFileCount p o e |
	openFileCount := self numberOfOpenFiles.
	self should: [shell outputStream contents isEmpty].
	self should: shell outputStream isEmpty.
	pipelines := shell evaluateOrMakePipelinesFrom: 'foobar !'.
	self assert: pipelines size = 1.
	procs := pipelines last.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	procs value.
	o := procs output.
	self should: [o isEmpty].
	e := procs errorUpToEnd.
	self should: ['Compiler: invalid Smalltalk expression [foobar ]*' match: e].
	self shouldnt: [e isEmpty].
	self should: shell outputStream isEmpty.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline01 [

	"(CommandShellTestCase selector: #testPipeline01) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ps'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline02 [

	"(CommandShellTestCase selector: #testPipeline02) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'echo hello world'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: ['hello world*' match: o].
	self should: [(CommandShell withBlanksTrimmed: o) = 'hello world'].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline03 [

	"(CommandShellTestCase selector: #testPipeline03) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ps | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline04 [

	"(CommandShellTestCase selector: #testPipeline04) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ps | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline05 [

	"(CommandShellTestCase selector: #testPipeline05) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ps | cat | od | cat'.
	p := procs last.
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline06 [

	"(CommandShellTestCase selector: #testPipeline06) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ps > /tmp/delete.me | cat'.
	p := procs last.
	o := procs output.
	self should: [p class == PipeableOSProcess].
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline07 [

	"(CommandShellTestCase selector: #testPipeline07) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ps > /dev/null | cat'.
	p := procs last.
	o := procs output.
	self should: [p class == PipeableOSProcess].
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline08 [

	"(CommandShellTestCase selector: #testPipeline08) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'cat < /etc/passwd | cat'.
	p := procs last.
	o := procs output.
	self should: [p class == PipeableOSProcess].
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline09 [

	"(CommandShellTestCase selector: #testPipeline09) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ls /etc/hosts /etc/NOSUCHFILE 2> /tmp/delete.me | cat'.
	p := procs last.
	o := procs output.
	self should: [p class == PipeableOSProcess].
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline10 [

	"(CommandShellTestCase selector: #testPipeline10) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ps | cat > /tmp/delete.me | cat'.
	p := procs last.
	o := procs output.
	self should: [p class == PipeableOSProcess].
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline11 [

	"(CommandShellTestCase selector: #testPipeline11) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ps | cat > /dev/null | cat'.
	p := procs last.
	o := procs output.
	self should: [p class == PipeableOSProcess].
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline12 [

	"(CommandShellTestCase selector: #testPipeline12) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ps | cat < /etc/passwd | cat'.
	p := procs last.
	o := procs output.
	self should: [p class == PipeableOSProcess].
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	(self numberOfOpenFiles == openFileCount) ifFalse: [Smalltalk garbageCollect].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline13 [

	"(CommandShellTestCase selector: #testPipeline13) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'who | ls /etc/hosts /etc/NOSUCHFILE 2> /tmp/delete.me | cat'.
	p := procs last.
	o := procs output.
	self should: [p class == PipeableOSProcess].
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline14 [

	"(CommandShellTestCase selector: #testPipeline14) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | cat < /etc/passwd | cat'.
	p := procs last.
	o := procs output.
	self should: [p class == PipeableOSProcess].
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline20 [

	"(CommandShellTestCase selector: #testPipeline20) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline21 [

	"(CommandShellTestCase selector: #testPipeline21) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput > /tmp/delete.me | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline22 [

	"(CommandShellTestCase selector: #testPipeline22) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput 2> /tmp/delete.me | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty not].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline23 [

	"(CommandShellTestCase selector: #testPipeline23) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput 2 > /dev/null | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline24 [

	"(CommandShellTestCase selector: #testPipeline24) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput>/tmp/delete.me | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline25 [

	"(CommandShellTestCase selector: #testPipeline25) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput2>/tmp/delete.me | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty not].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline26 [

	"(CommandShellTestCase selector: #testPipeline26) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput < /etc/hosts | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty not].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline27 [

	"(CommandShellTestCase selector: #testPipeline27) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput < /etc/hosts | copyToError'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline28 [

	"(CommandShellTestCase selector: #testPipeline28) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ls -l | copyToOutput < /etc/hosts | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty not].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline30 [

	"(CommandShellTestCase selector: #testPipeline30) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline31 [

	"(CommandShellTestCase selector: #testPipeline31) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput > /tmp/delete.me | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline32 [

	"(CommandShellTestCase selector: #testPipeline32) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput 2> /tmp/delete.me | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty not].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline33 [

	"(CommandShellTestCase selector: #testPipeline33) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput 2> /dev/null | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline34 [

	"(CommandShellTestCase selector: #testPipeline34) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput>/tmp/delete.me | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline35 [

	"(CommandShellTestCase selector: #testPipeline35) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput2>/tmp/delete.me | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty not].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline36 [

	"(CommandShellTestCase selector: #testPipeline36) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput < /etc/hosts | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty not].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline37 [

	"(CommandShellTestCase selector: #testPipeline37) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ls -l | copyToOutput < /etc/hosts | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty not].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline38 [

	"(CommandShellTestCase selector: #testPipeline38) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline39 [

	"(CommandShellTestCase selector: #testPipeline39) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help > /tmp/delete.me | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline40 [

	"(CommandShellTestCase selector: #testPipeline40) run"

	| procs p o openFileCount fs |
	openFileCount := self numberOfOpenFiles.
	CommandShell deleteFileNamed: '/tmp/delete.me'.	
	procs := shell pipeline: 'ps > /tmp/delete.me'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	fs := FileStream fileNamed: '/tmp/delete.me'.
	self should: [fs upToEnd isEmpty not].
	fs close.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline41 [

	"(CommandShellTestCase selector: #testPipeline41) run"

	| procs p o openFileCount fs |
	openFileCount := self numberOfOpenFiles.
	CommandShell deleteFileNamed: '/tmp/delete.me'.	
	procs := shell pipeline: 'ls /etc/hosts /NO/SUCH/FILE 2> /tmp/delete.me'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	fs := FileStream fileNamed: '/tmp/delete.me'.
	self should: [fs upToEnd isEmpty not].
	fs close.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline42 [

	"(CommandShellTestCase selector: #testPipeline42) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'cat < /etc/hosts'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline43 [

	"(CommandShellTestCase selector: #testPipeline43) run"

	| procs p o e openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput 2> /tmp/delete.me | noSuchCommand'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].

	self shouldnt: [p succeeded].

	o := procs upToEnd.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	e := p errorUpToEnd.
	self should: [e isKindOf: String].
	self shouldnt: [e isEmpty].
	self should: [procs output isEmpty]. "Force read to EOF, closes output pipe"
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline44 [

	"(CommandShellTestCase selector: #testPipeline44) run"

	| procs p o e openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'copyToOutput | noSuchCommand'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	self shouldnt: [p succeeded].
	o := procs upToEnd.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	e := p errorUpToEnd.
	self should: [e isKindOf: String].
	self shouldnt: [e isEmpty].
	self should: [procs output isEmpty]. "Force read to EOF, closes output pipe"
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline45 [

	"(CommandShellTestCase selector: #testPipeline45) run"

	| procs p o e openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | noSuchCommand'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].

	self shouldnt: [p succeeded].

	o := procs upToEnd.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	e := p errorUpToEnd.
	self should: [e isKindOf: String].
	self shouldnt: [e isEmpty].
	self should: [procs output isEmpty]. "Force read to EOF, closes output pipe"
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline46 [

	"(CommandShellTestCase selector: #testPipeline46) run"

	| procs p o e openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | who'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs upToEndOfFile. "wait for output, otherwise may be lost when in polling mode"
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	e := p errorUpToEnd.
	self should: [e isKindOf: String].
	self should: [e isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline47 [

	"(CommandShellTestCase selector: #testPipeline47) run"

	| procs p o e openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | sleep 1'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs upToEnd.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	e := p errorUpToEnd.
	self should: [e isKindOf: String].
	self should: [e isEmpty].
	self should: [procs output isEmpty]. "Force read to EOF, closes output pipe"
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline48 [

	"(CommandShellTestCase selector: #testPipeline48) run"

	| procs p o e openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'who | noSuchCommand'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].

	self shouldnt: [p succeeded].

	o := procs upToEnd.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	e := p errorUpToEnd.
	self should: [e isKindOf: String].
	self shouldnt: [e isEmpty].
	self should: [procs output isEmpty]. "Force read to EOF, closes output pipe"
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline49 [

	"(CommandShellTestCase selector: #testPipeline49) run"

	| procs p o e openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help | copyToOutput 2> /tmp/delete.me | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].

	self should: [p succeeded].

	o := procs upToEnd.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	e := p errorUpToEnd.
	self should: [e isKindOf: String].
	self should: [e isEmpty].
	self should: [procs output isEmpty]. "Force read to EOF, closes output pipe"
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline50 [

	"(CommandShellTestCase selector: #testPipeline50) run"

	| procs p o openFileCount fs |
	openFileCount := self numberOfOpenFiles.
	CommandShell deleteFileNamed: '/tmp/delete.me'.	
	procs := shell pipeline: 'help > /tmp/delete.me'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	procs finalize.
	procs := CommandShell new pipeline: 'cat /tmp/delete.me'.
	self shouldnt: [procs last output isEmpty].
	fs := FileStream fileNamed: '/tmp/delete.me'.
	self should: [fs upToEnd isEmpty not].
	fs close.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline51 [

	"(CommandShellTestCase selector: #testPipeline51) run"

	| openFileCount procs p o fs |
	openFileCount := self numberOfOpenFiles.
	CommandShell deleteFileNamed: '/tmp/delete.me'.	
	procs := shell pipeline: 'copyToError /etc/hosts 2> /tmp/delete.me'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	fs := FileStream fileNamed: '/tmp/delete.me'.
	self should: [fs upToEnd isEmpty not].
	fs close.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline52 [

	"(CommandShellTestCase selector: #testPipeline52) run"

	| procs p o openFileCount fs |
	openFileCount := self numberOfOpenFiles.
	CommandShell deleteFileNamed: '/tmp/delete.me'.	
	procs := shell pipeline: 'copyToError < /etc/hosts 2> /tmp/delete.me'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	fs := FileStream fileNamed: '/tmp/delete.me'.
	self should: [fs upToEnd isEmpty not].
	fs close.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline53 [

	"(CommandShellTestCase selector: #testPipeline53) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'copyToOutput < /etc/hosts'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline60 [

	"(CommandShellTestCase selector: #testPipeline60) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	CommandShell deleteFileNamed: '/tmp/delete.me'.	
	procs := shell pipeline: 'Smalltalk! > /tmp/delete.me'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	procs finalize.
	procs := CommandShell new pipeline: 'cat /tmp/delete.me'.
	self shouldnt: [procs last output isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline61 [

	"(CommandShellTestCase selector: #testPipeline61) run"

	| procs p o openFileCount fs |
	openFileCount := self numberOfOpenFiles.
	CommandShell deleteFileNamed: '/tmp/delete.me'.	
	procs := shell pipeline: 'stdout nextPutAll: ''Hello world!'' ! > /tmp/delete.me'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	fs := FileStream fileNamed: '/tmp/delete.me'.
	self should: [fs upToEnd isEmpty not].
	fs close.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline62 [

	"(CommandShellTestCase selector: #testPipeline62) run"

	| procs p o openFileCount fs |
	openFileCount := self numberOfOpenFiles.
	CommandShell deleteFileNamed: '/tmp/delete.me'.	
	procs := shell pipeline: 'stderr nextPutAll: ''Hello stderr'' ! 2> /tmp/delete.me'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	fs := FileStream fileNamed: '/tmp/delete.me'.
	self should: [fs upToEnd isEmpty not].
	fs close.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline63 [

	"(CommandShellTestCase selector: #testPipeline63) run"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'stdin upToEnd ! < /etc/hosts'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline64 [

	"(CommandShellTestCase selector: #testPipeline64) run"

	| procs p o openFileCount fs |
	openFileCount := self numberOfOpenFiles.
	CommandShell deleteFileNamed: '/tmp/delete.me'.	
	procs := shell pipeline: 'stdout nextPutAll: stdin upToEnd ! < /etc/hosts > /tmp/delete.me'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	fs := FileStream fileNamed: '/tmp/delete.me'.
	self should: [fs upToEnd isEmpty not].
	fs close.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline65 [
	"Run a fairly long Smalltalk expression and make sure the complete output
	gets picked up by the next internal process in the pipeline."

	"(CommandShellTestCase selector: #testPipeline65) run"

	| procs p o last |
	(Smalltalk respondsTo: #asArray)
		ifTrue: ["traditional system dictionary"
			last := (Smalltalk asArray first: 300) printString last: 20.
			procs := shell pipeline: 'Smalltalk asArray first: 300! | copyToOutput']
		ifFalse: ["newer image with refactored system dictionary"
			(Smalltalk respondsTo: #globals)
				ifFalse: [self error: 'unknown system dictionary organization'].
			last := (Smalltalk globals keys first: 300) printString last: 20.
			procs := shell pipeline: 'Smalltalk globals keys first: 300! | copyToOutput'].
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	"n.b. remove trailing line terminator from command output"
	self should: (o last: 21) allButLast = last

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline66 [
	"Run a fairly long Smalltalk expression and make sure the complete output
	gets picked up by the next internal process in the pipeline."

	"Warning: This test will produce a deadlock condition if the Smalltalk
	expression runs too long."

	"(CommandShellTestCase selector: #testPipeline66) run"

	| procs p o last count |
	count := 150. "<== Make this smaller if you get a deadlock"
	(Smalltalk respondsTo: #asArray)
		ifTrue: ["traditional system dictionary"
			last := (Smalltalk asArray first: count) last printString.
			procs := shell pipeline: 'Smalltalk asArray first: ', count printString, '! | cat']
		ifFalse: ["newer image with refactored system dictionary"
			(Smalltalk respondsTo: #globals)
				ifFalse: [self error: 'unknown system dictionary organization'].
			last := (Smalltalk globals keys first: count) last printString.
			procs := shell pipeline: 'Smalltalk globals keys first: ', count printString, '! | cat'].
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [((o copyFrom: (o size - (last size + 1)) to: o size) allButLast allButLast) = last]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline67 [

	"(CommandShellTestCase selector: #testPipeline67) run"

	| procs p o openFileCount e |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'bogusExpression !'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	e := procs errorUpToEnd.
	self assert: (('Compiler: invalid Smalltalk expression [bogusExpression ]', String lf) = e).
	procs finalize.
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline70 [

	"(CommandShellTestCase selector: #testPipeline70) run"

	| procs p o openFileCount e |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ls /no/such/file'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	e := procs errorUpToEnd.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [e isKindOf: String].
	self shouldnt: [e isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline71 [

	"(CommandShellTestCase selector: #testPipeline71) run"

	| procs p o openFileCount e |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ls /no/such/file | cat'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs output.
	e := p errorPipelineStream contents.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [e isKindOf: String].
	self shouldnt: [e isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline72 [

	"(CommandShellTestCase selector: #testPipeline72) run"

	| procs p o openFileCount e |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ls /no/such/file | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	e := p errorPipelineStream contents.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [e isKindOf: String].
	self shouldnt: [e isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline73 [

	"(CommandShellTestCase selector: #testPipeline73) run"

	| procs p o openFileCount e |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ls /no/such/file | stdout nextPutAll: stdin upToEnd !'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	o := procs upToEnd.
	e := p errorPipelineStream contents.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [e isKindOf: String].
	self shouldnt: [e isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline74 [

	"(CommandShellTestCase selector: #testPipeline74) run"

	| procs p o openFileCount e |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ls /no/such/file | stdout nextPutAll: stdin upToEnd ! | cat | copyToOutput | cat | cat | copyToOutput | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	e := p errorPipelineStream contents.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [e isKindOf: String].
	self shouldnt: [e isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline75 [

	"(CommandShellTestCase selector: #testPipeline75) run"

	| procs p o openFileCount e |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ls /no/such/file | stdout nextPutAll: stdin upToEnd ! | cat | copyToOutput | cat | cat | copyToOutput | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs output.
	e := procs errorUpToEnd.
	self should: [o isKindOf: String].
	self should: [o isEmpty].
	self should: [e isKindOf: String].
	self shouldnt: [e isEmpty].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline80 [
	"Test error streaming for a PipeableOSProcess"

	"(CommandShellTestCase selector: #testPipeline80) run"

	| procs p o openFileCount errorLength e1 e2 |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ls /etc/hosts /NO/SUCH/FILE'.
	p := procs last.
	self should: [p class == PipeableOSProcess].
	o := procs upToEndOfFile. "wait for output, otherwise may be lost when in polling mode"
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	errorLength := p errorPipelineStream size.
	e1 := procs nextFromError: 15.
	e2 := procs errorUpToEnd.
	self should: [errorLength == (e1 size + (e2 size))].
	self should: [procs errorUpToEnd isEmpty].
	self should: [p errorPipelineStream upToEnd size = 0].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline81 [
	"Test error streaming for a ShellBuiltinEvaluator"

	"(CommandShellTestCase selector: #testPipeline81) run"

	| procs p o openFileCount errorLength e1 e2 |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'ls /etc/hosts /NO/SUCH/FILE | copyToOutput'.
	p := procs last.
	self should: [p class == ShellBuiltinEvaluator].
	o := procs upToEnd.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	errorLength := p errorPipelineStream size.
	e1 := procs nextFromError: 15.
	e2 := procs errorUpToEnd.
	self should: [errorLength == (e1 size + (e2 size))].
	self should: [procs errorUpToEnd isEmpty].
	self should: [p errorPipelineStream size == 0].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline90 [
	"Test Smalltalk expression as the complete command. Do not worry about the
	actual output, as it gets clobbered by the prompt."

	"(CommandShellTestCase selector: #testPipeline90) run"

	| o |
	shell command: 'Smalltalk classNames size'.
	o := shell outputStream contents.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	self should: [o size > 3]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline91 [
	"Test Smalltalk expression as the complete command"

	"(CommandShellTestCase selector: #testPipeline91) run"

	| numberOfClasses p o numberCounted |
	numberOfClasses := Smalltalk classNames size.
	p := shell tryEvaluatingAsSmalltalk: 'Smalltalk classNames size'.
	self should: [p class == ExpressionEvaluator].
	self should: [p isComplete].
	o := p upToEnd.
	self should: [o isKindOf: String].
	self shouldnt: [o isEmpty].
	numberCounted := o asInteger.
	self should: [numberCounted == numberOfClasses]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline92 [
	"Test Smalltalk expression as the complete command"

	"(CommandShellTestCase selector: #testPipeline92) run"

	| p o |
	p := shell tryEvaluatingAsSmalltalk: '#Smalltalk classNames size'.
	self should: [p class == ExpressionEvaluator].
	self should: [p isComplete].
	self should: [p exitStatus == #fail].
	o := p upToEnd.
	self should: [o isKindOf: String].
	self should: [o isEmpty]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline93 [
	"Test Smalltalk expression as the complete command. Should fail in compiler."

	"(CommandShellTestCase selector: #testPipeline93) run"

	| p o |
	p := shell tryEvaluatingAsSmalltalk: 'Smalltalk classNames size!'.
	self should: [p class == ExpressionEvaluator].
	self should: [p isComplete].
	self should: [p exitStatus == #fail].
	o := p upToEnd.
	self should: [o isKindOf: String].
	self should: [o isEmpty]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline94 [
	"Test Smalltalk expression as the complete command. Should fail in evaluation."

	"(CommandShellTestCase selector: #testPipeline94) run"

	| p o |
	p := shell tryEvaluatingAsSmalltalk: 'Smalltalk noSuchSelector'.
	self should: [p class == ExpressionEvaluator].
	self should: [p isComplete].
	self should: [p exitStatus == #fail].
	o := p upToEnd.
	self should: [o isKindOf: String].
	self should: [o isEmpty]

]

{ #category : #'testing-pipelines' }
CommandShellTestCase >> testPipeline95 [
	"Test Smalltalk expression as the complete command. Should fail in compiler."

	"(CommandShellTestCase selector: #testPipeline95) run"

	| p o |
	p := shell tryEvaluatingAsSmalltalk: '(Smalltalk classNames size'.
	self should: [p class == ExpressionEvaluator].
	self should: [p isComplete].
	self should: [p exitStatus == #fail].
	o := p upToEnd.
	self should: [o isKindOf: String].
	self should: [o isEmpty]

]

{ #category : #'testing-scripts' }
CommandShellTestCase >> testScriptOnFailure01 [

	"(CommandShellTestCase selector: #testScriptOnFailure01) run"

	| openFileCount result |
	openFileCount := self numberOfOpenFiles.
	result := shell
		script: 'who
				help
				ls -l NOSUCHFILE
				help'
		onFailureDo: [:p | 'the pipeline collection that failed was ', p printString].
	self should: ['the pipeline collection *' match: result].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-scripts' }
CommandShellTestCase >> testScriptOnFailure02 [

	"(CommandShellTestCase selector: #testScriptOnFailure02) run"

	| openFileCount result |
	openFileCount := self numberOfOpenFiles.
	result := shell
		script: 'who
				help
				ls
				help'
		onFailureDo: [:p | 'the pipeline collection that failed was ', p printString].
	self should: [result isKindOf: OrderedCollection].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-scripts' }
CommandShellTestCase >> testScriptOnFailure03 [

	"(CommandShellTestCase selector: #testScriptOnFailure03) run"

	| openFileCount result |
	openFileCount := self numberOfOpenFiles.
	result := shell
		script: 'who
				help
				ls -l NOSUCHFILE
				help'
		onFailureDo: ['the pipeline collection failed'].
	self should: ['the pipeline collection failed' = result].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-expression evaluator' }
CommandShellTestCase >> testSimpleExpression [
	"Simple expression is directly evaluated by the shell and does not produce
	a pipeline collection."

	"(CommandShellTestCase selector: #testSimpleExpression) debug"

	| procs openFileCount |
	openFileCount := self numberOfOpenFiles.
	self assert: shell outputStream contents isEmpty.
	procs := shell evaluateOrMakePipelinesFrom: 'Object new printString'.
	self assert: #() equals: procs.
	self deny: shell outputStream contents isEmpty.
	self assert: (self isNumberOfOpenFiles: openFileCount)

]

{ #category : #'testing-expression evaluator' }
CommandShellTestCase >> testStdinPseudoVariable [

	"(CommandShellTestCase selector: #testStdinPseudoVariable) debug"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help help | stdin upToEnd !'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty not].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-expression evaluator' }
CommandShellTestCase >> testStdinPseudoVariableFromExternalProcess [

	"(CommandShellTestCase selector: #testStdinPseudoVariableFromExternalProcess) debug"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'who | stdin upToEndOfFile !'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty not].
	self should: [self isNumberOfOpenFiles: openFileCount]

]

{ #category : #'testing-expression evaluator' }
CommandShellTestCase >> testStdinPseudoVariableUpToEndOfFile [

	"(CommandShellTestCase selector: #testStdinPseudoVariableUpToEndOfFile) debug"

	| procs p o openFileCount |
	openFileCount := self numberOfOpenFiles.
	procs := shell pipeline: 'help help | stdin upToEndOfFile !'.
	p := procs last.
	self should: [p class == ExpressionEvaluator].
	o := procs output.
	self should: [o isKindOf: String].
	self should: [o isEmpty not].
	self should: [self isNumberOfOpenFiles: openFileCount]

]
