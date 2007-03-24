Extension { #name : #WeakArray }

{ #category : #'*CommandShell' }
WeakArray class >> removeFromFinalizationRegistry: anObject [
	"Synchronize removal such that the finalization process does not
	access the registry while the removal is taking place."

	FinalizationLock critical:
		[self finalizationRegistry remove: anObject]
]
