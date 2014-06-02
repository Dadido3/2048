
UsePNGImageDecoder()

EnableExplicit

; ##################################################### Dokumentation / Kommentare ##################################
; 
; Todo:
;   
; ##################################################### Includes ####################################################

; ##################################################### Prototypes ##################################################

Prototype.i Function_AI_Do(Array Field.i(2))

; ##################################################### Constants ###################################################

#Field_Size = 4
#Tile_Size = 100 ; px
#Tile_Margin = 10 ; px

#Tile_Font_Max_Size = 30

Enumeration
  #Direction_Right
  #Direction_Down
  #Direction_Left
  #Direction_Up
EndEnumeration

Enumeration
  #Menu_Reset
  #Menu_Exit
  
  #Menu_AI_Start
  #Menu_AI_Stop
  #Menu_AI_Step
  #Menu_AI_Choose
  #Menu_AI_Delay
  
  #Menu_About
  
  #Menu_Key_Right
  #Menu_Key_Up
  #Menu_Key_Left
  #Menu_Key_Down
EndEnumeration

Enumeration
  #AI_State_Stop
  #AI_State_Start
  #AI_State_Step
EndEnumeration

; ##################################################### Structures ##################################################

Structure Tile
  Value.i
  
  X.i
  Y.i
EndStructure

Structure Main
  Quit.i
  
  
EndStructure
Global Main.Main

Structure Main_Window
  ID.i
  
  ToolBar_ID.i
  ToolBar_Height.i
  
  Menu_ID.i
  Menu_Height.l
  
  Canvas_Info.i
  Canvas_Info_Redraw.i
  
  Canvas_Field.i
  Canvas_Field_Redraw.i
EndStructure
Global Main_Window.Main_Window

Structure Game_Animation
  Blend_State_New.d   ; Blending between previous game state (0) and new game state (1) for new tiles
  Blend_State_Move.d  ; Blending between previous game state (0) and new game state (1) for moving tiles
  
  New_Tile.Tile
  Array Transition.Tile(#Field_Size, #Field_Size)      ; Coordinates of the tile in a previous game state
  Array Additional_Tile.Tile(#Field_Size, #Field_Size) ; Additional tiles to be shown, which were merged in a previous state
EndStructure

Structure Game
  Array Field.i(#Field_Size, #Field_Size)
  
  Score.i
  
  Animation.Game_Animation
EndStructure
Global Game.Game

Structure AI
  Name.s
  
  Function_Do.Function_AI_Do
EndStructure
Global NewList AI.AI()

Structure AI_Main
  *AI.AI
  
  Delay.i
  
  State.i
  
  Mutex_ID.i
  Thread_ID.i
EndStructure
Global AI_Main.AI_Main

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

Global Icon_Reset = CatchImage(#PB_Any, ?Icon_Reset)
Global Icon_AI_Start = CatchImage(#PB_Any, ?Icon_AI_Start)
Global Icon_AI_Stop = CatchImage(#PB_Any, ?Icon_AI_Stop)
Global Icon_AI_Step = CatchImage(#PB_Any, ?Icon_AI_Step)
Global Icon_AI_Choose = CatchImage(#PB_Any, ?Icon_AI_Choose)

Define i
Global Dim Tile_Font.i(#Tile_Font_Max_Size)
For i = 0 To #Tile_Font_Max_Size
  Tile_Font(i) = LoadFont(#PB_Any, "Arial", i, #PB_Font_Bold)
Next

Global Font_Generic = LoadFont(#PB_Any, "Arial", 30)

; ##################################################### Declares ####################################################

Declare   AI_Change(Number)
Declare   AI_Add(Name.s, *Do.Function_AI_Do)

Declare   Field_Check_Direction(Array Field.i(2), Direction)

Declare   Gamelogic_Move(Direction)
Declare   Gamelogic_Reset()

; ##################################################### Macros ######################################################

Macro Line(x, y, Width, Height, Color)
  LineXY((x), (y), (x)+(Width), (y)+(Height), (Color))
EndMacro

; ##################################################### Includes ####################################################

XIncludeFile "Includes/About.pbi"
XIncludeFile "Includes/Choose_AI.pbi"
XIncludeFile "Includes/AI_Dadido3.pbi"
XIncludeFile "Includes/AI_Simple.pbi"
XIncludeFile "Includes/AI_Random.pbi"

; ##################################################### Procedures ##################################################

Procedure.s SHGetFolderPath(CSIDL)
  Protected *String = AllocateMemory(#MAX_PATH+1)
  SHGetFolderPath_(0, CSIDL, #Null, 0, *String)
  Protected String.s = PeekS(*String)
  FreeMemory(*String)
  ProcedureReturn String
EndProcedure

Procedure AI_Change(Number)
  If SelectElement(AI(), Number)
    AI_Main\AI = AI()
  EndIf
EndProcedure

Procedure AI_Change_By_Name(Name.s)
  ForEach AI()
    If LCase(AI()\Name) = LCase(Name)
      AI_Main\AI = AI()
      ProcedureReturn #True
    EndIf
  Next
  
  ProcedureReturn #False
EndProcedure

Procedure AI_Add(Name.s, *Do.Function_AI_Do)
  If AddElement(AI())
    AI()\Name = Name
    AI()\Function_Do = *Do
    
  EndIf
EndProcedure

Procedure AI_Thread(*Dummy)
  Protected Direction
  Protected Dim Field.i(#Field_Size,#Field_Size)
  
  Repeat
    
    If AI_Main\Delay > 1000
      AI_Main\Delay = 1000
    EndIf
    
    Delay(AI_Main\Delay)
    
    Select AI_Main\State
      Case #AI_State_Stop
        Delay(100)
        
      Case #AI_State_Start, #AI_State_Step
        
        ; #### Copy Field
        LockMutex(AI_Main\Mutex_ID)
        CopyArray(Game\Field(), Field())
        UnlockMutex(AI_Main\Mutex_ID)
        
        If AI_Main\AI
          If AI_Main\AI\Function_Do
            Direction = AI_Main\AI\Function_Do(Field())
          EndIf
        EndIf
        
        If Direction >= 0
          Gamelogic_Move(Direction)
        Else
          AI_Main\State = #AI_State_Stop
        EndIf
        
        If AI_Main\State = #AI_State_Step
          AI_Main\State = #AI_State_Stop
        EndIf
        
    EndSelect
    
  Until Main\Quit
  
EndProcedure

Procedure Main_Window_Event_SizeWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
EndProcedure

Procedure Main_Window_Event_Timer()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Timer = EventTimer()
  
  Select Event_Timer
    Case 0
      LockMutex(AI_Main\Mutex_ID)
      Game\Animation\Blend_State_Move + 0.2
      If Game\Animation\Blend_State_Move > 1
        Game\Animation\Blend_State_Move = 1
      Else
        Main_Window\Canvas_Field_Redraw = #True
      EndIf
      If Game\Animation\Blend_State_Move >= 1
        Game\Animation\Blend_State_New + 0.2
        If Game\Animation\Blend_State_New > 1
          Game\Animation\Blend_State_New = 1
        Else
          Main_Window\Canvas_Field_Redraw = #True
        EndIf
      EndIf
      UnlockMutex(AI_Main\Mutex_ID)
      
  EndSelect
EndProcedure

Procedure Main_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  Protected AI_List.s
  
  Select Event_Menu
    Case #Menu_Reset : Gamelogic_Reset()
    Case #Menu_Exit : Main\Quit = #True
    
    Case #Menu_AI_Start   : AI_Main\State = #AI_State_Start
    Case #Menu_AI_Stop    : AI_Main\State = #AI_State_Stop
    Case #Menu_AI_Step    : AI_Main\State = #AI_State_Step
    Case #Menu_AI_Choose  : Choose_AI_Open()
    Case #Menu_AI_Delay   : AI_Main\Delay = Val(InputRequester("Set Delay", "Set the delay in ms between steps", Str(AI_Main\Delay)))
    
    Case #Menu_Key_Right  : Gamelogic_Move(#Direction_Right)
    Case #Menu_Key_Up     : Gamelogic_Move(#Direction_Up)
    Case #Menu_Key_Left   : Gamelogic_Move(#Direction_Left)
    Case #Menu_Key_Down   : Gamelogic_Move(#Direction_Down)
    
    Case #Menu_About      : About_Open()
  EndSelect
EndProcedure

Procedure Main_Window_Event_CloseWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Main\Quit = #True
EndProcedure

Procedure Main_Window_Open()
  Protected Width, Height
  Protected Field_Width, Field_Height
  
  Width = #Field_Size * #Tile_Size + (#Field_Size+1) * #Tile_Margin
  Height = #Field_Size * #Tile_Size + (#Field_Size+1) * #Tile_Margin + 150
  
  Main_Window\ID = OpenWindow(#PB_Any, 0, 0, Width, Height, "2048", #PB_Window_SystemMenu | #PB_Window_TitleBar | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
  
  If Not Main_Window\ID
    ProcedureReturn 0
  EndIf
  
  SmartWindowRefresh(Main_Window\ID, 1)
  
  Main_Window\Menu_ID = CreateImageMenu(#PB_Any, WindowID(Main_Window\ID), #PB_Menu_ModernLook)
  If Not Main_Window\Menu_ID
    MessageRequester("D3hex", "Menü konnte nicht erstellt werden.")
    CloseWindow(Main_Window\ID)
    ProcedureReturn 0
  EndIf
  
  MenuTitle("Game")
  MenuItem(#Menu_Reset, "Restart")
  MenuBar()
  MenuItem(#Menu_Exit, "Exit")
  
  MenuTitle("AI")
  MenuItem(#Menu_AI_Step, "Step")
  MenuItem(#Menu_AI_Start, "Start")
  MenuItem(#Menu_AI_Stop, "Stop")
  MenuBar()
  MenuItem(#Menu_AI_Choose, "Choose")
  MenuItem(#Menu_AI_Delay, "Set Delay")
  
  MenuTitle("?")
  MenuItem(#Menu_About, "About")
  
  ; ######################### Short
  
  AddKeyboardShortcut(Main_Window\ID, #PB_Shortcut_Right, #Menu_Key_Right)
  AddKeyboardShortcut(Main_Window\ID, #PB_Shortcut_Up,    #Menu_Key_Up)
  AddKeyboardShortcut(Main_Window\ID, #PB_Shortcut_Left,  #Menu_Key_Left)
  AddKeyboardShortcut(Main_Window\ID, #PB_Shortcut_Down,  #Menu_Key_Down)
  
  ; ######################### Toolbar
  
  Main_Window\ToolBar_ID = CreateToolBar(#PB_Any, WindowID(Main_Window\ID))
  If Not Main_Window\ToolBar_ID
    MessageRequester("D3hex", "ToolBar konnte nicht erstellt werden.")
    CloseWindow(Main_Window\ID)
    ProcedureReturn 0
  EndIf
  
  ToolBarImageButton(#Menu_Reset, ImageID(Icon_Reset))
  ToolBarSeparator()
  ToolBarImageButton(#Menu_AI_Choose, ImageID(Icon_AI_Choose))
  ToolBarImageButton(#Menu_AI_Stop, ImageID(Icon_AI_Stop))
  ToolBarImageButton(#Menu_AI_Start, ImageID(Icon_AI_Start))
  ToolBarImageButton(#Menu_AI_Step, ImageID(Icon_AI_Step))
  
  ; ######################### Timer
  
  AddWindowTimer(Main_Window\ID, 0, 10)
  
  ; ######################### Größe
  
  Main_Window\Menu_Height = MenuHeight()
  Main_Window\ToolBar_Height = ToolBarHeight(Main_Window\ToolBar_ID)
  
  ; ################# Gadgets
  
  Field_Width = #Field_Size * #Tile_Size + (#Field_Size+1) * #Tile_Margin
  Field_Height = #Field_Size * #Tile_Size + (#Field_Size+1) * #Tile_Margin
  
  If UseGadgetList(WindowID(Main_Window\ID))
    Main_Window\Canvas_Info = CanvasGadget(#PB_Any, 0, Main_Window\ToolBar_Height, Field_Width, 150)
    Main_Window\Canvas_Field = CanvasGadget(#PB_Any, 0, Main_Window\ToolBar_Height + 150, Field_Width, Field_Height, #PB_Canvas_Keyboard)
  EndIf
  
  ResizeWindow(Main_Window\ID, #PB_Ignore, #PB_Ignore, Field_Width, Field_Height + Main_Window\ToolBar_Height + Main_Window\Menu_Height + 150)
  
  BindEvent(#PB_Event_Menu, @Main_Window_Event_Menu(), Main_Window\ID)
  BindEvent(#PB_Event_CloseWindow, @Main_Window_Event_CloseWindow(), Main_Window\ID)
  BindEvent(#PB_Event_Timer, @Main_Window_Event_Timer(), Main_Window\ID)
EndProcedure

Procedure Main_Window_Redraw_Info()
  Protected Width = GadgetWidth(Main_Window\Canvas_Info)
  Protected Height = GadgetHeight(Main_Window\Canvas_Info)
  Protected ix, iy, jx.d, jy.d
  Protected Tile_Color
  
  If StartDrawing(CanvasOutput(Main_Window\Canvas_Info))
    Box(0, 0, Width, Height, RGB(187, 173, 160))
    
    RoundBox(#Tile_Margin, #Tile_Margin, Width - 2*#Tile_Margin, Height - #Tile_Margin, 8, 8, RGB(200, 190, 180))
    
    DrawingFont(FontID(Font_Generic))
    DrawingMode(#PB_2DDrawing_Transparent)
    
    DrawText(2*#Tile_Margin, 2*#Tile_Margin, "Score: "+Str(Game\Score), 0)
    
    StopDrawing()
  EndIf
EndProcedure

Procedure Tile_Draw(X.d, Y.d, ix, iy, Value.i)
  Protected Color_Back, Color_Text
  Protected Scaling.d
  Protected Font_Size.l
  
  Select Value
    Case 0      : Color_Back = RGB(205,193,180) : Color_Text = RGB(0,0,0)
    Case 2      : Color_Back = RGB(238,228,218) : Color_Text = RGB(0,0,0)
    Case 4      : Color_Back = RGB(237,224,200) : Color_Text = RGB(0,0,0)
    Case 8      : Color_Back = RGB(242,177,121) : Color_Text = RGB(0,0,0)
    Case 16     : Color_Back = RGB(245,149,99)  : Color_Text = RGB(0,0,0)
    Case 32     : Color_Back = RGB(246,124,95)  : Color_Text = RGB(0,0,0)
    Case 64     : Color_Back = RGB(246,94,59)   : Color_Text = RGB(0,0,0)
    Case 128    : Color_Back = RGB(237,204,97)  : Color_Text = RGB(0,0,0)
    Case 256    : Color_Back = RGB(237,200,80)  : Color_Text = RGB(0,0,0)
    Case 512    : Color_Back = RGB(242,177,121) : Color_Text = RGB(0,0,0)
    Case 1024   : Color_Back = RGB(237,197,63)  : Color_Text = RGB(0,0,0)
    Case 2048   : Color_Back = RGB(237,187,53)  : Color_Text = RGB(0,0,0)
    Case 4096   : Color_Back = RGB(237,167,43)  : Color_Text = RGB(0,0,0)
    Case 8192   : Color_Back = RGB(237,154,36)  : Color_Text = RGB(0,0,0)
    Case 16384  : Color_Back = RGB(220,144,26)  : Color_Text = RGB(0,0,0)
    Case 32768  : Color_Back = RGB(200,134,16)  : Color_Text = RGB(0,0,0)
    Default     : Color_Back = RGB(10,10,10)    : Color_Text = RGB(205,193,180)
  EndSelect
  
  If ix = Game\Animation\New_Tile\X And iy = Game\Animation\New_Tile\Y
    Scaling = 0.8 * Game\Animation\Blend_State_New + 0.2
    If Game\Animation\Blend_State_New = 0
      ProcedureReturn
    EndIf
  Else
    Scaling = 1
  EndIf
  
  DrawingMode(#PB_2DDrawing_Transparent)
  RoundBox(X+#Tile_Size*(1-Scaling)/2, Y+#Tile_Size*(1-Scaling)/2, #Tile_Size*Scaling, #Tile_Size*Scaling, 8, 8, Color_Back)
  
  If Value
    For Font_Size = #Tile_Font_Max_Size To 1 Step -1
      DrawingFont(FontID(Tile_Font(Font_Size)))
      If TextWidth(Str(Value)) < #Tile_Size - 10
        DrawingFont(FontID(Tile_Font(Int(Font_Size * Scaling))))
        DrawText(X+#Tile_Size/2-TextWidth(Str(Value))/2, Y+#Tile_Size/2-TextHeight(Str(Value))/2, Str(Value), Color_Text)
        Break
      EndIf
    Next
  EndIf
  
EndProcedure

Procedure Main_Window_Redraw_Field()
  Protected Width = GadgetWidth(Main_Window\Canvas_Field)
  Protected Height = GadgetHeight(Main_Window\Canvas_Field)
  Protected ix, iy, jx.d, jy.d
  Protected Tile_Color
  
  If StartDrawing(CanvasOutput(Main_Window\Canvas_Field))
    Box(0, 0, Width, Height, RGB(187, 173, 160))
    
    For ix = 0 To #Field_Size-1
      For iy = 0 To #Field_Size-1
        Tile_Draw(#Tile_Margin+ix*(#Tile_Size+#Tile_Margin), #Tile_Margin+iy*(#Tile_Size+#Tile_Margin), -1, -1, 0)
      Next
    Next
    
    LockMutex(AI_Main\Mutex_ID)
    
    For ix = 0 To #Field_Size-1
      For iy = 0 To #Field_Size-1
        If Game\Animation\Additional_Tile(ix, iy)\Value
          jx = ix * Game\Animation\Blend_State_Move + Game\Animation\Additional_Tile(ix, iy)\X * (1-Game\Animation\Blend_State_Move)
          jy = iy * Game\Animation\Blend_State_Move + Game\Animation\Additional_Tile(ix, iy)\Y * (1-Game\Animation\Blend_State_Move)
          Tile_Draw(#Tile_Margin+jx*(#Tile_Size+#Tile_Margin), #Tile_Margin+jy*(#Tile_Size+#Tile_Margin), ix, iy, Game\Animation\Additional_Tile(ix, iy)\Value)
        EndIf
      Next
    Next
    
    For ix = 0 To #Field_Size-1
      For iy = 0 To #Field_Size-1
        If Game\Field(ix, iy)
          jx = ix * Game\Animation\Blend_State_Move + Game\Animation\Transition(ix,iy)\X * (1-Game\Animation\Blend_State_Move)
          jy = iy * Game\Animation\Blend_State_Move + Game\Animation\Transition(ix,iy)\Y * (1-Game\Animation\Blend_State_Move)
          Tile_Draw(#Tile_Margin+jx*(#Tile_Size+#Tile_Margin), #Tile_Margin+jy*(#Tile_Size+#Tile_Margin), ix, iy, Game\Field(ix, iy))
        EndIf
      Next
    Next
    
    UnlockMutex(AI_Main\Mutex_ID)
    
    StopDrawing()
  EndIf
EndProcedure

Procedure.i Field_Check_Direction(Array Field.i(2), Direction)
  Protected ix, iy, jx, jy
  
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      
      Select Direction
        Case #Direction_Right : jx = ix+1 : jy = iy
        Case #Direction_Up    : jx = ix   : jy = iy-1
        Case #Direction_Left  : jx = ix-1 : jy = iy
        Case #Direction_Down  : jx = ix   : jy = iy+1
      EndSelect
      
      If ix >= 0 And iy >= 0 And ix < #Field_Size And iy < #Field_Size
        If jx >= 0 And jy >= 0 And jx < #Field_Size And jy < #Field_Size
          If Field(ix, iy) And Field(jx, jy) = 0
            ProcedureReturn #True ; #### Found an empty tile beneath
          ElseIf Field(ix, iy) And Field(ix, iy) = Field(jx, jy)
            ProcedureReturn #True ; #### Found mergable tiles
          EndIf
        EndIf
      EndIf
      
    Next
  Next
  
  ProcedureReturn #False
EndProcedure

Procedure Gamelogic_Place_Random()
  Protected NewList Empty_Tile.Tile()
  Protected ix, iy
  Protected Result
  
  LockMutex(AI_Main\Mutex_ID)
  
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      If Game\Field(ix,iy) = 0
        AddElement(Empty_Tile())
        Empty_Tile()\X = ix
        Empty_Tile()\Y = iy
      EndIf
    Next
  Next
  
  If SelectElement(Empty_Tile(), Random(ListSize(Empty_Tile())-1))
    
    Select Random(1)
      Case 0 : Game\Field(Empty_Tile()\X,Empty_Tile()\Y) = 2 ;Pow(2, Random(5)+1)
      Case 1 : Game\Field(Empty_Tile()\X,Empty_Tile()\Y) = 4
    EndSelect
    
    Game\Animation\New_Tile\X = Empty_Tile()\X
    Game\Animation\New_Tile\Y = Empty_Tile()\Y
    Game\Animation\Blend_State_New = 0
    Main_Window\Canvas_Info_Redraw = #True
    Main_Window\Canvas_Field_Redraw = #True
    
    Result = #True
  Else
    Result = #False
  EndIf
  
  UnlockMutex(AI_Main\Mutex_ID)
  
  ProcedureReturn Result
EndProcedure

Procedure Gamelogic_Move_Helper(Direction)
  Protected i, j, cx, cy, tx, ty
  Protected ix, iy
  Protected Moved = #False
  
  LockMutex(AI_Main\Mutex_ID)
  
  ; #### Reset transition array for animations
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      Game\Animation\Transition(ix,iy)\X = ix
      Game\Animation\Transition(ix,iy)\Y = iy
    Next
  Next
  ; #### Reset additional array for animations
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      Game\Animation\Additional_Tile(ix,iy)\Value = 0
    Next
  Next
  Game\Animation\Blend_State_Move = 0
  
  For i = 0 To #Field_Size-1
    ; #### Iterate from different directions throught the field, depending on "Direction".
    Select Direction
      Case #Direction_Right : cx = #Field_Size-1 : cy = i
      Case #Direction_Up    : cx = i             : cy = 0
      Case #Direction_Left  : cx = 0             : cy = i
      Case #Direction_Down  : cx = i             : cy = #Field_Size-1
    EndSelect
    ; #### Save the temporary position and value
    tx = cx : ty = cy
    
    ; #### Search for tiles to be merged
    For j = 1 To #Field_Size-1
      Select Direction
        Case #Direction_Right : tx - 1
        Case #Direction_Up    : ty + 1
        Case #Direction_Left  : tx + 1
        Case #Direction_Down  : ty - 1
      EndSelect
      
      If Game\Field(cx,cy) = 0
        cx = tx : cy = ty
      ElseIf Game\Field(cx,cy) = Game\Field(tx,ty)
        Game\Animation\Additional_Tile(cx,cy)\X = tx
        Game\Animation\Additional_Tile(cx,cy)\Y = ty
        Game\Animation\Additional_Tile(cx,cy)\Value = Game\Field(tx,ty)
        Game\Field(cx,cy) + Game\Field(tx,ty)
        Game\Field(tx,ty) = 0
        Game\Score + Game\Field(cx,cy)
        Main_Window\Canvas_Info_Redraw = #True
        Main_Window\Canvas_Field_Redraw = #True
        Moved = #True
        cx = tx : cy = ty
      ElseIf Game\Field(cx,cy) <> Game\Field(tx,ty) And Game\Field(tx,ty)
        cx = tx : cy = ty
      EndIf
    Next
    
    ; #### Iterate from different directions throught the field, depending on "Direction".
    Select Direction
      Case #Direction_Right : cx = #Field_Size-1 : cy = i
      Case #Direction_Up    : cx = i             : cy = 0
      Case #Direction_Left  : cx = 0             : cy = i
      Case #Direction_Down  : cx = i             : cy = #Field_Size-1
    EndSelect
    ; #### Save the temporary position and value
    tx = cx : ty = cy
    
    ; #### Move all tiles in the defined direction
    For j = 1 To #Field_Size-1
      Select Direction
        Case #Direction_Right : tx - 1
        Case #Direction_Up    : ty + 1
        Case #Direction_Left  : tx + 1
        Case #Direction_Down  : ty - 1
      EndSelect
      
      If Game\Field(cx,cy)
        cx = tx : cy = ty
      ElseIf Game\Field(cx,cy) = 0 And Game\Field(tx,ty)
        Game\Field(cx,cy) = Game\Field(tx,ty)
        Game\Field(tx,ty) = 0
        Game\Animation\Transition(cx,cy)\X = tx
        Game\Animation\Transition(cx,cy)\Y = ty
        Game\Animation\Additional_Tile(cx,cy)\X = Game\Animation\Additional_Tile(tx,ty)\X
        Game\Animation\Additional_Tile(cx,cy)\Y = Game\Animation\Additional_Tile(tx,ty)\Y
        Game\Animation\Additional_Tile(cx,cy)\Value = Game\Animation\Additional_Tile(tx,ty)\Value
        Game\Animation\Additional_Tile(tx,ty)\X = 0
        Game\Animation\Additional_Tile(tx,ty)\Y = 0
        Game\Animation\Additional_Tile(tx,ty)\Value = 0
        Main_Window\Canvas_Field_Redraw = #True
        Moved = #True
        Select Direction
          Case #Direction_Right : cx - 1
          Case #Direction_Up    : cy + 1
          Case #Direction_Left  : cx + 1
          Case #Direction_Down  : cy - 1
        EndSelect
      EndIf
    Next
    
  Next
  
  UnlockMutex(AI_Main\Mutex_ID)
  
  ProcedureReturn Moved
EndProcedure

Procedure Gamelogic_Move(Direction)
  
  If Gamelogic_Move_Helper(Direction)
    Gamelogic_Place_Random()
  EndIf
  
EndProcedure

Procedure Gamelogic_Reset()
  Protected ix, iy
  
  LockMutex(AI_Main\Mutex_ID)
  
  ; #### Reset transition array for animations
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      Game\Animation\Transition(ix,iy)\X = ix
      Game\Animation\Transition(ix,iy)\Y = iy
    Next
  Next
  ; #### Reset additional array for animations
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      Game\Animation\Additional_Tile(ix,iy)\Value = 0
    Next
  Next
  
  ; #### Reset Field
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      Game\Field(ix,iy) = 0
    Next
  Next
  
  Game\Score = 0
  Main_Window\Canvas_Info_Redraw = #True
  
  AI_Main\State = #AI_State_Stop
  
  UnlockMutex(AI_Main\Mutex_ID)
  
  Gamelogic_Place_Random()
EndProcedure

Procedure Configuration_Save(Filename.s)
  If CreatePreferences(Filename, #PB_Preference_GroupSeparator)
    
    PreferenceGroup("AI")
    If AI_Main\AI
      WritePreferenceString("Name", AI_Main\AI\Name)
    EndIf
    
    WritePreferenceInteger("Step_Delay", AI_Main\Delay)
    
    ClosePreferences()
  EndIf
EndProcedure

Procedure Configuration_Load(Filename.s)
  OpenPreferences(Filename, #PB_Preference_GroupSeparator)
  
  PreferenceGroup("AI")
  If Not AI_Change_By_Name(ReadPreferenceString("Name", ""))
    AI_Change(0)
  EndIf
  
  AI_Main\Delay = ReadPreferenceInteger("Step_Delay", 100)
  
  ClosePreferences()
EndProcedure

; ##################################################### Initialisation ##############################################

Configuration_Load(SHGetFolderPath(#CSIDL_APPDATA)+"\D3\2048\Settings.txt")

AI_Main\Mutex_ID = CreateMutex()
AI_Main\Thread_ID = CreateThread(@AI_Thread(), 0)

Main_Window_Open()

Gamelogic_Reset()

; ##################################################### Main ########################################################

Repeat
  
  WaitWindowEvent(10)
  
  If Main_Window\Canvas_Info_Redraw
    Main_Window\Canvas_Info_Redraw = #False
    Main_Window_Redraw_Info()
  EndIf
  
  If Main_Window\Canvas_Field_Redraw
    Main_Window\Canvas_Field_Redraw = #False
    Main_Window_Redraw_Field()
  EndIf
  
  About_Main()
  Choose_AI_Main()
  
Until Main\Quit

; ##################################################### End #########################################################

WaitThread(AI_Main\Thread_ID)

CreateDirectory(SHGetFolderPath(#CSIDL_APPDATA)+"\D3")
CreateDirectory(SHGetFolderPath(#CSIDL_APPDATA)+"\D3\2048")

Configuration_Save(SHGetFolderPath(#CSIDL_APPDATA)+"\D3\2048\Settings.txt")

; ##################################################### Data Sections ###############################################

DataSection
  Icon_Reset:     : IncludeBinary "Data/Icons/Reset.png"
  
  Icon_AI_Start:  : IncludeBinary "Data/Icons/AI_Start.png"
  Icon_AI_Stop:   : IncludeBinary "Data/Icons/AI_Stop.png"
  Icon_AI_Step:   : IncludeBinary "Data/Icons/AI_Step.png"
  Icon_AI_Choose: : IncludeBinary "Data/Icons/AI_Choose.png"
EndDataSection
; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 164
; FirstLine = 131
; Folding = ----
; EnableUnicode
; EnableXP
; DisableDebugger