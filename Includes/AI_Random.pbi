; ##################################################### Documentation ###############################################
; 
; An example on how to write an AI for 2048.
;   
; ##################################################### Includes ####################################################

; ##################################################### Constants ###################################################

; ##################################################### Structures ##################################################

; ##################################################### Variables ###################################################

; ##################################################### Procedures ##################################################

Procedure.i AI_Random_Do(Array Field.i(2))
  
  ; #### This function gets called if the game asks your AI to make a move.
  ; ####
  ; #### The Field(X,Y) array contains the values of all tiles.
  ; #### The Field consists out of #Field_Size^2 tiles.
  ; #### Field(0,0) is the value of the top left tile,
  ; #### and Field(#Field_Size-1,#Field_Size-1) is the bottom right tile.
  ; #### Field(X,Y) = 0 means that the tile is empty.
  ; #### 
  ; #### You can use Field_Check_Direction(Field(), Direction) to check if the field can be moved in the given direction
  
  ProcedureReturn Random(3) ; Chooses randomly one of the directions (#Direction_Right, #Direction_Down, #Direction_Left, #Direction_Up)
EndProcedure

; ##################################################### Initialisation ##############################################

AI_Add("Random", @AI_Random_Do())

; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 25
; Folding = -
; EnableUnicode
; EnableXP