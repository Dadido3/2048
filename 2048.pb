UseCRC32Fingerprint()
UsePNGImageDecoder()

EnableExplicit

; ##################################################### Documentation ###############################################
; 
; Todo:
;   
; History:
; - V0.000 (02.06.2014)
;   - Project started
; 
; - V0.??? (08.06.2014)
;   - Added "Game over" message
;   - Improved AI_Simple
;   - Added restart with a specific seed
;   - Added tuner to optimize AI parameters with some sort of genetic algorithm
;   - Other small improvements
;
; - V1.000 (02.07.2016)
;   - Added program icon
;   - Seed can now contain any character
;   - Changed binary output to distribution folder
;   - Code should be compatble with Linux and macOS from now on
;   - Game starts with two random tiles
; 
; 
; ##################################################### Includes ####################################################

; ##################################################### Prototypes ##################################################

Prototype.i Function_AI_Do(Array Field.i(2))

; ##################################################### Constants ###################################################
#Version = 1000

#Software_Name = "2048"

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
  #Menu_Restart
  #Menu_Restart_With_Seed
  #Menu_Exit
  
  #Menu_AI_Start
  #Menu_AI_Stop
  #Menu_AI_Step
  #Menu_AI_Settings
  
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
  
  Highscore.i
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
  
  Array Transition.Tile(#Field_Size, #Field_Size)       ; Coordinates of the tile in a previous game state
  Array New.l(#Field_Size, #Field_Size)                 ; Array of new tiles, if #True the zoom animation will be shown
  Array Additional_Tile.Tile(#Field_Size, #Field_Size)  ; Additional tiles to be shown, which were merged in a previous state
EndStructure

Structure Game
  Array Field.i(#Field_Size, #Field_Size)
  
  Score.i             ; Current score
  Lost.i              ; True if lost
  
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
  
  Restart_With_Seed.i
EndStructure
Global AI_Main.AI_Main

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

Global Icon_Restart = CatchImage(#PB_Any, ?Icon_Restart)
Global Icon_Restart_With_Seed = CatchImage(#PB_Any, ?Icon_Restart_With_Seed)
Global Icon_AI_Start = CatchImage(#PB_Any, ?Icon_AI_Start)
Global Icon_AI_Stop = CatchImage(#PB_Any, ?Icon_AI_Stop)
Global Icon_AI_Step = CatchImage(#PB_Any, ?Icon_AI_Step)
Global Icon_AI_Settings = CatchImage(#PB_Any, ?Icon_AI_Settings)

Define i
Global Dim Tile_Font.i(#Tile_Font_Max_Size)
For i = 0 To #Tile_Font_Max_Size
  Tile_Font(i) = LoadFont(#PB_Any, "Arial", i, #PB_Font_Bold)
Next

Global Font_Generic = LoadFont(#PB_Any, "Arial", 30)
Global Font_Generic_Big = LoadFont(#PB_Any, "Arial", 40)

; ##################################################### Declares ####################################################

Declare   AI_Change(Number)
Declare   AI_Add(Name.s, *Do.Function_AI_Do)

Declare   Field_Check_Direction(Array Field.i(2), Direction)

Declare   Gamelogic_Move(Direction)
Declare   Gamelogic_Restart()

Declare   Main()

; ##################################################### Macros ######################################################

; ##################################################### Includes ####################################################

XIncludeFile "Includes/Helper.pbi"
UseModule Helper

XIncludeFile "Includes/About.pbi"
XIncludeFile "Includes/AI_Settings.pbi"
XIncludeFile "Includes/Tuner.pbi"

; #### Add AI-Includes here
XIncludeFile "Includes/AI_Simple.pbi"
XIncludeFile "Includes/AI_WorstCase.pbi"
XIncludeFile "Includes/AI_Random.pbi"

; ##################################################### Procedures ##################################################

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
  Protected Timer.i
  
  Repeat
    
    If AI_Main\Restart_With_Seed
      RandomSeed(AI_Main\Restart_With_Seed)
      AI_Main\Restart_With_Seed = 0
    EndIf
    
    While Timer + AI_Main\Delay > ElapsedMilliseconds()
      Delay(10)
    Wend
    Timer = ElapsedMilliseconds()
    
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
      
      Main()
      
  EndSelect
EndProcedure

Procedure Main_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  Protected AI_List.s, Seed.s
  
  Select Event_Menu
    Case #Menu_Restart : Gamelogic_Restart()
    Case #Menu_Restart_With_Seed
      AI_Main\State = #AI_State_Stop
      Seed.s = InputRequester("Restart", "Enter the new seed", "")
      ; #### Check for one-to-one correspondence (If true, the seed string is an integer)
      If Str(Val(Seed)) = Seed
        AI_Main\Restart_With_Seed = Val(Seed)
      Else
        AI_Main\Restart_With_Seed = Val("$"+StringFingerprint(Seed, #PB_Cipher_CRC32))
      EndIf
      
      RandomSeed(AI_Main\Restart_With_Seed)
      Gamelogic_Restart()
    Case #Menu_Exit : Main\Quit = #True
    
    Case #Menu_AI_Start   : AI_Main\State = #AI_State_Start
    Case #Menu_AI_Stop    : AI_Main\State = #AI_State_Stop
    Case #Menu_AI_Step    : AI_Main\State = #AI_State_Step
    Case #Menu_AI_Settings: AI_Settings_Open()
    
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
  
  Main_Window\ID = OpenWindow(#PB_Any, 0, 0, Width, Height, #Software_Name + " V"+StrF(#Version*0.001,2), #PB_Window_SystemMenu | #PB_Window_TitleBar | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
  
  If Not Main_Window\ID
    ProcedureReturn 0
  EndIf
  
  SmartWindowRefresh(Main_Window\ID, 1)
  
  Main_Window\Menu_ID = CreateImageMenu(#PB_Any, WindowID(Main_Window\ID))
  If Not Main_Window\Menu_ID
    MessageRequester("Error", "Menü konnte nicht erstellt werden.")
    CloseWindow(Main_Window\ID)
    ProcedureReturn 0
  EndIf
  
  MenuTitle("Game")
  MenuItem(#Menu_Restart, "Restart", ImageID(Icon_Restart))
  MenuItem(#Menu_Restart_With_Seed, "Restart with Seed", ImageID(Icon_Restart_With_Seed))
  MenuBar()
  MenuItem(#Menu_Exit, "Exit")
  
  MenuTitle("AI")
  MenuItem(#Menu_AI_Settings, "Settings", ImageID(Icon_AI_Settings))
  MenuBar()
  MenuItem(#Menu_AI_Step, "Step", ImageID(Icon_AI_Step))
  MenuItem(#Menu_AI_Start, "Start", ImageID(Icon_AI_Start))
  MenuItem(#Menu_AI_Stop, "Stop", ImageID(Icon_AI_Stop))
  
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
    MessageRequester("Error", "ToolBar konnte nicht erstellt werden.")
    CloseWindow(Main_Window\ID)
    ProcedureReturn 0
  EndIf
  
  ToolBarImageButton(#Menu_Restart, ImageID(Icon_Restart))
  ToolBarImageButton(#Menu_Restart_With_Seed, ImageID(Icon_Restart_With_Seed))
  ToolBarSeparator()
  ToolBarImageButton(#Menu_AI_Settings, ImageID(Icon_AI_Settings))
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
    
    If Game\Lost ; ! THE GAME !
      DrawingMode(#PB_2DDrawing_AlphaBlend | #PB_2DDrawing_Transparent)
      
      Box(0, 0, Width, Height, RGBA(255, 255, 255, 150))
      
      DrawingMode(#PB_2DDrawing_Default)
    EndIf
    
    RoundBox(#Tile_Margin, #Tile_Margin, Width - 2*#Tile_Margin, Height - #Tile_Margin, 8, 8, RGB(200, 190, 180))
    
    DrawingFont(FontID(Font_Generic))
    DrawingMode(#PB_2DDrawing_Transparent)
    
    DrawText(2*#Tile_Margin, 2*#Tile_Margin, "Score: "+Str(Game\Score), 0)
    DrawText(2*#Tile_Margin, 2*#Tile_Margin + Height/2 - 5, "Highscore: "+Str(Main\Highscore), 0)
    
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
  
  If ix >= 0 And iy >= 0 And Game\Animation\New(ix, iy)
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
    
    If Game\Lost ; ! THE GAME !
      DrawingMode(#PB_2DDrawing_AlphaBlend | #PB_2DDrawing_Transparent)
      
      DrawingFont(FontID(Font_Generic_Big))
      Box(0, 0, Width, Height, RGBA(255, 255, 255, 150))
      DrawText(Width/2 - TextWidth("Game over!")/2, Height/2 - TextHeight("Game over!")/2, "Game over!", RGBA(0, 0, 0, 200))
    EndIf
    
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
          ElseIf Field(ix, iy) > 0 And Field(ix, iy) = Field(jx, jy)
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
    
    Select Random(9)
      Case 0 To 8 : Game\Field(Empty_Tile()\X,Empty_Tile()\Y) = 2 ;Pow(2, Random(5)+1)
      Case 9 : Game\Field(Empty_Tile()\X,Empty_Tile()\Y) = 4
    EndSelect
    
    ;Game\Field(Empty_Tile()\X,Empty_Tile()\Y) = 3
    
    Game\Animation\New(Empty_Tile()\X, Empty_Tile()\Y) = #True
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
  ; #### Reset new tile array for animations
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      Game\Animation\New(ix,iy) = #False
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
        If Main\Highscore < Game\Score
          Main\Highscore = Game\Score
        EndIf
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
  Protected i, Found
  
  If Gamelogic_Move_Helper(Direction)
    Gamelogic_Place_Random()
  EndIf
  
  ; #### Check if there is any movable direction left
  For i = 0 To 3
    If Field_Check_Direction(Game\Field(), i)
      Found = #True
      Break
    EndIf
  Next
  If Not Found
    Game\Lost = #True
    AI_Main\State = #AI_State_Stop
  EndIf
  
EndProcedure

Procedure Gamelogic_Restart()
  Protected ix, iy
  
  LockMutex(AI_Main\Mutex_ID)
  
  ; #### Initialize transition array for animations
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      Game\Animation\Transition(ix,iy)\X = ix
      Game\Animation\Transition(ix,iy)\Y = iy
    Next
  Next
  ; #### Initialize new tile array for animations
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      Game\Animation\New(ix,iy) = #False
    Next
  Next
  ; #### Initialize additional array for animations
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      Game\Animation\Additional_Tile(ix,iy)\Value = 0
    Next
  Next
  
  ; #### Initialize Field
  For ix = 0 To #Field_Size-1
    For iy = 0 To #Field_Size-1
      Game\Field(ix,iy) = 0
    Next
  Next
  
  Game\Lost = #False
  
  Game\Score = 0
  Main_Window\Canvas_Info_Redraw = #True
  
  AI_Main\State = #AI_State_Stop
  
  UnlockMutex(AI_Main\Mutex_ID)
  
  ; #### Game starts with two random tiles
  Gamelogic_Place_Random()
  Gamelogic_Place_Random()
EndProcedure

Procedure Configuration_Save(Filename.s)
  If CreatePreferences(Filename, #PB_Preference_GroupSeparator)
    
    PreferenceGroup("Main")
    WritePreferenceInteger("Highscore", Main\Highscore)
    
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
  
  PreferenceGroup("Main")
  Main\Highscore = ReadPreferenceInteger("Highscore", 0)
  
  PreferenceGroup("AI")
  If Not AI_Change_By_Name(ReadPreferenceString("Name", ""))
    AI_Change(0)
  EndIf
  
  AI_Main\Delay = ReadPreferenceInteger("Step_Delay", 100)
  
  ClosePreferences()
EndProcedure

Procedure Main()
  
  If Main_Window\Canvas_Info_Redraw
    Main_Window\Canvas_Info_Redraw = #False
    Main_Window_Redraw_Info()
  EndIf
  
  If Main_Window\Canvas_Field_Redraw
    Main_Window\Canvas_Field_Redraw = #False
    Main_Window_Redraw_Field()
  EndIf
  
  About_Main()
  AI_Settings_Main()
  Tuner_Main()
  
EndProcedure

; ##################################################### Initialisation ##############################################

Configuration_Load(GetPreferencesDirectory() + "D3\2048\Settings.txt")

AI_Main\Mutex_ID = CreateMutex()
AI_Main\Thread_ID = CreateThread(@AI_Thread(), 0)

Main_Window_Open()

;Tuner_Window_Open()

Gamelogic_Restart()

; ##################################################### Main ########################################################

Repeat
  
  If WaitWindowEvent(10)
    While WindowEvent()
    Wend
  EndIf
  
  ; ################### Main functions of all modules
  
  Main()
  
Until Main\Quit

; ##################################################### End #########################################################

WaitThread(AI_Main\Thread_ID)

MakeSureDirectoryPathExists(GetPreferencesDirectory() + "D3\2048\")
Configuration_Save(GetPreferencesDirectory() + "D3\2048\Settings.txt")

; ##################################################### Data Sections ###############################################

DataSection
  Icon_Restart:           : IncludeBinary "Data/Icons/Restart.png"
  Icon_Restart_With_Seed: : IncludeBinary "Data/Icons/Restart_With_Seed.png"
  
  Icon_AI_Start:          : IncludeBinary "Data/Icons/AI_Start.png"
  Icon_AI_Stop:           : IncludeBinary "Data/Icons/AI_Stop.png"
  Icon_AI_Step:           : IncludeBinary "Data/Icons/AI_Step.png"
  Icon_AI_Settings:       : IncludeBinary "Data/Icons/AI_Settings.png"
EndDataSection
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 370
; FirstLine = 355
; Folding = ----
; EnableUnicode
; EnableXP
; DisableDebugger