#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsBuffer false
#Include "P2EGui.ahk" ; Contains the GUI-functionality
#Include "P2ESync.ahk" ; Contains the synchronization of the settings

; ! AHK Settings
A_HotkeyInterval := 999000
A_MaxHotkeysPerInterval := 999000
ProcessSetPriority("High")
KeyHistory(false)
ListLines(false)
SetKeyDelay(-1)
SetMouseDelay(-1)
SetDefaultMouseSpeed(0)
SetWinDelay(-1)
SetControlDelay(-1)
Persistent


; ! VARS
; Cache
ActiveHotkeys := Array() ; List of ahk-hotkeys in usage
ActiveHooks := Array() ; List of windows-hooks in usage
HookedToWindowEvents := false
HookedToMouseEvents := false
; AF
AF_Hotkeys := Array() ; List of af-hotkey
AF_TimeTracking := Array() ; List of next fireTimes
AF_Active := false
; AM
AM_Active := unset
AM_IncludeAF := unset
; Exe
ExeHwnd := unset
ExeName := unset
ExeIsActive := false
; Sound
S_Active := true
S_BOOT := 523
S_REBOOT := 262
S_FOUND := 785
S_DURATION := 140
S_DURATION_SHORT := 80


; ! RUN

; * Load all user-settings
LoadSettings()
    
; * Hook to window-changes-events
HookToWindowEvents()

; * Boot all features
BootFeatures()


; ! FUNCTIONS

/* # HELPER # */

; Searches for the exe
FindExeHwnd()
{
    global ExeHwnd
    global ExeName
    global ExeIsActive
    global S_Active

    ; Params
    CheckIntervalMs := 1000
    CheckPriority := 1

    ; Run
    ExeTitle := "ahk_exe " ExeName
    try
    {
        ExeHwnd := WinGetID("ahk_exe " ExeName)
        if (IsSet(ExeHwnd))
        {
            ActiveHwnd := WinActive(ExeTitle)
            ExeIsActive := ActiveHwnd == ExeHwnd

            if (S_Active)
                SoundBeep(S_FOUND, S_DURATION)
        }
        else
        {
            ; Check later again
            SetTimer(FindExeHwnd, CheckIntervalMs * -1, CheckPriority)
        }
    }
    catch
    {
        ; Exe is not active
        ExeHwnd := "-9"
        if (ExeIsActive != false)
            ExeIsActive := false
        
        ; Check later again
        SetTimer(FindExeHwnd, CheckIntervalMs * -1, CheckPriority)
    }
}

; Creates a specified hook for WinEvents
HookToWindowEvents()
{
    global HookedToWindowEvents

    static EVENT_SYSTEM_FOREGROUND := 0x0003
    static EVENT_OBJECT_DESTROY := 0x8001

    if (!HookedToWindowEvents)
    {
        ; Create a ref
        static Ref_OnWindowEvent := CallbackCreate(OnWindowEvent)
        ; Enqueue the it
        static Hook_OnWindowEvent_1 := SetWindowsEventHook(EVENT_SYSTEM_FOREGROUND,Ref_OnWindowEvent)
        static Hook_OnWindowEvent_2 := SetWindowsEventHook(EVENT_OBJECT_DESTROY,Ref_OnWindowEvent)
        HookedToWindowEvents := true
    }

    ; Callback
    OnWindowEvent(winEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime)
    {
        global ExeHwnd
        global ExeIsActive
        global AF_Active
        global S_Active

        switch event
        {
            ; A window moved into the foreground
            case EVENT_SYSTEM_FOREGROUND:
                if (IsSet(ExeHwnd))
                {
                    ; Determine if the exe is still active
                    ExeIsActive := hwnd == ExeHwnd
                }
                else
                {
                    ExeIsActive := false
                }

                ; With that change..
                if (ExeIsActive)
                {
                    ; Restart AF
                    AutoFire_SetLoop(AF_Active)
                }
                else
                {
                    ; Relase AM?
                    if (GetKeyState("LButton"))
                        SendEvent("{LButton up}") ;SendInput("{LButton up}")
                }

            
            ; A window-like destroyed
            case EVENT_OBJECT_DESTROY:
                if (IsSet(ExeHwnd) && hwnd == ExeHwnd) 
                {
                    ; Search for the exe again
                    FindExeHwnd()

                    if (S_Active)
                    {
                        SoundBeep(S_FOUND, S_DURATION_SHORT)
                        SoundBeep(S_FOUND, S_DURATION_SHORT)
                    }
                }
        }
        
        ; ! Has side-effect; eg. create a new window by copying a tab out of a window (= eg. browser-tab) - more?
        ; Todo: Call-Next-Hook?
        return
    }
}

; Setup for all AutoMove related features
SetupAutoMove()
{
    global P2ESettings
    global HookedToMouseEvents

    ; Ref
    static WH_MOUSE_LL := 14
    static WM_MOUSEMOVE := 0x0200
    static WM_LBUTTONDOWN := 0x0201
    static WM_LBUTTONUP := 0x0202
    static WM_RBUTTONDOWN := 0x0204
    static WM_RBUTTONUP := 0x0205
    static WM_MOUSEWHEEL := 0x020A
    
    ; State
    static AM_INTERRUPTED := false
    
    ; Params
    static AM_PRIORITY := 1
    static AM_TARGET := "LButton" ; Todo: Make user-config + change with WASD?
    static AM_SLEEP := Integer(GetActiveProfile().AutoMove.Sleep)
    static AM_TOGGLE_HK := GetActiveProfile().AutoMove.Toggle
    static AM_INTERRUPT_HK := GetActiveProfile().AutoMove.Interrupt

    ; Validate
    if (AM_SLEEP > 0)
    {
        AM_SLEEP := -1 * AM_SLEEP
    }
    else if (AM_SLEEP == 0)
    {
        hardFallBackValue := 500
        GetActiveProfile().AutoMove.Sleep := 500
        AM_SLEEP := -1 * hardFallBackValue
    }
    
    if (!HookedToMouseEvents)
    {
        ; Create a ref
        static Ref_OnWindowEvent := CallbackCreate(OnMouseEventEvent)
        ; Enqueue the it
        static Hook_OnMouseEventEvent := SetWindowsHookExA(WH_MOUSE_LL, Ref_OnWindowEvent)
        
        HookedToMouseEvents := true
    }

    ; Callback
    OnMouseEventEvent(nCode, event, lParam)
    {
        global ExeIsActive
        global AM_Active
        
        if (AM_Active && ExeIsActive && nCode >= 0 && WM_LBUTTONUP == event)
        {
            ; Press down once after sleeping
            SetTimer(AutMove_PressDown, AM_SLEEP, AM_PRIORITY)
        }
        
        ; Call potential other hooks
        return CallNextHookEx(nCode, event, lParam)
    }

    ; Send LButton-Down if appropriate
    AutMove_PressDown()
    {
        global AM_Active
        global ExeIsActive

        if (ExeIsActive && AM_Active && !AM_INTERRUPTED)
        {
            ; Send the input
            SendEvent("{" AM_TARGET " down}") ;SendInput("{" AM_TARGET " down}")
        }
    }

    ; Sends LButton-Up if appropriate
    AutoMove_Release()
    {
        global ExeIsActive

        if (ExeIsActive && GetKeyState(AM_TARGET))
            SendEvent("{" AM_TARGET " up}") ;SendInput("{" AM_TARGET " up}")
    }

    ; Hotkeys only during exe scope
    HotIf (*) => ExeIsActive

        ; AM Toggle
        Hotkey(AM_TOGGLE_HK, AutoMove_Hotkey_Toggle, "On")
        AutoMove_Hotkey_Toggle(*)
        {
            global AM_Active
            global AM_IncludeAF
            global AF_Active

            ; Toggle state
            AM_Active := !AM_Active

            ; Include AF?
            if (AM_IncludeAF)
                AutoFire_SetLoop(AM_Active)
            
            ; Update LMB
            if (AM_Active && !AM_INTERRUPTED)
            {
                AutMove_PressDown()
            }
            else
            {
                SendEvent("{LButton up}")
            }
        }
        ActiveHotkeys.Push({Hotkey: AM_TOGGLE_HK, Callback: AutoMove_Hotkey_Toggle})

        ; AM Interrupt
        Hotkey(AM_INTERRUPT_HK, AutoMove_Hotkey_Interrupt, "On")
        AutoMove_Hotkey_Interrupt(*)
        {
            ; Toggle and release
            AM_INTERRUPTED := true
            AutoMove_Release()

            ; Wait for key-release
            KeyWait(AM_INTERRUPT_HK)
            
            ; Toggle back and press down
            AM_INTERRUPTED := false
            AutMove_PressDown()
        }
        ActiveHotkeys.Push({Hotkey: AM_INTERRUPT_HK, Callback: AutoMove_Hotkey_Interrupt})

    ; Remove scope
    HotIf
}

; Setup for all AutoFire related features
SetupAutoFire()
{
    global ExeIsActive
    global AF_Hotkeys
    global AF_TimeTracking
    global AF_Active

    ; Vars
    static AF_Hotkey := GetActiveProfile().AutoFire.BoundTo
    for hk in GetActiveProfile().AutoFire.Hotkeys
    {
        ; Only active ones
        if (hk.Active)
        {
            _hotkey := {
                Key: hk.Hotkey,
                Cooldown: Integer(hk.Cooldown),
                Delay: Integer(hk.Delay)
            }

            ; Sanitate
            if (_hotkey.Cooldown <= 0)
            {
                _hotkey.Cooldown := 100
            }
            if (_hotkey.Delay < 0)
            {
                _hotkey.Delay := 0
            }
            
            ; Finally
            AF_Hotkeys.Push(_hotkey)
        }
    }
    ; Track them
    for hk in AF_Hotkeys
    {
        AF_TimeTracking.Push(A_TickCount + hk.Delay)
    }

    ; Hotkeys only during exe scope
    HotIf (*) => ExeIsActive

        static DynHotkeyLookUp := Map()

        ; Also setup hotkey to listen for manual time-changes
        for hk in AF_Hotkeys
        {
            Hotkey("~" hk.Key, AutoFire_Hotkey_Dynamic, "On")
            AutoFire_Hotkey_Dynamic(hotkeyName)
            {
                global AF_TimeTracking

                ; Update the next firetime
                idx := DynHotkeyLookUp[hotkeyName]
                AF_TimeTracking[idx] := A_TickCount + AF_Hotkeys[idx].Cooldown
            }
            DynHotkeyLookUp["~" hk.Key] := A_Index
            ActiveHotkeys.Push({Hotkey: "~" hk.Key, Callback: AutoFire_Hotkey_Dynamic})
        }

    ; Hotkeys only during exe scope
    HotIf (*) => ExeIsActive

        ; AF Toggle
        Hotkey("~" AF_Hotkey, AutoFire_Hotkey_Toggle, "On")
        AutoFire_Hotkey_Toggle(*)
        {
            global AF_Active 
            AutoFire_SetLoop(!AF_Active)
        }
        ActiveHotkeys.Push({Hotkey: "~" AF_Hotkey, Callback: AutoFire_Hotkey_Toggle})

    ; Remove scope
    HotIf
}

; Sets the AutoFire-Loop in a given state
AutoFire_SetLoop(state)
{
    global AF_Active 

    static AF_LOOP_ALIVE := false

    ; Update the state
    if (AF_Active != state)
        AF_Active := state

    ; Start/Stop?
    if (AF_Active)
    {
        if (!AF_LOOP_ALIVE)
        {
            ; Start the loop immediately
            SetTimer(AutoFire_CoreLoop, -1, 1)
            AF_LOOP_ALIVE := true
        }
    }
    else
    {
        if (AF_LOOP_ALIVE)
        {
            ; Stop the loop immediately
            SetTimer(AutoFire_CoreLoop, 0, 1)
            AF_LOOP_ALIVE := false
        }
    }

    ; The AF-Loop (timeTarget-aware)
    AutoFire_CoreLoop()
    {
        global AF_TimeTracking
        global AF_Hotkeys

        ; Param
        static AF_Loop_MaxSleep := 5000 ; Todo: Make setting?
        static AF_Rand_Max := Integer(P2ESettings.General.Randomness)

        ; Check if still active
        if (!ExeIsActive || !AF_Active)
            return

        now := A_TickCount
        rand := Random(1, AF_Rand_Max)
        nextTimeTarget := now + AF_Loop_MaxSleep

        for timeTarget in AF_TimeTracking
        {
            ; Check if the hotkey is due
            if (now > timeTarget)
            {
                hk := AF_Hotkeys[A_Index]
                
                ; DoubleCheck if input can be send
                if (ExeIsActive && AF_Active)
                {
                    SendEvent(hk.Key) ; SendInput(hk.Key)
                    newTimeTarget := A_TickCount + hk.Cooldown - rand
                    AF_TimeTracking[A_Index] := newTimeTarget

                    ; Is the next timeTarget?
                    if (nextTimeTarget > newTimeTarget)
                        nextTimeTarget := newTimeTarget
                }
            }
            else
            {
                ; Is the next timeTarget?
                if (nextTimeTarget > timeTarget)
                    nextTimeTarget := timeTarget
            }
        }

        ; Repeat
        ;OutputDebug("A_TickCount:" A_TickCount " - nextTimeTarget:" nextTimeTarget "`n")
        nextRun := A_TickCount - nextTimeTarget
        if (nextRun >= 0) ; 0 would stop the timer; >0 would increase the callstack
            nextRun := -10

        SetTimer(AutoFire_CoreLoop, nextRun, 0)
    }
}

; Starts all features for this script
BootFeatures()
{
    global ExeName
    global ExeIsActive
    global AM_Active
    global AM_IncludeAF
    global AF_Active
    global S_BOOT
    global S_DURATION
    global S_Active

    S_Active := P2ESettings.General.Beep

    if (S_Active)
        SoundBeep(S_BOOT, S_DURATION)

    ; * Search for the targeted exe's hwnd until found
    ExeName := P2ESettings.General.TargetedExe
    ExeIsActive := false
    FindExeHwnd()

    ; * AutoMove
    AM_Active := false
    AM_IncludeAF := GetActiveProfile().AutoMove.IncludeAutoFire
    if (GetActiveProfile().AutoMove.Enable)
        SetupAutoMove()

    ; * AutoFire
    AF_Active := false
    if (GetActiveProfile().AutoFire.Enable)
        SetupAutoFire()

    ; * Show
    if (!P2ESettings.General.StartMinimized)
        FindGui()
}

; Unloads all features and boots them up again
Reload(*) 
{
    global ActiveHooks
    global ActiveHotkeys
    global S_REBOOT
    global S_DURATION
    global S_Active

    if (S_Active)
        SoundBeep(S_REBOOT, S_DURATION)

    ; Unhook
    /* ! Causes the new hooks to be dead
    for (hook in ActiveHooks)
    {
        if (hook.Type == "WinEventHook")
        {
            UnhookWinEventHook(hook.Ptr)
        }
        else if (hook.Type == "WindowsHookExA")
        {
            UnhookWindowsHookEx(hook)
        }
    }
    ActiveHooks := Array()
    */

    ; Disable hotkeys
    for (hk in ActiveHotkeys)
    {
        try
        {
            Hotkey(hk.Hotkey, hk.Callback, "Off")
        }
        catch  ; == Does not exist
        {}
    }
    ActiveHotkeys := Array()

    ; Load all features again
    BootFeatures()
}

/* # API # */

; Hooks to SetWindowsHookExA
SetWindowsHookExA(idHook, lpfn, dwThreadId := 0)
{
    Hook := DllCall(
        "SetWindowsHookExA", 
        "int", idHook,
        "Ptr", lpfn, 
        "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr"), 
        "UInt", dwThreadId ; Todo: hook only to a given .EXE ?
    )

    ; Remember it
    ActiveHooks.Push({
        Type: "WindowsHookExA",
        Ptr: Hook
    })
    return Hook
}

; Calls the next hook via CallNextHookEx
CallNextHookEx(nCode, wParam, lParam, hHook := 0)
{
    Return DllCall(
        "CallNextHookEx", 
        "Ptr", hHook, 
        "int", nCode, 
        "Ptr", wParam, 
        "Ptr", lParam
    )
}

; Hooks to SetWinEventHook
SetWindowsEventHook(event, lpfnWinEventProc, hmodWinEventProc := 0, idProcess := 0, idThread := 0, dwflags := 0)
{
    ; Create the hook
    Hook := DllCall( 
        "SetWinEventHook",
        "UInt", event,
        "UInt", event,
        "Ptr", hmodWinEventProc, 
        "Ptr", lpfnWinEventProc, 
        "UInt", idProcess,
        "UInt", idThread, 
        "UInt", dwflags 
    )

    ; Remember it
    ActiveHooks.Push({
        Type: "WinEventHook",
        Ptr: Hook
    })
    return Hook
}

; Removes a Windows-Hook
UnhookWindowsHookEx(hHook)
{
   Return DllCall("UnhookWindowsHookEx", "Ptr", hHook)
}

; Removes a WinEvent-Hook
UnhookWinEventHook(hHook)
{
    Return DllCall("UnhookWinEvent", "Ptr", hHook)
}