;=============================================================================================================================================================================
;
;                          
;                                                ██▓███   ▒█████  ▓█████  ███▄ ▄███▓ ▄▄▄     ▄▄▄█████▓ ██▓ ▄████▄  
;                                               ▓██░  ██▒▒██▒  ██▒▓█   ▀ ▓██▒▀█▀ ██▒▒████▄   ▓  ██▒ ▓▒▓██▒▒██▀ ▀█  
;                                               ▓██░ ██▓▒▒██░  ██▒▒███   ▓██    ▓██░▒██  ▀█▄ ▒ ▓██░ ▒░▒██▒▒▓█    ▄ 
;                                               ▒██▄█▓▒ ▒▒██   ██░▒▓█  ▄ ▒██    ▒██ ░██▄▄▄▄██░ ▓██▓ ░ ░██░▒▓▓▄ ▄██▒
;                                               ▒██▒ ░  ░░ ████▓▒░░▒████▒▒██▒   ░██▒ ▓█   ▓██▒ ▒██▒ ░ ░██░▒ ▓███▀ ░
;                                               ▒▓▒░ ░  ░░ ▒░▒░▒░ ░░ ▒░ ░░ ▒░   ░  ░ ▒▒   ▓▒█░ ▒ ░░   ░▓  ░ ░▒ ▒  ░
;                                               ░▒ ░       ░ ▒ ▒░  ░ ░  ░░  ░      ░  ▒   ▒▒ ░   ░     ▒ ░  ░  ▒   
;                                               ░░       ░ ░ ░ ▒     ░   ░      ░     ░   ▒    ░       ▒ ░░        
;                                                            ░ ░     ░  ░       ░         ░  ░         ░  ░ ░      
;                                                                                                         ░        
;             
;                                                Project: PoeMatic 
;                                            Description: An AutoHotKey-v2-script to automate certain task while playing PoE
;                                                Version: 0.2 (07/2023)
;                                                 Author: Jan Gaida (github.com/JanGaida)
;
;                                                  Goals: - Improve accessibility by reducing/automating user input (esp. for people with disabilities/impairment)
;                                                         - Reduce stress to muscle and tendon (esp. for the hand)
;                                                         - Increase fun
;
;                                             Disclaimer: This very likely will break EULA and/or TOS and might considered 'cheating'!
;                                                         Use at your own risk! Viewer discretion is advised!
;
;                                           Contribution: This shall be opensource - feel free to share, edit, contribute
;
;                            	                 License: Apache License, Version 2.0
;
;                                           Useful Links:
;                                                   Repo: https://github.com/JanGaida/PoeMatic
;                                          Documentation: https://www.autohotkey.com/docs/v2/
;                                       List of ahk-keys: https://www.autohotkey.com/docs/v2/KeyList.htm
;

#SingleInstance Force
A_HotkeyInterval := 1000 
A_MaxHotkeysPerInterval := 100



;=============================================================================================================================================================================
;
;                                                           ▄▄▄· ▄• ▄▌▄▄▄▄▄      ·▄▄▄▪  ▄▄▄  ▄▄▄ .
;                                                          ▐█ ▀█ █▪██▌•██  ▪     ▐▄▄·██ ▀▄ █·▀▄.▀·
;                                                          ▄█▀▀█ █▌▐█▌ ▐█.▪ ▄█▀▄ ██▪ ▐█·▐▀▀▄ ▐▀▀▪▄
;                                                          ▐█ ▪▐▌▐█▄█▌ ▐█▌·▐█▌.▐▌██▌.▐█▌▐█•█▌▐█▄▄▌
;                                                           ▀  ▀  ▀▀▀  ▀▀▀  ▀█▄▀▪▀▀▀ ▀▀▀.▀  ▀ ▀▀▀ 
;                                                    
;                                      Sick of playing piano? Missing critical timings? Let this automate your key-strokes …
;
; Key-Features:
;   - Automatically fires given keys within specified timings
;   - Considers manual user-input within the timing
;   - Supports more complex timings (Wip)
;   - Randomized additional delays to disguise the automated user-input
;
; Configuration:
;  +---------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  |      Variable       |                             Description                              |          Type          |                   Example                   |
;  +---------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  | Input_AutoFire      | The toggle-key used for this                                         | KEY                    | Input_AutoFire := "F13"                     |
;  +---------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  | AutoFire_BoundKey   | The trigger-key to bind too during AutoFire                          | KEY                    | AutoFire_BoundKey := "LButton"              |
;  |                     | (if not included in AutoMove via IncludeAutoFire_AutoMove )          |                        |                                             |
;  +---------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  | AutoFireKeys        | The keys to automatically fire                                       | ARRAY<New_AutoFireKey> | AutoFireKeys := Array()                     |
;  |                     | (New_AutoFireKey: key, duration_in_seconds, inital_delay_in_seconds) |                        | AutoFireKeys.Push New_AutoFireKey("5", 7.6) |
;  +---------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  | AutoFireTrackedKeys | Keys to consider for the timing when pressed manually                | ARRAY<KEY>             | AutoFireTrackedKeys := Array()              |
;  |                     |                                                                      |                        | AutoFireTrackedKeys.Push "5"                |
;  +---------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;
;=============================================================================================================================================================================
;
; Randomized delay after a fired key 
PseudoRandomDelay_Min_AutoFire := 0
PseudoRandomDelay_Max_AutoFire := 125
; Dynamic-variables
Enabled_AutoFire := False
Initalized_AutoFire := False
AutoFireKeys_Tracking := Array()
; Helper
New_AutoFireKey(key, duration, inital_delay:=0) {
	it := Map()
	it["K"] := key
	it["D"] := duration * 1000
	it["I"] := inital_delay * 1000
	return it
}

HotIfWinActive "ahk_exe PathOfExile.exe"
Hotkey Input_AutoFire, Hk_AutoFire
Hk_AutoFire(*) {
	global Enabled_AutoFire
	global Initalized_AutoFire
	Enabled_AutoFire := !Enabled_AutoFire
	
	if (Enabled_AutoFire) {	
		Initalized_AutoFire := False
	}
}

for autoFireTrackedKey in AutoFireTrackedKeys {
	Hotkey autoFireTrackedKey, Hk_AutoFire_Tracking
}
HotIfWinActive "ahk_exe PathOfExile.exe"
Hk_AutoFire_Tracking(key) {
	global Enabled_AutoFire
	global Initalized_AutoFire
	global AutoFireKeys_Tracking
	global AutoFireKeys
	global PseudoRandomDelay_Min_AutoFire
	
	Send key
	if (Enabled_AutoFire && Initalized_AutoFire) {
		idx := -1
		i := 0
		; Find the index 
		for autofirekey in AutoFireKeys {
			i := i + 1
			if (autoFireKey["K"] == key) {
				idx := i
				break
			}
		}
		if (!(idx == -1)) {
			AutoFireKeys_Tracking[idx] := A_TickCount + AutoFireKeys[idx]["D"] + Random(PseudoRandomDelay_Min_AutoFire, 100)
		}
	}
}



;=============================================================================================================================================================================
;
;                                                       ▄▄▄· ▄• ▄▌▄▄▄▄▄      • ▌ ▄ ·.        ▌ ▐·▄▄▄ .
;                                                      ▐█ ▀█ █▪██▌•██  ▪     ·██ ▐███▪▪     ▪█·█▌▀▄.▀·
;                                                      ▄█▀▀█ █▌▐█▌ ▐█.▪ ▄█▀▄ ▐█ ▌▐▌▐█· ▄█▀▄ ▐█▐█•▐▀▀▪▄
;                                                      ▐█ ▪▐▌▐█▄█▌ ▐█▌·▐█▌.▐▌██ ██▌▐█▌▐█▌.▐▌ ███ ▐█▄▄▌
;                                                       ▀  ▀  ▀▀▀  ▀▀▀  ▀█▄▀▪▀▀  █▪▀▀▀ ▀█▄▀▪. ▀   ▀▀▀ 
;
;                              Relax your index finger with AutoMove! Click left mousebutton once and just keep following the cursor …
;
; Key-Features:
;   - Interupts when you press left mousebutton manually while active for a specified amount of time
;   - Automatically corrects the mousebutton-states
;   - Can include the autofire-feature (see below)
;
; Configuration:
;  +--------------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  |         Variable         |                             Description                              |          Type          |                   Example                   |
;  +--------------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  | Input_AutoMove           | The toggle-key used for this                                         | KEY                    | Input_AutoMove := "XButton1"                |
;  +--------------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  | Input_InterupAutoMove    | The toggle-key used for this                                         | KEY                    | Input_AutoMove := "XButton2"                |
;  +--------------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  | SleepMsOnClick_AutoMove  | Sleeptimer when AutoMove has been interupted by LMB (in ms)          | NUMBER                 | SleepMsOnClick_AutoMove := 666              |
;  +--------------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  | IncludeAutoFire_AutoMove | Wether to include AutoFire while AutoMove is enabled                 | BOOL                   | IncludeAutoFire_AutoMove := True            |
;  |                          | (can be toggled independently)                                       |                        |                                             |
;  +--------------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;
;=============================================================================================================================================================================
;
; Dynamic-variables
Enabled_AutoMove := False

;InterceptSleep_AutoMove := False
InterceptUntil_AutoMove := 0
InterceptUntilActive_AutoMove := False

HotIfWinActive "ahk_exe PathOfExile.exe"
Hotkey Input_AutoMove, Hk_AutoMove
Hk_AutoMove(*) {
	global Enabled_AutoMove
	global Enabled_AutoFire
	global Initalized_AutoFire
	global InterceptUntil_AutoMove
	global Interupted_AutoMove
	global Input_InterupAutoMove
	
	; Toggle
	Enabled_AutoMove := !Enabled_AutoMove
	; AutoFire?
	if (IncludeAutoFire_AutoMove) {
		if (!Enabled_AutoFire) {
			Enabled_AutoFire := True
			Initalized_AutoFire := False
		} else {
			Enabled_AutoFire := False
		}
	}
	; Act
	if (Enabled_AutoMove) {
		if (!Interupted_AutoMove) {
			Click "Down"
		} else {
			KeyWait Input_InterupAutoMove
			Click "Down"
		}
	} else {
		InterceptUntil_AutoMove := 0
		Click "Up"
	}
}

HotIfWinActive "ahk_exe PathOfExile.exe"
~LButton:: {
	global Enabled_AutoMove
	global InterceptUntil_AutoMove
	global SleepMsOnClick_AutoMove
	
	if (Enabled_AutoMove) {
		InterceptUntil_AutoMove := A_TickCount + SleepMsOnClick_AutoMove
		Click "Up"
	}
}

HotIfWinActive "ahk_exe PathOfExile.exe"
~LButton Up:: {
	global Enabled_AutoMove
	global InterceptUntil_AutoMove
	global Interupted_AutoMove
	global Input_InterupAutoMove
	
	if (Enabled_AutoMove && InterceptUntil_AutoMove == 0) {
		if (!Interupted_AutoMove) {
			Click "Down"
		} else {
			KeyWait Input_InterupAutoMove
			Click "Down"
		}
	}
}

Interupted_AutoMove := False

HotIfWinActive "ahk_exe PathOfExile.exe"
Hotkey Input_InterupAutoMove, Hk_InteruptTemporaryAutoMove
Hk_InteruptTemporaryAutoMove(*) {
	global Interupted_AutoMove
	global Input_InterupAutoMove
	global Enabled_AutoMove
	
	Interupted_AutoMove := True
	if (Enabled_AutoMove) {
		Click "Up"
	}
	KeyWait Input_InterupAutoMove
	Interupted_AutoMove := False
	if (Enabled_AutoMove) {
		Click "Down"
	}
}


;=============================================================================================================================================================================
;
;                                                    .▄▄ · ▪   ▐ ▄  ▄▄ • ▄▄▌  ▄▄▄ .    ▄ •▄ ▄▄▄ . ▄· ▄▌   
;                                                    ▐█ ▀. ██ •█▌▐█▐█ ▀ ▪██•  ▀▄.▀·    █▌▄▌▪▀▄.▀·▐█▪██▌     
;                                                    ▄▀▀▀█▄▐█·▐█▐▐▌▄█ ▀█▄██▪  ▐▀▀▪▄    ▐▀▀▄·▐▀▀▪▄▐█▌▐█▪    
;                                                    ▐█▄▪▐█▐█▌██▐█▌▐█▄▪▐█▐█▌▐▌▐█▄▄▌    ▐█.█▌▐█▄▄▌ ▐█▀·.   
;                                                     ▀▀▀▀ ▀▀▀▀▀ █▪·▀▀▀▀ .▀▀▀  ▀▀▀     ·▀  ▀ ▀▀▀   ▀ •     
;
; 												   Need to press multiple buttons at once? Just use this …
;
; Key-Features:
;   - Supports an inital delay
;
; Configuration:
;  +---------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  |      Variable       |                             Description                              |          Type          |                   Example                   |
;  +---------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  | Input_SingleKey     | The trigger-key which triggers all specified keys                    | KEY                    | Input_SingleKey:= "<^w"                     |
;  +---------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;  | SingleKeys          | The keys to trigger with the Input_SingleKey                         | ARRAY<New_SingleKeys>  | SingleKeys := Array()                       |
;  | -                   | New_SingleKey ( key , inital_delay_in_seconds )                      | -                      | SingleKeys.Push New_SingleKey("<^e")        |
;  +---------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;
;=============================================================================================================================================================================
;
; How long to sleep during
SleepBtw_SingleKeys := 10
; Helper
New_SingleKey(key, inital_delay:=0) {
	it := Map()
	it["K"] := key
	it["I"] := inital_delay * 1000
	return it
}

HotIfWinActive "ahk_exe PathOfExile.exe"
Hotkey Input_SingleKey, Hk_SingleKey
Hk_SingleKey(*) {
	for singleAuraKey in SingleKeys {
		if (singleAuraKey["I"] > 0) {
			Sleep singleAuraKey["I"]
		}
		Send singleAuraKey["K"]
		Sleep SleepBtw_SingleKeys
	}
}



;=============================================================================================================================================================================
;
; WiP: Cursor Coordinates
; Provides a popup with information about the mouse-cursor-coordinates
;
;=============================================================================================================================================================================
;

HotIfWinActive "ahk_exe PathOfExile.exe"
Hotkey Input_ShowMouseCursorCoordinates, Hk_ShowMouseCursorCoordinates
Hk_ShowMouseCursorCoordinates(*) {
	MouseGetPos &xpos, &ypos, &id, &control
	Result := MsgBox("Cursorcoordinates:`n X: " xpos ", Y: " ypos "`n`nId: " id "`nWinClass: " WinGetClass(id) "`nWinTitle: " WinGetTitle(id) "`n`n Would you like to copy the coordinates?",, "YesNo")
	if Result = "Yes"
		A_Clipboard := "X: " xpos ", Y: " ypos
	return
}



;=============================================================================================================================================================================
;
; Wip: SCOURING CRAFTING
; Uses a orb of scouring on an item and then uses another orb on the item.
;
; !! CAUTION: PLEASE SETUP BEFORE USING IT, BY DEFINING THE REQUIRED COORDINATES BELOW !!
;
;=============================================================================================================================================================================
; 
; Dynamic-variables
LastTime_ScouringCrafting := 20000101010001
TimeoutMinutes_ScouringCrafting := 10
Enabled_ScouringCrafting := False

HotIfWinActive "ahk_exe PathOfExile.exe"
Hotkey Input_ScouringCrafting, Hk_ScouringCrafting
Hk_ScouringCrafting(*) {
	global LastTime_ScouringCrafting
	global Enabled_ScouringCrafting
	global TimeoutMinutes_ScouringCrafting
	; Enable/Disable
	LastTimeDiffMin := DateDiff(LastTime_ScouringCrafting, A_Now, "Minutes")
	if (!Enabled_ScouringCrafting && LastTimeDiffMin < TimeoutMinutes_ScouringCrafting) {
		Result := MsgBox("Enable 'ScouringCrafting'?",, "YesNo")
		if Result = "Yes"
			Enabled_ScouringCrafting := True
		else 
			Enabled_ScouringCrafting := False
	}
	; Execute
	if (Enabled_ScouringCrafting) {
		LastTime_ScouringCrafting := A_Now
		;Move to the scouring
		MouseMove(XPos_OrbOfScouring, YPos_OrbOfScouring, CursorSpeed_ScouringCrafting)
		Sleep MvSleep_OrbOfScouring
		MouseClick "right", XPos_OrbOfScouring, YPos_OrbOfScouring, 1, 0, "D"
		Sleep MvSleep_OrbOfScouring
		MouseClick "right", XPos_OrbOfScouring, YPos_OrbOfScouring, 1, 0, "U"
		Sleep MvSleep_OrbOfScouring
		;Apply the scouring
		MouseMove(XPos_CraftableItem, YPos_CraftableItem, CursorSpeed_ScouringCrafting)
		Sleep MvSleep_OrbOfScouring
		MouseClick "left", XPos_CraftableItem, YPos_CraftableItem, 1, 0, "D"
		Sleep MvSleep_OrbOfScouring
		MouseClick "left", XPos_CraftableItem, YPos_CraftableItem, 1, 0, "U"
		Sleep MvSleep_OrbOfScouring
		;Move to the crafting-orb
		MouseMove(XPos_CraftingOrb, YPos_CraftingOrb, CursorSpeed_ScouringCrafting)
		Sleep MvSleep_OrbOfScouring
		MouseClick "right", XPos_CraftingOrb, YPos_CraftingOrb, 1, 0, "D"
		Sleep MvSleep_OrbOfScouring
		MouseClick "right", XPos_CraftingOrb, YPos_CraftingOrb, 1, 0, "U"
		Sleep MvSleep_OrbOfScouring
		;Apply the crafting-orb
		MouseMove(XPos_CraftableItem, YPos_CraftableItem, CursorSpeed_ScouringCrafting)
		Sleep MvSleep_OrbOfScouring
		MouseClick "left", XPos_CraftableItem, YPos_CraftableItem, 1, 0, "D"
		Sleep MvSleep_OrbOfScouring
		MouseClick "left", XPos_CraftableItem, YPos_CraftableItem, 1, 0, "U"
		Sleep MvSleep_OrbOfScouring
	}
}



;=============================================================================================================================================================================
;
;                                                                           • ▌ ▄ ·.  ▄▄▄· ▪   ▐ ▄ 
;                                                                           ·██ ▐███▪▐█ ▀█ ██ •█▌▐█
;                                                                           ▐█ ▌▐▌▐█·▄█▀▀█ ▐█·▐█▐▐▌
;                                                                           ██ ██▌▐█▌▐█ ▪▐▌▐█▌██▐█▌
;                                                                           ▀▀  █▪▀▀▀ ▀  ▀ ▀▀▀▀▀ █▪
;                                                             
; 																	From here the main-loop will be called …
;
;=============================================================================================================================================================================
;
; Dynamic-variables
MainLoop_Sleep := 15
LastLoop := 0

Loop {
	global MainLoop_Sleep
	global PseudoRandomDelay_Min_AutoFire
	global PseudoRandomDelay_Max_AutoFire
	global Enabled_AutoFire
	global Initalized_AutoFire
	global AutoFire_BoundKey
	global AutoFireKeys 
	global AutoFireKeys_Tracking
	global Enabled_AutoMove
	global InterceptUntil_AutoMove
	
	global Interupted_AutoMove
	global Input_InterupAutoMove
	
	if (WinActive("Path of Exile")) {
		_A_TickCount := A_TickCount
		; AutoMove
		if (Enabled_AutoMove && !Interupted_AutoMove) {
			; Correct LButton?
			if (InterceptUntil_AutoMove == 0) {
				if (!GetKeyState("LButton")) {
					Click "Down"
				}
			}
			; Restart after inception?
			else if (InterceptUntil_AutoMove < _A_TickCount) {
				InterceptUntil_AutoMove := 0
				if (!GetKeyState("LButton")) {
					Click "Down"
				}
			}
		}
		
		; AutoFire
		if (
			Enabled_AutoFire 
			&& (Enabled_AutoMove || GetKeyState("LButton"))
		) {
			; Initalize?
			if (!Initalized_AutoFire) {	
				AutoFireKeys_Tracking := Array()
				for autoFireKey in AutoFireKeys {
					AutoFireKeys_Tracking.Push _A_TickCount + autoFireKey["I"]
				}
				Initalized_AutoFire := True
			}
			
			; Calculate random delay 
			rndDelay := Random(PseudoRandomDelay_Min_AutoFire, 100)
			
			idx := 1
			for nextTick in AutoFireKeys_Tracking {
				_A_TickCount := A_TickCount
				if _A_TickCount >= nextTick {
					autoFireKey := AutoFireKeys[idx]
					; fire the key
					Send autoFireKey["K"]
					; set next fire time
					AutoFireKeys_Tracking[idx] := _A_TickCount + autoFireKey["D"] + rndDelay
				}
				; next
				idx := idx + 1
			}
		}
	}
	; To keep cpu-usage low
	Sleep MainLoop_Sleep
}