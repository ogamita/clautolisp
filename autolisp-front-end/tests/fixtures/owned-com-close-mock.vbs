Option Explicit
Dim fso, app, doc, created, runFile, statusFile, errFile, scenario
Dim lifeShell, lifeRoot, lifeHelper, lifeIdentity, lifeRequest, lifeResult, lifeCode, lifeDoc, lifeIndex, lifeStream, lifeAttempt, lifeError, lifeDescription, lifeFailureStream
Dim attempts, closed, quitCalled
Set fso=CreateObject("Scripting.FileSystemObject")
scenario=WScript.Arguments(1)
lifeRoot=WScript.Arguments(0)
lifeRequest=fso.BuildPath(lifeRoot, scenario & ".request")
lifeResult=fso.BuildPath(lifeRoot, scenario & ".result")
errFile=fso.BuildPath(lifeRoot, scenario & ".errors")
statusFile=fso.BuildPath(lifeRoot, "absent.status")
lifeHelper="unused"
lifeIdentity="unused"
Set lifeStream=fso.CreateTextFile(lifeRequest, True)
lifeStream.Close
Set doc=New MockDoc
Set app=New MockApp
Set lifeShell=New MockShell
created=(scenario <> "attached")
attempts=0
closed=False
quitCalled=False
Sub AppendLine(path, text)
 Dim stream
 Set stream=fso.OpenTextFile(path, 8, True)
 stream.WriteLine text
 stream.Close
End Sub
Class MockDoc
 Sub Close(saveChanges)
  If saveChanges Then Err.Raise 5, , "saving forbidden"
  attempts=attempts+1
  If scenario="persistent" Or attempts<=2 Then Err.Raise -2147418111, , "simulated busy COM"
  closed=True
 End Sub
End Class
Class MockDocs
 Property Get Count
  If closed Then Count=0 Else Count=1
 End Property
 Function Item(index)
  Set Item=doc
 End Function
End Class
Class MockApp
 Property Get Documents
  Set Documents=New MockDocs
 End Property
 Sub Quit
  quitCalled=True
 End Sub
End Class
Class MockShell
 Function Run(command, style, synchronous)
  If Not (app Is Nothing) Or Not (doc Is Nothing) Or Not (lifeDoc Is Nothing) Then Err.Raise 5, , "references retained"
  If scenario="transient" And attempts<>3 Then Err.Raise 5, , "retry count wrong"
  If scenario="persistent" And attempts<>40 Then Err.Raise 5, , "retry not bounded"
  If quitCalled Then Run=0 Else Run=1
 End Function
End Class

Function OwnedComIsReady(a, seconds)
 OwnedComIsReady=(scenario <> "not-ready")
End Function
