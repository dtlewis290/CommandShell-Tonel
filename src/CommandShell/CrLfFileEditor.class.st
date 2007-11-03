"
I provide an editor on a single file. I attempt to avoid changing the line termination character convention when writing my text back to a file.

Bug: On older Squeak systems which do not support FilesStream>>truncate, file permissions may be lost when a file is rewritten at a shorter length.

"
Class {
	#name : #CrLfFileEditor,
	#superclass : #StringHolder,
	#instVars : [
		'lineEndConvention',
		'directory',
		'fileName',
		'viewStyle'
	],
	#category : #CommandShell
}

{ #category : #private }
CrLfFileEditor class >> defaultLineEndConvention [
	"FIXME: The Unix and Win32 are right, but I just guessed at the others - dtl"

	| platform |
	platform _  Smalltalk platformName.
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
	dir _ FileDirectory on: dirPath.
	(dir fileExists: pathName)
		ifTrue:
			[[fs _ CrLfFileStream readOnlyFileNamed: dirPath, FileDirectory slash, pathName.
			convention _ fs detectLineEndConvention.
			editText _ fs contentsOfEntireFile.
			fs close]
				on: Error
				do: [:ex |
					convention _ #lf.	"Default for Unix text files"
					editText _ '']]
		ifFalse:
			[convention _ #lf.	"Default for Unix text files"
			editText _ ''].
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
	dirPath _ FileDirectory dirPathFor: pathName.
	dir _ FileDirectory on: dirPath.
	localName _ FileDirectory localNameFor: pathName.
	(dir fileExists: localName)
		ifTrue:
			[[fs _ CrLfFileStream readOnlyFileNamed: pathName.
			convention _ fs detectLineEndConvention.
			editText _ fs contentsOfEntireFile.
			fs close]
				on: Error
				do: [:ex |
					convention _ #lf.	"Default for Unix text files"
					editText _ '']]
		ifFalse:
			[convention _ #lf.	"Default for Unix text files"
			editText _ ''].
	^ self on: editText
		withLabel: windowLabel
		inDirectory: dir
		defaultFileName: localName
		lineEndConvention: convention

]

{ #category : #'class initialization' }
CrLfFileEditor class >> initialize [

	"CrLfFileEditor initialize"

	Preferences 
		setWindowColorFor: #CrLfFileEditor 
		to: (Color colorFrom: self windowColorSpecification pastelColor)

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
	model _ self new contents: aString.
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

	^ Smalltalk isMorphic
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

	"CrLfFileEditor openOn: 'this is the string to edit' withLabel: 'this is the window label' inDirectory: FileDirectory default defaultFileName: 'buffer.txt' convention: #lf"

	| model |
	model _ self new contents: aString.
	model directory: aDirectory.
	model fileName: nameString.
	model lineEndConvention: convention.
	^ model openLabel: aLabelString

]

{ #category : #'window color' }
CrLfFileEditor class >> windowColorSpecification [
	"Answer a WindowColorSpec object that declares my preference"

	^ WindowColorSpec
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
	name _ fileStream name.
	fileStream close.
	directory deleteFileNamed: name.
	^ CrLfFileStream fileNamed: name

]

{ #category : #menus }
CrLfFileEditor >> browseChanges [
	"Browse in fileIn format."

	| fs |
	fs _  self directory fileNamed: fileName.
	ChangeList browseStream: fs.
	fs close

]

{ #category : #'model access' }
CrLfFileEditor >> contents [

	^ (self viewStyle == #hex)
		ifTrue: [self hexFormat: contents]
		ifFalse: [contents]

]

{ #category : #'model access' }
CrLfFileEditor >> contents: aString [

	(self viewStyle == #hex)
		ifTrue: [self inform: 'cannot update in hex mode']
		ifFalse: [^ super contents: aString]
]

{ #category : #menus }
CrLfFileEditor >> controllerForAccept [
	"Find the controller or morph which expects the #accept message"

	| controller view |
	Smalltalk isMorphic
		ifTrue:
			[controller _ dependents detect: [:e | e respondsTo: #accept] ifNone: [nil]]
		ifFalse:
			[view _ dependents detect: [:e | e controller respondsTo: #accept] ifNone: [nil].
			controller _ view isNil
				ifTrue: [nil]
				ifFalse: [view controller]].
	^ controller
]

{ #category : #'model access' }
CrLfFileEditor >> currentFilePathName [

	^ self directory pathName, FileDirectory slash, self fileName
]

{ #category : #accessing }
CrLfFileEditor >> directory [

	^ directory
]

{ #category : #accessing }
CrLfFileEditor >> directory: aDirectory [

	directory _ aDirectory
]

{ #category : #menus }
CrLfFileEditor >> exit [

	self changed: #accept.
	Smalltalk isMorphic
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

	ifTrue: [shiftMenu _ ParagraphEditor shiftedYellowButtonMenu.
		aMenu 
			labels: shiftMenu labelString 
			lines: shiftMenu lineArray
			selections: shiftMenu selections]


]

{ #category : #accessing }
CrLfFileEditor >> fileName [

	^ fileName
]

{ #category : #accessing }
CrLfFileEditor >> fileName: aString [

	fileName _ aString
]

{ #category : #private }
CrLfFileEditor >> forceDirtyBuffer [
	"This will force the view to behave as if it had been edited. Call this to
	enable a file save even if the text has not actually been edited by the
	user."

	| controller |
	controller _ self dependents
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
	choice _ (PopUpMenu
		labels: 'choose another name\cancel' withCRs)
		startUpWithCaption: initialFileName.
	choice = 1
		ifTrue: [newFileName _ FillInTheBlank
									request: 'Enter a new file name'
									initialAnswer: initialFileName.
				newFileName _ (directory fileExists: newFileName)
					ifTrue: [self getFileName: newFileName]
					ifFalse: [newFileName].
				^ newFileName].
	^ nil
]

{ #category : #private }
CrLfFileEditor >> getFileName: initialFileName [

	| choice newFileName |
	choice _ (PopUpMenu
		labels: 'overwrite that file\choose another name\cancel' withCRs)
		startUpWithCaption: initialFileName, ' already exists.'.
	choice = 1
		ifTrue: [^ initialFileName].
	choice = 2
		ifTrue: [newFileName _ FillInTheBlank
									request: 'Enter a new file name'
									initialAnswer: initialFileName.
				newFileName _ (directory fileExists: newFileName)
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
	s _ WriteStream on: (String new: aString size*4).
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
CrLfFileEditor >> lineEndConvention [

	^ lineEndConvention
]

{ #category : #accessing }
CrLfFileEditor >> lineEndConvention: aSymbol [
	"See CrLfFileStream for the allowable values of aSymbol."

	lineEndConvention _ aSymbol
]

{ #category : #'initialize-release' }
CrLfFileEditor >> mvcWithLabel: aLabelString [

	| topView fileContentsView |
	Smalltalk isMorphic ifTrue:
		[^ self error: 'this method should be used only for MVC'].
	topView _ StandardSystemView new.
	topView
		model: self;
		controller: DeferredActionStandardSystemController new;
		label: aLabelString;
		minimumSize: 200@200.
	topView borderWidth: 1.
	fileContentsView _ PluggableTextView on: self
		text: #contents
		accept: #put:
		readSelection: #contentsSelection
		menu: #fileContentsMenu:shifted:.
	fileContentsView window: (0@0 extent: 200@140).
	topView addSubView: fileContentsView.
	^ topView controller

]

{ #category : #'initialize-release' }
CrLfFileEditor >> openAsMorphLabel: aLabelString [

	| window |
	window _ (SystemWindow labelled: aLabelString) model: self.
	window
		addMorph: (PluggableTextMorph
		on: self
		text: #contents
		accept: #put:
		readSelection: #contentsSelection menu: #fileContentsMenu:shifted:)
		frame: (0@0 corner: 1@1).
	^ window
]

{ #category : #'initialize-release' }
CrLfFileEditor >> openLabel: aLabelString [

	Smalltalk isMorphic
		ifTrue:
			[^ (self openAsMorphLabel: aLabelString) openInWorld]
		ifFalse:
			[^ (self mvcWithLabel: aLabelString) open]

]

{ #category : #'model access' }
CrLfFileEditor >> put: aText [ 

	| str newFileName fs |
	(self viewStyle == #hex)
		ifTrue:
			[self inform: 'cannot save file in hex mode'.
			^ false].
	str _ aText asString.
	self contents: str.
	(directory fileExists: fileName)
		ifTrue: [newFileName _ self
					getFileName: directory pathName,
						FileDirectory slash , fileName.]
		ifFalse: [newFileName _ directory pathName,
						FileDirectory slash , fileName].
	newFileName ifNil: [^ false].
	fs _ CrLfFileStream fileNamed: newFileName.
	[fs isNil] whileTrue:
		[self inform: 'cannot write file'.
		newFileName _ self getAnotherFileName: newFileName.
		newFileName isNil
			ifTrue:
				[self inform: 'file not written'.
				^ false]
			ifFalse:
				[fs _ CrLfFileStream fileNamed: newFileName]].
	(str size < fs size)
		ifTrue:
			[(fs respondsTo: #truncate)
				ifTrue:
					[[fs truncate]
						on: Error
						do: [:ex | fs _ self bogusTruncate: fs]]
				ifFalse: [fs _ self bogusTruncate: fs]].
	fs nextPutAll: str.
	fs close.
	self updateFilePathWith: newFileName.
	^ true
]

{ #category : #menus }
CrLfFileEditor >> save [

	| controller |
	self forceDirtyBuffer.
	controller _ self controllerForAccept.
	controller ifNotNil: [controller accept]

]

{ #category : #menus }
CrLfFileEditor >> saveAs [

	| oldFilePath newFilePath controller |
	oldFilePath _ self currentFilePathName.
	newFilePath _ FillInTheBlank
					request: 'Enter a new file name'
					initialAnswer: oldFilePath.
	newFilePath isEmpty
		ifFalse:
			[self updateFilePathWith: newFilePath.
			controller _ self controllerForAccept.
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

	self fileName: (FileDirectory localNameFor: aPathString).
	self directory: (FileDirectory on: (FileDirectory dirPathFor: aPathString)).
	self changed: #relabel

]

{ #category : #accessing }
CrLfFileEditor >> viewStyle [
	"#text or #hex"

	viewStyle isNil ifTrue: [viewStyle _ #text].
	^ viewStyle
]

{ #category : #accessing }
CrLfFileEditor >> viewStyle: aSymbol [
	"#text or #hex"

	viewStyle _ aSymbol
]

{ #category : #'initialize-release' }
CrLfFileEditor >> withLabel: aLabelString [
	"Same as #openLabel: but does not open the window in MVC"

	Smalltalk isMorphic
		ifTrue:
			[^ self openAsMorphLabel: aLabelString]
		ifFalse:
			[^ self mvcWithLabel: aLabelString]

]
