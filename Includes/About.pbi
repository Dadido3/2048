
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

Structure About_Main
  
EndStructure
Global About_Main.About_Main

Structure About
  Window_ID.i
  Window_Close.l
  
  ; #### Gadgets
  Editor.i
  
  Redraw.l
EndStructure
Global About.About

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Init ########################################################

Global About_Font = LoadFont(#PB_Any, "Arial", 12)

; ##################################################### Declares ####################################################

Declare   About_Close()

; ##################################################### Procedures ##################################################

Procedure About_Editor_Fill()
  ClearGadgetItems(About\Editor)
  
  SetGadgetFont(About\Editor, FontID(About_Font))
  
  AddGadgetItem(About\Editor, -1, "2048")
  AddGadgetItem(About\Editor, -1, "")
  AddGadgetItem(About\Editor, -1, "Created with PureBasic")
  AddGadgetItem(About\Editor, -1, "")
  AddGadgetItem(About\Editor, -1, "Times compiled: "+Str(#PB_Editor_CompileCount))
  AddGadgetItem(About\Editor, -1, "Times built: "+Str(#PB_Editor_BuildCount))
  AddGadgetItem(About\Editor, -1, "Build Timestamp: "+FormatDate("%hh:%ii:%ss %dd.%mm.%yyyy", #PB_Compiler_Date))
  CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
    AddGadgetItem(About\Editor, -1, "Compiler Version: "+StrF(#PB_Compiler_Version/100, 2)+" (x86)")
  CompilerElse
    AddGadgetItem(About\Editor, -1, "Compiler Version: "+StrF(#PB_Compiler_Version/100, 2)+" (x64)")
  CompilerEndIf
  AddGadgetItem(About\Editor, -1, "")
  AddGadgetItem(About\Editor, -1, "Programmer: David Vogel (Dadido3, Xaardas)")
  AddGadgetItem(About\Editor, -1, "")
  AddGadgetItem(About\Editor, -1, "Iconset by Mark James")
  AddGadgetItem(About\Editor, -1, "http://www.famfamfam.com/lab/icons/silk/")
  
EndProcedure

Procedure About_Event_SizeWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  
  About\Redraw = #True
EndProcedure

Procedure About_Event_ActivateWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  About\Redraw = #True
EndProcedure

Procedure About_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
EndProcedure

Procedure About_Event_CloseWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  ;About_Close()
  About\Window_Close = #True
EndProcedure

Procedure About_Open()
  Protected Width, Height
  
  If About\Window_ID = 0
    
    Width = 500
    Height = 300
    
    About\Window_ID = OpenWindow(#PB_Any, 0, 0, Width, Height, "About", #PB_Window_SystemMenu | #PB_Window_WindowCentered, WindowID(Main_Window\ID))
    
    About\Editor = EditorGadget(#PB_Any, 0, 0, Width, Height, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
    
    About_Editor_Fill()
    
    ;BindEvent(#PB_Event_SizeWindow, @About_Event_SizeWindow(), About\Window_ID)
    ;BindEvent(#PB_Event_Repaint, @About_Event_SizeWindow(), About\Window_ID)
    ;BindEvent(#PB_Event_RestoreWindow, @About_Event_SizeWindow(), About\Window_ID)
    ;BindEvent(#PB_Event_Menu, @About_Event_Menu(), About\Window_ID)
    BindEvent(#PB_Event_CloseWindow, @About_Event_CloseWindow(), About\Window_ID)
    
    About\Redraw = #True
    
  EndIf
EndProcedure

Procedure About_Close()
  If About\Window_ID
    
    ;UnbindEvent(#PB_Event_SizeWindow, @About_Event_SizeWindow(), About\Window_ID)
    ;UnbindEvent(#PB_Event_Repaint, @About_Event_SizeWindow(), About\Window_ID)
    ;UnbindEvent(#PB_Event_RestoreWindow, @About_Event_SizeWindow(), About\Window_ID)
    ;UnbindEvent(#PB_Event_Menu, @About_Event_Menu(), About\Window_ID)
    UnbindEvent(#PB_Event_CloseWindow, @About_Event_CloseWindow(), About\Window_ID)
    
    CloseWindow(About\Window_ID)
    About\Window_ID = 0
  EndIf
EndProcedure

Procedure About_Main()
  If Not About\Window_ID
    ProcedureReturn #False
  EndIf
  
  If About\Window_Close
    About\Window_Close = #False
    About_Close()
  EndIf
  
EndProcedure

; ##################################################### Initialisation ##############################################



; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 72
; FirstLine = 27
; Folding = --
; EnableUnicode
; EnableXP