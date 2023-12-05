#Requires AutoHotkey v2.0
#Include "JSON.ahk"

; AppSettings
AppSettingsFilename := "appsettings.json"
AppSettingsPath := ".\" AppSettingsFilename
AppSettingsEncoding := "UTF-8"

; Keys
SettingKeys := {

    /* AutoFire */
    AF: "AutoFire",
    AF_Enable: "Enable",
    AF_BoundTo: "BoundTo",
    AF_Toggle: "Toggle",
    AF_Hotkeys: "Hotkeys",

    /* AutoFire-Hotkey */
    AFHK_Active: "Active",
    AFHK_Name: "Name",
    AFHK_Hotkey: "Hotkey",
    AFHK_Cooldown: "Cooldown",
    AFHK_Delay: "Delay",
    
    /* AutoFire */
    AM: "AutoMove",
    AM_Enable: "Enable",
    AM_Hotkey: "Hotkey",
    AM_Toggle: "Toggle",
    AM_Interrupt: "Interrupt",
    AM_Sleep: "Sleep",
    AM_IncludeAutoFire: "IncludeAutoFire",    

    /* AutoFire */
    G: "General",
    G_Randomness: "Randomness",
    G_StartMinimized: "StartMinimized",
    G_CloseToTray: "CloseToTray",
    G_TargetedExe: "TargetedExe",
    G_Beep: "Beep"
}

; Data
P2ESettings := {
    
    AutoFire: {
        Enable: 1,
        BoundTo: "LButton",
        Toggle: "F13",
        Hotkeys: []
        /*Hotkeys : [
            { 
                Active: 0,
                Name: "Ability-1",
                Hotkey: "T",
                Cooldown: "1000",
                Delay: "100"
            },
            { 
                Active: 1,
                Name: "Ability-2",
                Hotkey: "T",
                Cooldown: "1000",
                Delay: "100"
            }
        ]*/
    },

    AutoMove: {
        Enable: 1,
        Hotkey: "LButton",
        Toggle: "XButton1",
        Interrupt: "XButton2",
        Sleep: 500,
        IncludeAutoFire: 1
    },

    General: {
        Randomness: 80,
        StartMinimized: true,
        CloseToTray: true,
        TargetedExe: "PathOfExile.exe",
        Beep: true
    }
}
Backup_P2ESettings := unset

; Determines if the settings-obj from this has changes
SettingsContainsChanges()
{
    global Backup_P2ESettings
    global P2ESettings

    /* AutoFire */
    ; Enable
    if (Backup_P2ESettings.AutoFire.Enable != P2ESettings.AutoFire.Enable)
        return true
    ; BoundTo
    if (Backup_P2ESettings.AutoFire.BoundTo != P2ESettings.AutoFire.BoundTo)
        return true
    ; Toggle
    if (Backup_P2ESettings.AutoFire.Toggle != P2ESettings.AutoFire.Toggle)
        return true
    ; Hotkeys
    if (P2ESettings.AutoFire.Hotkeys.Length != Backup_P2ESettings.AutoFire.Hotkeys.Length)
        return true
    for key in P2ESettings.AutoFire.Hotkeys
    {
        backup_key := Backup_P2ESettings.AutoFire.Hotkeys[A_Index]
        if (backup_key.Active != key.Active)
            return true
        if (backup_key.Name != key.Name)
            return true
        if (backup_key.Hotkey != key.Hotkey)
            return true
        if (backup_key.Cooldown != key.Cooldown)
            return true
        if (backup_key.Delay != key.Delay)
            return true
    }

    /* AutoMove */
    ; Enable
    if (Backup_P2ESettings.AutoMove.Enable != P2ESettings.AutoMove.Enable)
        return true
    ; Hotkey
    if (Backup_P2ESettings.AutoMove.Hotkey != P2ESettings.AutoMove.Hotkey)
        return true
    ; Toggle
    if (Backup_P2ESettings.AutoMove.Toggle != P2ESettings.AutoMove.Toggle)
        return true
    ; Interrupt
    if (Backup_P2ESettings.AutoMove.Interrupt != P2ESettings.AutoMove.Interrupt)
        return true
    ; Sleep
    if (Backup_P2ESettings.AutoMove.Sleep != P2ESettings.AutoMove.Sleep)
        return true
    ; Sleep
    if (Backup_P2ESettings.AutoMove.IncludeAutoFire != P2ESettings.AutoMove.IncludeAutoFire)
        return true

    /* General */
    ; Randomness
    if (Backup_P2ESettings.General.Randomness != P2ESettings.General.Randomness)
        return true
    ; StartMinimized
    if (Backup_P2ESettings.General.StartMinimized != P2ESettings.General.StartMinimized)
        return true
    ; CloseToTray
    if (Backup_P2ESettings.General.CloseToTray != P2ESettings.General.CloseToTray)
        return true
    ; TargetedExe
    if (Backup_P2ESettings.General.TargetedExe != P2ESettings.General.TargetedExe)
        return true
    ; Beep
    if (Backup_P2ESettings.General.Beep != P2ESettings.General.Beep)
        return true

    ; all checks passed
    return false
}

; Saves the settings-obj from this global
SaveSettings()
{
    global AppSettingsPath
    global AppSettingsEncoding

    ; only save when needed
    if (FileExist(AppSettingsPath) && !SettingsContainsChanges())
        return

    ; determine the output
    appsettingsString := JsonSerialize(MapSettings(),4,1)

    ; ensure to append to a new file
    if (FileExist(AppSettingsPath))
        FileRecycle(AppSettingsPath)

    ; append content
    FileAppend(appsettingsString, AppSettingsPath, AppSettingsEncoding)
}

; Loads the settings-obj into this global
LoadSettings()
{
    global Backup_P2ESettings
    global P2ESettings

    LoadDefaultSettings()
    {
        global Backup_P2ESettings
        global P2ESettings

        ; Load default settings
        UnmapSettings(Map())
        ; Use as backup
        Backup_P2ESettings := P2ESettings
        ; And deserialize again
        UnmapSettings(Map())
    }

    ; Check if settings exists
    if (FileExist(AppSettingsPath))
    {
        ;try
        ;{
            ; Read and unmap the file
            appsettingsStr := FileRead(AppSettingsPath, AppSettingsEncoding)
            UnmapSettings(JsonDeserialize(&appsettingsStr))
            ; Use as backup
            Backup_P2ESettings := P2ESettings
            ; And deserialize again
            UnmapSettings(JsonDeserialize(&appsettingsStr))
        ;}
        ;catch
        ;
        ;    LoadDefaultSettings()
        ;}
    }
    else
    {
        LoadDefaultSettings()
    }
}

; Creates a settings-obj from the 'root'-map
UnmapSettings(root)
{
    global P2ESettings
    global SettingKeys

    P2ESettings := Object()

    /* AutoFire */
    P2ESettings.AutoFire := Object()
    ; Root
    if (root.Has(SettingKeys.AF))
        rootAutoFire := root[SettingKeys.AF]
    else 
        rootAutoFire := Map()
    ; Enable
    if (rootAutoFire.Has(SettingKeys.AF_Enable))
        P2ESettings.Autofire.Enable := rootAutoFire[SettingKeys.AF_Enable]
    else 
        P2ESettings.Autofire.Enable := 0
    ; BoundTo
    if (rootAutoFire.Has(SettingKeys.AF_BoundTo))
        P2ESettings.Autofire.BoundTo := rootAutoFire[SettingKeys.AF_BoundTo]
    else 
        P2ESettings.Autofire.BoundTo := "LButton"
    ; Toggle
    if (rootAutoFire.Has(SettingKeys.AF_Toggle))
        P2ESettings.Autofire.Toggle := rootAutoFire[SettingKeys.AF_Toggle]
    else 
        P2ESettings.Autofire.Toggle := "F13"
    ; Hotkeys
    if (rootAutoFire.Has(SettingKeys.AF_Hotkeys))
    {
        Hotkeys := Array()
        for obj in rootAutoFire[SettingKeys.AF_Hotkeys]
        {
            Hotkeys.Push(
                { 
                    Active: obj[SettingKeys.AFHK_Active],
                    Name: obj[SettingKeys.AFHK_Name],
                    Hotkey: obj[SettingKeys.AFHK_Hotkey],
                    Cooldown: obj[SettingKeys.AFHK_Cooldown],
                    Delay: obj[SettingKeys.AFHK_Delay]
                }
            )
        }
    }
    else
    {
        Hotkeys := Array()
    }
    P2ESettings.Autofire.Hotkeys := Hotkeys

    /* AutoMove */
    P2ESettings.AutoMove := Object()
    ; Root
    if (root.Has(SettingKeys.AM))
        rootAutoFire := root[SettingKeys.AM]
    else 
        rootAutoFire := Map()
    ; Enable
    if (rootAutoFire.Has(SettingKeys.AM_Enable))
        P2ESettings.AutoMove.Enable := rootAutoFire[SettingKeys.AM_Enable]
    else 
        P2ESettings.AutoMove.Enable := 1
    ; Hotkey
    if (rootAutoFire.Has(SettingKeys.AM_Hotkey))
        P2ESettings.AutoMove.Hotkey := rootAutoFire[SettingKeys.AM_Hotkey]
    else 
        P2ESettings.AutoMove.Hotkey := "LButton"
    ; Toggle
    if (rootAutoFire.Has(SettingKeys.AM_Toggle))
        P2ESettings.AutoMove.Toggle := rootAutoFire[SettingKeys.AM_Toggle]
    else 
        P2ESettings.AutoMove.Toggle := "XButton1"
    ; Interrupt
    if (rootAutoFire.Has(SettingKeys.AM_Interrupt))
        P2ESettings.AutoMove.Interrupt := rootAutoFire[SettingKeys.AM_Interrupt]
    else 
        P2ESettings.AutoMove.Interrupt := "XButton2"
    ; Sleep
    if (rootAutoFire.Has(SettingKeys.AM_Sleep))
        P2ESettings.AutoMove.Sleep := rootAutoFire[SettingKeys.AM_Sleep]
    else 
        P2ESettings.AutoMove.Sleep := "500"
    ; IncludeAutoFire
    if (rootAutoFire.Has(SettingKeys.AM_IncludeAutoFire))
        P2ESettings.AutoMove.IncludeAutoFire := rootAutoFire[SettingKeys.AM_IncludeAutoFire]
    else 
        P2ESettings.AutoMove.IncludeAutoFire := 1

    /* General */
    P2ESettings.General := Object()
    ; Root
    if (root.Has(SettingKeys.G))
        rootGeneral := root[SettingKeys.G]
    else 
        rootGeneral := Map()
    ; IncludeAutoFire
    if (rootGeneral.Has(SettingKeys.G_Randomness))
        P2ESettings.General.Randomness := rootGeneral[SettingKeys.G_Randomness]
    else 
        P2ESettings.General.Randomness := 80
    ; StartMinimized
    if (rootGeneral.Has(SettingKeys.G_StartMinimized))
        P2ESettings.General.StartMinimized := rootGeneral[SettingKeys.G_StartMinimized]
    else 
        P2ESettings.General.StartMinimized := false
    ; CloseToTray
    if (rootGeneral.Has(SettingKeys.G_CloseToTray))
        P2ESettings.General.CloseToTray := rootGeneral[SettingKeys.G_CloseToTray]
    else 
        P2ESettings.General.CloseToTray := false
    ; TargetedExe
    if (rootGeneral.Has(SettingKeys.G_TargetedExe))
        P2ESettings.General.TargetedExe := rootGeneral[SettingKeys.G_TargetedExe]
    else 
        P2ESettings.General.TargetedExe := "notepad.exe"
    ; Beep
    if (rootGeneral.Has(SettingKeys.G_Beep))
        P2ESettings.General.Beep := rootGeneral[SettingKeys.G_Beep]
    else 
        P2ESettings.General.Beep := true
    ; Finally
    return P2ESettings
}

; Creates a map from the settings-obj
MapSettings()
{
    global P2ESettings
    
    root := Map()

    /* AutoFire */
    ; Root
    root[SettingKeys.AF] := Map()
    ; Enable
    root[SettingKeys.AF][SettingKeys.AF_Enable] := P2ESettings.Autofire.Enable
    ; BoundTo
    root[SettingKeys.AF][SettingKeys.AF_BoundTo] := P2ESettings.Autofire.BoundTo
    ; Toggle
    root[SettingKeys.AF][SettingKeys.AF_Toggle] := P2ESettings.Autofire.Toggle
    ; Hotkeys
    Hotkeys := Array()
    for key in P2ESettings.AutoFire.Hotkeys
    {
        obj := Map()
        obj[SettingKeys.AFHK_Active] := key.Active
        obj[SettingKeys.AFHK_Name] := key.Name
        obj[SettingKeys.AFHK_Hotkey] := key.Hotkey
        obj[SettingKeys.AFHK_Cooldown] := key.Cooldown
        obj[SettingKeys.AFHK_Delay] := key.Delay
        Hotkeys.Push(obj)
    }
    root[SettingKeys.AF][SettingKeys.AF_Hotkeys] := Hotkeys

    /* AutoMove */
    ; Root
    root[SettingKeys.AM] := Map()
    ; Hotkey
    root[SettingKeys.AM][SettingKeys.AM_Hotkey] := P2ESettings.AutoMove.Hotkey
    ; Enable
    root[SettingKeys.AM][SettingKeys.AM_Enable] := P2ESettings.AutoMove.Enable
    ; Toggle
    root[SettingKeys.AM][SettingKeys.AM_Toggle] := P2ESettings.AutoMove.Toggle
    ; Interrupt
    root[SettingKeys.AM][SettingKeys.AM_Interrupt] := P2ESettings.AutoMove.Interrupt
    ; Sleep
    root[SettingKeys.AM][SettingKeys.AM_Sleep] := P2ESettings.AutoMove.Sleep
    ; IncludeAutoFire
    root[SettingKeys.AM][SettingKeys.AM_IncludeAutoFire] := P2ESettings.AutoMove.IncludeAutoFire

    /* General */
    ; Root
    root[SettingKeys.G] := Map()
    ; IncludeAutoFire
    root[SettingKeys.G][SettingKeys.G_Randomness] := P2ESettings.General.Randomness
    ; StartMinimized
    root[SettingKeys.G][SettingKeys.G_StartMinimized] := P2ESettings.General.StartMinimized
    ; CloseToTray
    root[SettingKeys.G][SettingKeys.G_CloseToTray] := P2ESettings.General.CloseToTray
    ; TargetedExe
    root[SettingKeys.G][SettingKeys.G_TargetedExe] := P2ESettings.General.TargetedExe
    ; Beep
    root[SettingKeys.G][SettingKeys.G_Beep] := P2ESettings.General.Beep

    ; Finally
    return root
}