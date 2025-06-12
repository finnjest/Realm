#NoTrayIcon
#SingleInstance, Force
SetBatchLines, -1

#MaxHotkeysPerInterval 500

FileEncoding, UTF-8

; -------------------------------------------------------------------------------
; VARIABLES
; -------------------------------------------------------------------------------

version := "v1.0.0"

Global KeepEmptyLines
global LastFoundPos := 0
global CurrentSavePath := ""

AlwaysOnTop := 0
AutoInput := 0
ColumnView := 0
InlineTooltip := 0
; editControls := ["Edit1", "Edit2"]

CurrentIndex := 1
SavedValues := []
CaretIndices := []

; -------------------------------------------------------------------------------
; TRAY ICON HANDLE
; -------------------------------------------------------------------------------

if FileExist(a_scriptDir . "\icon\realm.ico") {
    Menu, Tray, Icon, % a_scriptDir "\icon\realm.ico", , 1
}

; -------------------------------------------------------------------------------
; ---------------------------------- MAIN GUI -----------------------------------
; -------------------------------------------------------------------------------

; -------------------------------------------------------------------------------
; MENU BAR
; -------------------------------------------------------------------------------

Menu, FileMenu, Add, New, ReloadScript
Menu, FileMenu, Add, Open, SelectFile
Menu, FileMenu, Add, Save `tCTRL + S, FileSave
Menu, FileMenu, Add, Save As, FileSaveAs
Menu, FileMenu, Add ; Separator
Menu, FileMenu, Add, Exit `tEsc, GuiClose

Menu, EditMenu, Add, Undo `tCTRL + Z, Undo
Menu, EditMenu, Add, Redo `tCTRL + SHIFT + Z, Redo
Menu, EditMenu, Add
Menu, EditMenu, Add, Cut, Cut
Menu, EditMenu, Add, Copy, Copy
Menu, EditMenu, Add, Paste, Paste
Menu, EditMenu, Add,
Menu, EditMenu, Add, Select All, SelectAll
Menu, EditMenu, Add, Date `tF5, InsertDateTime

Menu, ZoomMenu, Add, Zoom In, ZoomIn
Menu, ZoomMenu, Add, Zoom Out, ZoomOut
Menu, ZoomMenu, Add, Restore Default Zoom, ResetFont

Menu, TransparencyMenu, Add, 0`% (Opaque), SetTransparency, Radio
Menu, TransparencyMenu, Add, 10`%, SetTransparency, Radio
Menu, TransparencyMenu, Add, 20`%, SetTransparency, Radio
Menu, TransparencyMenu, Add, 30`%, SetTransparency, Radio
Menu, TransparencyMenu, Add, 40`%, SetTransparency, Radio
Menu, TransparencyMenu, Add, 50`%, SetTransparency, Radio
Menu, TransparencyMenu, Add, 60`%, SetTransparency, Radio
Menu, TransparencyMenu, Add, 70`%, SetTransparency, Radio
Menu, TransparencyMenu, Add, 80`%, SetTransparency, Radio
Menu, TransparencyMenu, Add, 90`%, SetTransparency, Radio

Menu, ViewMenu, Add, Zoom, :ZoomMenu
Menu, ViewMenu, Add, Transparency, :TransparencyMenu
Menu, ViewMenu, Add, Font..., Font
Menu, ViewMenu, Add
Menu, ViewMenu, Add, Status Bar, ToggleStatusBar
Menu, ViewMenu, Check, Status Bar

Menu, SettingsMenu, Add, Always On Top, ToggleAlwaysOnTop
Menu, SettingsMenu, Uncheck, Always On Top
Menu, SettingsMenu, Add, Auto Result, ToggleAutoInput
Menu, SettingsMenu, Uncheck, Auto Result
Menu, SettingsMenu, Add, Column Mode, ColumnMod
Menu, SettingsMenu, Uncheck, Column Mode

Menu, HelpMenu, Add, Tooltips, HelpTooltips
Menu, HelpMenu, Uncheck, Tooltips
Menu, HelpMenu, Add, About, ShowAboutDialog

; Create the Main Menu Bar
Menu, MyMenuBar, Add, File, :FileMenu
Menu, MyMenuBar, Add, Edit, :EditMenu
Menu, MyMenuBar, Add, View, :ViewMenu
Menu, MyMenuBar, Add, Settings, :SettingsMenu
Menu, MyMenuBar, Add, Help, :HelpMenu

Gui, Menu, MyMenuBar

; -------------------------------------------------------------------------------
; STATUS BAR
; -------------------------------------------------------------------------------

Gui, Add, StatusBar, hwndSBOption
SB_SetParts(150, 150, 150, 150, 215)

; -------------------------------------------------------------------------------
; GUI FONT
; -------------------------------------------------------------------------------

Gui, Font, s8, MS Shell Dlg

; -------------------------------------------------------------------------------
; GUI ADDITIONAL HANDLING
; -------------------------------------------------------------------------------

OnMessage(0x6, "WM_ACTIVATE")
Gui, +hwndhwnd

; -------------------------------------------------------------------------------
; INPUT AND OUTPUT FIELDS
; -------------------------------------------------------------------------------

Gui, Add, Text, x15 y9 w110 h20 vInputTextLabel, Input Text:
Gui, Add, Edit, x15 y29 w487 h310 vInputText gUpdateStats hwndedit,

Edit_EnableZoom(Edit)

Gui, Add, Text, x15 y389 w70 h20 vOutputTextLabel, Output Text:
Gui, Add, Edit, x15 y409 w487 h310 +Wrap vOutputText gUpdateStats hwndedit1,

Edit_EnableZoom(Edit1)

; -------------------------------------------------------------------------------
; QUICK COMMANDS
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x122 y344 w272 h54 vQuickCommandsBox,

Gui Add, Button, x130 y363 w80 h23 gCopyToInput vSendToInputButton hwndOutputToInputOption, Send to Input
Gui Add, Button, x218 y363 w80 h23 gCopyEditedTextToClipboard vCopyOutputButton, Copy Output
Gui Add, Button, x306 y363 w80 h23 gClearAllFields vClearButton hwndClearOption, Clear

; -------------------------------------------------------------------------------
; QUICK COMMANDS AUTO RESULT MOD [INITIALLY HIDDEN]
; -------------------------------------------------------------------------------

Gui, Font, s10  bold, Consolas
Gui Add, Button, x122 y683 w46 h23 gPreviousValue vHistoryPrevious hwndUndoButton, <<
Gui,Add, Button, x352 y683 w46 h23 gNextValue vHistoryNext hwndRedoButton, >>
GuiControl, Hide, HistoryPrevious
GuiControl, Hide, HistoryNext
Gui, Font
Gui, Font, s8, MS Shell Dlg

; -------------------------------------------------------------------------------
; TAB FOR MAIN MODULES
; -------------------------------------------------------------------------------

Gui, Add, Tab3, x512 y5 w290 h717 vModuleGround, Basic|Spaces-Breaks|Remove|Sort-Position

Gui, Tab, Basic

; -------------------------------------------------------------------------------
; FIND
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y32 w272 h95, Find
Gui Add, Edit, x584 y50 w92 h21 vSearchTextGlobal,
Gui Add, CheckBox, x528 y74 w92 h23 vIgnoreCaseFind, Ignore Case
Gui Add, CheckBox, x528 y96 w93 h23 vWholeWordFind, Whole Words
Gui Add, CheckBox, x690 y49 w90 h23 vRegexEnabled, Enable RegEx

Gui Add, Text, x528 y53 w33 h23, Find:
Gui Add, Button, x704 y96 w80 h23 gFindButton, Find

; -------------------------------------------------------------------------------
; SEARCH AND REPLACE
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y133 w272 h127, Search / Replace
Gui Add, Text, x528 y154 w48 h23 +0x200, Search:
Gui Add, Edit, x584 y157 w92 h21 vSearchText,
Gui Add, Text, x528 y178 w48 h23 +0x200, Replace:
Gui Add, Edit, x584 y181 w92 h21 vReplaceText,
Gui Add, CheckBox, x528 y205 w92 h23 vCaseSensitive, Ignore Case
Gui Add, CheckBox, x528 y229 w93 h23 vWholeWord, Whole Words
Gui Add, CheckBox, x690 y156 w90 h23 vRegexMode, Enable RegEx

Gui Add, Button, x704 y229 w80 h23 gReplaceText, Replace

; -------------------------------------------------------------------------------
; SUFFIX AND PREFIX
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y266 w272 h135, Add Suffix / Preffix
Gui Add, Text, x528 y314 w45 h23, Suffix:
Gui Add, Edit, x584 y314 w92 h21 vSuffixBasic,
Gui Add, Text, x528 y290 w45 h23, Prefix:
Gui Add, Edit, x584 y290 w92 h21 vPrefixBasic,
Gui Add, CheckBox, x690 y290 w90 h21 vExcludeEmpty, Exclude Empty
Gui, Add, Checkbox, x690 y314 w90 h21 vExcludeBlank, Exclude Blank

Gui Add, CheckBox, x528 y338 w120 h23 vDeleteEmpty, Delete Empty
Gui, Add, Checkbox, x528 y362 w120 h23 vDeleteBlank, Delete Blank

Gui Add, Button, x704 y370 w80 h23 gAddSuffixPrefix, Add

Gui, Tab, Spaces-Breaks

; -------------------------------------------------------------------------------
; SPACES
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y32 w272 h130, Remove Extra Spaces
Gui Add, CheckBox, x528 y56 w100 h16 vTrimAbove hwndSROption1, Trim Above
Gui Add, CheckBox, x528 y80 w100 h16 vTrimBelow hwndSROption2, Trim Below
Gui Add, CheckBox, x648 y56 w100 h16 vTrimEnd hwndSROption3, Trim Trailing
Gui Add, CheckBox, x648 y80 w100 h16 vTrimStart hwndSROption4, Trim Leading
Gui Add, CheckBox, x648 y104 w108 h16 vRemoveExtra hwndSROption5, Trim Extra Inside
Gui Add, CheckBox, x528 y104 w115 h16 vRemoveExtraWholeText hwndSROption6, Reduce to Single
Gui Add, CheckBox, x528 y128 w100 h16 vRemoveAllSpaces hwndSROption7, Remove All
Gui Add, Button, x704 y128 w80 h25 gRemoveSpaces, Trim/Reduce

; -------------------------------------------------------------------------------
; LINE BREAKS BASIC
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y168 w272 h105, Line Breaks
Gui Add, Radio, x528 y192 w52 h17 vLineBreakOption2 hwndLBBOption1, Keep:
Gui Add, Radio, x528 y216 w45 h17 vLineBreakOption3 hwndLBBOption2, Add:
Gui Add, Radio, x648 y192 w66 h17 vLineBreakOption4 hwndLBBOption3, Remove:
Gui Add, Radio, x648 y216 w80 h17 vLineBreakOption1 hwndLBBOption4, Remove All
Gui Add, Radio, x528 y240 w63 h17 vLineBreakOption5 hwndLBBOption5, Join All
Gui Add, Edit, x584 y192 w50 h20 vCustomBreaks Number, 1
Gui Add, UpDown, vCustomBreaksUpDown,1
Gui Add, Edit, x584 y216 w50 h20 vLineBreakCount Number, 1
Gui Add, UpDown, vLineBreakCountUpDown,1
Gui Add, Edit, x718 y192 w50 h20 vAutoProcessCount Number, 1
Gui Add, UpDown, vAutoProcessCountUpDown,1
Gui Add, Button, x704 y240 w80 h25 gLineBreaksBasic, Process

; -------------------------------------------------------------------------------
; LINE BREAKS EXTENDED
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y277 w272 h176 , Line Breaks Extended
Gui Add, Radio, x528 y299 w54 h18 vOption1 hwndLBEOption1, Before:
Gui Add, Radio, x528 y323 w58 h18 vOption2 hwndLBEOption2, Instead:
Gui Add, Radio, x528 y347 w49 h18 vOption3 hwndLBEOption3, After:
Gui Add, Radio, x528 y371 w65 h18 vOption4 hwndLBEOption4, Replace:

Gui Add, Radio, x528 y395 w110 h18 vOption5, Line Break Every:
Gui Add, Edit, x648 y395 w50 h20 vNumCharacters Number, 1
Gui, Add, UpDown, Range1-1000 vNumCharactersUpDown, 1
Gui Add, Text, x704 y397 w57 h18, characters

Gui Add, Text, x685 y305 w76 h18, This Character
Gui Add, Edit, x674 y320 w97 h20 vSymbol
Gui Add, CheckBox, x684 y344 w90 h18 vCaseInsensitive, Ignore Case
Gui Add, CheckBox, x684 y364 w90 h18 vwholeWordLineBreaks, Whole Word

Gui Add, GroupBox, x664 y295 w117 h92 -Theme
Gui Add, Text, x648 y344 w18 h2 +0x10
Gui Add, Text, x616 y308 w35 h2 +0x10
Gui Add, Text, x648 y308 w5 h77 +0x1 +0x10
Gui Add, Text, x616 y356 w36 h2 +0x10
Gui Add, Text, x616 y332 w36 h2 +0x10
Gui Add, Text, x616 y380 w36 h2 +0x10

Gui Add, Button, x704 y423 w80 h23 gLineBreaksExtended, Process

Gui, Tab, Remove

; -------------------------------------------------------------------------------
; DELETION
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y32 w273 h159, Deletion
Gui Add, Text, x528 y56 w98 h23 vDeletionSharedLabel1, Choose an Option:
Gui Add, Edit, x664 y56 w96 h20 vDeletionEditField1
Gui Add, Text, x528 y80 w121 h23 vDeletionSharedLabel2, From Drop Down List:
Gui Add, Edit, x664 y80 w96 h20 vDeletionEditField2

; Gui Add, Text, x536 y56 w98 h23, Delete Containing:
; Gui Add, Edit, x664 y56 w96 h20 vRemoveText
; Gui Add, Text, x536 y80 w121 h23, Delete NOT Containing:
; Gui Add, Edit, x664 y80 w96 h20 vRemoveNotText
; Gui Add, Text, x536 y112 w76 h23, Delete Before:
; Gui Add, Edit, x664 y112 w96 h20 vRemoveBefore
; Gui Add, Text, x536 y136 w67 h23, Delete After:
; Gui Add, Edit, x664 y136 w96 h20 vRemoveAfter

Gui Add, DDL, x528 y160 w140 h80 vActionType gActionTypeChanged hwndDOption1, Delete Containing|Delete NOT Containing|Delete Before and After|Delete Block
Gui Add, CheckBox, x528 y105 w98 h23 vIsLineContext hwndDOption2, Line by Line
Gui Add, CheckBox, x528 y129 w98 h22 vRemoveSymbol hwndDOption3, Delete Symbol
Gui Add, CheckBox, x664 y129 w86 h23 vCaseInsensitiveDel, Ignore Case
Gui Add, CheckBox, x664 y105 w93 h23 vWholeWordsOnlyDel, Whole Words

Gui Add, Button, x705 y160 w80 h23 gDellActionButton, Delete

; -------------------------------------------------------------------------------
; DUPLICATE LINES
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y198 w273 h123, Duplicate Lines
Gui Add, CheckBox, x528 y218 w82 h23 vIgnoreCase, Ignore Case
Gui Add, CheckBox, x528 y242 w220 h23 vTrimSpaces hwndDLOption1, Consider Trailing and Leading Spaces
Gui Add, CheckBox, x528 y266 w170 h23 vKeepDuplicates hwndDLOption2, Empty Line Instead of Duplicate
Gui, Add, Checkbox, x528 y290 w150 h23 vDeleteFirstDuplicate hwndDLOption3, Don't Keep First Occurrence
Gui Add, Button, x705 y290 w80 h23 gRemoveDuplicates, Remove

; -------------------------------------------------------------------------------
; EMPTY LINES REMOVAL
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y328 w273 h52, Empty Lines
Gui Add, Radio, x528 y347 w51 h23 vDeleteOnlyEmptyLines hwndELOption1, Empty
Gui Add, Radio, x592 y347 w50 h23 vDeleteBothEmptyBlankLines hwndELOption2, Both
Gui Add, Radio, x648 y347 w50 h23 vDeleteOnlyBlankLines hwndELOption3, Blank
Gui Add, Button, x705 y349 w80 h23 gDeleteEmptyBlankLines, Remove

; -------------------------------------------------------------------------------
; SPECIAL CHARACTER REMOVAL
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y387 w273 h52, Special Character Removal

Gui Add, Edit, x528 y409 w170 h20 hwndSCREdit vRemoveCharsField
SetEditFieldPlaceholder(SCREdit, " Enter Characters without Spaces")
Gui Add, Button, x705 y408 w80 h23 gRemoveChars, Remove

Gui, Tab, Sort-Position

; -------------------------------------------------------------------------------
; NUMBERING
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y32 w273 h175, Numbering

Gui Add, Radio, x528 y48 w70 h20 vNumberingMode1, Numbers
Gui Add, Radio, x712 y48 w70 h20 vNumberingMode3, Letters
Gui Add, Radio, x600 y48 w110 h20 vNumberingMode2, Roman Numerals

Gui Add, Text, x528 y80 w63 h23, Start with:
Gui Add, Edit, x596 y78 w25 h20 vStartChar

Gui Add, Text, x528 y128 w38 h23, Suffix:
Gui Add, Edit, x576 y126 w45 h20 vPrefix

Gui Add, Text, x528 y104 w41 h23, Prefix:
Gui Add, Edit, x576 y102 w45 h20 vSuffix, %A_Space%

; Gui Add, CheckBox, x632 y101 w133 h23 vSkipEmptyLines, Delete Empty Lines
; Gui Add, CheckBox, x632 y77 w134 h23 vKeepEmptyLines, Exclude Empty Lines

; Gui Add, GroupBox, x627 y63 w156 h34 ; Optional

Gui Add, Text, x632 y72 w47 h23 +0x200, Exclude
Gui Add, CheckBox, x736 y72 w45 h23 vExcludeBlankLines hwndNExcludeBlank, Blank
Gui Add, CheckBox, x680 y72 w45 h23 vExcludeEmptyLines hwndNExcludeEmpty, Empty

; Gui Add, GroupBox, x627 y92 w156 h34 ; Optional

Gui Add, Text, x632 y100 w47 h23 +0x200, Delete
Gui Add, CheckBox, x680 y100 w50 h23 vDeleteEmptyLines hwndNDeleteEmpty, Empty
Gui Add, CheckBox, x736 y100 w45 h23 vDeleteBlankLines hwndNDeleteBlank, Blank

Gui Add, CheckBox, x632 y127 w149 h20 vDeleteStartNumbers, Strip Leading Numbers
Gui Add, CheckBox, x632 y151 w142 h20 vUppercase, Lower Case Numbering

Gui Add, CheckBox, x528 y176 w95 h23 vAddDot, Dot by Default
Gui Add, CheckBox, x528 y152 w92 h23 vLeadingZeros, Leading Zeros

Gui Add, Button, x704 y176 w80 h23 gNumberText, Number

; -------------------------------------------------------------------------------
; CASE CHANGING
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y213 w273 h73, Case Changing
Gui Add, Radio, x528 y229 w70 h23 vCaseUpper, Upper
Gui Add, Radio, x600 y229 w66 h23 vCaseLower, Lower
Gui Add, Radio, x528 y253 w68 h23 vCaseTitled, Title
Gui Add, Radio, x600 y253 w70 h23 vCaseSentence, Sentence
Gui Add, Button, x704 y253 w80 h23 gConvertText, Change

; -------------------------------------------------------------------------------
; SORTING
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y292 w273 h127, Sorting
Gui Add, Radio, x528 y308 w88 h23 vAlph, Alphabetical

Gui Add, Radio, x528 y332 w90 h23 vLineLength, Line Length

Gui Add, Radio, x528 y380 w93 h23 vFlip, Upside Down
Gui Add, Radio, x528 y356 w90 h23 vNatural, Natural

Gui Add, CheckBox, x624 y308 w135 h23 hwndSORTOption1 vReverseSorting, Reverse Sorting
Gui Add, CheckBox, x624 y332 w135 h23 hwndSORTOption2 vConsiderCaseSorting, Case Sensitive

Gui Add, Button, x704 y388 w80 h23 gSortStrings, Sort

; -------------------------------------------------------------------------------
; ALIGNING
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y425 w132 h170, Aligning
Gui Add, Radio, x528 y442 w40 h23 vLeft, Left
Gui Add, Radio, x528 y465 w54 h23 vCenter, Center
Gui Add, Radio, x528 y489 w51 h23 vRight, Right
Gui Add, Text, x528 y516 w60 h17, Line Length:
Gui Add, Edit, x592 y513 w50 h19 vLineLengthAlligning Number, 1
Gui Add, UpDown, Range1-1000 vLineLengthUpDown
Gui Add, Text, x528 y538 w56 h23, Fill with:
Gui Add, Edit, x592 y537 w50 h19 vFillChar,
Gui Add, Button, x563 y563 w80 h23 gAllign, Align

; -------------------------------------------------------------------------------
; PADDING
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x661 y425 w132 h170, Padding
Gui Add, Radio, x669 y441 w40 h23 vPadLeft, Left
Gui Add, Radio, x669 y489 w46 h23 vPadBoth, Both
Gui Add, Radio, x669 y465 w51 h23 vPadRight, Right
Gui Add, Text, x669 y516 w62 h19, Pad Length:
Gui Add, Edit, x733 y513 w50 h20 vPaddingSize Number, 1
Gui Add, UpDown, Range1-1000 vPaddingSizeUpDown
Gui Add, Text, x669 y538 w54 h23, Pad with:
Gui Add, Edit, x733 y537 w50 h19 vPaddingChar,
Gui Add, Button, x704 y563 w80 h23 gAddPadding, Pad

; -------------------------------------------------------------------------------
; LINE REPEAT
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y599 w272 h109, Line Repeat
Gui Add, Text, x655 y615 w80 h23 +0x200, Repeat Count:
Gui Add, Edit, x733 y619 w50 h20 vRepeatCount hwndLROption1 Number, 1
Gui Add, UpDown, Range1-1000
Gui Add, Radio, x625 y669 w70 h23 vLineModeAll hwndLROption2, All Lines
Gui Add, Radio, x625 y645 w96 h23 vLineModeSpecific hwndLROption3, Specific Line(s):
Gui Add, Edit, x733 y648 w51 h21 hwndTwo vSpecificLines,
SetEditFieldPlaceholder(Two, "1-3, 5")

Gui Add, Text, x528 y615 w59 h23 +0x200, Separator:
Gui Add, Edit, x592 y619 w48 h19 vSeparatorText hwndLROption4,
Gui Add, Radio, x528 y645 w82 h23 vRepeatModeSingleLine hwndLROption5, Single Line
Gui Add, Radio, x528 y669 w71 h23 vRepeatModeNewLine hwndLROption6, New Line

Gui Add, Button, x704 y676 w80 h23 gRepeatText, Repeat

Gui, Tab

; -------------------------------------------------------------------------------
; EDIT FIELD FOR COLUMN MODE [INITIALLY HIDDEN]
; -------------------------------------------------------------------------------

Gui, Add, Text, x264 y9 w110 h20 vColumnTwoLabel, Column 2:
Gui Add, Edit, x264 y29 w239 h310 vSecondColumn gUpdateStats hwndSColumn

Edit_EnableZoom(SColumn)
GuiControl, Hide, SecondColumn
GuiControl, Hide, ColumnTwoLabel

; -------------------------------------------------------------------------------
; TAB FOR ADDITIONAL MODULES [INITIALLY HIDDEN]
; -------------------------------------------------------------------------------

Gui, Add, Tab3, x512 y5 w290 h717 vColumnGround, Concatenate Text
GuiControl, Hide, ColumnGround

; -------------------------------------------------------------------------------
; CONCATENATE [INITIALLY HIDDEN]
; -------------------------------------------------------------------------------

Gui Add, GroupBox, x520 y32 w272 h48, Concatenate
Gui Add, Text, x528 y53 w60 h23, Separator:
Gui Add, Edit, x592 y50 w92 h21 vColumnSeparator
Gui Add, Button, x704 y49 w80 h23 gConcatenateColumns, Process

; -------------------------------------------------------------------------------
; SHOWING THE GUI
; -------------------------------------------------------------------------------

Gui, Show, w814 h750, Realm

Gosub, InlineHelp
Gosub, UpdateStats
return

; -------------------------------------------------------------------------------
; ----------------------------- FUNCTIONS & LABELS ------------------------------
; -------------------------------------------------------------------------------

; -------------------------------------------------------------------------------
; STATUS BAR: INPUT \ OUTPUT STATS
; -------------------------------------------------------------------------------

UpdateStats:
    Gui, Submit, NoHide
    UpdateStatusBar(control)
    Gosub, SaveValue

    ; Get text from both input boxes
    text1 := InputText
    text2 := OutputText
    text3 := SecondColumn

    ; Process first input box
    chars1 := StrLen(text1)
    words1 := CountWords(text1)
    lines1 := CountLines(text1)
    sentences1 := CountSentences(text1)

    ; Process second input box
    chars2 := StrLen(text2)
    words2 := CountWords(text2)
    lines2 := CountLines(text2)
    sentences2 := CountSentences(text2)

    chars3 := StrLen(text3)
    words3 := CountWords(text3)
    lines3 := CountLines(text3)
    sentences3 := CountSentences(text3)

    ; Update status bar
    if (AutoInput = 0 && ColumnView = 0) {
        SB_SetText("Chars: " chars1 " | " chars2, 1)
        SB_SetText("Words: " words1 " | " words2, 2)
        SB_SetText("Lines: " lines1 " | " lines2, 3)
        SB_SetText("Sentences: " sentences1 " | " sentences2, 4)
    }
    else if (AutoInput = 1) {
        SB_SetText("Chars: " chars1, 1)
        SB_SetText("Words: " words1, 2)
        SB_SetText("Lines: " lines1, 3)
        SB_SetText("Sentences: " sentences1, 4)
    }
    else if (ColumnView = 1) {
        SB_SetText("Chars: " chars1 " | " chars3 " | " chars2, 1)
        SB_SetText("Words: " words1 " | " words3 " | " words2, 2)
        SB_SetText("Lines: " lines1 " | " lines3 " | " lines2, 3)
        SB_SetText("Sentences: " sentences1 " | " sentences3 " | " sentences2, 4)
    }
    Sleep 50
return

; -------------------------------------------------------------------------------
; STATUS BAR
; -------------------------------------------------------------------------------
; SELECTED TEXT STATS
; -------------------

UpdateStatusBar(control){
    ; Get the current focused control
    ControlGetFocus, focusedControl, ahk_class AutoHotkeyGUI

    ; Retrieve the selected text (if any) from the focused Edit control
    selectedText := ""
    ControlGet, selectedText, Selected,, %focusedControl%, ahk_class AutoHotkeyGUI

    ; If text is selected, count the lines, characters, and words
    if (selectedText != "")
    {
        ; Count number of lines by splitting the text at newline characters
        lines := 0
        Loop, Parse, selectedText, `n, `r
        {
            lines++
        }

        ; Count number of characters (excluding line breaks)
        chars := StrLen(selectedText) - (lines - 1) ; Subtracting line breaks

        ; Count words
        words := CountWords(selectedText)

        ; Update the status bar with the new information
        SB_SetText("Selected: " chars " | " lines " | " words, 5)
    }
    else
    {
        ; If no text is selected, reset to 0
        SB_SetText("Selected: 0 | 0 | 0", 5)
    }
}

; -------------------------------------------------------------------------------
; STATUS BAR
; -------------------------------------------------------------------------------
; GET SELECTED TEXT STATS WHEN MOUSE IS HELD DOWN
; -----------------------------------------------

; CheckMouseOverControls() {
;     ; Check if the mouse button is held down
;     while GetKeyState("LButton", "P")
;     {
;         ; Get the current mouse position
;         MouseGetPos, mouseX, mouseY, hwnd, control, 1

;         ; Check if the control is one of the desired Edit controls
;         if (control in editControls) && (control != "SysTabControl321")
;         {
;             UpdateStatusBar(control)
;         }

;         ; Sleep for a short duration to avoid high CPU usage
;         Sleep, 50
;         UpdateStatusBar(control) ; Added this little thing for accurate Update
;     }
; }

; -------------------------------------------------------------------------------
; STATUS BAR
; -------------------------------------------------------------------------------
; INPUT \ OUTPUT FIELDS: WORDS, LINES AND SENTENCES COUNT
; -------------------------------------------------------

CountWords(text) {
    text := Trim(text)
    if (text = "")
        return 0

    ; Replace multiple consecutive spaces and line breaks with single space
    text := RegExReplace(text, "[\s\r\n]+", " ")

    ; Remove leading and trailing spaces
    text := Trim(text)

    ; If text is empty after trimming, return 0
    if (text = "")
        return 0

    ; Count words by counting spaces and adding 1
    StringReplace, text, text, %A_Space%, %A_Space%, UseErrorLevel
    return ErrorLevel + 1
}

; CountLines(text) {
;     StringReplace, text, text, `n, `n, UseErrorLevel
;     return ErrorLevel + 1
; }

CountLines(text) {
    return StrSplit(text, "`n").Length()
}

CountSentences(text) {
    ; Count sentences by counting .!? followed by space or end of line
    count := 0
    pos := 1

    while (pos := RegExMatch(text, "[.!?](\s|$)", match, pos)) {
        count++
        pos += StrLen(match)
    }

    return count ? count : 0
}

; -------------------------------------------------------------------------------
; CHECK IF MOUSE IS OVER CERTAIN CONTROL
; -------------------------------------------------------------------------------

MouseIsOver(Control) {
    MouseGetPos,,, Win, Ctrl
    return (Ctrl = Control)
}

; -------------------------------------------------------------------------------
; REMOVES INITIAL FOCUS FROM THE GUI [AUTHOR: teadrinker]
; -------------------------------------------------------------------------------

WM_ACTIVATE(wp, lp, msg, hwnd) {
    static WA_ACTIVE := 1
    if (wp = WA_ACTIVE)
        GuiControl, %hwnd%: Focus, Static1
}

; -------------------------------------------------------------------------------
; TOGLE STATUS BAR VISIBILITY ON AND OFF
; -------------------------------------------------------------------------------

ToggleStatusBar() {
    static isVisible := true
    if (isVisible) {
        GuiControl, Hide, msctls_statusbar321
        isVisible := false
        Menu, ViewMenu, Uncheck, Status Bar
    } else {
        GuiControl, Show, msctls_statusbar321
        isVisible := true
        Menu, ViewMenu, Check, Status Bar
    }
}

; -------------------------------------------------------------------------------
; SET WINDOW ALWAYS ON TOP
; -------------------------------------------------------------------------------

ToggleAlwaysOnTop() {
    global AlwaysOnTop
    if (AlwaysOnTop = 0) {
        WinSet, AlwaysOnTop, On, A
        Menu, SettingsMenu, Check, Always On Top
        AlwaysOnTop := 1
    }
    else {
        WinSet, AlwaysOnTop, Off, A
        Menu, SettingsMenu, Uncheck, Always On Top
        AlwaysOnTop := 0
    }
}

; -------------------------------------------------------------------------------
; SET AUTO RESULT FOR INPUT FIELD
; -------------------------------------------------------------------------------

ToggleAutoInput() {
    global AutoInput
    global ColumnView
    if (AutoInput = 0 && ColumnView = 0) {
        Menu, SettingsMenu, Check, Auto Result
        GuiControl, Hide, OutputText,
        GuiControl, Hide, OutputTextLabel
        GuiControl, Hide, SendToInputButton
        GuiControl, Move, InputText, h631
        GuiControl, Move, QuickCommandsBox, x112 y664 w292
        GuiControl, Move, CopyOutputButton, x174 y683
        GuiControl, Move, ClearButton, x262 y683
        GuiControl, Show, HistoryPrevious
        GuiControl, Show, HistoryNext
        AutoInput := 1
        Gosub, UpdateStats
    }
    else if (AutoInput = 1 && ColumnView = 0) {
        Menu, SettingsMenu, Uncheck, Auto Result
        GuiControl, Show, OutputText,
        GuiControl, Show, OutputTextLabel
        GuiControl, Show, SendToInputButton
        GuiControl, Move, InputText, h310
        GuiControl, Move, QuickCommandsBox, x122 y344 w272 h54
        GuiControl, Move, CopyOutputButton, x218 y363 w80 h23
        GuiControl, Move, ClearButton, x306 y363 w80 h23
        GuiControl, Hide, HistoryPrevious
        GuiControl, Hide, HistoryNext
        AutoInput := 0
        Gosub, UpdateStats
    }
    else if (ColumnView = 1 && AutoInput = 0) {
        Tooltip, Disable Column Mode first.
        SetTimer, RemoveToolTip, -2000
    }
}

; -------------------------------------------------------------------------------
; TOGGLE COLUMN MODE
; -------------------------------------------------------------------------------

ColumnMod() {
    global ColumnView
    global AutoInput
    if (ColumnView = 0 && AutoInput = 0) {
        GuiControl, Hide, ModuleGround
        GuiControl, Show, ColumnGround
        GuiControl, Show, SecondColumn
        GuiControl, Show, ColumnTwoLabel
        GuiControl, Move, InputText, w239 h310
        GuiControl, Text, InputTextLabel, Column 1:
        Menu, SettingsMenu, Check, Column Mode
        ColumnView := 1
        Gosub, UpdateStats

    }
    else if (ColumnView = 1 && AutoInput = 0) {
        GuiControl, Hide, ColumnGround
        GuiControl, Hide, SecondColumn
        GuiControl, Hide, ColumnTwoLabel
        GuiControl, Show, ModuleGround
        GuiControl, Move, InputText, w487 h310
        GuiControl, Text, InputTextLabel, Input Text:
        Menu, SettingsMenu, Uncheck, Column Mode
        ColumnView := 0
        Gosub, UpdateStats
    }
    else if (AutoInput = 1 && ColumnView = 0) {
        Tooltip, Disable Auto Result first.
        SetTimer, RemoveToolTip, -2000
    }
}

; -------------------------------------------------------------------------------
; SET WINDOW TRANSPARENCY LEVEL
; -------------------------------------------------------------------------------

SetTransparency() {
    ; Array of transparency percentages
    transparencyOptions := ["0% (Opaque)", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%"]

    ; Uncheck all menu items
    for index, option in transparencyOptions {
        Menu, TransparencyMenu, UnCheck, %option%
    }

    ; Check the selected menu item
    Menu, TransparencyMenu, Check, %A_ThisMenuItem%

    ; Mapping of transparency percentages to actual transparency values
    transparencyMap := {"90%": 25, "80%": 51, "70%": 76, "60%": 102, "50%": 127, "40%": 153, "30%": 178, "20%": 204, "10%": 229, "0% (Opaque)": "OFF"}

    transparencyValue := transparencyMap[A_ThisMenuItem]

    WinSet, Transparent, %transparencyValue%, A
}

; -------------------------------------------------------------------------------
; LOAD FILE
; -------------------------------------------------------------------------------

SelectFile:
    Gui, +OwnDialogs ; Highest Priority
    FileSelectFile, SelectedFile, 3,, Open, Text Files (*.txt)
    if (SelectedFile) {
        FileRead, FileContent, %SelectedFile%
        GuiControl,, InputText, %FileContent%
        Gosub, UpdateStats
    }
return

; -------------------------------------------------------------------------------
; SAVE FILE
; -------------------------------------------------------------------------------

FileSave:
    Gui, Submit, NoHide

    ; If no previous save path exists, prompt for file selection
    if (CurrentSavePath = "") {
        Gui, +OwnDialogs ; Highest Priority
        FileSelectFile, SavePath, S16, output.txt, Save Output Contents, Text Files (*.txt)
        if (SavePath != "") {
            CurrentSavePath := SavePath
        } else {
            return ; Cancel if no file selected
        }
    }

    FileDelete, %CurrentSavePath%
    FileAppend, %OutputText%, %CurrentSavePath%
    Tooltip, Contents saved to %CurrentSavePath%
    SetTimer, RemoveToolTip, -2000
return

; -------------------------------------------------------------------------------
; SAVE FILE AS
; -------------------------------------------------------------------------------

FileSaveAs:
    Gui, Submit, NoHide
    Gui, +OwnDialogs ; Highest Priority
    FileSelectFile, SavePath, S16, output.txt, Save Output Contents, Text Files (*.txt)
    if (SavePath != "") {
        CurrentSavePath := SavePath
        FileDelete, %CurrentSavePath%
        FileAppend, %OutputText%, %CurrentSavePath%
        Tooltip, Contents saved to %CurrentSavePath%
        SetTimer, RemoveToolTip, -2000
    }
return

; -------------------------------------------------------------------------------
; COPY TO INPUT
; -------------------------------------------------------------------------------

CopyToInput:
    GuiControlGet, OutputText

    if (OutputText = "" || Trim(OutputText) = "" || RegExMatch(OutputText, "^[\s\r\n]*$")) {
        return
    }

    GuiControl,, InputText, %OutputText%
    GuiControl,, OutputText,
    Gosub, UpdateStats
Return

; -------------------------------------------------------------------------------
; COPY TO CLIPBOARD
; -------------------------------------------------------------------------------

CopyEditedTextToClipboard:
    GuiControlGet, OutputText,, OutputText
    Clipboard := OutputText
    ToolTip, Copied: %Clipboard%
    SetTimer, RemoveToolTip, -1500
Return

; -------------------------------------------------------------------------------
; CLEAR ALL FIELDS
; -------------------------------------------------------------------------------

ClearAllFields:
    global AutoInput
    global ColumnView
    GuiControl,, InputText
    GuiControl,, OutputText
    GuiControl,, SearchTextGlobal
    GuiControl,, SearchText
    GuiControl,, ReplaceText
    GuiControl,, SuffixBasic
    GuiControl,, PrefixBasic
    GuiControl,, CustomBreaks, 1
    GuiControl,, LineBreakCount, 1
    GuiControl,, AutoProcessCount, 1
    GuiControl,, NumCharacters, 1
    GuiControl,, Symbol
    GuiControl,, DeletionEditField1
    GuiControl,, DeletionEditField2
    GuiControl,, RemoveCharsField
    GuiControl,, StartChar
    GuiControl,, Prefix
    GuiControl,, Suffix
    GuiControl,, LineLengthAlligning, 1
    GuiControl,, FillChar
    GuiControl,, PaddingSize, 1
    GuiControl,, PaddingChar
    GuiControl,, RepeatCount, 1
    GuiControl,, SpecificLines, 1
    GuiControl,, SeparatorText
    GuiControl,, ColumnSeparator
    GuiControl,, SecondColumn

    if (AutoInput = 0 && ColumnView = 0) {
        ; Reset status bar to zero or empty
        SB_SetText("Chars: 0 | 0", 1)
        SB_SetText("Words: 0 | 0", 2)
        SB_SetText("Lines: 0 | 0", 3)
        SB_SetText("Sentences: 0 | 0", 4)
    }
    else if (AutoInput = 1) {
        SB_SetText("Chars: 0", 1)
        SB_SetText("Words: 0", 2)
        SB_SetText("Lines: 0", 3)
        SB_SetText("Sentences: 0", 4)
    }
    else if (ColumnView = 1) {
        SB_SetText("Chars: 0 | 0 | 0", 1)
        SB_SetText("Words: 0 | 0 | 0", 2)
        SB_SetText("Lines: 0 | 0 | 0", 3)
        SB_SetText("Sentences: 0 | 0 | 0", 4)
    }
Return

; -------------------------------------------------------------------------------
; HANDLE PLACEHOLDERS [AUTHOR: just me]
; -------------------------------------------------------------------------------

SetEditFieldPlaceholder(HWND, Cue)
{
    Static EM_SETCUEBANNER := (0x1500 + 1)
    Return DllCall("User32.dll\SendMessageW", "Ptr", HWND, "Uint", EM_SETCUEBANNER, "Ptr", True, "WStr", Cue)
}

; -------------------------------------------------------------------------------
; ZOOM IN\OUT\RESET + ADDITIONAL FUNCTIONS [AUTHOR: jballi] [Win10+]
; -------------------------------------------------------------------------------

Edit_EnableZoom(hEdit,p_Enable:=True)
{
    Static ES_EX_ZOOMABLE:=0x10
    Return Edit_SetExtendedStyle(hEdit,ES_EX_ZOOMABLE,p_Enable ? ES_EX_ZOOMABLE:0)
}

Edit_SetExtendedStyle(hEdit,p_Mask,p_ExStyle)
{
    Static Dummy69574821
        ,S_OK:=0x0
        ,EM_SETEXTENDEDSTYLE:=0x150A

    SendMessage EM_SETEXTENDEDSTYLE,p_Mask,p_ExStyle,,ahk_id %hEdit%
    Return ErrorLevel="FAIL" ? False:ErrorLevel=S_OK or ErrorLevel=0x10 ? True:False
}

Edit_GetZoom(hEdit,ByRef r_Numerator:="",ByRef r_Denominator:="",ByRef r_ZoomPct:="")
{
    Static EM_GETZOOM:=0x4E0  ;-- WM_USER+224

    ;-- Get Zoom
    r_Numerator:=r_Denominator:=0  ;-- Initialize jic SendMessage fails
    DllCall("SendMessage" . (A_IsUnicode ? "W":"A")
        ,"UPtr",hEdit
        ,"UInt",EM_GETZOOM
        ,"UInt*",r_Numerator
        ,"UInt*",r_Denominator)

    ;-- Populate output variables and return object
    r_ZoomPct:=r_Denominator ? Round((r_Numerator/r_Denominator)*100):0
    Return {Numerator:r_Numerator,Denominator:r_Denominator,ZoomPct:r_ZoomPct}
}

Edit_ZoomIn(hEdit,p_IncrementPct:=10,p_MaxZoomPct:=9999)
{
    Static EM_SETZOOM:=0x4E1  ;-- WM_USER+225

    ;-- Get the current zoom factor
    ;   Bounce if there is no zoom percent (Error or zoom not enabled)
    Edit_GetZoom(hEdit,Numerator,Denominator,ZoomPct)
    if (ZoomPct=0)
        Return False

    ;-- If needed, reset values
    if (Numerator=Denominator)
        Numerator:=Denominator:=100

    ;-- Zoom in by the specified percentage
    Numerator:=Min(p_MaxZoomPct,Numerator+p_IncrementPct)

    ;-- Set zoom
    SendMessage EM_SETZOOM,Numerator,100,,ahk_id %hEdit%
    Return ErrorLevel="FAIL" ? False:ErrorLevel
}

Edit_ZoomOut(hEdit,p_DecrementPct:=10,p_MinZoomPct:=10)
{
    Static EM_SETZOOM:=0x4E1  ;-- WM_USER+225

    ;-- Get the current zoom factor
    ;   Bounce if there is no zoom percent (Error or zoomable not enabled)
    Edit_GetZoom(hEdit,Numerator,Denominator,ZoomPct)
    if (ZoomPct=0)
        Return False

    ;-- If needed, reset values
    if (Numerator=Denominator)
        Numerator:=Denominator:=100

    ;-- Zoom out
    Numerator:=Max(p_MinZoomPct,Numerator-p_DecrementPct)

    ;-- Set zoom
    SendMessage EM_SETZOOM,Numerator,100,,ahk_id %hEdit%
    Return ErrorLevel="FAIL" ? False:ErrorLevel
}

Edit_ZoomReset(hEdit)
{
    Static EM_SETZOOM:=0x4E1  ;-- WM_USER+225
    SendMessage EM_SETZOOM,100,100,,ahk_id %hEdit%
    Return ErrorLevel="FAIL" ? False:ErrorLevel
}

ResetFont:
    Edit_ZoomReset(Edit)
    Edit_ZoomReset(Edit1)
    Edit_ZoomReset(SColumn)
return

ZoomIn:
    Edit_ZoomIn(Edit)
    Edit_ZoomIn(Edit1)
    Edit_ZoomIn(SColumn)
return

ZoomOut:
    Edit_ZoomOut(Edit)
    Edit_ZoomOut(Edit1)
    Edit_ZoomOut(SColumn)
return

; -------------------------------------------------------------------------------
; FONT [AUTHOR: maestrith]
; -------------------------------------------------------------------------------

; https://www.autohotkey.com/board/topic/94083-ahk-11-font-and-color-dialogs/
Font:
    if !font:=Dlg_Font(name,style,hwnd) ;shows the user the font selection dialog
        ;to get information from the style object use ( bold:=style.bold ) or ( underline:=style.underline )...
        return
    Gui,font,% "c" RGB(style.color)
    GuiControl,font,InputText
    GuiControl,font,OutputText
    GuiControl,font,SecondColumn
    SendMessage,0x30,font,1,,ahk_id%Edit%
    SendMessage,0x30,font,1,,ahk_id%Edit1%
    SendMessage,0x30,font,1,,ahk_id%SColumn%
return
;to get any of the style return values : value:=style.bold will get you the bold value and so on
Dlg_Font(ByRef Name,ByRef Style,hwnd="",effects=1){
    static logfont
    VarSetCapacity(logfont,60),LogPixels:=DllCall("GetDeviceCaps","uint",DllCall("GetDC","uint",0),"uint",90),Effects:=0x041+(Effects?0x100:0)
    for a,b in fontval:={16:style.bold?700:400,20:style.italic,21:style.underline,22:style.strikeout,0:style.size?Floor(style.size*logpixels/72):16}
        NumPut(b,logfont,a)
    cap:=VarSetCapacity(choosefont,A_PtrSize=8?103:60,0)
    NumPut(hwnd,choosefont,A_PtrSize)
    for index,value in [[cap,0,"Uint"],[&logfont,A_PtrSize=8?24:12,"Uptr"],[effects,A_PtrSize=8?36:20,"Uint"],[style.color,A_PtrSize=4?6*A_PtrSize:5*A_PtrSize,"Uint"]]
        NumPut(value.1,choosefont,value.2,value.3)
    if (A_PtrSize=8)
        strput(name,&logfont+28),r:=DllCall("comdlg32\ChooseFont","uptr",&CHOOSEFONT,"cdecl"),name:=strget(&logfont+28)
    else
        strput(name,&logfont+28,32,"utf-8"),r:=DllCall("comdlg32\ChooseFontA","uptr",&CHOOSEFONT,"cdecl"),name:=strget(&logfont+28,32,"utf-8")
    if !r
        return 0
    for a,b in {bold:16,italic:20,underline:21,strikeout:22}
        style[a]:=NumGet(logfont,b,"UChar")
    style.bold:=style.bold<188?0:1
    style.color:=NumGet(choosefont,A_PtrSize=4?6*A_PtrSize:5*A_PtrSize)
    style.size:=NumGet(CHOOSEFONT,A_PtrSize=8?32:16,"UChar")//10
    ;charset:=NumGet(logfont,23,"UChr")
    return DllCall("CreateFontIndirect",uptr,&logfont,"cdecl")
}
rgb(c){
    setformat,IntegerFast,H
    c:=(c&255)<<16|(c&65280)|(c>>16),c:=SubStr(c,1)
    SetFormat, integerfast,D
    return c
}

; -------------------------------------------------------------------------------
; GETFONT [AUTHOR: teadrinker]
; -------------------------------------------------------------------------------

; https://www.autohotkey.com/boards/viewtopic.php?t=161

GetFont(hWnd) {
    static WM_GETFONT := 0x31

    hFont := DllCall("SendMessage", "Ptr", hWnd, "UInt", WM_GETFONT, "Ptr", 0, "Ptr", 0, "Ptr")
    if !hFont {
        Gui, %hWnd%: Add, Text, xp yp wp hp Hidden hwndhText
        hFont := DllCall("SendMessage", "Ptr", hText, "UInt", WM_GETFONT, "Ptr", 0, "Ptr", 0, "Ptr")
        DllCall("DestroyWindow", "Ptr", hText)
    }
    sizeLF := DllCall("GetObject", "Ptr", hFont, "Int", 0, "Ptr", 0)
    VarSetCapacity(LOGFONT, sizeLF, 0)
    DllCall("GetObject", "Ptr", hFont, "Int", sizeLF, "Ptr", &LOGFONT)

    Size      :=-NumGet(LOGFONT, "Int")*72//A_ScreenDPI
    Weight    := NumGet(LOGFONT, 16, "Int")
    Italic    := NumGet(LOGFONT, 20, "Char")
    Underline := NumGet(LOGFONT, 21, "Char")
    Strike    := NumGet(LOGFONT, 22, "Char")
    Quality   := NumGet(LOGFONT, 26, "Char")
    FaceName  := StrGet(&LOGFONT + 28)

    res := {}
    for k, v in ["Size", "Weight", "Italic", "Underline", "Strike", "Quality", "FaceName"]
        res[v] := %v%
    Return res
}

; -------------------------------------------------------------------------------
; ZOOMFONT (Provides zooming to users that are not on Win10)
; -------------------------------------------------------------------------------

ZoomFont(Control, Direction) {
    static FontData := {} ; Store font info for all controls

    ; Get control handle and current font info
    GuiControlGet, hControl, HWND, %Control%
    fontInfo := GetFont(hControl) ; Using your GetFont() function

    ; If font name changed, reset stored data
    if (FontData.HasKey(Control) && FontData[Control].Name != fontInfo.FaceName) {
        FontData.Delete(Control)  ; Clear old data
    }

    ; Initialize static variables if they don't exist
    if !FontData.HasKey(Control) {
        FontData[Control] := {Name: fontInfo.FaceName, Size: fontInfo.Size}
    }

    ; Update the size based on direction
    newSize := FontData[Control].Size + Direction
    newSize := newSize < 6 ? 6 : newSize > 72 ? 72 : newSize
    FontData[Control].Size := newSize

    ; Reapply font with new size but original face
    Gui, Font, s%newSize%, % FontData[Control].Name
    GuiControl, Font, %Control%
}

; -------------------------------------------------------------------------------
; CHANGE HISTORY
; -------------------------------------------------------------------------------

SaveValue:
    Gui, Submit, NoHide
    if (InputText != "" || InputText = "") {
        CaretIndex := Edit_GetCaretIndex(Edit) ; Get current caret index
        SavedValues.Push(InputText)             ; Save the input text
        CaretIndices.Push(CaretIndex)           ; Save the caret index
        CurrentIndex := SavedValues.Length()     ; Update current index
    }
return

; Navigate to the previous saved value
PreviousValue:
    GuiControl, Focus, InputText
    if (SavedValues.Length() > 0 && CurrentIndex > 1) {
        CurrentIndex--
        GuiControl,, InputText, % SavedValues[CurrentIndex]
        Edit_SetCaretIndex(Edit, CaretIndices[CurrentIndex]) ; Restore caret index
    }
return

; Navigate to the next saved value
NextValue:
    GuiControl, Focus, InputText
    if (SavedValues.Length() > 0 && CurrentIndex < SavedValues.Length()) {
        CurrentIndex++
        GuiControl,, InputText, % SavedValues[CurrentIndex]
        Edit_SetCaretIndex(Edit, CaretIndices[CurrentIndex]) ; Restore caret index
    }
return

; -------------------------------------------------------------------------------
; CARET HANDLE [AUTHOR: jballi]
; -------------------------------------------------------------------------------

Edit_GetCaretIndex(hEdit)
{
    Static EM_GETCARETINDEX:=0x1512  ;-- ECM_FIRST+18
    SendMessage EM_GETCARETINDEX,0,0,,ahk_id %hEdit%
    Return ErrorLevel="FAIL" ? False:ErrorLevel
}

Edit_SetCaretIndex(hEdit,p_CaretIndex)
{
    Static EM_SETCARETINDEX:=0x1511  ;-- ECM_FIRST+17
    SendMessage EM_SETCARETINDEX,p_CaretIndex,0,,ahk_id %hEdit%
    Return ErrorLevel:="FAIL" ? False:True
}

; -------------------------------------------------------------------------------
; HELP TOOLTIP TOGGLE
; -------------------------------------------------------------------------------

HelpTooltips:
    global InlineTooltip
    if (InlineTooltip = 0) {
        Menu, HelpMenu, Check, Tooltips
        InlineTooltip := 1
        Help.Suspend(False)
        Tooltip, Inline help is enabled. Hovering over certain`ncontrols will display Help Tooltips.
        SetTimer, RemoveToolTip, -4000
    }
    else {

        Menu, HelpMenu, Uncheck, Tooltips
        InlineTooltip := 0
        Help.Suspend(True)
        Tooltip, Inline help is disabled. Help Tooltips`nwont be shown.
        SetTimer, RemoveToolTip, -3000
    }
return

; -------------------------------------------------------------------------------
; HELP TOOLTIP HANDLE [AUTHOR: just me]
; -------------------------------------------------------------------------------

Class GuiControlTips {

    HTIP := 0
    HGUI := 0
    CTRL := {}

    __New(HGUI) {
        Static CLASS_TOOLTIP      := "tooltips_class32"
        Static CW_USEDEFAULT      := 0x80000000
        Static TTM_SETMAXTIPWIDTH := 0x0418
        Static TTM_SETMARGIN      := 0x041A
        Static WS_EX_TOPMOST      := 0x00000008
        Static WS_STYLES          := 0x80000002 ; WS_POPUP | TTS_NOPREFIX

        HTIP := DllCall("User32.dll\CreateWindowEx", "UInt", WS_EX_TOPMOST, "Str", CLASS_TOOLTIP, "Ptr", 0
            , "UInt", WS_STYLES
            , "Int", CW_USEDEFAULT, "Int", CW_USEDEFAULT, "Int", CW_USEDEFAULT, "Int", CW_USEDEFAULT
            , "Ptr", HGUI, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr")
        If ((ErrorLevel) || !(HTIP))
            Return False

        DllCall("User32.dll\SendMessage", "Ptr", HTIP, "Int", TTM_SETMAXTIPWIDTH, "Ptr", 0, "Ptr", 0)

        This.HTIP := HTIP
        This.HGUI := HGUI
        If (DllCall("Kernel32.dll\GetVersion", "UInt") & 0xFF) < 6
            This.Attach(HGUI, "")
    }

    __Delete() {
        If (This.HTIP) {
            DllCall("User32.dll\DestroyWindow", "Ptr", This.HTIP)
        }
    }

    SetToolInfo(ByRef TOOLINFO, HCTRL, TipTextAddr, CenterTip = 0) {
        Static TTF_IDISHWND  := 0x0001
        Static TTF_CENTERTIP := 0x0002
        Static TTF_SUBCLASS  := 0x0010
        Static OffsetSize  := 0
        Static OffsetFlags := 4
        Static OffsetHwnd  := 8
        Static OffsetID    := OffsetHwnd + A_PtrSize
        Static OffsetRect  := OffsetID + A_PtrSize
        Static OffsetInst  := OffsetRect + 16
        Static OffsetText  := OffsetInst + A_PtrSize
        Static StructSize  := (4 * 6) + (A_PtrSize * 6)
        Flags := TTF_IDISHWND | TTF_SUBCLASS
        If (CenterTip)
            Flags |= TTF_CENTERTIP
        VarSetCapacity(TOOLINFO, StructSize, 0)
        NumPut(StructSize, TOOLINFO, OffsetSize, "UInt")
        NumPut(Flags, TOOLINFO, OffsetFlags, "UInt")
        NumPut(This.HGUI, TOOLINFO, OffsetHwnd, "Ptr")
        NumPut(HCTRL, TOOLINFO, OffsetID, "Ptr")
        NumPut(TipTextAddr, TOOLINFO, OffsetText, "Ptr")
        Return True
    }

    Attach(HCTRL, TipText, CenterTip = False) {
        Static TTM_ADDTOOL  := A_IsUnicode ? 0x0432 : 0x0404 ; TTM_ADDTOOLW : TTM_ADDTOOLA
        If !(This.HTIP) {
            Return False
        }
        If This.CTRL.HasKey(HCTRL)
            Return False
        TOOLINFO := ""
        This.SetToolInfo(TOOLINFO, HCTRL, &TipText, CenterTip)
        If DllCall("User32.dll\SendMessage", "Ptr", This.HTIP, "Int", TTM_ADDTOOL, "Ptr", 0, "Ptr", &TOOLINFO) {
            This.CTRL[HCTRL] := 1
            Return True
        } Else {
            Return False
        }
    }

    Suspend(Mode = True) {
        Static TTM_ACTIVATE := 0x0401
        If !(This.HTIP)
            Return False
        DllCall("SendMessage", "Ptr", This.HTIP, "Int", TTM_ACTIVATE, "Ptr", !Mode, "Ptr", 0)
        Return True
    }

    SetDelayTimes(Init = -1, PopUp = -1, ReShow = -1) {
        Static TTM_SETDELAYTIME   := 0x0403
        Static TTDT_RESHOW   := 1
        Static TTDT_AUTOPOP  := 2
        Static TTDT_INITIAL  := 3
        DllCall("SendMessage", "Ptr", This.HTIP, "Int", TTM_SETDELAYTIME, "Ptr", TTDT_INITIAL, "Ptr", Init)
        DllCall("SendMessage", "Ptr", This.HTIP, "Int", TTM_SETDELAYTIME, "Ptr", TTDT_AUTOPOP, "Ptr", PopUp)
        DllCall("SendMessage", "Ptr", This.HTIP, "Int", TTM_SETDELAYTIME, "Ptr", TTDT_RESHOW , "Ptr", ReShow)
    }
}

; -------------------------------------------------------------------------------
; FIND
; -------------------------------------------------------------------------------

FindButton:
    Gui, Submit, NoHide
    if (StrLen(SearchTextGlobal) > 0) {
        ; Get the handle of the edit control
        GuiControlGet, InputTextHwnd, Hwnd, InputText

        ; Start position logic
        StartPos := (LastFoundPos = 0) ? 1 : LastFoundPos + StrLen(SearchTextGlobal)

        ; Prepare search parameters
        SearchOptions := ""
        if (IgnoreCaseFind)
            SearchOptions .= "i"

        if (RegexEnabled) {
            ; Regex Search
            try {
                if (WholeWordFind)
                    SearchTextGlobal := "\b" . SearchTextGlobal . "\b"

                FoundPos := RegExMatch(InputText, SearchOptions . ")" . SearchTextGlobal, Match, StartPos)

                if (FoundPos > 0) {
                    ; Calculate actual position considering line breaks
                    ActualPos := 0
                    NewlineCount := 0
                    Loop, % FoundPos - 1 {
                        if (SubStr(InputText, A_Index, 1) == "`n")
                            NewlineCount++
                    }

                    ; Account for newlines in the selection position
                    ActualPos := FoundPos + NewlineCount

                    ; Select the found text
                    SendMessage, 0xB1, ActualPos - 1, ActualPos - 1 + StrLen(Match), , ahk_id %InputTextHwnd%

                    ; Scroll and focus
                    SendMessage, 0xB7, 0, 0, , ahk_id %InputTextHwnd%
                    ControlFocus, , ahk_id %InputTextHwnd%

                    LastFoundPos := FoundPos
                } else {
                    ; If not found from current position, wrap around
                    FoundPos := RegExMatch(InputText, SearchOptions . ")" . SearchTextGlobal, Match)

                    if (FoundPos > 0) {
                        ; Calculate actual position considering line breaks
                        ActualPos := 0
                        NewlineCount := 0
                        Loop, % FoundPos - 1 {
                            if (SubStr(InputText, A_Index, 1) == "`n")
                                NewlineCount++
                        }

                        ; Account for newlines in the selection position
                        ActualPos := FoundPos + NewlineCount

                        SendMessage, 0xB1, ActualPos - 1, ActualPos - 1 + StrLen(Match), , ahk_id %InputTextHwnd%
                        SendMessage, 0xB7, 0, 0, , ahk_id %InputTextHwnd%
                        ControlFocus, , ahk_id %InputTextHwnd%

                        LastFoundPos := 0
                    } else {
                        MsgBox, Text not found!
                        LastFoundPos := 0
                    }
                }
            } catch e {
                MsgBox, Invalid Regex Pattern: %e%
                LastFoundPos := 0
            }
        } else {
            ; Original non-regex search
            ; Normalize text by removing or replacing newlines for the search
            NormalizedText := StrReplace(InputText, "`r`n", " ")

            ; Normalize case if 'IgnoreCaseFind' is checked
            if (IgnoreCaseFind) {
                StringLower, NormalizedText, NormalizedText
                StringLower, SearchTextGlobal, SearchTextGlobal
            }

            ; Determine if whole word matching is needed
            if (WholeWordFind) {
                ; Use RegEx to find whole words
                SearchPattern := "\b" . RegExEscape(SearchTextGlobal) . "\b"
                FoundPos := RegExMatch(NormalizedText, SearchPattern, Match, StartPos)
            } else {
                ; Use InStr for normal search
                FoundPos := InStr(NormalizedText, SearchTextGlobal, 0, StartPos)
            }

            ; If not found from current position, wrap around to beginning
            if (FoundPos = 0 && LastFoundPos != 0) {
                if (WholeWordFind) {
                    FoundPos := RegExMatch(NormalizedText, SearchPattern, Match)
                } else {
                    FoundPos := InStr(NormalizedText, SearchTextGlobal, 0)
                }
                LastFoundPos := 0  ; Reset for next search
            }

            if (FoundPos > 0) {
                ; We now need to calculate the actual position in the original text, considering line breaks.
                ActualPos := 0
                ; Count how many newlines precede the matched text
                NewlineCount := 0
                Loop, % FoundPos - 1 {
                    if (SubStr(InputText, A_Index, 1) == "`n")
                        NewlineCount++
                }

                ; Account for newlines in the selection position
                ActualPos := FoundPos + NewlineCount

                ; Select/Highlight the found text in the original position
                SendMessage, 0xB1, ActualPos - 1, ActualPos - 1 + StrLen(SearchTextGlobal), , ahk_id %InputTextHwnd%

                ; Scroll to make the selection visible
                SendMessage, 0xB7, 0, 0, , ahk_id %InputTextHwnd%  ; EM_SCROLLCARET

                ; Focus the control to make selection visible
                ControlFocus, , ahk_id %InputTextHwnd%

                ; Update LastFoundPos for next search
                LastFoundPos := FoundPos
            } else {
                ToolTip, Text not found!
                SetTimer, RemoveToolTip, -1000
                LastFoundPos := 0  ; Reset for next search
            }
        }
    }
return

; Function to escape special regex characters
RegExEscape(str) {
    return RegExReplace(str, "([\[\]\(\)\{\}\.\*\+\?\^\$\\\|])", "\\\$1")
}

; -------------------------------------------------------------------------------
; SEARCH AND REPLACE
; -------------------------------------------------------------------------------

ReplaceText:
    Gui, Submit, NoHide

    input := InputText
    search := SearchText
    replace := ReplaceText

caseSensitive := !CaseSensitive

    ; Escape special regex characters if not in regex mode
    if (!RegexMode) {
        escapedSearch := ""
        Loop, Parse, search
        {
            if A_LoopField ~= "[\.\*\+\?\^\$\{\}\(\)\|\[\]\\]"
                escapedSearch .= "\" . A_LoopField
            else
                escapedSearch .= A_LoopField
        }
        search := escapedSearch
    }

    ; Whole word handling
    if (WholeWord) {
        regex := "\b" . search . "\b"
    } else {
        regex := search
    }

    ; Perform replacement
    if (caseSensitive) {
        output := RegExReplace(input, regex, replace)
    } else {
        output := RegExReplace(input, "(?i)" . regex, replace)
    }

    OutputText := output
    GuiControl,, OutputText, %OutputText%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

; -------------------------------------------------------------------------------
; SUFFIX AND PREFIX
; -------------------------------------------------------------------------------

AddSuffixPrefix:
    Gui, Submit, NoHide
    text := InputText
    result := ""
    PrefixBasic := StrReplace(PrefixBasic, " ", Chr(160))
    SuffixBasic := StrReplace(SuffixBasic, " ", Chr(160))

    Loop, Parse, text, `n, `r
    {
        line := A_LoopField
        trimmedLine := Trim(line)

        ; Existing functionality
        if (DeleteEmpty && line = "")
            continue

        if (DeleteBlank && RegExMatch(line, "^\s+$"))
            continue

        ; New option to exclude blank lines from prefix/suffix
        if (ExcludeBlank && RegExMatch(line, "^\s+$"))
        {
            result .= line . "`n"
            continue
        }

        if (!ExcludeEmpty || line != "")
            line := PrefixBasic . line . SuffixBasic

        result .= line . "`n"
    }

    result := RTrim(result, "`n`r")

    GuiControl, , OutputText, %result%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

; -------------------------------------------------------------------------------
; SPACES
; -------------------------------------------------------------------------------

RemoveSpaces:
    Gui, Submit, NoHide
    text := InputText

    if (TrimStart) {
        Loop, Parse, text, `n
        {
            Line := A_LoopField
            Line := LTrim(Line)
            Result .= Line . "`n"
        }
        text := Result
        Result := ""
    }

    if (TrimEnd) {
        Loop, Parse, text, `n
        {
            Line := A_LoopField
            Line := RTrim(Line)
            Result .= Line . "`n"
        }
        text := Result
        Result := ""
    }

    if (RemoveExtra) {
        Loop, Parse, text, `n
        {
            Line := A_LoopField
            Line := RegExReplace(Line, "(\S)\s+(\S)", "$1 $2")
            Result .= Line . "`n"
        }
        text := Result
        Result := ""
    }

    if (TrimAbove)
        text := RegExReplace(text, "^\s+", "")
    if (TrimBelow)
        text := RegExReplace(text, "\s+$", "")
    if (RemoveExtraWholeText)
        text := RegExReplace(text, "[ \t]+", " ")

    if (RemoveAllSpaces) {
        text := RegExReplace(text, "[ \t]+", "")
    }

    ; text := RTrim(text, "`n`r")

    GuiControl, , OutputText, %text%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

; -------------------------------------------------------------------------------
; LINE BREAKS BASIC
; -------------------------------------------------------------------------------

LineBreaksBasic:
    Gui, Submit, NoHide
    ; Get the text from input
    GuiControlGet, text,, InputText

    ; First, normalize all line breaks to single newlines
    text := RegExReplace(text, "\r\n|\r|\n", "`n")

    ; Process according to selected option
    if (LineBreakOption1)
    {
        ; Remove all line breaks
        text := RegExReplace(text, "\s*\n\s*", "")
    }
    else if (LineBreakOption5)
    {
        ; Remove all line breaks
        text := RegExReplace(text, "\s*\n\s*", " ")
    }
    else if (LineBreakOption2)
    {
        ; Custom number of line breaks
        numBreaks := CustomBreaksUpDown

        ; First normalize to single breaks
        text := RegExReplace(text, "\s*\n\s*", "`n")
        text := RegExReplace(text, "\n+", "`n")

        ; Then replace with custom number
        breaks := RepeatStr("`n", numBreaks)
        text := RegExReplace(text, "\n", breaks)
    }
    else if (LineBreakOption3)
    {
        ; Retrieve source text and line break count
        LineBreakCount := LineBreakCountUpDown

        ; Validate line break count (default to 1 if invalid)
        if (LineBreakCount = "" || LineBreakCount < 0)
            LineBreakCount := 1

        ; Split the text into lines
        lines := StrSplit(text, "`n")
        result := ""

        ; Process each line
        for index, line in lines {
            ; Skip adding extra line breaks for empty lines or "/n"
            if (Trim(line) != "" && Trim(line) != "/n") {
                ; Add specified number of line breaks
                Loop, %LineBreakCount%
                {
                    result .= "`n"
                }
                result .= line
            } else {
                result .= line
            }

            ; Add a final newline unless it's the last line
            if (index < lines.Length())
                result .= "`n"
        }

        ; Remove leading/trailing whitespace
        result := result, "`n" ; Use result := Trim(result, "`n") to exclude adding of line breaks before text

        text := result
    }
    else if (LineBreakOption4)
    {
        ; Validate auto process count
        AutoProcessCount := AutoProcessCountUpDown
        if (AutoProcessCount < 1)
            AutoProcessCount := 1

        ; Store original text
        originalText := text

        ; Repeat processing specified number of times
        Loop, %AutoProcessCount%
        {
            ; Split the text into lines
            lines := StrSplit(text, "`n", "`r")

            ; Combine lines
            combinedLines := []
            currentLine := ""

            for index, line in lines {
                trimmedLine := Trim(line)

                ; If line is not empty
                if (trimmedLine != "") {
                    ; If current line is empty, start a new line
                    if (currentLine == "") {
                        currentLine := trimmedLine
                    } else {
                        ; Append to current line with a space
                        currentLine .= "" . trimmedLine
                    }
                } else {
                    ; Empty line means end of paragraph
                    if (currentLine != "") {
                        combinedLines.Push(currentLine)
                        currentLine := ""
                    }
                    ; Push empty line to preserve paragraph breaks
                    combinedLines.Push("")
                }
            }

            ; Add last line if not empty
            if (currentLine != "") {
                combinedLines.Push(currentLine)
            }

            ; Process combined lines
            processedLines := []
            i := 1
            while (i <= combinedLines.Length()) {
                ; If current line is not empty
                if (Trim(combinedLines[i]) != "") {
                    processedLines.Push(combinedLines[i])

                    ; If next line is empty, skip it
                    if (i + 1 <= combinedLines.Length() && Trim(combinedLines[i+1]) == "") {
                        i++
                    }
                } else {
                    ; Keep other empty lines
                    processedLines.Push(combinedLines[i])
                }

                i++
            }

            ; Join processed lines
            text := ""
            for index, line in processedLines {
                text .= line . "`n"
            }

            ; Remove trailing newline
            text := RegExReplace(text, "^(\n){" . AutoProcessCount . "}", "") ; Use text := RTrim(text, "`n") to exclude removing of line breaks before text
        }
    }

    ; Update output field
    GuiControl,, OutputText, %text%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

RepeatStr(str, count) {
    result := ""
    Loop, %count%
        result .= str
    return result
}

; -------------------------------------------------------------------------------
; LINE BREAKS EXTENDED
; -------------------------------------------------------------------------------

LineBreaksExtended:
    Gui, Submit, NoHide
    text := InputText
    symbol := Symbol
    numCharacters := NumCharactersUpDown
    insensitive := CaseInsensitive
    wholeWordLineBreaks := WholeWordLineBreaks
    regexSymbol := symbol

    if (insensitive) {
        regexSymbol := "(?i)" . symbol
    } else {
        regexSymbol := symbol
    }

    if (wholeWordLineBreaks) {
        regexSymbol := "\b" . regexSymbol . "\b"
    }

    if (Option4) {
        result := RegExReplace(text, "`n", symbol)
    } else if (Option1) {
        result := RegExReplace(text, "(" . regexSymbol . ")", "`n$1")
    } else if (Option2) {
        result := RegExReplace(text, "(" . regexSymbol . ")", "`n")
    } else if (Option3) {
        result := RegExReplace(text, "(" . regexSymbol . ")", "$1`n")
    } else if (Option5) {
        if (numCharacters > 0) {
            result := ""
            charCount := 0
            Loop, Parse, text
            {
                charCount++
                result .= A_LoopField
                if (charCount >= numCharacters) {
                    result .= "`n"
                    charCount := 0
                }
            }
        } else {
            MsgBox, 16, Error, Please enter a valid number of characters.
        }
    }

    GuiControl,, OutputText, % result
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats

return

; -------------------------------------------------------------------------------
; DELETION
; -------------------------------------------------------------------------------

ActionTypeChanged:
    Gui, Submit, NoHide

    if (ActionType = "Delete Containing") {
        GuiControl,, DeletionSharedLabel1, Delete Containing:
        GuiControl,, DeletionSharedLabel2, Delete NOT Containing:
        GuiControl, Enabled, DeletionEditField1
        GuiControl, Disabled, DeletionEditField2
        GuiControl, Disabled, RemoveSymbol
        GuiControl, Disabled, IsLineContext
    }

    else if (ActionType = "Delete NOT Containing") {
        GuiControl,, DeletionSharedLabel1, Delete Containing:
        GuiControl,, DeletionSharedLabel2, Delete NOT Containing:
        GuiControl, Enabled, DeletionEditField2
        GuiControl, Disabled, DeletionEditField1
        GuiControl, Disabled, RemoveSymbol
        GuiControl, Disabled, IsLineContext
    }

    else if (ActionType = "Delete Before and After") {
        GuiControl,, DeletionSharedLabel1, Delete Before:
        GuiControl,, DeletionSharedLabel2, Delete After:
        GuiControl, Enabled, DeletionEditField1
        GuiControl, Enabled, DeletionEditField2
        GuiControl, Enabled, RemoveSymbol
        GuiControl, Enabled, IsLineContext
    }
    else if (ActionType = "Delete Block") {
        GuiControl,, DeletionSharedLabel1, Block Start:
        GuiControl,, DeletionSharedLabel2, Block End:
        GuiControl, Enabled, DeletionEditField1
        GuiControl, Enabled, DeletionEditField2
        GuiControl, Enabled, RemoveSymbol
        GuiControl, Enabled, IsLineContext
    }
return

DellActionButton:
    Gui, Submit, NoHide

    Switch ActionType
    {
    Case "Delete Containing":
        Result := RemoveLines(InputText, DeletionEditField1, CaseInsensitiveDel, WholeWordsOnlyDel)

    Case "Delete NOT Containing":
        Result := RemoveNotLines(InputText, DeletionEditField2, CaseInsensitiveDel, WholeWordsOnlyDel)

    Case "Delete Before and After":
        Result := DeleteBeforeAfter(InputText, DeletionEditField1, DeletionEditField2, IsLineContext, RemoveSymbol, CaseInsensitiveDel, WholeWordsOnlyDel)

    Case "Delete Block":
        Result := DeleteBlock(inputText, DeletionEditField1, DeletionEditField2, isLineContext, removeSymbol, CaseInsensitiveDel, WholeWordsOnlyDel)
    }

    GuiControl,, OutputText, %Result%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
Return

RemoveLines(inputText, DeletionEditField1, CaseInsensitiveDel, WholeWordsOnlyDel) {
    StringSplit, Lines, InputText, `n
    Result := ""
    Loop, %Lines0%
    {
        if (WholeWordsOnlyDel) {
            if (CaseInsensitiveDel) {
                if !RegExMatch(Lines%A_Index%, "i)\b" . EscapeRegExChars(DeletionEditField1) . "\b")
                    Result .= Lines%A_Index% . "`n"
            }
            else {
                if !RegExMatch(Lines%A_Index%, "\b" . EscapeRegExChars(DeletionEditField1) . "\b")
                    Result .= Lines%A_Index% . "`n"
            }
        }
        else {
            if (CaseInsensitiveDel) {
                if !InStr(Lines%A_Index%, DeletionEditField1)
                    Result .= Lines%A_Index% . "`n"
            }
            else {
                if !InStr(Lines%A_Index%, DeletionEditField1, True)
                    Result .= Lines%A_Index% . "`n"
            }
        }
    }
    return RTrim(Result, "`n")
}

RemoveNotLines(inputText, DeletionEditField2, CaseInsensitiveDel, WholeWordsOnlyDel) {
    StringSplit, Lines, InputText, `n
    Result := ""
    Loop, %Lines0%
    {
        if (WholeWordsOnlyDel) {
            if (CaseInsensitiveDel) {
                if RegExMatch(Lines%A_Index%, "i)\b" . EscapeRegExChars(DeletionEditField2) . "\b")
                    Result .= Lines%A_Index% . "`n"
            }
            else {
                if RegExMatch(Lines%A_Index%, "\b" . EscapeRegExChars(DeletionEditField2) . "\b")
                    Result .= Lines%A_Index% . "`n"
            }
        }
        else {
            if (CaseInsensitiveDel) {
                if InStr(Lines%A_Index%, DeletionEditField2)
                    Result .= Lines%A_Index% . "`n"
            }
            else {
                if InStr(Lines%A_Index%, DeletionEditField2, True)
                    Result .= Lines%A_Index% . "`n"
            }
        }
    }
    return RTrim(Result, "`n")
}

DeleteBeforeAfter(mainText, DeletionEditField1, DeletionEditField2, isLineContext, removeSymbol, CaseInsensitiveDel, WholeWordsOnlyDel) {
    DeletionEditField1 := EscapeRegExChars(DeletionEditField1)
    DeletionEditField2 := EscapeRegExChars(DeletionEditField2)

    if (isLineContext) {
        processedText := ""
        Loop, Parse, mainText, `n, `r
        {
            line := A_LoopField

            if (WholeWordsOnlyDel) {
                if (CaseInsensitiveDel) {
                    if (DeletionEditField1 != "") {
                        line := RegExReplace(line, "(?i).*?\b(" DeletionEditField1 ")\b", !removeSymbol ? "$1" : "")
                    }

                    if (DeletionEditField2 != "") {
                        line := RegExReplace(line, "(?i)\b(" DeletionEditField2 ")\b.*", !removeSymbol ? "$1" : "")
                    }
                }
                else {
                    if (DeletionEditField1 != "") {
                        line := RegExReplace(line, ".*?\b(" DeletionEditField1 ")\b", !removeSymbol ? "$1" : "")
                    }

                    if (DeletionEditField2 != "") {
                        line := RegExReplace(line, "\b(" DeletionEditField2 ")\b.*", !removeSymbol ? "$1" : "")
                    }
                }
            }
            else {
                if (CaseInsensitiveDel) {
                    if (DeletionEditField1 != "") {
                        line := RegExReplace(line, "(?i).*?(" DeletionEditField1 ")", !removeSymbol ? "$1" : "")
                    }

                    if (DeletionEditField2 != "") {
                        line := RegExReplace(line, "(?i)(" DeletionEditField2 ").*", !removeSymbol ? "$1" : "")
                    }
                }
                else {
                    if (DeletionEditField1 != "") {
                        line := RegExReplace(line, ".*?(" DeletionEditField1 ")", !removeSymbol ? "$1" : "")
                    }

                    if (DeletionEditField2 != "") {
                        line := RegExReplace(line, "(" DeletionEditField2 ").*", !removeSymbol ? "$1" : "")
                    }
                }
            }

            processedText .= line . "`n"
        }
        mainText := RTrim(processedText, "`n")
    }
    else {
        if (WholeWordsOnlyDel) {
            if (CaseInsensitiveDel) {
                if (DeletionEditField1 != "") {
                    mainText := RegExReplace(mainText, "(?i).*?\b(" DeletionEditField1 ")\b", !removeSymbol ? "$1" : "")
                }

                if (DeletionEditField2 != "") {
                    mainText := RegExReplace(mainText, "(?i)\b(" DeletionEditField2 ")\b.*", !removeSymbol ? "$1" : "")
                }
            }
            else {
                if (DeletionEditField1 != "") {
                    mainText := RegExReplace(mainText, ".*?\b(" DeletionEditField1 ")\b", !removeSymbol ? "$1" : "")
                }

                if (DeletionEditField2 != "") {
                    mainText := RegExReplace(mainText, "\b(" DeletionEditField2 ")\b.*", !removeSymbol ? "$1" : "")
                }
            }
        }
        else {
            if (CaseInsensitiveDel) {
                if (DeletionEditField1 != "") {
                    mainText := RegExReplace(mainText, "(?i).*?(" DeletionEditField1 ")", !removeSymbol ? "$1" : "")
                }

                if (DeletionEditField2 != "") {
                    mainText := RegExReplace(mainText, "(?i)(" DeletionEditField2 ").*", !removeSymbol ? "$1" : "")
                }
            }
            else {
                if (DeletionEditField1 != "") {
                    mainText := RegExReplace(mainText, ".*?(" DeletionEditField1 ")", !removeSymbol ? "$1" : "")
                }

                if (DeletionEditField2 != "") {
                    mainText := RegExReplace(mainText, "(" DeletionEditField2 ").*", !removeSymbol ? "$1" : "")
                }
            }
        }
    }

    return mainText
}

DeleteBlock(inputText, DeletionEditField1, DeletionEditField2, isLineContext, removeSymbol, CaseInsensitiveDel, WholeWordsOnlyDel) {
    ; Set regex options based on case sensitivity
    regexOptions := CaseInsensitiveDel ? "i)" : ""

    ; Determine regex pattern based on checkboxes and context
    if (isLineContext) {
        ; Line-context mode: only match within a single line
        if (WholeWordsOnlyDel) {
            if (removeSymbol) {
                pattern := "\b" . EscapeRegExChars(DeletionEditField1) . ".*?" . EscapeRegExChars(DeletionEditField2) . "\b"
            } else {
                pattern := "(?<=\b" . EscapeRegExChars(DeletionEditField1) . "\b).*?(?=\b" . EscapeRegExChars(DeletionEditField2) . "\b)"
            }
        } else {
            if (removeSymbol) {
                pattern := EscapeRegExChars(DeletionEditField1) . ".*?" . EscapeRegExChars(DeletionEditField2)
            } else {
                pattern := "(?<=(" . EscapeRegExChars(DeletionEditField1) . ")).*?(?=(" . EscapeRegExChars(DeletionEditField2) . "))"
            }
        }

        ; Split input into lines and process each line separately
        StringSplit, Lines, InputText, `n
        Result := ""

        Loop, %Lines0%
        {
            ; Remove the matched text
            processedLine := RegExReplace(Lines%A_Index%, regexOptions . pattern, "")

            ; Add the processed line to output if it's not empty
            if (processedLine != "") {
                Result .= processedLine . "`n"
            }
        }

        ; Remove trailing newline
        return RTrim(Result, "`n")
    } else {
        ; Multiline mode: match across multiple lines
        if (WholeWordsOnlyDel) {
            if (removeSymbol) {
                pattern := "\b" . EscapeRegExChars(DeletionEditField1) . ".*?" . EscapeRegExChars(DeletionEditField2) . "\b"
            } else {
                pattern := "(?<=\b" . EscapeRegExChars(DeletionEditField1) . "\b).*?(?=\b" . EscapeRegExChars(DeletionEditField2) . "\b)"
            }
        } else {
            if (removeSymbol) {
                pattern := EscapeRegExChars(DeletionEditField1) . "[\s\S]*?" . EscapeRegExChars(DeletionEditField2)
            } else {
                pattern := "(?<=(" . EscapeRegExChars(DeletionEditField1) . "))[\s\S]*?(?=(" . EscapeRegExChars(DeletionEditField2) . "))"
            }
        }

        ; Remove the matched text across multiple lines
        Result := RegExReplace(inputText, regexOptions . pattern, "")

        return Result
    }
}

EscapeRegExChars(str) {
    specialChars := "\.*?+^$[](){}|"

    Loop, Parse, specialChars
        str := StrReplace(str, A_LoopField, "\" A_LoopField)

    return str
}

; -------------------------------------------------------------------------------
; DUPLICATE LINES
; -------------------------------------------------------------------------------

RemoveDuplicates:
    Gui, Submit, NoHide
    StringSplit, Lines, InputText, `n
    UniqueLines := {}
    ResultText := ""
    FirstOccurrences := {}

    Loop, % Lines0
    {
        Line := Lines%A_Index%

        checkLine := TrimSpaces ? Trim(Line) : Line

        if (checkLine = "")
        {
            ResultText .= "`n"
            continue
        }

        regexLine := IgnoreCase ? "(?i)" . checkLine : checkLine

        isDuplicate := false
        for key, value in UniqueLines
        {
            if (RegExMatch(key, "^" . regexLine . "$"))
            {
                isDuplicate := true
                break
            }
        }

        if (!isDuplicate)
        {
            UniqueLines[checkLine] := true
            FirstOccurrences[checkLine] := Line
            ResultText .= Line "`n"
        }
        else
        {
            if (DeleteFirstDuplicate)
            {
                ; Remove the first occurrence if this is a duplicate
                if (FirstOccurrences.HasKey(checkLine))
                {
                    ; If KeepDuplicates is on, add a blank line instead of completely removing
                    if (KeepDuplicates)
                    {
                        ResultText := StrReplace(ResultText, FirstOccurrences[checkLine] . "`n", "`n")
                    }
                    else
                    {
                        ResultText := StrReplace(ResultText, FirstOccurrences[checkLine] . "`n", "")
                    }
                    FirstOccurrences.Delete(checkLine)
                }
            }

            if (KeepDuplicates)
            {
                ResultText .= "`n"
            }
        }
    }

    ResultText := RTrim(ResultText, "`n")
    GuiControl,, OutputText, %ResultText%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

; -------------------------------------------------------------------------------
; EMPTY AND BLANK LINES REMOVAL
; -------------------------------------------------------------------------------

DeleteEmptyBlankLines:
    ; Get the input text from the input field
    Gui, Submit, NoHide
    text := InputText

    ; Determine which option is selected
    if (DeleteOnlyEmptyLines) {
        ; Delete all empty lines (no characters)
        StringReplace, text, text, `r`n, `n, All ; Normalize line endings
        StringSplit, lines, text, `n
        result := ""
        Loop, %lines0% {
            if (lines%A_Index% != "") {
                result .= lines%A_Index% "`n"
            }
        }
    } else if (DeleteBothEmptyBlankLines) {
        ; Delete lines that are only whitespace
        StringReplace, text, text, `r`n, `n, All ; Normalize line endings
        StringSplit, lines, text, `n
        result := ""
        Loop, %lines0% {
            if (Trim(lines%A_Index%) != "") {
                result .= lines%A_Index% "`n"
            }
        }
    } else if (DeleteOnlyBlankLines) {
        ; Delete lines that are completely blank (no characters or spaces)
        StringReplace, text, text, `r`n, `n, All ; Normalize line endings
        StringSplit, lines, text, `n
        result := ""
        Loop, %lines0% {
            if (lines%A_Index% == "" || !RegExMatch(lines%A_Index%, "^\s+$")) {
                result .= lines%A_Index% "`n"
            }
        }
    }

    ; Display the result in the result field
    GuiControl,, OutputText, %result%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

; -------------------------------------------------------------------------------
; SPECIAL CHARACTER REMOVAL
; -------------------------------------------------------------------------------

RemoveChars:
    Gui, Submit, NoHide
    Output := InputText

    Loop, Parse, RemoveCharsField
    {
        StringReplace, Output, Output, %A_LoopField%, , All
    }

    GuiControl,, OutputText, %Output%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

; -------------------------------------------------------------------------------
; NUMBERING
; -------------------------------------------------------------------------------

NumberingMode1:
    Gui, Submit, NoHide
    GuiControl,, StartChar, 1
return

NumberingMode2:
    Gui, Submit, NoHide
    GuiControl,, StartChar, I
return

NumberingMode3:
    Gui, Submit, NoHide
    GuiControl,, StartChar, A
return

NumberText:
    Gui, Submit, NoHide
    Output := ""
    Prefix := (Prefix != "") ? Prefix : "" ; Префикс по умолчанию пустой
    Suffix := (Suffix != "") ? Suffix : "" ; Суффикс по умолчанию пустой
    Prefix := StrReplace(Prefix, " ", Chr(160))
    Suffix := StrReplace(Suffix, " ", Chr(160))
    dot := (AddDot = "1") ? "." : "" ; Точка добавляется, если чекбокс активен
    lowercase := (Uppercase = "1") ? true : false ; Нумерация в нижнем регистре

    ; Устанавливаем значение по умолчанию для начального символа
    if (NumberingMode3 = "1") ; Буквы (A)
    {
        StartChar := StartChar ? StartChar : "A" ; Используем 'A', если не заполнено
    }
    else if (NumberingMode2 = "1") ; Римские цифры
    {
        StartChar := StartChar ? StartChar : 1 ; Устанавливаем начальный символ в 1, если пусто
        StartChar := IsNumber(StartChar) ? StartChar : RomanToDecimal(StartChar)
    }
    else
    {
        StartChar := StartChar ? StartChar : 1 ; Для цифр используем число 1
    }

    ; if (DeleteStartNumbers = "1") {
    ;     ; Regex to remove leading digits and special characters from the start of each line
    ;     tempInputText := ""
    ;     Loop, Parse, InputText, `n
    ;     {
    ;         ; Remove leading digits, special characters, and whitespace from the start of the line
    ;         cleanedLine := RegExReplace(A_LoopField, "^[\s\d]+", "") ; I had /W here to remove non-word chars but it removes unicode stuff too
    ;         tempInputText .= cleanedLine . "`n"
    ;     }
    ;     InputText := Trim(tempInputText, "`n")
    ; }

    if (DeleteStartNumbers = "1") {
        ; Regex to remove leading digits and any following special characters/whitespace
        tempInputText := ""
        Loop, Parse, InputText, `n
        {
            ; Remove leading digits followed by any special chars (.,), etc.) and whitespace
            cleanedLine := RegExReplace(A_LoopField, "^[\s\d]+[\.\,\)\]\}\s]*", "")
            tempInputText .= cleanedLine . "`n"
        }
        InputText := Trim(tempInputText, "`n")

        if (NumberingMode1 != "1" && NumberingMode2 != "1" && NumberingMode3 != "1") {
            Output := Trim(tempInputText, "`n")
        }

    }

    ; Определяем режим нумерации
    if (NumberingMode1 = "1") ; Digits
    {
        ; Calculate max width for leading zeros
        maxWidth := (LeadingZeros = "1") ? GetMaxNumberWidth(StartChar, totalLines, numberingMode) : 0

        Loop, Parse, InputText, `n
        {

            if (DeleteEmptyLines && A_LoopField = "")
            {
                continue
            }
            ; Handle DeleteBlankLines
            else if (DeleteBlankLines && RegExMatch(A_LoopField, "^\s+$"))
            {
                continue
            }
            ; Handle ExcludeBlankLines
            else if (ExcludeBlankLines && RegExMatch(A_LoopField, "^\s+$"))
            {
                ; Add the blank line without numbering
                Output .= A_LoopField . "`n"
            }
            ; Original empty line handling
            else if (ExcludeEmptyLines && A_LoopField = "")
            {
                Output .= A_LoopField . "`n"
            }
            else if (!DeleteEmptyLines || (DeleteEmptyLines && A_LoopField != ""))
            {
                ; Format number with leading zeros if enabled
                num := (LeadingZeros = "1")
                    ? Prefix . Format("{:0" . maxWidth . "}", StartChar)
                    : Prefix . Format("{:U}", StartChar)

                separator := (Suffix != "") ? "" : dot
                Output .= num . dot . Suffix . A_LoopField . "`n"
                StartChar++
            }
        }
    }

    else if (NumberingMode2 = "1") ; Римские цифры
    {
        Loop, Parse, InputText, `n
        {
            if (DeleteEmptyLines && A_LoopField = "")
            {
                continue
            }
            ; Handle DeleteBlankLines
            else if (DeleteBlankLines && RegExMatch(A_LoopField, "^\s+$"))
            {
                continue
            }
            ; Handle ExcludeBlankLines
            else if (ExcludeBlankLines && RegExMatch(A_LoopField, "^\s+$"))
            {
                ; Add the blank line without numbering
                Output .= A_LoopField . "`n"
            }
            ; Original empty line handling
            else if (ExcludeEmptyLines && A_LoopField = "")
            {
                Output .= A_LoopField . "`n"
            }
            else if (!DeleteEmptyLines || (DeleteEmptyLines && A_LoopField != "")) ; Пропускаем пустые строки, если чекбокс активен и строка пуста
            {
                romanNum := ToRoman(StartChar)
                if (lowercase)
                    romanNum := Format("{:L}", romanNum) ; Преобразуем в нижний регистр
                num := Prefix . romanNum ; Используем римские цифры
                separator := (Suffix != "") ? "" : dot ; Точка ставится только если суффикса нет и чекбокс активен
                Output .= num . dot . Suffix . A_LoopField . "`n"
                StartChar++
            }
        }
    }
    else if (NumberingMode3 = "1") ; Буквы (A)
    {
        startIndex := (StartChar = "") ? 1 : Asc(StartChar) - 64 ; 'A' = 65 в ASCII
        Loop, Parse, InputText, `n
        {
            if (DeleteEmptyLines && A_LoopField = "")
            {
                continue
            }
            ; Handle DeleteBlankLines
            else if (DeleteBlankLines && RegExMatch(A_LoopField, "^\s+$"))
            {
                continue
            }
            ; Handle ExcludeBlankLines
            else if (ExcludeBlankLines && RegExMatch(A_LoopField, "^\s+$"))
            {
                ; Add the blank line without numbering
                Output .= A_LoopField . "`n"
            }
            ; Original empty line handling
            else if (ExcludeEmptyLines && A_LoopField = "")
            {
                Output .= A_LoopField . "`n"
            }
            else if (!DeleteEmptyLines || (DeleteEmptyLines && A_LoopField != "")) ; Пропускаем пустые строки, если чекбокс активен и строка пуста
            {
                letter := Chr(64 + startIndex) ; 'A' = 65 в ASCII
                if (lowercase)
                    letter := Format("{:L}", letter) ; Преобразуем в нижний регистр
                num := Prefix . letter
                separator := (Suffix != "") ? "" : dot ; Точка ставится только если суффикса нет и чекбокс активен
                Output .= num . dot . Suffix . A_LoopField . "`n"
                startIndex++
            }
        }
    }

    ; Выводим результат
    GuiControl,, OutputText, %Output%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

ToRoman(num) {
    local romanNumerals := [["M", 1000], ["CM", 900], ["D", 500], ["CD", 400], ["C", 100], ["XC", 90], ["L", 50], ["XL", 40], ["X", 10], ["IX", 9], ["V", 5], ["IV", 4], ["I", 1]]
    local result := ""

    for index, pair in romanNumerals {
        while (num >= pair[2]) {
            result .= pair[1]
            num -= pair[2]
        }
    }
    return result
}

RomanToDecimal(roman) {
    local romanNumerals := { "I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000 }
    local result := 0
    local prevValue := 0

    loop, parse, roman
    {
        currentValue := romanNumerals[A_LoopField]
        if (currentValue > prevValue) {
            result += currentValue - 2 * prevValue
        } else {
            result += currentValue
        }
        prevValue := currentValue
    }
    return result
}

IsNumber(value) {
    return (value+0) = value
}

GetMaxNumberWidth(startChar, totalLines, numberingMode) {
    local maxWidth := 0
    local currentNum := startChar
    local linesCount := 0

    ; Count actual numbered lines
    Loop, Parse, InputText, `n
    {
        if (!SkipEmptyLines || (SkipEmptyLines && Trim(A_LoopField) != ""))
        {
            linesCount++
        }
    }

    if (NumberingMode1 = "1") ; Digits
    {
        maxWidth := StrLen(currentNum + linesCount - 1)
    }
    else if (NumberingMode2 = "1") ; Roman numerals
    {
        Loop, % linesCount
        {
            romanNum := ToRoman(currentNum)
            maxWidth := Max(maxWidth, StrLen(romanNum))
            currentNum++
        }
    }
    else if (NumberingMode3 = "1") ; Letters
    {
        startIndex := (startChar = "") ? 1 : Asc(startChar) - 64
        maxWidth := StrLen(Chr(64 + startIndex + linesCount - 1))
    }

    return maxWidth
}

; -------------------------------------------------------------------------------
; SORTING
; -------------------------------------------------------------------------------

UpdateSortOrder:
    ; Обновляем сортировку при изменении радиокнопки
    Gui, Submit, NoHide
return

SortStrings:
    Gui, Submit, NoHide ; Получаем данные из GUI
    if (Alph && !ReverseSorting && !ConsiderCaseSorting) ; По алфавиту
    {
        Sort, InputText,
    }
    else if (Alph && ReverseSorting && !ConsiderCaseSorting) ; Обратная сортировка по алфавиту
    {
        Sort, InputText, R
    }
    else if (Alph && ConsiderCaseSorting && !ReverseSorting)
    {
        Sort, InputText, CL F ForceCaseOrder
    }
    else if (Alph && ConsiderCaseSorting && ReverseSorting)
    {
        Sort, InputText, CL F ForceCaseOrder
        Sort, InputText, F Rvrs
    }
    else if (Flip) ; Обратная сортировка строк
    {
        Sort, InputText, F Rvrs
    }
    else if (LineLength && !ReverseSorting) ; По длине строки
    {
        Sort, InputText, F SortFunc
    }
    else if (LineLength && ReverseSorting) ; Обратная сортировка по длине строки
    {
        Sort, InputText, F RevSortFunc
    }
    else if (Natural && !ReverseSorting) ; Естественная сортировка
    {
        Sort, InputText, F NaturalSortFunc
    }
    else if (Natural && ReverseSorting) ; Естественная сортировка (обратная)
    {
        Sort, InputText, F NaturalSortFunc ; Сначала выполняем естественную сортировку
        Sort, InputText, F Rvrs ; Затем переворачиваем результат
    }

    OutputText := InputText ; Сохраняем отсортированный текст в переменную
    GuiControl,, OutputText, %OutputText% ; Обновляем поле вывода
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

ForceCaseOrder(a, b, offset) {
    aFirstChar := Asc(SubStr(a, 1, 1))  ; ASCII value of first char
    bFirstChar := Asc(SubStr(b, 1, 1))

    ; Classify case (UPPER=1, LOWER=2)
    aCase := (aFirstChar >= 65 && aFirstChar <= 90) ? 1 : 2
    bCase := (bFirstChar >= 65 && bFirstChar <= 90) ? 1 : 2

    ; If cases differ, uppercase comes first
    if (aCase != bCase)
        return aCase < bCase ? -1 : 1
    ; If same case, sort alphabetically
    else
        return a < b ? -1 : a > b ? 1 : 0
}

; Функция для обратной сортировки строк
Rvrs(a1, a2, b)
{
    return b
}

SortFunc(lineA, lineB, offset)
{
    ; Return positive if lineA is longer than line B.
    ; Return negative if lineA is shorter than line B.
    if StrLen(lineA) != StrLen(lineB)
        return StrLen(lineA)-StrLen(lineB)
    ; Use offset to try to preserve the order in the file when two lines are of equal length.
    return -offset
}

RevSortFunc(lineA, lineB, offset)
{
    ; Обратная сортировка по длине строки
    if StrLen(lineA) != StrLen(lineB)
        return StrLen(lineB) - StrLen(lineA) ; Здесь изменено на lineB
    return -offset
}

; Функция для естественной сортировки
NaturalSortFunc(a, b)
{
    return NaturalCompare(a, b)
}

; Функция сравнения для естественной сортировки
NaturalCompare(a, b)
{
    aLen := StrLen(a), bLen := StrLen(b)
    i := 1, j := 1

    while (i <= aLen && j <= bLen)
    {
        ; Извлекаем числовые и нечисловые части
        aNum := "", bNum := ""
        while (i <= aLen && IsDigit(SubStr(a, i, 1)))
            aNum .= SubStr(a, i++, 1)
        while (j <= bLen && IsDigit(SubStr(b, j, 1)))
            bNum .= SubStr(b, j++, 1)

        ; Сравниваем числа, если они есть
        if (aNum != "" && bNum != "")
        {
            if (aNum != bNum)
                return aNum - bNum
        }
        else ; Сравниваем символы
        {
            aChar := SubStr(a, i++, 1)
            bChar := SubStr(b, j++, 1)
            if (aChar != bChar)
                return Asc(aChar) - Asc(bChar)
        }
    }

    ; Если одна строка закончилась, а другая нет
    return aLen - bLen
}

; Вспомогательная функция для проверки, является ли символ цифрой
IsDigit(char)
{
    return char >= "0" && char <= "9"
}

; -------------------------------------------------------------------------------
; CASE CHANGING
; -------------------------------------------------------------------------------

ConvertText:
    Gui, Submit, NoHide
    InputText := InputText
    OutputText := ""

    ; Проверка, какая радиокнопка выбрана
    if (CaseUpper) {
        StringUpper, OutputText, InputText
    } else if (CaseLower) {
        StringLower, OutputText, InputText
    } else if (CaseTitled) {
        StringUpper, OutputText, InputText, T
    } else if (CaseSentence) {
        StringLower, InputText, InputText
        sentences := StrSplit(InputText, "`n") ; Разделяем текст на строки

        for index, line in sentences {
            if (line != "") { ; Проверяем, что строка не пустая
                words := StrSplit(line, " ")
                newLine := ""

                for wordIndex, word in words {
                    ; Проверяем, нужно ли преобразовать первое слово в заглавную букву
                    if (wordIndex = 1 || RegExMatch(newLine, "(\.|!|\?)\s*$")) {
                        word := Format("{:U}", SubStr(word, 1, 1)) . SubStr(word, 2) ; Заглавная буква
                    }
                    newLine .= word ; Добавляем слово без пробела

                    ; Добавляем пробел только если это не последнее слово
                    if (wordIndex < words.MaxIndex()) {
                        newLine .= " "
                    }
                }
                OutputText .= newLine ; Добавляем строку без лишнего пробела
            }
            OutputText .= "`n" ; Добавляем перенос строки после каждой строки
        }

        ; Убираем последний перенос строки, если он есть
        StringTrimRight, OutputText, OutputText, 1
    }

    ; Обновляем поле вывода
    GuiControl,, OutputText, %OutputText%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

; -------------------------------------------------------------------------------
; ALIGNING
; -------------------------------------------------------------------------------

Allign:
    Gui, Submit, NoHide
    text := InputText
    fillChar := FillChar
    lineLength := LineLengthAlligning

    if (Left = 1) {
        ; Выравнивание влево
        result := ""
        lines := StrSplit(text, "`n")
        for index, line in lines {
            result.= line
            while (StrLen(result) < lineLength) {
                result.= fillChar
            }
            ; Добавляем перевод строки только если это не последняя строка
            if (index < lines.MaxIndex()) {
                result.= "`n"
            }
        }
    } else if (Center = 1) {
        ; Выравнивание по центру
        result := ""
        lines := StrSplit(text, "`n")
        for index, line in lines {
            spaces := lineLength - StrLen(line)
            leftSpaces := spaces // 2
            rightSpaces := spaces - leftSpaces
            result.= Repeat(fillChar, leftSpaces)
            result.= line
            result.= Repeat(fillChar, rightSpaces)
            ; Добавляем перевод строки только если это не последняя строка
            if (index < lines.MaxIndex()) {
                result.= "`n"
            }
        }
    } else if (Right = 1) {
        ; Выравнивание вправо
        result := ""
        lines := StrSplit(text, "`n")
        for index, line in lines {
            result.= Repeat(fillChar, lineLength - StrLen(line))
            result.= line
            ; Добавляем перевод строки только если это не последняя строка
            if (index < lines.MaxIndex()) {
                result.= "`n"
            }
        }
    }

    ; Вывод результата
    GuiControl,, OutputText, %result%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

; Функция для повторения символа
Repeat(char, count) {
    result := ""
    Loop, %count%
    {
        result.= char
    }
    return result
}

; -------------------------------------------------------------------------------
; PADDING
; -------------------------------------------------------------------------------

AddPadding:
    {
        Gui, Submit, NoHide ; Считывание значений из полей GUI
        padding := ""
        Loop, % PaddingSize
            padding .= PaddingChar ; Создание строки отступа

        ; Разделение входного текста на строки
        ResultText := ""
        Loop, Parse, InputText, `n
        {
            ; Проверка выбранного направления и добавление отступов
            if (PadBoth) ; В обе стороны
                ResultLine := padding . A_LoopField . padding
            else if (PadLeft) ; Только слева
                ResultLine := padding . A_LoopField
            else if (PadRight) ; Только справа
                ResultLine := A_LoopField . padding

            ; Добавление обработанной строки в результат
            ResultText .= ResultLine . "`n"
        }

        GuiControl,, OutputText, %ResultText% ; Отображение результата
        if (AutoInput == 1) {
            Gosub, CopyToInput
        }
        Gosub, UpdateStats
    }
Return

; -------------------------------------------------------------------------------
; LINE REPEAT
; -------------------------------------------------------------------------------

RepeatText:
    ; Get input values
    Gui, Submit, NoHide

    if (RepeatCount = "" || RepeatCount <= 0) {
        RepeatCount := 1
    }

    ; Clear previous output
    OutputText := ""

    ; Split input text into lines
    InputLines := StrSplit(InputText, "`n")

    ; Determine which lines to process
    if (LineModeAll = 1) {
        ; All lines mode
        ProcessLines := InputLines
    } else {
        ; Specific lines mode
        ProcessLines := []
        SpecificLinesList := StrSplit(SpecificLines, ",")
        Loop, % SpecificLinesList.Length() {
            lineRange := StrSplit(SpecificLinesList[A_Index], "-")
            if (lineRange.Length() = 1) {
                lineNum := lineRange[1]
                if (lineNum >= 1 && lineNum <= InputLines.Length()) {
                    ProcessLines.Push(InputLines[lineNum])
                }
            } else if (lineRange.Length() = 2) {
                startLine := lineRange[1]
                endLine := lineRange[2]
                if (startLine >= 1 && endLine <= InputLines.Length() && startLine <= endLine) {
                    Loop, % endLine - startLine + 1 {
                        lineNum := startLine + A_Index - 1
                        ProcessLines.Push(InputLines[lineNum])
                    }
                }
            }
        }
    }

    ; Repeat text based on mode
    if (RepeatModeNewLine = 1) {
        ; New Line mode
        Loop, %RepeatCount%
        {
            for index, line in ProcessLines {
                OutputText .= line

                ; Add separator if it's not the last iteration
                if (index < ProcessLines.Length()) {
                    OutputText .= "`n"
                }
            }

            ; Add separator between repetitions
            if (A_Index < RepeatCount) {
                OutputText .= (SeparatorText != "") ? "`n" . SeparatorText . "`n" : "`n"
            }
        }
    }
    else {
        ; Single Line mode
        Loop, %RepeatCount%
        {
            for index, line in ProcessLines {
                ; If separator is specified, use it between texts
                if (SeparatorText != "") {
                    OutputText .= line . SeparatorText
                } else {
                    OutputText .= line
                }
            }
        }
        ; Remove trailing separator in single line mode
        if (SeparatorText != "") {
            OutputText := RTrim(OutputText, SeparatorText)
        }
    }

    ; Update output field
    GuiControl,, OutputText, %OutputText%
    if (AutoInput == 1) {
        Gosub, CopyToInput
    }
    Gosub, UpdateStats
return

; -------------------------------------------------------------------------------
; COLUMNS
; -------------------------------------------------------------------------------

ConcatenateColumns:
    Gui, Submit, NoHide

    Text1Content := InputText
    Text2Content := SecondColumn
    Separator := ColumnSeparator

    Text1Lines := StrSplit(Text1Content, "`n")
    Text2Lines := StrSplit(Text2Content, "`n")

    CombinedText := ""

    Loop, % Text1Lines.MaxIndex()
    {

        if (A_Index <= Text2Lines.MaxIndex())
            CombinedText .= Text1Lines[A_Index] Separator Text2Lines[A_Index] "`n"
        else
            CombinedText .= Text1Lines[A_Index] "`n"
    }

    if (Text2Lines.MaxIndex() > Text1Lines.MaxIndex())
    {
        Loop, % Text2Lines.MaxIndex()
        {
            if (A_Index > Text1Lines.MaxIndex())
                CombinedText .= Text2Lines[A_Index] "`n"
        }
    }

    CombinedText := RTrim(CombinedText, "`n")

    GuiControl,, OutputText, % CombinedText
Return

; -------------------------------------------------------------------------------
; DATE AND TIME
; -------------------------------------------------------------------------------

InsertDateTime() {
    FormatTime, CurrentDateTime,, hh:mm tt dd/MM/yyyy
    SendInput, %CurrentDateTime%
}

; -------------------------------------------------------------------------------
; EDIT ACTIONS
; -------------------------------------------------------------------------------

Copy() {
    Send, ^c
    return
}

Paste() {
    Send, ^v
    return
}

SelectAll() {
    Send, ^a
    return
}

Cut() {
    Send, ^x
    return
}

Undo() {
    Gosub, PreviousValue
}

Redo() {
    Gosub, NextValue
}

; -------------------------------------------------------------------------------
; RELOAD
; -------------------------------------------------------------------------------

ReloadScript() {
    Reload
}

; -------------------------------------------------------------------------------
; ---------------------------------- HOTKEYS ------------------------------------
; -------------------------------------------------------------------------------

#IfWinActive, Realm
    Ctrl & MButton::
        Edit_ZoomReset(Edit)
        Edit_ZoomReset(Edit1)
    Return
#IfWinActive

#IfWinActive, Realm
    F5::
        InsertDateTime()
    return
#IfWinActive

#IfWinActive, Realm
    Esc::
        WinClose, A
    return
#IfWinActive

; #IfWinActive, Realm
;     ~LButton::
;         CheckMouseOverControls()
;     return
; #IfWinActive

#IfWinActive, Realm
    ~LButton Up::
        UpdateStatusBar(control)
    return
#IfWinActive

#IfWinActive, Realm
    ~^a::
    ~+Left::
    ~+Right::
    ~^+Left::
    ~^+Right::
    ~+Home::
    ~+^Home::
    ~+End::
    ~+^End::
    ~Left::
    ~Right::
    ~Up::
    ~Down::
        Sleep, 100
        UpdateStatusBar(control)
    return
#IfWinActive

#IfWinActive Realm
    ^BackSpace::
        Send ^+{Left}{Del}
    return
#If

#IfWinActive Realm
    ^z::
        Gosub, PreviousValue
    return
#If

#IfWinActive Realm
    ^y::
    ^+z::
        Gosub, NextValue
    return
#If

#If MouseIsOver("Edit1") && WinActive("Realm") && (A_OSVersion ~= "WIN_(7|8|8\.1|VISTA|2003|XP|2000)")
    ^WheelUp::
        ZoomFont("Edit1", 1)
    return

    ^WheelDown::
        ZoomFont("Edit1", -1)
    return
#If

#If MouseIsOver("Edit2") && WinActive("Realm") && (A_OSVersion ~= "WIN_(7|8|8\.1|VISTA|2003|XP|2000)")
    ^WheelUp::
        ZoomFont("Edit2", 1)
    return

    ^WheelDown::
        ZoomFont("Edit2", -1)
    return
#If

#If MouseIsOver("Edit26") && WinActive("Realm") && (A_OSVersion ~= "WIN_(7|8|8\.1|VISTA|2003|XP|2000)")
    +WheelUp::
        ZoomFont("Edit26", 1)
    return

    +WheelDown::
        ZoomFont("Edit26", -1)
    return
#If

#If MouseIsOver("Edit1") || MouseIsOver("Edit2") || MouseIsOver("Edit26")
    ~LButton::
        while GetKeyState("LButton", "P")
        {
            UpdateStatusBar(control)
            Sleep 50
        }
    return
#If

; -------------------------------------------------------------------------------
; ---------------------------------- DIALOGS ------------------------------------
; -------------------------------------------------------------------------------

; -------------------------------------------------------------------------------
; ABOUT
; -------------------------------------------------------------------------------

ShowAboutDialog() {
    global version
    AboutDescription := "Realm " . version "`n`nAdvanced Text Processing Tool`n`nCopyright (c) 2024-2025 finnjest"
    OnMessage(0x6, "WM_ACTIVATE")
    Gui, About:New, +AlwaysOnTop
    Gui, About:-MinimizeBox
    Gui, About:Font, s10, Segoe UI
    ; Gui, About:Font, cGray
    Gui, About:Add, Text, x10 y10 -E0x200  -VScroll , %AboutDescription%
    Gui, Add, Link, x10 y110, <a href="https://github.com/finnjest/realm">https://github.com/finnjest/realm</a>
    Gui, About:Show,, About
}
return

; -------------------------------------------------------------------------------
; ---------------------------------- TOOLTIPS -----------------------------------
; -------------------------------------------------------------------------------

; -------------------------------------------------------------------------------
; CREATING TOOLTIP CONTROL
; -------------------------------------------------------------------------------

InlineHelp:
    Help := New GuiControlTips(HGUI)
    Help.SetDelayTimes(1000, 30000, -1)
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Attach(SBOption, "Stats are shown as: Input Text | Ouput Text or Column 1 | Column 2 | Output Text`nwith Column Mode enabled. Selected text stats are: Chars | Lines | Words")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Attach(OutputToInputOption, "This will copy text from Output to Input.`nOutput field will be cleared.")
    Help.Attach(ClearOption, "Pressing this button will result in clearing all exisiting edit fields.")
    Help.Attach(UndoButton, "Undo")
    Help.Attach(RedoButton, "Redo")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Attach(SROption1, "The whitespace area above the first non-empty line`nwill be trimmed. Including the first leading space.")
    Help.Attach(SROption2, "The whitespace area after the last non-empty line`nwill be trimmed. Including the last trailing space.")
    Help.Attach(SROption3, "All whitespaces at the end of each line will be`ntrimmed. Empty lines wont be affected.")
    Help.Attach(SROption4, "All whitespaces at the beginning of each line `nwill be trimmed. Empty lines wont be affected.")
    Help.Attach(SROption5, "All non single whitespaces between words`nor characters will be removed.")
    Help.Attach(SROption6, "All whitespace occurences will be replaced`nwith a single space.")
    Help.Attach(SROption7, "All whitespace occurences will be removed.")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Attach(LBBOption1, "For each line break group, only the specified amount`nwill be kept.")
    Help.Attach(LBBOption2, "To each line break group only the specified amount`nwill be added.")
    Help.Attach(LBBOption3, "From each line break group the specified amount of line`nbreaks will be removed.")
    Help.Attach(LBBOption4, "All line breaks will be removed from the Input Text.")
    Help.Attach(LBBOption5, "All line break groups will be replaced with spaces.`nThis action is known as 'Joining'.")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Attach(LBEOption1, "Line break will be added before the specified character.")
    Help.Attach(LBEOption2, "Line break will be added instead of the specified character.")
    Help.Attach(LBEOption3, "Line break will be added after the specified character.")
    Help.Attach(LBEOption4, "Line break will be replaced with the specified character.")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    DDLDescription =
    (
1. Delete Lines Containing will remove all lines which contain the specified character.
2. Delete NOT Lines Containing will delete all lines except those that contain the specified character.
3. Delete Before or After will remove everything before or after the specified character.
4. Delete Block will cut out a block of text which borders are the specified characters.
    )
    Help.Attach(DOption1, DDLDescription)
    Help.Attach(DOption2, "The removing will be applied to each line individually, if chosen.`nOtherwise the action is applied to the whole text.")
    Help.Attach(DOption3, "The removing will include the specified character(s).")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Attach(DLOption1, "By default, two lines are considered duplicates, only if they`nare exactly the same, even when it comes to leading `nand trailing whitespaces. This option ignores them.")
    Help.Attach(DLOption2, "By default, all duplicate lines, apart from the very first occurence, are removed.`nThis option replaces duplicates with emply lines.")
    Help.Attach(DLOption3, "By default, the first unique word is kept, only its duplicates are deleted.`nThis option treats first unique occurence as its duplicates.")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Attach(ELOption1, "Deletes only empty lines. Those that basically`nconsist of a line break.")
    Help.Attach(ELOption2, "Deletes both empty and blank lines.")
    Help.Attach(ELOption3, "Deletes only blank lines. Those that are`nnon-empty and consist of whitespace(s).")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Attach(SCREdit, "This will simply delete all occurences of the specified`ncharacter. It only deletes characters, not words.")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Attach(NExcludeEmpty, "Empty lines (those that consist of a line break)`nwill be kept, but excluded from numbering.")
    Help.Attach(NExcludeBlank, "Blank lines (non-empty lines that consist only of whitespaces)`nwill be kept, but excluded from numbering.")
    Help.Attach(NDeleteEmpty, "Empty lines will be excluded from numbering and deleted.")
    Help.Attach(NDeleteBlank, "Blank lines will be excluded from numbering and deleted.")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Attach(SORTOption1, "Reverses the sort order while preserving the selected`nsorting rules (alphabetical, line length or natural).")
    Help.Attach(SORTOption2, "When enabled, sorts text in a case-sensitive way, prioritizing uppercase letters (A-Z)`nbefore lowercase (a-z). Works for alphabetical sorting only.")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Attach(LROption1, "Define how many times the specified line(s) will be repeated.")
    Help.Attach(LROption2, "All lines of Input Text will be repeated.")
    Help.Attach(LROption3, "Only specified lines of Input Text will be repeated.")
    Help.Attach(LROption4, "The character(s) that will separate repeated lines from each other.")
    Help.Attach(LROption5, "All lines of Input Text will become a single string with all line breaks removed.`nThe specified number of repeated lines will be added to them.")
    Help.Attach(LROption6, "The Input Text won't change. The specified number of repeated`nlines will be added after the very last line of Input Text.")
    ; ---------------------------------------------------------------------------------------------------------------------------------------------
    Help.Suspend(True)
return

RemoveToolTip:
    ToolTip
Return

; -------------------------------------------------------------------------------
; EXIT
; -------------------------------------------------------------------------------

GuiClose:
ExitApp
