Imports System.Windows.Forms

Public Class mainForm

    Private Sub b_ok_Click(sender As Object, e As EventArgs) Handles b_ok.Click
        Me.txt_status.Clear()
        Me.txt_status.Refresh()
        click_ok()
    End Sub

    Private Sub b_cancel_Click(sender As Object, e As EventArgs) Handles b_cancel.Click
        click_cancel()
    End Sub

    Private Sub mainForm_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' set default pay period end date

        Dim defaultDate As Date

        ' Typically we run the transfer on Monday or Tuesday for the previous week's labor.
        ' To get the dates from last week, first get the date of the most recent Monday. 
        ' (Probably today, or yesterday.) That is the end date, not inclusive.  

        ' get most recent monday 
        Dim today As Date = Date.Today
        Dim dayDiff As Integer = today.DayOfWeek - DayOfWeek.Monday  ' .NET day of the week, Sun=0, Mon=1, Sat=6
        dayDiff = IIf(dayDiff < 0, dayDiff + 7, dayDiff)    ' if today is Sunday, add a week to the diff (i.e., go 1 week earlier)
        defaultDate = today.AddDays(-dayDiff)  ' subract the dayDiff to get the most recent Monday

        ' subtract 1 day to get to end of pay period (Sunday)
        defaultDate = defaultDate.AddDays(-1)

        ' use the calculated value as the default Pay Period End Date
        Me.dt_end.Value = defaultDate

        ' define the key-value pairs for the Node combo box
        Dim comboSource As New Dictionary(Of String, String)()
        comboSource.Add("", "")
        comboSource.Add("200", "200-Seattle Sprinkler")
        comboSource.Add("251", "251-Spokane Sprinkler")
        comboSource.Add("711", "711-Portland Service")
        comboSource.Add("900", "900-Seattle Service")
        comboSource.Add("907", "907-Spokane Service")
        comboSource.Add("909", "909-Tacoma Service")
        Me.cb_node.DataSource = New BindingSource(comboSource, Nothing)
        Me.cb_node.DisplayMember = "Value"
        Me.cb_node.ValueMember = "Key"
    End Sub

    Private Sub cb_node_SelectedIndexChanged(sender As Object, e As EventArgs) Handles cb_node.SelectedIndexChanged

    End Sub
End Class