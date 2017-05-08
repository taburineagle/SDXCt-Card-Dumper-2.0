; MAIN GUI CUSTOMIZATIONS
GUICtrlSendMsg($cardDumpListView, $LVM_SETCOLUMNWIDTH, 0, 50)
GUICtrlSendMsg($cardDumpListView, $LVM_SETCOLUMNWIDTH, 1, 312)
GUICtrlSendMsg($cardDumpListView, $LVM_SETCOLUMNWIDTH, 2, 75)
GUICtrlSetFont($cardDumpListView, 9, 400, 0, "Segoe UI")

GUICtrlSetState($backupCheckbox, $GUI_CHECKED)
GUICtrlSetFont($backupCheckbox, 9, 400, 0, "Segoe UI")
;~ GUICtrlSetState($sleepCheckbox, $GUI_CHECKED) ; un-check sleep checkbox - tooooo many feckups!
GUICtrlSetFont($sleepCheckbox, 9, 400, 0, "Segoe UI")

GUICtrlSetFont($copyButton, 9, 400, 0, "Segoe UI")
GUICtrlSetFont($deleteItemButton, 9, 400, 0, "Segoe UI")
GUICtrlSetFont($startCopyingButton, 9, 800, 0, "Segoe UI")

GUICtrlSetState($deleteItemButton, $GUI_DISABLE)
GUICtrlSetState($startCopyingButton, $GUI_DISABLE)