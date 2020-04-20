Imports System.Configuration
Imports System.Collections.Specialized
Imports System.Data.SqlClient
Imports System.IO
Imports System.Net.Mail
Imports System.Text
Imports System.Windows.Forms

'Imports System.Xml

' ================================================================================================
' Payroll Transfer
' This console application reads untransferred labor records from the Astea database, validates
' the data in the Viewpoint database, and produces an output file that can be imported into 
' Viewpoint as timesheets.  After a successful transfer, the source labor records are stamped.
' The transfer can be run in Test mode with the -t command line argument. This runs the records
' through the validations without creating the output file or stamping the source records.
'
'  2014-10-08  Curt S.  Created
'  2014-11-23  Curt S.  98797 skip geo "503" on overhead calls
'  2014-11-10  Curt S.  improve error handling on missing phases; email log to admin; 
'                       add rejects and exceptions to log;
'                       dont send rejects and exceptions to database when running in test mode
'  2014-11-01  Curt S.  Viewpoint go-live version
'  2014-12-01  Curt S.  98473/98474 - convert 2320 phase to 2300, add node to batch filename, clean up log messages
'  2014-12-20  Curt S.  pay seq param not required (set based on node);
'                       separate log paths for test mode;
'                       exclude cross-company exceptions from the output file - these labor recs get hand-keyed elsewhere
'  2015-07-11  Curt S.  98619 make user-friendly
'  2015-11-11  Curt S.  98999 allow job labor for companies other than company 01
'  2016-02-01  Curt S.  98619 convert from console app to Windows form app
'  2016-02-15  Curt S.  99176 validate Work Order, Scope, Job, Job Phase, and Cost Type on Viewpoint side
'  2016-04-18  Curt S.  99373 correct validation problem with co20 work order labor
'  2017-07-07  Curt S.  100819 add Spokane Fire - node 251, payseq 7
' ================================================================================================

Module Module1

    'Dim args() As String                                ' command-line arguments 98619 no longer used
    Dim aTest As String
    Dim aPaySeq As String
    Dim aActgr As String
    Dim aNode As String
    Dim aStart As Date
    Dim aEnd As Date
    Dim endSearch As Date
    Dim aVerbose As String
    Dim aFile As String
    Dim connAst As New SqlConnection                    ' connection to Astea db
    Dim connVP As New SqlConnection                     ' connection to Viewpoint db
    Dim isProduction As Boolean                         ' emails restricted in Training environment
    Dim adminAddress1, adminAddress2 As MailAddress     ' administrator notification addresses
    Dim smtp As New SmtpClient("mail.mckinstry.com")    ' mail client class
    Dim shutDownMsg As String = String.Empty            ' why did we shut down?
    Dim fromAddress As MailAddress                      ' send notifications from this address
    Dim delimiter As String = "|"                       ' output file delimiter
    Dim sqlFileAst As String                            ' text file filename, Astea script
    Dim sqlFileVP As String                             ' text file filename, VP script
    Dim lb As New StringBuilder()                       ' holds log text until it is dumped at the end
    Dim rej As New StringBuilder()                      ' string of rejected records, included in log
    Dim exc As New StringBuilder()                      ' string of exceptions, included in log
    Dim exceptionSql As New StringBuilder()             ' SQL to insert records to mck_transferexceptions
    Dim logFilePath As String                           ' log file path
    Dim filePath As String                              ' output file path (overridden by -f parameter)
    Dim testFilePath As String                          ' output file path in test mode (overridden by -f parameter)
    Dim mailToCollection As MailAddressCollection
    Dim mainForm As New mainForm                        ' 98619 convert application to windows form

    Function RefreshAppSettings() As Boolean
        Dim success As Boolean = False
        Try
            adminAddress1 = New MailAddress(My.Settings.adminAddress1)
            adminAddress2 = New MailAddress(My.Settings.adminAddress2)
            isProduction = My.Settings.isProduction
            fromAddress = New MailAddress(My.Settings.fromAddress)
            sqlFileAst = My.Settings.sqlFileNameAst
            sqlFileVP = My.Settings.sqlFileNameVP
            logFilePath = My.Settings.logFilePath
            filePath = My.Settings.filePath
            testFilePath = My.Settings.testFilePath
            success = True

        Catch ex As Exception
            ' do nothing
        End Try
        Return success
    End Function

    Function WriteToEventLog(entryType As EventLogEntryType, eventText As String) As Boolean
        Dim appName As String = "Astea Payroll Transfer"
        Dim logName As String = "Application"
        Dim objEventLog As New EventLog

        Try
            'Register the Application as an Event Source
            If Not EventLog.SourceExists(appName) Then
                EventLog.CreateEventSource(appName, logName)
            End If

            'log the entry
            objEventLog.Source = appName
            objEventLog.WriteEntry(eventText, entryType)

            Return True

        Catch Ex As Exception
            Return False
        End Try

    End Function

    Function SendMail(mailTo As MailAddressCollection, mailFrom As MailAddress, mailCC As MailAddressCollection, mailSubject As String, mailBody As String, ByRef mailError As String) As Boolean
        Dim success As Boolean = False
        mailError = String.Empty

        ' validate recipient and sender addresses
        If mailTo.Count = 0 Then
            mailError = "Could not send mail, missing 'to' address"
        ElseIf String.IsNullOrEmpty(mailFrom.ToString) Then
            mailError = "Could not send mail, missing 'from' address"
        Else
            Try
                ' create the mail message
                Dim mail As New MailMessage()

                ' populate the sender's address
                mail.From = mailFrom

                ' populate the recipient(s) address
                If isProduction Then
                    For Each address As MailAddress In mailTo
                        mail.To.Add(address)
                    Next
                    If Not mailCC.Count = 0 Then
                        For Each address As MailAddress In mailCC
                            mail.CC.Add(address)
                        Next
                    End If
                Else
                    mail.To.Add(adminAddress1)
                    mail.CC.Add(adminAddress2)
                End If

                'set the content
                mail.Subject = mailSubject
                mail.Body = mailBody

                'send the message

                smtp.Send(mail)
                success = True
            Catch ex As Exception
                mailError = "Failed to send mail:" & vbCrLf & ex.Message
            End Try
        End If
        Return success
    End Function

    Function ValidateArguments() As String
        ' return empty string if arguments are ok
        Dim retMsg As String = String.Empty
        'Dim argCount As Integer    98619 - not used
        Dim payStart, payEnd As String

        ' set default values
        payStart = String.Empty
        payEnd = String.Empty

        ' begin 98619 
        ' get end date from form, use it to calculate start date
        ' subtract 6 days to get last week's Monday -- this is the start of the pay period
        aStart = aEnd.AddDays(-6)

        ' convert to string representation
        payStart = aStart.ToString()
        payEnd = aEnd.ToString()
        ' end 98619

        ' 98619 - comment out
        'aTest = String.Empty
        'aNode = String.Empty
        'aActgr = String.Empty
        'aVerbose = String.Empty
        'aPaySeq = String.Empty
        'aFile = String.Empty

        ' loop through argument array
        'argCount = 0

        ' Note: If there are args(0), args(1), and args(2), the UBound is 2
        ' arg(0) is always the path and filename of the program
        'Do While argCount < UBound(args) + 1
        '    Select Case args(argCount).ToLower
        '        Case "/?"
        '            retMsg = "help"
        '            Exit Do

        '        Case "-t"
        '            aTest = "Y"

        '        Case "-v"
        '            aVerbose = "Y"

        '        Case "-p"  ' pay sequence
        '            If argCount < UBound(args) Then
        '                aPaySeq = args(argCount + 1)  ' next argument contains value
        '                argCount += 1   ' skip next argument
        '            End If

        '        Case "-a"
        '            If argCount < UBound(args) Then
        '                aActgr = args(argCount + 1)  ' next argument contains value
        '                argCount += 1   ' skip next argument
        '            End If

        '        Case "-n"
        '            If argCount < UBound(args) Then
        '                aNode = args(argCount + 1)  ' next argument contains value
        '                argCount += 1   ' skip next argument
        '            End If

        '        Case "-s"
        '            If argCount < UBound(args) Then
        '                payStart = args(argCount + 1)  ' next argument contains value
        '                argCount += 1   ' skip next argument
        '            End If

        '        Case "-e"
        '            If argCount < UBound(args) Then
        '                payEnd = args(argCount + 1)  ' next argument contains value
        '                argCount += 1   ' skip next argument
        '            End If

        '        Case "-f"
        '            If argCount < UBound(args) Then
        '                aFile = args(argCount + 1)  ' next argument contains value
        '                argCount += 1   ' skip next argument
        '            End If

        '    End Select
        '    argCount += 1   ' next argument
        'Loop


        ' There are two different date ranges: 
        ' (1) The pay pay period, which is Monday (inclusive) to Sunday (inclusive)
        ' (2) The search period, which is Monday (inclusive) to Monday (not inclusive)
        ' Start date is the same for both and is generally clear.

        ' First, determine the PAY PERIOD (payStart to payEnd)

        If String.IsNullOrEmpty(payStart) And String.IsNullOrEmpty(payEnd) Then

            ' No dates specified -- use default date range

            ' Typically we run the transfer on Monday or Tuesday for the previous week's labor.
            ' To get the dates from last week, first get the date of the most recent Monday. 
            ' (Probably today, or yesterday.) That is the end date, not inclusive.  

            ' get most recent monday 
            Dim today As Date = Date.Today
            Dim dayDiff As Integer = today.DayOfWeek - DayOfWeek.Monday  ' .NET day of the week, Sun=0, Mon=1, Sat=6
            dayDiff = IIf(dayDiff < 0, dayDiff + 7, dayDiff)    ' if today is Sunday, add a week to the diff (i.e., go 1 week earlier)
            aEnd = today.AddDays(-dayDiff)  ' subract the dayDiff to get the most recent Monday

            ' subtract 1 day to get to end of pay period (Sunday)
            aEnd = aEnd.AddDays(-1)

            ' subtract 6 days to get last week's Monday -- this is the start of the pay period
            aStart = aEnd.AddDays(-6)

            ' convert to string representation
            payStart = aStart.ToString()
            payEnd = aEnd.ToString()

        Else
            ' validate pay period specified by the user

            If String.IsNullOrEmpty(payStart) Then
                retMsg = "End date " & payEnd & " provided but start date missing"
                GoTo quitValidation
            End If
            If Not Date.TryParse(payStart, aStart) Then
                retMsg = "Invalid start date " & payStart
                GoTo quitValidation
            End If

            If String.IsNullOrEmpty(payEnd) Then
                retMsg = "Start date " & payStart & " provided but end date missing"
                GoTo quitValidation
            End If
            If Not Date.TryParse(payEnd, aEnd) Then
                retMsg = "Invalid end date " & payEnd
                GoTo quitValidation
            End If
        End If

        ' make sure end date is not prior to start date
        If aEnd < aStart Then
            retMsg = "End date " & payEnd & " cannot be earlier than start date " & payStart & "."
            GoTo quitValidation
        End If

        ' make sure date range is 7 days
        If aEnd.Subtract(aStart).TotalDays <> 6 Then
            retMsg = "Pay period must be seven days."
            GoTo quitValidation
        End If

        ' start should be a Monday, end should be a Sunday
        If aStart.DayOfWeek <> DayOfWeek.Monday Then
            retMsg = "Start date " & payStart & " must be a Monday"
            GoTo quitValidation
        End If
        If aEnd.DayOfWeek <> DayOfWeek.Sunday Then
            retMsg = "End date " & payEnd & " must be a Sunday"
            GoTo quitValidation
        End If

        ' Now that we have established the PAY PERIOD, add 1 to the pay period end date 
        ' to determine the non-inclusive end of the SEARCH PERIOD

        endSearch = aEnd.AddDays(1)

        ' additional validations

        ' node is mandatory
        If String.IsNullOrEmpty(aNode) Then
            retMsg = "Node -n parameter required"
            GoTo quitValidation
        End If

        ' get pay sequence from node
        If String.IsNullOrEmpty(aPaySeq) Then
            If aNode = "711" Then
                aPaySeq = 10
            ElseIf (aNode = "251" Or aNode = "907") Then
                aPaySeq = 7
            Else
                aPaySeq = 1
            End If
        End If

        ' PaySeq must be a tinyint (integer between 0-255)
        If Not IsNumeric(aPaySeq) Then
            retMsg = "Pay Sequence -p must be an integer between 0 and 255 inclusive"
            GoTo quitValidation
        Else
            Dim iPaySeq As Integer = Convert.ToInt32(aPaySeq)
            If iPaySeq < 0 Or iPaySeq > 255 Then
                retMsg = "Pay Sequence -p must be an integer between 0 and 255 inclusive"
            End If
        End If

quitValidation:

        Return retMsg
    End Function

    Sub AddStatus(ByRef msg)
        ' add a line to the status list box
        If Not String.IsNullOrEmpty(msg) Then
            mainForm.txt_status.AppendText(msg + vbCrLf)
        End If
    End Sub

    Sub Main()
        ' 98619 open the main form to get user input
        Application.Run(mainForm)
    End Sub

    Public Sub click_cancel()
        ' 98619 handle cancel button click
        Application.Exit()
    End Sub

    Public Sub click_ok()

        ' begin 98619
        ' pull user values from the main form
        aNode = mainForm.cb_node.SelectedValue
        aVerbose = "Y"  ' always verbose!
        aTest = If(mainForm.cbx_testmode.Checked, "Y", "N")
        aPaySeq = mainForm.txt_payseq.Text
        aActgr = mainForm.txt_actgr.Text
        aEnd = mainForm.dt_end.Value
        aFile = mainForm.txt_file.Text

        ' do basic validations
        If String.IsNullOrEmpty(aNode) Then
            MessageBox.Show("Please select a node")
            GoTo EndNoLog
        End If

        If aEnd.DayOfWeek <> DayOfWeek.Sunday Then
            MessageBox.Show("End date must be a Sunday")
            GoTo EndNoLog
        End If
        ' end 98619

        ' 98619 no longer using command line arguments
        'args = System.Environment.GetCommandLineArgs()

        mainForm.b_ok.Enabled = False ' 98619 gray out the Ok button while we process

        ' 98619 because we will make the Ok button available again after we run a transfer, clear out logs
        lb.Clear()
        rej.Clear()
        exc.Clear()
        exceptionSql.Clear()
        ' end 98619 

        Dim success As Boolean
        Dim connStringAst As String
        Dim connStringVP As String
        Dim mailError As String = String.Empty
        Dim retMsg As String = String.Empty
        Dim history As String = String.Empty
        Dim milliseconds As Integer = Convert.ToInt32(Date.Now.TimeOfDay.TotalMilliseconds)
        Dim errorsFound As Boolean = False      ' if any labor record fails validation, this gets set to True
        Dim countOutput As Integer = 0          ' count of successful records
        Dim countReject As Integer = 0          ' count of rejected records (these cause a transfer failure)
        Dim countExcept As Integer = 0          ' count of exceptions (these cannot be transferred but do not cause failure)

        ' output strings
        Dim Co, Employee, PREndDate, DayNum, PostingDate, PhaseGroup, SMCo, SMWorkOrder, SMScope, SMPayType, Job, JCCo, RequestedBy As String
        Dim AsteaOrderId, mck_job_phase, isVPJob, actvType, sa_person_id, actualDate, failReason, isOverhead As String
        Dim SMCostType, SMJCCostType, EarnCode, Shift, Hours, udArea, udAsteaDemandId As String
        Dim StripJCCo, StripPhase As String
        Dim Strip As Boolean

        Dim actual_dt As Date

        ' get app.config settings
        success = RefreshAppSettings()
        If Not success Then
            shutDownMsg = "Unable to refresh application settings"
            GoTo ProcessExit
        End If

        ' initial log entry
        lb.Append("Payroll transfer started ").Append(DateTime.Now.ToString()).Append(" user ").Append(Environment.UserName).Append(vbCrLf)

        ' validate arguments and load argument values into variables
        retMsg = ValidateArguments()

        ' handle "help" request
        If retMsg = "help" Then
            ' 98619 no longer using the Help command line argument - comment this section
            '    Console.WriteLine("Transfers Timesheets from Astea to Viewpoint")
            '    Console.WriteLine("-T = test only, no data updates")
            '    Console.WriteLine("-V = verbose")
            '    Console.WriteLine("-P nn = pay sequence (1 or 10)")
            '    Console.WriteLine("-C nn = company (mandatory)")
            '    Console.WriteLine("-A mmm = only this action group")
            '    Console.WriteLine("-N mmm = only this node")
            '    Console.WriteLine("-S yyyy-mm-dd = start date")
            '    Console.WriteLine("-E yyyy-mm-dd = end date")
            '    Console.WriteLine("-F abc = output file path override")
            '    Console.WriteLine("If dates are not supplied, dates of the last work week (Mon-Sun) will be used")
            GoTo ProcessExit
        ElseIf retMsg <> String.Empty Then
            shutDownMsg = retMsg
            GoTo ProcessExit
        End If

        PREndDate = aEnd.ToString("yyyyMMdd")         ' convert to string for output file detail and output file name

        ' build output file name, ex: PR20140831_900_001_12345t
        Dim ob = New StringBuilder()
        ob.Append("PR").Append(PREndDate)
        If Not String.IsNullOrEmpty(aNode) Then ob.Append("_").Append(aNode)
        ob.Append("_").Append(aPaySeq.PadLeft(3, "0")).Append("_").Append(milliseconds.ToString())
        If String.Equals(aTest, "Y") Then ob.Append("t")

        Dim outputFileName As String = ob.ToString()

        ' get keyboard confirmation

        ' 98619 - comment this because we are getting rid of console interface
        'If String.Equals(aTest, "Y") Then Console.WriteLine("(TEST MODE) ")
        'Console.WriteLine("Transfer payroll for node " & aNode & ", week ending " & aEnd.ToString("MMM dd, yyyy") & vbCrLf)
        'Console.WriteLine("Press 'Y' to continue, or any other key to quit")
        'Dim cki As ConsoleKeyInfo
        'cki = Console.ReadKey()
        'If cki.Key.ToString <> "Y" Then GoTo EndNoLog
        'Console.WriteLine(vbCrLf)

        ' add params to log
        lb.Append("Node = ").Append(aNode).Append(", PaySeq = ").Append(aPaySeq).Append(", Start = ").Append(aStart.ToString("yyyy-MM-dd")).Append(", End = ").Append(aEnd.ToString("yyyy-MM-dd")).Append(", Test Mode = ")
        If aTest = "Y" Then lb.Append("Y") Else lb.Append("N")
        lb.Append(vbCrLf)

        If String.Equals(aVerbose, "Y") Then
            AddStatus("Starting Payroll Transfer...") ' 98619 Console.WriteLine(
            If String.Equals(aTest, "Y") Then AddStatus("Test mode, records will not be timestamped") ' 98619 Console.WriteLine(
        End If

        ' MAIN PROCESS

        If String.Equals(aVerbose, "Y") Then AddStatus("Establishing Astea database connection...") ' 98619 Console.WriteLine(

        ' establish an Astea DB connection
        Try
            connStringAst = ConfigurationManager.ConnectionStrings("AsteaDB").ConnectionString
            connAst.ConnectionString = connStringAst
            connAst.Open()
        Catch ex As Exception
            shutDownMsg = "Unable to connect to Astea DB. Exception raised:" & vbCrLf & ex.Message
            GoTo ProcessExit
        End Try

        If String.Equals(aVerbose, "Y") Then AddStatus("Establishing Viewpoint database connection, for validation...") ' 98619 Console.WriteLine(

        ' establish a Viewpoint DB connection

        Try
            connStringVP = ConfigurationManager.ConnectionStrings("ViewpointDB").ConnectionString
            connVP.ConnectionString = connStringVP
            connVP.Open()
        Catch ex As Exception
            shutDownMsg = "Unable to connect to Viewpoint DB. Exception raised:" & vbCrLf & ex.Message
            GoTo ProcessExit
        End Try

        ' query Astea DB to get payroll data
        Try
            ' build SELECT query
            If String.Equals(aVerbose, "Y") Then AddStatus("Building Astea query...") ' 98619 Console.WriteLine(

            ' get base query from file

            Dim sqlAst As String = File.ReadAllText(sqlFileAst)

            ' append WHERE criteria from command-line arguments
            Dim replaceText As String = String.Empty
            If Not String.IsNullOrEmpty(aActgr) Then
                replaceText += " AND P.actgr_id = @actgr "
            End If
            If Not String.IsNullOrEmpty(aNode) Then
                replaceText += " AND emp.node_id = @node "
            End If
            sqlAst = sqlAst.Replace("AND (1=1)", replaceText)

            ' build SQL command
            Dim commandAst As SqlCommand = New SqlCommand(sqlAst, connAst)

            ' populate SELECT params
            commandAst.Parameters.AddWithValue("@dtmStartDate", aStart)    ' first day of pay period
            commandAst.Parameters.AddWithValue("@dtmEndDate", endSearch)   ' end of search period is one day later than end of pay period
            commandAst.Parameters.AddWithValue("@PaySeq", aPaySeq)
            If Not String.IsNullOrEmpty(aActgr) Then commandAst.Parameters.AddWithValue("@actgr", aActgr)
            If Not String.IsNullOrEmpty(aNode) Then commandAst.Parameters.AddWithValue("@node", aNode)

            ' Build Astea data adapter 
            Dim dataAdapterAst As SqlDataAdapter = New SqlDataAdapter
            dataAdapterAst.SelectCommand = commandAst

            If String.Equals(aVerbose, "Y") Then AddStatus("Loading Astea payroll data...") ' 98619 Console.WriteLine(

            ' Fill the Labor table 
            Dim dsAstea As DataSet = New DataSet
            dataAdapterAst.Fill(dsAstea, "Labor")

            If dsAstea.Tables("Labor").Rows.Count > 0 Then

                ' override the output file path with the test output file path
                If String.Equals(aTest, "Y") Then
                    filePath = testFilePath
                End If

                ' override the output file path with -f param
                If Not String.IsNullOrEmpty(aFile) Then
                    filePath = aFile
                End If

                If Right(filePath, 1) <> "\" Then filePath = String.Concat(filePath, "\")

                If String.Equals(aVerbose, "Y") Then AddStatus("Processing labor records...") ' 98619 Console.WriteLine(

                Dim laborLines As New StringBuilder()       ' output file contents
                Dim liveDemands As New StringBuilder()      ' update command for live orders
                Dim histDemands As New StringBuilder()      ' update command for orders in history

                Dim genericUpdate As String = "UPDATE [d] SET mck_extract_status = '10', mck_extract_date = '" & DateTime.Now().ToString("yyyy-MM-dd hh:mm:ss") & _
                        "' WHERE demand_id IN ("

                ' Parse payroll data row-by-row, write each row to stringbuilder for eventual output to file

                For Each rowAst As DataRow In dsAstea.Tables("Labor").Rows

                    Try
                        history = rowAst.Item("history").ToString()         ' is this demand in history? Y/N

                        ' default all output strings to empty so no chance of data copying from prior records
                        Co = String.Empty
                        Employee = String.Empty
                        SMCo = String.Empty
                        SMWorkOrder = String.Empty
                        SMScope = String.Empty
                        PhaseGroup = String.Empty
                        SMCostType = String.Empty
                        SMJCCostType = String.Empty
                        EarnCode = String.Empty
                        Shift = String.Empty
                        Hours = String.Empty
                        DayNum = String.Empty
                        PostingDate = String.Empty
                        udArea = String.Empty
                        udAsteaDemandId = String.Empty
                        AsteaOrderId = String.Empty
                        mck_job_phase = String.Empty
                        isVPJob = String.Empty
                        Job = String.Empty
                        JCCo = String.Empty
                        actvType = String.Empty
                        sa_person_id = String.Empty
                        actualDate = String.Empty
                        failReason = String.Empty
                        StripJCCo = String.Empty
                        StripPhase = String.Empty
                        Strip = False

                        isOverhead = String.Empty

                        ' get data from Astea
                        udAsteaDemandId = rowAst.Item("demand_id").ToString()   ' udAsteaDemandId
                        Co = rowAst.Item("Co").ToString()                       ' Payroll Company (company of the action group)
                        Employee = rowAst.Item("Employee").ToString()           ' Employee Number
                        SMCo = rowAst.Item("SMCo").ToString()  ' SM Company
                        AsteaOrderId = rowAst.Item("order_id").ToString()         ' Astea order ID
                        mck_job_phase = rowAst.Item("mck_job_phase").ToString()   ' Phase
                        isVPJob = rowAst.Item("IsVPJob").ToString()               ' Is Viewpoint Job? Y/N
                        Job = rowAst.Item("mck_string_2").ToString()                            ' Job
                        actvType = rowAst.Item("actv_type_id").ToString()
                        sa_person_id = rowAst.Item("sa_person_id").ToString()
                        Hours = rowAst.Item("Duration").ToString()                ' Hours
                        actual_dt = rowAst.Item("actual_dt")
                        actualDate = actual_dt.ToString()
                        udArea = rowAst.Item("mck_geo_id").ToString()           ' udArea
                        SMWorkOrder = rowAst.Item("refno").ToString()           ' Work Order
                        isOverhead = rowAst.Item("isOverhead").ToString()       ' is overhead (based on CGC job number starting with Z)

                        ' don't use 503 on overhead labor
                        If String.Equals(isOverhead, "Y") And String.Equals(udArea, "503") Then
                            udArea = String.Empty
                        End If

                        If Not IsNumeric(Employee) Then
                            failReason = "Employee ID must be numeric. Astea technician = " & sa_person_id
                            GoTo RejectRecord
                        End If

                        If String.IsNullOrEmpty(SMWorkOrder) Then
                            failReason = "Missing Work Order number"
                            GoTo RejectRecord
                        End If

                        Select Case actvType
                            Case "REGULAR_TIME"
                                EarnCode = "1"
                                Shift = "1"
                            Case "REGULAR_SHIFT"
                                EarnCode = "1"
                                Shift = "2"
                            Case "OTHER" ' Doubletime
                                EarnCode = "3"
                                Shift = "1"
                            Case "OVERTIME"
                                EarnCode = "2"
                                Shift = "1"
                            Case Else
                                failReason = "Invalid activity type: " & actvType.ToString()
                                GoTo RejectRecord
                        End Select

                        ' if this is job labor, it must have a phase
                        If String.Equals(isVPJob, "Y") And String.IsNullOrEmpty(mck_job_phase) Then
                            failReason = "Missing job phase"
                            GoTo RejectRecord
                        End If

                        ' get data from Viewpoint

                        ' get JCCo 
                        If Not String.IsNullOrEmpty(Job) Then

                            Dim sqlVPJob As New StringBuilder()

                            ' 99176 comment
                            'sqlVPJob.Append("SELECT TOP 1 j.JCCo FROM dbo.JCJM j ")
                            'sqlVPJob.Append(" INNER JOIN HQCO h ON j.JCCo = h.HQCo AND h.udTESTCo = 'N'")
                            'sqlVPJob.Append(" WHERE Job = @Job")

                            ' 99176 include Job Status and PhaseGroup in select
                            sqlVPJob.Append("SELECT TOP 1 j.JCCo, j.JobStatus, h.PhaseGroup FROM dbo.JCJM j ")
                            sqlVPJob.Append(" INNER JOIN HQCO h ON j.JCCo = h.HQCo AND h.udTESTCo = 'N'")
                            sqlVPJob.Append(" WHERE Job = @Job")

                            Dim commandVPJob As New SqlCommand(sqlVPJob.ToString(), connVP)
                            commandVPJob.Parameters.AddWithValue("@Job", Job)

                            Dim readerVPJob As SqlDataReader = commandVPJob.ExecuteReader
                            Dim tableVPJob As New DataTable
                            tableVPJob.Load(readerVPJob)

                            ' if data not found, skip this record
                            If tableVPJob.Rows.Count < 1 Then
                                failReason = "Unable to retrieve job " & Job & " from Viewpoint"
                                GoTo RejectRecord
                            End If

                            JCCo = tableVPJob.Rows(0).Item("JCCo").ToString()
                            PhaseGroup = tableVPJob.Rows(0).Item("PhaseGroup").ToString()   ' 99176

                            ' begin 99176 

                            ' check job status to make sure it is active
                            Dim jobStat As Integer = tableVPJob.Rows(0).Item("JobStatus")
                            If Not Integer.Equals(jobStat, 1) Then
                                failReason = "Job " & Job & " is not active"
                                GoTo RejectRecord
                            End If

                            ' check if job phase exists and is active
                            Dim sqlVPPhase As New StringBuilder()
                            sqlVPPhase.Append("SELECT TOP 1 p.ActiveYN FROM dbo.JCJP p ")
                            sqlVPPhase.Append(" WHERE p.Job = @Job AND p.JCCo = @JCCo AND p.Phase = @Phase AND p.PhaseGroup = @PhaseGroup ")

                            Dim commandVPPhase As New SqlCommand(sqlVPPhase.ToString(), connVP)
                            commandVPPhase.Parameters.AddWithValue("@Job", Job)
                            commandVPPhase.Parameters.AddWithValue("@JCCo", JCCo)
                            commandVPPhase.Parameters.AddWithValue("@Phase", mck_job_phase)
                            commandVPPhase.Parameters.AddWithValue("@PhaseGroup", PhaseGroup)

                            Dim readerVPPhase As SqlDataReader = commandVPPhase.ExecuteReader
                            Dim tableVPPhase As New DataTable
                            tableVPPhase.Load(readerVPPhase)

                            ' if phase is not found, skip this record
                            If tableVPPhase.Rows.Count < 1 Then
                                failReason = "Unable to retrieve Phase " & mck_job_phase & " for Job " & Job & " from Viewpoint"
                                GoTo RejectRecord
                            End If

                            ' if phase is not active, skip this record
                            Dim phaseActive As String = tableVPPhase.Rows(0).Item("ActiveYN").ToString()

                            If Not String.Equals(phaseActive, "Y") Then
                                failReason = "Phase " & mck_job_phase & " is not active for Job " & Job
                                GoTo RejectRecord
                            End If

                            ' if check if Labor cost type exists and is active for this phase
                            Dim sqlVPCostType As New StringBuilder()
                            sqlVPCostType.Append("SELECT TOP 1 c.ActiveYN FROM dbo.JCCH c ")
                            sqlVPCostType.Append(" WHERE c.Job = @Job AND c.JCCo = @JCCo AND c.Phase = @Phase AND c.PhaseGroup = @PhaseGroup AND c.CostType = 1 ")

                            Dim commandVPCostType As New SqlCommand(sqlVPCostType.ToString(), connVP)
                            commandVPCostType.Parameters.AddWithValue("@Job", Job)
                            commandVPCostType.Parameters.AddWithValue("@JCCo", JCCo)
                            commandVPCostType.Parameters.AddWithValue("@Phase", mck_job_phase)
                            commandVPCostType.Parameters.AddWithValue("@PhaseGroup", PhaseGroup)

                            Dim readerVPCostType As SqlDataReader = commandVPCostType.ExecuteReader
                            Dim tableVPCostType As New DataTable
                            tableVPCostType.Load(readerVPCostType)

                            ' if Labor cost type is not found, skip this record
                            If tableVPCostType.Rows.Count < 1 Then
                                failReason = "Unable to retrieve Labor cost type for Phase " & mck_job_phase & " for Job " & Job & " from Viewpoint"
                                GoTo RejectRecord
                            End If

                            ' if Labor cost type is not active, skip this record
                            Dim costTypeActive As String = tableVPCostType.Rows(0).Item("ActiveYN").ToString()

                            If Not String.Equals(costTypeActive, "Y") Then
                                failReason = "Labor cost type for Phase " & mck_job_phase & " is not active for Job " & Job
                                GoTo RejectRecord
                            End If

                            ' end 99176

                            ' if the job company is different, strip job info from record
                            ' 98999 commented - later we'll check the Job number on the VP order
                            'If JCCo <> Co Then
                            '    Strip = True
                            '    StripJCCo = JCCo
                            '    StripPhase = mck_job_phase
                            '    Job = String.Empty
                            '    JCCo = String.Empty
                            '    mck_job_phase = String.Empty
                            '    isVPJob = "N"
                            'End If

                        End If  ' If Not String.IsNullOrEmpty(Job)

                        ' check for scope on work order
                        If Not String.IsNullOrEmpty(Job) Then

                            Dim sqlVPWO As New StringBuilder()

                            '98999 - comment -- restructure this so there should always be a rowcount > 0
                            'sqlVPWO.Append("SELECT TOP 1 s.Scope FROM dbo.SMWorkOrderScope s ")
                            'sqlVPWO.Append(" INNER JOIN SMWorkOrder w ON s.WorkOrder = w.WorkOrder AND s.SMCo = w.SMCo ")
                            'sqlVPWO.Append(" WHERE s.SMCo = @SMCo AND s.WorkOrder = @WorkOrder AND s.Phase = @mck_job_phase ")

                            ' 99176 - comment
                            ' 98999 - select from SMWorkOrder, with outer join to SMWorkOrderScope, and pull in Job number
                            'sqlVPWO.Append("SELECT TOP 1 s.Scope, w.Job FROM SMWorkOrder w ")
                            'sqlVPWO.Append(" LEFT OUTER JOIN dbo.SMWorkOrderScope s ON s.WorkOrder = w.WorkOrder AND s.SMCo = w.SMCo AND s.Phase = @mck_job_phase ")
                            'sqlVPWO.Append(" WHERE w.SMCo = @SMCo AND w.WorkOrder = @WorkOrder ")

                            ' 99176 - include order and scope statuses in the SELECT
                            sqlVPWO.Append("SELECT TOP 1 s.Scope, w.Job, w.WOStatus, s.Status FROM SMWorkOrder w ")
                            sqlVPWO.Append(" LEFT OUTER JOIN dbo.SMWorkOrderScope s ON s.WorkOrder = w.WorkOrder AND s.SMCo = w.SMCo AND s.Phase = @mck_job_phase ")
                            sqlVPWO.Append(" WHERE w.SMCo = @SMCo AND w.WorkOrder = @WorkOrder ")

                            Dim commandVPWO As New SqlCommand(sqlVPWO.ToString(), connVP)
                            commandVPWO.Parameters.AddWithValue("@SMCo", SMCo)
                            commandVPWO.Parameters.AddWithValue("@WorkOrder", SMWorkOrder)
                            commandVPWO.Parameters.AddWithValue("@mck_job_phase", mck_job_phase)

                            Dim readerVPWO As SqlDataReader = commandVPWO.ExecuteReader
                            Dim tableVPWO As New DataTable
                            tableVPWO.Load(readerVPWO)

                            ' if work order not found, skip this record
                            If tableVPWO.Rows.Count < 1 Then
                                failReason = "Work Order not found in Viewpoint"    ' 98999 change text of message
                                GoTo RejectRecord
                            End If

                            ' begin 98999 - if the work order in VP doesn't have a job number, strip job info from record
                            If IsDBNull(tableVPWO.Rows(0).Item("Job")) Then
                                Strip = True
                                StripJCCo = JCCo
                                StripPhase = mck_job_phase
                                Job = String.Empty
                                JCCo = String.Empty
                                mck_job_phase = String.Empty
                                isVPJob = "N"
                            Else
                                ' if scope was not found, skip this record
                                If IsDBNull(tableVPWO.Rows(0).Item("Scope")) Then
                                    failReason = "Scope not found"
                                    GoTo RejectRecord
                                End If

                                ' begin 99176 - test WO status and scope status
                                ' 99373 - move these validations inside "ELSE" so they're not called when job is stripped
                                Dim woStat As Integer = tableVPWO.Rows(0).Item("WOStatus")
                                If Not Integer.Equals(woStat, 0) Then
                                    failReason = "Work Order " & SMWorkOrder & " is not open"
                                    GoTo RejectRecord
                                End If

                                Dim scopeStat As Integer = tableVPWO.Rows(0).Item("Status")
                                If Not Integer.Equals(scopeStat, 1) Then
                                    failReason = "Scope " & tableVPWO.Rows(0).Item("Scope").ToString() & " for Work Order " & SMWorkOrder & " is not open"
                                    GoTo RejectRecord
                                End If
                                ' end 99176

                            End If


                        End If ' If Not String.IsNullOrEmpty(Job)

                        ' build VP SQL, add params
                        Dim sqlVP As String = File.ReadAllText(sqlFileVP)
                        Dim commandVP As New SqlCommand(sqlVP, connVP)
                        commandVP.Parameters.AddWithValue("@Co", Co)
                        commandVP.Parameters.AddWithValue("@Employee", Employee)
                        commandVP.Parameters.AddWithValue("@WorkOrder", SMWorkOrder)
                        commandVP.Parameters.AddWithValue("@EarnCode", EarnCode)
                        commandVP.Parameters.AddWithValue("@IsVPJob", isVPJob)
                        commandVP.Parameters.AddWithValue("@Phase", mck_job_phase)
                        commandVP.Parameters.AddWithValue("@SMCo", SMCo)

                        ' get HQ and WO (read-only) into a DataTable -- should only be one line
                        Dim readerVP As SqlDataReader = commandVP.ExecuteReader
                        Dim tableVP As New DataTable
                        tableVP.Load(readerVP)

                        ' if data not found, skip this record
                        If tableVP.Rows.Count < 1 Then
                            failReason = "Unable to retrieve Work Order & Employee data from Viewpoint"
                            GoTo RejectRecord
                        End If

                        ' Work Order fields
                        'SMWorkOrder = tableVP.Rows(0).Item("WorkOrder").ToString()   get SMWorkOrder from the Astea Db
                        SMScope = tableVP.Rows(0).Item("Scope").ToString()
                        SMPayType = tableVP.Rows(0).Item("PayType").ToString()
                        PhaseGroup = tableVP.Rows(0).Item("PhaseGroup").ToString()
                        SMCostType = tableVP.Rows(0).Item("SMCostType").ToString()
                        SMJCCostType = tableVP.Rows(0).Item("JCCostType").ToString()
                        RequestedBy = tableVP.Rows(0).Item("RequestedBy").ToString()

                        ' have we stripped job info from this record, because it's the wrong company?
                        If Strip = True Then
                            ' if so, check for job info in RequestedBy field
                            If RequestedBy.IndexOf("Job") = -1 Then
                                ' log failure and move on
                                failReason = "Cannot post to company " & StripJCCo
                                GoTo RejectRecord
                            Else
                                ' bump record counter
                                countExcept = countExcept + 1

                                ' if RequestedBy contains job info then we log the Job info in mck_payrollexceptions and skip this record
                                If Not String.Equals(aTest, "Y") Then

                                    ' build insert SQL, to be run after all validations are passed
                                    exceptionSql.Append("INSERT INTO dbo.mck_payrollexceptions ( Creation,Batch,Status,AsteaDemandId,")
                                    exceptionSql.Append(" AsteaOrderId,PRCo,Employee,SMCo,WorkOrder,ActivityType,")
                                    exceptionSql.Append(" PersonId,Hours,ActualDate,Area,Exception ) ")
                                    'exceptionSql.Append(" VALUES (@cre,@bat,@sta,@dem,@ord,@prc,@emp,@smc,@wor,@typ,@per,@hrs,@dat,@ara,@exc) ")
                                    exceptionSql.Append(" VALUES ( ")
                                    exceptionSql.Append("'" & DateTime.Now().ToString("yyyy-MM-dd hh:mm:ss") & "'").Append(",")     ' @cre
                                    exceptionSql.Append("'" & outputFileName & "'").Append(",")                                     ' @bat
                                    exceptionSql.Append("''").Append(",")                                                             ' @sta
                                    exceptionSql.Append("'" & udAsteaDemandId & "'").Append(",")                                    ' @dem
                                    exceptionSql.Append("'" & AsteaOrderId & "'").Append(",")                                       ' @ord
                                    exceptionSql.Append("'" & Co & "'").Append(",")                                                 ' @prc
                                    exceptionSql.Append("'" & Employee & "'").Append(",")                                           ' @emp
                                    exceptionSql.Append("'" & SMCo & "'").Append(",")                                               ' @smc
                                    exceptionSql.Append("'" & SMWorkOrder & "'").Append(",")                                        ' @wor
                                    exceptionSql.Append("'" & actvType & "'").Append(",")                                           ' @typ
                                    exceptionSql.Append("'" & sa_person_id & "'").Append(",")                                       ' @per
                                    exceptionSql.Append("'" & Hours & "'").Append(",")                                              ' @hrs
                                    exceptionSql.Append("'" & actual_dt & "'").Append(",")                                          ' @dat
                                    exceptionSql.Append("'" & udArea & "'").Append(",")                                             ' @ara
                                    exceptionSql.Append("'" & RequestedBy & " Phase " & StripPhase & "'")                           ' @exc
                                    exceptionSql.Append(" ); ").Append(vbCrLf)
                                    'Dim exceptionCmd As New SqlCommand(exceptionSql.ToString(), connAst)
                                    'exceptionCmd.Parameters.AddWithValue("@cre", DateTime.Now().ToString("yyyy-MM-dd hh:mm:ss"))
                                    'exceptionCmd.Parameters.AddWithValue("@bat", outputFileName)
                                    'exceptionCmd.Parameters.AddWithValue("@sta", "")
                                    'exceptionCmd.Parameters.AddWithValue("@dem", udAsteaDemandId)
                                    'exceptionCmd.Parameters.AddWithValue("@ord", AsteaOrderId)
                                    'exceptionCmd.Parameters.AddWithValue("@prc", Co)
                                    'exceptionCmd.Parameters.AddWithValue("@emp", Employee)
                                    'exceptionCmd.Parameters.AddWithValue("@smc", SMCo)
                                    'exceptionCmd.Parameters.AddWithValue("@wor", SMWorkOrder)
                                    'exceptionCmd.Parameters.AddWithValue("@typ", actvType)
                                    'exceptionCmd.Parameters.AddWithValue("@per", sa_person_id)
                                    'exceptionCmd.Parameters.AddWithValue("@hrs", Hours)
                                    'exceptionCmd.Parameters.AddWithValue("@dat", actual_dt)
                                    'exceptionCmd.Parameters.AddWithValue("@ara", udArea)
                                    'exceptionCmd.Parameters.AddWithValue("@exc", RequestedBy & " Phase " & StripPhase)
                                    'exceptionCmd.ExecuteNonQuery()
                                End If

                                ' build string of exception records for the log
                                If exc.Length = 0 Then
                                    ' headers
                                    exc.Append("AsteaDemandId,AsteaOrderId,PRCo,Employee,SMCo,WorkOrder,ActivityType,PersonId,Hours,ActualDate,Area,Exception").Append(vbCrLf)
                                End If
                                exc.Append(udAsteaDemandId).Append(",").Append(AsteaOrderId).Append(",").Append(Co).Append(",").Append(Employee).Append(",")
                                exc.Append(SMCo).Append(",").Append(SMWorkOrder).Append(",").Append(actvType).Append(",").Append(sa_person_id).Append(",")
                                exc.Append(Hours).Append(",").Append(actual_dt.ToString("yyyyMMdd")).Append(",").Append(udArea).Append(",")
                                exc.Append(RequestedBy).Append(" Phase ").Append(StripPhase.ToString()).Append(vbCrLf)

                                GoTo SkipRejects
                            End If
                        End If

                        ' Day Number
                        DayNum = CInt(actual_dt.DayOfWeek).ToString()    ' .NET Day Number (day of the week, Sun=0, Mon=1, Sat=6)
                        If DayNum = 0 Then DayNum = 7 ' convert to VP Day Number (Mon=1, Sun=7)

                        PostingDate = Today.ToString("yyyyMMdd")

                        laborLines.Append(Co & delimiter)            ' Payroll Company
                        laborLines.Append(Employee & delimiter)      ' Employee Number
                        laborLines.Append(PREndDate & delimiter)      ' Payroll End Date
                        laborLines.Append(aPaySeq & delimiter)          ' Payment Sequence (designates where checks/paystubs get printed)
                        laborLines.Append(DayNum & delimiter)      ' Day Number
                        laborLines.Append(PostingDate & delimiter)       ' Posting date
                        laborLines.Append(PhaseGroup & delimiter)      ' Phase Group
                        laborLines.Append(mck_job_phase & delimiter)   ' Phase
                        laborLines.Append(SMCo & delimiter)      ' SM Company
                        laborLines.Append(SMWorkOrder & delimiter)      ' SM Work Order
                        laborLines.Append(SMScope & delimiter)      ' SM Scope
                        laborLines.Append(SMPayType & delimiter)    ' SM Pay Type
                        laborLines.Append(SMCostType & delimiter)      ' SM Cost Type
                        laborLines.Append(SMJCCostType & delimiter)      ' SM JC Cost Type
                        laborLines.Append(EarnCode & delimiter)      ' Earnings Code
                        laborLines.Append(Shift & delimiter)      ' Shift
                        laborLines.Append(Hours & delimiter)     ' Hours
                        laborLines.Append(udArea & delimiter)            ' udArea
                        laborLines.Append(udAsteaDemandId & vbCrLf)   ' udAsteaDemandId

                        If history = "Y" Then
                            If histDemands.Length = 0 Then
                                histDemands.Append(Replace(genericUpdate, "[d]", "demand_labor_done"))
                            Else
                                histDemands.Append(",")
                            End If
                            histDemands.Append(udAsteaDemandId)
                        Else
                            If liveDemands.Length = 0 Then
                                liveDemands.Append(Replace(genericUpdate, "[d]", "demand_labor"))
                            Else
                                liveDemands.Append(",")
                            End If
                            liveDemands.Append(udAsteaDemandId)
                        End If

                        ' bump record counter
                        countOutput = countOutput + 1

                        ' can't use dataAdapter to update these fields because there are multiple tables involved
                        'rowAst.Item("mck_extract_status") = "10"
                        'rowAst.Item("mck_extract_date") = DateTime.Now().ToString("yyyy-MM-dd hh:mm:ss")

                        GoTo SkipRejects
RejectRecord:
                        errorsFound = True  ' don't allow db updates, don't create output file

                        ' bump record counter
                        countReject = countReject + 1

                        ' comment this out -- we don't need to save rejects in the db

                        'If Not String.Equals(aTest, "Y") Then
                        '    ' Dump record to the Astea db
                        '    Dim failSql = New StringBuilder()
                        '    failSql.Append("INSERT INTO dbo.mck_payrollrejects ( Creation,Batch,Status,AsteaDemandId,")
                        '    failSql.Append(" AsteaOrderId,PRCo,Employee,SMCo,Phase,Job,JCCo,ActivityType,")
                        '    failSql.Append(" PersonId,Hours,ActualDate,Area,FailureReason ) ")
                        '    failSql.Append(" VALUES (@cre,@bat,@sta,@dem,@ord,@prc,@emp,@smc,@pha,@job,@jcc,@typ,@per,@hrs,@dat,@ara,@fai) ")

                        '    Dim failCmd As New SqlCommand(failSql.ToString(), connAst)
                        '    failCmd.Parameters.AddWithValue("@cre", DateTime.Now().ToString("yyyy-MM-dd hh:mm:ss"))
                        '    failCmd.Parameters.AddWithValue("@bat", outputFileName)
                        '    failCmd.Parameters.AddWithValue("@sta", "")
                        '    failCmd.Parameters.AddWithValue("@dem", udAsteaDemandId)
                        '    failCmd.Parameters.AddWithValue("@ord", AsteaOrderId)
                        '    failCmd.Parameters.AddWithValue("@prc", Co)
                        '    failCmd.Parameters.AddWithValue("@emp", Employee)
                        '    failCmd.Parameters.AddWithValue("@smc", SMCo)
                        '    failCmd.Parameters.AddWithValue("@pha", mck_job_phase)
                        '    failCmd.Parameters.AddWithValue("@job", Job)
                        '    failCmd.Parameters.AddWithValue("@jcc", JCCo)
                        '    failCmd.Parameters.AddWithValue("@typ", actvType)
                        '    failCmd.Parameters.AddWithValue("@per", sa_person_id)
                        '    failCmd.Parameters.AddWithValue("@hrs", Hours)
                        '    failCmd.Parameters.AddWithValue("@dat", actual_dt)
                        '    failCmd.Parameters.AddWithValue("@ara", udArea)
                        '    failCmd.Parameters.AddWithValue("@fai", failReason)
                        '    failCmd.ExecuteNonQuery()
                        'End If

                        ' build string of reject records for the log

                        ' restructure this to make more human-readable
                        'If rej.Length = 0 Then
                        ' headers
                        'rej.Append("AsteaDemandId,AsteaOrderId,PRCo,Employee,SMCo,SMWorkOrder,Phase,Job,JCCo,ActivityType,PersonId,Hours,ActualDate,Area,FailureReason").Append(vbCrLf)
                        'End If
                        'rej.Append(udAsteaDemandId).Append(",").Append(AsteaOrderId).Append(",").Append(Co).Append(",").Append(Employee).Append(",")
                        'rej.Append(SMCo).Append(",").Append(SMWorkOrder).Append(",").Append(mck_job_phase).Append(",").Append(Job).Append(",")
                        'rej.Append(JCCo).Append(",").Append(actvType).Append(",").Append(sa_person_id).Append(",")
                        'rej.Append(Hours).Append(",").Append(actual_dt.ToString("yyyyMMdd")).Append(",").Append(udArea).Append(",")

                        rej.Append("Employee=").Append(sa_person_id).Append(", ")
                        rej.Append("Date=").Append(actual_dt.ToString("yyyyMMdd")).Append(", ")
                        rej.Append(Hours).Append(" hrs").Append(", ")
                        rej.Append("Activity=").Append(actvType).Append(", ")
                        rej.Append("Area=").Append(udArea).Append(vbCrLf)
                        rej.Append("  Work Order=").Append(SMWorkOrder).Append(", ")
                        rej.Append("SMCo=").Append(SMCo).Append(", ")
                        rej.Append("JCCo=").Append(JCCo).Append(", ")
                        rej.Append("Job=").Append(Job).Append(", ")
                        rej.Append("Phase=").Append(mck_job_phase).Append(vbCrLf)
                        rej.Append("  Reason=").Append(failReason).Append(vbCrLf).Append(vbCrLf)

SkipRejects:

                    Catch ex As Exception
                        ' send exceptions to log
                        lb.Append("Labor record rejected due to thrown exception, Demand ID: ").Append(rowAst.Item("demand_id").ToString()).Append(vbCrLf)
                        lb.Append("*** ").Append(ex.Message).Append(vbCrLf)
                        Throw New Exception("Exception Thrown. " & ex.Message)
                    End Try

                Next rowAst

                ' End of loop through labor records. 

                ' If errors found, skip output, don't insert exceptions, and prevent Astea record stamping.
                If errorsFound = True Then
                    AddStatus("Transfer failed. Please correct the following:" & vbCrLf)  ' 98619 Console.Write(
                    AddStatus(rej.ToString)  ' 98619 Console.Write(
                Else
                    ' update the demands in the Astea database with timestamp

                    ' don't update in test mode
                    If String.Equals(aTest, "Y") Then
                        AddStatus("Transfer test is complete -- no errors.")  ' 98619 Console.WriteLine(
                    Else
                        Try
                            ' write labor data to output file and close file
                            Dim objWriter As New System.IO.StreamWriter(filePath & outputFileName & ".txt", True)  ' True = append (should never need to append, but policy is to not overwrite anything)
                            objWriter.WriteLine(laborLines.ToString())
                            objWriter.Close()
                        Catch ex As Exception
                            Throw New Exception("Could not write to output file: " & ex.Message)
                        End Try

                        If String.Equals(aVerbose, "Y") Then AddStatus("Time-stamping labor records in Astea database...") ' 98619 Console.WriteLine(

                        ' update records in history
                        If histDemands.Length > 0 Then
                            Try
                                histDemands.Append(")")
                                lb.Append(vbCrLf).Append("History update: ").Append(vbCrLf).Append(histDemands.ToString()).Append(vbCrLf)
                                Dim histCmd As New SqlCommand(histDemands.ToString(), connAst)
                                histCmd.ExecuteNonQuery()
                            Catch ex As Exception
                                Throw New Exception("History labor records could not be time-stamped: " & ex.Message)
                            End Try
                        End If

                        ' update live records
                        If liveDemands.Length > 0 Then
                            Try
                                liveDemands.Append(")")
                                lb.Append("Live update: ").Append(vbCrLf).Append(liveDemands.ToString()).Append(vbCrLf)
                                Dim liveCmd As New SqlCommand(liveDemands.ToString(), connAst)
                                liveCmd.ExecuteNonQuery()
                            Catch ex As Exception
                                Throw New Exception("Live labor records could not be time-stamped: " & ex.Message)
                            End Try
                        End If

                        ' insert exceptions
                        If exceptionSql.Length > 0 Then
                            If String.Equals(aVerbose, "Y") Then AddStatus("Saving cross-company exceptions in Astea database...") ' 98619 Console.WriteLine(
                            Try
                                Dim exceptionCmd As New SqlCommand(exceptionSql.ToString(), connAst)
                                exceptionCmd.ExecuteNonQuery()
                            Catch ex As Exception
                                Throw New Exception("Cross-company exceptions could not be saved: " & ex.Message)
                            End Try
                        End If

                        'Dim objCommandBuilder As New SqlCommandBuilder(dataAdapterAst)
                        'dataAdapterAst.Update(dsAstea, "Labor")
                    End If

                End If

            Else
                If String.Equals(aVerbose, "Y") Then AddStatus("No records found") ' 98619 Console.WriteLine(
            End If

        Catch ex As Exception
            shutDownMsg = "Payroll Transfer failed: " & ex.Message
            GoTo ProcessExit
        End Try

ProcessExit:
        If String.Equals(aVerbose, "Y") Then AddStatus("Closing database connections...") ' 98619 Console.WriteLine(

        If connAst.State = ConnectionState.Open Then
            connAst.Close()
        End If

        If connVP.State = ConnectionState.Open Then
            connVP.Close()
        End If

        ' notification when system is shut down
        If Not String.IsNullOrEmpty(shutDownMsg) Then

            If String.Equals(aVerbose, "Y") Then AddStatus("Process terminated abnormally: " & shutDownMsg) ' 98619 Console.WriteLine(

            ' log in log file
            lb.Append("Process terminated abnormally: ").Append(shutDownMsg).Append(vbCrLf)

            ' log in event viewer
            WriteToEventLog(EventLogEntryType.Information, "Payroll Transfer terminated abnormally: " & vbCrLf & shutDownMsg)

            ' send notification to administrator (both addresses)
            mailToCollection = New MailAddressCollection
            mailToCollection.Add(adminAddress1)
            mailToCollection.Add(adminAddress2)
            SendMail(mailToCollection, fromAddress, New MailAddressCollection, "Payroll Transfer terminated abnormally", shutDownMsg, mailError)

        End If

        ' log rejects and exceptions
        If rej.Length > 0 Then lb.Append(vbCrLf).Append("Rejected records:").Append(vbCrLf).Append(rej.ToString()).Append(vbCrLf)
        If exc.Length > 0 Then lb.Append(vbCrLf).Append("Exceptions:").Append(vbCrLf).Append(exc.ToString()).Append(vbCrLf)

        ' record counts
        If String.Equals(aVerbose, "Y") Then
            ' 98619 Console.WriteLine(
            AddStatus("Record counts:")
            AddStatus("  Successful... " & countOutput.ToString)
            AddStatus("  Rejected...   " & countReject.ToString)
            AddStatus("  Exceptions... " & countExcept.ToString)
            AddStatus("  Total...      " & (countOutput + countReject + countExcept).ToString)
        End If

        lb.Append("Record counts:").Append(vbCrLf)
        lb.Append("  Successful... " & countOutput.ToString).Append(vbCrLf)
        lb.Append("  Rejected...   " & countReject.ToString).Append(vbCrLf)
        lb.Append("  Exceptions... " & countExcept.ToString).Append(vbCrLf)
        lb.Append("  Total...      " & (countOutput + countReject + countExcept).ToString).Append(vbCrLf).Append(vbCrLf)

        ' log end of process
        lb.Append("Payroll transfer complete ").Append(DateTime.Now.ToString()).Append(vbCrLf)

        ' build log file name
        Dim logb = New StringBuilder()
        If Right(logFilePath, 1) <> "\" Then logFilePath = String.Concat(logFilePath, "\")
        logb.Append(logFilePath).Append("PRLog_")
        If Not String.IsNullOrEmpty("aNode") Then logb.Append(aNode).Append("_")
        logb.Append(Environment.UserName).Append("_").Append(milliseconds.ToString())
        If String.Equals(aTest, "Y") Then logb.Append("t")
        logb.Append(".txt")
        Dim logFileName = logb.ToString()
        Dim logWriter As New System.IO.StreamWriter(logFileName, True)  ' True = append

        ' dump log to file
        If String.Equals(aVerbose, "Y") Then
            AddStatus("Sending log to " & logFileName & "...")  ' 98619 Console.WriteLine(
        End If

        logWriter.Write(lb.ToString())
        logWriter.Close()

        ' email log to admin
        If String.Equals(aVerbose, "Y") Then
            AddStatus("Emailing log to admins...")  ' 98619 Console.WriteLine(
        End If

        mailToCollection = New MailAddressCollection
        mailToCollection.Add(adminAddress1)
        mailToCollection.Add(adminAddress2)
        SendMail(mailToCollection, fromAddress, New MailAddressCollection, "Payroll Transfer Log", lb.ToString(), mailError)

        If String.Equals(aVerbose, "Y") Then
            AddStatus("Payroll transfer process is finished.")  ' 98619 Console.WriteLine(
            'Console.WriteLine("Press any key to quit.")
            'Console.ReadKey()
        End If
EndNoLog:
        mainForm.b_ok.Enabled = True ' 98619 re-enable the Ok button
    End Sub

End Module
