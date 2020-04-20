<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
 <head id="Head1" runat="server">
    <title>MySQL Server Connection Test Results</title>

    <script language="javascript" src="OnlineHelp.js" type="text/javascript"></script>
<link href="TestConfiguration.css" rel="stylesheet" rev="stylesheet" type="text/css" />
</head>

<%@ page autoeventwireup="false" debug="true" language="vb" %>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server" language="VB">
	    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

			'=============================================================================================
			' CHANGE ONLY THE FOLLOWING SIX STRINGS
			'=============================================================================================
			Dim ServerName As String =		"(local)"
	        Dim DatabaseName As String =	"Northwind"
	        Dim UserId As String =			"3306"
	        Dim Port As String =			"sa"
	        Dim Password As String =		""
        Dim MySQLQuery As String = "SELECT * FROM "
	        Dim TableName As String = 		"Customer"
			'=============================================================================================
			'=============================================================================================

			If Request.QueryString("server") <> "" Then
				ServerName = Request.QueryString("server")
			End If

			If Request.QueryString("database") <> "" Then
				DatabaseName = Request.QueryString("database")
			End If

            If Request.QueryString("port") <> "" Then
            Port = Request.QueryString("port")
			End If
			
			If Request.QueryString("user") <> "" Then
            UserId = Request.QueryString("user")
			End If

			If Request.QueryString("password") <> "" Then
				Password = Request.QueryString("password")
			End If

			If Request.QueryString("table") <> "" Then
            TableName = Request.QueryString("table")
			End If

			MySQLQuery += TableName

			ServerNameLabel.Text = ServerName
			DatabaseNameLabel.Text = DatabaseName
			TableNameLabel.Text = TableName

			' EVERYTHING BELOW SHOULD WORK AS IS WITHOUT ANY CHANGES

	        ' Use a string variable to hold the ConnectionString.
        Dim connectString As String = "Data Source=" & ServerName & ";" & _
                    "Port=" & Port & ";" & _
           "Database=" & DatabaseName & ";" & _
           "User Id=" & UserId & ";" & _
           "Password=" & Password & ""

	        ' Create an OleDbConnection object,
        ' and then pass in the ConnectionString to the constructor.
        'Dim cst As String = "Data Source=qaxp-net;Port=3306;User Id=root;Password=sa"
        Dim cn As MySql.Data.MySqlClient.MySqlConnection = New MySql.Data.MySqlClient.MySqlConnection(connectString)

	        'Open the connection.
	        cn.Open()
        '   MySQLQuery = "select * from customers"
	        ' Create an OleDbCommand object.
	        ' Notice that this line passes in the SQL statement and the OleDbConnection object.
	        Dim cmd As MySql.Data.MySqlClient.MySqlCommand  = New MySql.Data.MySqlClient.MySqlCommand(MySQLQuery, cn)

	        ' Send the CommandText to the connection, and then build an OleDbDataReader.
	        ' Note: The OleDbDataReader is forward-only.
	        Dim reader As MySql.Data.MySqlClient.MySqlDataReader = cmd.ExecuteReader()

	        ' Loop through the resultant data selection and add the data value
	        ' for each respective column in the table.
	        Dim r As Integer
	        For r = 1 to 5
				If (reader.Read()) Then
					Dim row As TableRow = New TableRow
					Dim cell As TableCell

					cell = New TableCell
					cell.Text = "<b>" & r & "</b>"
					row.Cells.Add(cell)

					Dim c As Integer
					For c = 0 To reader.FieldCount-1
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
    <form id="Form1" runat="server" method="post">
    <table border="0" cellpadding="3," cellspacing="0">
        <tr>
            <td class="page_heading">
                <b>
                    <asp:Label ID="Result" runat="server" Text="Test Failed"></asp:Label></b><br />
                <br />
            </td>
        </tr>
        <tr>
            <td>
                Check to make sure up to five rows of data are displayed from your MySQL Server
                database.
            </td>
        </tr>
        <tr>
            <td>
                Server name:
                <asp:Label ID="ServerNameLabel" runat="server"></asp:Label><br />
                Database name:
                <asp:Label ID="DatabaseNameLabel" runat="server"></asp:Label><br />
                Database Table:
                <asp:Label ID="TableNameLabel" runat="server"></asp:Label>
                <br />
                <br />
            </td>
        </tr>
        <tr>
            <td>
                <asp:Table ID="DisplayTable" runat="server" BorderStyle="Solid" BorderWidth="1" CellPadding="3"
                    CellSpacing="0" GridLines="Both">
                </asp:Table>
            </td>
        </tr>
        <tr>
            <td>
                <input onclick="javascript:window.close();" type="button" value="Close Window" />
            </td>
        </tr>
    </table>
    </form>
</body>
</html>
