#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "P2ESync.ahk"

; Globals
P2E_Title := "Path2Ease"
P2E_Version := "1.0"
Window := {
    Width: 620,
    Height: 500,
}
Window_Tab := { 
    Width: 160,
    TabLeftPadding: 10,
    TabPaddingTop: 125,
    TabX0: "x" 160 + 10, ; == Tab.Width + LeftPadding
    TabY0: "y" 10, ; = TopPadding
    TabW: "w" Window.Width - 160, ; = Window.Width - Tab.Width
    Label: [ "🔥 AutoFire", "👣 AutoMove", "-", "🔧 Settings", "👤 Profiles", "ℹ️ About (Wip)", "❓ Help (Wip)"],
    Spacer: "   ",
    HoverWidth: 5
}

Window_ToolTipTimerShow := 250
Window_ToolTipTimerCheck := 100
;Window_FocusChangeTimeout := 85

Icon_FileName := "Shell32.dll"
Icon_Number := 13
Text_Font := "Segoe UI"
Color_Gray := "c4a4a4a"
Color_Black := "c000000"
Color_Blue := "c0375d2"
Color_DBlue := "c0375d2"
Color_TBlue := "c9ad2ff"
Color_White := "cCCE8FF"
Color_DWhite := "cF3F3F3"

Image_CircledQuestionmark := "./Ressources/CircledQuestionMark.png"
Image_Floppy := "./Ressources/Floppy.png"
Image_ArrowClockwise := "./Ressources/ArrowClockwise.png"
Image_VolumeDown := "./Ressources/VolumeDown.png"
Image_VolumeMuted := "./Ressources/VolumeMuted.png"

Image_Logo := "./Ressources/P2ELogo.png"
Icon_Logo := "./Ressources/P2ELogo.ico"

Text_Pointer := "⎆ "
Text_UnitMs := " ms"
TextSize_Big := "s13"
TextSize_Normal := "s11"
Text_AddIcon := "✱ "
Text_RmvIcon := "🗑 "
Text_EditIcon := "🖍 "

Application := { Name: P2E_Title, Version: P2E_Version }
Window := { Width: Window.Width, Height: Window.Height, Title: Application.Name }
AutoFire_TableColumns := ["Name", "Hotkey", "Cooldown", "Delay"]

; Tray-Icon
Tray := A_TrayMenu
TraySetIcon(Icon_Logo)
TrayTip(Application.Name)
Tray.Delete("1&") ; = Open
Tray.Delete("1&") ; = Help
Tray.Delete("4&") ; = Edit Script
Tray.Delete("5&") ; = Suspend
Tray.Delete("5&") ; = ---
Tray.Delete("5&") ; = Exit
Tray.Insert("1&", "Open GUI", (*) => FindGui())
Tray.Add("Reload", Reload)
Tray.Add("Hide", (*) => BaseGui.Destroy())
Tray.Add("Exit", OnExitTray)
Tray.ClickCount := 1
Tray.Default := "Open GUI"

FindOrHide(*)
{
    if WinExist(Application.Name) && WinExist("ahk_class AutoHotkeyGUI")
    {
        WinHide(Application.Name)
    }
    else
    {
        FindGui()
    }
}

FindGui(*)
{
    global Application
 
    if WinExist(Application.Name) && WinExist("ahk_class AutoHotkeyGUI")
    {
        WinActivate()
    }
    else
    {
        DisplayGui()
    }
}

/* # Static refs */

Tab := unset
BaseGui := unset
VolumeDownPic := unset
VolumeMutedPic := unset
BeepChk := unset
PopUp_AutoFire := {}

; Builds and displays the gui
DisplayGui()
{
    global Window
    global Tab
    global BaseGui
    global VolumeDownPic
    global VolumeMutedPic

    ; Window-Events
    OnMessage(0x0020, WM_SETCURSOR)
    OnMessage(0x02A2, WM_NCMOUSELEAVE)

    ; Setup Gui
    BaseGui := Gui()
    BaseGui.OnEvent("Close", OnExit)
    BaseGui.OnEvent("Escape", OnExit)
    BaseGui.OnEvent("Size", OnResize)
    BaseGui.Opt("+LastFound +Resize MinSize" Window.Width "x" Window.Height)
    BaseGui.SetFont("" Color_Gray, Text_Font)
    BaseGui.BackColor := "FFFFFF"
    BaseGui.Title := Window.Title
 
    ; Setup Tabs
    TabBg := BaseGui.AddText("x0 y0 w" Window_Tab.Width " h9999 Section Background" Color_DWhite)
    TabBg.BottomDistance := 0
    LogoBg := BaseGui.AddPicture("x28 y10 h100 w100 BackgroundTrans", Image_Logo)
    Tab := BaseGui.Add("Tab2", "x-999999 y-999999 -Wrap +Theme")
    BaseGui.Tabs := Tab
    Tab.UseTab()

    ; TabHover
    BaseGui.TabPicSelect := BaseGui.AddText("x0 y" (Window_Tab.TabPaddingTop) " w" Window_Tab.HoverWidth " h32 Background" Color_Blue) ; Using a text control to create a colored rectangle
    BaseGui.TabPicHover := BaseGui.AddText("x0 y" (Window_Tab.TabPaddingTop) " w" Window_Tab.HoverWidth " h32 Background" Color_TBlue " Hidden") ; Using a text control to create a colored rectangle

    ; Setup entries
    Loop Window_Tab.Label.Length { 
        Tab.Add([Window_Tab.Label[A_Index]])
        If (Window_Tab.Label[A_Index] = "-") {
            Continue
        }
        textMenuItem := BaseGui.AddText("x0 y" (32*(A_Index-1) + Window_Tab.TabPaddingTop) " h32 w" Window_Tab.Width " +0x200 BackgroundTrans vMenuItem" . A_Index, Window_Tab.Spacer Window_Tab.Label[A_Index])
        textMenuItem.SetFont(TextSize_Big " " Color_Gray, Text_Font) ; Set font
        textMenuItem.OnEvent("Click", OnTabClick)
        textMenuItem.Index := A_Index

        ; Highlight the chosen one
        if (A_Index = 1) {
            textMenuItem.SetFont(Color_Blue " " TextSize_Big)
            BaseGui.ActiveTab := textMenuItem
            ;BaseGui.TabTitle.Value := trim(textMenuItem.text)
        }
    }

    ; Add tab-actions
    SavePic := BaseGui.AddPicture("xp33 yp5 h18 w18 BackgroundTrans", Image_Floppy)
    SavePic.BottomDistance := 12
    SavePic.OnEvent("Click", (*) => SaveSettings())

    ReloadPic := BaseGui.AddPicture("xp33 yp25 h20 w20 BackgroundTrans", Image_ArrowClockwise)
    ReloadPic.BottomDistance := 10
    ReloadPic.OnEvent("Click", (*) => Reload())

    VolumeDownPic := BaseGui.AddPicture("xp33 yp25 h24 w24 BackgroundTrans", Image_VolumeDown)
    VolumeDownPic.BottomDistance := 8
    VolumeDownPic.Visible := P2ESettings.General.Beep
    VolumeDownPic.OnEvent("Click", (*) => OnSoundChange(false))

    VolumeMutedPic := BaseGui.AddPicture("xp0 yp25 h24 w24 BackgroundTrans", Image_VolumeMuted)
    VolumeMutedPic.BottomDistance := 8
    VolumeMutedPic.Visible := !P2ESettings.General.Beep
    VolumeMutedPic.OnEvent("Click", (*) => OnSoundChange(true))

    ; Populate all Tabs
    /*try
    {*/
        SetupTab_AutoFire(1)
        SetupTab_AutoMove(2)
        SetupTab_Settings(4)
        SetupTab_Profiles(5)
        MakeUnderConstructionTab(6)
        MakeUnderConstructionTab(7)
        MakeUnderConstructionTab(8)
    /*}
    catch 
    {}*/

    ; Finally show it
    BaseGui.Show(" w" Window.Width " h" Window.Height "")

    ; References
    AutoFireVList := unset

    /* # Nested views # */

    SetupTab_Settings(tabIdx)
    {
        global BeepChk 

        ; Render
        Tab.UseTab(tabIdx)

        ; General
        generalH := BaseGui.AddText(Window_Tab.TabX0 " " Window_Tab.TabY0 " " Window_Tab.TabW " h32", Text_Pointer "General:")
        generalH.SetFont(Color_DBlue " bold " TextSize_Big, Text_Font)

        rndDesc := BaseGui.AddText("xp60 yp28 h32 w120", "Randomness:")
        rndDesc.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        rndEdit := BaseGui.AddEdit("xp100 yp0 w70 h23 number", P2ESettings.General.Randomness)
        rndEdit.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        rndUnit := BaseGui.AddText("yp0 xp80 h30 w80", " in ms")
        rndUnit.SetFont(Color_Gray " " TextSize_Normal, Text_Font)

        exeDesc := BaseGui.AddText("x" (Window_Tab.Width + Window_Tab.TabLeftPadding + 10) " yp28 h32 w150", "Targeted executable:")
        exeDesc.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        exeEdit := BaseGui.AddEdit("xp150 yp0 w160 h23", P2ESettings.General.TargetedExe)
        exeEdit.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        exeEdit.OnEvent("LoseFocus", (guiCtrlObj, info) => P2ESettings.General.TargetedExe := guiCtrlObj.Value)
        
        ; Behavior
        generalH := BaseGui.AddText(Window_Tab.TabX0 " yp45 " Window_Tab.TabW " h32", Text_Pointer "Behavior:")
        generalH.SetFont(Color_DBlue " bold " TextSize_Big, Text_Font)
        
        mStartChk := BaseGui.AddCheckbox("xp15 yp24 h32 w160", "Start minimized")
        mStartChk.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        mStartChk.Value := P2ESettings.General.StartMinimized
        mStartChk.OnEvent("Click", (guiCtrlObj, info) => P2ESettings.General.StartMinimized := guiCtrlObj.Value)

        mEndChk := BaseGui.AddCheckbox("xp0 yp24 h32 w160", "Close to systemtray")
        mEndChk.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        mEndChk.Value := P2ESettings.General.CloseToTray
        mEndChk.OnEvent("Click", (guiCtrlObj, info) => P2ESettings.General.CloseToTray := guiCtrlObj.Value)

        BeepChk := BaseGui.AddCheckbox("xp0 yp24 h32 w160", "Play status-beep")
        BeepChk.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        BeepChk.Value := P2ESettings.General.Beep
        BeepChk.OnEvent("Click", (guiCtrlObj, info) => OnSoundChange(guiCtrlObj.Value))
    }

    SetupTab_AutoFire(tabIdx)
    {
        global P2ESettings
        global AutoFireVList
        global AutoFire_TableColumns

        ; Render
        Tab.UseTab(tabIdx)

        ; Config
        autoFireTxtCfg := BaseGui.AddText(Window_Tab.TabX0 " " Window_Tab.TabY0 " " Window_Tab.TabW " h32", Text_Pointer "Configuration:")
        autoFireTxtCfg.SetFont(Color_DBlue " bold " TextSize_Big, Text_Font)
        autoFireCkUse := BaseGui.AddCheckbox("xp15 yp24 h32 " Window_Tab.TabW, "Enable AutoFire")
        autoFireCkUse.Value := GetActiveProfile().AutoFire.Enable
        autoFireCkUse.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoFireCkUse.OnEvent("Click", (guiCtrlObj, info) => GetActiveProfile().AutoFire.Enable := guiCtrlObj.Value)

        ; Options
        autoFireTxtCfg := BaseGui.AddText(Window_Tab.TabX0 " yp36 h32 " Window_Tab.TabW , Text_Pointer "Options:")
        autoFireTxtCfg.SetFont(Color_DBlue " bold " TextSize_Big, Text_Font)
        autoFireDescBoundTo := BaseGui.AddText("xp35 yp28 h32 w120", "BoundTo-Hotkey:")
        autoFireDescBoundTo.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoFireEditBoundTo := BaseGui.AddEdit("xp125 yp0 w120 h23", GetActiveProfile().AutoFire.BoundTo)
        autoFireEditBoundTo.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoFireEditBoundTo.OnEvent("LoseFocus", (guiCtrlObj, info) => GetActiveProfile().AutoFire.BoundTo := guiCtrlObj.Value)
        
        autoFireHelpBoundTo := BaseGui.AddPicture("xp125 yp1 h20 w20", Image_CircledQuestionmark)
        autoFireHelpBoundTo.Tooltip := "The hotkey to bind the AutoFire-Hotkeys too.`n`nIf it gets pressed, all AutoFire-Hotkeys will be immediately evaluated`nand fired in accordance to their time schedule.`n`nDoubleclick to open the AHK-Documentation with all available hotkeys."
        autoFireHelpBoundTo.OnEvent("DoubleClick", OpenAutoHotkeyV2Doc)
        autoFireDescToggle := BaseGui.AddText("x" Window_Tab.Width + Window_Tab.TabLeftPadding + 48 " yp28 h32 w120", "Toggle-Hotkey:")
        autoFireDescToggle.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoFireEditToggle := BaseGui.AddEdit("xp112 yp0 w120 h23", GetActiveProfile().AutoFire.Toggle)
        autoFireEditToggle.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoFireEditToggle.OnEvent("LoseFocus", (guiCtrlObj, info) => GetActiveProfile().AutoFire.Toggle := guiCtrlObj.Value)
        autoFireHelpToggle := BaseGui.AddPicture("xp125 yp2 h20 w20", Image_CircledQuestionmark)
        autoFireHelpToggle.Tooltip := "Toggles the usage of the hotkeys independently.`n`n-  ON : BoundTo-Hotkey will be considered `n- OFF : BoundTo-Hotkey will be ignored`n`nDoubleclick to open the AHK-Documentation with all available hotkeys"
        autoFireHelpToggle.OnEvent("DoubleClick", OpenAutoHotkeyV2Doc)

        ; ListView
        autoFireTxtHk := BaseGui.AddText(Window_Tab.TabX0 " yp35 h32 " Window_Tab.TabW, Text_Pointer "Hotkeys:")
        autoFireTxtHk.SetFont(Color_DBlue " bold " TextSize_Big, Text_Font)
        AutoFireVList := BaseGui.AddListView("x" Window_Tab.Width + Window_Tab.TabLeftPadding + 15 " yp28 " Window_Tab.TabW " Checked -Multi NoSort NoSortHdr -WantF2 -LV0x10 Grid", AutoFire_TableColumns)
        AutoFire_ListView_Draw()
        AutoFireVList.LeftMargin := "20"
        AutoFireVList.BottomMargin := "50"
        AutoFireVList.OnEvent("ItemCheck", (guiCtrlObj, idx, checked) => GetActiveProfile().AutoFire.Hotkeys[idx].Active := checked)
        AutoFireVList.OnEvent("DoubleClick", OnDoubleClick_AutoFireVList)
        
        ; Buttons
        autoFireBtnAdd := BaseGui.AddButton("x" (Window.Width - 330) " w120 h28 vButtonCAdd", Text_AddIcon "Add")
        autoFireBtnAdd.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoFireBtnAdd.LeftDistance := 30 + 2 * 135
        autoFireBtnAdd.BottomDistance := 10
        autoFireBtnEdit := BaseGui.AddButton("x" (Window.Width - 300) " w120 h28 vButtonEdit", Text_EditIcon "Edit")
        autoFireBtnEdit.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoFireBtnEdit.LeftDistance := 30 + 1 * 135
        autoFireBtnEdit.BottomDistance := 10
        autoFireBtnRmv := BaseGui.AddButton("x" (Window.Width - 90) " w120 h28 vButtonRemove", Text_RmvIcon "Remove")
        autoFireBtnRmv.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoFireBtnRmv.LeftDistance := 30
        autoFireBtnRmv.BottomDistance := 10

        ; Events
        autoFireBtnAdd.OnEvent("Click", OnClick_AddAutoFire)
        autoFireBtnEdit.OnEvent("Click", OnClick_EditAutoFire)
        autoFireBtnRmv.OnEvent("Click", OnClick_RemoveAutoFire)

        AutoFire_ListView_Draw()
        {
            global AutoFireVList
            global P2ESettings
            global Text_UnitMs
            
            ; Spacer
            MinusSpacer := " - "
            WsSpacer := " "
            
            ; Styling
            AutoFireVList.SetFont(TextSize_Normal " " Color_Black, Text_Font)

            ; Stop drawing
            AutoFireVList.Opt("-Redraw")
    
            ; Clear
            if (AutoFireVList.GetCount() != 0)
            {
                AutoFireVList.Delete()
            }

            ; Loop
            for hotkey in GetActiveProfile().AutoFire.Hotkeys {
                options := "Checked"
                if (hotkey.Active == 1)
                {
                    options := "-" options
                }
                AutoFireVList.Add(options, 
                    WsSpacer hotkey.Name WsSpacer,
                    WsSpacer hotkey.Hotkey WsSpacer,
                    WsSpacer hotkey.Cooldown Text_UnitMs WsSpacer,
                    WsSpacer hotkey.Delay Text_UnitMs WsSpacer
                )
            }
            
            ; Add FixtureHeader
            AutoFireVList.Add("", 
                MinusSpacer AutoFire_TableColumns[1] MinusSpacer MinusSpacer MinusSpacer MinusSpacer, 
                MinusSpacer AutoFire_TableColumns[2] MinusSpacer, 
                MinusSpacer AutoFire_TableColumns[3] MinusSpacer, 
                MinusSpacer AutoFire_TableColumns[4] MinusSpacer
            )
            AutoFireVList.ModifyCol  ; Auto-size each column to fit its contents.
            AutoFireVList.Delete(AutoFireVList.GetCount())
    
            AutoFireVList.Opt("+Redraw")
        }

        OnClick_AddAutoFire(*)
        {
            global PopUp_AutoFire
            
            PopUp_AutoFire := {
                Mode_Add: 1,
                Mode_Edit: 0,
                Idx: 0,
                Data: {
                    Active: 1,
                    Name: "Ability X",
                    Hotkey: "^+F1",
                    Cooldown: "1000",
                    Delay: "0"
                }
            }
            AutoFire_DisplayPopup()
        }
        
        OnClick_EditAutoFire(*)
        {
            global AutoFireVList
            global P2ESettings
            global PopUp_AutoFire
    
            selectionIdx := AutoFireVList.GetNext()
            if (selectionIdx == 0)
            {
                warnMsg := MsgBox("You haven't selected an entry.", "Warning", "OK Icon! 0x1000")
            }
            else
            {
                hotkey := GetActiveProfile().AutoFire.Hotkeys[selectionIdx]
                PopUp_AutoFire := {
                    Mode_Add: 0,
                    Mode_Edit: 1,
                    Idx: selectionIdx,
                    Data: {
                        Active: hotkey.Active,
                        Name: hotkey.Name,
                        Hotkey: hotkey.Hotkey,
                        Cooldown: hotkey.Cooldown,
                        Delay: hotkey.Delay
                    }
                }
                AutoFire_DisplayPopup()
            }
        }

        OnClick_RemoveAutoFire(*)
        {
            global AutoFireVList
            global P2ESettings
            global PopUp_AutoFire
    
            selectionIdx := AutoFireVList.GetNext()
            if (selectionIdx == 0)
            {
                warnMsg := MsgBox("You haven't selected an entry.", "Warning", "OK Icon! 0x1000")
            }
            else
            {
                if ("Yes" == MsgBox("Are you sure to delete Hotkey '" GetActiveProfile().AutoFire.Hotkeys[selectionIdx].Name "' ?", "Confirmation required", "Icon? YesNo"))
                {
                    GetActiveProfile().AutoFire.Hotkeys.RemoveAt(selectionIdx, 1)
                    AutoFire_ListView_Draw()
                }
            }
        }

        OnDoubleClick_AutoFireVList(*)
        {
            global AutoFireVList
    
            selectionIdx := AutoFireVList.GetNext()
            if (selectionIdx != 0)
            {
                OnClick_EditAutoFire()
            }
        }
        
        AutoFire_DisplayPopup(*)
        {
            global P2ESettings
            global PopUp_AutoFire
    
            ; Window
            PopUpWindow := {
                Width: 400,
                Height: 320
            }
            
            ; Window-Events
            OnMessage(0x0020, WM_SETCURSOR)
            OnMessage(0x02A2, WM_NCMOUSELEAVE)

            ; Setup Gui
            AutoFirePopUp_Gui := Gui()
            AutoFirePopUp_Gui.OnEvent("Escape", PopUpOnExit)
            AutoFirePopUp_Gui.OnEvent("Close", PopUpOnExit)
            AutoFirePopUp_Gui.OnEvent("Size", OnResize)
            AutoFirePopUp_Gui.Opt("+LastFound AlwaysOnTop -Resize -MaximizeBox -MinimizeBox MinSize" PopUpWindow.Width "x" PopUpWindow.Height)
            AutoFirePopUp_Gui.SetFont("" Color_Gray, Text_Font)
            AutoFirePopUp_Gui.BackColor := "FFFFFF"
            
            ; Buttons
            if (PopUp_AutoFire.Mode_Add)
            {
                AutoFirePopUp_Gui.Title := "Add a new AutoFire-Hotkey"
                createBtn := AutoFirePopUp_Gui.AddButton("w80 h28", Text_AddIcon "Add")
                createBtn.SetFont(TextSize_Normal, Text_Font)
                createBtn.BottomDistance := 15
                createBtn.LeftDistance := 115
                createBtn.OnEvent("Click", OnPopUpClick_AddAutoFire)
            }
            else ;if (PopUp_AutoFire.Mode_Edit)
            {
                AutoFirePopUp_Gui.Title := "Edit AutoFire"
                editBtn := AutoFirePopUp_Gui.AddButton("w80 h28", Text_EditIcon "Edit")
                editBtn.SetFont(TextSize_Normal, Text_Font)
                editBtn.BottomDistance := 15
                editBtn.LeftDistance := 115
                editBtn.OnEvent("Click", OnPopUpClick_EditAutoFire)
            }
            cancelBtn := AutoFirePopUp_Gui.AddButton("w80 h28", "Cancel")
            cancelBtn.SetFont(TextSize_Normal, Text_Font)
            cancelBtn.BottomDistance := 15
            cancelBtn.LeftDistance := 25
            cancelBtn.OnEvent("Click", OnPopUpClick_CancelAutoFire)
            
            ; Inputs
            nameDesc := AutoFirePopUp_Gui.AddText("ym10 xm45 h30 w100", "Name:")
            nameDesc.SetFont(Color_Black " " TextSize_Normal, Text_Font)
            nameEdit := AutoFirePopUp_Gui.AddEdit("yp0 xp50 h23 w220")
            nameEdit.SetFont(Color_Black " " TextSize_Normal, Text_Font)
            nameEdit.Value := PopUp_AutoFire.Data.Name
            nameEditHelp := AutoFirePopUp_Gui.AddPicture("xp225 yp2 h20 w20", Image_CircledQuestionmark)
            nameEditHelp.Tooltip := "The name to use for this AutoFire-Hotkey."
            
            hotkeyDesc := AutoFirePopUp_Gui.AddText("yp45 xm40 h30 w100", "Hotkey:")
            hotkeyDesc.SetFont(Color_Black " " TextSize_Normal, Text_Font)
            hotkeyEdit := AutoFirePopUp_Gui.AddEdit("yp0 xp55 h23 w220")
            hotkeyEdit.SetFont(Color_Black " " TextSize_Normal, Text_Font)
            hotkeyEdit.Value := PopUp_AutoFire.Data.Hotkey
            hotkeyEditHelp := AutoFirePopUp_Gui.AddPicture("xp225 yp2 h20 w20", Image_CircledQuestionmark)
            hotkeyEditHelp.Tooltip := "The AutoFire-Hotkey to be triggered within the specifications.`n`nDoubleclick to open the AHK-Documentation with all available hotkeys."
            hotkeyEditHelp.OnEvent("DoubleClick", OpenAutoHotkeyV2Doc)

            activeDesc := AutoFirePopUp_Gui.AddText("yp45 xm40 h30 w100", "Active:")
            activeDesc.SetFont(Color_Black " " TextSize_Normal, Text_Font)
            activeCBox := AutoFirePopUp_Gui.AddCheckbox("ym102 xp55 h30 w100")
            activeCBox.Value := PopUp_AutoFire.Data.Active
        
            cooldownDesc := AutoFirePopUp_Gui.AddText("ym147 xm18 h30 w100", "Cooldown:")
            cooldownDesc.SetFont(Color_Black " " TextSize_Normal, Text_Font)
            cooldownEdit := AutoFirePopUp_Gui.AddEdit("yp0 xp79 h23 w100 Number")
            cooldownEdit.SetFont(Color_Black " " TextSize_Normal, Text_Font)
            cooldownEdit.Value := PopUp_AutoFire.Data.Cooldown
            cooldownUnit := AutoFirePopUp_Gui.AddText("yp0 xp105 h30 w100", " in ms")
            cooldownUnit.SetFont(Color_Gray " " TextSize_Normal, Text_Font)
            cooldownHelp := AutoFirePopUp_Gui.AddPicture("xp57 yp2 h20 w20", Image_CircledQuestionmark)
            cooldownHelp.Tooltip := "The time to wait between two triggers of this AutoFire-Hotkey in milliseconds.`n`n-      150 ms = 0.15 s`n-   1 500 ms = 1.5 s`n- 10 500 ms = 10.5 s"

            delayDesc := AutoFirePopUp_Gui.AddText("yp45 xm47 h30 w100", "Delay:")
            delayDesc.SetFont(Color_Black " " TextSize_Normal, Text_Font)
            delayEdit := AutoFirePopUp_Gui.AddEdit("yp0 xp49 h23 w100 Number")
            delayEdit.SetFont(Color_Black " " TextSize_Normal, Text_Font)
            delayEdit.Value := PopUp_AutoFire.Data.Delay
            delayUnit := AutoFirePopUp_Gui.AddText("yp0 xp105 h30 w100", " in ms")
            delayUnit.SetFont(Color_Gray " " TextSize_Normal, Text_Font)
            delayHelp := AutoFirePopUp_Gui.AddPicture("xp58 yp2 h20 w20", Image_CircledQuestionmark)
            delayHelp.Tooltip := "The time to wait only until the first triggers of this AutoFire-Hotkey in milliseconds once.`n`n-      150 ms = 0.15 s`n-   1 500 ms = 1.5 s`n- 10 500 ms = 10.5 s"

            OnPopUpClick_AddAutoFire(*)
            {
                global P2ESettings
    
                GetActiveProfile().AutoFire.Hotkeys.Push(
                    {
                        Active: activeCBox.Value,
                        Name: nameEdit.Value,
                        Hotkey: hotkeyEdit.Value,
                        Cooldown: cooldownEdit.Value,
                        Delay: delayEdit.Value
                    }
                )
                AutoFire_ListView_Draw()

                AutoFirePopUp_Gui.Hide()
                BaseGui.Show()
            }
    
            OnPopUpClick_EditAutoFire(*)
            {
                global P2ESettings
                global PopUp_AutoFire
                
                GetActiveProfile().AutoFire.Hotkeys[PopUp_AutoFire.Idx].Active := activeCBox.Value
                GetActiveProfile().AutoFire.Hotkeys[PopUp_AutoFire.Idx].Name := nameEdit.Value
                GetActiveProfile().AutoFire.Hotkeys[PopUp_AutoFire.Idx].Hotkey := hotkeyEdit.Value
                GetActiveProfile().AutoFire.Hotkeys[PopUp_AutoFire.Idx].Cooldown := cooldownEdit.Value
                GetActiveProfile().AutoFire.Hotkeys[PopUp_AutoFire.Idx].Delay := delayEdit.Value

                AutoFire_ListView_Draw()
                AutoFirePopUp_Gui.Hide()
                BaseGui.Show()
            }
    
            OnPopUpClick_CancelAutoFire(*)
            {
                AutoFirePopUp_Gui.Hide()
                FindGui()
            }
    
            PopUpOnExit(*)
            {
                OnPopUpClick_CancelAutoFire()
            }
            
            ; Finally show it
            BaseGui.Hide()
            AutoFirePopUp_Gui.Show(" w" PopUpWindow.Width " h" PopUpWindow.Height)
        }
    }

    SetupTab_AutoMove(tabIdx)
    {
        global P2ESettings

        ; Render
        Tab.UseTab(tabIdx)

        ; Config
        autoMoveTxtCfg := BaseGui.AddText(Window_Tab.TabX0 " " Window_Tab.TabY0 " " Window_Tab.TabW " h32", Text_Pointer "Configuration:")
        autoMoveTxtCfg.SetFont(Color_DBlue " bold " TextSize_Big, Text_Font)
        autoMoveCkUse := BaseGui.AddCheckbox("xp15 yp24 h32 " Window_Tab.TabW, "Enable AutoMove")
        autoMoveCkUse.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoMoveCkUse.Value := GetActiveProfile().AutoMove.Enable
        autoMoveCkUse.OnEvent("Click", (guiCtrlObj, info) => GetActiveProfile().AutoMove.Enable := guiCtrlObj.Value)

        ; Options
        autoMoveTxtCfg := BaseGui.AddText(Window_Tab.TabX0 " yp36 h32 " Window_Tab.TabW , Text_Pointer "Options:")
        autoMoveTxtCfg.SetFont(Color_DBlue " bold " TextSize_Big, Text_Font)
        autoMoveDescToggle := BaseGui.AddText("xp48 yp28 h32 w120", "Toggle-Hotkey:")
        autoMoveDescToggle.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoMoveEditToggle := BaseGui.AddEdit("xp111 yp0 w120 h23", GetActiveProfile().AutoMove.Toggle)
        autoMoveEditToggle.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoMoveEditToggle.OnEvent("LoseFocus", (guiCtrlObj, info) => GetActiveProfile().AutoMove.Toggle := guiCtrlObj.Value)
        
        autoMoveHelpToggle := BaseGui.AddPicture("xp125 yp2 h20 w20", Image_CircledQuestionmark)
        autoMoveHelpToggle.Tooltip := "Toggles the usage of the automove independently.`n`n-  ON : AutoMove will press LMB permanently `n- OFF : AutoMove is not active`n`nDoubleclick to open the AHK-Documentation with all available hotkeys"
        autoMoveHelpToggle.OnEvent("DoubleClick", OpenAutoHotkeyV2Doc)
        
        autoMoveDescIntr := BaseGui.AddText("xm197 yp27 h32 w120", "Interrupt-Hotkey:")
        autoMoveDescIntr.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoMoveEditIntr := BaseGui.AddEdit("xp122 yp0 w120 h23", GetActiveProfile().AutoMove.Interrupt)
        autoMoveEditIntr.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoMoveEditIntr.OnEvent("LoseFocus", (guiCtrlObj, info) => GetActiveProfile().AutoMove.Interrupt := guiCtrlObj.Value)
        
        autoMoveHelpIntr := BaseGui.AddPicture("xp125 yp2 h20 w20", Image_CircledQuestionmark)
        autoMoveHelpIntr.Tooltip := "Interrupts AutoMove temporarily while pressed.`n`n-  ON : AutoMove will act as if it was toggled-off `n- OFF : AutoMove works as specified`n`nDoubleclick to open the AHK-Documentation with all available hotkeys"
        autoMoveHelpIntr.OnEvent("DoubleClick", OpenAutoHotkeyV2Doc)
        
        autoMoveDescIntrSl := BaseGui.AddText("xm204 yp27 h32 w120", "Interrupt-Sleep:")
        autoMoveDescIntrSl.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoMoveEditIntrSl := BaseGui.AddEdit("xp114 yp0 w60 h23", GetActiveProfile().AutoMove.Sleep)
        autoMoveEditIntrSl.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        
        autoMoveEditIntrSlUnit := BaseGui.AddText("yp0 xp65 h30 w100", " in ms")
        autoMoveEditIntrSlUnit.SetFont(Color_Gray " " TextSize_Normal, Text_Font)
        autoMoveHelpIntrS := BaseGui.AddPicture("xp47 yp2 h20 w20", Image_CircledQuestionmark)
        autoMoveHelpIntrS.Tooltip := "Interrupts AutoMove temporarily while pressed.`n`n-  ON : AutoMove will act as if it was toggled-off `n- OFF : AutoMove works as specified`n`nDoubleclick to open the AHK-Documentation with all available hotkeys"
        
        autoMoveDescInclAf := BaseGui.AddText("xm199 yp27 h32 w120", "Include AutoFire:")
        autoMoveDescInclAf.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoMoveInclAf := BaseGui.AddCheckbox("xp120 ym175 h32 w22", "")
        autoMoveInclAf.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        autoMoveInclAf.Value := GetActiveProfile().AutoMove.IncludeAutoFire
        autoMoveInclAf.OnEvent("Click", (guiCtrlObj, info) => GetActiveProfile().AutoMove.IncludeAutoFire := guiCtrlObj.Value)
        
        autoMoveHelpInclAf := BaseGui.AddPicture("xp22 yp5 h20 w20", Image_CircledQuestionmark)
        autoMoveHelpInclAf.Tooltip := "Toggles the usage of the automove independently.`n`n-  ON : AutoMove will press LMB permanently `n- OFF : AutoMove is not active`n`nDoubleclick to open the AHK-Documentation with all available hotkeys"
    }

    SetupTab_Profiles(tabIdx)
    {
        static ProfileLV
        
        ; Render
        Tab.UseTab(tabIdx)

        ; Header
        header := BaseGui.AddText(Window_Tab.TabX0 " " Window_Tab.TabY0 " " Window_Tab.TabW " h32", Text_Pointer "Profiles:")
        header.SetFont(Color_DBlue " bold " TextSize_Big, Text_Font)

        ; Current
        currentText := BaseGui.AddText("xp48 yp28 " Window_Tab.TabW " h32", "Active:")
        currentText.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        CurrentEdit := BaseGui.AddEdit("xp57 yp0 w280 ReadOnly", GetActiveProfile().ProfileSettings.Name)
        CurrentEdit.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        
        ; List
        Profile_TableColumns := ["Name", "Description", "Created"]
        ProfileLV := BaseGui.AddListView("x" (Window_Tab.Width + 48) " ym75 Checked -Multi NoSort NoSortHdr -WantF2 -LV0x10 Grid", Profile_TableColumns)
        ProfileLV.LeftMargin := "20"
        ProfileLV.BottomMargin := "50"
        ProfileLV.OnEvent("ItemCheck", (guiCtrlObj, idx, checked) => Profile_SetActive(idx))
        ProfileLV.OnEvent("DoubleClick", (guiCtrlObj, idx) => Profile_Edit(idx))
        Profile_ListView_Draw()

        ; Buttons
        profileUp := BaseGui.AddButton("x" (Window_Tab.Width + 15) " ym100 h28", "⇧")
        profileUp.SetFont(Color_Black " bold " TextSize_Normal, Text_Font)
        profileUp.OnEvent("Click", (*) => Profile_Move(true))

        profileDown := BaseGui.AddButton("x" (Window_Tab.Width + 15) " ym135 h28", "⇩")
        profileDown.SetFont(Color_Black " bold " TextSize_Normal, Text_Font)
        profileDown.OnEvent("Click", (*) => Profile_Move(false))

        profileAdd := BaseGui.AddButton("x" (Window.Width - 330) " w120 h28", Text_AddIcon "Add")
        profileAdd.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        profileAdd.LeftDistance := 30 + 2 * 135
        profileAdd.BottomDistance := 10
        profileAdd.OnEvent("Click", Profile_Add)

        profileEdit := BaseGui.AddButton("x" (Window.Width - 300) " w120 h28", Text_EditIcon "Edit")
        profileEdit.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        profileEdit.LeftDistance := 30 + 1 * 135
        profileEdit.BottomDistance := 10
        profileEdit.OnEvent("Click", (guiCtrlObj, idx) => Profile_Edit(idx))
        
        profileRmv := BaseGui.AddButton("x" (Window.Width - 90) " w120 h28", Text_RmvIcon "Remove")
        profileRmv.SetFont(Color_Black " " TextSize_Normal, Text_Font)
        profileRmv.LeftDistance := 30
        profileRmv.BottomDistance := 10
        profileRmv.OnEvent("Click", Profile_Delete)
        
        Profile_ListView_Draw()
        {
            global P2ESettings
            
            ; Spacer
            MinusSpacer := " - "
            WsSpacer := " "
            
            ; Styling
            ProfileLV.SetFont(TextSize_Normal " " Color_Black, Text_Font)

            ; Stop drawing
            ProfileLV.Opt("-Redraw")
    
            ; Clear
            if (ProfileLV.GetCount() != 0)
                ProfileLV.Delete()

            
            ; Loop
            for profile in P2ESettings.Profiles {
                options := "Check"
                activeIndex := Integer(P2ESettings.General.ActiveProfile)
                if (activeIndex != A_Index)
                {
                    options := "-" options
                }

                ProfileLV.Add(options, 
                    WsSpacer profile.ProfileSettings.Name WsSpacer,
                    WsSpacer profile.ProfileSettings.Description WsSpacer,
                    WsSpacer profile.ProfileSettings.Created WsSpacer,
                )
            }

            ; Add FixtureHeader
            ProfileLV.Add("", 
                MinusSpacer Profile_TableColumns[1] MinusSpacer MinusSpacer MinusSpacer MinusSpacer, 
                MinusSpacer Profile_TableColumns[2] MinusSpacer, 
                MinusSpacer Profile_TableColumns[3] MinusSpacer
            )
            ProfileLV.ModifyCol  ; Auto-size each column to fit its contents.
            ProfileLV.Delete(ProfileLV.GetCount())
            
            ; Draw
            ProfileLV.Opt("+Redraw")
        }

        Profile_Move(up)
        {
            ; Get selection
            selectionIdx := ProfileLV.GetNext()

            ; Warn if nothing selected
            if (selectionIdx == 0)
            {
                warnMsg := MsgBox("You haven't selected an entry.", "Confirm", "OK Icon! 0x1000")
                return
            }
            
            ; Can move?
            if ((up && selectionIdx == 1) || (!up && selectionIdx == P2ESettings.Profiles.Length))
                return

            ; Where to move
            other := unset
            if (up)
                other := selectionIdx - 1
            else
                other := selectionIdx + 1

            ; Also change selection?
            if (selectionIdx == P2ESettings.General.ActiveProfile)
                P2ESettings.General.ActiveProfile := other
            else if (other == P2ESettings.General.ActiveProfile)
                P2ESettings.General.ActiveProfile := selectionIdx

            ; Act
            P2ESettings.Profiles := SwapElements(P2ESettings.Profiles, selectionIdx, other)
            Profile_ListView_Draw()
            SaveSettings()

            SwapElements(sourceAr, idx1, idx2)
            {
                ar := Array()

                for e in sourceAr
                {
                    if (A_Index == idx1)
                    {
                        ar.Push(sourceAr[idx2])
                    }
                    else if (A_Index == idx2)
                    {
                        ar.Push(sourceAr[idx1])
                    }
                    else
                    {
                        ar.Push(e)
                    }
                }

                return ar
            }
        }
    
        Profile_SetActive(idx)
        {
            global BaseGui
            if (idx == P2ESettings.General.ActiveProfile)
                return
            
            ; User confirm
            Result := MsgBox("Would you like to switch Profile to '" CurrentEdit.Value "'?",, "YesNo")
            if (Result == "No")
            {
                Profile_ListView_Draw()
                return
            }
            
            ; Set new idx
            P2ESettings.General.ActiveProfile := idx
            
            ; Update all
            BaseGui.Destroy()
            DisplayGui()
            Reload()
        }

        Profile_Delete(*)
        {
            ; Get selection
            selectionIdx := ProfileLV.GetNext()

            ; Warn if nothing selected
            if (selectionIdx == 0)
            {
                MsgBox("You haven't selected an entry.", "Warning", "OK Icon! 0x1000")
                return
            }

            ; Warn if active
            if (selectionIdx == P2ESettings.General.ActiveProfile)
            {
                MsgBox("You need to swap the active profile first.", "Warning", "OK Icon! 0x1000")
                return
            }

            ; Confirm
            Result := MsgBox("Do you really want to delete '" P2ESettings.Profiles[selectionIdx].ProfileSettings.Name "'?",, "YesNo")
            if (Result == "No")
            {
                return
            }

            ; Adjust active-idx
            if (selectionIdx < P2ESettings.General.ActiveProfile)
            {   
                P2ESettings.General.ActiveProfile := P2ESettings.General.ActiveProfile - 1
            }

            ; Act
            P2ESettings.Profiles.RemoveAt(selectionIdx)
            Profile_ListView_Draw()
            SaveSettings()
        }

        static ProfilePopupData := unset

        Profile_Add(*)
        {
            ProfilePopupData := {
                Name: "",
                Description: "",
                Created: "",
                Idx: -1
            }
            Profile_DisplayPopup(false)
        }

        Profile_Edit(idx)
        {
            ProfilePopupData := {
                Name: P2ESettings.Profiles[idx].ProfileSettings.Name,
                Description: P2ESettings.Profiles[idx].ProfileSettings.Description,
                Created: P2ESettings.Profiles[idx].ProfileSettings.Created,
                Idx: idx
            }
            Profile_DisplayPopup(true)
        }

        Profile_DisplayPopup(isEdit)
        {
            global P2ESettings
    
            ; Window
            PopUpWindow := {
                Width: 400,
                Height: 150
            }
            
            ; Window-Events
            OnMessage(0x0020, WM_SETCURSOR)
            OnMessage(0x02A2, WM_NCMOUSELEAVE)

            ; Setup Gui
            PopUpGui := Gui()
            PopUpGui.OnEvent("Escape", PopUp_OnExit)
            PopUpGui.OnEvent("Close", PopUp_OnExit)
            PopUpGui.OnEvent("Size", OnResize)
            PopUpGui.Opt("+LastFound AlwaysOnTop -Resize -MaximizeBox -MinimizeBox MinSize" PopUpWindow.Width "x" PopUpWindow.Height)
            PopUpGui.SetFont("" Color_Gray, Text_Font)
            PopUpGui.BackColor := "FFFFFF"

            ; Buttons
            if (isEdit)
            {
                PopUpGui.Title := "Edit profile"
                editBtn := PopUpGui.AddButton("w80 h28", Text_EditIcon "Edit")
                editBtn.SetFont(TextSize_Normal, Text_Font)
                editBtn.BottomDistance := 15
                editBtn.LeftDistance := 115
                editBtn.OnEvent("Click", PopUp_OnEdit)
            }
            else ;if (PopUp_AutoFire.Mode_Edit)
            {
                PopUpGui.Title := "Add a new profile"
                createBtn := PopUpGui.AddButton("w80 h28", Text_AddIcon "Add")
                createBtn.SetFont(TextSize_Normal, Text_Font)
                createBtn.BottomDistance := 15
                createBtn.LeftDistance := 115
                createBtn.OnEvent("Click", PopUp_OnAdd)
            }
            cancelBtn := PopUpGui.AddButton("w80 h28", "Cancel")
            cancelBtn.SetFont(TextSize_Normal, Text_Font)
            cancelBtn.BottomDistance := 15
            cancelBtn.LeftDistance := 25
            cancelBtn.OnEvent("Click", PopUp_OnExit)
            
            nameDesc := PopUpGui.AddText("xm65 ym10 h23 w80", "Name:")
            nameDesc.SetFont(TextSize_Normal " " Color_Black, Text_Font)
            nameEdit := PopUpGui.AddEdit("xm115 yp0 h23 w200", ProfilePopupData.Name)
            nameEdit.SetFont(TextSize_Normal " " Color_Black, Text_Font)

            descDesc := PopUpGui.AddText("xm28 ym45 h23 w80", "Description:")
            descDesc.SetFont(TextSize_Normal " " Color_Black, Text_Font)
            descEdit := PopUpGui.AddEdit("xm113 yp0 h23 w200", ProfilePopupData.Description)
            descEdit.SetFont(TextSize_Normal " " Color_Black, Text_Font)
            
            
            if (!isEdit)
            {
                copyCk := PopUpGui.AddCheckbox("xm100 ym90 h23 w200", "Copy active profiles")
                copyCk.SetFont(TextSize_Normal " " Color_Black, Text_Font)
                swapCk := PopUpGui.AddCheckbox("xm100 ym115 h23 w270", "Swap to the new profile after")
                swapCk.SetFont(TextSize_Normal " " Color_Black, Text_Font)
                swapCk.Value := true
                PopUpWindow.Height := 205
            }

            ; Finally show it
            BaseGui.Hide()
            PopUpGui.Show(" w" PopUpWindow.Width " h" PopUpWindow.Height)

            PopUp_OnAdd(*)
            {
                global P2ESettings

                newProfile := Object()
                newProfile.ProfileSettings := Object()
                newProfile.ProfileSettings.Name := nameEdit.Value
                newProfile.ProfileSettings.Description := descEdit.Value
                newProfile.ProfileSettings.Created := A_DD "." A_MM "." A_YYYY

                if (copyCk.Value)
                {
                    newProfile.AutoFire := GetActiveProfile().AutoFire
                    newProfile.AutoMove := GetActiveProfile().AutoMove
                }
                else
                {
                    newProfile.AutoFire := Object()
                    newProfile.AutoFire := {
                        Enable: false,
                        BoundTo: "LButton",
                        Toggle: "F13",
                        Hotkeys: Array()
                    }
                    newProfile.AutoMove := Object()
                    newProfile.AutoMove := {
                        Enable: false,
                        Hotkey: "LButton",
                        IncludeAutoFire: true,
                        Interrupt: "XButton2",
                        Sleep: "500",
                        Toggle: "XButton1"
                    }
                }

                ; Add
                P2ESettings.Profiles.Push(newProfile)
                SaveSettings()

                ; Swap?
                if (swap := swapCk.Value)
                {
                    P2ESettings.General.ActiveProfile := P2ESettings.Profiles.Length
                    Reload()
                }
                else
                {
                    Profile_ListView_Draw()
                }

                ; Show
                PopUpGui.Hide()
                FindGui()
            }

            PopUp_OnEdit(*)
            {
                global P2ESettings
                P2ESettings.Profiles[ProfilePopupData.Idx].ProfileSettings.Name := nameEdit.Value
                P2ESettings.Profiles[ProfilePopupData.Idx].ProfileSettings.Description := descEdit.Value
                SaveSettings()

                ; Show
                PopUpGui.Hide()
                FindGui()

                ; Refresh
                Profile_ListView_Draw()
            }

            PopUp_OnExit(*)
            {

                PopUpGui.Hide()
                FindGui()
            }
        }
    }

    /* # HELPER #*/
    OpenAutoHotkeyV2Doc(*)
    {
        Run("https://www.autohotkey.com/docs/v2/KeyList.htm")
    }

    MakeUnderConstructionTab(tabIdx)
    {
        ; Render
        Tab.UseTab(tabIdx)
        message := BaseGui.AddText(Window_Tab.TabX0 " y30 h32 " Window_Tab.TabW , "🚧 This tab is currently under construction.")
        message.SetFont(Color_Black " " TextSize_Big, Text_Font)
        message2 := BaseGui.AddText(Window_Tab.TabX0 " ym45 h32 " Window_Tab.TabW , "      Try again with the next update.")
        message2.SetFont(Color_Black " " TextSize_Big, Text_Font)
    }

    /* # UI-ALC # */
    OnTabClick(guiCtrlObj, info, *)
    {
        global BaseGui

        ; Unset focus
        guiCtrlObj.Focus()
        ; Remove current tab-highlighting
        BaseGui.ActiveTab.SetFont(Color_Gray " " TextSize_Big)
        ; Swap tab
        BaseGui.Tabs.Choose(trim(guiCtrlObj.text))
        ;thisGui.TabTitle.Value := trim(GuiCtrlObj.text)
        BaseGui.ActiveTab := GuiCtrlObj
        ; Apply tab-highlighting
        guiCtrlObj.SetFont(Color_Blue " " TextSize_Big)
        BaseGui.TabPicSelect.Move(0, (32*(GuiCtrlObj.Index-1) + Window_Tab.TabPaddingTop))
    }

    OnResize(thisGui, MinMax, Width, Height) 
    {
        if (MinMax = -1) ; The window has been minimized. No action needed.
        {
            OnMinimizeToTray()
            return
        }

        DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)
        For (Hwnd, GuiCtrlObj in thisGui)
        {
            if GuiCtrlObj.HasProp("LeftMargin")
            {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, , Width-cX-GuiCtrlObj.LeftMargin,)
            }
            if GuiCtrlObj.HasProp("LeftDistance")
            {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(Width -cWidth - GuiCtrlObj.LeftDistance, , , )
            }
            if GuiCtrlObj.HasProp("BottomDistance")
            {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, Height - cHeight - GuiCtrlObj.BottomDistance, ,  )
            }
            if GuiCtrlObj.HasProp("BottomMargin")
            {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, , , Height -cY - GuiCtrlObj.BottomMargin)
            }  
        }
        DllCall("LockWindowUpdate", "Uint", 0)
    }

    /* # UI-EVENT-CALLBACKS # */

    __ToolTipShown := false
    WM_SETCURSOR(wParam, lParam, msg, hwnd)
    {
        MouseGetPos(,,, &hCtrl, 2) ; Get hovered control hwnd.

        ; Hide Tooltip
        if (!hCtrl)
        {
            __ToolTipShown := false
            ToolTip()
            return
        }
        if !guiCtrl := GuiCtrlFromHwnd(hCtrl) 
        {
            __ToolTipShown := false
            ToolTip()
            return
        }

        ; MenuItem-hover
        if (InStr(guiCtrl.Name, "MenuItem"))
        {
            if (guiCtrl != BaseGui.ActiveTab)
            {
                BaseGui.TabPicHover.Visible := true
                BaseGui.TabPicHover.Move(0, (32 * (guiCtrl.Index-1) + Window_Tab.TabPaddingTop))
            }
            else
            {
                BaseGui.TabPicHover.Visible := false
            }
        }
        ; Tooltip
        else if (guiCtrl.HasProp("ToolTip") && !__ToolTipShown)
        {
            guiCtrl.GetPos(&X, &Y)
            ToolTip(guiCtrl.ToolTip, X + 25, Y + 2)
            __ToolTipShown := true
        }
        else
        {
            try
            {
                BaseGui.TabPicHover.Visible := false
            }
            catch 
            {
                ; Probably destroyed
            }
        }
    }

    WM_NCMOUSELEAVE(wParam, lParam, msg, hwnd)
    {
        if (__ToolTipShown := true)
        {
            __ToolTipShown := false
            try
            {
                BaseGui.TabPicHover.Visible:= false
            }
            catch 
            {
                ; Probably destroyed
            }
        }
    }
}

/* # API # */


/* # ALC # */

OnPreExit()
{
    ; Set the focus somewhere it wont hurt
    if (IsSet(Tab))
    {
        try
        {
            Tab.Focus() 
        }
        catch
        {}
    }
    
    ; Check if settings should be saved
    SaveSettings() 
}

OnExit(*)
{
    global BaseGui

    ; Before actually exiting
    OnPreExit()

    if (P2ESettings.General.CloseToTray)
        OnMinimizeToTray() ; Go to tray
    else
        ExitApp() ; Terminate
}

OnExitTray(item, itemPos, menu)
{
    global BaseGui

    ; Before actually exiting
    OnPreExit()

    ; Terminate
    ExitApp()
}

OnMinimizeToTray()
{
    global BaseGui

    OnPreExit()
    if (IsSet(BaseGui))
        BaseGui.Destroy()
}

OnSoundChange(State)
{
    global P2ESettings
    global VolumeDownPic
    global VolumeMutedPic
    global S_Active

    S_Active := !State
    BeepChk.Value := State
    P2ESettings.General.Beep := State
    VolumeDownPic.Visible := State
    VolumeMutedPic.Visible := !State
}

#Include "P2EBase.ahk"