"
My instances implement parsing of strings in a manner similar to a simple Unix command shell. I provide path name expansion in the context of an external file system, and support the syntax required for IO redirection. All file name globbing and PATH searching are implemented in Smalltalk rather than in C library functions or an external command shell.

Most of my syntax is applicable for any operating system. Where needed, platform specific methods are in my ""platform dependent"" category. Currently, Unix and Windows are supported, and other platforms have not been testing. The primary difference between Unix and Windows support is that device names (such as 'C:') are used in Windows path strings. Separate current working directory strings are maintained for all Windows device names. For Unix, a single current working directory path is used. On Windows, this permits the CommandShell 'cd' command to support changing directories to another device without losing track of the current working directory for the previous device.

Command pipeline syntax is not supported here. See CommandShell for the implementation of command pipelines.

"
Class {
	#name : #ShellSyntax,
	#superclass : #Object,
	#instVars : [
		'cwdDictionary',
		'cwdIndex'
	],
	#category : #CommandShell
}

{ #category : #'path name expansion' }
ShellSyntax >> appendPath: aPathString toPath: startingPathString [

	"ShellSyntax new appendPath: 'hosts' toPath: '/etc'"
	"ShellSyntax new appendPath: 'etc' toPath: '/'"
	"ShellSyntax new appendPath: 'hosts' toPath: '/etc'"
	"ShellSyntax new appendPath: 'WINDOWS' toPath: 'C:\'"
	"ShellSyntax new appendPath: 'someFileName' toPath: 'C:\WINDOWS'"

	^ (self isAtFileSystemRoot: startingPathString)
		ifTrue: [startingPathString, aPathString]
		ifFalse: [startingPathString, FileDirectory slash, aPathString]
]

{ #category : #'command string parsing' }
ShellSyntax >> argsFromCommand: aString [

	^ aString findTokens: ' 	'

]

{ #category : #globbing }
ShellSyntax >> character: aCharacter matches: aToken [
	"Test if aCharacter is included in the characters of aToken, or if aToken is a #matchAny"

	(aToken == #matchAny) ifTrue: [^ true].
	^ aToken includes: aCharacter
]

{ #category : #defaults }
ShellSyntax >> commentChar [

	^ $#
]

{ #category : #accessing }
ShellSyntax >> cwdDictionary [
	"Current working directory paths indexed by device or file system name"

	^ cwdDictionary ifNil: [cwdDictionary _ Dictionary new]

]

{ #category : #accessing }
ShellSyntax >> cwdIndex [
	"Key to current cwd path name in cwdDictionary"

	^ cwdIndex ifNil: [cwdIndex _ self cwdIndexFor: FileDirectory default pathName]

]

{ #category : #'working directory' }
ShellSyntax >> cwdIndex: aSymbol [
	"Key to current cwd path name in cwdDictionary"

	cwdIndex _ aSymbol

]

{ #category : #'working directory' }
ShellSyntax >> cwdIndexFor: aPathStringWithPrefix [
	"Answer key to use for aPathStringWithPrefix"

	| prefix |
	prefix _ (self splitLocationPrefixFromPath: aPathStringWithPrefix) first.
	^ prefix isEmpty
		ifTrue: [#default]
		ifFalse: [prefix]
]

{ #category : #'working directory' }
ShellSyntax >> defaultPathFor: aPathStringWithPrefix [
	"Answer a reasonable path string to use as a default"

	^ self pathRoot: aPathStringWithPrefix

]

{ #category : #'path name expansion' }
ShellSyntax >> expandArgument: aString inDirectoryPath: aPath [
	"Expand a single argument and answer a fully qualified path to the first matching
	name. If no match, answer the literal path and file name (which does not exist).
	This method may be used to expand a single argument, such as the target for a
	command output redirection, where the target is expected to resolve to a single
	file name."

	"ShellSyntax new expandArgument: 'b?*h' inDirectoryPath: '/usr/bin'"
	"ShellSyntax new expandArgument: 'b?*h' inDirectoryPath: '/no/such/directory'"
	"ShellSyntax new expandArgument: 'no*such*file???' inDirectoryPath: '/usr/bin'"
	"ShellSyntax new expandArgument: '/usr/bin/vi' inDirectoryPath: '/usr/bin'"
	"ShellSyntax new expandArgument: '../bin/vi' inDirectoryPath: '/usr/bin'"
	"ShellSyntax new expandArgument: nil inDirectoryPath: '/usr/bin'"

	| expanded path trimmedString |
	aString ifNil: [^ ''].
	trimmedString _ aString withBlanksTrimmed.
	expanded _ self expandArgumentsFrom: (Array with: trimmedString) inDirectoryPath: aPath.
	path _ expanded isEmpty
			ifTrue: [trimmedString]
			ifFalse: [expanded first].
	^ self newPathFor: path fromDefault: aPath

]

{ #category : #'path name expansion' }
ShellSyntax >> expandArgumentsFrom: argArray [
	"Perform globbing expansion of command arguments."

	"ShellSyntax new expandArgumentsFrom: #('this' 'is' 'a' 'test' 'Sq*log')"

	^ self expandArgumentsFrom: argArray inDirectoryPath: FileDirectory default pathName

]

{ #category : #'path name expansion' }
ShellSyntax >> expandArgumentsFrom: argArray inDirectoryPath: aDefaultFileDirectoryPath [
	"Perform globbing expansion of command arguments. For each argument which is not a
	pathname, use aDefaultFileDirectory as the context for globbing."

	"ShellSyntax new
		expandArgumentsFrom: #('-help' '/b?n/s?' 'ho?ts' 'fs*' 'NOSUCHFILE')
		inDirectoryPath: '/etc'"
	"ShellSyntax new
		expandArgumentsFrom: #('this' 'is' 'a' 'test' 'Sq*log' '/us*/b?n/v?')
		inDirectoryPath: FileDirectory default pathName"
	"ShellSyntax new
		expandArgumentsFrom: #('this' 'is' 'a' 'test' 'Sq*log' '/us*/b?n/v?')
		inDirectoryPath: nil"

	| newArgs pathStrings dirPath |
	dirPath _ aDefaultFileDirectoryPath ifNil: [FileDirectory default pathName].
	newArgs _ OrderedCollection new.
	argArray do:
		[:arg |
		(self isFlagParameter: arg)
			ifTrue:
				[newArgs add: arg]
			ifFalse:
				[(pathStrings _ self glob: arg inDirectory: (FileDirectory on: dirPath))
					isEmpty ifTrue: [pathStrings _ self expandedPathsFrom: arg beginningAt: dirPath].
				pathStrings isEmpty
					ifTrue: [newArgs add: arg]
					ifFalse: [newArgs addAll: pathStrings]]].
	^ newArgs

]

{ #category : #'path name expansion' }
ShellSyntax >> expandPathParts: pathParts beginningAt: root [
	"Walk directory tree and answer a collection of matching path strings."

	| firstPart remainder dirPaths names dirNames basePath |
	(pathParts size == 0)
		ifTrue:
			["Should never get here, but just in case"
			^ Array with: root].
	firstPart _ pathParts first.
	remainder _ pathParts allButFirst.
	(firstPart = '.')
		ifTrue: "Stay at the current directory level"
			[dirPaths _ Array with: root]
		ifFalse:
			[(firstPart = '..') "Move up a directory level if possible"
				ifTrue:
					[dirPaths _ Array with: (self upOneDirectoryLevel: root)]
				ifFalse: "Normal case, a directory name"
					[remainder isEmpty
						ifTrue:
							["This condition terminates recursion"
							names _ self glob: firstPart inDirectory: (FileDirectory on: root).
							^ (root = FileDirectory slash)
								ifTrue: [^ names collect: [:n | root, n]]
								ifFalse: [^ names collect: [:n | root, FileDirectory slash, n]]]
						ifFalse:
							["Continue recursion until no more elements"
							dirNames _ self glob: firstPart
											names: (FileDirectory on: root) directoryNames.
							(('*', FileDirectory slash) match: root)
								ifTrue: [basePath _ root]
								ifFalse: [basePath _ root, FileDirectory slash].
							dirPaths _ dirNames collect: [:d | basePath, d]]]].
		^ dirPaths
			inject: OrderedCollection new
			into: [:result :dir |
				result addAll: (self expandPathParts: remainder beginningAt: dir).
				result]

]

{ #category : #'path name expansion' }
ShellSyntax >> expandedFileNames: argArray inDirectoryPath: dirPathString [
	"Expand argArray into a collection of file names"

	"ShellSyntax new
		expandedFileNames: (Array with: '/etc/h?st*' with: '/bin/*sh')
		inDirectoryPath: nil"

	| oc |
	argArray size == 0
		ifTrue:
			[^ argArray]
		ifFalse:
			[oc _ OrderedCollection new.
			argArray do:
				[:arg |
				oc addAll: (self expandArgumentsFrom: (Array with: arg)
								inDirectoryPath: dirPathString)]].
	^ oc collect: [:e | self newPathFor: e fromDefault: dirPathString]

]

{ #category : #'path name expansion' }
ShellSyntax >> expandedPathsFrom: aPathString beginningAt: firstPartOfPath [
	"Answer a collection of all paths which match aPathString. If aPathString is a relative path,
	expand the path relative to firstPartOfPath."

	 "ShellSyntax new expandedPathsFrom: '/e*c/h*s' beginningAt: nil"
	 "ShellSyntax new expandedPathsFrom: 'e*c/h*s' beginningAt: '/'"
	 "ShellSyntax new expandedPathsFrom: '/usr/bin/vi' beginningAt: nil"
	 "ShellSyntax new expandedPathsFrom: 'bin/vi' beginningAt: '/usr'"
	 "ShellSyntax new expandedPathsFrom: '/usr/*/vi' beginningAt: nil"
	 "ShellSyntax new expandedPathsFrom: '/usr/bin/../bin/./../bin/../../usr/bin/vi' beginningAt: nil"
	 "ShellSyntax new expandedPathsFrom: '/bin/../bin/./../bin/../../usr/bin/vi' beginningAt: '/usr'"
	 "ShellSyntax new expandedPathsFrom: '/usr/bin/../bin/./../bin/../../../../../usr/bin/vi' beginningAt: nil"
	 "ShellSyntax new expandedPathsFrom: '../../../../../../usr/bin/vi' beginningAt: nil"
	 "ShellSyntax new expandedPathsFrom: '/' beginningAt: '/'"
	 "ShellSyntax new expandedPathsFrom: '*.image' beginningAt: nil"
	 "ShellSyntax new expandedPathsFrom: 'C:\WINDOWS\*.*' beginningAt: nil"
	 "ShellSyntax new expandedPathsFrom: '*.*' beginningAt: 'C:\WINDOWS'"
	 "ShellSyntax new expandedPathsFrom: 'C:\*.*' beginningAt: nil"
	 "ShellSyntax new expandedPathsFrom: 'C:\CONFIG.*' beginningAt: nil"
	 "ShellSyntax new expandedPathsFrom: 'C:\CONFIG.*' beginningAt: '\'"

	| result oldPrefix a prefix dirPathString pathParts root |
	result _ OrderedCollection new.
	oldPrefix _ firstPartOfPath isNil
				ifTrue: ['']
				ifFalse: [(self splitLocationPrefixFromPath: firstPartOfPath) first].
	a _ self splitLocationPrefixFromPath: aPathString.
	prefix _ (a at: 1) isEmpty
				ifTrue: [oldPrefix]
				ifFalse: [a at: 1].
	dirPathString _ a at: 2.
	pathParts _ dirPathString findTokens: FileDirectory slash.
	root _ (self isAbsolutePath: dirPathString)
			ifTrue: "Fully qualified path name, ignore firstPartOfPathName"
				[prefix, FileDirectory slash]
			ifFalse: "Relative path name, need to use firstPartOfPathName"
				[firstPartOfPath isNil
					ifTrue: [FileDirectory default pathName]
					ifFalse: [firstPartOfPath]].
	result addAll: (self expandPathParts: pathParts beginningAt: root).
	^ result


]

{ #category : #'path name expansion' }
ShellSyntax >> findExecutablePathFor: aString inDirectoryPath: pathString [
	"Look for the executable, following Unix conventions for searching the PATH.
	If no likely candidate is found, answer nil."

	"ShellSyntax new findExecutablePathFor: 'bash' inDirectoryPath: nil"
	"ShellSyntax new findExecutablePathFor: 'ReadMe.txt' inDirectoryPath: nil"
	"ShellSyntax new findExecutablePathFor: 'SqueakDebug.log' inDirectoryPath: nil"
	"ShellSyntax new findExecutablePathFor: 'noSuchFileName' inDirectoryPath: nil"
	"ShellSyntax new findExecutablePathFor: 'a' inDirectoryPath: nil"
	"ShellSyntax new findExecutablePathFor: 'sqcat' inDirectoryPath: '/home/lewis/bin'"

	| delimiter path localNames fd fullName pathEntries dir |
	delimiter _ FileDirectory pathNameDelimiter.
	path _ pathString ifNil: [FileDirectory default pathName].
	"Unix compatibility note: If aString contains wildcard characters,
	it is expanded in the context of the current working directory. Expansion
	does not take place in the context of the PATH directories."
	localNames _ self glob: aString.
	fd _ FileDirectory default.

	(aString includes: delimiter)
		ifTrue:
			["A fully or partially qualified path, do not search PATH"
			(self isAbsolutePath: aString)
				ifTrue:
					["Fully qualified path from the file system root"
					^ localNames
						detect:
							[:fileName |
							((fd fileExists: fileName) and: [self isExecutable: fileName])
								ifTrue: [^ fileName]]
						ifNone: [nil]]
				ifFalse:
					["A path relative to the current directory, pathString"
					^ localNames
						detect:
							[:fileName |
							fullName _ path, FileDirectory slash, aString.
							((fd fileExists: fullName) and: [self isExecutable: fullName])
								ifTrue: [^ fullName]]
						ifNone: [nil]]]
		ifFalse:
			["Look for the file in the PATH locations"
			(localNames size == 0)
				ifTrue:
					["Name was not expanded, so use the unmodified value of aString"
					localNames _ Array with: aString].
		(Smalltalk hasClassNamed: #OSProcess)
			ifTrue:
				[pathEntries _ ((Smalltalk at: #OSProcess) thisOSProcess path findTokens: ':')
					collect:
						[:e | (e first == delimiter)
						ifTrue: [e]
						ifFalse: [path, delimiter asString, e]]]
			ifFalse:
				[pathEntries _ #()].
			dir _ pathEntries
				detect: [:pathName |
					(localNames
						detect: [:fileName |
							fullName _ pathName, FileDirectory slash, fileName.
							((fd fileExists: fullName) and: [self isExecutable: fullName])
								ifTrue: [^ fullName].
						false]
						ifNone: [nil]) notNil]
				ifNone: [nil].
			dir isNil
				ifTrue: [^ nil]
				ifFalse: [self error: 'should be nil']]

]

{ #category : #'path name expansion' }
ShellSyntax >> findPathTo: aString inDirectoryPath: pathString [
	"Look for a path to aString, following Unix conventions for searching the PATH.
	If no likely candidate is found, answer nil."

	"ShellSyntax new findPathTo: 'bash' inDirectoryPath: nil"
	"ShellSyntax new findPathTo: 'ReadMe.txt' inDirectoryPath: nil"
	"ShellSyntax new findPathTo: 'SqueakDebug.log' inDirectoryPath: nil"
	"ShellSyntax new findPathTo: 'noSuchFileName' inDirectoryPath: nil"
	"ShellSyntax new findPathTo: 'a' inDirectoryPath: nil"

	| delimiter localNames pathEntries dir fd exeName path relativePath |
	delimiter _ FileDirectory pathNameDelimiter.
	path _ pathString ifNil: [FileDirectory default pathName].
	(aString includes: delimiter)
		ifTrue:
			["A fully or partially qualified path, do not search PATH"
			(self isAbsolutePath: aString)
				ifTrue:
					["Fully qualified path from the file system root"
					(FileDirectory default fileExists: aString)
						ifTrue: [^ aString]
						ifFalse: [^ nil]]
				ifFalse:
					["A path relative to the current directory, pathString"
					relativePath _ path, FileDirectory slash, aString.
					(FileDirectory default fileExists: relativePath)
						ifTrue: [^ relativePath]
						ifFalse: [^ nil]]]
		ifFalse:
			["Look for the file in the PATH locations"
			localNames _ self glob: aString. "Unix shells do this for some reason"
			(localNames size == 0)
				ifTrue:
					["Name was not expanded, so use the unmodified value of aString"
					localNames _ Array with: aString].

			(Smalltalk hasClassNamed: #OSProcess)
				ifTrue:
					[pathEntries _ ((Smalltalk at: #OSProcess) thisOSProcess path findTokens: ':')
						collect:
							[:e | (e first == delimiter)
							ifTrue: [e]
							ifFalse: [path, FileDirectory slash, e]]]
				ifFalse:
					[pathEntries _ #()].
			dir _ pathEntries
				detect: [:pathName |
					fd _ FileDirectory on: pathName.
					(localNames
						detect: [:fileName |
							(fd fileExists: fileName)
								ifTrue: [exeName _ fileName. true]
								ifFalse: [false]]
						ifNone: [nil]) notNil]
				ifNone: [exeName].
			dir isNil
				ifTrue: [^ nil]
				ifFalse: [^ (self expandedPathsFrom: (dir, FileDirectory slash, exeName)
								beginningAt: FileDirectory slash) at: 1 ifAbsent: [nil]]]
]

{ #category : #'working directory' }
ShellSyntax >> getCwdForPath: aPathString [

	| prefix |
	prefix _ (self splitLocationPrefixFromPath: aPathString) first.
	^ prefix isEmpty
		ifTrue: [self workingDirectory]
		ifFalse: [self cwdDictionary at: prefix ifAbsentPut: [self defaultPathFor: aPathString]]

]

{ #category : #globbing }
ShellSyntax >> glob: aString [
	"Apply Unix shell globbing rules to aString, and answer an array of matching
	file names."

	"ShellSyntax new glob: 'ReadMe.txt'"
	"ShellSyntax new glob: 'rEADmE.TXT'"
	"ShellSyntax new glob: 'R*dM?.txt'"

	^ self glob: aString inDirectory: FileDirectory default

]

{ #category : #globbing }
ShellSyntax >> glob: aString inDirectory: aFileDirectory [
	"Apply Unix shell globbing rules to aString, and answer an array of matching
	file names."

	"ShellSyntax new glob: 'ReadMe.txt' inDirectory: FileDirectory default"
	"ShellSyntax new glob: 'SqueakDebug.log' inDirectory: FileDirectory default"
	"ShellSyntax new glob: '?queak*.[0-9].log' inDirectory: FileDirectory default"
	"ShellSyntax new glob: '*image*' inDirectory: FileDirectory default"
	"ShellSyntax new glob: 'noSuchFileName' inDirectory: FileDirectory default"
	"ShellSyntax new glob: 'b?n' inDirectory: (FileDirectory on: '/usr')"

	[^ self glob: aString names: aFileDirectory fileAndDirectoryNames]
		on: Error
		do: [^ #()]


]

{ #category : #globbing }
ShellSyntax >> glob: aString names: fileNameArray [
	"Apply Unix shell globbing rules to aString with respect to the elements of fileNameArray,
	and answer an array of matching file names. The fileNameArray is expected to have been
	provided by a FileDirectory query."

	| tokens |
	tokens _ self globTokensFrom: aString.
	^ fileNameArray
		select: [:n |
			self tokenStream: (ReadStream on: tokens)
				matches: (ReadStream on: n)]


]

{ #category : #globbing }
ShellSyntax >> globRangeFrom: aString tokenStream: aTokenStream [
	"Answer a string containing the characters specified by a range expression
	such as [a-z]. Sorry, this is just a simple implementation which assumes ASCII."

	| r w c t |
	(aString includes: $-) ifFalse: [^ aString]. "Simple case"
	r _ ReadStream on: aString.
	w _ WriteStream on: ''.
	(r peek == $!) ifTrue:
		[r next.
		aTokenStream nextPut: #not].
	[r atEnd] whileFalse: [
		c _ r next.
		(r peek == $-)
			ifTrue: [r next.
					t _ r next.
					(c asciiValue to: t asciiValue) do:
						[:e | w nextPut: (Character value: e)]]
			ifFalse: [w nextPut: c]].
	^ w contents
]

{ #category : #globbing }
ShellSyntax >> globTokensFrom: aString [
	"Answer a collection of tokens to be used for glob matching."

	"ShellSyntax new globTokensFrom: 'abc?def\ghi\?jkl*mno\*pqr[hello]there[Xa-eY]Z[!A-Z]end'"

	| lastToken r w t |
	lastToken _ nil.
	r _ ReadStream on: aString.
	w _ WriteStream on: #().
	[r atEnd] whileFalse:
		[t _ self nextGlobToken: r lastToken: lastToken tokenStream: w.
		(t ~~ #escape) ifTrue: [w nextPut: t].
		lastToken _ t].
	^ w contents

]

{ #category : #'platform dependent' }
ShellSyntax >> isAbsolutePath: aPathString [
	"Answer true if aPathString is specified relative to the root of the file system."

	"ShellSyntax new isAbsolutePath: 'not/absolute/path'"
	"ShellSyntax new isAbsolutePath: '/absolute/path'"
	"ShellSyntax new isAbsolutePath: '/'"
	"ShellSyntax new isAbsolutePath: 'C:\'"
	"ShellSyntax new isAbsolutePath: '\'"
	"ShellSyntax new isAbsolutePath: 'C:'"
	"ShellSyntax new isAbsolutePath: 'C:WINDOWS'"
	"ShellSyntax new isAbsolutePath: 'C:\WINDOWS'"

	| prefixAndPath path |
	^ ((((FileDirectory slash, '*') match: aPathString)
		or:	[prefixAndPath _ self splitLocationPrefixFromPath: aPathString.
			(FileDirectory slash, '*') match: (path _ prefixAndPath last)])
				or: [prefixAndPath first isEmpty not and: [path isEmpty]]) "One above the root of a Win32 file system tree"

]

{ #category : #'platform dependent' }
ShellSyntax >> isAtFileSystemRoot: aPathString [
	"Answer true if aPathString is not a subdirectory."

	"ShellSyntax new isAtFileSystemRoot: 'D:\'"
	"ShellSyntax new isAtFileSystemRoot: 'D:'"
	"ShellSyntax new isAtFileSystemRoot: 'D:\Windows'"
	"ShellSyntax new isAtFileSystemRoot: '\'"

	^ (FileDirectory slash = (self splitLocationPrefixFromPath: aPathString) last) or: [aPathString isEmpty]

]

{ #category : #'command string parsing' }
ShellSyntax >> isComment: aString [
	"Answer true if aString is empty or if its first non-space character is commentChar"

	"ShellSyntax new isComment: '   #comment'"
	"ShellSyntax new isComment: '#comment'"
	"ShellSyntax new isComment: '   notComment'"
	"ShellSyntax new isComment: 'notComment'"
	"ShellSyntax new isComment: ''"

	^ (aString size == 0)
		or:
			[aString do: [:e | (e isSeparator not)
							ifTrue: [^ e == self commentChar]].
			false]
]

{ #category : #'platform dependent' }
ShellSyntax >> isExecutable: aPath [
	"Answer true if aPath points to an executable file. This could be
	enhanced to support setting UID and GID for a CommandShell session.
	For now, just take the default for the current Squeak process."

	^ aPath notNil
		and: [(Smalltalk hasClassNamed: #OSProcess)
			and: [(Smalltalk at: #OSProcess) accessor isExecutable: aPath]]

]

{ #category : #'command string parsing' }
ShellSyntax >> isFlagParameter: aString [
	"Answer true if aString begins with $- (the convention for command flags for Unix)"

	"ShellSyntax new isFlagParameter: '-help'"
	"ShellSyntax new isFlagParameter: 'filename'"
	"ShellSyntax new isFlagParameter: ''"

	^ (aString size > 0) and: [(aString at: 1) == $-]
]

{ #category : #'path name expansion' }
ShellSyntax >> newPathFor: aPathString fromDefault: startingPathString [
	"Answer a new path starting from startingPathString if aPathString is a,
	relative path, otherwise just answer aPathString unmodified."

	"ShellSyntax new newPathFor: 'hosts' fromDefault: '/etc'"
	"ShellSyntax new newPathFor: 'three' fromDefault: 'one/two'"
	"ShellSyntax new newPathFor: 'one/two/three' fromDefault: ''"
	"ShellSyntax new newPathFor: '/hosts' fromDefault: '/etc'"
	"ShellSyntax new newPathFor: 'WINDOWS' fromDefault: 'C:\'"
	"ShellSyntax new newPathFor: 'D:\WINDOWS' fromDefault: 'C:\'"
	"ShellSyntax new newPathFor: 'D:WINDOWS' fromDefault: 'C:\'"

	^ (self isAbsolutePath: aPathString)
		ifTrue:
			[aPathString]
		ifFalse:
			[self appendPath: (self splitLocationPrefixFromPath: aPathString) last
					toPath: startingPathString]

]

{ #category : #globbing }
ShellSyntax >> nextGlobToken: aStream lastToken: aToken tokenStream: aTokenStream [
	"Escape character processing probably belongs elsewhere. Since it can conflict
	with Win32 file name conventions, I have commented it out here. The code
	is otherwise left alone here in case I change my mind later. -dtl"

	| c |
	(aToken == #escape)
		ifTrue:
			[^ aStream next]
		ifFalse:
			[c _ aStream next.
			(c == $[)
				ifTrue:
					["character range"
					^ self globRangeFrom: (aStream upTo: $]) tokenStream: aTokenStream]
				ifFalse:
					[(c == $*) ifTrue: [^ #matchRun].
					(c == $?) ifTrue: [^ #matchAny].
					"(c == $\) ifTrue: [^ #escape].	Escape processing disabled here"
					^ c asString]]
]

{ #category : #'platform dependent' }
ShellSyntax >> pathAboveRoot [
	"Answer a path pointing to a location above the file system root. The
	pathStringAboveRoot string refers to this location."

	 "ShellSyntax new pathAboveRoot"

	^ (self platformName = 'Win32')
		ifTrue: ['']
		ifFalse: [FileDirectory slash].

]

{ #category : #'platform dependent' }
ShellSyntax >> pathRoot: aPathString [
	"For aPathString pointing to a file in a file system, answer the root of the
	file system. This method works fine for Unix and Windows, but may require
	conditional code for other platforms."

	| prefix |
	prefix _ (self splitLocationPrefixFromPath: aPathString) first.
	^ prefix, FileDirectory slash

]

{ #category : #'path name expansion' }
ShellSyntax >> pathStringAboveRoot [
	"Magic string indicating location above the file system root. For Unix, this just
	points to the file system root. For Windows, it points to one level above the C: drive."

	^ '[]'
]

{ #category : #defaults }
ShellSyntax >> pipeCharToken [
	"The command pipeline character"

	^ '|'
]

{ #category : #'version dependent' }
ShellSyntax >> platformName [ 
	"After Squeak version 3.6, #platformName was moved to SmalltalkImage "

	^ ((Smalltalk classNamed: 'SmalltalkImage')
		ifNil: [^ Smalltalk platformName]) current platformName
]

{ #category : #'path name expansion' }
ShellSyntax >> programNameAndArgumentsFrom: aString inDirectoryPath: pathString [

	"ShellSyntax new programNameAndArgumentsFrom: 'sleep 6' inDirectoryPath: '/etc'"
	"ShellSyntax new programNameAndArgumentsFrom: 'ls -l h?s*' inDirectoryPath: '/etc'"

	| tokens tok args exe |
	tokens _ self argsFromCommand: aString.
	tokens size == 0
		ifTrue: [tok _ '']
		ifFalse: [tok _ tokens at: 1].
	args _ self expandArgumentsFrom: (tokens copyFrom: 2 to: tokens size) inDirectoryPath: pathString.
	exe _ self findExecutablePathFor: tok inDirectoryPath: pathString.
	exe ifNil: [exe _ tok].
	^ Array with: exe with: args

]

{ #category : #'command string parsing' }
ShellSyntax >> redirectIOFor: commandString inDirectoryPath: dirPathString [
	"Handle IO redirection. Answer a four element array with the command string
	(with IO tokens removed); and stdin, stdout and stderr if specified for
	redirection."

	"ShellSyntax new
		redirectIOFor: 'ls /tmp /NOSUCHFILE > /tmp/sqTempOut.tmp 2> /tmp/sqTempErr.tmp'
		inDirectoryPath: nil"
	"ShellSyntax new
		redirectIOFor: 'cat < /etc/hosts > /tmp/sqHosts.tmp'
		inDirectoryPath: nil"

	| cmd tokenStream tok target input output error |
	cmd _ nil.
	input _ output _ error _ nil.
	"Default to nil unless overridden by commandString."
	tokenStream _ ReadStream on: (self tokenizeForRedirect: commandString).
	[tokenStream atEnd]
		whileFalse:
			[tok _ tokenStream next.
			tok == #inputRedirect
				ifTrue: ["Do input redirection"
					target _ self expandArgument: tokenStream next
								inDirectoryPath: dirPathString.
					input _ FileStream readOnlyFileNamed: target.
					input
						ifNil: [self inform: 'Cannot open ' , target , ', using default stdin']]
				ifFalse: [tok == #outputRedirect
						ifTrue: ["Do output redirection"
							target _ self expandArgument: tokenStream next
										inDirectoryPath: dirPathString.
							output _ self truncatedOutputFile: target.
							output ifNil:
									[self inform: 'Cannot open ' , target , ', using default stdout']]
						ifFalse: [tok == #outputAppendRedirect
								ifTrue: ["Do output redirection, appended to existing output file if any."
									target _ self expandArgument: tokenStream next
												inDirectoryPath: dirPathString.
									output _ FileStream fileNamed: target.
									output isNil
										ifTrue: [self inform: 'Cannot open ' , target , ', using default stdout']
										ifFalse: [output setToEnd]]
								ifFalse: [tok == #errorRedirect
										ifTrue: ["Do error redirection"
											target _ self expandArgument: tokenStream next
														inDirectoryPath: dirPathString.
											error _ self truncatedOutputFile: target.
											error ifNil:
													[self inform: 'Cannot open ' , target , ', using default stdout']]
										ifFalse: [tok == #errorAppendRedirect
												ifTrue: ["Do error redirection, appended to existing error file if any. "
													target _ self expandArgument: tokenStream next
																inDirectoryPath: dirPathString.
													error _ FileStream fileNamed: target.
													error isNil
														ifTrue: [self inform: 'Cannot open ' , target , ', using default stdout']
														ifFalse: [error setToEnd]]
												ifFalse: [cmd isNil
														ifTrue: [cmd _ tok]
														ifFalse: [self inform: 'Ack! Pfft! IO redirection parsing error.']]]]]]].
	^ Array
		with: cmd
		with: input
		with: output
		with: error
]

{ #category : #'working directory' }
ShellSyntax >> setCwdIndexFrom: aPathString [
	"Set the current working directory index to a string (Win32 device name) or to #default."

	| prefix |
	prefix _ (self splitLocationPrefixFromPath: aPathString) first.
	prefix isEmpty
		ifTrue: [self cwdIndex: #default]
		ifFalse: [self cwdIndex: prefix]

]

{ #category : #'platform dependent' }
ShellSyntax >> splitLocationPrefixFromPath: aPathString [
	"Split any leading prefix from a path string, such as the C: device name
	for Win32. Answer an Array with prefix and path."

	 "ShellSyntax new splitLocationPrefixFromPath: 'C:\u'"
	 "ShellSyntax new splitLocationPrefixFromPath: 'C:\'"
	 "ShellSyntax new splitLocationPrefixFromPath: 'C:'"
	 "ShellSyntax new splitLocationPrefixFromPath: 'C:u'"
	 "ShellSyntax new splitLocationPrefixFromPath: 'c:u'"
	 "ShellSyntax new splitLocationPrefixFromPath: '\u'"

	| prefix path |
	(self platformName = 'Win32')
		ifTrue:
			[((aPathString at: 2 ifAbsent: []) == $:)
				ifTrue:
					[prefix _ (String new: 2).
					prefix at: 1 put: (aPathString at: 1) asUppercase.
					prefix at: 2 put: $:.
					path _ aPathString copyAfter: $:]
				ifFalse:
					[prefix _ ''.
					path _ aPathString]]
		ifFalse:
			[prefix _ ''.
			path _ aPathString].
	^ Array with: prefix with: path

]

{ #category : #globbing }
ShellSyntax >> tokenStream: aTokenStream matches: aCharacterStream [ 
	"Iterate over both streams. If each character in aCharacterStream 
	matches its corresponding token in tokenStream, answer true."

	"ShellSyntax new tokenStream: (ReadStream on: (ShellSyntax new globTokensFrom: 'a?c')) matches: (ReadStream on: 'abc')"
	"ShellSyntax new tokenStream: (ReadStream on: (ShellSyntax new globTokensFrom: 'ab*cde')) matches: (ReadStream on: 'abcde')"
	"ShellSyntax new tokenStream: (ReadStream on: (ShellSyntax new globTokensFrom: 'ab*cde')) matches: (ReadStream on: 'abXXXcde')"
	"ShellSyntax new tokenStream: (ReadStream on: (ShellSyntax new globTokensFrom: 'ab*cdX')) matches: (ReadStream on: 'abXXXcde')"
	"ShellSyntax new tokenStream: (ReadStream on: (ShellSyntax new globTokensFrom: 'abc*')) matches: (ReadStream on: 'abcde')"
	"ShellSyntax new tokenStream: (ReadStream on: (ShellSyntax new globTokensFrom: 'abc*')) matches: (ReadStream on: 'abc')"
	"ShellSyntax new tokenStream: (ReadStream on: (ShellSyntax new globTokensFrom: 'a?cde*jkl')) matches: (ReadStream on: 'abcdefghijkl')"
	"ShellSyntax new tokenStream: (ReadStream on: (ShellSyntax new globTokensFrom: 'abc[A-C]xyz')) matches: (ReadStream on: 'abcBxyz')"
	"ShellSyntax new tokenStream: (ReadStream on: (ShellSyntax new globTokensFrom: 'abc[!A-C]xyz')) matches: (ReadStream on: 'abcZxyz')"

	| c tok |
	[aCharacterStream atEnd]
		whileFalse: [aTokenStream atEnd
				ifTrue: [^ false].
			c _ aCharacterStream peek.
			tok _ aTokenStream next.
			tok == #not
				ifTrue: ["A negated character range follows"
					tok _ aTokenStream next.
					(self character: c matches: tok)
						ifTrue: [^ false].
					aCharacterStream next]
				ifFalse: ["The normal case"
					tok == #matchRun
						ifTrue:
							["Skip characters until we resync the streams, or answer false"
							[self tokenStream: aTokenStream copy matches: aCharacterStream copy]
								whileFalse:
									[aCharacterStream atEnd ifTrue: [^ false].
									aCharacterStream next]]
						ifFalse: [(self character: c matches: tok)
								ifFalse: [^ false].
							aCharacterStream next]]].
	^ aTokenStream atEnd
		or: [aTokenStream next == #matchRun
				and: [aTokenStream atEnd]]

]

{ #category : #'command string parsing' }
ShellSyntax >> tokenizeForRedirect: aString [
	"Answer a collection of tokens for IO redirection. Answers a collection of
	tokens, where each token is either a String, or a Symbol in:
	#(#inputRedirect #outputRedirect #outputAppendRedirect #errorRedirect #errorAppendRedirect)"

	"ShellSyntax new tokenizeForRedirect: 'one > two < three 2> four five six 2>> seven eight > nine ten >> eleven twelve 2 > thirteen'"

	| oc rs ws c redirectToken tok |
	oc _ OrderedCollection new.
	rs _ ReadStream on: aString.
	ws _ WriteStream on: ''.
	[rs atEnd]
		whileFalse:
			[c _ rs next.
			((c == $2) and: [rs peek == $>])
				ifTrue:
					[rs next.
					(rs peek == $>)
						ifTrue:
							[rs next.
							redirectToken _ #errorAppendRedirect]
						ifFalse:
							[redirectToken _ #errorRedirect].
					c _ ws contents.
					(c size > 0)
						ifTrue:
							[oc add: c.
							ws resetContents].
					oc add: redirectToken]
				ifFalse:
					[(c == $>)
						ifTrue:
							[(rs peek == $>)
								ifTrue:
									[rs next.
									redirectToken _ #outputAppendRedirect]
								ifFalse:
									[redirectToken _ #outputRedirect].
							c _ ws contents.
							(c size > 0)
								ifTrue:
									[oc add: c.
									ws resetContents].
							oc add: redirectToken]
						ifFalse:
							[(c == $<)
								ifTrue:
									[c _ ws contents.
									(c size > 0)
										ifTrue:
											[oc add: c.
											ws resetContents].
									oc add: #inputRedirect]
								ifFalse: [ws nextPut: c]]]].
	tok _ ws contents.
	(tok size > 0) ifTrue: [oc add: tok].
	^ oc

]

{ #category : #'command string parsing' }
ShellSyntax >> truncatedOutputFile: fileName [
	"Attempt to do reasonable things to open a file of size zero. Better would be
	to implement a file truncation primitive."

	"ShellSyntax new truncatedOutputFile: '/tmp/delete.me'"
	"ShellSyntax new truncatedOutputFile: '/dev/null'"

	| strm |
	[strm _ FileStream concreteStream forceNewFileNamed: fileName]
		on: Error
		do: [:ex | ^ FileStream fileNamed: fileName].
	^ strm

]

{ #category : #'platform dependent' }
ShellSyntax >> upOneDirectoryLevel: aPathName [
	"Answer a path name for a directory one level up the directory tree"

	 "ShellSyntax new upOneDirectoryLevel: 'C:\Windows\temp'"
	 "ShellSyntax new upOneDirectoryLevel: 'C:\Windows'"
	 "ShellSyntax new upOneDirectoryLevel: 'C:\'"
	 "ShellSyntax new upOneDirectoryLevel: ''"
	 "ShellSyntax new upOneDirectoryLevel: '/usr/bin'"
	 "ShellSyntax new upOneDirectoryLevel: '/usr'"
	 "ShellSyntax new upOneDirectoryLevel: '/'"

	| prefixAndPath prefix path newPath |
	prefixAndPath _ self splitLocationPrefixFromPath: aPathName.
	prefix _ prefixAndPath at: 1.
	path _ prefixAndPath at: 2.
	(self isAtFileSystemRoot: aPathName)
		ifTrue:
			[prefix isEmpty
				ifTrue: "Normal case, unix. Do not go up a level."
					[^ aPathName]
				ifFalse: "A Win32 device name, go up a level above the file systems"
					[^ '']]
		ifFalse:
			[newPath _ path copyUpToLast: FileDirectory pathNameDelimiter.
			^ newPath isEmpty
				ifTrue:
					[prefix, FileDirectory slash]
				ifFalse:
					[prefix, newPath]]

]

{ #category : #'working directory' }
ShellSyntax >> workingDirectory [

	^ self cwdDictionary at: self cwdIndex ifAbsentPut:
		[(Smalltalk hasClassNamed: #OSProcess)
			ifTrue: [(Smalltalk at: #OSProcess) thisOSProcess getCwd]
			ifFalse: [nil]]

]

{ #category : #'working directory' }
ShellSyntax >> workingDirectory: aPathString [

	self setCwdIndexFrom: aPathString.
	self cwdDictionary at: self cwdIndex put: aPathString
]
