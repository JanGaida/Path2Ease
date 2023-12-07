#Requires AutoHotkey v2.0
#Include "JSON.ahk"

; AppSettings
AppSettingsFilename := "appsettings.json"
AppSettingsPath := ".\" AppSettingsFilename
AppSettingsEncoding := "UTF-8"

; Keys
SettingKeys := {
    /* Profile */
    P: "Profiles",
    P_ProfileSettings: "ProfileSettings",
    P_ProfileIndex: "Index",
    P_ProfileName: "Name",
    P_Description: "Description",
    P_Created: "Created",

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
    G_Beep: "Beep",
    G_ActiveProfile: "ActiveProfile"
}

; Data
P2ESettings := {
    
    Profiles: [
        {
            ProfileSettings: {
                Name: "Default"
            },

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
            }
        }
    ],

    General: {
        Randomness: 80,
        StartMinimized: true,
        CloseToTray: true,
        TargetedExe: "Notepad.exe",
        Beep: true,
        ActiveProfile: 0
    }
}
Backup_P2ESettings := unset

; Determines if the settings-obj from this has changes
SettingsContainsChanges()
{
    global Backup_P2ESettings
    global P2ESettings

    /* # General # */
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
    ; ActiveProfile
    if (Backup_P2ESettings.General.ActiveProfile != P2ESettings.General.ActiveProfile)
        return true
    ; Length match
    if Backup_P2ESettings.Profiles.Length != P2ESettings.Profiles.Length
        return true

    ; Loop all
    for Profile in P2ESettings.Profiles
    {
        Backup_Profile := Backup_P2ESettings.Profiles[A_Index]

        /* # ProfileSettings # */
        ; Name
        if (Backup_Profile.ProfileSettings.Name != Profile.ProfileSettings.Name)
            return true

        /* # AutoFire # */
        ; Enable
        if (Backup_Profile.AutoFire.Enable != Profile.AutoFire.Enable)
            return true
        ; BoundTo
        if (Backup_Profile.AutoFire.BoundTo != Profile.AutoFire.BoundTo)
            return true
        ; Toggle
        if (Backup_Profile.AutoFire.Toggle != Profile.AutoFire.Toggle)
            return true
        ; Hotkeys
        if (Backup_Profile.AutoFire.Hotkeys.Length != Profile.AutoFire.Hotkeys.Length)
            return true
        for key in Profile.AutoFire.Hotkeys
        {
            Backup_Key := Backup_Profile.AutoFire.Hotkeys[A_Index]
            if (Backup_Key.Active != key.Active)
                return true
            if (Backup_Key.Name != key.Name)
                return true
            if (Backup_Key.Hotkey != key.Hotkey)
                return true
            if (Backup_Key.Cooldown != key.Cooldown)
                return true
            if (Backup_Key.Delay != key.Delay)
                return true
        }

        /* # AutoMove # */
        ; Enable
        if (Backup_Profile.AutoMove.Enable != Profile.AutoMove.Enable)
            return true
        ; Hotkey
        if (Backup_Profile.AutoMove.Hotkey != Profile.AutoMove.Hotkey)
            return true
        ; Toggle
        if (Backup_Profile.AutoMove.Toggle != Profile.AutoMove.Toggle)
            return true
        ; Interrupt
        if (Backup_Profile.AutoMove.Interrupt != Profile.AutoMove.Interrupt)
            return true
        ; Sleep
        if (Backup_Profile.AutoMove.Sleep != Profile.AutoMove.Sleep)
            return true
        ; SleepIncludeAutoFire
        if (Backup_Profile.AutoMove.IncludeAutoFire != Profile.AutoMove.IncludeAutoFire)
            return true
    }

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
    appsettingsString := JsonSerialize(MapifySettings(),4,1)

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

    ; Check if settings exists
    if (FileExist(AppSettingsPath))
    {
        ; Read and objectify the file
        appsettingsStr := FileRead(AppSettingsPath, AppSettingsEncoding)
        ObjectifySettings(JsonDeserialize(&appsettingsStr))
        ; Use as backup
        Backup_P2ESettings := P2ESettings
        ; And deserialize again
        ObjectifySettings(JsonDeserialize(&appsettingsStr))
    }
    else
    {
        LoadDefaultSettings()
    }

    ; Helper to load default-settings
    LoadDefaultSettings()
    {
        global Backup_P2ESettings
        global P2ESettings

        ; Load default settings
        ObjectifySettings(Map())
        ; Use as backup
        Backup_P2ESettings := P2ESettings
        ; And deserialize again
        ObjectifySettings(Map())
    }
}

; Creates a settings-obj from the 'root'-map
ObjectifySettings(root)
{
    global P2ESettings
    global SettingKeys

    P2ESettings := Object()

    /* # Profiles # */
    P2ESettings.Profiles := Array()
    if (root.Has(SettingKeys.P))
    {
        for profile in root[SettingKeys.P]
        {
            profileSettings := Object()
            autoFire := Object()
            autoMove := Object()

            /* # ProfileSettings # */
            if (profile.Has(SettingKeys.P_ProfileSettings))
            {
                _profileSettings := profile[SettingKeys.P_ProfileSettings]

                ; Name
                profileSettings.Name := GrabValue(_profileSettings, SettingKeys.P_ProfileName, "Profile (default)")
                ; Description
                profileSettings.Description := GrabValue(_profileSettings, SettingKeys.P_Description, "")
                ; Created
                profileSettings.Created := GrabValue(_profileSettings, SettingKeys.P_Created, A_DD "." A_MM "." A_YYYY)
            }
            else
            {
                ; Defaults
                profileSettings.Name := "Profile (default)"
                profileSettings.Description := ""
                profileSettings.Created := A_DD "." A_MM "." A_YYYY
            }

            /* # AutoFire # */
            if (profile.Has(SettingKeys.AF))
            {
                _autoFire := profile[SettingKeys.AF]

                ; Enable
                autoFire.Enable := GrabValue(_autoFire, SettingKeys.AF_Enable, false)
                ; BoundTo
                autoFire.BoundTo := GrabValue(_autoFire, SettingKeys.AF_BoundTo, "LButton")
                ; Toggle
                autoFire.Toggle := GrabValue(_autoFire, SettingKeys.AF_Toggle, "F13")
                ; Hotkeys
                autoFire.Hotkeys := Array()
                if (_autoFire.Has(SettingKeys.AF_Hotkeys))
                {
                    for afHotkey in _autoFire[SettingKeys.AF_Hotkeys]
                    {
                        autoFire.Hotkeys.Push(
                            { 
                                Active: GrabValue(afHotkey, SettingKeys.AFHK_Active, false),
                                Name: GrabValue(afHotkey, SettingKeys.AFHK_Name, "Ability-1"),
                                Hotkey: GrabValue(afHotkey, SettingKeys.AFHK_Hotkey, "^+F1"),
                                Cooldown: GrabValue(afHotkey, SettingKeys.AFHK_Cooldown, "5000"),
                                Delay: GrabValue(afHotkey, SettingKeys.AFHK_Delay, "0")
                            }
                        )
                    }
                }
            }
            else
            {
                ; Defaults
                autoFire.Enable := false
                autoFire.BoundTo := "LButton"
                autoFire.Toggle := "F13"
                autoFire.Hotkeys := Array()
            }

            /* # AutoMove # */
            if (profile.Has(SettingKeys.AM))
            {
                _autoMove := profile[SettingKeys.AM]

                ; Enable
                autoMove.Enable := GrabValue(_autoMove, SettingKeys.AM_Enable, false)
                ; Hotkey
                autoMove.Hotkey := GrabValue(_autoMove, SettingKeys.AM_Hotkey, "LButton")
                ; IncludeAutoFire
                autoMove.IncludeAutoFire := GrabValue(_autoMove, SettingKeys.AM_IncludeAutoFire, true)
                ; Interrupt
                autoMove.Interrupt := GrabValue(_autoMove, SettingKeys.AM_Interrupt, "XButton2")
                ; Sleep
                autoMove.Sleep := GrabValue(_autoMove, SettingKeys.AM_Sleep, "500")
                ; Toggle
                autoMove.Toggle := GrabValue(_autoMove, SettingKeys.AM_Toggle, "XButton1")
            }
            else
            {
                ; Defaults
                autoMove.Enable := false
                autoMove.Hotkey := "LButton"
                autoMove.IncludeAutoFire := true
                autoMove.Interrupt := "XButton2"
                autoMove.Sleep := "500"
                autoMove.Toggle := "XButton1"
            }

            ; Assemble
            P2ESettings.Profiles.Push(
                {
                    ProfileSettings: profileSettings,
                    AutoFire: autoFire,
                    AutoMove: autoMove
                }
            )
        }
    }
    else
    {
        P2ESettings.Profiles := Array()
        P2ESettings.Profiles.Push(
            {
                ProfileSettings: {
                    Name: "Default",
                    Description: "",
                    Created: A_DD "." A_MM "." A_YYYY
                },
                AutoFire: {
                    Enable: false,
                    BoundTo: "LButton",
                    Toggle: "F13",
                    Hotkeys: Array()
                },
                AutoMove: {
                    Enable: false,
                    Hotkey: "LButton",
                    IncludeAutoFire: true,
                    Interrupt: "XButton2",
                    Sleep: "500",
                    Toggle: "XButton1"
                }
            }
        )
    }

    /* # General # */
    P2ESettings.General := Object()
    if (root.Has(SettingKeys.G))
    {
        _general := root[SettingKeys.G]

        ; Beep
        P2ESettings.General.Beep := GrabValue(_general, SettingKeys.G_Beep, true)
        ; CloseToTray
        P2ESettings.General.CloseToTray := GrabValue(_general, SettingKeys.G_CloseToTray, true)
        ; Randomness
        P2ESettings.General.Randomness := GrabValue(_general, SettingKeys.G_Randomness, 80)
        ; StartMinimized
        P2ESettings.General.StartMinimized := GrabValue(_general, SettingKeys.G_StartMinimized, false)
        ; TargetedExe
        P2ESettings.General.TargetedExe := GrabValue(_general, SettingKeys.G_TargetedExe, "Notepad.exe")
        ; ActiveProfile
        P2ESettings.General.ActiveProfile := GrabValue(_general, SettingKeys.G_ActiveProfile, 0)
    }
    else
    {
        ; Default
        P2ESettings.General.Beep := true
        P2ESettings.General.CloseToTray := true
        P2ESettings.General.Randomness := 80
        P2ESettings.General.StartMinimized := false
        P2ESettings.General.TargetedExe := "Notepad.exe"
        P2ESettings.General.ActiveProfile := 1
    }

    ; Finally
    return P2ESettings
}

; Grabs a value from a dict or the default-value
GrabValue(dict, key, default)
{
    if (dict.Has(key))
        return dict[key]
    else
        return default
}

; Creates a map from the settings-obj
MapifySettings()
{
    global P2ESettings
    
    root := Map()

    /* # Profiles # */
    root[SettingKeys.P] := Array()
    for profile in P2ESettings.Profiles
    {
        _profile := Map()

        /* # ProfileSettings # */
        _profile[SettingKeys.P_ProfileSettings] := Map()
        _profile[SettingKeys.P_ProfileSettings][SettingKeys.P_ProfileName] := profile.ProfileSettings.Name
        _profile[SettingKeys.P_ProfileSettings][SettingKeys.P_Description] := profile.ProfileSettings.Description
        _profile[SettingKeys.P_ProfileSettings][SettingKeys.P_Created] := profile.ProfileSettings.Created

        /* # AutoFire # */
        _profile[SettingKeys.AF] := Map()
        _profile[SettingKeys.AF][SettingKeys.AF_Enable] := profile.AutoFire.Enable
        _profile[SettingKeys.AF][SettingKeys.AF_BoundTo] := profile.AutoFire.BoundTo
        _profile[SettingKeys.AF][SettingKeys.AF_Toggle] := profile.AutoFire.Toggle
        _hotkeys := Array()
        for hotkey in profile.AutoFire.Hotkeys
        {
            _hotkey := Map()
            _hotkey[SettingKeys.AFHK_Active] := hotkey.Active
            _hotkey[SettingKeys.AFHK_Cooldown] := hotkey.Cooldown
            _hotkey[SettingKeys.AFHK_Delay] := hotkey.Delay
            _hotkey[SettingKeys.AFHK_Hotkey] := hotkey.Hotkey
            _hotkey[SettingKeys.AFHK_Name] := hotkey.Name
            _hotkeys.Push(_hotkey)
        }
        _profile[SettingKeys.AF][SettingKeys.AF_Hotkeys] := _hotkeys

        /* # AutoMove # */
        _profile[SettingKeys.AM] := Map()
        _profile[SettingKeys.AM][SettingKeys.AM_Enable] := profile.AutoMove.Enable
        _profile[SettingKeys.AM][SettingKeys.AM_Hotkey] := profile.AutoMove.Hotkey
        _profile[SettingKeys.AM][SettingKeys.AM_IncludeAutoFire] := profile.AutoMove.IncludeAutoFire
        _profile[SettingKeys.AM][SettingKeys.AM_Interrupt] := profile.AutoMove.Interrupt
        _profile[SettingKeys.AM][SettingKeys.AM_Sleep] := profile.AutoMove.Sleep
        _profile[SettingKeys.AM][SettingKeys.AM_Toggle] := profile.AutoMove.Toggle

        ; Finally
        root[SettingKeys.P].Push(_profile)
    }

    /* # General # */
    ; Root
    root[SettingKeys.G] := Map()
    root[SettingKeys.G][SettingKeys.G_Randomness] := P2ESettings.General.Randomness
    root[SettingKeys.G][SettingKeys.G_ActiveProfile] := P2ESettings.General.ActiveProfile
    root[SettingKeys.G][SettingKeys.G_StartMinimized] := P2ESettings.General.StartMinimized
    root[SettingKeys.G][SettingKeys.G_CloseToTray] := P2ESettings.General.CloseToTray
    root[SettingKeys.G][SettingKeys.G_TargetedExe] := P2ESettings.General.TargetedExe
    root[SettingKeys.G][SettingKeys.G_Beep] := P2ESettings.General.Beep

    ; Finally
    return root
}

GetActiveProfile()
{
    if (P2ESettings.General.ActiveProfile > 0)
        return P2ESettings.Profiles[P2ESettings.General.ActiveProfile]
    else
        return P2ESettings.Profiles[1]
}