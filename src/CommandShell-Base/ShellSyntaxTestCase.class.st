"
Unit tests for ShellSyntax. Conditional tests are needed for Windows and other platforms, so not all tests are effective on all platforms. Unix is the development platform, and many of the tests are specific to a Unix file system environment.
"
Class {
	#name : #ShellSyntaxTestCase,
	#superclass : #TestCase,
	#instVars : [
		'shellSyntax'
	],
	#category : 'CommandShell-Tests'
}

{ #category : #running }
ShellSyntaxTestCase >> runAll [

	"ShellSyntaxTestCase new runAll"

	| result suite |
	suite := TestSuite new.

	suite addTest: (ShellSyntaxTestCase selector: #testUpOneDirectoryLevel01).
	suite addTest: (ShellSyntaxTestCase selector: #testUpOneDirectoryLevel02).
	suite addTest: (ShellSyntaxTestCase selector: #testUpOneDirectoryLevel03).
	suite addTest: (ShellSyntaxTestCase selector: #testUpOneDirectoryLevel01).
	suite addTest: (ShellSyntaxTestCase selector: #testUpOneDirectoryLevel10).
	suite addTest: (ShellSyntaxTestCase selector: #testUpOneDirectoryLevel11).
	suite addTest: (ShellSyntaxTestCase selector: #testUpOneDirectoryLevel12).
	suite addTest: (ShellSyntaxTestCase selector: #testUpOneDirectoryLevel13).

	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom01).
	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom02).
	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom03).
	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom04).
	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom05).
	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom06).
	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom07).
	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom08).
	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom09).
	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom10).
	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom11).
	suite addTest: (ShellSyntaxTestCase selector: #testStringTokensFrom12).

	suite addTest: (ShellSyntaxTestCase selector: #testArgsFromCommand01).
	suite addTest: (ShellSyntaxTestCase selector: #testArgsFromCommand02).
	suite addTest: (ShellSyntaxTestCase selector: #testArgsFromCommand03).
	suite addTest: (ShellSyntaxTestCase selector: #testArgsFromCommand04).
	suite addTest: (ShellSyntaxTestCase selector: #testArgsFromCommand05).

	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument01).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument02).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument03).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument04).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument05).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument06).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument07).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument08).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument09).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument10).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument11).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument12).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument13).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgument14).

	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgumentFrom01).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgumentFrom02).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandArgumentFrom03).

	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths01).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths02).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths03).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths04).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths05).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths06).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths07).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths08).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths09).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths10).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths11).

	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths20).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths21).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths22).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths23).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths24).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths25).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths26).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths27).
	suite addTest: (ShellSyntaxTestCase selector: #testExpandedPaths28).

	suite addTest: (ShellSyntaxTestCase selector: #testNewDirPathFrom01).
	suite addTest: (ShellSyntaxTestCase selector: #testNewDirPathFrom02).
	suite addTest: (ShellSyntaxTestCase selector: #testNewDirPathFrom03).
	suite addTest: (ShellSyntaxTestCase selector: #testNewDirPathFrom04).
	suite addTest: (ShellSyntaxTestCase selector: #testNewDirPathFrom05).

	suite addTest: (ShellSyntaxTestCase selector: #testFirstExpandedArgument01).
	suite addTest: (ShellSyntaxTestCase selector: #testFirstExpandedArgument02).
	suite addTest: (ShellSyntaxTestCase selector: #testFirstExpandedArgument04).
	suite addTest: (ShellSyntaxTestCase selector: #testFirstExpandedArgument05).
	suite addTest: (ShellSyntaxTestCase selector: #testFirstExpandedArgument06).
	suite addTest: (ShellSyntaxTestCase selector: #testFirstExpandedArgument07).
	suite addTest: (ShellSyntaxTestCase selector: #testFirstExpandedArgument08).
	suite addTest: (ShellSyntaxTestCase selector: #testFirstExpandedArgument09).
	suite addTest: (ShellSyntaxTestCase selector: #testFirstExpandedArgument10).
	suite addTest: (ShellSyntaxTestCase selector: #testFirstExpandedArgument11).
	suite addTest: (ShellSyntaxTestCase selector: #testFirstExpandedArgument12).

	suite addTest: (ShellSyntaxTestCase selector: #testAppendPathToPath01).
	suite addTest: (ShellSyntaxTestCase selector: #testAppendPathToPath02).
	suite addTest: (ShellSyntaxTestCase selector: #testAppendPathToPath03).
	suite addTest: (ShellSyntaxTestCase selector: #testAppendPathToPath04).
	suite addTest: (ShellSyntaxTestCase selector: #testAppendPathToPath05).
	suite addTest: (ShellSyntaxTestCase selector: #testAppendPathToPath06).
	suite addTest: (ShellSyntaxTestCase selector: #testAppendPathToPath10).
	suite addTest: (ShellSyntaxTestCase selector: #testAppendPathToPath11).
	suite addTest: (ShellSyntaxTestCase selector: #testAppendPathToPath12).
	suite addTest: (ShellSyntaxTestCase selector: #testAppendPathToPath13).
	suite addTest: (ShellSyntaxTestCase selector: #testAppendPathToPath14).

	result := suite run.
	self should: [result defects size == 0].
	^ result

]

{ #category : #running }
ShellSyntaxTestCase >> setUp [

	shellSyntax := ShellSyntax new

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testAppendPathToPath01 [

	"(ShellSyntaxTestCase selector: #testAppendPathToPath01) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax appendPath: 'hosts' toPath: '/etc'.
		self should: [path = '/etc/hosts']]

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testAppendPathToPath02 [

	"(ShellSyntaxTestCase selector: #testAppendPathToPath02) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax appendPath: 'etc' toPath: '/'.
		self should: [path = '/etc']]

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testAppendPathToPath03 [

	"(ShellSyntaxTestCase selector: #testAppendPathToPath03) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax appendPath: 'vi' toPath: '/usr/bin'.
		self should: [path = '/usr/bin/vi']]

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testAppendPathToPath04 [

	"(ShellSyntaxTestCase selector: #testAppendPathToPath04) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax appendPath: '../bin/vi' toPath: '/usr/bin'.
		self should: [path = '/usr/bin/vi']]

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testAppendPathToPath05 [

	"(ShellSyntaxTestCase selector: #testAppendPathToPath05) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax appendPath: './vi' toPath: '/usr/bin'.
		self should: [path = '/usr/bin/vi']]

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testAppendPathToPath06 [

	"(ShellSyntaxTestCase selector: #testAppendPathToPath06) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax appendPath: '../bin/./../bin/vi' toPath: '/usr/bin'.
		self should: [path = '/usr/bin/vi']]

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testAppendPathToPath10 [

	"(ShellSyntaxTestCase selector: #testAppendPathToPath10) run"

	| path |
	self win32 ifTrue:
		[path := shellSyntax appendPath: 'WINDOWS' toPath: 'C:\'.
		self should: [path = 'C:\WINDOWS']]

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testAppendPathToPath11 [

	"(ShellSyntaxTestCase selector: #testAppendPathToPath11) run"

	| path |
	self win32 ifTrue:
		[path := shellSyntax appendPath: 'someFileName' toPath: 'C:\WINDOWS'.
		self should: [path = 'C:\WINDOWS\someFileName']]

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testAppendPathToPath12 [

	"(ShellSyntaxTestCase selector: #testAppendPathToPath12) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax appendPath: '..' toPath: '/usr'.
		self should: [path = '/']]

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testAppendPathToPath13 [

	"(ShellSyntaxTestCase selector: #testAppendPathToPath13) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax appendPath: '..' toPath: 'usr/bin'.
		self should: [path = 'usr']]

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testAppendPathToPath14 [

	"(ShellSyntaxTestCase selector: #testAppendPathToPath14) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax appendPath: '..' toPath: 'usr'.
		self should: [path = '']]

]

{ #category : #'testing - argument tokens' }
ShellSyntaxTestCase >> testArgsFromCommand01 [

	"(ShellSyntaxTestCase selector: #testArgsFromCommand01) run"

	| args |
	args := shellSyntax argsFromCommand: 'sleep 6'.
	self should: [args size == 2].
	self should: [args first = 'sleep'].
	self should: [args last = '6']

]

{ #category : #'testing - argument tokens' }
ShellSyntaxTestCase >> testArgsFromCommand02 [

	"(ShellSyntaxTestCase selector: #testArgsFromCommand02) run"

	| args |
	args := shellSyntax argsFromCommand: 'ls -l h?s*'.
	self should: [args size == 3].
	self should: [args last = 'h?s*']

]

{ #category : #'testing - argument tokens' }
ShellSyntaxTestCase >> testArgsFromCommand03 [

	"(ShellSyntaxTestCase selector: #testArgsFromCommand03) run"

	| args |
	args := shellSyntax argsFromCommand: 'This string contains a ''quoted token'' in the middle'.
	self should: [args size == 8].
	self should: [(args at: 5) = 'quoted token']

]

{ #category : #'testing - argument tokens' }
ShellSyntaxTestCase >> testArgsFromCommand04 [

	"(ShellSyntaxTestCase selector: #testArgsFromCommand04) run"

	| args |
	args := shellSyntax argsFromCommand: '''quoted token'' is first'.
	self should: [args size == 3].
	self should: [args first = 'quoted token']

]

{ #category : #'testing - argument tokens' }
ShellSyntaxTestCase >> testArgsFromCommand05 [

	"(ShellSyntaxTestCase selector: #testArgsFromCommand05) run"

	| args |
	args := shellSyntax argsFromCommand: 'the last token is ''a quoted token'''.
	self should: [args size == 5].
	self should: [args last = 'a quoted token']

]

{ #category : #'testing - command parsing' }
ShellSyntaxTestCase >> testDoItStringFrom [

	"(ShellSyntaxTestCase selector: #testDoItStringFrom) run"

	self should:
		(shellSyntax doItStringFrom: 'this should answer a string!')
			= 'this should answer a string'.
	self should:
		(shellSyntax doItStringFrom: 'this should answer a string!   ')
			= 'this should answer a string'.
	self should:
		(shellSyntax doItStringFrom: 'this should answer nil') isNil

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument01 [
	"This will not work on a non-unix system, as it assumes existence of '/etc/hosts'"

	"(ShellSyntaxTestCase selector: #testExpandArgument01) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandArgument: 'ho?ts' inDirectoryPath: '/etc'.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'hosts']]

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument02 [

	"(ShellSyntaxTestCase selector: #testExpandArgument02) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandArgument: '/b?n/s?' inDirectoryPath: '/etc'.
		self shouldnt: [args isEmpty].
		self should: [args includes: '/bin/sh']]

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument03 [

	"(ShellSyntaxTestCase selector: #testExpandArgument03) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandArgument: 'fs*' inDirectoryPath: '/etc'.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'fstab']]

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument04 [
	"This should work on any system. If no file exists by the given name, then leave
	the name token unmodified."

	"(ShellSyntaxTestCase selector: #testExpandArgument04) run"

	| args |
	args := shellSyntax expandArgument: 'NOSUCHFILE' inDirectoryPath: '/etc'.
	self shouldnt: [args isEmpty].
	self should: [args includes: 'NOSUCHFILE'].

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument05 [
	"This should work on any system. If no file exists by the given name, then leave
	the name token unmodified. Even the wild card characters should remain as part
	of the literal text."

	"(ShellSyntaxTestCase selector: #testExpandArgument05) run"

	| args |
	args := shellSyntax expandArgument: 'NO?SUCH*FILE' inDirectoryPath: '/etc'.
	self shouldnt: [args isEmpty].
	self should: [args includes: 'NO?SUCH*FILE'].

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument06 [
	"A fully specified path overrides the default directory path."

	"(ShellSyntaxTestCase selector: #testExpandArgument06) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandArgument: '/us*/b?n/v?' inDirectoryPath: '/NO/SUCH/PATH'.
		self shouldnt: [args isEmpty].
		self should: [args includes: '/usr/bin/vi']]

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument07 [
	"File not found, keep the literal token"

	"(ShellSyntaxTestCase selector: #testExpandArgument07) run"

	| args |
	args := shellSyntax expandArgument: 'ho?ts' inDirectoryPath: '/NO/SUCH/DIRECTORY'.
	self shouldnt: [args isEmpty].
	self should: [args includes: 'ho?ts'].

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument08 [
	"File not found, keep the literal token"

	"(ShellSyntaxTestCase selector: #testExpandArgument08) run"

	| args |
	args := shellSyntax expandArgument: 'ho?ts' inDirectoryPath: nil.
	self shouldnt: [args isEmpty].
	self should: [args includes: 'ho?ts'].

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument09 [
	"File not found, keep the literal token. Implementation may optimize to check
	explicitly for a flag string, but the result should be the same."

	"(ShellSyntaxTestCase selector: #testExpandArgument09) run"

	| args |
	args := shellSyntax expandArgument: '-flag' inDirectoryPath: '/etc'.
	self should: [args size == 1].
	self should: [args includes: '-flag'].

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument10 [
	"This should work on any system. If no file exists by the given name, then leave
	the name token unmodified."

	"(ShellSyntaxTestCase selector: #testExpandArgument10) run"

	| args |
	args := shellSyntax expandArgument: 'no*such*file???' inDirectoryPath: '/etc'.
	self shouldnt: [args isEmpty].
	self should: [args includes: 'no*such*file???'].

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument11 [
	"This should work on any system. If no file exists by the given name, then leave
	the name token unmodified."

	"(ShellSyntaxTestCase selector: #testExpandArgument11) run"

	| args |
	args := shellSyntax expandArgument: nil inDirectoryPath: '/etc'.
	self should: [args isEmpty].

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument12 [
	"Character ranges. Look for /etc/horts or /etc/hosts or /etc/hotts, and answer /etc/hosts."

	"(ShellSyntaxTestCase selector: #testExpandArgument12) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandArgument: 'ho[r-t]ts' inDirectoryPath: '/etc'.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'hosts']]

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument13 [
	"Character ranges. Answer /etc/hosts."

	"(ShellSyntaxTestCase selector: #testExpandArgument13) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandArgument: 'ho[tsr]ts' inDirectoryPath: '/etc'.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'hosts']]

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgument14 [
	"Character ranges. Answer /etc/hosts."

	"(ShellSyntaxTestCase selector: #testExpandArgument14) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandArgument: 'ho[s]ts' inDirectoryPath: '/etc'.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'hosts']]

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgumentFrom01 [

	"(ShellSyntaxTestCase selector: #testExpandArgumentFrom01) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax
			expandArgumentsFrom: #('-help' '/b?n/s?' 'ho?ts' 'fs*' 'NOSUCHFILE')
			inDirectoryPath: '/etc'.
		self shouldnt: [args isEmpty].
		self should: [args includes: '-help'].
		self should: [args includes: '/bin/sh'].
		self should: [args includes: '/bin/su'].
		self should: [args includes: 'hosts'].
		self should: [args includes: 'NOSUCHFILE'].
		self shouldnt: [args includes: nil].
		self shouldnt: [args includes: '']]

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgumentFrom02 [

	"(ShellSyntaxTestCase selector: #testExpandArgumentFrom02) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax
			expandArgumentsFrom: #('this' 'is' 'a' 'test' '*.image' '/us*/b?n/v?')
			inDirectoryPath: CommandShell defaultPathString.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'this'].
		self should: [args includes: 'is'].
		self should: [args includes: 'a'].
		self should: [args includes: 'test'].
		self should: [args includes: '/usr/bin/vi'].
		self shouldnt: [args includes: nil].
		self shouldnt: [args includes: ''].
		self should: [(args detect: [:e | '*.image' match: e] ifNone: []) notNil]]

]

{ #category : #'testing - token expansion' }
ShellSyntaxTestCase >> testExpandArgumentFrom03 [

	"(ShellSyntaxTestCase selector: #testExpandArgumentFrom03) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax
			expandArgumentsFrom: #('this' 'is' 'a' 'test' '*.image' '/us*/b?n/v?')
			inDirectoryPath: nil.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'this'].
		self should: [args includes: 'is'].
		self should: [args includes: 'a'].
		self should: [args includes: 'test'].
		self should: [args includes: '/usr/bin/vi'].
		self shouldnt: [args includes: nil].
		self shouldnt: [args includes: ''].
		self should: [(args detect: [:e | '*.image' match: e] ifNone: []) notNil]]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths01 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths01) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandedPathsFrom: '/e*c/h*s' beginningAt: nil.
		self shouldnt: [args isEmpty].
		self should: [args includes: '/etc/hosts']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths02 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths02) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandedPathsFrom: 'e*c/h*s' beginningAt: '/'.
		self shouldnt: [args isEmpty].
		self should: [args includes: '/etc/hosts']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths03 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths03) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandedPathsFrom: '/usr/bin/vi' beginningAt: nil.
		self should: [args size == 1].
		self should: [args includes: '/usr/bin/vi']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths04 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths04) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandedPathsFrom: 'bin/vi' beginningAt: '/usr'.
		self should: [args size == 1].
		self should: [args includes: '/usr/bin/vi']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths05 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths05) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandedPathsFrom: '/usr/*/vi' beginningAt: nil.
		self should: [args size == 1].
		self should: [args includes: '/usr/bin/vi']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths06 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths06) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandedPathsFrom: '/usr/bin/../bin/./../bin/../../usr/bin/vi' beginningAt: nil.
		self should: [args size == 1].
		self should: [args includes: '/usr/bin/vi']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths07 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths07) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandedPathsFrom: '/bin/../bin/./../bin/../../usr/bin/vi' beginningAt: '/usr'.
		self should: [args size == 1].
		self should: [args includes: '/usr/bin/vi']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths08 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths08) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax
			expandedPathsFrom: '/usr/bin/../bin/./../bin/../../../../../usr/bin/vi'
			beginningAt: nil.
		self should: [args size == 1].
		self should: [args includes: '/usr/bin/vi']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths09 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths09) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandedPathsFrom: '../../../../../../../../../../usr/bin/vi' beginningAt: nil.
		self should: [args size == 1].
		self should: [args includes: '/usr/bin/vi']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths10 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths10) run"

	| args |
	self unix ifTrue:
		[args := shellSyntax expandedPathsFrom: '/' beginningAt: '/'.
		self should: [args size == 1].
		self should: [args includes: '/']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths11 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths11) run"

	| args |
	args := shellSyntax expandedPathsFrom: '*.image' beginningAt: nil.
	self shouldnt: [args isEmpty].
	self should: ['*.image' match: args first].

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths20 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths20) run"

	| args |
	self win32 ifTrue:
		[args := shellSyntax expandedPathsFrom: 'C:\WINDOWS\*.*' beginningAt: nil.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'C:\WINDOWS\WRITE.EXE']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths21 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths21) run"

	| args |
	self win32 ifTrue:
		[args := shellSyntax expandedPathsFrom: '*.*' beginningAt: 'C:\WINDOWS'.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'C:\WINDOWS\WRITE.EXE']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths22 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths22) run"

	| args |
	self win32 ifTrue:
		[args := shellSyntax expandedPathsFrom: 'C:\*.*' beginningAt: nil.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'C:\AUTOEXEC.BAT']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths23 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths23) run"

	| args |
	self win32 ifTrue:
		[args := shellSyntax expandedPathsFrom: 'C:\CONFIG.*' beginningAt: nil.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'C:\CONFIG.SYS']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths24 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths24) run"

	| args |
	self win32 ifTrue:
		[args := shellSyntax expandedPathsFrom: 'C:\CONFIG.*' beginningAt: '\'.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'C:\CONFIG.SYS']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths25 [
	"If no expanded path is found, answer an empty collection"

	"(ShellSyntaxTestCase selector: #testExpandedPaths25) run"

	| args |
	args := shellSyntax expandedPathsFrom: 'CONFIG.*' beginningAt: nil.
	self should: [args isEmpty].

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths26 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths26) run"

	| args |
	self win32 ifTrue:
		[args := shellSyntax expandedPathsFrom: '..\..\..\..\..\..\..\..\..\WINDOWS\*.*' beginningAt: nil.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'C:\WINDOWS\WRITE.EXE']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths27 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths27) run"

	| args |
	self win32 ifTrue:
		[args := shellSyntax
			expandedPathsFrom: '..\..\..\..\..\..\..\..\..\WINDOWS\*.*'
			beginningAt: 'C:\WINDOWS'.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'C:\WINDOWS\WRITE.EXE']]

]

{ #category : #'testing - path expansion' }
ShellSyntaxTestCase >> testExpandedPaths28 [

	"(ShellSyntaxTestCase selector: #testExpandedPaths28) run"

	| args |
	self win32 ifTrue:
		[args := shellSyntax
			expandedPathsFrom: '..\..\..\..\..\..\..\..\..\WINDOWS\.\*.*'
			beginningAt: 'C:\WINDOWS'.
		self shouldnt: [args isEmpty].
		self should: [args includes: 'C:\WINDOWS\WRITE.EXE']]

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument01 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument01) run"

	|  arg |
	self unix ifTrue:
		[arg := shellSyntax firstExpandedArgument: 'm?*l' inDirectoryPath: '/usr/bin'.
		self shouldnt: [arg isEmpty].
		self should: ['/usr/bin/m*l' match: arg].
		self shouldnt: [arg = '/usr/bin/m?*l']]

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument02 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument02) run"

	|  arg |
	arg := shellSyntax firstExpandedArgument: 'm?*l' inDirectoryPath: '/no/such/directory'.
	self shouldnt: [arg isEmpty].
	self should: [arg = '/no/such/directory/m?*l']

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument03 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument03) run"

	|  arg |
	arg := shellSyntax firstExpandedArgument: 'no*such*file???' inDirectoryPath: '/usr/bin'.
	self shouldnt: [arg isEmpty].
	self should: [arg = '/usr/bin/no*such*file???']

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument04 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument04) run"

	|  arg |
	self unix ifTrue:
		[arg := shellSyntax firstExpandedArgument: '/usr/bin/vi' inDirectoryPath: '/usr/bin'.
		self shouldnt: [arg isEmpty].
		self should: [arg = '/usr/bin/vi']]

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument05 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument05) run"

	|  arg |
	self unix ifTrue:
		[arg := shellSyntax firstExpandedArgument: '../bin/vi' inDirectoryPath: '/usr/bin'.
		self shouldnt: [arg isEmpty].
		self should: [arg = '/usr/bin/vi']]

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument06 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument06) run"

	|  arg |
	arg := shellSyntax firstExpandedArgument: nil inDirectoryPath: '/usr/bin'.
	self should: [arg = '']

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument07 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument07) run"

	|  arg |
	self unix ifTrue:
		[arg := shellSyntax firstExpandedArgument: '/usr/b[a-z]n/vi' inDirectoryPath: nil.
		self shouldnt: [arg isEmpty].
		self should: [arg = '/usr/bin/vi']]

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument08 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument08) run"

	|  arg |
	self unix ifTrue:
		[arg := shellSyntax firstExpandedArgument: '/us[r-r]/b[a-z]n/vi' inDirectoryPath: nil.
		self shouldnt: [arg isEmpty].
		self should: [arg = '/usr/bin/vi']]

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument09 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument09) run"

	|  arg |
	self unix ifTrue:
		[arg := shellSyntax firstExpandedArgument: '/us[z-a]/bin/vi' inDirectoryPath: nil.
		self shouldnt: [arg isEmpty].
		self should: [arg = '/us[z-a]/bin/vi']]

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument10 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument10) run"

	|  arg |
	self unix ifTrue:
		[arg := shellSyntax firstExpandedArgument: '/t[l-n]p' inDirectoryPath: nil.
		self should: [arg = '/tmp']]

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument11 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument11) run"

	|  arg |
	self unix ifTrue:
		[arg := shellSyntax firstExpandedArgument: '../bin/v?' inDirectoryPath: '/usr/bin'.
		self shouldnt: [arg isEmpty].
		self should: [arg = '/usr/bin/vi']]

]

{ #category : #'testing - first expanded path' }
ShellSyntaxTestCase >> testFirstExpandedArgument12 [

	"(ShellSyntaxTestCase selector: #testFirstExpandedArgument12) run"

	|  arg |
	self unix ifTrue:
		[arg := shellSyntax firstExpandedArgument: '../bin' inDirectoryPath: '/usr/bin'.
		self shouldnt: [arg isEmpty].
		self should: [arg = '/usr/bin']]

]

{ #category : #'testing - command parsing' }
ShellSyntaxTestCase >> testIsComment [

	"(ShellSyntaxTestCase selector: #testIsComment) run"

	self should: (shellSyntax isComment: '   #comment').
	self should: (shellSyntax isComment: '#comment').
	self shouldnt: (shellSyntax isComment: '   notComment').
	self shouldnt: (shellSyntax isComment: 'notComment').
	self should: (shellSyntax isComment: '')

]

{ #category : #'testing - path navigation' }
ShellSyntaxTestCase >> testIsDirectoryPath [

	"(ShellSyntaxTestCase selector: #testIsDirectoryPath) debug"

	self unix ifTrue: [
		self should: [ShellSyntax new isDirectoryPath: '/usr/bin'].
		self should: [ShellSyntax new isDirectoryPath: '/'].
		self shouldnt: [ShellSyntax new isDirectoryPath: '/bin/sh'].
		self shouldnt: [ShellSyntax new isDirectoryPath: '/foo'].
		self shouldnt: [ShellSyntax new isDirectoryPath: '/foo/bar'] ].
	self win32 ifTrue: [
		self should: [ShellSyntax new isDirectoryPath: 'C:' ] ]

		

]

{ #category : #'testing - command parsing' }
ShellSyntaxTestCase >> testIsDoItCommand [

	"(ShellSyntaxTestCase selector: #testIsDoItCommand) run"

	self should: (shellSyntax isDoItCommand: 'this should answer true!').
	self should: (shellSyntax isDoItCommand: 'this should answer true!   ').
	self shouldnt: (shellSyntax isDoItCommand: 'this should answer false')
]

{ #category : #'testing - command parsing' }
ShellSyntaxTestCase >> testIsFlagParameter [

	"(ShellSyntaxTestCase selector: #testIsFlagParameter) run"

	self should: (shellSyntax isFlagParameter: '-help').
	self shouldnt: (shellSyntax isFlagParameter: 'filename').
	self shouldnt: (shellSyntax isFlagParameter: '')

]

{ #category : #'testing - command parsing' }
ShellSyntaxTestCase >> testIsRedirectIOFor [

	"(ShellSyntaxTestCase selector: #testIsRedirectIOFor) run"

	| r1 r2 |
	r1 := shellSyntax
		redirectIOFor: 'ls /tmp /NOSUCHFILE > /tmp/sqTempOut.tmp 2> /tmp/sqTempErr.tmp'
		inDirectoryPath: nil.
	self should: r1 first = 'ls /tmp /NOSUCHFILE '.
	self should: r1 second isNil.
	self should: (r1 third isKindOf: FileStream).
	self should: r1 third name =  '/tmp/sqTempOut.tmp'.
	r1 third close.
	self should: (r1 fourth isKindOf: FileStream).
	self should: r1 fourth name =  '/tmp/sqTempErr.tmp'.
	r1 fourth close.
	r2 :=shellSyntax
		redirectIOFor: 'cat < /etc/hosts > /tmp/sqHosts.tmp'
		inDirectoryPath: nil.
	self should: r2 first = 'cat '.
	self should: (r2 second isKindOf: FileStream).
	self should: r2 second name = '/etc/hosts'.
	r2 second close.
	self should: (r2 third isKindOf: FileStream).
	self should: r2 third name = '/tmp/sqHosts.tmp'.
	r2 third close.
	self should: r2 fourth isNil

]

{ #category : #'testing - new dir path' }
ShellSyntaxTestCase >> testNewDirPathFrom01 [

	"(ShellSyntaxTestCase selector: #testNewDirPathFrom01) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax newDirPath: 'b?n' from: '/usr'.
		self should: [path = '/usr/bin']]


	

]

{ #category : #'testing - new dir path' }
ShellSyntaxTestCase >> testNewDirPathFrom02 [

	"(ShellSyntaxTestCase selector: #testNewDirPathFrom02) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax newDirPath: '..' from: '/usr/bin'.
		self should: [path = '/usr']]


	

]

{ #category : #'testing - new dir path' }
ShellSyntaxTestCase >> testNewDirPathFrom03 [

	"(ShellSyntaxTestCase selector: #testNewDirPathFrom03) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax newDirPath: '.././bin' from: '/usr/bin'.
		self should: [path = '/usr/bin']]


	

]

{ #category : #'testing - new dir path' }
ShellSyntaxTestCase >> testNewDirPathFrom04 [

	"(ShellSyntaxTestCase selector: #testNewDirPathFrom04) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax newDirPath: '../../../../..' from: '/usr/bin'.
		self should: [path = '/']]


	

]

{ #category : #'testing - new dir path' }
ShellSyntaxTestCase >> testNewDirPathFrom05 [

	"(ShellSyntaxTestCase selector: #testNewDirPathFrom05) run"

	| path |
	self unix ifTrue:
		[path := shellSyntax newDirPath: '../../../../../usr' from: '/usr/bin'.
		self should: [path = '/usr']]


	

]

{ #category : #'testing - command parsing' }
ShellSyntaxTestCase >> testStringTokensFrom [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom) debug"

	| r |
	r := shellSyntax stringTokensFrom: 'this is 	a	test of 	 the string tokenizer'.
	self should: r second isNil.
	self should: r first size = 8.
	self should: r first last = 'tokenizer'.

	r := shellSyntax stringTokensFrom: 'this is 	a	test of 	 ''the string'' tokenizer'"
	self should: r second isNil.
	self should: r first size = 7.
	self should: r first last = 'tokenizer'.
	self should: r first sixth = 'the tokenizer'.

	r := shellSyntax stringTokensFrom: 'this is 	a	test of'' the string'' tokenizer'".
	self should: r second isNil.
	self should: r first size = 7.
	self should: r first sixth = 'the string'.

	r := shellSyntax stringTokensFrom: 'this is 	a	test of ''the string ''tokenizer'.
	self should: r second isNil.
	self should: r first size = 6.
	self should: r first sixth = 'the string tokenizer'.

	r := shellSyntax stringTokensFrom: 'this is 	a	test of 	 \''the string\'' tokenizer'.
	self should: r second isNil.
	self should: r first size = 8.
	self should: r first sixth = '''the'.
	self should: r first seventh = 'string'''.
	self should: r first eighth = 'tokenizer'.

	r := shellSyntax stringTokensFrom: '''this is'' 	a	test'.
	self should: r second isNil.
	self should: r first size = 3.
	self should: r first first = 'this is'.
	self should: r first second = 'a'.
	self should: r first third = 'test'.

	r := shellSyntax stringTokensFrom: 'this is ''a	test'''.
	self should: r second isNil.
	self should: r first size = 3.
	self should: r first first = 'this'.
	self should: r first second = 'is'.
	self should: r first third = 'a	test'.
	self should: r first third second = Character tab.

	r := shellSyntax stringTokensFrom: '''this is'' 	a	test of 	 \''the string\'' tokenizer '.
	self should: r second isNil.
	self should: r first size = 7.
	self should: r first first = 'this is'.
	self should: r first second = 'a'.
	self should: r first third = 'test'.
	self should: r first fourth = 'of'.
	self should: r first fifth = '''the'.
	self should: r first sixth = 'string'''.
	self should: r first seventh = 'tokenizer'.


	r := shellSyntax stringTokensFrom: 'this is ''a	test'.
	self should: r second = 'unbalanced quotes'.
	self should: r first size = 3.
	self should: r first first = 'this'.
	self should: r first second = 'is'.
	self should: r first third = 'a	test'.
	self should: r first third second = Character tab

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom01 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom01) run"

	| t |
	t := shellSyntax stringTokensFrom: 'this is 	a	test'.
	self should: [t last isNil].
	self should: [t first size == 4].
	self should: [t first last = 'test'].
	self should: [t first first = 'this'].

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom02 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom02) run"

	| t |
	t := shellSyntax stringTokensFrom: 'this ''is 	a''	test'.
	self should: [t last isNil].
	self should: [t first size == 3].
	self should: [t first last = 'test'].
	self should: [t first first = 'this'].

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom03 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom03) run"

	| t |
	t := shellSyntax stringTokensFrom: '	this ''is 	a''	test	'.
	self should: [t last isNil].
	self should: [t first size == 3].
	self should: [t first last = 'test'].
	self should: [t first first = 'this'].

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom04 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom04) run"

	| t |
	t := shellSyntax stringTokensFrom: ' this ''is 	a''	test '.
	self should: [t last isNil].
	self should: [t first size == 3].
	self should: [t first last = 'test'].
	self should: [t first first = 'this'].

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom05 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom05) run"

	| t |
	t := shellSyntax stringTokensFrom: ' this \''is 	a\''	test '.
	self should: [t last isNil].
	self should: [t first size == 4].
	self should: [t first last = 'test'].
	self should: [t first second = '''is'].
	self should: [t first third = 'a'''].
	self should: [t first first = 'this'].

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom06 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom06) run"

	| t |
	t := shellSyntax stringTokensFrom: ' this ''is 	a	test '.
	self should: [t last = 'unbalanced quotes'].
	self should: [t first size == 2].
	self should: [t first last = 'is 	a	test '].
	self should: [t first first = 'this'].

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom07 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom07) run"

	| t |
	t := shellSyntax stringTokensFrom: 'this is 	a	te\st'.
	self should: [t last isNil].
	self should: [t first size == 4].
	self should: [t first last = 'test'].
	self should: [t first first = 'this'].

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom08 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom08) run"

	| t |
	t := shellSyntax stringTokensFrom: 'this ''is\ a'' test'.
	self should: [t last isNil].
	self should: [t first size == 3].
	self should: [t first last = 'test'].
	self should: [t first second = 'is\ a'].
	self should: [t first first = 'this'].

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom09 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom09) run"

	| t |
	t := shellSyntax stringTokensFrom: '''this is'' 	a	test'.
	self should: [t last isNil].
	self should: [t first size == 3].
	self should: [t first last = 'test'].
	self should: [t first first = 'this is'].

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom10 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom10) run"

	| t |
	t := shellSyntax stringTokensFrom: 'this is 	''a	test'''.
	self should: [t last isNil].
	self should: [t first size == 3].
	self should: [t first last = 'a	test'].
	self should: [t first first = 'this'].

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom11 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom11) run"

	| t |
	t := shellSyntax stringTokensFrom: 'this'' is ''	a	test'.
	self should: [t last isNil].
	self should: [t first size == 3].
	self should: [t first last = 'test'].
	self should: [t first first = 'this is '].

]

{ #category : #'testing - string tokenizer' }
ShellSyntaxTestCase >> testStringTokensFrom12 [

	"(ShellSyntaxTestCase selector: #testStringTokensFrom12) run"

	| t |
	t := shellSyntax stringTokensFrom: 'this ''is ''	a	test'.
	self should: [t last isNil].
	self should: [t first size == 4].
	self should: [t first last = 'test'].
	self should: [t first first = 'this'].

]

{ #category : #'testing - command parsing' }
ShellSyntaxTestCase >> testTokenizeForRedirect [

	"(ShellSyntaxTestCase selector: #testTokenizeForRedirect) debug"

	| r |
	r := shellSyntax tokenizeForRedirect: 'one > two < three 2> four five six 2>> seven eight > nine ten >> eleven twelve 2 > thirteen'.
	self should: r size = 15.
	self should: (r at: 1) = 'one '.
	self should: (r at: 2) = #outputRedirect.
	self should: (r at: 3) = ' two '.
	self should: (r at: 4) = #inputRedirect.
	self should: (r at: 5) = ' three '.
	self should: (r at: 6) = #errorRedirect.
	self should: (r at: 7) = ' four five six '.
	self should: (r at: 8) = #errorAppendRedirect.
	self should: (r at: 9) = ' seven eight '.
	self should: (r at: 10) = #outputRedirect.
	self should: (r at: 11) = ' nine ten '.
	self should: (r at: 12) = #outputAppendRedirect.
	self should: (r at: 13) = ' eleven twelve 2 '.
	self should: (r at: 14) = #outputRedirect.
	self should: (r at: 15) = ' thirteen'

]

{ #category : #'testing - up one directory level' }
ShellSyntaxTestCase >> testUpOneDirectoryLevel01 [

	"(ShellSyntaxTestCase selector: #testUpOneDirectoryLevel01) run"

	|  upOne |
	self unix ifTrue:
		[upOne := shellSyntax upOneDirectoryLevel: '/usr/bin'.
		self should: [upOne = '/usr']]

]

{ #category : #'testing - up one directory level' }
ShellSyntaxTestCase >> testUpOneDirectoryLevel02 [

	"(ShellSyntaxTestCase selector: #testUpOneDirectoryLevel02) run"

	|  upOne |
	self unix ifTrue:
		[upOne := shellSyntax upOneDirectoryLevel: '/usr'.
		self should: [upOne = '/']]

]

{ #category : #'testing - up one directory level' }
ShellSyntaxTestCase >> testUpOneDirectoryLevel03 [

	"(ShellSyntaxTestCase selector: #testUpOneDirectoryLevel03) run"

	|  upOne |
	self unix ifTrue:
		[upOne := shellSyntax upOneDirectoryLevel: '/'.
		self should: [upOne = '/']]

]

{ #category : #'testing - up one directory level' }
ShellSyntaxTestCase >> testUpOneDirectoryLevel04 [

	"(ShellSyntaxTestCase selector: #testUpOneDirectoryLevel04) run"

	|  upOne |
	upOne := shellSyntax upOneDirectoryLevel: ''.
	self should: [upOne = '..']

]

{ #category : #'testing - up one directory level' }
ShellSyntaxTestCase >> testUpOneDirectoryLevel10 [

	"(ShellSyntaxTestCase selector: #testUpOneDirectoryLevel10) run"

	|  upOne |
	self win32 ifTrue:
		[upOne := shellSyntax upOneDirectoryLevel: 'C:\Windows\temp'.
		self should: [upOne = 'C:\Windows']]

]

{ #category : #'testing - up one directory level' }
ShellSyntaxTestCase >> testUpOneDirectoryLevel11 [

	"(ShellSyntaxTestCase selector: #testUpOneDirectoryLevel11) run"

	|  upOne |
	self win32 ifTrue:
		[upOne := shellSyntax upOneDirectoryLevel: 'C:\Windows'.
		self should: [upOne = 'C:\']]

]

{ #category : #'testing - up one directory level' }
ShellSyntaxTestCase >> testUpOneDirectoryLevel12 [

	"(ShellSyntaxTestCase selector: #testUpOneDirectoryLevel12) run"

	|  upOne |
	self win32 ifTrue:
		[upOne := shellSyntax upOneDirectoryLevel: 'C:\'.
		self should: [upOne = 'C:\']]

]

{ #category : #'testing - up one directory level' }
ShellSyntaxTestCase >> testUpOneDirectoryLevel13 [

	"(ShellSyntaxTestCase selector: #testUpOneDirectoryLevel13) run"

	|  upOne |
	self win32 ifTrue:
		[upOne := shellSyntax upOneDirectoryLevel: 'D:\Windows\temp'.
		self should: [upOne = 'D:\Windows']]

]

{ #category : #'platform dependency' }
ShellSyntaxTestCase >> unix [

	^ ShellSyntax new platformName = 'unix'
]

{ #category : #'platform dependency' }
ShellSyntaxTestCase >> win32 [

	^ ShellSyntax new platformName = 'Win32'
]
