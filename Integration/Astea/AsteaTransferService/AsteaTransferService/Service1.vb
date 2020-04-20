Imports System.Configuration
Imports System.Collections.Specialized
Imports System.Data.SqlClient
Imports System.Net.Mail
Imports System.Threading
Imports System.Text

' ================================================================================================
' Astea Transfer Service
' This Windows service polls the mck_transfer table in the Astea database.  Each record represents
' an entity (Service Order, job phase, invoice) to be transferred from Astea to Viewpoint via the
' MCK_INTEGRATION database.  Each transfer is accomplished by calling the appropriate stored
' procedure.  
' Secondarily, this service looks for failed transfer records in the MCK_INTEGRATION database.
' If an "F" (Failed) record is found, a notification is sent via email and then the record is
' stamped with "R" (Reported) so it won't be reported again.
'
'  2014-10-08  Curt S.      Created
'  2015-06-12  Curt S.      commented out "heartbeat" event log entry
'  2016-04-13  Curt S.      99368 - add a setting for record maturity
' ================================================================================================

Public Class AsteaTransferService

    Private _shutdown As Boolean = False                    ' inter-thread communication
    Private _isProduction As Boolean                        ' email limited in Training environment
    Private _adminAddress1, _adminAddress2 As MailAddress   ' administrator notification addresses
    Private _fromAddress As MailAddress                     ' send notifications from this address
    Private _logFilePath As String                          ' log file full path
    Private _restMilliseconds As Integer                    ' pause between retrieves
    Private _smtp As New SmtpClient("mail.mckinstry.com")   ' mail client class
    Private _recordMaturitySeconds As Integer               ' wait till record is this many seconds old

    ' Keep track of worker thread.
    Private _oPollingThread As New Thread(New System.Threading.ThreadStart(AddressOf PollProcess))

    Protected Function RefreshAppSettings() As Boolean
        Dim success As Boolean = False
        Try
            _adminAddress1 = New MailAddress(My.Settings.adminAddress1)
            _adminAddress2 = New MailAddress(My.Settings.adminAddress2)
            _isProduction = My.Settings.isProduction
            _fromAddress = New MailAddress(My.Settings.fromAddress)
            _logFilePath = My.Settings.logFilePath
            _restMilliseconds = My.Settings.restMilliseconds
            _recordMaturitySeconds = My.Settings.recordMaturitySeconds
            success = True
        Catch ex As Exception
            ' do nothing
        End Try
        Return success
    End Function

    Protected Overrides Sub OnStart(ByVal args() As String)

        EventLog1.WriteEntry("Astea Transfer Service is starting.", EventLogEntryType.Information, 10)

        ' Start the thread.

        _oPollingThread.Start()
    End Sub

    Protected Overrides Sub OnStop()

        EventLog1.WriteEntry("Astea Transfer Service is stopping.", EventLogEntryType.Information, 20)

        ' Stop the thread.  

        _oPollingThread.Abort()
    End Sub

    Private Sub PollProcess()
        ' Loops, until killed by OnStop.

        EventLog1.WriteEntry("Astea Transfer Service polling thread started.", EventLogEntryType.Information, 30)

        Do While Not _shutdown
            ' Wait...
            Try
                System.Threading.Thread.Sleep(_restMilliseconds)

                If Not _shutdown Then
                    ' run that thing!
                    PollingPass()
                    'EventLog1.WriteEntry("Astea Transfer Service polling pass executed.", EventLogEntryType.Information, 100)
                End If
            Catch ex As Exception
                EventLog1.WriteEntry("Polling thread experienced a fatal error: " & vbCrLf & ex.Message, EventLogEntryType.Error)
                ' instead of stopping the service, let it rest for a half-minute and then start again
                System.Threading.Thread.Sleep(30000)
                _shutdown = False
            End Try

        Loop

        Stop    ' kill the process

    End Sub

    Private Sub PollingPass()
        Try
            ' establish an Astea DB connection
            Dim connAst As New SqlConnection                    ' connection to Astea db
            Dim connStringAst As String
            Dim connInt As New SqlConnection                    ' connection to Integration db
            Dim connStringInt As String
            Dim cmdBuilder As SqlCommandBuilder
            Dim dataAdapterAst As SqlDataAdapter
            Dim dataAdapterInt As SqlDataAdapter

            If Not RefreshAppSettings() Then
                Throw New System.Exception("Unable to refresh application settings")
            End If

            Try
                connStringAst = ConfigurationManager.ConnectionStrings("AsteaDB").ConnectionString
                connAst.ConnectionString = connStringAst
                connAst.Open()
            Catch ex As Exception
                Throw New System.Exception("Unable to connect to Astea database." & vbCrLf & ex.Message)
            End Try

            'temp
            'Dim xmailToCollection As New MailAddressCollection
            'xmailToCollection.Add(_adminAddress1)
            'xmailToCollection.Add(_adminAddress2)
            'SendMail(xmailToCollection, _fromAddress, New MailAddressCollection, "Test email subject", "test body")

            ' retrieve all unprocessed transfer records
            dataAdapterAst = New SqlDataAdapter("SELECT id, creation, entity, entity_id, source, " +
                " transfer_status, retry_count, last_attempt, error_message, error_procedure, " +
                " error_line FROM mck_transfer where transfer_status is null AND " +
                " DATEDIFF(SECOND, creation, GETDATE()) > " & _recordMaturitySeconds.ToString(), connAst) ' 98689 give all entities 5 minutes, not just invoices
            '" (entity <> 'invoice' OR (entity = 'invoice' AND DATEDIFF(MINUTE, creation, GETDATE()) > 5 )) ", connAst) ' give invoices 5 minutes

            'Initialize the SqlCommandBuilder object to automatically generate and initialize
            'the UpdateCommand, InsertCommand and DeleteCommand properties of the SqlDataAdapter.
            cmdBuilder = New SqlCommandBuilder(dataAdapterAst)

            ' fill the transfer table 
            Dim dsAstea As DataSet = New DataSet
            dataAdapterAst.Fill(dsAstea, "transfer")
            Dim dt As DataTable = dsAstea.Tables("transfer")

            ' use a dataview so we can filter and sort
            Dim dv As New DataView(dt)

            Dim quit As Boolean = False
            Dim row As DataRowView

            ' apply filter to limit rows to only control records
            dv.RowFilter = "id < 0"

            ' loop through control records
            For Each row In dv

                ' control records could potentially be used for other things,
                ' like force a refresh of the application settings,
                ' but for now, the existence of an unprocessed control record
                ' means we should shut down

                ' stamp it so it isn't processed again
                row.Item("transfer_status") = "Y"
                row.Item("last_attempt") = DateTime.Now()

                Try
                    ' commit changes to the database
                    dataAdapterAst.Update(dsAstea, "transfer")
                Catch ex As Exception
                    ' non-fatal exception (we're shutting down anyway)
                    EventLog1.WriteEntry("Failed to commit control record changes '" & _
                    ex.Message & "'", EventLogEntryType.Error)

                    ' send notification to administrator (both addresses)
                    Try
                        Dim mailToCollection As New MailAddressCollection
                        mailToCollection.Add(_adminAddress1)
                        mailToCollection.Add(_adminAddress2)
                        SendMail(mailToCollection, _fromAddress, New MailAddressCollection, "Astea Transfer control record failed", ex.Message)
                    Catch ex1 As Exception
                        EventLog1.WriteEntry("Error encountered when sending mail '" & _
                        ex1.Message & "'", EventLogEntryType.Error)
                    End Try
                End Try

                quit = True ' shut down
            Next row

            If Not quit Then
                Dim sprocSQL As String
                Dim sprocCMD As SqlCommand
                Dim id As String                ' used for logging and notification
                Dim entity_id As String
                Dim source As String

                ' load up array with list of entities to process
                Dim entity As String
                Dim entityArray() As String = {"invoice", "service_order", "job_phase"}

                ' loop through entities

                For Each entity In entityArray

                    ' limit to only the current entity
                    dv.RowFilter = "id >= 0 AND entity = '" & entity & "'"
                    dv.Sort = "id ASC"  ' first in, first out

                    ' loop through transfer records, process and stamp each
                    For Each row In dv

                        Try
                            ' validate critical columns
                            If IsDBNull(row.Item("id")) Then
                                Throw New System.Exception("Transfer record missing ID")
                            Else
                                id = row.Item("id").ToString()
                            End If

                            If IsDBNull(row.Item("entity_id")) Then
                                Throw New System.Exception("Transfer record missing entity, ID=" & id)
                            Else
                                entity_id = row.Item("entity_id").ToString()
                            End If

                            ' build stored procedure call based on current entity
                            sprocSQL = String.Empty
                            Select Case entity

                                Case "invoice"
                                    sprocSQL = "exec dbo.up_McK_TransferInvoice @UNIQUEID='" & _
                                        entity_id & "'"

                                Case "service_order"

                                    sprocSQL = "exec up_McK_TransferServiceOrder @UNIQUEID='" & _
                                        entity_id & "', @TRANSTYPE='I'"

                                Case "job_phase"
                                    If IsDBNull(row.Item("source")) Then
                                        Throw New System.Exception("Transfer record missing source, ID=" & id)
                                    Else
                                        source = Trim(row.Item("source")) ' trim added to compensate for padding issue
                                        Dim sourceAsInt As Integer
                                        If Not Integer.TryParse(source, sourceAsInt) Then
                                            Throw New System.Exception("Work order not an integer, ID=" & id)
                                        End If
                                    End If
                                    sprocSQL = "exec up_McK_TransferScope @UNIQUEID=0, " & _
                                        "@JOBPHASE='" & entity_id & "', @WORKORDER=" & source

                                Case Else
                                    Throw New System.Exception("Invalid entity value " & entity & ", ID=" & id)
                            End Select

                            ' execute the stored procedure to transfer the record
                            Try
                                EventLog1.WriteEntry("Going to transfer:'" & vbCrLf & sprocSQL, EventLogEntryType.Information, 1000)
                                sprocCMD = New SqlCommand(sprocSQL, connAst)
                                sprocCMD.ExecuteNonQuery()
                                EventLog1.WriteEntry("Transfer success:'" & vbCrLf & sprocSQL, EventLogEntryType.Information, 2000)
                                row.Item("transfer_status") = "Y"
                            Catch ex As Exception
                                ' handle a failure in the stored procedure
                                Throw New System.Exception("Execution of the Astea stored procedure for mck_transfer record id " & id & " failed: " & vbCrLf & vbCrLf & ex.Message & vbCrLf & "Statement: " & sprocSQL & vbCrLf)
                            End Try

                        Catch ex As Exception
                            ' non-fatal exception
                            EventLog1.WriteEntry("Transfer record failed '" & _
                            ex.Message & "'", EventLogEntryType.Error)

                            ' send notification to administrator (both addresses)
                            Try
                                Dim mailToCollection As New MailAddressCollection
                                mailToCollection.Add(_adminAddress1)
                                mailToCollection.Add(_adminAddress2)
                                Dim body As String = ex.Message ' + vbCrLf & "Production? " & _isProduction & vbCrLf & vbCrLf & "This is an automated email sent by the Astea Transfer Service, running on " + My.Computer.Name
                                SendMail(mailToCollection, _fromAddress, New MailAddressCollection, "Astea transfer record failed", body)
                            Catch ex1 As Exception
                                EventLog1.WriteEntry("Error encountered when sending mail '" & _
                                ex1.Message & "'", EventLogEntryType.Error)
                            End Try

                            row.Item("transfer_status") = "F"
                            row.Item("error_message") = ex.Message
                            row.Item("error_procedure") = ex.Source
                        End Try

                        Try
                            ' commit changes to the database
                            row.Item("last_attempt") = DateTime.Now()
                            dataAdapterAst.Update(dsAstea, "transfer")
                        Catch ex As Exception
                            ' fatal exception
                            Throw ex
                        End Try

                    Next row
                Next entity

            End If  ' if not quit

            ' close the db connection
            If connAst.State = ConnectionState.Open Then
                connAst.Close()
            End If

            If quit Then
                EventLog1.WriteEntry("Astea Transfer Service shut down by control record", EventLogEntryType.Information, 40)
                ' send notification to administrator (both addresses)
                Try
                    Dim mailToCollection As New MailAddressCollection
                    mailToCollection.Add(_adminAddress1)
                    mailToCollection.Add(_adminAddress2)
                    SendMail(mailToCollection, _fromAddress, New MailAddressCollection, "Astea Transfer Service shutting down", "Shutdown forced by control record")
                Catch ex1 As Exception
                    EventLog1.WriteEntry("Error encountered when sending mail '" & _
                    ex1.Message & "'", EventLogEntryType.Error)
                End Try

                ' kill the service
                _shutdown = True

            Else

                ' look for "Failure" records in the integration database

                Try
                    connStringInt = ConfigurationManager.ConnectionStrings("IntegrationDB").ConnectionString
                    connInt.ConnectionString = connStringInt
                    connInt.Open()
                Catch ex As Exception
                    Throw New System.Exception("Unable to connect to Integration database." & vbCrLf & ex.Message)
                End Try

                ' retrieve all unprocessed transfer records
                ' load up array with list of entities to process
                Dim script As String
                Dim scriptArray() As String = { _
                 " SELECT 'Invoice' Type, RowId, AsteaInvoiceId AsteaId, DateCreated, ProcessStatus, ProcessTimeStamp, ProcessDesc FROM Invoice WHERE ProcessStatus = 'F' ", _
                 " SELECT 'WorkOrder' Type, RowId, CAST(WorkOrder AS VARCHAR(20)) AsteaId, DateCreated, ProcessStatus, ProcessTimeStamp, ProcessDesc FROM dbo.WorkOrder WHERE ProcessStatus = 'F' ", _
                 " SELECT 'Customer' Type, RowId, CustomerId AsteaId, DateCreated, ProcessStatus, ProcessTimeStamp, ProcessDesc FROM dbo.Customer WHERE ProcessStatus = 'F' ", _
                 " SELECT 'Site' TYPE, RowId, SiteId AsteaId, DateCreated, ProcessStatus, ProcessTimeStamp, ProcessDesc FROM dbo.Site WHERE ProcessStatus = 'F' "}

                ' loop through scripts

                For Each script In scriptArray

                    dataAdapterInt = New SqlDataAdapter(script, connInt)

                    'Initialize the SqlCommandBuilder object to automatically generate and initialize
                    'the UpdateCommand, InsertCommand and DeleteCommand properties of the SqlDataAdapter.
                    cmdBuilder = New SqlCommandBuilder(dataAdapterInt)

                    ' fill the transfer table 
                    Dim dsInt As DataSet = New DataSet
                    dataAdapterInt.Fill(dsInt, "transferfailure")
                    Dim dtInt As DataTable = dsInt.Tables("transferfailure")

                    ' any failure records found?
                    If dtInt.Rows.Count > 0 Then

                        ' loop through failure records, build an output message
                        Dim failB As New StringBuilder()

                        ' loop through columns
                        For k As Integer = 0 To dtInt.Columns.Count - 1
                            'add separator
                            failB.Append(dtInt.Columns(k).ColumnName + ","c)
                        Next

                        'append new line
                        failB.Append(vbCr & vbLf)

                        ' loop through rows
                        For i As Integer = 0 To dtInt.Rows.Count - 1
                            For k As Integer = 0 To dtInt.Columns.Count - 1
                                'add separator
                                failB.Append(dtInt.Rows(i)(k).ToString().Replace(",", ";") + ","c)
                            Next
                            'append new line
                            failB.Append(vbCr & vbLf)
                        Next

                        Try
                            Dim mailToCollection As New MailAddressCollection
                            mailToCollection.Add(_adminAddress1)
                            mailToCollection.Add(_adminAddress2)
                            SendMail(mailToCollection, _fromAddress, New MailAddressCollection, "Transfer failure record detected", "Transfer attempt can't continue because it failed a validation." & vbCrLf & vbCrLf & failB.ToString())
                        Catch ex1 As Exception
                            EventLog1.WriteEntry("Error encountered when sending mail '" & _
                            ex1.Message & "'", EventLogEntryType.Error)
                        End Try

                        ' use a dataview so we can filter and sort
                        Dim dvInt As New DataView(dtInt)

                        For Each row In dvInt

                            ' stamp it so it isn't processed again
                            row.Item("ProcessStatus") = "R"

                            Try
                                ' commit changes to the database
                                dataAdapterInt.Update(dsInt, "transferfailure")
                            Catch ex As Exception
                                ' non-fatal exception (we're shutting down anyway)
                                EventLog1.WriteEntry("Failed to commit failure reset changes '" & _
                                ex.Message & "'", EventLogEntryType.Error)

                                ' send notification to administrator (both addresses)
                                Try
                                    Dim mailToCollection As New MailAddressCollection
                                    mailToCollection.Add(_adminAddress1)
                                    mailToCollection.Add(_adminAddress2)
                                    SendMail(mailToCollection, _fromAddress, New MailAddressCollection, "Failed to commit failure reset changes", vbCrLf & ex.Message)
                                Catch ex1 As Exception
                                    EventLog1.WriteEntry("Error encountered when sending mail '" & _
                                    ex1.Message & "'", EventLogEntryType.Error)
                                End Try
                            End Try

                        Next row  ' loop through failure records
                    End If ' any failures found?
                Next ' for each script

                ' close the db connection
                If connInt.State = ConnectionState.Open Then
                    connInt.Close()
                End If

            End If ' if not quit

        Catch ex As System.Exception
            EventLog1.WriteEntry("Astea Transfer Service encountered an error '" & _
            ex.Message & "'", EventLogEntryType.Error)
            EventLog1.WriteEntry("Astea Transfer Service service Stack Trace: " & _
            ex.StackTrace, EventLogEntryType.Error)

            ' send notification to administrator (both addresses)
            Try
                Dim mailToCollection As New MailAddressCollection
                mailToCollection.Add(_adminAddress1)
                mailToCollection.Add(_adminAddress2)
                Dim subject As String = "Astea Transfer Service encountered an error"
                If _isProduction Then subject = subject & " in Production"
                SendMail(mailToCollection, _fromAddress, New MailAddressCollection, subject, ex.Message & vbCrLf & vbCrLf & "The service will sleep for thirty seconds and then resume.")
            Catch ex1 As Exception
                EventLog1.WriteEntry("Error encountered when sending mail '" & _
                ex1.Message & "'", EventLogEntryType.Error)
            End Try

            ' kill the service
            ' ...don't kill the service -- allow service to keep trying, and keep sending notifications
            ' _shutdown = True  
            System.Threading.Thread.Sleep(30000)

        End Try
    End Sub

    Function SendMail(mailTo As MailAddressCollection, mailFrom As MailAddress, mailCC As MailAddressCollection, mailSubject As String, mailBody As String) As Boolean
        Dim success As Boolean = False
        Try
            ' validate recipient and sender addresses
            If mailTo.Count = 0 Then
                Throw New System.Exception("Could not send mail, missing 'to' address")
            ElseIf String.IsNullOrEmpty(mailFrom.ToString) Then
                Throw New System.Exception("Could not send mail, missing 'from' address")
            End If

            ' create the mail message
            Dim mail As New MailMessage()

            ' populate the sender's address
            mail.From = mailFrom

            ' populate the recipient(s) address
            If _isProduction Then
                For Each address As MailAddress In mailTo
                    mail.To.Add(address)
                Next
                If Not mailCC.Count = 0 Then
                    For Each address As MailAddress In mailCC
                        mail.CC.Add(address)
                    Next
                End If
            Else
                mail.To.Add(_adminAddress1)
                mail.CC.Add(_adminAddress2)
            End If

            'set the content
            mail.Subject = mailSubject
            mail.Body = mailBody + vbCrLf & "Production: " & _isProduction.ToString() & vbCrLf & vbCrLf & "This is an automated email sent by the Astea Transfer Service, running on " + My.Computer.Name

            'send the message
            _smtp.Send(mail)
            success = True
        Catch ex As Exception
            Throw ex
        End Try

        Return success
    End Function
End Class
