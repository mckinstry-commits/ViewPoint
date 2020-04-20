<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
 <head id="Head1" runat="server">
  <title>Microsoft SQL Server Compact Edition Connection Test Results</title>
  <script src="OnlineHelp.js" language="javascript" type="text/javascript"></script>
  <link rel="stylesheet" rev="stylesheet" type="text/css" href="TestConfiguration.css" />
 </head>

<%@ Page Language="vb" AutoEventWireup="false"%>
	<script language="VB" runat="server">
	    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

	        If Not BaseClasses.Configuration.ApplicationSettings.Current.UseSQLCE() Then
	            Me.Result.Text = "Microsoft SQL CE is not enabled in this application."
	            Return
	        End If

	        Dim Password As String = ""
	        Dim TableName As String = "Customers"

	        
	        If Request.QueryString("database") <> "" Then
	            Dim file As String = Request.QueryString("database")
	            If Request.QueryString("table") <> "" Then
	                TableName = Request.QueryString("table")
	            End If
	            If Request.QueryString("password") <> "" Then
	                Password = Request.QueryString("password")
	            End If
	            Try
	                TestConnection(file, TableName, Password)	                
	            Catch ex As Exception
	                Result.Text = ex.Message
	                ServerNameLabel.Text = file
	            End Try
	        Else
	            ' Determine the full path of the default file.
	            ' We assume the default file is in the same folder as this file.
	            Dim appDir As String = System.Web.HttpContext.Current.Server.MapPath(".")
	            Dim file35 As String = System.IO.Path.Combine(appDir, "TestConfiguration35.sdf")
	            Dim file40 As String = System.IO.Path.Combine(appDir, "TestConfiguration40.sdf")
	            Try
	                TestConnection(file35, "Customers", "")
	            Catch ex As Exception
	                Try
	                    TestConnection(file40, "Customers", "")
	                Catch ex2 As Exception
	                    Result.Text = ex.Message & "<br/>" & ex2.Message
	                    ServerNameLabel.Text = file35 & " and " & file40
	                End Try
	            End Try
	        End If

	    End Sub

	    
	    Public Sub TestConnection(ByVal ServerName As String, ByVal Tablename As String, ByVal Password As String)
	        Dim SQLQuery As String = "SELECT TOP (5) * FROM "


	        SQLQuery &= "[" & Tablename & "]"

	        ServerNameLabel.Text = ServerName
	        TableNameLabel.Text = Tablename

	        ' EVERYTHING BELOW SHOULD WORK AS IS WITHOUT ANY CHANGES

	        ' Use a string variable to hold the ConnectionString.
	        Dim connectString As String = "Data Source=" & ServerName & ";"
	        If Password <> "" Then
	            connectString &= "SSCE:Database Password=" & Password
	        End If

	        ' Create an OleDbConnection object,
	        ' and then pass in the ConnectionString to the constructor.
	        'Open the connection.
	        Dim cn As System.Data.IDbConnection = BaseClasses.Data.SqlProvider.SqlProvider.GetConnection(BaseClasses.Configuration.DatabaseConnection.ConnectionType.SQLCECLIENT, connectString)
	        cn.Open()

	        ' Create an OleDbCommand object.
	        ' Notice that this line passes in the SQL statement and the OleDbConnection object.
	        Dim cmd As System.Data.IDbCommand = BaseClasses.Data.SqlProvider.SqlProvider.GetCommand(SQLQuery, cn)

	        ' Send the CommandText to the connection, and then build an OleDbDataReader.
	        ' Note: The OleDbDataReader is forward-only.
	        Dim reader As System.Data.IDataReader = cmd.ExecuteReader()

	        ' Loop through the resultant data selection and add the data value
	        ' for each respective column in the table.
	        Dim r As Integer
	        For r = 1 To 5
	            If (reader.Read()) Then
	                Dim row As TableRow = New TableRow
	                Dim cell As TableCell

	                cell = New TableCell
	                cell.Text = "<b>" & r & "</b>"
	                row.Cells.Add(cell)

	                Dim c As Integer
	                For c = 0 To reader.FieldCount - 1
	                    cell = New TableCell
	                    cell.Text = reader(c).ToString()
	                    row.Cells.Add(cell)
	                Next c

	                'Add the new row to the table.
	                DisplayTable.Rows.Add(row)
	            End If

	        Next r

	        Result.Text = "Test Successful!"

	        ' Close the reader and the related connection.
	        reader.Close()
	        cn.Close()

	    End Sub
	</script>

<body>

<form id="Form1" method="post" runat="server">

<table cellpadding="3" cellspacing="0" border="0" width="100%">
 <tr>
  <td class="page_heading">
	<b><asp:label id="Result" runat="server" Text="Test Failed"/></b><br /><br />
  </td>
 </tr>
 <tr>
  <td>
	Check to make sure up to five rows of data are displayed from the Microsoft SQL Server Compact Edition database.
  </td>
 </tr>

 <tr>
  <td>
	Database File: <asp:Label Id="ServerNameLabel" runat="server"/><br />
	Database Table: <asp:Label Id="TableNameLabel" runat="server"/>
	<br /><br />
  </td>
 </tr>
 <tr>
  <td>
	<asp:Table id="DisplayTable" runat="server" CellSpacing="0" CellPadding="3"
			GridLines="Both"
    		BorderStyle="Solid"
			BorderWidth="1"></asp:Table>
  </td>
 </tr>
 <tr>
  <td>
	<input type="button" value="Close Window" onclick="javascript:window.close();" />
  </td>
 </tr>
</table>

</form>

</body>

</html>