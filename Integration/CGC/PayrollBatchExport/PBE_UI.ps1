<#
2014.06.05 - LWO - 
Down and dirty utility for capturing CGC Payroll Batch Data
from PRPWKD to a SQL Database to be used in posted payroll
in Viewpoint for parallel processing, testing and auditting.
#>

function GetPreviousDate { 
param([STRING]$WeekDay = `
$(Throw ‘WeekDay is required’), [Int]$NumberOfWeeks = 0)
$DayNumber = @{
“Saturday” = 1; 
“Sunday” = 0; 
“Monday” = -1;
“Tuesday” = -2; 
“Wednesday” = -3;
“Thursday” = -4
“Friday” = -5}

([System.Datetime] $Today = $(get-date)) |Out-Null 
$NumDaysSincePreviousDate = $Today.DayOfWeek.value__ + $DayNumber[$WeekDay]
([System.Datetime] $PreviousDateThisWeek = $Today.AddDays(- $NumDaysSincePreviousDate)) |Out-Null
$PreviousDate =$PreviousDateThisWeek.AddDays(-($NumberOfWeeks *7)) #.ToString(“MM/dd/yyyy”)
return $PreviousDate
}

Function LogWrite
{
   Param ([string]$logstring)
  
   $ts = (Get-Date).ToLongTimeString() + "`t" + $logstring
   Add-content $Logfile -value $ts
   Write-Host $logstring
}

$prevWeekEndingDate = GetPreviousDate Sunday


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
$script:emailCcList="billo@mckinstry.com,erics@mckinstry.com,theresap@mckinstry.com"
$script:mailSubject = "CGC PayrollBatch Export Processing Executed "
$script:mailBody = $Null

#Creating SMTP server object
$smtp = new-object Net.Mail.SmtpClient
$smtp.Host = $script:smptServer
$smtp.Port = $script:smptPort

#Email structure 
$msg.From = $script:emailFrom
$msg.ReplyTo = $script:replyTo

if ( ($script:emailToList -ne $Null) -and ($script:emailToList -ne ""))
{
	ForEach ( $emailTo in $script:emailToList.split(",") )
	{
		$msg.To.Add($emailTo)
	}
}

if ( ($script:emailCcList -ne $Null) -and ($script:emailCcList -ne ""))
{
	ForEach ( $emailCc in $script:emailCcList.Split(",") )
	{
		$msg.Cc.Add($emailCc)
	}
}

$msg.subject = "CGC PayrollBatch Export [" + $Server + "." + $Database + "]"

#$script:msgBody = "<B><FONT COLOR='RED'>DEV/TEST ONLY</FONT></B><BR/><HR/>"
$script:msgBody += "<P><B>Export/Upload of CGC PayrollBatch data.</B><BR/>"
#$script:msgBody += "into {0}:{1}.dbo.cgcPRPWKD</P>" -f $Server, $Database
$script:msgBody += "<HR/>"

Add-Type -AssemblyName System.Windows.Forms
$form = New-Object Windows.Forms.Form
$form.Size = New-Object Drawing.Size @(400,325)
$form.StartPosition = "CenterScreen"
$form.Text = "CGC PR Batch Capture"

$lblCompany = New-Object System.Windows.Forms.Label
$lblCompany.Text = 'Company Number'
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 20
$lblCompany.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 5
$System_Drawing_Point.Y = 21
$lblCompany.Location = $System_Drawing_Point
$form.Controls.Add($lblCompany)

$txtCompany = New-Object System.Windows.Forms.TextBox
$txtCompany.Text = '1'
$txtCompany.TabIndex = 1
$txtCompany.name = 'txtCompany'
#$txtCompany.Font = New-Object System.Drawing.Font("Courier New",10,0,3,0)
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 60
$System_Drawing_Size.Height = 20
$txtCompany.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 120
$System_Drawing_Point.Y = 21
$txtCompany.Location = $System_Drawing_Point
$form.Controls.Add($txtCompany)

$lblBatch = New-Object System.Windows.Forms.Label
$lblBatch.Text = 'Batch Number'
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 20
$lblBatch.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 5
$System_Drawing_Point.Y = 42
$lblBatch.Location = $System_Drawing_Point
$form.Controls.Add($lblBatch)

$txtBatch = New-Object System.Windows.Forms.TextBox
$txtBatch.Text = ''
$txtBatch.TabIndex = 2
$txtBatch.name = 'txtBatch'
#$txtBatch.Font = New-Object System.Drawing.Font("Courier New",10,0,3,0)
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 20
$txtBatch.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 120
$System_Drawing_Point.Y = 42
$txtBatch.Location = $System_Drawing_Point
$form.Controls.Add($txtBatch)


$lblWeekEnding = New-Object System.Windows.Forms.Label
$lblWeekEnding.Text = 'Week Ending'
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 20
$lblWeekEnding.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 5
$System_Drawing_Point.Y = 63
$lblWeekEnding.Location = $System_Drawing_Point
$form.Controls.Add($lblWeekEnding)

#$txtWeekEnding = New-Object System.Windows.Forms.TextBox
$txtWeekEnding = New-Object System.Windows.Forms.MonthCalendar
$txtWeekEnding.SetDate($prevWeekEndingDate)
$txtWeekEnding.ShowTodayCircle = $False
$txtWeekEnding.MaxSelectionCount = 1

#$txtWeekEnding.Text = '<week ending>'
$txtWeekEnding.TabIndex = 2
$txtWeekEnding.name = 'txtWeekEnding'
#$txtBatch.Font = New-Object System.Drawing.Font("Courier New",10,0,3,0)
#$System_Drawing_Size = New-Object System.Drawing.Size
#$System_Drawing_Size.Width = 100
#$System_Drawing_Size.Height = 20
$txtWeekEnding.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 120
$System_Drawing_Point.Y = 63
$txtWeekEnding.Location = $System_Drawing_Point
$form.Controls.Add($txtWeekEnding)


$btn = New-Object System.Windows.Forms.Button
#$btn.DialogResult = [System.Windows.Forms.DialogResult]::DialogResult.OK
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 200
$System_Drawing_Point.Y = 250
$btn.Location = $System_Drawing_Point
$form.Controls.Add($txtWeekEnding)
$btn.add_click({CheckPreviousCapture})
$btn.Text = "Capture"
$form.Controls.Add($btn)

$btnCancel = New-Object System.Windows.Forms.Button
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 100
$System_Drawing_Point.Y = 250
$btnCancel.Location = $System_Drawing_Point
$btnCancel.add_click({$form.Close()})
$btnCancel.Text = "Cancel"
$form.Controls.Add($btnCancel)

$respform = New-Object Windows.Forms.Form
$respform.Size = New-Object Drawing.Size @(400,325)
$respform.StartPosition = "CenterScreen"
$respform.Text = "CGC PR Batch Capture"

$lblMsg = New-Object System.Windows.Forms.Label
$lblMsgText = '{0} records already captured.  Are you sure you want to re-capture?'
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
			
function CheckPreviousCapture
{
		$SqlQuery = "exec mspGetCgcPayrollBatch;1 "
		$SqlQuery += "@CompanyNumber=" + $txtCompany.Text + ', '
		$SqlQuery += "@BatchNumber=" + $txtBatch.Text + ', '
		$SqlQuery += "@WeekEnding=" + $txtWeekEnding.SelectionStart.ToString("yyyyMMdd") + ', '
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
		
		if ( $nRecs -gt 0 )
		{
			 $lblMsg.Text = $lblMsgText -f $nRecs

			
			 if ( $respform.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK ) 
			 {
			 	DoExportData
			 }
		}
		else
		{
			DoExportData
		}
		
}

function DoExportData
{
	try
	{
		LogWrite("-----------------------------------------------")
    	LogWrite((Get-Date).ToLongDateString() )
		LogWrite("-----------------------------------------------")
	
		#$btn.Enabled = "false"
				
		$SqlQuery = "exec mspGetCgcPayrollBatch;1 "
		$SqlQuery += "@CompanyNumber=" + $txtCompany.Text + ', '
		$SqlQuery += "@BatchNumber=" + $txtBatch.Text + ', '
		$SqlQuery += "@WeekEnding=" + $txtWeekEnding.SelectionStart.ToString("yyyyMMdd") + ', '
		$SqlQuery += "@DoRefresh=1"
	
		LogWrite($SqlQuery)
	
		$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$SqlConnection.ConnectionString = $DBConnection
		
		LogWrite($SqlConnection.ConnectionString)
	
		$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
		$SqlCmd.CommandText = $SqlQuery
		$SqlCmd.Connection = $SqlConnection
		$SqlCmd.CommandTimeout = 0
		$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
		$SqlAdapter.SelectCommand = $SqlCmd
		$DataSet = New-Object System.Data.DataSet
		$nRecs = $SqlAdapter.Fill($DataSet)
		$nRecs | Out-Null 
		
		LogWrite($nRecs.ToString() + (" records captured from CGC to {0}:{1}.dbo.cgcPRPWKD" -f $Server,$Database))
	
		$msg.subject = "CGC PayrollBatch Export [" + $txtCompany.Text + "." + $txtBatch.Text + "." + $txtWeekEnding.SelectionStart.ToString("yyyyMMdd") + "] [" + $Server + "." + $Database + "]" 
		$curMsgBody = $script:msgBody
		$curMsgBody += "Company:     " + $txtCompany.Text + "<br/>"
		$curMsgBody += "Batch:       " + $txtBatch.Text + "<br/>"
		$curMsgBody += "Week Ending: " + $txtWeekEnding.SelectionStart.ToString("yyyyMMdd") + "<br/><br/>"
		$curMsgBody += $nRecs.ToString() + (" records captured from CGC to {0}:{1}.dbo.cgcPRPWKD" -f $Server,$Database) + "<br/><br/>"
		$curMsgBody += "Run at: {0}" -f (Get-Date)
	
		$txtBatch.Text = ""
		
		if ( ($script:emailToList -ne $Null) -and ($script:emailToList -ne ""))
		{
			ForEach ( $emailTo in $script:emailToList.split(",") )
			{
				LogWrite("To: " + $emailTo)
			}
		}
	
		if ( ($script:emailCcList -ne $Null) -and ($script:emailCcList -ne ""))
		{
			ForEach ( $emailCc in $script:emailCcList.Split(",") )
			{
				LogWrite("Cc: " + $emailCc)
			}
		}
	
		$compname = $script:compname
	
		$msg.body = $curMsgBody
		$msg.IsBodyHTML=$true
		#Sending email 
		$smtp.Send($msg)
		#$msg.Dispose();

		
		[System.Windows.Forms.MessageBox]::Show(("{0} records captured." -f $nRecs), ("{0}-{1}-{2}" -f $txtCompany.Text, $txtBatch.Text, $txtWeekEnding.SelectionStart.ToString("yyyyMMdd")))

	}
	catch [Exception]
	{
		LogWrite $_.Exception.Message
		LogWrite "Caught an exception:" -ForegroundColor Red
		LogWrite "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
		LogWrite "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
	}

}

try
{

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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXJBcosDfJ0d6Kecu6QGwgryy
# 6t6gggohMIIE3jCCA8agAwIBAgICAwEwDQYJKoZIhvcNAQEFBQAwYzELMAkGA1UE
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
# hkiG9w0BCQQxFgQUWtqwssXSxenNpDLePmkKuRC+bWUwDQYJKoZIhvcNAQEBBQAE
# ggEAEEq+2VU6r/pOJq73xyjQfRUUnXLpD0/P6/A86u4xxrtlTNVewXW3XeyIKI4r
# oxDOxtTdcwsYZwWkt2+dz7QwxGWDiEtzvmjRfM17kQ8GzTD290wRxW9YzJ5wQ4lC
# DBTTqNw47hH6M2kF7ODGPSiXoZmKKNvW0Ebx3c4xjfVtAnYXu1h7xK970ujMFi54
# llpdOK8EkU2M2ipc/ksoTVvHLQbq3xdtQoJGyaexRNBer+v5NiUhWtIceJiBy/Yx
# CjcfIm3Wk+A8Am65fKy5PtrrsLNIGWB8B3vCpnkH9FI7MkluRYdIus1evV51MMky
# hOnL/rZ9S5gWs/7p2FB8icb+XA==
# SIG # End signature block
