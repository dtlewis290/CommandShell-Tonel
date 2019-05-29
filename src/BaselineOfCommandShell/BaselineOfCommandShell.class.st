Class {
	#name : #BaselineOfCommandShell,
	#superclass : #BaselineOf,
	#category : #BaselineOfCommandShell
}

{ #category : #baselines }
BaselineOfCommandShell >> baseline: spec [
	<baseline>

	spec for: #common do: [ 
		spec 
			baseline: 'OSProcess' with: [ 
				spec repository: 'github://akgrant43/OSProcess/src' ].

		"There is a circular dependency between Base, Commands, Piping and UI.
		Just declare all packages and ensure that Core loads them all."
		spec
			package: 'CommandShell-Base';
			package: 'CommandShell-Commands';
			package: 'CommandShell-Morphic';
			package: 'CommandShell-Piping' with: [ spec requires: 'OSProcess' ];
			package: 'CommandShell-UI';
			package: 'CommandShellPharo';
			package: 'CommandShell-Tests'.

		spec
			group: 'Core' with: #('CommandShell-Base' 'CommandShell-Commands' 'CommandShell-Morphic' 'CommandShell-Piping' 'CommandShell-UI' 'CommandShellPharo');
			group: 'Tests' with: #('Core' 'CommandShell-Tests');
			group: 'Piping' with: #('CommandShell-Piping');
			group: 'default' with: #('Tests').
			 ]
]
