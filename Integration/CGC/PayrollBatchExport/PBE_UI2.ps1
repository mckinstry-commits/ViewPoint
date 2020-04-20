<#
2014.06.05 - LWO - 
Down and dirty utility for capturing CGC Payroll Batch Data
from PRPWKD to a SQL Database to be used in posted payroll
in Viewpoint for parallel processing, testing and auditting.
#>

Function LogWrite
{
	Param ([string]$logstring)
	
	$ts = (Get-Date).ToLongTimeString() + "`t" + $logstring
	Add-content $Logfile -value $ts
	Write-Host $logstring
}

#Database Connection Strings
$Database = "MCK_INTEGRATION"
$Server = "MCKTESTSQL04\VIEWPOINT"
#$SqlConnection.ConnectionString = "Data Source=$Server;Initial Catalog=$Database;Integrated Security=True"
$DBConnection = "Data Source=$Server;Initial Catalog=$Database;Integrated Security=False;User Id=PRBE;Password=QV1ZWz82T4qocDP6kviI"

# Local Variables
$script:compname = gc env:computername
$script:homeDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$script:logFile = $script:homeDir + "\Log\PRBE_ExportLog.txt"

#Creating a Mail object
$msg = new-object Net.Mail.MailMessage

# Email Variables
$script:smptServer = "mail.mckinstry.com"
$script:smptPort = 25
$script:emailFrom = "cgc@mckinstry.com"
$script:replyTo = "lindaw@mckinstry.com"
$script:emailToList = "lindaw@mckinstry.com,bethr@mckinstry.com,allisonf@McKinstry.com,t-sandym@McKinstry.com,JouaV@McKinstry.com"
$script:emailCcList = "billo@mckinstry.com,erics@mckinstry.com,theresap@mckinstry.com"
#$script:emailToList = "billo@mckinstry.com"
#$script:emailCcList=$Null
$script:mailSubject = "CGC PayrollBatch Export Processing Executed "
$script:mailBody = $Null

#Creating SMTP server object
$smtp = new-object Net.Mail.SmtpClient
$smtp.Host = $script:smptServer
$smtp.Port = $script:smptPort

#Email structure
$msg.From = $script:emailFrom
$msg.ReplyTo = $script:replyTo

if (($script:emailToList -ne $Null) -and ($script:emailToList -ne ""))
{
	ForEach ($emailTo in $script:emailToList.split(","))
	{
		$msg.To.Add($emailTo)
	}
}

if (($script:emailCcList -ne $Null) -and ($script:emailCcList -ne ""))
{
	ForEach ($emailCc in $script:emailCcList.Split(","))
	{
		$msg.Cc.Add($emailCc)
	}
}

$msg.subject = "CGC PayrollBatch Export [" + $Server + "." + $Database + "]"

$script:mailBody += "<P><B>Export/Upload of CGC PayrollBatch data.</B><BR/>"
$script:mailBody += "<HR/>"

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.Size = New-Object Drawing.Size @(400, 275)
$form.MaximizeBox = $false
$form.MinimizeBox = $False
$form.FormBorderStyle = 'FixedDialog'
$form.StartPosition = "CenterScreen"
$form.Text = "CGC PR Batch Capture"
#region Binary Data
$form.Icon = [System.Convert]::FromBase64String('
AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAQAQAABMLAAATCwAAAAAA
AAAAAABAKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/
QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9A
Kwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0Ar
Cv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK
/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/oJWF/4h7Zv9wYEf/oJWF/1hGKf+glYX/
fG5X/6CVhf/PysL/t6+j/3BgR/+glYX/iHtm/3BgR/+glYX/fG5X///////n5OD/oJWF//////+g
lYX/////////////////5+Tg//Py8P/n5OD//////9vX0f+glYX//////6CVhf/PysL//////6ui
k///////29fR/+fk4P///////////8/Kwv+glYX/z8rC//Py8P//////5+Tg//////9wYEf/oJWF
///////PysL////////////n5OD////////////z8vD/TDgZ/3BgR//b19H/////////////////
TDgZ/3xuV//////////////////n5OD//////////////////////7evo///////////////////
/////////0w4Gf9YRin/////////////////oJWF////////////29fR/+fk4P///////////6ui
k/////////////////+ropP/QCsK/+fk4P///////////0w4Gf///////////9vX0f9AKwr/QCsK
/0ArCv9MOBn//////+fk4P/PysL//////0ArCv+ropP/z8rC/8/Kwv9AKwr/oJWF/8/Kwv/PysL/
QCsK/0ArCv9AKwr/QCsK/8O8sv/PysL/WEYp/8O8sv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9A
Kwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0Ar
Cv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK
/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/
QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9AKwr/QCsK/0ArCv9A
Kwr/AABoYQAAZFwAAG5kAABzIAAAdmUAADpcAABvZwAAbSAAAGxlAAAoeAAAKVwAAG1tAAAgRgAA
ZXMAAGljAABzbw==')
#endregion

$dgBatches = New-Object System.Windows.Forms.DataGridView
$dgBatches.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 365
$System_Drawing_Size.Height = 200
$dgBatches.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 10
$System_Drawing_Point.Y = 10
$dgBatches.Location = $System_Drawing_Point
$dgBatches.DataBindings.DefaultDataSourceUpdateMode = 0
#$dgBatches.HeaderForeColor = [System.Drawing.Color]::FromArgb(255,0,0,0)
$dgBatches.Name = "dgBatches"
$dgBatches.DataMember = ""
$dgBatches.TabIndex = 0
$form.Controls.Add($dgBatches)

$respform = New-Object Windows.Forms.Form
$respform.Size = New-Object Drawing.Size @(400, 325)
$respform.StartPosition = "CenterScreen"
$respform.Text = "CGC PR Batch Capture"

$lblMsg = New-Object System.Windows.Forms.Label
$lblMsgText = '{0} records already captured for {1}-{2}-{3}.  Are you sure you want to re-capture?'
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 300
$System_Drawing_Size.Height = 200
$lblMsg.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 5
$System_Drawing_Point.Y = 21
$lblMsg.Location = $System_Drawing_Point
$respform.Controls.Add($lblMsg)

$btnOK = New-Object System.Windows.Forms.Button
$btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 200
$System_Drawing_Point.Y = 250
$btnOK.Location = $System_Drawing_Point
$btnOK.Text = "Yes"
$respform.Controls.Add($btnOK)

$btnReject = New-Object System.Windows.Forms.Button
$btnReject.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 300
$System_Drawing_Point.Y = 250
$btnReject.Location = $System_Drawing_Point
$btnReject.Text = "No"
$respform.Controls.Add($btnReject)

$btnProcessGrid = New-Object System.Windows.Forms.Button
#$btnProcessGrid.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 105
$System_Drawing_Point.Y = 215
$btnProcessGrid.Location = $System_Drawing_Point
$btnProcessGrid.Text = "Process"
$btnProcessGrid.add_click({ ProcessGrid })
$form.Controls.Add($btnProcessGrid)

$btnCancel = New-Object System.Windows.Forms.Button
#$btnProcessGrid.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 25
$System_Drawing_Point.Y = 215
$btnCancel.Location = $System_Drawing_Point
$btnCancel.Text = "Cancel"
$btnCancel.add_click({ $form.Close() })
$form.Controls.Add($btnCancel)

#TODO Get Selected Values
function ProcessGrid
{
	$rows = $dgBatches.SelectedRows
	Write-Host $dgBatches.SelectedRows.Count
	
	$script:mailBody += "<table border='1' cellpadding='3'><tr>"
	$script:mailBody += "<td>Company</td>"
	$script:mailBody += "<td>Batch</td>"
	$script:mailBody += "<td>Week Ending</td><td></td>"
	$script:mailBody += "</tr>"
	
	foreach ($row in $rows)
	{
		$cells = $row.Cells
		Write-Host $row
		Write-Host $cells[0].Value + "`t" + $cells[1].Value + "`t" + $cells[2].Value
		
		CheckPreviousCapture -inWeekEnding $cells[0].Value -inCompany $cells[1].Value -inBatch $cells[2].Value
	}
	
	$script:mailBody += "</table>"
	$script:mailBody += "<hr/>Run at: {0}" -f (Get-Date)
	
	$msg.body = $script:mailBody
	$msg.IsBodyHTML = $true
	#Sending email
	$smtp.Send($msg)
	#$msg.Dispose();
	
}


function CheckPreviousCapture
{
	Param (
		[string]$inWeekEnding
		, [string]$inCompany
		, [string]$inBatch
	)
	
	try
	{
		$SqlQuery = "exec mspGetCgcPayrollBatch;1 "
		$SqlQuery += "@CompanyNumber=" + $inCompany + ', '
		$SqlQuery += "@BatchNumber=" + $inBatch + ', '
		$SqlQuery += "@WeekEnding=" + $inWeekEnding + ', '
		$SqlQuery += "@DoRefresh=0"
		
		$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$SqlConnection.ConnectionString = $DBConnection
		
		$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
		$SqlCmd.CommandText = $SqlQuery
		$SqlCmd.Connection = $SqlConnection
		$SqlCmd.CommandTimeout = 0
		$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
		$SqlAdapter.SelectCommand = $SqlCmd
		$DataSet = New-Object System.Data.DataSet
		$nRecs = $SqlAdapter.Fill($DataSet)
		$nRecs | Out-Null
		
		if ($nRecs -gt 0)
		{
			$lblMsgText = $lblMsg.Text = $lblMsgText -f $nRecs, $inWeekEnding, $inCompany, $inBatch
			
			if ($respform.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
			{
				DoExportData -inWeekEnding $inWeekEnding -Company $inCompany -Batch $inBatch
			}
			else
			{
				LogWrite("CANCELLED Capture of {0}:{1}:{2}" -f $inWeekEnding, $inCompany, $inBatch)
				$script:mailBody += "<tr>"
				$script:mailBody += "<td>" + $inCompany + "</td>"
				$script:mailBody += "<td>" + $inBatch + "</td>"
				$script:mailBody += "<td>" + $inWeekEnding + "</td>"
				$script:mailBody += "<td>" + "Cancelled" + "</td>"
				$script:mailBody += "</tr>"
			}
		}
		else
		{
			DoExportData -inWeekEnding $inWeekEnding -Company $inCompany -Batch $inBatch
		}
	}
	catch [Exception]
	{
		LogWrite $_.Exception.Message
		LogWrite "Caught an exception:" -ForegroundColor Red
		LogWrite "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
		LogWrite "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
	}
	finally
	{
		$SqlConnection.Close()
	}
}

function GetAvailableBatches
{
	try
	{
		$SqlQuery = "SELECT DISTINCT GPDTWE as WeekEnding, GPCONO as Company, GPBT05 as Batch FROM CMS.S1017192.CMSFIL.PRPWKD ORDER BY GPDTWE, GPCONO, GPBT05"
		#$SqlQuery = "SELECT DISTINCT GPDTWE as WeekEnding, GPCONO as Company, GPBT05 as Batch FROM cgcPRPWKD ORDER BY GPDTWE DESC, GPCONO, GPBT05"
		$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$SqlConnection.ConnectionString = $DBConnection
		
		$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
		$SqlCmd.CommandText = $SqlQuery
		$SqlCmd.Connection = $SqlConnection
		$SqlCmd.CommandTimeout = 0
		$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
		$SqlAdapter.SelectCommand = $SqlCmd
		$DataSet = New-Object System.Data.DataSet
		$nRecs = $SqlAdapter.Fill($DataSet)
		$nRecs | Out-Null
		
		LogWrite ($nRecs.ToString() + " batches available for capture.")
		
		$objTable = $DataSet.Tables[0]
		
		$dgBatches.DataSource = $objTable
		$dgBatches.AutoResizeColumns()
		
		if ($nRecs -gt 0)
		{
			$btnProcessGrid.Enabled = $true
		}
		else
		{
			$btnProcessGrid.Enabled = $false
		}
		$form.refresh()
		
		
	}
	catch [Exception]
	{
		Write-Host $_.Exception.Message
		Write-Host "Caught an exception:" -ForegroundColor Red
		Write-Host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
		Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
	}
	finally
	{
		$SqlConnection.Close()
	}
}

function DoExportData
{
	Param (
		[string]$inWeekEnding
		, [string]$inCompany
		, [string]$inBatch
	)
	
	try
	{
		LogWrite("-----------------------------------------------")
		LogWrite((Get-Date).ToLongDateString())
		LogWrite("-----------------------------------------------")
		
		#$btn.Enabled = "false"
		
		$SqlQuery = "exec mspGetCgcPayrollBatch;1 "
		$SqlQuery += "@CompanyNumber=" + $inCompany + ', '
		$SqlQuery += "@BatchNumber=" + $inBatch + ', '
		$SqlQuery += "@WeekEnding=" + $inWeekEnding + ', '
		$SqlQuery += "@DoRefresh=1"
		
		LogWrite($SqlQuery)
		
		$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$SqlConnection.ConnectionString = $DBConnection
		
		#LogWrite($SqlConnection.ConnectionString)
		
		$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
		$SqlCmd.CommandText = $SqlQuery
		$SqlCmd.Connection = $SqlConnection
		$SqlCmd.CommandTimeout = 0
		$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
		$SqlAdapter.SelectCommand = $SqlCmd
		$DataSet = New-Object System.Data.DataSet
		$nRecs = $SqlAdapter.Fill($DataSet)
		$nRecs | Out-Null
		
		LogWrite("Captured {3} records to {4}:{5}.dbo.cgcPRPWKD for {0}:{1}:{2}" -f $inWeekEnding, $inCompany, $inBatch, $nRecs.ToString(), $Server, $Database)
		
		#LogWrite($nRecs.ToString() + (" records captured from CGC to {0}:{1}.dbo.cgcPRPWKD" -f $Server,$Database))
		
		#$msg.subject = "CGC PayrollBatch Export [" + $txtCompany.Text + "." + $txtBatch.Text + "." + $txtWeekEnding.SelectionStart.ToString("yyyyMMdd") + "] [" + $Server + "." + $Database + "]"
		$script:mailBody += "<tr>"
		$script:mailBody += "<td>" + $inCompany + "</td>"
		$script:mailBody += "<td>" + $inBatch + "</td>"
		$script:mailBody += "<td>" + $inWeekEnding + "</td>"
		$script:mailBody += "<td>" + $nRecs.ToString() + (" records captured from CGC to {0}:{1}.dbo.cgcPRPWKD" -f $Server, $Database) + "</td>"
		$script:mailBody += "</tr>"
		
		[System.Windows.Forms.MessageBox]::Show(("{0} records captured." -f $nRecs), ("{0}-{1}-{2}" -f $txtCompany.Text, $txtBatch.Text, $txtWeekEnding.SelectionStart.ToString("yyyyMMdd")))
		
	}
	catch [Exception]
	{
		LogWrite $_.Exception.Message
		LogWrite "Caught an exception:" -ForegroundColor Red
		LogWrite "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
		LogWrite "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
	}
	finally
	{
		$SqlConnection.Close()
	}
	
}

try
{
	GetAvailableBatches
	
	$drc = $form.ShowDialog()
	
}
catch [Exception]
{
	Write-Host $_.Exception.Message
	write-host "Caught an exception:" -ForegroundColor Red
	write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
	write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
	
	exit 1
}
finally
{
	$msg.Dispose();
	$form.Dispose()
	exit 0
}

# SIG # Begin signature block
# MIINLwYJKoZIhvcNAQcCoIINIDCCDRwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSiYHk8sFfRj3BPgaSs7bGKWL
# txCgggohMIIE3jCCA8agAwIBAgICAwEwDQYJKoZIhvcNAQEFBQAwYzELMAkGA1UE
# BhMCVVMxITAfBgNVBAoTGFRoZSBHbyBEYWRkeSBHcm91cCwgSW5jLjExMC8GA1UE
# CxMoR28gRGFkZHkgQ2xhc3MgMiBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0w
# NjExMTYwMTU0MzdaFw0yNjExMTYwMTU0MzdaMIHKMQswCQYDVQQGEwJVUzEQMA4G
# A1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMRR29E
# YWRkeS5jb20sIEluYy4xMzAxBgNVBAsTKmh0dHA6Ly9jZXJ0aWZpY2F0ZXMuZ29k
# YWRkeS5jb20vcmVwb3NpdG9yeTEwMC4GA1UEAxMnR28gRGFkZHkgU2VjdXJlIENl
# cnRpZmljYXRpb24gQXV0aG9yaXR5MREwDwYDVQQFEwgwNzk2OTI4NzCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBAMQt1RWMnCZM7DI161+4WQFapmGBWTtw
# Y6vj3D3HKrjJM9N55DrtPDAjhI6zMBS2sofDPZVUBJ7fmd0LJR4h3mUpfjWoqVTr
# 9vcyOdQmVZWt7/v+WIbXnvQAjYwqDL1CBM6nPwT27oDyqu9SoWlm2r4arV3aLGbq
# Gmu75RpRSgAvSMeYddi5Kcju+GZtCpyz8/x4fKL4o/K1w/O5epHBp+YlLpyo7RJl
# bmr2EkRTcDCVw5wrWCs9CHRK8r5RsL+H0EwnWGu1NcWdrxcx+AuP7q2BNgWJCJjP
# Oq8lh8BJ6qf9Z/dFjpfMFDniNoW1fho3/Rb2cRGadDAW/hOUoz+EDU8CAwEAAaOC
# ATIwggEuMB0GA1UdDgQWBBT9rGEyk2xF1uLuhV+auud2mWjM5zAfBgNVHSMEGDAW
# gBTSxLDSkdRMEXGzYcs9of7dqGrU4zASBgNVHRMBAf8ECDAGAQH/AgEAMDMGCCsG
# AQUFBwEBBCcwJTAjBggrBgEFBQcwAYYXaHR0cDovL29jc3AuZ29kYWRkeS5jb20w
# RgYDVR0fBD8wPTA7oDmgN4Y1aHR0cDovL2NlcnRpZmljYXRlcy5nb2RhZGR5LmNv
# bS9yZXBvc2l0b3J5L2dkcm9vdC5jcmwwSwYDVR0gBEQwQjBABgRVHSAAMDgwNgYI
# KwYBBQUHAgEWKmh0dHA6Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5jb20vcmVwb3Np
# dG9yeTAOBgNVHQ8BAf8EBAMCAQYwDQYJKoZIhvcNAQEFBQADggEBANKGwOy9+aG2
# Z+5mC6IGOgRQjhVyrEp0lVPLN8tESe8HkGsz2ZbwlFalEzAFPIUyIXvJxwqoJKSQ
# 3kbTJSMUA2fCENZvD117esyfxVgqwcSeIaha86ykRvOe5GPLL5CkKSkB2XIsKd83
# ASe8T+5o0yGPwLPk9Qnt0hCqU7S+8MxZC9Y7lhyVJEnfzuz9p0iRFEUOOjZv2kWz
# RaJBydTXRE4+uXR21aITVSzGh6O1mawGhId/dQb8vxRMDsxuxN89txJx9OjxUUAi
# KEngHUuHqDTMBqLdElrRhjZkAzVvb3du6/KFUJheqwNTrZEjYx8WnM25sgVjOuH0
# aBsXBTWVU+4wggU7MIIEI6ADAgECAgcrECpLGUQ0MA0GCSqGSIb3DQEBBQUAMIHK
# MQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRz
# ZGFsZTEaMBgGA1UEChMRR29EYWRkeS5jb20sIEluYy4xMzAxBgNVBAsTKmh0dHA6
# Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeTEwMC4GA1UEAxMn
# R28gRGFkZHkgU2VjdXJlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MREwDwYDVQQF
# EwgwNzk2OTI4NzAeFw0xMjA0MDMxNjI5MTdaFw0xNTA1MjAxODQ3MjRaMGYxCzAJ
# BgNVBAYMAlVTMQswCQYDVQQIDAJXQTEQMA4GA1UEBwwHU2VhdHRsZTEbMBkGA1UE
# CgwSTWNLaW5zdHJ5IENvLiwgTExDMRswGQYDVQQDDBJNY0tpbnN0cnkgQ28uLCBM
# TEMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCZQqlk7T4SZfB4wvH9
# yXXH4WnRBh7Zjak3CXk/3qzL3Y3P8lZAG1UKOAwT4J9JNAflR3ky1tOOupt9m9To
# fBIpWXSBtFmR2Ai2NgtYndUNl6Up7HetubDCIn/kK0ajg9qdg8sh+OSwCl9dZDA4
# nh2uFUcIm2AMkVmZrHlR4naTcnDTd41TNZTdHkNJpQG86Ah0wuW+ltqU7duYuU4P
# 0cRVyUcMu+ngox1Uy+BwiX/Nfs++W8xHlqiLcdhSNSKdo3JRbM8gXWnB+96aJ5/a
# L4BpegWDGSM1G/8xgLXr9hHy6fTYAOm/djlSKuEROhCAukGrwQSE2gAtzkCHthin
# ezUdAgMBAAGjggGHMIIBgzAPBgNVHRMBAf8EBTADAQEAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMDMA4GA1UdDwEB/wQEAwIHgDAzBgNVHR8ELDAqMCigJqAkhiJodHRwOi8v
# Y3JsLmdvZGFkZHkuY29tL2dkczUtMTYuY3JsMFMGA1UdIARMMEowSAYLYIZIAYb9
# bQEHFwIwOTA3BggrBgEFBQcCARYraHR0cDovL2NlcnRpZmljYXRlcy5nb2RhZGR5
# LmNvbS9yZXBvc2l0b3J5LzCBgAYIKwYBBQUHAQEEdDByMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5nb2RhZGR5LmNvbS8wSgYIKwYBBQUHMAKGPmh0dHA6Ly9jZXJ0
# aWZpY2F0ZXMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS9nZF9pbnRlcm1lZGlhdGUu
# Y3J0MB8GA1UdIwQYMBaAFP2sYTKTbEXW4u6FX5q653aZaMznMB0GA1UdDgQWBBST
# 3ekzgPNdOwT6OBPHxUsnk8gRwTANBgkqhkiG9w0BAQUFAAOCAQEAs85sqguN08S0
# GZW2E4gkggz8lEATTQHvZFMssQJBll6c+YjIlVCz+z9XND1uIhz2Zi29SepGun+R
# AhJyMhKmC589ZSuz/jE6F9Gkgq6YI6wjW4NNBkXsTOngLEy6jb6jl9L1JorMKGIw
# 20Ql1o5TmV2vsMUKUgueogDtNSmS0ym2Z2hwuY23L54xjk5javj/viawHO60S/Ly
# JR9fwuekvQgrm03+d5jnLQ/CG7hd230YHXYcUnQXhSGJ6dVzohoy1AXGfdWXsBf3
# 91z6qxHOhsiIeNCgGecTMss+7OxJ016Qf1qD6SWQgQ/yzWVqrPp8j9pGsM9Pp73X
# C36YchZpTTGCAngwggJ0AgEBMIHWMIHKMQswCQYDVQQGEwJVUzEQMA4GA1UECBMH
# QXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMRR29EYWRkeS5j
# b20sIEluYy4xMzAxBgNVBAsTKmh0dHA6Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5j
# b20vcmVwb3NpdG9yeTEwMC4GA1UEAxMnR28gRGFkZHkgU2VjdXJlIENlcnRpZmlj
# YXRpb24gQXV0aG9yaXR5MREwDwYDVQQFEwgwNzk2OTI4NwIHKxAqSxlENDAJBgUr
# DgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkq
# hkiG9w0BCQQxFgQUvkAQaCQS5Cfr8ST9PW2rQyZu2cowDQYJKoZIhvcNAQEBBQAE
# ggEATEylqAHnTCU7xVvx5HVuBWjicnx1l/BGHB6wEg9A0A5QMpI/n1kq+Riv2kce
# foaSgo18QUJIGNalyQakP0OgBuVh1oLY5wqb8ehC0T+Pu7/VxT4VT16/76oeIc3u
# inZ4NmIAQcCbNPrQiYgcOZ0usfJdEqzD0bvT4H4oECgnSineoJsHJrvJDuMA5Eop
# TxPkD2vrVMqHNdR4RewC91uWVvtrMsoec0/lAFhHTB7A+JyoOkwrKkWv6XCjNM5t
# Ks+kTrvhMFA3t4V7ELz+pmbA7f25He/+HBfa6YWWAO5HkNYEf6mGx3AVI2Ez1jmv
# 61xG0jU192fiDYUTM45LSHpx7Q==
# SIG # End signature block
