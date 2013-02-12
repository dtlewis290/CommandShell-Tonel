"
ConfigurationOfCommandShell project stableVersion load
"
Class {
	#name : #ConfigurationOfCommandShell,
	#superclass : #Object,
	#instVars : [
		'project'
	],
	#classVars : [
		'LastVersionLoad'
	],
	#category : #ConfigurationOfCommandShell
}

{ #category : #'development support' }
ConfigurationOfCommandShell class >> DevelopmentSupport [

"See the methods in the 'development support' category on the class-side of MetacelloBaseConfiguration. Decide what development support methods you would like to use and copy them the the class-side of your configuration."
	<apiDocumentation>

]

{ #category : #private }
ConfigurationOfCommandShell class >> baseConfigurationClassIfAbsent: aBlock [

	^Smalltalk
		at: #MetacelloBaseConfiguration
		ifAbsent: [ 
			self ensureMetacelloBaseConfiguration.
			Smalltalk at: #MetacelloBaseConfiguration ifAbsent: aBlock ].

]

{ #category : #private }
ConfigurationOfCommandShell class >> ensureMetacello [

	(self baseConfigurationClassIfAbsent: []) ensureMetacello
]

{ #category : #private }
ConfigurationOfCommandShell class >> ensureMetacelloBaseConfiguration [

	Smalltalk
		at: #MetacelloBaseConfiguration
		ifAbsent: [ 
			| repository version |
			repository := MCHttpRepository location: 'http://seaside.gemstone.com/ss/metacello' user: '' password: ''.
			repository
				versionReaderForFileNamed: 'Metacello-Base-DaleHenrichs.2.mcz'
				do: [ :reader | 
					version := reader version.
					version load.
					version workingCopy repositoryGroup addRepository: repository ] ]
]

{ #category : #'metacello tool support' }
ConfigurationOfCommandShell class >> isMetacelloConfig [
	"Answer true and the Metacello tools will operate on you"
	
	^true
]

{ #category : #loading }
ConfigurationOfCommandShell class >> load [
	"Load the #stable version defined for this platform. The #stable version is the version that is recommended to be used on this platform."

	"self load"

	<apiDocumentation>
	^(self project version: #stable) load
]

{ #category : #loading }
ConfigurationOfCommandShell class >> loadBleedingEdge [
	"Load the latest versions of the mcz files defined for this project. It is not likely that the #bleedingEdge has been tested."

	"self loadBleedingEdge"

	<apiDocumentation>
	^(self project version: #bleedingEdge) load
]

{ #category : #loading }
ConfigurationOfCommandShell class >> loadDevelopment [
	"Load the #development version defined for this platform. The #development version will change over time and is not expected to be stable."

	"self loadDevelopment"

	<apiDocumentation>
	^(self project version: #development) load
]

{ #category : #accessing }
ConfigurationOfCommandShell class >> project [

	^self new project
]

{ #category : #'development support' }
ConfigurationOfCommandShell class >> validate [
	"Check the configuration for Errors, Critical Warnings, and Warnings (see class comment for MetacelloMCVersionValidator for more information). 
	Errors identify specification issues that will result in unexpected behaviour when you load the configuration. 
	Critical Warnings identify specification issues that may result in unexpected behavior when you load the configuration.
	Warnings identify specification issues that are technically correct, but are worth take a look at."

	"self validate"

	<apiDocumentation>
	self ensureMetacello.
	^ ((Smalltalk at: #MetacelloToolBox) validateConfiguration: self debug: #() recurse: false) explore
]

{ #category : #baselines }
ConfigurationOfCommandShell >> baseline10: spec [
	<version: '1.0-baseline'>

	spec for: #'common' do: [
		spec blessing: #'baseline'.
		spec repository: 'http://www.squeaksource.com/CommandShell'.
		spec project: 'OSProcess' with: [
			spec
				className: 'ConfigurationOfOSProcess';
				loads: #('Core');
				repository: 'http://www.squeaksource.com/MetacelloRepository' ].
		spec
			package: 'CommandShell-Base' with: [ 
				"Base actually requires the following packages, but the dependency is circular, so we'll include until it''s fixed"
				spec includes: #('CommandShell-Commands' 'CommandShell-Piping' 'CommandShell-UI') ];
			package: 'CommandShell-Commands' with: [ spec requires: #('CommandShell-Base') ];
			package: 'CommandShell-Morphic' with: [ spec requires: #('CommandShell-Base') ];
			package: 'CommandShell-Piping' with: [ spec requires: #('CommandShell-Base' 'OSProcess') ];
			package: 'CommandShell-UI' with: [ spec requires: #('CommandShell-Base' 'CommandShell-Morphic') ];
			package: 'CommandShellPharo' with: [ spec requires: #('CommandShell-Base') ];
			package: 'CommandShell-Tests' with: [ spec requires: #('CommandShell-Base' 'CommandShell-Piping' 'OSProcess') ].

		spec
			group: 'Core' with: #('CommandShell-Base' 'CommandShell-Commands' 'CommandShell-Morphic' 'CommandShell-Piping' 'CommandShell-UI' 'CommandShellPharo' );
			group: 'Piping' with: #('CommandShell-Piping');
			group: 'Tests' with: #('CommandShell-Tests'). ].
	
	spec for: #'squeak' do: [	
		spec package: 'CommandShell-MVC' with: [ "Unknown dependencies" ] ].
]

{ #category : #'symbolic versions' }
ConfigurationOfCommandShell >> development: spec [
	<symbolicVersion: #'development'>

	spec for: #'common' version: '1.1'.

]

{ #category : #accessing }
ConfigurationOfCommandShell >> project [

	^ project ifNil: [ | constructor |
		"Bootstrap Metacello if it is not already loaded"
		(self class baseConfigurationClassIfAbsent: []) ensureMetacello.
		"Construct Metacello project"
		constructor := (Smalltalk at: #MetacelloVersionConstructor) on: self.
		project := constructor project.
		project loadType: #linear. "change to #atomic if desired"
		project ]
]

{ #category : #'symbolic versions' }
ConfigurationOfCommandShell >> stable: spec [
	<symbolicVersion: #'stable'>

	spec for: #'common' version: '1.1'.
	spec for: #'pharo1.4.x' version: '1.0'.
]

{ #category : #versions }
ConfigurationOfCommandShell >> version10: spec [
	<version: '1.0' imports: #('1.0-baseline' )>

	spec for: #'common' do: [
		spec blessing: #'development'.
		spec description: ''.
		spec author: 'SeanDeNigris'.
		spec timestamp: '7/5/2012 15:51'.
		spec project: 'OSProcess' with: [ spec version: '4.4.6' ].
		spec 
			package: 'CommandShell-Base' with: 'CommandShell-Base-dtl.23';
			package: 'CommandShell-Commands' with: 'CommandShell-Commands-dtl.10';
			package: 'CommandShell-Morphic' with: 'CommandShell-Morphic-dtl.1';
			package: 'CommandShell-Piping' with: 'CommandShell-Piping-dtl.10';
			package: 'CommandShell-Tests' with: 'CommandShell-Tests-dtl.9';
			package: 'CommandShell-UI' with: 'CommandShell-UI-dtl.9' ].
		
	spec for: #'pharo' do: [
		spec package: 'CommandShellPharo' with: 'CommandShellPharo-dtl.2' ].
	
	spec for: #'squeak' do: [
		spec package: 'CommandShell-MVC' with: 'CommandShell-MVC-dtl.2' ].

]

{ #category : #versions }
ConfigurationOfCommandShell >> version11: spec [
	<version: '1.1' imports: #('1.0-baseline' )>

	spec for: #'common' do: [
		spec blessing: #'release'.
		spec description: ''.
		spec author: 'StephaneDucasse'.
		spec timestamp: '10/02/2013 12:57'.
		spec project: 'OSProcess' with: [ spec version: '4.5' ].
		spec 
			package: 'CommandShell-Base' with: 'CommandShell-Base-dtl.31';
			package: 'CommandShell-Commands' with: 'CommandShell-Commands-dtl.14';
			package: 'CommandShell-Morphic' with: 'CommandShell-Morphic-dtl.2';

			package: 'CommandShell-Piping' with: 'CommandShell-Piping-dtl.13';
			package: 'CommandShell-Tests' with: 'CommandShell-Tests-dtl.11';
			package: 'CommandShell-UI' with: 'CommandShell-UI-dtl.10' ].
		
	spec for: #'pharo' do: [
		spec package: 'CommandShellPharo' with: 'CommandShellPharo-dtl.2' ].

	spec for: #'squeak' do: [
		spec package: 'CommandShell-MVC' with: 'CommandShell-MVC-dtl.3' ].
]
