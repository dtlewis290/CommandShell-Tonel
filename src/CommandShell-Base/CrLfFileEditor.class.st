"
I provide an editor on a single file. I attempt to avoid changing the line termination character convention when writing my text back to a file.

Bug: On older Squeak systems which do not support FilesStream>>truncate, file permissions may be lost when a file is rewritten at a shorter length.

"
Class {
	#name : #CrLfFileEditor,
	#superclass : #Model,
	#instVars : [
		'contents',
		'lineEndConvention',
		'directory',
		'fileName',
		'viewStyle'
	],
	#category : 'CommandShell-Commands'
}

{ #category : #private }
CrLfFileEditor class >> defaultLineEndConvention [
	"FIXME: The Unix and Win32 are right, but I just guessed at the others - dtl"

	| platform |
	platform :=  ShellSyntax new platformName.
	(platform = 'unix') ifTrue: [^ #lf].
	(platform = 'Win32') ifTrue: [^ #crlf].
	(platform = 'Mac OS') ifTrue: [^ #cr].
	(platform = 'RiscOS') ifTrue: [^ #cr].
	(platform = 'OS2') ifTrue: [^ #crlf]. "FIXME: Is this the right name for OS2?"
	"Add other system types here..."
	^ #cr

]

{ #category : #'instance creation' }
CrLfFileEditor class >> editFileNamed: pathName [

	"CrLfFileEditor editFileNamed: '/etc/hosts'"
	"CrLfFileEditor editFileNamed: '/NO/SUCH/FILE'"
	"CrLfFileEditor editFileNamed: '/etc/NOSUCHFILE)'"

	^ Cursor read showWhile: [self openForFileNamed: pathName].

]

{ #category : #'instance creation' }
CrLfFileEditor class >> fileNamed: pathName [
	"Answer a Controller or Morph as view on an instance of myself."

	"CrLfFileEditor fileNamed: '/etc/hosts'"
	"CrLfFileEditor fileNamed: '/NO/SUCH/FILE'"
	"CrLfFileEditor fileNamed: '/etc/NOSUCHFILE'"

	^ self fileNamed: pathName withLabel: pathName

]

{ #category : #'instance creation' }
CrLfFileEditor class >> fileNamed: pathName inDirectoryPath: dirPath [
	"Answer a Controller or Morph as view on an instance of myself."

	"CrLfFileEditor fileNamed: '/etc/hosts' inDirectoryPath: '/usr/bin'"
	"CrLfFileEditor fileNamed: 'bin/vi' inDirectoryPath: '/usr'"
	"CrLfFileEditor fileNamed: 'hosts' inDirectoryPath: '/etc'"
	"CrLfFileEditor fileNamed: 'hosts' inDirectoryPath: '/usr/bin'"
	"CrLfFileEditor fileNamed: '/NO/SUCH/FILE' inDirectoryPath: '/etc'"
	"CrLfFileEditor fileNamed: '/etc/NOSUCHFILE' inDirectoryPath: '/etc'"

	| dir fs convention editText |
	dir := CommandShell directoryForPath: dirPath.
	(dir fileExists: pathName)
		ifTrue:
			[[fs := (Smalltalk
						at: #MultiByteFileStream
						ifAbsent: [Smalltalk at: #CrLfFileStream])
							readOnlyFileNamed: dirPath, CommandShell pathSeparator, pathName.
			convention := fs detectLineEndConvention.
			editText := fs contentsOfEntireFile.
			fs close]
				on: Error
				do: [:ex |
					convention := #lf.	"Default for Unix text files"
					editText := '']]
		ifFalse:
			[convention := #lf.	"Default for Unix text files"
			editText := ''].
	^ self on: editText
		withLabel: pathName
		inDirectory: dir
		defaultFileName: pathName
		lineEndConvention: convention

]

{ #category : #'instance creation' }
CrLfFileEditor class >> fileNamed: pathName withLabel: windowLabel [
	"Answer a Controller or Morph as view on an instance of myself."

	"CrLfFileEditor fileNamed: '/etc/hosts' withLabel: 'an editor on /etc/hosts'"

	| dirPath dir fs convention editText localName |
	dirPath := CommandShell dirPathFor: pathName.
	dir := CommandShell directoryForPath: dirPath..
	localName := CommandShell localNameFor: pathName.
	(CommandShell fileExists: localName inDirectory: dir)
		ifTrue:
			[[fs := (Smalltalk
						at: #MultiByteFileStream
						ifAbsent: [Smalltalk at: #CrLfFileStream])
							readOnlyFileNamed: pathName.
			convention := fs detectLineEndConvention.
			editText := fs contentsOfEntireFile.
			fs close]
				on: Error
				do: [:ex |
					convention := #lf.	"Default for Unix text files"
					editText := '']]
		ifFalse:
			[convention := #lf.	"Default for Unix text files"
			editText := ''].
	^ self on: editText
		withLabel: windowLabel
		inDirectory: dir
		defaultFileName: localName
		lineEndConvention: convention

]

{ #category : #'class initialization' }
CrLfFileEditor class >> initialize [

	"CrLfFileEditor initialize"

	| preferencesClass |
	(Smalltalk hasClassNamed: #Preferences)
		ifTrue: ["Pharo deprecates Preference in favor of pragma registration mechanism"
			preferencesClass := Smalltalk at: #Preferences.
			(preferencesClass respondsTo: #setWindowColorFor:to: )
				ifTrue: ["Squeak"
					preferencesClass 
						setWindowColorFor: #CommandShell 
						to: (Color colorFrom: self windowColorSpecification pastelColor)]
				ifFalse: ["Pharo images use some other preferences protocol"]].

]

{ #category : #'instance creation' }
CrLfFileEditor class >> on: aString withLabel: aLabelString inDirectory: aDirectory defaultFileName: nameString [

	"(CrLfFileEditor on: 'this is the string to edit' withLabel: 'this is the window label' inDirectory: FileDirectory default defaultFileName: 'buffer.txt') openInWorld"

	^ self on: aString withLabel: aLabelString inDirectory: aDirectory defaultFileName: nameString lineEndConvention: self defaultLineEndConvention

]

{ #category : #'instance creation' }
CrLfFileEditor class >> on: aString withLabel: aLabelString inDirectory: aDirectory defaultFileName: nameString lineEndConvention: convention [


	"(CrLfFileEditor on: 'this is the string to edit' withLabel: 'this is the window label' inDirectory: FileDirectory default defaultFileName: 'buffer.txt' lineEndConvention: #lf) openInWorld"

	| model |
	model := self new contents: aString.
	model directory: aDirectory.
	model fileName: nameString.
	model lineEndConvention: convention.
	^ model withLabel: aLabelString

]

{ #category : #private }
CrLfFileEditor class >> openForFileNamed: pathName [

	"CrLfFileEditor openForFileNamed: '/etc/hosts'"
	"CrLfFileEditor openForFileNamed: '/NO/SUCH/FILE'"
	"CrLfFileEditor openForFileNamed: '/etc/NOSUCHFILE'"

	^ CommandShell isMorphic
		ifTrue: [(self fileNamed: pathName) openInWorld]
		ifFalse: [(self fileNamed: pathName) open]

]

{ #category : #'instance creation' }
CrLfFileEditor class >> openOn: aString withLabel: aLabelString inDirectory: aDirectory defaultFileName: nameString [

	"CrLfFileEditor openOn: 'this is the string to edit' withLabel: 'this is the window label' inDirectory: FileDirectory default defaultFileName: 'buffer.txt'"

	^ self openOn: aString withLabel: aLabelString inDirectory: aDirectory defaultFileName: nameString lineEndConvention: self defaultLineEndConvention

]

{ #category : #'instance creation' }
CrLfFileEditor class >> openOn: aString withLabel: aLabelString inDirectory: aDirectory defaultFileName: nameString lineEndConvention: convention [

	"CrLfFileEditor openOn: 'this is the string to edit' withLabel: 'this is the window label' inDirectory: FileDirectory default defaultFileName: 'buffer.txt' lineEndConvention: #lf"

	| model |
	model := self new contents: aString.
	model directory: aDirectory.
	model fileName: nameString.
	model lineEndConvention: convention.
	^ model openLabel: aLabelString

]

{ #category : #'window color' }
CrLfFileEditor class >> windowColorSpecification [
	"Answer a WindowColorSpec object that declares my preference"

	| windowColorSpec |
	windowColorSpec := Smalltalk
				at: #WindowColorSpec
				ifAbsent: [^self error: 'this image does not support WindowColorSpec'].
	^ windowColorSpec
		classSymbol: self name
		wording: 'Squeak Shell File Editor'
		brightColor: Color lightOrange
		pastelColor: Color lightOrange paler paler
		helpMessage: 'CrLfFileEditor window for CommandShell ''edit'' comand'

]

{ #category : #private }
CrLfFileEditor >> bogusTruncate: fileStream [
	"Truncate the file by brute force if FileStream>>truncate is not supported on
	this system. Note that this does not preserve file permissions."

	| name |
	name := fileStream name.
	fileStream close.
	CommandShell deleteFileNamed: name inDirectory: directory.
	^ (Smalltalk at: #CrLfFileStream) fileNamed: name

]

{ #category : #menus }
CrLfFileEditor >> browseChanges [
	"Browse in fileIn format."

	| fs |
	fs :=  CommandShell fileNamed: fileName inDirectory: directory.
	ChangeList browseStream: fs.
	fs close

]

{ #category : #'model access' }
CrLfFileEditor >> contents [

	^ viewStyle == #hex
		ifTrue: [self hexFormat: contents]
		ifFalse: [contents]

]

{ #category : #'model access' }
CrLfFileEditor >> contents: aString [
	viewStyle == #hex
		ifTrue: [ self inform: 'cannot update in hex mode' ]
		ifFalse: [ contents := aString	"asString" ]
]

{ #category : #accessing }
CrLfFileEditor >> contentsSelection [
	"Return the interval of text in the code pane to select when I set the pane's contents"

	^ 1 to: 0  "null selection"
]

{ #category : #menus }
CrLfFileEditor >> controllerForAccept [
	"Find the controller or morph which expects the #accept message"

	| controller view |
	CommandShell isMorphic
		ifTrue:
			[controller := dependents detect: [:e | e respondsTo: #accept] ifNone: [nil]]
		ifFalse:
			[view := dependents detect: [:e | e controller respondsTo: #accept] ifNone: [nil].
			controller := view isNil
				ifTrue: [nil]
				ifFalse: [view controller]].
	^ controller
]

{ #category : #'model access' }
CrLfFileEditor >> currentFilePathName [

	^ (CommandShell dirPathFor: directory), CommandShell pathSeparator, fileName
]

{ #category : #'initialize-release' }
CrLfFileEditor >> defaultFont [
	"A fixed width font suitable for displaying output of shell command lines"

	^ StrikeFont familyName: 'Atlanta' size: 11 emphasized: 0
]

{ #category : #accessing }
CrLfFileEditor >> directory: aDirectory [

	directory := aDirectory
]

{ #category : #menus }
CrLfFileEditor >> exit [

	self changed: #accept.
	CommandShell isMorphic
		ifTrue:
			[dependents do: [:d | (d respondsTo: #closeBoxHit) ifTrue: [d closeBoxHit]]]
		ifFalse:
			[dependents first controller closeAndUnschedule]
]

{ #category : #'model access' }
CrLfFileEditor >> fileContentsMenu: aMenu shifted: shifted [

| shiftMenu |
^ shifted 
	ifFalse: [aMenu 
		labels: 
'save
save as...
exit
view as hex
view as text
browse changes
find...(f)
find again (g)
set search string (h)
do again (j)
undo (z)
copy (c)
cut (x)
paste (v)
paste...
do it (d)
print it (p)
inspect it (i)
fileIn selection
accept (s)
cancel (l)
more...' 
		lines: #(3 6 9 11 15 19 21)
		selections: #(save saveAs exit getHex getText browseChanges
find findAgain setSearchString
again undo
copySelection cut paste pasteRecent
doIt printIt inspectIt fileItIn
accept cancel
shiftedYellowButtonActivity)]

	ifTrue: [shiftMenu := (Smalltalk at: #ParagraphEditor) shiftedYellowButtonMenu.
		aMenu 
			labels: shiftMenu labelString 
			lines: shiftMenu lineArray
			selections: shiftMenu selections]


]

{ #category : #accessing }
CrLfFileEditor >> fileName: aString [

	fileName := aString
]

{ #category : #private }
CrLfFileEditor >> forceDirtyBuffer [
	"This will force the view to behave as if it had been edited. Call this to
	enable a file save even if the text has not actually been edited by the
	user."

	| controller |
	controller := self dependents
			detect: [:e | e respondsTo: #hasUnacceptedEdits:]
			ifNone:
				[self dependents
					collect: [:d | d controller]
					thenSelect: [:c | c respondsTo: #hasUnacceptedEdits:]].
	controller hasUnacceptedEdits: true.

]

{ #category : #private }
CrLfFileEditor >> getAnotherFileName: initialFileName [

	| choice newFileName |
	choice := ((Smalltalk at: #PopUpMenu)
		labels: 'choose another name\cancel' withCRs)
		startUpWithCaption: initialFileName.
	choice = 1
		ifTrue: [newFileName := (Smalltalk at: #FillInTheBlank)
									request: 'Enter a new file name'
									initialAnswer: initialFileName.
				newFileName := (CommandShell fileExists: newFileName inDirectory: directory)
					ifTrue: [self getFileName: newFileName]
					ifFalse: [newFileName].
				^ newFileName].
	^ nil
]

{ #category : #private }
CrLfFileEditor >> getFileName: initialFileName [

	| choice newFileName |
	choice := ((Smalltalk at: #PopUpMenu)
		labels: 'overwrite that file\choose another name\cancel' withCRs)
		startUpWithCaption: initialFileName, ' already exists.'.
	choice = 1
		ifTrue: [^ initialFileName].
	choice = 2
		ifTrue: [newFileName := (Smalltalk at: #FillInTheBlank)
									request: 'Enter a new file name'
									initialAnswer: initialFileName.
				newFileName := (CommandShell fileExists: newFileName inDirectory: directory)
					ifTrue: [self getFileName: newFileName]
					ifFalse: [newFileName].
				^ newFileName].
	^ nil
]

{ #category : #menus }
CrLfFileEditor >> getHex [

	Cursor read showWhile:
		[self viewStyle: #hex.
		self changed: #contents]

]

{ #category : #'model access' }
CrLfFileEditor >> getSelection [

	^ 1 to: 0  "null selection"
]

{ #category : #menus }
CrLfFileEditor >> getText [

	Cursor read showWhile:
		[self viewStyle: #text.
		self changed: #contents]

]

{ #category : #private }
CrLfFileEditor >> hexFormat: aString [

	"CrLfFileEditor new hexFormat: 'this is a test of the HEX string reformat method'"

	| s |
	s := WriteStream on: (String new: aString size*4).
	0 to: aString size-1 by: 16 do:
		[:loc | s nextPutAll: loc hex; space;
			nextPut: $(; print: loc; nextPut: $); space; tab.
		loc+1 to: (loc+16 min: aString size) do: [:i | s nextPutAll: (aString at: i) hex; space].
		s cr].
	^ s contents.

]

{ #category : #'model access' }
CrLfFileEditor >> labelString [
	"For views to use a labels"

	^ self currentFilePathName
]

{ #category : #accessing }
CrLfFileEditor >> lineEndConvention: aSymbol [
	"See CrLfFileStream for the allowable values of aSymbol."

	lineEndConvention := aSymbol
]

{ #category : #'initialize-release' }
CrLfFileEditor >> mvcWithLabel: aLabelString [
	| topView controllerClass fileContentsView |
	CommandShell isMorphic
		ifTrue: [ ^ self error: 'this method should be used only for MVC' ].
	topView := (Smalltalk at: #StandardSystemView) new.
	controllerClass := Smalltalk
		at: #DeferredActionStandardSystemController
		ifAbsent: [ Smalltalk at: #StandardSystemController ].
	topView
		model: self;
		controller: controllerClass new;
		label: aLabelString;
		minimumSize: 200 @ 200.
	topView borderWidth: 1.
	fileContentsView := (Smalltalk at: #PluggableTextView)
		on: self
		text: #contents
		accept: #put:
		readSelection: #contentsSelection
		menu: #fileContentsMenu:shifted:.
	fileContentsView window: (0 @ 0 extent: 200 @ 140).
	topView addSubView: fileContentsView.
	^ topView controller
]

{ #category : #'initialize-release' }
CrLfFileEditor >> openAsMorphLabel: aLabelString [

	| window textMorph |
	textMorph := PluggableTextMorph
		on: self
		text: #contents
		accept: #put:
		readSelection: #contentsSelection menu: #fileContentsMenu:shifted:.
	textMorph font: self defaultFont.
	window := (SystemWindow labelled: aLabelString) model: self.
	window
		addMorph: textMorph
		frame: (0@0 corner: 1@1).
	^ window
]

{ #category : #'initialize-release' }
CrLfFileEditor >> openLabel: aLabelString [

	CommandShell isMorphic
		ifTrue:
			[^ (self openAsMorphLabel: aLabelString) openInWorld]
		ifFalse:
			[^ (self mvcWithLabel: aLabelString) open]

]

{ #category : #'model access' }
CrLfFileEditor >> put: aText [ 

	| str newFileName fs |
	viewStyle == #hex
		ifTrue: [self inform: 'cannot save file in hex mode'.
				^ false].
	str := aText asString.
	self contents: str.
	(CommandShell fileExists: fileName inDirectory: directory)
		ifTrue: [newFileName := self
					getFileName: (CommandShell pathNameForDirectory: directory),
						CommandShell pathSeparator , fileName.]
		ifFalse: [newFileName := (CommandShell pathNameForDirectory: directory),
						CommandShell pathSeparator , fileName].
	newFileName ifNil: [^ false].
	fs := (Smalltalk at: #CrLfFileStream) fileNamed: newFileName.
	[fs isNil] whileTrue:
		[self inform: 'cannot write file'.
		newFileName := self getAnotherFileName: newFileName.
		newFileName isNil
			ifTrue:
				[self inform: 'file not written'.
				^ false]
			ifFalse:
				[fs := (Smalltalk at: #CrLfFileStream )fileNamed: newFileName]].
	(str size < fs size)
		ifTrue:
			[(fs respondsTo: #truncate)
				ifTrue:
					[[fs truncate]
						on: Error
						do: [:ex | fs := self bogusTruncate: fs]]
				ifFalse: [fs := self bogusTruncate: fs]].
	fs nextPutAll: str.
	fs close.
	self updateFilePathWith: newFileName.
	^ true
]

{ #category : #menus }
CrLfFileEditor >> save [

	| controller |
	self forceDirtyBuffer.
	controller := self controllerForAccept.
	controller ifNotNil: [controller accept]

]

{ #category : #menus }
CrLfFileEditor >> saveAs [

	| oldFilePath newFilePath controller |
	oldFilePath := self currentFilePathName.
	newFilePath := (Smalltalk at: #FillInTheBlank)
					request: 'Enter a new file name'
					initialAnswer: oldFilePath.
	newFilePath isEmpty
		ifFalse:
			[self updateFilePathWith: newFilePath.
			controller := self controllerForAccept.
			controller ifNotNil:
				[self forceDirtyBuffer.
				controller accept]]


]

{ #category : #menus }
CrLfFileEditor >> selectedClassOrMetaClass [
	"For support of the pretty printer menu option"

	^ self class
]

{ #category : #menus }
CrLfFileEditor >> selectedMessageCategoryName [
	"For support of the pretty printer menu option"

	^ '-- all --'
]

{ #category : #private }
CrLfFileEditor >> updateFilePathWith: aPathString [

	self fileName: (CommandShell localNameFor: aPathString).
	self directory: (CommandShell directoryForPath: aPathString).
	self changed: #relabel

]

{ #category : #accessing }
CrLfFileEditor >> viewStyle: aSymbol [
	"#text or #hex"

	viewStyle := aSymbol
]

{ #category : #'initialize-release' }
CrLfFileEditor >> withLabel: aLabelString [
	"Same as #openLabel: but does not open the window in MVC"

	CommandShell isMorphic
		ifTrue:
			[^ self openAsMorphLabel: aLabelString]
		ifFalse:
			[^ self mvcWithLabel: aLabelString]

]
