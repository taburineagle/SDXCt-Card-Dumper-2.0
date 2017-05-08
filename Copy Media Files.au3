#cs
======================================================
=   Card Dumper 2.0! - also (now) known as SDXCt!    =
======================================================
=           © 2014-17 Zach Glenwright                =
=             www.gullswingmedia.com                 =
======================================================

Version History -
1.0  - 4/22/14
		- Original version of SDHC Card Dumper, changed several times between 1.0 - 2.0!!
		- Sat with Poofy Coon - what an awesome raccoon! <3 - but on to the program...
2.0a - 5/4/17
		- Complete re-write of SDHC Card Dumper program using the re-made GUI that I never got around to using (before!)
2.0b - 5/5/17
		- Added ability to rename folder to just base part if the "(" was left
		- Wrote a PID pool watcher, to watch multiple PIDs and then delay after every one is done
		- Wrote the status informer, letting you know how *many* PIDs were still in use
		- Better handling of enable/disable with the main buttons
2.0c  - 5/5/17
		- Wrote procedure to lock buttons out during the copy process
		- Wrote Function to show status of current process (if copying/backing up, etc.)
		- Wrote backing up procedure and sleep procedure
2.0d  - 5/8/17
		- Due to a major DUUUUUUUUUUUUUUHHHHH had to write quick procedure to warn about overwriting anything.  THANK GOD FOR BACKUPS!!!
2.0e  - 5/8/17
		- Tweaked re-dating process in file naming procedure to ask whether or not a Raccoon session started during the night before
		- Tweaked warning message for dumping files to an already existing directory, and asks now if you want to continue dumping the files!
		- Wrote procedure to open the BC log after copying to the SDHC Card Dumps directory - now you can see instantly if there was a problem somewhere

Things to do~!
		- Some form of INI file, to track output path (maybe hold SHIFT down to set a new path?) and backup/sleep options
#ce

; SYSTEM INCLUDES
#include <File.au3>
#include <Array.au3>
#include <Date.au3>
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <ListViewConstants.au3>
#include <WindowsConstants.au3>
#include <GuiListView.au3>

; CUSTOM MODULE INCLUDES

; GLOBALS AND CONSTANTS
Const $progTitle = "SDXCt! 2.0d by Zach Glenwright"
Const $MPC_HC_BIN = "C:\Program Files\MPC-HC\mpc-hc64.exe" ; The path to MPC-HC to preview the folder
Const $SDHCBasePath = "L:\SDHC Card Dumps"
Const $BC_Logs_Path = "C:\BC\Logs"

; BUILD THE GUI
$mainWindow = GUICreate($progTitle, 442, 268, -1, -1)

$cardDumpListView = GUICtrlCreateListView("Drive|Folder Name|Drive Type", 0, 0, 441, 177)
$backupCheckbox = GUICtrlCreateCheckbox(" Back up the SDHC Card Dumps directory when finished copying files", 28, 182, 401, 25)
$sleepCheckbox = GUICtrlCreateCheckbox(" Put the computer to sleep when finished dumping files / backup", 28, 202, 369, 25)
$copyButton = GUICtrlCreateButton("Add new card...", 10, 232, 121, 25)
$deleteItemButton = GUICtrlCreateButton("Delete item", 140, 232, 137, 25)
$startCopyingButton = GUICtrlCreateButton("Start Copying", 285, 232, 145, 25, $BS_DEFPUSHBUTTON)

#include 'includes\custom\mainGUI_Custom.au3'

GUISetState(@SW_SHOW)

While 1
	$nMsg = GUIGetMsg()

	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $copyButton
			addNewDrive()
		Case $deleteItemButton
			$currentSelection = GUICtrlRead($cardDumpListView)
			GUICtrlDelete($currentSelection)
		Case $startCopyingButton
			setStatus("Initializng copy processes...")
			enableButtons($GUI_DISABLE)

			$currentListCount = _GUICtrlListView_GetItemCount($cardDumpListView)
			Local $PID_List[0]

			For $i = 0 to ($currentListCount - 1)
				$copyFrom = _GUICtrlListView_GetItemText($cardDumpListView, $i, 0)
				$copyTo = $SDHCBasePath & "\" & _GUICtrlListView_GetItemText($cardDumpListView, $i, 1)

				If FileExists($copyTo) = False Then
					DirCreate($copyTo)
					$goAhead = 6
				Else
					$goAhead = MsgBox(20, "Directory already exists!", "The directory you chose to dump files to already exists in the" & @CRLF & "SDHC Card Dumps folder:" & @CRLF & @CRLF & _GUICtrlListView_GetItemText($cardDumpListView, $i, 1) & @CRLF & @CRLF & "Please check the date to make sure that you're not overwriting anything!  Do you want to go ahead and copy to this directory?")
				EndIf

				If $goAhead = 6 Then
					Sleep(500)
					$currentPID = ShellExecute("C:\Program Files\Beyond Compare 4\BCompare.exe", '"@C:\BC\BC_CopyCards_New.txt" "' & $copyFrom & '" "' & $copyTo & '"')
					Sleep(2500)

					_ArrayAdd($PID_List, $currentPID)
				EndIf
			Next

			If UBound($PID_List) > 0 Then
				ProcessesExistWait($PID_List, "copying", 2500)
				Dim $PID_List[0]

				openBCLog()

				If GUICtrlRead($backupCheckbox) = 1 Then
					setStatus("Initializng backup process...")
					$currentPID = ShellExecute("C:\Program Files\Beyond Compare 4\BCompare.exe", '"@C:\BC\BC.txt"')
					Sleep(2500)

					_ArrayAdd($PID_List, $currentPID)
					ProcessesExistWait($PID_List, "backup", 5000)
				EndIf

				If GUICtrlRead($sleepCheckbox) = 1 Then
					setStatus("Initializng sleep process...")
					Sleep(2500)
					Shutdown(32)
				EndIf
			EndIf

			setStatus("")
			enableButtons($GUI_ENABLE)
	EndSwitch

	; CHECK TO SEE IF YOU HAVE AN ITEM SELECTED - IF SO, THEN ACTIVATE THE DELETE ITEM BUTTON
	$currentSelection = GUICtrlRead($cardDumpListView)

	If $currentSelection <> 0 Then ; if you have something selected
		If GUICtrlGetState($deleteItemButton) = 144 Then ; if the delete button is disabled
			GUICtrlSetState($deleteItemButton, $GUI_ENABLE) ; enable the delete button
		EndIf
	Else ; if you have no items selected
		If GUICtrlGetState($deleteItemButton) = 80 Then ; if the delete button is enabled
			GUICtrlSetState($deleteItemButton, $GUI_DISABLE) ; disable the delete button
		EndIf
	EndIf

	; CHECK TO SEE IF YOU HAVE ITEMS IN THE LIST VIEW - IF SO, THEN ACTIVATE THE START COPYING BUTTON
	$currentListCount = _GUICtrlListView_GetItemCount($cardDumpListView)

	If $currentListCount > 0 Then ; if you have more than one item in the queue
		If GUICtrlGetState($startCopyingButton) = 144 Then ; and the start copying button is disabled
			GUICtrlSetState($startCopyingButton, $GUI_ENABLE) ; enable the start copying button
		EndIf
	Else ; if you have nothing in the queue
		If GUICtrlGetState($startCopyingButton) = 80 Then ; and the start copying button is enabled
			GUICtrlSetState($startCopyingButton, $GUI_DISABLE) ; disable the start copying button
		EndIf
	EndIf

	Sleep(50) ; short bit o' rest to save on processor use
WEnd

Func enableButtons($onOrOff)
	GUICtrlSetState($copyButton, $onOrOff)
	GUICtrlSetState($deleteItemButton, $onOrOff)
	GUICtrlSetState($startCopyingButton, $onOrOff)
EndFunc

Func openBCLog()
	$currentDate = StringSplit(_NowDate(), "/")
	$logFilePath = $BC_Logs_Path & "\Log_CopyCards " & $currentDate[3] & "-" & StringFormat("%02d", $currentDate[1]) & "-" & StringFormat("%02d", $currentDate[2]) & ".txt"
	ShellExecute($logFilePath)
EndFunc

Func ProcessesExistWait($PID_List, $processType, $waitAfter)
	$isDone = False

	While $isDone = False
		$totalValue = 0 ; reset the counter to 0 to start the count off (hopefully this will work after the While condition)

		For $i = 0 to UBound($PID_List) - 1
			If ProcessExists($PID_List[$i]) Then
				$totalValue = $totalValue + 1
			EndIf
		Next

		If $totalValue > 0 Then
			If $processType = "copying" Then
				If UBound($PID_List) > 1 Then
					$statusString = UBound($PID_List) & " copy processes launched / " & $totalValue & " still running"
				Else
					$statusString = "1 copy process launched / " & $totalValue & " still running"
				EndIf
			Else
				$statusString = "Backup process running"
			EndIf

			setStatus($statusString & " ..")
			Sleep(200)
			setStatus($statusString & " ....")
			Sleep(200)
			setStatus($statusString & " ......")
			Sleep(200)
		Else
			If $processType = "copying" Then
				If UBound($PID_List) > 1 Then
					setStatus("Copy processes finished - waiting for program...")
				Else
					setStatus("Copy process finished - waiting for program...")
				EndIf
			Else
				setStatus("Backup process finished - waiting for program...")
			EndIf

			$isDone = True
			Sleep($waitAfter)
		EndIf
	Wend
EndFunc

Func setStatus($theStatus)
	If $theStatus <> "" Then
		WinSetTitle($mainWindow, "", "SDXCt! 2.0d - " & $theStatus)
	Else
		WinSetTitle($mainWindow, "", $progTitle)
	EndIf
EndFunc

Func addNewDrive()
	$theFolder = FileSelectFolder("Choose drive to dump media files from", "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}")

	If $theFolder <> "" Then
		If FileExists($theFolder & "\MISC") Then ; check MISC first, because GoPro drives *also* have DCIM folders
			$theType = "GoPro"
			$theFiles = _FileListToArrayRec($theFolder, "*.mp4", 1, 1, 1, 2) ; The drive is a GoPro drive
		ElseIf FileExists($theFolder & "\DCIM") Then ; if the drive has a DCIM, but *no* MISC, then it's not a GoPro drive!
			$theType = "G30"
			$theFiles = _FileListToArrayRec($theFolder, "*.mp4", 1, 1, 1, 2) ; The drive is a G30 drive
		ElseIf FileExists($theFolder & "\PRIVATE\M4ROOT") Then
			$theType = "X3000 4K"
			$theFiles = _FileListToArrayRec($theFolder, "*.mp4", 1, 1, 1, 2) ; The drive is a X3000 drive
		ElseIf FileExists($theFolder & "\AVCHD") Then
			$theType = "AVCHD"
			$theFiles = _FileListToArrayRec($theFolder, "*.m*|*.mpl", 1, 1, 1, 2) ; The drive is an AVCHD (CX550V) drive
		EndIf

		$MPC_PID = ShellExecute($MPC_HC_BIN, $theFiles[1]) ; launch the first file on that drive
		Sleep(1200)

		$folderName = InputBox("Folder Name", "What do you want to call this folder?", getPossibleFile($theType, $theFiles[1]), "", 250, 125)

		ProcessClose($MPC_PID)

		If $folderName <> "" Then
			If StringRight($folderName, 1) = "(" Then
				$folderName = StringTrimRight($folderName, 2) ; if you didn't list an angle, it will take that angle part off
			Else
				$folderName = $folderName & " Shot)" ; if you did list an angle, add the phrase Shot after it and close the paren
			EndIf

			GUICtrlCreateListViewItem($theFolder & "|" & $folderName & "|" & $theType, $cardDumpListView)
		EndIf
	EndIf
EndFunc

Func getPossibleFile($theType, $theFirstFile)
	$fileTime = FileGetTime($theFirstFile)

	Switch $theType
		Case "G30", "AVCHD"
			$possibleTitle = "Raccoons "
		Case "GoPro"
			$possibleTitle = "Sqys! "
		Case "X3000 4K"
			$isSquirrelDrive = MsgBox(4, "Squirrel file?", "Is this drive a Squirrel project dump?")

			If $isSquirrelDrive = 6 Then
				$possibleTitle = "Sqys! "
			Else
				$possibleTitle = "Raccoons "
			EndIf
	EndSwitch

	If $possibleTitle = "Raccoons " And $fileTime[3] > 12 And $fileTime[3] <= 23 Then ; if the first file of the card is dated between 12pm and 12am and is a Raccoons file
		$isDayOfProject = MsgBox(36, "Project Date", "The original date for the first file of this card dump is:" & @CRLF & @CRLF & _
		$fileTime[1] & "-" & $fileTime[2] & "-" & $fileTime[0] & " " & $fileTime[3] & ":" & $fileTime[4] & ":" & $fileTime[5] & @CRLF & @CRLF & _
		"Was this project started before midnight?  Hit yes to save the date as the original start date instead of the day before.")

		If $isDayOfProject = 6 Then
			$raccoonDecrement = 0 ; if you say "YEHS!" then it doesn't take a day off for the file
		Else
			$raccoonDecrement = 1 ; if your first file is actually from midnight,
		EndIf
	Else ; the hour is after midnight, so it's the night before's session
		$raccoonDecrement = 1 ; takes one day off of the current first file date for Raccoons card dumps
	EndIf

	If $possibleTitle = "Raccoons " Then
		$possibleTitle = $possibleTitle & $fileTime[1] & "-" & StringFormat("%02d", $fileTime[2] - $raccoonDecrement) & "-" & StringRight($fileTime[0], 2) & " ("
	ElseIf $possibleTitle = "Sqys! " Then
		$possibleTitle = $possibleTitle & $fileTime[1] & "-" & StringFormat("%02d", $fileTime[2]) & "-" & StringRight($fileTime[0], 2) & " ("
	EndIf

	Return $possibleTitle
EndFunc