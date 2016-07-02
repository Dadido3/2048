; ##################################################### License / Copyright #########################################
; 
; ##################################################### Documentation / Comments ####################################
; 
; Todo:
; 
; 
; 
; 
; 
; 
; 
; 
; 
; 
; 
; 
; 
; 
; ##################################################### External Includes ###########################################

DeclareModule Helper
  EnableExplicit
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Constants ###################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Macros ######################################################
  Macro Line(x, y, Width, Height, Color)
    LineXY((x), (y), (x)+(Width), (y)+(Height), (Color))
  EndMacro
  
  ; ################################################### Declares ####################################################
  Declare.s GetFullPathName(Filename.s)
  Declare   IsChildOfPath(Parent.s, Child.s)
  Declare.s SHGetFolderPath(CSIDL)
  Declare.s GetPreferencesDirectory()
  Declare.s GetAppDataDirectory()
  Declare   MakeSureDirectoryPathExists(Path.s)
  
  Declare.q Quad_Divide_Floor(A.q, B.q)
  Declare.q Quad_Divide_Ceil(A.q, B.q)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module Helper
  EnableExplicit
  
  ; ################################################### Constants ###################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Procedures ##################################################
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    
    Procedure.s GetFullPathName(Filename.s)
      Protected Characters
      Protected *Temp_Buffer
      Protected Result.s
      
      Characters = GetFullPathName_(@Filename, #Null, #Null, #Null)
      *Temp_Buffer = AllocateMemory(Characters * SizeOf(Character))
      
      GetFullPathName_(@Filename, Characters, *Temp_Buffer, #Null)
      Result = PeekS(*Temp_Buffer, Characters)
      
      FreeMemory(*Temp_Buffer)
      
      ProcedureReturn Result
    EndProcedure
    
    Procedure IsChildOfPath(Parent.s, Child.s)
      Protected Parent_Full.s = GetPathPart(GetFullPathName(Parent))
      Protected Child_Full.s = GetPathPart(GetFullPathName(Child))
      
      If Left(Child_Full, Len(Parent_Full)) = Parent_Full
        ProcedureReturn #True
      Else
        ProcedureReturn #False
      EndIf
    EndProcedure
    
  CompilerEndIf
  
  Procedure.s SHGetFolderPath(CSIDL)
    Protected *String = AllocateMemory(#MAX_PATH+1)
    SHGetFolderPath_(0, CSIDL, #Null, 0, *String)     ; Doesn't include the last "\"
    Protected String.s = PeekS(*String)
    FreeMemory(*String)
    ProcedureReturn String
  EndProcedure
  
  Procedure.s GetPreferencesDirectory()
    CompilerSelect #PB_Compiler_OS
      CompilerCase #PB_OS_Windows
        ProcedureReturn SHGetFolderPath(#CSIDL_APPDATA) + "\"
        
      CompilerCase #PB_OS_Linux
        ProcedureReturn GetHomeDirectory() + "/." ; Not tested
        
      CompilerCase #PB_OS_MacOS
        ProcedureReturn GetHomeDirectory() + "Library/Preferences/" ; Not tested
        
      CompilerDefault
        CompilerError "OS not supported"
        
    CompilerEndSelect
  EndProcedure
  
  Procedure.s GetAppDataDirectory()
    CompilerSelect #PB_Compiler_OS
      CompilerCase #PB_OS_Windows
        ProcedureReturn SHGetFolderPath(#CSIDL_APPDATA) + "\"
        
      CompilerCase #PB_OS_Linux
        ProcedureReturn GetHomeDirectory() + "/." ; Not tested
        
      CompilerCase #PB_OS_MacOS
        ProcedureReturn GetHomeDirectory() + "Library/Application Support/" ; Not tested
        
      CompilerDefault
        CompilerError "OS not supported"
        
    CompilerEndSelect
  EndProcedure
  
  Procedure MakeSureDirectoryPathExists(Path.s)
    Protected Parent_Path.s
    Path = GetPathPart(Path)
    Path = ReplaceString(Path, "\", "/")
    
    If FileSize(Path) = -2 Or Path = ""
      ; #### Directory exists
      ProcedureReturn #True
    Else
      ; #### Directory doesn't exist. Check (and create) parent directory, and then create the final directory
      Parent_Path = ReverseString(Path)
      Parent_Path = RemoveString(Parent_Path, "/", #PB_String_CaseSensitive, 1, 1)
      Parent_Path = Mid(Parent_Path, FindString(Parent_Path, "/"))
      Parent_Path = ReverseString(Parent_Path)
      If MakeSureDirectoryPathExists(Parent_Path)
        CreateDirectory(Path)
        ProcedureReturn #True
      EndIf
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  ; #### Works perfectly, A and B can be positive or negative. B must not be zero!
  Procedure.q Quad_Divide_Floor(A.q, B.q)
    Protected Temp.q = A / B
    If (((a ! b) < 0) And (a % b <> 0))
      ProcedureReturn Temp - 1
    Else
      ProcedureReturn Temp
    EndIf
  EndProcedure
  
  ; #### Works perfectly, A and B can be positive or negative. B must not be zero!
  Procedure.q Quad_Divide_Ceil(A.q, B.q)
    Protected Temp.q = A / B
    If (((a ! b) >= 0) And (a % b <> 0))
      ProcedureReturn Temp + 1
    Else
      ProcedureReturn Temp
    EndIf
  EndProcedure
  
EndModule

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 41
; FirstLine = 1
; Folding = --
; EnableUnicode
; EnableXP