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

; The key to bound to automatically fire (if not included in AutoMove via IncludeAutoFire_AutoMove )
AutoFire_BoundKey := "LButton"

; Toggles AutoFire
Input_AutoFire := "F13"

; Keys to automatically fire
AutoFireKeys := Array()
; New_AutoFireKey ( key , duration_in_seconds , inital_delay_in_seconds )
AutoFireKeys.Push New_AutoFireKey("5", 7.6 * 1.23)
AutoFireKeys.Push New_AutoFireKey("t", 6.38/2, 0)
;AutoFireKeys.Push New_AutoFireKey("f", 8.95)
AutoFireKeys.Push New_AutoFireKey("f", 1.8, 0.5)

; Keys to consider during autofire if manually pressed
AutoFireTrackedKeys := Array()
AutoFireTrackedKeys.Push "5"
AutoFireTrackedKeys.Push "t"



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
;  | Input_AutoMove           | The toggle-key used for this                                         | KEY                    | Input_AutoMove := "XButton2"                |
;  | SleepMsOnClick_AutoMove  | Sleeptimer when AutoMove has been interupted by LMB (in ms)          | NUMBER                 | SleepMsOnClick_AutoMove := 666              |
;  | IncludeAutoFire_AutoMove | Wether to include AutoFire while AutoMove is enabled                 | BOOL                   | IncludeAutoFire_AutoMove := True            |
;  |                          | (can be toggled independently)                                       |                        |                                             |
;  +--------------------------+----------------------------------------------------------------------+------------------------+---------------------------------------------+
;
;=============================================================================================================================================================================


; The trigger-key which enables AutoMove
Input_AutoMove := "XButton2" ; == Mousebutton-Next
;Input_AutoMove := "~<!LButton Up"

; Sleeptimer when AutoMove has been interupted by LMB (in milliseconds)
SleepMsOnClick_AutoMove := 666

; Wether to include AutoFire while AutoMove is enabled (can be toggled independently; see Input_AutoFire)
IncludeAutoFire_AutoMove := True    



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

; The trigger-key which triggers all specified keys
Input_SingleKey:= "<^w" ; == Ctrl + W

; Keys to concatinate when using the aura-key
SingleKeys := Array()
; New_SingleKeys ( key , inital_delay_in_seconds )
SingleKeys.Push New_SingleKey("<^w")
SingleKeys.Push New_SingleKey("<^e")
SingleKeys.Push New_SingleKey("<^r")
SingleKeys.Push New_SingleKey("<^t")



;=============================================================================================================================================================================
;
;                                                                              ▄▄▌ ▐ ▄▌▪   ▄▄▄·
;                                                                              ██· █▌▐███ ▐█ ▄█
;                                                                              ██▪▐█▐▐▌▐█· ██▀·
;                                                                              ▐█▌██▐█▌▐█▌▐█▪·•
;                                                                               ▀▀▀▀ ▀▪▀▀▀.▀   
;                                                               
;                                                          Here are some work-inprogres scripts, for tasks like …
;                                                          - Crafting (eg. automatic crafting with scouring orbs)
;                                                                      Show the mousepositions
;
;=============================================================================================================================================================================

Input_ShowMouseCursorCoordinates := "F9"
Input_ScouringCrafting := "F10"

; Movingspeed of the cursor: 0 (fastest) - 100 (slowest)
CursorSpeed_ScouringCrafting := 80 
; The coordinates of the orb of scouring
XPos_OrbOfScouring := 575
YPos_OrbOfScouring := 690
; The coordinates of the craftable item
XPos_CraftableItem := 447
YPos_CraftableItem := 646
; The coordinates of the orb to use on the item
XPos_CraftingOrb := 670
YPos_CraftingOrb := 373
; Ms between server-actions
MvSleep_OrbOfScouring := 25



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
#Include "PoeMatic.ahk"