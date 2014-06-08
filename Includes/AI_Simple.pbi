; ##################################################### Documentation ###############################################
; 
; Todo:
;   
; ##################################################### Includes ####################################################

; ##################################################### Constants ###################################################

#AI_Simple_Depth = 5

; ##################################################### Structures ##################################################

Structure AI_Simple
  
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Declares ####################################################

; ##################################################### Macros ######################################################

; ##################################################### Includes ####################################################

; ##################################################### Procedures ##################################################

Procedure.d AI_Simple_Move(Array Field.i(2), Direction)
  Protected i, j, cx, cy, tx, ty
  Protected ix, iy
  Protected Rating.d = 0
  
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
      
      If Field(cx,cy) = 0
        cx = tx : cy = ty
      ElseIf Field(cx,cy) = Field(tx,ty) And Field(cx,cy) > 0
        Rating + 1;Field(tx,ty)
        Field(cx,cy) + Field(tx,ty)
        Field(tx,ty) = 0
        cx = tx : cy = ty
      ElseIf Field(cx,cy) <> Field(tx,ty) And Field(tx,ty) > 0
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
      
      If Field(cx,cy)
        cx = tx : cy = ty
      ElseIf Field(cx,cy) = 0 And Field(tx,ty)
        Field(cx,cy) = Field(tx,ty)
        Field(tx,ty) = 0
        Select Direction
          Case #Direction_Right : cx - 1
          Case #Direction_Up    : cy + 1
          Case #Direction_Left  : cx + 1
          Case #Direction_Down  : cy - 1
        EndSelect
      EndIf
    Next
    
  Next
  
  ProcedureReturn Rating
EndProcedure

Procedure AI_Simple_Fill_Chain(Array Field.i(2), X, Y, Direction, Value)
  Protected i, ix, iy
  Protected Direction_X, Direction_Y
  
  ix = X
  iy = Y
  
  If X >= #Field_Size/2
    Direction_X = -1
  Else
    Direction_X = 1
  EndIf
  If Y >= #Field_Size/2
    Direction_Y = -1
  Else
    Direction_Y = 1
  EndIf
  
  For i = 0 To #Field_Size*#Field_Size-1
    
    If Field(ix, iy) = 0
      Field(ix, iy) = Value
      Break
    EndIf
    
    If Direction
      ; #### Main direction in X
      ix + Direction_X
      If ix < 0
        ix = 0
        Direction_X * -1
        iy + Direction_Y
      ElseIf ix >= #Field_Size
        ix = #Field_Size-1
        Direction_X * -1
        iy + Direction_Y
      EndIf
    Else
      ; #### Main direction in Y
      iy + Direction_Y
      If iy < 0
        iy = 0
        Direction_Y * -1
        ix + Direction_X
      ElseIf iy >= #Field_Size
        iy = #Field_Size-1
        Direction_Y * -1
        ix + Direction_X
      EndIf
    EndIf
  Next
  
EndProcedure

Procedure.d AI_Simple_Rate_Chain(Array Field.i(2), X, Y, Direction)
  Protected i, ix, iy
  Protected Rating.d
  Protected Direction_X, Direction_Y
  Protected Current_Value
  
  ix = X
  iy = Y
  
  If X >= #Field_Size/2
    Direction_X = -1
  Else
    Direction_X = 1
  EndIf
  If Y >= #Field_Size/2
    Direction_Y = -1
  Else
    Direction_Y = 1
  EndIf
  
  For i = 0 To #Field_Size*#Field_Size-1
    
    If i = 0
      Current_Value = Field(ix,iy)
    Else
      If Field(ix,iy) > Current_Value
        Break
      EndIf
      Current_Value = Field(ix,iy)
    EndIf
    
    Rating + Current_Value
    
    If Direction
      ; #### Main direction in X
      ix + Direction_X
      If ix < 0
        ix = 0
        Direction_X * -1
        iy + Direction_Y
      ElseIf ix >= #Field_Size
        ix = #Field_Size-1
        Direction_X * -1
        iy + Direction_Y
      EndIf
    Else
      ; #### Main direction in Y
      iy + Direction_Y
      If iy < 0
        iy = 0
        Direction_Y * -1
        ix + Direction_X
      ElseIf iy >= #Field_Size
        iy = #Field_Size-1
        Direction_Y * -1
        ix + Direction_X
      EndIf
    EndIf
  Next
  
  ProcedureReturn Rating
EndProcedure

Procedure.d AI_Simple_Recursion(Array Field.i(2), Direction, Iteration_Left)
  Protected Dim Temp_Field.i(#Field_Size,#Field_Size)
  Protected Rating.d = 0
  Protected Rating_Chain.d, Rating_Chain_Temp.d
  Protected Rating_OldChain.d, Rating_OldChain_Temp.d
  Protected OldChain_Start_X = -1, OldChain_Start_Y = -1, OldChain_Direction = -1
  Protected Rating_Move.d
  Protected Rating_Previous.d, Rating_Previous_Temp.d
  Protected Rating_Far.d
  Protected Tiles_Free, Tile_Max
  Protected i, ix, iy, jx, jy
  
  Iteration_Left - 1
  
  If Field_Check_Direction(Field(), Direction)
    
    ; #### Move the field
    CopyArray(Field(), Temp_Field())
    Rating_Move = AI_Simple_Move(Temp_Field(), Direction)
    
    ; #### determine the old max. tile value
    Tile_Max = 0
    For ix = 0 To #Field_Size-1
      For iy = 0 To #Field_Size-1
        If Tile_Max < Field(ix,iy)
          Tile_Max = Field(ix,iy)
        EndIf
      Next
    Next
    
    ; #### Find the old chain
    Rating_Chain = 0
    For ix = 0 To #Field_Size-1 Step #Field_Size-1
      For iy = 0 To #Field_Size-1 Step #Field_Size-1
        If Field(ix,iy) = Tile_Max
          For i = 0 To 1
            Rating_OldChain_Temp = AI_Simple_Rate_Chain(Field(), ix, iy, i)
            If Rating_OldChain < Rating_OldChain_Temp
              Rating_OldChain = Rating_OldChain_Temp
              OldChain_Start_X = ix
              OldChain_Start_Y = iy
              OldChain_Direction = i
            EndIf
          Next
        EndIf
      Next
    Next
    
    ; #### Add a tile to the most annoying position, to the corner where the chain started for example!
    If OldChain_Start_X >= 0 And OldChain_Start_Y >= 0 And OldChain_Direction >= 0
      AI_Simple_Fill_Chain(Temp_Field(), OldChain_Start_X, OldChain_Start_Y, OldChain_Direction, 2)
    EndIf
    
    ;If OldChain_Start_X >= 0 And OldChain_Start_Y >= 0; And Not Temp_Field(OldChain_Start_X, OldChain_Start_Y)
    ;  Temp_Field(OldChain_Start_X, OldChain_Start_Y) = 2
    ;Else
    ;  For ix = 0 To #Field_Size-1
    ;    For iy = 0 To #Field_Size-1
    ;      If OldChain_Start_X = 0 And OldChain_Start_Y = 0
    ;        jx = ix : jy = iy
    ;      ElseIf OldChain_Start_X <> 0 And OldChain_Start_Y = 0
    ;        jx = #Field_Size-1-ix : jy = iy
    ;      ElseIf OldChain_Start_X <> 0 And OldChain_Start_Y <> 0
    ;        jx = #Field_Size-1-ix : jy = #Field_Size-1-iy
    ;      Else
    ;        jx = ix : jy = #Field_Size-1-iy
    ;      EndIf
    ;      If Not Temp_Field(jx,jy)
    ;        Temp_Field(jx,jy) = 2
    ;        Break 2
    ;      EndIf
    ;    Next
    ;  Next
    ;EndIf
    
    ; #### Count free tiles, determine the max. tile value
    Tile_Max = 0
    For ix = 0 To #Field_Size-1
      For iy = 0 To #Field_Size-1
        If Tile_Max < Temp_Field(ix,iy)
          Tile_Max = Temp_Field(ix,iy)
        EndIf
        If Temp_Field(ix,iy) = 0
          Tiles_Free + 1
        EndIf
      Next
    Next
    
    ; #### Rate how well everything is lined up (only from a corner, and only if the chain starts with one of the max-tiles)
    Rating_Chain = 0
    For ix = 0 To #Field_Size-1 Step #Field_Size-1
      For iy = 0 To #Field_Size-1 Step #Field_Size-1
        If Temp_Field(ix,iy) = Tile_Max
          For i = 0 To 1
            Rating_Chain_Temp = AI_Simple_Rate_Chain(Temp_Field(), ix, iy, i)
            If Rating_Chain < Rating_Chain_Temp
              Rating_Chain = Rating_Chain_Temp
            EndIf
          Next
        EndIf
      Next
    Next
    
    ; #### Neg. rate double numbers far away
    For ix = 0 To #Field_Size-1
      For iy = 0 To #Field_Size-1
        For jx = 0 To #Field_Size-1
          For jy = 0 To #Field_Size-1
            If ix <> jx Or iy <> jy
              If Temp_Field(ix, iy) = Temp_Field(jx, jy)
                Rating_Far + (2-Abs(ix-jx)-Abs(iy-jy)) * Temp_Field(jx, jy)
              EndIf
            EndIf
          Next
        Next
      Next
    Next
    
    
    ; #### Olde stuff
    ;For ix = 0 To #Field_Size-1
    ;  For iy = 0 To #Field_Size-2
    ;    If Field(ix,iy) And Field(ix,iy+1)
    ;      Rating + (Field(ix,iy) - Field(ix,iy+1)) * 1000
    ;    EndIf
    ;  Next
    ;Next
    
    If Iteration_Left > 0
      Rating_Previous = -Infinity()
      For i = 0 To 3
        Rating_Previous_Temp = AI_Simple_Recursion(Temp_Field(), i, Iteration_Left)
        If Rating_Previous < Rating_Previous_Temp
          Rating_Previous = Rating_Previous_Temp
        EndIf
        ;Rating_Previous + AI_Simple_Recursion(Temp_Field(), i, Iteration_Left)
      Next
    EndIf
    
    ; #### For the Tuner
    ;LockMutex(Tuner_Main\Mutex_ID)
    ;If FirstElement(Tuner_Dataset())
    ;  Rating = Rating_Move * Tuner_Dataset()\Variable("Move")\Value
    ;  Rating + Rating_Chain * Tuner_Dataset()\Variable("Chain")\Value
    ;  Rating + Rating_Previous * Tuner_Dataset()\Variable("Previous")\Value
    ;  Rating + Rating_Far * Tuner_Dataset()\Variable("Far")\Value
    ;  Rating + Tiles_Free * Tuner_Dataset()\Variable("Tiles_Free")\Value
    ;EndIf
    ;UnlockMutex(Tuner_Main\Mutex_ID)
    
    ; #### Tuned values For a 4x4 Field
    Rating = Rating_Move * 58.8
    Rating + Rating_Chain * 28980
    Rating + Rating_Previous * 0.72
    Rating + Rating_Far * 2.4
    Rating + Tiles_Free * 122
    
    ; #### Tuned values for a 3x3 Field
    ;Rating = Rating_Move * 50
    ;Rating + Rating_Chain * 27180
    ;Rating + Rating_Previous * 0.72
    ;Rating + Rating_Far * 20
    ;Rating + Tiles_Free * 140
    
    ; #### Handtuned values
    ;Rating = Rating_Move * 100
    ;Rating + Rating_Chain * 15000
    ;Rating + Rating_Previous * 0.9
    ;Rating + Rating_Far * 10
    ;;Rating + Tiles_Free * 1000
    
    If Rating_Chain < Rating_OldChain
      Rating - 1000000
    EndIf
    
  Else
    
    Rating = - 1000000
    
  EndIf
  
  ProcedureReturn Rating
EndProcedure

; #### Tuner stuff
; If AddElement(Tuner_Dataset())
;   Tuner_Dataset()\ID = Tuner_Main\ID_Counter : Tuner_Main\ID_Counter + 1
;   
;   Tuner_Dataset()\Variable("Move")\Value = 50
;   Tuner_Dataset()\Variable()\Stepsize = 20
;   Tuner_Dataset()\Variable()\Original= Tuner_Dataset()\Variable()\Value
;   
;   Tuner_Dataset()\Variable("Chain")\Value = 27180
;   Tuner_Dataset()\Variable()\Stepsize = 3000
;   Tuner_Dataset()\Variable()\Original= Tuner_Dataset()\Variable()\Value
;   
;   Tuner_Dataset()\Variable("Previous")\Value = 0.72
;   Tuner_Dataset()\Variable()\Stepsize = 0.1
;   Tuner_Dataset()\Variable()\Original= Tuner_Dataset()\Variable()\Value
;   
;   Tuner_Dataset()\Variable("Far")\Value = 20
;   Tuner_Dataset()\Variable()\Stepsize = 20
;   Tuner_Dataset()\Variable()\Original= Tuner_Dataset()\Variable()\Value
;   
;   Tuner_Dataset()\Variable("Tiles_Free")\Value = 140
;   Tuner_Dataset()\Variable()\Stepsize = 20
;   Tuner_Dataset()\Variable()\Original= Tuner_Dataset()\Variable()\Value
;   
;   Tuner_Dataset()\Max_Games = #Tuner_Games
; EndIf

Procedure.i AI_Simple_Do(Array Field.i(2))
  Protected Rating.d, Highest_Rating.d, Highest_Direction = -1
  Protected i
  
  Highest_Rating = -Infinity()
  For i = 0 To 3
    If Field_Check_Direction(Field(), i)
      Rating = AI_Simple_Recursion(Field(), i, #AI_Simple_Depth)
      If Highest_Rating <= Rating
        Highest_Rating = Rating
        Highest_Direction = i
      EndIf
    EndIf
  Next
  
  ProcedureReturn Highest_Direction
EndProcedure

; ##################################################### Initialisation ##############################################

AI_Add("Simple", @AI_Simple_Do())

; ##################################################### Main ########################################################

; ##################################################### End #########################################################

; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 371
; FirstLine = 324
; Folding = -
; EnableUnicode
; EnableXP