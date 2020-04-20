function doFileSend
{
	Param (
		[string]$filePath
	,   [string]$recipient
	)
	
	try
	{			
		# Loop through each file in directory and send to recipient.
		$files = Get-ChildItem $filePath
		for ($i = 0; $i -lt $files.Count; $i++)
		{
			Write-Host $files[$i].FullName + " to " + $recipient
			LogWrite($files[$i].FullName + " to " + $recipient)
			$script:msgFilesSent += $files[$i].FullName + "</br>"
			
			#Creating a Mail object
			$msg = new-object Net.Mail.MailMessage
			
			# Email Variables
			$script:smptServer = "mail.mckinstry.com"
			$script:smptPort = 25
			$script:emailFrom = "rlbfilesender@mckinstry.com"
			$script:replyTo = "billo@mckinstry.com"
			
			#Creating SMTP server object
			$smtp = new-object Net.Mail.SmtpClient
			$smtp.Host = $script:smptServer
			$smtp.Port = $script:smptPort
			$msg.From = $script:emailFrom
			$msg.ReplyTo = $script:replyTo
			$msg.To.Add($recipient)
			$msg.To.Add("estherb@mckinstry.com")
			
			$msg.subject = "DEV/TEST ONLY : " + $files[$i].FullName
			
			$msg.body = "<hr/><b>Sample AP submission for process testing.</b><hr/><br/>"
			$msg.body += $files[$i].FullName + "<br/>"
			$msg.body += "<hr/>"
			$msg.body += "<i><font size='-1'>" + (Get-Date -format "MM/dd/yyyy HH:mm:ss") + "</font></i>"
			
			$att = new-object Net.Mail.Attachment($files[$i].FullName)
			$msg.Attachments.Add($att)
			
			$msg.IsBodyHTML = $true
			
			$smtp.Send($msg)
			
			$att.Dispose();
			$msg.Dispose();
		}
		
	}
	catch [Exception] {
		Write-Host LogWrite($_.Exception.Message_)
		Write-Host LogWrite("Caught an exception:") -ForegroundColor Red
		write-host LogWrite("Exception Type: $($_.Exception.GetType().FullName)") -ForegroundColor Red
		write-host LogWrite("Exception Message: $($_.Exception.Message)") -ForegroundColor Red		
	}
}

Function LogWrite
{
	Param ([string]$logstring)
	
	$ts = (Get-Date).ToLongTimeString() + "`t" + $logstring
	Add-content $script:LogFile -value $ts
	return $ts
	
	
}

function doEmail
{
	
	LogWrite("** Sending Email")
	
	#Creating a Mail object
	$msg = new-object Net.Mail.MailMessage
	
	# Email Variables
	$script:smptServer = "mail.mckinstry.com"
	$script:smptPort = 25
	$script:emailFrom = "rlbfilesender@mckinstry.com"
	$script:replyTo = "billo@mckinstry.com"
	#$script:emailToList="mikesh@mckinstry.com"
	#$script:emailCcList="billo@mckinstry.com,howards@mckinstry.com,erics@mckinstry.com,c-davidmcc@mckinstry.com"
	$script:emailToList = "billo@mckinstry.com"
	$script:emailCcList = "EstherB@mckinstry.com,eva@retaillockbox.com"
	$script:mailSubject = "Send Test Files to RLB Email for Processing "
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
	
	$msg.subject = "DEV/TEST ONLY : Send Test Files to RLB Email for Processing"
	
	$script:msgBody = "<B><FONT COLOR='RED'>DEV/TEST ONLY</FONT></B><BR/><HR/>"
	$script:msgBody += "<P>Send Test Files to <B>"  + $script:recipient + "</B> for Processing.<BR/></P>"
	$script:msgBody += "<HR/><UL>"
	$script:msgBody += "<LI>" + $LogFile + "</LI>"
	$script:msgBody += "</UL>"
	$script:msgBody += "<HR/>"
	$script:msgBody +=$script:msgFilesSent
	$script:msgBody += "<P><FONT SIZE='-1'><I>"
	$script:msgBody += $script:compname + "<BR/>"
	$script:msgBody += $script:homeDir + "<BR/>"
	$script:msgBody += (Get-Date).ToLongDateString() + " " + (Get-Date).ToShortTimeString()
	$script:msgBody += "</I></FONT></P>"
	
	$msg.body = $script:msgBody
	
	$att = new-object Net.Mail.Attachment($LogFile)
	$msg.Attachments.Add($att)
	
	$msg.IsBodyHTML = $true
	
	#Sending email
	$smtp.Send($msg)
	
	$att.Dispose();
	$msg.Dispose();
	
}


#Main Application
try
{
	cls
	
	# Production Site Default
	$script:compname = gc env:computername
	$script:homeDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
	$script:filedDir = $script:homeDir + "\FilesToSend\"
	$script:recipient = "mckinstry@mypaystation.info"
	$script:msgFilesSent = ""
	
	$strToday = (Get-Date -format "yyyyMMdd")
	$script:LogFile = $script:homeDir + "\Log\ProcessLog_{0}.txt" -f ($strToday)
	
	If (Test-Path $LogFile)
	{
		Remove-Item $LogFile
	}
	
		
	LogWrite($script:compname) | Write-Host
	LogWrite($script:homeDir) | Write-Host
	LogWrite($myInvocation.MyCommand.Definition) | Write-Host
	LogWrite($script:filedDir) | Write-Host
	LogWrite($LogFile) | Write-Host
	
	LogWrite(("-" * 100)) | Write-Host
	LogWrite("Start ==>" + (Get-Date).ToLongDateString()) | Write-Host -ForegroundColor GREEN
	LogWrite(("-" * 100)) | Write-Host
	
	$ok = doFileSend -filePath $script:filedDir -recipient $script:recipient
	
	LogWrite(("-" * 100)) | Write-Host
	LogWrite("End ==>" + (Get-Date).ToLongDateString()) | Write-Host -ForegroundColor GREEN
		
}
catch [Exception] {
	Write-Host LogWrite($_.Exception.Message_)
	Write-Host LogWrite("Caught an exception:") -ForegroundColor Red
	write-host LogWrite("Exception Type: $($_.Exception.GetType().FullName)") -ForegroundColor Red
	write-host LogWrite("Exception Message: $($_.Exception.Message)") -ForegroundColor Red
	
	exit 1
}
finally
{
	
	doEmail
	
	exit 0
}
# SIG # Begin signature block
# MIITrgYJKoZIhvcNAQcCoIITnzCCE5sCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUCM1aVsX0eMY/dGMz041Gklk
# kH+ggg36MIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BJ8wggOHoAMCAQICEhEhQFwfDtJYiCvlTYaGuhHqRTANBgkqhkiG9w0BAQUFADBS
# MQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UE
# AxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjAeFw0xMzA4MjMwMDAw
# MDBaFw0yNDA5MjMwMDAwMDBaMGAxCzAJBgNVBAYTAlNHMR8wHQYDVQQKExZHTU8g
# R2xvYmFsU2lnbiBQdGUgTHRkMTAwLgYDVQQDEydHbG9iYWxTaWduIFRTQSBmb3Ig
# TVMgQXV0aGVudGljb2RlIC0gRzEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQCwF66i07YEMFYeWA+x7VWk1lTL2PZzOuxdXqsl/Tal+oTDYUDFRrVZUjtC
# oi5fE2IQqVvmc9aSJbF9I+MGs4c6DkPw1wCJU6IRMVIobl1AcjzyCXenSZKX1GyQ
# oHan/bjcs53yB2AsT1iYAGvTFVTg+t3/gCxfGKaY/9Sr7KFFWbIub2Jd4NkZrItX
# nKgmK9kXpRDSRwgacCwzi39ogCq1oV1r3Y0CAikDqnw3u7spTj1Tk7Om+o/SWJMV
# TLktq4CjoyX7r/cIZLB6RA9cENdfYTeqTmvT0lMlnYJz+iz5crCpGTkqUPqp0Dw6
# yuhb7/VfUfT5CtmXNd5qheYjBEKvAgMBAAGjggFfMIIBWzAOBgNVHQ8BAf8EBAMC
# B4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEFBQcCARYmaHR0cHM6
# Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYDVR0TBAIwADAWBgNV
# HSUBAf8EDDAKBggrBgEFBQcDCDBCBgNVHR8EOzA5MDegNaAzhjFodHRwOi8vY3Js
# Lmdsb2JhbHNpZ24uY29tL2dzL2dzdGltZXN0YW1waW5nZzIuY3JsMFQGCCsGAQUF
# BwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNv
# bS9jYWNlcnQvZ3N0aW1lc3RhbXBpbmdnMi5jcnQwHQYDVR0OBBYEFNSihEo4Whh/
# uk8wUL2d1XqH1gn3MB8GA1UdIwQYMBaAFEbYPv/c477/g+b0hZuw3WrWFKnBMA0G
# CSqGSIb3DQEBBQUAA4IBAQACMRQuWFdkQYXorxJ1PIgcw17sLOmhPPW6qlMdudEp
# Y9xDZ4bUOdrexsn/vkWF9KTXwVHqGO5AWF7me8yiQSkTOMjqIRaczpCmLvumytmU
# 30Ad+QIYK772XU+f/5pI28UFCcqAzqD53EvDI+YDj7S0r1txKWGRGBprevL9DdHN
# fV6Y67pwXuX06kPeNT3FFIGK2z4QXrty+qGgk6sDHMFlPJETiwRdK8S5FhvMVcUM
# 6KvnQ8mygyilUxNHqzlkuRzqNDCxdgCVIfHUPaj9oAAy126YPKacOwuDvsu4uyom
# jFm4ua6vJqziNKLcIQ2BCzgT90Wj49vErKFtG7flYVzXMIIFOzCCBCOgAwIBAgIH
# KxAqSxlENDANBgkqhkiG9w0BAQUFADCByjELMAkGA1UEBhMCVVMxEDAOBgNVBAgT
# B0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHku
# Y29tLCBJbmMuMTMwMQYDVQQLEypodHRwOi8vY2VydGlmaWNhdGVzLmdvZGFkZHku
# Y29tL3JlcG9zaXRvcnkxMDAuBgNVBAMTJ0dvIERhZGR5IFNlY3VyZSBDZXJ0aWZp
# Y2F0aW9uIEF1dGhvcml0eTERMA8GA1UEBRMIMDc5NjkyODcwHhcNMTIwNDAzMTYy
# OTE3WhcNMTUwNTIwMTg0NzI0WjBmMQswCQYDVQQGDAJVUzELMAkGA1UECAwCV0Ex
# EDAOBgNVBAcMB1NlYXR0bGUxGzAZBgNVBAoMEk1jS2luc3RyeSBDby4sIExMQzEb
# MBkGA1UEAwwSTWNLaW5zdHJ5IENvLiwgTExDMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEAmUKpZO0+EmXweMLx/cl1x+Fp0QYe2Y2pNwl5P96sy92Nz/JW
# QBtVCjgME+CfSTQH5Ud5MtbTjrqbfZvU6HwSKVl0gbRZkdgItjYLWJ3VDZelKex3
# rbmwwiJ/5CtGo4PanYPLIfjksApfXWQwOJ4drhVHCJtgDJFZmax5UeJ2k3Jw03eN
# UzWU3R5DSaUBvOgIdMLlvpbalO3bmLlOD9HEVclHDLvp4KMdVMvgcIl/zX7PvlvM
# R5aoi3HYUjUinaNyUWzPIF1pwfvemief2i+AaXoFgxkjNRv/MYC16/YR8un02ADp
# v3Y5UirhEToQgLpBq8EEhNoALc5Ah7YYp3s1HQIDAQABo4IBhzCCAYMwDwYDVR0T
# AQH/BAUwAwEBADATBgNVHSUEDDAKBggrBgEFBQcDAzAOBgNVHQ8BAf8EBAMCB4Aw
# MwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2NybC5nb2RhZGR5LmNvbS9nZHM1LTE2
# LmNybDBTBgNVHSAETDBKMEgGC2CGSAGG/W0BBxcCMDkwNwYIKwYBBQUHAgEWK2h0
# dHA6Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8wgYAGCCsG
# AQUFBwEBBHQwcjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZ29kYWRkeS5jb20v
# MEoGCCsGAQUFBzAChj5odHRwOi8vY2VydGlmaWNhdGVzLmdvZGFkZHkuY29tL3Jl
# cG9zaXRvcnkvZ2RfaW50ZXJtZWRpYXRlLmNydDAfBgNVHSMEGDAWgBT9rGEyk2xF
# 1uLuhV+auud2mWjM5zAdBgNVHQ4EFgQUk93pM4DzXTsE+jgTx8VLJ5PIEcEwDQYJ
# KoZIhvcNAQEFBQADggEBALPObKoLjdPEtBmVthOIJIIM/JRAE00B72RTLLECQZZe
# nPmIyJVQs/s/VzQ9biIc9mYtvUnqRrp/kQIScjISpgufPWUrs/4xOhfRpIKumCOs
# I1uDTQZF7Ezp4CxMuo2+o5fS9SaKzChiMNtEJdaOU5ldr7DFClILnqIA7TUpktMp
# tmdocLmNty+eMY5OY2r4/74msBzutEvy8iUfX8LnpL0IK5tN/neY5y0Pwhu4Xdt9
# GB12HFJ0F4UhienVc6IaMtQFxn3Vl7AX9/dc+qsRzobIiHjQoBnnEzLLPuzsSdNe
# kH9ag+klkIEP8s1laqz6fI/aRrDPT6e91wt+mHIWaU0xggUeMIIFGgIBATCB1jCB
# yjELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0
# c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMTMwMQYDVQQLEypodHRw
# Oi8vY2VydGlmaWNhdGVzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkxMDAuBgNVBAMT
# J0dvIERhZGR5IFNlY3VyZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTERMA8GA1UE
# BRMIMDc5NjkyODcCBysQKksZRDQwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFBAsmvQrOWV1Vf6y
# ZUAzo5zksqOzMA0GCSqGSIb3DQEBAQUABIIBAGzHo73qEPQwC/RnoK10/cVOK860
# kD+F6gu5OF/QN0b38DNdiwUe3K7/CJ/3Vk3lrrXDlxmBxG3PRSqotpSCCNoVniiu
# VY2wC+Z+3x9WaZe9IuI3mmXnoRqtUaAbMFsqLh4KKlRE3NU+CzjogYubC+/EldpR
# mO1bj3zCVnk2mhFyYGd4bgdXW6pEkL/5U0bOsTdjxO8k2zIDMN70tE6FgvMR53S8
# ATk7p0UXGv4YOPikVSRK1Hdq/HlVl6yOm0i5yT9olefiAAc0VLLAnuIW6TdEWyp2
# XN4dUh1Ah9W8RLaIGJeiXf+mxeivtZkaOnobs799EVF7/bwzKPRm6cpBq/KhggKi
# MIICngYJKoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZMBcG
# A1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1l
# c3RhbXBpbmcgQ0EgLSBHMgISESFAXB8O0liIK+VNhoa6EepFMAkGBSsOAwIaBQCg
# gf0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTQw
# NzAzMjEwMjAyWjAjBgkqhkiG9w0BCQQxFgQUM+Rm1BiO1Wsv6jXPXnhA8jETYRww
# gZ0GCyqGSIb3DQEJEAIMMYGNMIGKMIGHMIGEBBSM5p9QEuHRqPs5Xi4x4rQr3js0
# OzBsMFakVDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1z
# YTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESFA
# XB8O0liIK+VNhoa6EepFMA0GCSqGSIb3DQEBAQUABIIBAEK4Gbf8sDdDdtc8e7/f
# TAzTf8G8a9cIhbIang77/PG3mk19cP9Ld+BlWV5soqgoRtYtIrp450crqwTmUbYR
# uvVfiQwpd/TSDjvJyqCB6QtLPPD4HWRxinCfyw++NnxYfLsQdYns0OhNh7bZEkCI
# 29haSXBSmDcyi7xdRKP0uLoFebqQLURGKbzM+JwAHPDpYrq0h+6HSurKZrYR/DsZ
# 2e7lq74fo/ggT1cCiqB6BPWvlwELaRwSX7PxqJJEbxb+Mo8gIFUcWuMTGhB9JlEE
# KVqOE4IUISgIHUoOv6YMhPOHfjYMKmohNeaVy36H2Ng+tfuKi/eihVswmCAtZ/Xr
# Q+A=
# SIG # End signature block
