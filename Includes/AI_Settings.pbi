; ##################################################### Documentation ###############################################
; 
; 
; 
; 
; 
; 
; 

; ##################################################### Includes ####################################################

; ##################################################### Prototypes ##################################################

; ##################################################### Structures ##################################################

; ##################################################### Constants ###################################################

; ##################################################### Structures ##################################################

Structure AI_Settings_Main
  
EndStructure
Global AI_Settings_Main.AI_Settings_Main

Structure AI_Settings
  Window_ID.i
  Window_Close.l
  
  ; #### Gadgets
  ListView.i
  
  Text.i[10]
  String.i
  
  Button.i
EndStructure
Global AI_Settings.AI_Settings

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Init ########################################################

;Global AI_Settings_Font = LoadFont(#PB_Any, "Arial", 12)

; ##################################################### Declares ####################################################

Declare   AI_Settings_Close()

; ##################################################### Procedures ##################################################

Procedure AI_Settings_Event_ListView()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  AI_Change(GetGadgetState(Event_Gadget))
  
  If Event_Type = #PB_EventType_LeftDoubleClick
    AI_Settings\Window_Close = #True
  EndIf
  
EndProcedure

Procedure AI_Settings_Event_String()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  AI_Main\Delay = Val(GetGadgetText(Event_Gadget))
  
EndProcedure

Procedure AI_Settings_Event_Button()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  AI_Settings\Window_Close = #True
EndProcedure

Procedure AI_Settings_Event_SizeWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
EndProcedure

Procedure AI_Settings_Event_ActivateWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
EndProcedure

Procedure AI_Settings_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
EndProcedure

Procedure AI_Settings_Event_CloseWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  ;AI_Settings_Close()
  AI_Settings\Window_Close = #True
EndProcedure

Procedure AI_Settings_Open()
  Protected Width, Height
  
  If AI_Settings\Window_ID = 0
    
    Width = 300
    Height = 300
    
    AI_Settings\Window_ID = OpenWindow(#PB_Any, 0, 0, Width, Height, "AI Settings", #PB_Window_SystemMenu | #PB_Window_WindowCentered, WindowID(Main_Window\ID))
    
    AI_Settings\ListView = ListViewGadget(#PB_Any, 0, 0, Width, Height-40)
    ForEach AI()
      AddGadgetItem(AI_Settings\ListView, ListIndex(AI()), AI()\Name)
      If AI_Main\AI = AI()
        SetGadgetState(AI_Settings\ListView, ListIndex(AI()))
      EndIf
    Next
    
    AI_Settings\Button = ButtonGadget(#PB_Any, Width - 70, Height - 30, 60, 20, "OK")
    AI_Settings\Text[0] = TextGadget(#PB_Any, 10, Height - 30, 60, 20, "Step delay:", #PB_Text_Right)
    AI_Settings\String = StringGadget(#PB_Any, 80, Height - 30, 50, 20, Str(AI_Main\Delay), #PB_String3D_Numeric)
    
    BindGadgetEvent(AI_Settings\ListView, @AI_Settings_Event_ListView())
    BindGadgetEvent(AI_Settings\String, @AI_Settings_Event_String())
    BindGadgetEvent(AI_Settings\Button, @AI_Settings_Event_Button())
    
    ;BindEvent(#PB_Event_SizeWindow, @AI_Settings_Event_SizeWindow(), AI_Settings\Window_ID)
    ;BindEvent(#PB_Event_Repaint, @AI_Settings_Event_SizeWindow(), AI_Settings\Window_ID)
    ;BindEvent(#PB_Event_RestoreWindow, @AI_Settings_Event_SizeWindow(), AI_Settings\Window_ID)
    ;BindEvent(#PB_Event_Menu, @AI_Settings_Event_Menu(), AI_Settings\Window_ID)
    BindEvent(#PB_Event_CloseWindow, @AI_Settings_Event_CloseWindow(), AI_Settings\Window_ID)
    
  EndIf
EndProcedure

Procedure AI_Settings_Close()
  If AI_Settings\Window_ID
    
    UnbindGadgetEvent(AI_Settings\ListView, @AI_Settings_Event_ListView())
    UnbindGadgetEvent(AI_Settings\String, @AI_Settings_Event_String())
    UnbindGadgetEvent(AI_Settings\Button, @AI_Settings_Event_Button())
    
    ;UnbindEvent(#PB_Event_SizeWindow, @AI_Settings_Event_SizeWindow(), AI_Settings\Window_ID)
    ;UnbindEvent(#PB_Event_Repaint, @AI_Settings_Event_SizeWindow(), AI_Settings\Window_ID)
    ;UnbindEvent(#PB_Event_RestoreWindow, @AI_Settings_Event_SizeWindow(), AI_Settings\Window_ID)
    ;UnbindEvent(#PB_Event_Menu, @AI_Settings_Event_Menu(), AI_Settings\Window_ID)
    UnbindEvent(#PB_Event_CloseWindow, @AI_Settings_Event_CloseWindow(), AI_Settings\Window_ID)
    
    CloseWindow(AI_Settings\Window_ID)
    AI_Settings\Window_ID = 0
  EndIf
EndProcedure

Procedure AI_Settings_Main()
  If Not AI_Settings\Window_ID
    ProcedureReturn #False
  EndIf
  
  If AI_Settings\Window_Close
    AI_Settings\Window_Close = #False
    AI_Settings_Close()
  EndIf
  
EndProcedure

; ##################################################### Initialisation ##############################################



; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 7
; FirstLine = 30
; Folding = --
; EnableUnicode
; EnableXP