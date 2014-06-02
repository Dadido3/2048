; ##################################################### Dokumentation / Kommentare ##################################
; 
; Todo:
;   
; ##################################################### Includes ####################################################

; ##################################################### Constants ###################################################

#AI_Dadido3_Depth = 4

; ##################################################### Structures ##################################################

Structure AI_Dadido3
  
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Declares ####################################################

; ##################################################### Macros ######################################################

; ##################################################### Includes ####################################################

; ##################################################### Procedures ##################################################

Procedure.d AI_Dadido3_Move(Array Field.i(2), Direction)
  Protected i, j, cx, cy, tx, ty
  Protected ix, iy
  Protected Rating.d = 0.0
  
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
        Field(cx,cy) + Field(tx,ty)
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

Procedure.d AI_Dadido3_Rate_Chain(Array Field.i(2), ix, iy, Value)
  Protected Result.d = 0, Temp_Result.d, Temp_Result_Max.d
  
  If ix >= 0 And iy >= 0 And ix < #Field_Size And iy < #Field_Size And Field(ix,iy) < Value
    Result = Field(ix,iy)
    
    Temp_Result = AI_Dadido3_Rate_Chain(Field(), ix+1, iy, Field(ix,iy))
    If Temp_Result_Max < Temp_Result : Temp_Result_Max = Temp_Result : EndIf
    Temp_Result = AI_Dadido3_Rate_Chain(Field(), ix, iy+1, Field(ix,iy))
    If Temp_Result_Max < Temp_Result : Temp_Result_Max = Temp_Result : EndIf
    Temp_Result = AI_Dadido3_Rate_Chain(Field(), ix-1, iy, Field(ix,iy))
    If Temp_Result_Max < Temp_Result : Temp_Result_Max = Temp_Result : EndIf
    Temp_Result = AI_Dadido3_Rate_Chain(Field(), ix, iy-1, Field(ix,iy))
    If Temp_Result_Max < Temp_Result : Temp_Result_Max = Temp_Result : EndIf
    
    Result + Temp_Result_Max
  EndIf
  
  ProcedureReturn Result
EndProcedure

Procedure.d AI_Dadido3_Recursion(Array Field.i(2), Direction, Iteration_Left)
  Protected Dim Temp_Field.i(#Field_Size,#Field_Size)
  Protected Dim Temp_Field_2.i(#Field_Size,#Field_Size)
  Protected Rating.d = 0, Temp_Rating.d, Temp_Rating_Min.d, Temp_Rating_Max.d
  Protected i, ix, iy, Temp_Value
  
  Iteration_Left - 1
  
  If Field_Check_Direction(Field(), Direction)
    
    CopyArray(Field(), Temp_Field())
    Rating = AI_Dadido3_Move(Temp_Field(), Direction)*100
    
    Temp_Rating_Max = 0
    For ix = 0 To 1
      For iy = 0 To 1
        Temp_Rating = AI_Dadido3_Rate_Chain(Temp_Field(), ix*(#Field_Size-1), iy*(#Field_Size-1), 1+Temp_Field(ix*(#Field_Size-1), iy*(#Field_Size-1)))
        If Temp_Rating_Max < Temp_Rating
          Temp_Rating_Max = Temp_Rating
        EndIf
      Next
    Next
    
    Rating + Temp_Rating_Max * 1000
    
    If Iteration_Left > 0
      For i = 0 To 3
        Temp_Rating_Min = Infinity()
        For ix = 0 To #Field_Size-1
          For iy = 0 To #Field_Size-1
            If Temp_Field(ix, iy) = 0
              CopyArray(Temp_Field(), Temp_Field_2())
              Temp_Field_2(ix, iy) = -1;(Random(1)+1)*2
              Temp_Rating = AI_Dadido3_Recursion(Temp_Field_2(), i, Iteration_Left)
              If Temp_Rating_Min > Temp_Rating
                Temp_Rating_Min = Temp_Rating
              EndIf
            EndIf
          Next
        Next
        If Not IsInfinity(Temp_Rating_Min)
          Rating + Temp_Rating_Min * 0.2
        EndIf
      Next
    EndIf
    
    ;Debug Rating
    
  Else
    
    Rating = -1000
    
  EndIf
  
  ProcedureReturn Rating
EndProcedure

Procedure.i AI_Dadido3_Do(Array Field.i(2))
  Protected Rating.d, Highest_Rating.d, Highest_Direction = -1
  Protected i
  
  Highest_Rating = -Infinity()
  For i = 0 To 3
    If Field_Check_Direction(Field(), i)
      Rating = AI_Dadido3_Recursion(Field(), i, #AI_Dadido3_Depth)
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

AI_Add("Dadido3", @AI_Dadido3_Do())

; ##################################################### Main ########################################################

; ##################################################### End #########################################################

; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 174
; FirstLine = 131
; Folding = -
; EnableUnicode
; EnableXP