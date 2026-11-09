Option Explicit
Dim app, scenario, calls, errFile, seconds, result, expected
scenario=WScript.Arguments(0)
calls=0
errFile="unused"
seconds=0
If scenario="ready" Then seconds=2
Set app=New MockApp
Class MockApp
 Function GetAcadState
  calls=calls+1
  If scenario="rejected" Then Err.Raise -2147418111, , "simulated busy COM"
  Set GetAcadState=New MockState
 End Function
End Class
Class MockState
 Property Get IsQuiescent
  IsQuiescent=(scenario="ready" And calls>=3)
 End Property
End Class
Sub AppendLine(path, text)
 WScript.Echo text
End Sub
