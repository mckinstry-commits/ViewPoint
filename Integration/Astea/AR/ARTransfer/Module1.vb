Imports System.Configuration
Imports System.Collections.Specialized
Imports System.Data.SqlClient
Imports System.Net.Mail

' 2015-06-08 CS 98620   indicate production/non-production in notifications and logs; 
'                       handle additional batchinfo output arg from stored procedure;
'                       email batchinfo to main & backup recipients

Module Module1

    Dim args() As String                                ' command-line arguments
    Dim aContract As String                              ' argument
    Dim aServiceOrder As String                          ' argument
    Dim aInvoiceId As String                             ' argument
    Dim aNonJob As String                                ' argument
    Dim aJob As String                                   ' argument
    Dim aCompany As Integer                              ' argument
    Dim aPrevMonth As String                             ' argument
    Dim connInt As SqlConnection                        ' connection to Integration db
    Dim isProduction As Boolean                         ' emails restricted in Training environment
    Dim adminAddress1 As MailAddressCollection          ' main notification addresses, comma-delimited
    Dim adminAddress2 As MailAddressCollection          ' backup notification addresses, comma-delimited
    Dim smtp As New SmtpClient("mail.mckinstry.com")    ' mail client class
    Dim shutDownMsg As String = String.Empty            ' why did we shut down?
    Dim fromAddress As MailAddress                      ' send notifications from this address
    Dim productionmsg As String                         ' 98620 indicate production/non-production

    Function RefreshAppSettings() As Boolean
        Dim success As Boolean = False

        Try
            isProduction = My.Settings.isProduction

            ' begin 98620 set up email address collections
            adminAddress1 = New MailAddressCollection
            adminAddress1.Add(My.Settings.adminAddress1)
            adminAddress2 = New MailAddressCollection
            adminAddress2.Add(My.Settings.adminAddress2)
            ' end 98620

            fromAddress = New MailAddress(My.Settings.fromAddress)
            success = True
        Catch ex As Exception
            ' do nothing, allow to return with success = false
        End Try
        Return success
    End Function

    Function WriteToEventLog(entryType As EventLogEntryType, eventText As String) As Boolean
        Dim appName As String = "Astea AR Transfer"
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

                ' 98620 - populate the recipient(s) address
                For Each address As MailAddress In mailTo
                    mail.To.Add(address)
                Next

                If Not mailCC.Count = 0 Then
                    For Each address As MailAddress In mailCC
                        mail.CC.Add(address)
                    Next
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
        Dim argCount As Integer
        Dim docTypeCount As Integer = 0

        ' set default values
        aInvoiceId = String.Empty
        aContract = String.Empty
        aServiceOrder = String.Empty
        aNonJob = String.Empty
        aJob = String.Empty
        aPrevMonth = String.Empty

        ' loop through argument array
        argCount = 0

        ' Note: If there are args(0), args(1), and args(2), the UBound is 2
        ' arg(0) is always the path and filename of the program
        Do While argCount < UBound(args) + 1
            Select Case args(argCount).ToLower
                Case "/?"
                    retMsg = "help"
                    Exit Do
                Case "-c"
                    docTypeCount += 1
                    aContract = "Y"

                Case "-s"
                    docTypeCount += 1
                    aServiceOrder = "Y"

                Case "-i"
                    If argCount < UBound(args) Then
                        aInvoiceId = args(argCount + 1)  ' next argument contains value
                        argCount += 1   ' skip next argument
                    End If

                Case "-j"
                    aJob = "Y"

                Case "-n"
                    aNonJob = "Y"

                Case "-p"
                    aPrevMonth = "Y"

                Case "-co"
                    If argCount < UBound(args) Then
                        Dim sCo As String = args(argCount + 1) ' next argument contains value
                        Dim isInt As Boolean = Int32.TryParse(sCo, aCompany)
                        If Not isInt Then
                            retMsg = "Invalid Company number " & sCo & " (must be integer)"
                            Exit Do
                        End If
                        If aCompany < 0 Or aCompany > 255 Then
                            retMsg = "Invalid Company number " & sCo & " (must be 0-255)"
                        End If
                        argCount += 1   ' skip next argument
                    End If
            End Select
            argCount += 1   ' next argument
        Loop

        ' must be at least one docType switch selected, contract and/or serviceorder
        If retMsg = String.Empty Then
            If docTypeCount < 1 Then
                retMsg = "You must select either -Contract or -ServiceOrder, or both, in the command-line argument"
            End If
        End If

        ' company must be selected and must be integer
        If retMsg = String.Empty Then
            If String.IsNullOrEmpty(aCompany) Or Not IsNumeric(aCompany) Then
                retMsg = "You must specify a Company number"
            End If
        End If

        Return retMsg
    End Function

    Sub Main()
        args = System.Environment.GetCommandLineArgs()

        Dim success As Boolean
        Dim connString As String
        Dim mailError As String = String.Empty
        Dim retMsg As String = String.Empty
        Dim batchinfo As String = String.Empty      ' 98620 returned from stored procedure
        Dim productionmsg As String = String.Empty  ' 98620 add production/non-production indicator to notifications

        ' validate arguments and load argument values into variables
        retMsg = ValidateArguments()

        ' handle "help" request
        If retMsg = "help" Then
            Console.WriteLine("Transfers AR invoices from Astea to Viewpoint")
            Console.WriteLine("-C = include contract invoices")
            Console.WriteLine("-S = include service order invoices")
            Console.WriteLine("-I nnn = transfer only this invoice ID, ignore all other params")
            Console.WriteLine("-J = include only job-related invoices")
            Console.WriteLine("-N = include only non-job-related invoices")
            Console.WriteLine("-P = post to previous month")
            Console.WriteLine("-Co nnn = include invoices for this HQ company only (mandatory, numeric)")
            GoTo ProcessExitNoDb
        ElseIf retMsg <> String.Empty Then
            shutDownMsg = retMsg
            GoTo ProcessExitNoDb
        End If

        ' establish an Integration DB connection
        Try
            connString = ConfigurationManager.ConnectionStrings("IntegrationDB").ConnectionString
            connInt = New SqlConnection(connString)
            connInt.Open()
        Catch ex As Exception
            shutDownMsg = "Unable to connect to Integration DB. Exception raised:" & vbCrLf & ex.Message
            GoTo ProcessExitNoDb
        End Try

        ' get app.config settings
        success = RefreshAppSettings()
        If Not success Then
            shutDownMsg = "Unable to refresh application settings"
            GoTo ProcessExit
        End If

        ' begin 98620 set production/non-production string for use in notification
        If isProduction = True Then
            productionmsg = New String("Production")
        Else
            productionmsg = New String("Non-Production")
        End If
        ' end 98620

        ' MAIN PROCESS

        ' call Integration SPROC to send invoices to batch

        Dim cmd2 As New SqlCommand("dbo.spInsertInvoiceToARBatch", connInt)
        cmd2.CommandType = CommandType.StoredProcedure
        cmd2.Parameters.AddWithValue("@pAsteaInvoiceId", aInvoiceId)
        cmd2.Parameters.AddWithValue("@pContractSwitch", aContract)
        cmd2.Parameters.AddWithValue("@pServiceOrderSwitch", aServiceOrder)
        cmd2.Parameters.AddWithValue("@pJobSwitch", aJob)
        cmd2.Parameters.AddWithValue("@pNonJobSwitch", aNonJob)
        cmd2.Parameters.AddWithValue("@pCompany", aCompany)
        cmd2.Parameters.AddWithValue("@pPrevMonth", aPrevMonth)
        cmd2.Parameters.Add("@errmess", System.Data.SqlDbType.VarChar, 500)
        cmd2.Parameters("@errmess").Direction = ParameterDirection.Output

        ' begin 98620 specify additional output argument
        cmd2.Parameters.Add("@batchinfo", System.Data.SqlDbType.VarChar, 100)
        cmd2.Parameters("@batchinfo").Direction = ParameterDirection.Output
        ' end 98620

        Try
            cmd2.ExecuteNonQuery()
            Dim msg As String = cmd2.Parameters("@errmess").Value
            If Not String.IsNullOrEmpty(msg) Then
                shutDownMsg = msg
                GoTo ProcessExit
            End If

            ' begin 98620 - email the batch info
            batchinfo = cmd2.Parameters("@batchinfo").Value
            If String.IsNullOrEmpty(batchinfo) Then
                SendMail(adminAddress1, fromAddress, adminAddress2, "Astea AR transfer - no batch", "No batch was created." & vbCrLf & "Environment: " & productionmsg, mailError)
            Else
                SendMail(adminAddress1, fromAddress, adminAddress2, "Astea AR transfer " & batchinfo, "Please validate and post AR batch in Viewpoint" & vbCrLf & batchinfo & vbCrLf & "Environment: " & productionmsg, mailError)
            End If
            ' end 98620

        Catch ex As Exception
            shutDownMsg = ex.Message
            GoTo ProcessExit
        End Try

ProcessExit:

        ' notification when system is shut down
        If Not String.IsNullOrEmpty(shutDownMsg) Then

            ' begin 98620 include Production/Non-production indicator in failure notification
            Dim failMsg As String
            failMsg = productionmsg + " AR Transfer failed"
            ' end 98620

            ' log event
            WriteToEventLog(EventLogEntryType.Information, failMsg & vbCrLf & shutDownMsg) ' 98620 include Production/Non-production indicator

            ' 98620 include Production/Non-production indicator
            SendMail(adminAddress1, fromAddress, adminAddress2, failMsg, failMsg & vbCrLf & shutDownMsg, mailError)

        End If

        ' close DB connection
        connInt.Close()

ProcessExitNoDb:

    End Sub

End Module
