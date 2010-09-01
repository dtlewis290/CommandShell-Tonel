"
This test case does not directly correspond to a class. It tests the setup of events
in the proxies and pipes of a ProxyPipeline constructed in cooperation with a
CommandShell.

"
Class {
	#name : #PipelineEventsTestCase,
	#superclass : #TestCase,
	#instVars : [
		'shell',
		'checkFileHandleCount',
		'procDir'
	],
	#classVars : [
		'TempResult'
	],
	#category : #'CommandShell-Tests'
}

{ #category : #accessing }
PipelineEventsTestCase class >> tempResult [
	"A global variable for holding the result of an internal process proxy evaluation.
	This is an ugly kludge."

	^ TempResult
]

{ #category : #accessing }
PipelineEventsTestCase class >> tempResult: anObject [
	"A global variable for holding the result of an internal process proxy evaluation.
	This is an ugly kludge."

	TempResult := anObject
]

{ #category : #running }
PipelineEventsTestCase >> runAll [

	"self new runAll"

	| result suite |
	suite := TestSuite new.

	"testing - external proxy events"
	suite addTest: (self class selector: #testExternalPipelineEvents01).
	suite addTest: (self class selector: #testExternalPipelineEvents02).
	suite addTest: (self class selector: #testExternalProxyEvents01).
	suite addTest: (self class selector: #testExternalProxyEvents02).
	suite addTest: (self class selector: #testExternalProxyEvents03).
	suite addTest: (self class selector: #testExternalProxyEvents04).
	suite addTest: (self class selector: #testExternalProxyErrorPipelineEvents).

	"testing - internal proxy events"
	suite addTest: (self class selector: #testInternalPipelineEvents01).
	suite addTest: (self class selector: #testInternalPipelineEvents02).
	suite addTest: (self class selector: #testInternalProxyEvents01).
	suite addTest: (self class selector: #testInternalProxyEvents02).
	suite addTest: (self class selector: #testInternalProxyEvents03).
	suite addTest: (self class selector: #testInternalProxyEvents04).
	suite addTest: (self class selector: #testInternalProxyErrorPipelineEvents).

	result := suite run.
	self should: [result defects size == 0].
	^ result

]

{ #category : #'testing - external proxy events' }
PipelineEventsTestCase >> testExternalPipelineEvents01 [
	"No dependents for the pipeline (use events instead)"

	"(self selector: #testExternalPipelineEvents01) run"

	| pipeline |
	pipeline := self threeExternalProxies.
	self assert: pipeline dependents isEmpty.

]

{ #category : #'testing - external proxy events' }
PipelineEventsTestCase >> testExternalPipelineEvents02 [
	"No events are defined for the pipeline"

	"(self selector: #testExternalPipelineEvents02) run"

	| pipeline |
	pipeline := self threeExternalProxies.
	self assert: pipeline actionMap isEmpty

]

{ #category : #'testing - external proxy events' }
PipelineEventsTestCase >> testExternalProxyErrorPipelineEvents [

	"(self selector: #testExternalProxyErrorPipelineEvents) run"

	| pipeline |
	pipeline := self threeExternalProxies.

	"The proxies share an errorPipelineStream."
	self assert: pipeline errorPipelineStream == pipeline first errorPipelineStream.
	self assert: pipeline errorPipelineStream == pipeline second errorPipelineStream.
	self assert: pipeline errorPipelineStream == pipeline third errorPipelineStream.

	"The error pipeline has no events defined."
	self assert: pipeline errorPipelineStream actionMap isEmpty.

	"The error pipeline has no dependents."
	self assert: pipeline errorPipelineStream dependents isEmpty.

]

{ #category : #'testing - external proxy events' }
PipelineEventsTestCase >> testExternalProxyEvents01 [
	"A pipeline is a dependent of the last proxy, which sends #changed: when
	complete. Predecessor proxies could complete out of order if outputs or
	inputs, have been redirected, so the pipeline must ensure that all its
	proxies are complete after the last proxy has indicated its completion."

	"(self selector: #testExternalProxyEvents01) run"

	| pipeline |
	pipeline := self threeExternalProxies.
	self assert: pipeline first dependents isEmpty.
	self assert: pipeline second dependents isEmpty.
	self assert: pipeline third dependents size = 1.
	self assert: pipeline third dependents first == pipeline

]

{ #category : #'testing - external proxy events' }
PipelineEventsTestCase >> testExternalProxyEvents02 [
	"No actions defined for the elements of a pipeline. Note: Some earlier development
	versions of CommandShell used events heavily, but this was complex and provided
	poor performance."

	"(self selector: #testExternalProxyEvents02) run"

	| pipeline |
	pipeline := self threeExternalProxies.
	self assert: pipeline first actionMap isEmpty.
	self assert: pipeline second actionMap isEmpty.
	self assert: pipeline third actionMap isEmpty.

]

{ #category : #'testing - external proxy events' }
PipelineEventsTestCase >> testExternalProxyEvents03 [
	"Proxy error data ready events and dependents"

	"(self selector: #testExternalProxyEvents03) run"

	| pipeline proxyOne proxyTwo proxyThree |
	pipeline := self threeExternalProxies.

	proxyOne := pipeline first.
	self assert: proxyOne pipeFromError dependents size = 1.
	self assert: proxyOne pipeFromError dependents first == proxyOne.
	self assert: proxyOne pipeFromError actionMap isEmpty.

	proxyTwo := pipeline second.
	self assert: proxyTwo pipeFromError dependents size = 1.
	self assert: proxyTwo pipeFromError dependents first == proxyTwo.
	self assert: proxyTwo pipeFromError actionMap isEmpty.

	proxyThree := pipeline third.
	self assert: proxyThree pipeFromError dependents size = 1.
	self assert: proxyThree pipeFromError dependents first == proxyThree.
	self assert: proxyThree pipeFromError actionMap isEmpty.

]

{ #category : #'testing - external proxy events' }
PipelineEventsTestCase >> testExternalProxyEvents04 [
	"Proxy output data ready events and dependents"

	"(self selector: #testExternalProxyEvents04) run"

	| pipeline proxyOne proxyTwo proxyThree |
	pipeline := self threeExternalProxies.

	proxyOne := pipeline first.
	self assert: proxyOne pipeFromOutput dependents size = 1.
	self assert: proxyOne pipeFromOutput dependents first == proxyOne.
	self assert: proxyOne pipeFromOutput actionMap isEmpty.

	proxyTwo := pipeline second.
	self assert: proxyTwo pipeFromOutput dependents size = 1.
	self assert: proxyTwo pipeFromOutput dependents first == proxyTwo.
	self assert: proxyTwo pipeFromOutput actionMap isEmpty.

	proxyThree := pipeline third.
	self assert: proxyThree pipeFromOutput dependents size = 1.
	self assert: proxyThree pipeFromOutput dependents first == proxyThree.
	self assert: proxyThree pipeFromOutput actionMap isEmpty.

]

{ #category : #'testing - internal proxy events' }
PipelineEventsTestCase >> testInternalPipelineEvents01 [
	"No dependents for the pipeline (use events instead)"

	"(self selector: #testInternalPipelineEvents01) run"

	| pipeline |
	pipeline := self threeInternalProxies.
	self assert: pipeline dependents isEmpty.

]

{ #category : #'testing - internal proxy events' }
PipelineEventsTestCase >> testInternalPipelineEvents02 [
	"No events are defined for the pipeline"

	"(self selector: #testInternalPipelineEvents02) run"

	| pipeline |
	pipeline := self threeInternalProxies.
	self assert: pipeline actionMap isEmpty

]

{ #category : #'testing - internal proxy events' }
PipelineEventsTestCase >> testInternalProxyErrorPipelineEvents [

	"(self selector: #testInternalProxyErrorPipelineEvents) run"

	| pipeline |
	pipeline := self threeInternalProxies.

	"The proxies share an errorPipelineStream."
	self assert: pipeline errorPipelineStream == pipeline first errorPipelineStream.
	self assert: pipeline errorPipelineStream == pipeline second errorPipelineStream.
	self assert: pipeline errorPipelineStream == pipeline third errorPipelineStream.

	"The error pipeline has no events defined."
	self assert: pipeline errorPipelineStream actionMap isEmpty.

	"Internal proxies are dependents of the errorPipelineStream, because they
	use is directly as their pipeFromError."
	self assert: (pipeline errorPipelineStream dependents size = 3).

]

{ #category : #'testing - internal proxy events' }
PipelineEventsTestCase >> testInternalProxyEvents01 [
	"A pipeline is a dependent of the last proxy, which sends #changed: when
	complete. Predecessor proxies could complete out of order if outputs or
	inputs, have been redirected, so the pipeline must ensure that all its
	proxies are complete after the last proxy has indicated its completion."

	"(self selector: #testInternalProxyEvents01) run"

	| pipeline |
	pipeline := self threeInternalProxies.
	self assert: pipeline first dependents isEmpty.
	self assert: pipeline second dependents isEmpty.
	self assert: pipeline third dependents size = 1.
	self assert: pipeline third dependents first == pipeline

]

{ #category : #'testing - internal proxy events' }
PipelineEventsTestCase >> testInternalProxyEvents02 [
	"No actions defined for the elements of a pipeline. Note: Some earlier development
	versions of CommandShell used events heavily, but this was complex and provided
	poor performance."

	"(self selector: #testInternalProxyEvents02) run"

	| pipeline |
	pipeline := self threeInternalProxies.
	self assert: pipeline first actionMap isEmpty.
	self assert: pipeline second actionMap isEmpty.
	self assert: pipeline third actionMap isEmpty.

]

{ #category : #'testing - internal proxy events' }
PipelineEventsTestCase >> testInternalProxyEvents03 [
	"Proxy error data ready events and dependents. Internal proxies do not have
	pipeFromError streams, instead they use the errorPipelineStream directly.
	No events or dependencies are required."

	"(self selector: #testInternalProxyEvents03) run"

	| pipeline proxyOne proxyTwo proxyThree |
	pipeline := self threeInternalProxies.

	proxyOne := pipeline first.
	self assert: proxyOne pipeFromError dependents size = 3.
	self assert: (proxyOne pipeFromError dependents includes: proxyOne).
	self assert: proxyOne pipeFromError actionMap isEmpty.

	proxyTwo := pipeline second.
	self assert: proxyTwo pipeFromError dependents size = 3.
	self assert: (proxyOne pipeFromError dependents includes: proxyTwo).
	self assert: proxyTwo pipeFromError actionMap isEmpty.

	proxyThree := pipeline third.
	self assert: proxyThree pipeFromError dependents size = 3.
	self assert: (proxyOne pipeFromError dependents includes: proxyThree).
	self assert: proxyThree pipeFromError actionMap isEmpty.

]

{ #category : #'testing - internal proxy events' }
PipelineEventsTestCase >> testInternalProxyEvents04 [
	"Proxy output data ready events and dependents"

	"(self selector: #testInternalProxyEvents04) run"

	| pipeline proxyOne proxyTwo proxyThree |
	pipeline := self threeInternalProxies.

	proxyOne := pipeline first.
	self assert: proxyOne pipeFromOutput dependents size = 1.
	self assert: proxyOne pipeFromOutput dependents first == proxyOne.
	self assert: proxyOne pipeFromOutput actionMap isEmpty.

	proxyTwo := pipeline second.
	self assert: proxyTwo pipeFromOutput dependents size = 1.
	self assert: proxyTwo pipeFromOutput dependents first == proxyTwo.
	self assert: proxyTwo pipeFromOutput actionMap isEmpty.

	proxyThree := pipeline third.
	self assert: proxyThree pipeFromOutput dependents size = 1.
	self assert: proxyThree pipeFromOutput dependents first == proxyThree.
	self assert: proxyThree pipeFromOutput actionMap isEmpty.

]

{ #category : #'private - pipeline creation' }
PipelineEventsTestCase >> threeExternalProxies [

	^ ProxyPipeline fromString: 'ps | cat | cat' shell: CommandShell new

]

{ #category : #'private - pipeline creation' }
PipelineEventsTestCase >> threeInternalProxies [

	^ ProxyPipeline fromString: 'help | copyToOutput | copyToOutput' shell: CommandShell new
]
