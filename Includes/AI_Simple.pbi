; ##################################################### Dokumentation / Kommentare ##################################
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
      ElseIf Field(cx,cy) = Field(tx,ty)
        Rating + Field(tx,ty)
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

Procedure.d AI_Simple_Recursion(Array Field.i(2), Direction, Iteration_Left)
  Protected Dim Temp_Field.i(#Field_Size,#Field_Size)
  Protected Rating.d = 0
  Protected i, ix, iy, Temp_Value
  
  Iteration_Left - 1
  
  If Field_Check_Direction(Field(), Direction)
    
    CopyArray(Field(), Temp_Field())
    Rating = AI_Simple_Move(Temp_Field(), Direction) * 10000
    
    ;Debug Rating
    
    For ix = 0 To #Field_Size-1
      For iy = 0 To #Field_Size-2
        If Field(ix,iy) And Field(ix,iy+1)
          Rating + (Field(ix,iy) - Field(ix,iy+1)) * 1000
        EndIf
      Next
    Next
    
    ; #### Rate how good the numbers are lined up
    For iy = 0 To #Field_Size-1
      For i = 0 To #Field_Size-1
        If iy & 1
          ix = i
        Else
          ix = #Field_Size-1-i
        EndIf
        
        If ix = #Field_Size-1 And iy = 0
          Temp_Value = Field(ix,iy)
        Else
          If Temp_Value = Field(ix,iy) Or Temp_Value = Field(ix,iy) * 2
            Rating + 10000 * Temp_Value
            Temp_Value = Field(ix,iy)
          ElseIf Temp_Value > Field(ix,iy)
            Rating + 6000 * Temp_Value
            Temp_Value = Field(ix,iy)
          Else
            Rating + 6000 * Temp_Value
            ;Rating - Field(ix,iy) * 10000
            Break 2
          EndIf
        EndIf
      Next
    Next
    
    If Iteration_Left > 0
      For i = 0 To 3
        Rating + 0.1 * AI_Simple_Recursion(Temp_Field(), i, Iteration_Left)
      Next
    EndIf
    
    ;Debug Rating
    
  Else
    
    Rating = -1000
    
  EndIf
  
  ProcedureReturn Rating
EndProcedure

Procedure.i AI_Simple_Do(Array Field.i(2))
  Protected Rating.d, Highest_Rating.d, Highest_Direction = -1
  Protected i
  
  Highest_Rating = -Infinity()
  For i = 0 To 3
    If Field_Check_Direction(Field(), i)
      Rating = AI_Simple_Recursion(Field(), i, #AI_Simple_Depth)
      If i = #Direction_Down
        Rating * 0
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

AI_Add("Simple", @AI_Simple_Do())

; ##################################################### Main ########################################################

; ##################################################### End #########################################################

; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 162
; FirstLine = 104
; Folding = -
; EnableUnicode
; EnableXP