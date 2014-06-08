; ##################################################### Documentation ###############################################
; 
; Todo:
;   
; ##################################################### Includes ####################################################

; ##################################################### Constants ###################################################

#AI_WorstCase_Depth = 4

; ##################################################### Structures ##################################################

Structure AI_WorstCase
  
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Declares ####################################################

; ##################################################### Macros ######################################################

; ##################################################### Includes ####################################################

; ##################################################### Procedures ##################################################

Procedure.d AI_WorstCase_Move(Array Field.i(2), Direction)
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
      ElseIf Field(cx,cy) = Field(tx,ty) And Field(cx,cy) > 0 And Field(tx,ty) > 0
        Rating + Field(tx,ty)*Field(tx,ty)
        Field(cx,cy) + 1;Field(tx,ty)
        Field(tx,ty) = 0
        cx = tx : cy = ty
      ElseIf Field(cx,cy) <> Field(tx,ty) And Field(tx,ty)
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

Procedure.d AI_WorstCase_Rate_Chain(Array Field.i(2), Array Occupied.a(2), ix, iy, Value)
  Protected Result.d = 0, Temp_Result.d, Temp_Result_Max.d
  Protected Dim Temp_Occupied.a(#Field_Size,#Field_Size)
  
  CopyArray(Occupied(), Temp_Occupied())
  
  If ix >= 0 And iy >= 0 And ix < #Field_Size And iy < #Field_Size And Field(ix,iy) <= Value And Field(ix,iy) > 0
    Result = Field(ix,iy)
    
    If Field(ix,iy) = Value
      Result / 2
    EndIf
    Temp_Occupied(ix,iy) = #True
    
    If ix < #Field_Size-1 And Temp_Occupied(ix+1,iy) = #False
      Temp_Result = AI_WorstCase_Rate_Chain(Field(), Temp_Occupied(), ix+1, iy, Field(ix,iy))
      If Temp_Result_Max < Temp_Result : Temp_Result_Max = Temp_Result : EndIf
    EndIf
    If iy < #Field_Size-1 And Temp_Occupied(ix,iy+1) = #False
      Temp_Result = AI_WorstCase_Rate_Chain(Field(), Temp_Occupied(), ix, iy+1, Field(ix,iy))
      If Temp_Result_Max < Temp_Result : Temp_Result_Max = Temp_Result : EndIf
    EndIf
    If ix > 0 And Temp_Occupied(ix-1,iy) = #False
      Temp_Result = AI_WorstCase_Rate_Chain(Field(), Temp_Occupied(), ix-1, iy, Field(ix,iy))
      If Temp_Result_Max < Temp_Result : Temp_Result_Max = Temp_Result : EndIf
    EndIf
    If iy > 0 And Temp_Occupied(ix,iy-1) = #False
      Temp_Result = AI_WorstCase_Rate_Chain(Field(), Temp_Occupied(), ix, iy-1, Field(ix,iy))
      If Temp_Result_Max < Temp_Result : Temp_Result_Max = Temp_Result : EndIf
    EndIf
    
    Result + Temp_Result_Max
  EndIf
  
  ProcedureReturn Result
EndProcedure

Procedure.d AI_WorstCase_Recursion(Array Field.i(2), Direction, Iteration_Left)
  Protected Dim Temp_Field.i(#Field_Size,#Field_Size)
  Protected Dim Temp_Field_2.i(#Field_Size,#Field_Size)
  Protected Dim Chain_Occupied.a(#Field_Size,#Field_Size)
  Protected Rating.d = 0, Temp_Rating.d, Temp_Rating_Min.d, Temp_Rating_Max.d
  Protected i, ix, iy, jx, jy, Temp_Value
  
  Iteration_Left - 1
  
  If Field_Check_Direction(Field(), Direction)
    
    CopyArray(Field(), Temp_Field())
    ;AI_WorstCase_Move(Temp_Field(), Direction)
    Rating = AI_WorstCase_Move(Temp_Field(), Direction) * 200
    
    
    Temp_Rating_Max = 0
    For ix = 0 To 1
      For iy = 0 To 1
        Temp_Rating = AI_WorstCase_Rate_Chain(Temp_Field(), Chain_Occupied(), ix*(#Field_Size-1), iy*(#Field_Size-1), 1+Temp_Field(ix*(#Field_Size-1), iy*(#Field_Size-1)))
        If Temp_Rating_Max < Temp_Rating
          Temp_Rating_Max = Temp_Rating
        EndIf
      Next
    Next
    Rating + Temp_Rating_Max * 1000
    
    ;Temp_Rating_Max = 0
    ;For ix = 0 To 1
    ;  For iy = 0 To 1
    ;    Temp_Rating = AI_WorstCase_Rate_Distance(Temp_Field(), ix*(#Field_Size-1), iy*(#Field_Size-1))
    ;    If Temp_Rating_Max < Temp_Rating
    ;      Temp_Rating_Max = Temp_Rating
    ;    EndIf
    ;  Next
    ;Next
    ;Rating + Temp_Rating_Max * 1000
    
    For ix = 0 To #Field_Size-1
      For iy = 0 To #Field_Size-1
        Select Field(ix, iy)
          Case 0 : Rating + 1000
        EndSelect
      Next
    Next
    
    For ix = 0 To #Field_Size-1
      For iy = 0 To #Field_Size-1
        For i = 0 To 3
          Select i
            Case 0 : jx = -1 : jy =  0
            Case 1 : jx =  0 : jy = -1
            Case 2 : jx =  1 : jy =  0
            Case 3 : jx =  0 : jy =  1
          EndSelect
          If ix+jx >= 0 And iy+jy >= 0 And ix+jx < #Field_Size And iy+jy < #Field_Size
            If Field(ix, iy) < Field(ix+jx, iy+jy) And Field(ix, iy)
              ;Rating + (Field(ix+jx, iy+jy) - Field(ix, iy)) * 100
            EndIf
          EndIf
        Next
      Next
    Next
    
    ; #### Neg. rate double numbers far away
    For ix = 0 To #Field_Size-1
      For iy = 0 To #Field_Size-1
        For jx = 0 To #Field_Size-1
          For jy = 0 To #Field_Size-1
            If ix <> jx Or iy <> jy
              If Field(ix, iy) = Field(jx, jy)
                Rating + (2-Abs(ix-jx)-Abs(iy-jy))*1000
              EndIf
            EndIf
          Next
        Next
      Next
    Next
    
    If Iteration_Left > 0
      For i = 0 To 3
        Temp_Rating_Min = Infinity()
        For ix = 0 To #Field_Size-1
          For iy = 0 To #Field_Size-1
            If Temp_Field(ix, iy) = 0
              CopyArray(Temp_Field(), Temp_Field_2())
              Temp_Field_2(ix, iy) = 2;-1;(Random(1)+1)*2
              Temp_Rating = AI_WorstCase_Recursion(Temp_Field_2(), i, Iteration_Left)
              If Temp_Rating_Min > Temp_Rating
                Temp_Rating_Min = Temp_Rating
              EndIf
            EndIf
          Next
        Next
        If Not IsInfinity(Temp_Rating_Min)
          Rating + Temp_Rating_Min * 0.3
        EndIf
      Next
    EndIf
    
    ;Debug Rating
    
  Else
    
    ;Rating = -100
    
  EndIf
  
  ProcedureReturn Rating
EndProcedure

Procedure.i AI_WorstCase_Do(Array Field.i(2))
  Protected Rating.d, Highest_Rating.d, Highest_Direction = -1
  Protected i
  
  Highest_Rating = -Infinity()
  For i = 0 To 3
    If Field_Check_Direction(Field(), i)
      Rating = AI_WorstCase_Recursion(Field(), i, #AI_WorstCase_Depth)
      If i = #Direction_Down
        ;Rating * 0
      EndIf
      ;Debug Rating
      If Highest_Rating <= Rating
        Highest_Rating = Rating
        Highest_Direction = i
      EndIf
    EndIf
  Next
  
  ProcedureReturn Highest_Direction
EndProcedure

; ##################################################### Initialisation ##############################################

AI_Add("WorstCase", @AI_WorstCase_Do())

; ##################################################### Main ########################################################

; ##################################################### End #########################################################

; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; Folding = -
; EnableUnicode
; EnableXP