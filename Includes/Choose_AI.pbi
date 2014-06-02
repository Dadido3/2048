
; ##################################################### Dokumentation / Kommentare ##################################
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

Structure Choose_AI_Main
  
EndStructure
Global Choose_AI_Main.Choose_AI_Main

Structure Choose_AI
  Window_ID.i
  Window_Close.l
  
  ; #### Gadgets
  ListView.i
  
  Button.i
EndStructure
Global Choose_AI.Choose_AI

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Init ########################################################

Global Choose_AI_Font = LoadFont(#PB_Any, "Arial", 12)

; ##################################################### Declares ####################################################

Declare   Choose_AI_Close()

; ##################################################### Procedures ##################################################

Procedure Choose_AI_Event_ListView()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  AI_Change(GetGadgetState(Event_Gadget))
  
  If Event_Type = #PB_EventType_LeftDoubleClick
    Choose_AI\Window_Close = #True
  EndIf
  
EndProcedure

Procedure Choose_AI_Event_Button()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Choose_AI\Window_Close = #True
EndProcedure

Procedure Choose_AI_Event_SizeWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
EndProcedure

Procedure Choose_AI_Event_ActivateWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
EndProcedure

Procedure Choose_AI_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
EndProcedure

Procedure Choose_AI_Event_CloseWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  ;Choose_AI_Close()
  Choose_AI\Window_Close = #True
EndProcedure

Procedure Choose_AI_Open()
  Protected Width, Height
  
  If Choose_AI\Window_ID = 0
    
    Width = 300
    Height = 200
    
    Choose_AI\Window_ID = OpenWindow(#PB_Any, 0, 0, Width, Height, "Choose AI", #PB_Window_SystemMenu | #PB_Window_WindowCentered, WindowID(Main_Window\ID))
    
    Choose_AI\ListView = ListViewGadget(#PB_Any, 0, 0, Width, Height-50)
    ForEach AI()
      AddGadgetItem(Choose_AI\ListView, ListIndex(AI()), AI()\Name)
      If AI_Main\AI = AI()
        SetGadgetState(Choose_AI\ListView, ListIndex(AI()))
      EndIf
    Next
    
    Choose_AI\Button = ButtonGadget(#PB_Any, Width - 70, Height - 40, 60, 30, "OK")
    
    BindGadgetEvent(Choose_AI\ListView, @Choose_AI_Event_ListView())
    BindGadgetEvent(Choose_AI\Button, @Choose_AI_Event_Button())
    
    ;BindEvent(#PB_Event_SizeWindow, @Choose_AI_Event_SizeWindow(), Choose_AI\Window_ID)
    ;BindEvent(#PB_Event_Repaint, @Choose_AI_Event_SizeWindow(), Choose_AI\Window_ID)
    ;BindEvent(#PB_Event_RestoreWindow, @Choose_AI_Event_SizeWindow(), Choose_AI\Window_ID)
    ;BindEvent(#PB_Event_Menu, @Choose_AI_Event_Menu(), Choose_AI\Window_ID)
    BindEvent(#PB_Event_CloseWindow, @Choose_AI_Event_CloseWindow(), Choose_AI\Window_ID)
    
  EndIf
EndProcedure

Procedure Choose_AI_Close()
  If Choose_AI\Window_ID
    
    UnbindGadgetEvent(Choose_AI\ListView, @Choose_AI_Event_ListView())
    UnbindGadgetEvent(Choose_AI\Button, @Choose_AI_Event_Button())
    
    ;UnbindEvent(#PB_Event_SizeWindow, @Choose_AI_Event_SizeWindow(), Choose_AI\Window_ID)
    ;UnbindEvent(#PB_Event_Repaint, @Choose_AI_Event_SizeWindow(), Choose_AI\Window_ID)
    ;UnbindEvent(#PB_Event_RestoreWindow, @Choose_AI_Event_SizeWindow(), Choose_AI\Window_ID)
    ;UnbindEvent(#PB_Event_Menu, @Choose_AI_Event_Menu(), Choose_AI\Window_ID)
    UnbindEvent(#PB_Event_CloseWindow, @Choose_AI_Event_CloseWindow(), Choose_AI\Window_ID)
    
    CloseWindow(Choose_AI\Window_ID)
    Choose_AI\Window_ID = 0
  EndIf
EndProcedure

Procedure Choose_AI_Main()
  If Not Choose_AI\Window_ID
    ProcedureReturn #False
  EndIf
  
  If Choose_AI\Window_Close
    Choose_AI\Window_Close = #False
    Choose_AI_Close()
  EndIf
  
EndProcedure

; ##################################################### Initialisation ##############################################



; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 58
; FirstLine = 33
; Folding = --
; EnableUnicode
; EnableXP