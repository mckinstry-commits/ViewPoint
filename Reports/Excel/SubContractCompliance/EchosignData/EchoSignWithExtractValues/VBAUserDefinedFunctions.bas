Attribute VB_Name = "RegexFunctions"
Function ExtractValues(ByVal text As String, ByVal pattern As String) As String

Dim result As String
Dim allMatches As Object
Dim RE As Object
Set RE = CreateObject("vbscript.regexp")

RE.pattern = pattern
RE.Global = True
RE.IgnoreCase = True
Set allMatches = RE.Execute(text)

If allMatches.Count <> 0 Then
    result = allMatches.Item(0).Value
End If

ExtractValues = result

End Function

