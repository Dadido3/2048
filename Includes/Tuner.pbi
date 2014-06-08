; ##################################################### Documentation ###############################################
; 
; Todo:
;   
; ##################################################### Includes ####################################################

; ##################################################### Constants ###################################################

#Tuner_Games = 25
#Tuner_Variable_Iterations = 10

Enumeration
  #Tuner_State_Stop
  
  #Tuner_State_Start
  #Tuner_State_Wait
EndEnumeration

Enumeration
  #Tuner_Menu_Stop
  #Tuner_Menu_Start
EndEnumeration

; ##################################################### Structures ##################################################

Structure Tuner_Variable
  Value.d
  
  Original.d
  
  Stepsize.d
EndStructure

Structure Tuner_Dataset
  ID.i
  
  Map Variable.Tuner_Variable()
  
  Max_Games.i
  
  List Score.d()
  Mean_Score.d
EndStructure
Global NewList Tuner_Dataset.Tuner_Dataset()

Structure Tuner_Window
  ID.i
  
  ToolBar_ID.i
  ToolBar_Height.i
  
  ListIcon.i
EndStructure
Global Tuner_Window.Tuner_Window

Structure Tuner_Main
  State.i
  
  Mutex_ID.i
  
  Current_Variable.i
  Current_Variable_Counter.i
  
  ID_Counter.i
EndStructure
Global Tuner_Main.Tuner_Main

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Declares ####################################################

; ##################################################### Macros ######################################################

; ##################################################### Includes ####################################################

; ##################################################### Procedures ##################################################

Procedure Tuner_Window_Event_Timer()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Timer = EventTimer()
  
  Select Event_Timer
    Case 0
      Protected Text.s
      Protected Current_ID.i
      Protected i, j
      Protected Delta.d
      
      LockMutex(Tuner_Main\Mutex_ID)
      
      ;Current_ID = GetGadgetItemData(Tuner_Window\ListIcon, GetGadgetState(Tuner_Window\ListIcon))
      ForEach Tuner_Dataset()
        i = ListIndex(Tuner_Dataset())
        If CountGadgetItems(Tuner_Window\ListIcon) <= i
          AddGadgetItem(Tuner_Window\ListIcon, i, Str(Tuner_Dataset()\ID))
        EndIf
        
        SetGadgetItemText(Tuner_Window\ListIcon, i, Str(Tuner_Dataset()\ID), 0)
        
        SetGadgetItemText(Tuner_Window\ListIcon, i, StrD(Tuner_Dataset()\Mean_Score, 0), 1)
        SetGadgetItemText(Tuner_Window\ListIcon, i, Str(ListSize(Tuner_Dataset()\Score())) + "/" + Str(Tuner_Dataset()\Max_Games), 2)
        
        j = 3
        ForEach Tuner_Dataset()\Variable()
          SetGadgetItemText(Tuner_Window\ListIcon, i, StrD(Tuner_Dataset()\Variable()\Value), j)
          
          Delta = 255 * (Tuner_Dataset()\Variable()\Value - Tuner_Dataset()\Variable()\Original) / Tuner_Dataset()\Variable()\Original
          If Delta >  255 : Delta =  255 : EndIf
          If Delta < -255 : Delta = -255 : EndIf
          If Delta > 0
            SetGadgetItemColor(Tuner_Window\ListIcon, i, #PB_Gadget_BackColor, RGB(255, 255-Delta, 255-Delta), j)
          ElseIf Delta < 0
            SetGadgetItemColor(Tuner_Window\ListIcon, i, #PB_Gadget_BackColor, RGB(255+Delta, 255, 255), j)
          Else
            SetGadgetItemColor(Tuner_Window\ListIcon, i, #PB_Gadget_BackColor, RGB(255, 255, 255), j)
          EndIf
          j + 1
        Next
      Next
      
      UnlockMutex(Tuner_Main\Mutex_ID)
      
      
  EndSelect
EndProcedure

Procedure Tuner_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  Protected AI_List.s
  
  Select Event_Menu
    Case #Tuner_Menu_Stop   : Tuner_Main\State = #Tuner_State_Stop
    Case #Tuner_Menu_Start  : Tuner_Main\State = #Tuner_State_Start
  EndSelect
EndProcedure

Procedure Tuner_Window_Event_CloseWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  
EndProcedure

Procedure Tuner_Window_Open()
  Protected Width, Height
  Protected Field_Width, Field_Height
  Protected j
  
  Width = 700
  Height = 600
  
  Tuner_Window\ID = OpenWindow(#PB_Any, 0, 0, Width, Height, "2048 - Tuner", #PB_Window_SystemMenu | #PB_Window_TitleBar | #PB_Window_WindowCentered | #PB_Window_MinimizeGadget, WindowID(Main_Window\ID))
  
  If Not Tuner_Window\ID
    ProcedureReturn 0
  EndIf
  
  SmartWindowRefresh(Tuner_Window\ID, 1)
  
  ; ######################### Short
  
  ; ######################### Toolbar
  
  Tuner_Window\ToolBar_ID = CreateToolBar(#PB_Any, WindowID(Tuner_Window\ID))
  If Not Tuner_Window\ToolBar_ID
    MessageRequester("Error", "ToolBar konnte nicht erstellt werden.")
    CloseWindow(Tuner_Window\ID)
    ProcedureReturn 0
  EndIf
  
  ToolBarImageButton(#Tuner_Menu_Stop, ImageID(Icon_AI_Stop))
  ToolBarImageButton(#Tuner_Menu_Start, ImageID(Icon_AI_Start))
  
  ; ######################### Timer
  
  AddWindowTimer(Tuner_Window\ID, 0, 100)
  
  ; ######################### Größe
  
  Tuner_Window\ToolBar_Height = ToolBarHeight(Tuner_Window\ToolBar_ID)
  
  ; ################# Gadgets
  
  If UseGadgetList(WindowID(Tuner_Window\ID))
    Tuner_Window\ListIcon = ListIconGadget(#PB_Any, 0, Tuner_Window\ToolBar_Height, Width, Height-Tuner_Window\ToolBar_Height, "ID", 40, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
    AddGadgetColumn(Tuner_Window\ListIcon, 1, "Mean_Score", 100)
    AddGadgetColumn(Tuner_Window\ListIcon, 2, "Games", 80)
    If FirstElement(Tuner_Dataset())
      j = 3
      ForEach Tuner_Dataset()\Variable()
        AddGadgetColumn(Tuner_Window\ListIcon, j, MapKey(Tuner_Dataset()\Variable()), 80)
        j + 1
      Next
    EndIf
  EndIf
  
  BindEvent(#PB_Event_Menu, @Tuner_Window_Event_Menu(), Tuner_Window\ID)
  BindEvent(#PB_Event_CloseWindow, @Tuner_Window_Event_CloseWindow(), Tuner_Window\ID)
  BindEvent(#PB_Event_Timer, @Tuner_Window_Event_Timer(), Tuner_Window\ID)
EndProcedure

; ##################################################### Initialisation ##############################################

Tuner_Main\Mutex_ID = CreateMutex()

; ##################################################### Main ########################################################

Procedure Tuner_Main()
  Protected *Temp_Dataset.Tuner_Dataset
  Protected i, Variable
  
  LockMutex(Tuner_Main\Mutex_ID)
  
  Select Tuner_Main\State
    Case #Tuner_State_Start
      Gamelogic_Restart()
      AI_Main\State = #AI_State_Start
      Tuner_Main\State = #Tuner_State_Wait
      
    Case #Tuner_State_Wait
      ; #### Wait until the game is finished.
      If AI_Main\State = #AI_State_Stop
        
        *Temp_Dataset = FirstElement(Tuner_Dataset())
        If *Temp_Dataset
          AddElement(*Temp_Dataset\Score())
          *Temp_Dataset\Score() = Game\Score
          
          *Temp_Dataset\Mean_Score = 0
          ForEach *Temp_Dataset\Score()
            *Temp_Dataset\Mean_Score + *Temp_Dataset\Score()
          Next
          *Temp_Dataset\Mean_Score / ListSize(*Temp_Dataset\Score())
          
          If ListSize(*Temp_Dataset\Score()) >= *Temp_Dataset\Max_Games
            *Temp_Dataset\Max_Games + #Tuner_Games
            SortStructuredList(Tuner_Dataset(), #PB_Sort_Descending, OffsetOf(Tuner_Dataset\Mean_Score), TypeOf(Tuner_Dataset\Mean_Score))
            
            If FirstElement(Tuner_Dataset())
              
              If Tuner_Dataset()\Mean_Score <= *Temp_Dataset\Mean_Score
                
                InsertElement(Tuner_Dataset())
                CopyStructure(*Temp_Dataset, Tuner_Dataset(), Tuner_Dataset)
                
                Tuner_Dataset()\ID = Tuner_Main\ID_Counter : Tuner_Main\ID_Counter + 1
                ClearList(Tuner_Dataset()\Score())
                Tuner_Dataset()\Max_Games = #Tuner_Games
                
                If Tuner_Main\Current_Variable_Counter >= #Tuner_Variable_Iterations
                  Tuner_Main\Current_Variable_Counter = 0
                  Tuner_Main\Current_Variable + 1
                  If Tuner_Main\Current_Variable >= MapSize(Tuner_Dataset()\Variable())
                    Tuner_Main\Current_Variable = 0
                  EndIf
                EndIf
                Tuner_Main\Current_Variable_Counter + 1
                i = 0
                ForEach Tuner_Dataset()\Variable()
                  If i = Tuner_Main\Current_Variable
                    Tuner_Dataset()\Variable()\Value + (Random(100)-50)/50.0 * Tuner_Dataset()\Variable()\Stepsize
                    Break
                  EndIf
                  i + 1
                Next
                
              EndIf
              
              
              
            EndIf
          EndIf
        EndIf
        
        Tuner_Main\State = #Tuner_State_Start
        
      EndIf
      
  EndSelect
  
  UnlockMutex(Tuner_Main\Mutex_ID)
  
EndProcedure

; ##################################################### End #########################################################

; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 118
; FirstLine = 77
; Folding = -
; EnableUnicode
; EnableXP