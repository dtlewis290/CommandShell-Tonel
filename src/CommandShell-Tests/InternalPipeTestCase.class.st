"
Test operation of InternalPipe in blocking and nonBlocking mode.
"
Class {
	#name : #InternalPipeTestCase,
	#superclass : #TestCase,
	#instVars : [
		'pipe'
	],
	#category : 'CommandShell-Tests'
}

{ #category : #private }
InternalPipeTestCase >> readFromAndClose: aPipe writingTo: aStream [

	| s |
	[aPipe atEnd] whileFalse:
		[s := aPipe next: 10000.
		aStream nextPutAll: s asString.
		(Delay forMilliseconds: 100) wait].
	(aPipe respondsTo: #reader) ifTrue: [aPipe reader close].
	^ aStream

]

{ #category : #running }
InternalPipeTestCase >> runAll [

	"InternalPipeTestCase new runAll"

	| result suite |
	suite := TestSuite new.
	suite addTest: (InternalPipeTestCase selector: #testBlocking).
	suite addTest: (InternalPipeTestCase selector: #testNonBlocking).
	result := suite run.
	self should: [result defects size == 0].
	^ result

]

{ #category : #running }
InternalPipeTestCase >> setUp [

		pipe := InternalPipe new

]

{ #category : #testing }
InternalPipeTestCase >> testBlocking [

	"(InternalPipeTestCase selector: #testBlocking) run"

	| resultString |
	pipe setBlocking.
	self writeStuffOnThenClose: pipe.
	Processor yield.
	resultString := pipe upToEnd last: 16.
	self should: [resultString notNil].
	self should: ['this is line 10*' match: resultString]

]

{ #category : #testing }
InternalPipeTestCase >> testNonBlocking [

	"(InternalPipeTestCase selector: #testNonBlocking) run"

	| ws str |
	pipe setNonBlocking.
	self writeStuffOnThenClose: pipe.
	ws := self readFromAndClose: pipe writingTo: (WriteStream on: String new).
	str := (ws contents last: 16).
	self should: ['this is line 10*' match: str]

]

{ #category : #private }
InternalPipeTestCase >> writeStuffOnThenClose: aPipe [

	^ [(1 to: 10) do:
		[:i |
		aPipe nextPutAll: 'this is line ', i printString; cr.
		(Delay forMilliseconds: 100) wait].
	(aPipe respondsTo: #writer)
		ifTrue: [aPipe writer close]
		ifFalse: [aPipe close]] forkAt: Processor userInterruptPriority
]
