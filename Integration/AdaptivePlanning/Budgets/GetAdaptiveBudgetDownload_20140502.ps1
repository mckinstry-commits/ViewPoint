# GetAdaptiveBudget.ps1 /u vpsvcacct@mckinstry.com /p v1ewp@int /i MCKINSTRY2

function exportBudgetData {
	Param (
		[string]$Login
	, 	[string]$Password
	,	[string]$Instance
	,	[string]$BudgetVersion
	,	[string]$Year
	)

	try {

		LogWrite( $script:AdaptiveAPI + " [" + $Login + ":" + $Password + "]" ) | Write-Host
		$apiCommand = "<?xml version='1.0' encoding='UTF-8'?>";
		$apiCommand += "<call method='exportData'>";
		$apiCommand += "<credentials login='$Login' password='$Password' instanceCode='$Instance'/>";
		$apiCommand += "<version name='$BudgetVersion' isDefault='false'/>";
		$apiCommand += "<format useInternalCodes='false' includeUnmappedItems='false'/>";
		$apiCommand += "<filters>";
		#$apiCommand += "<accounts>";
		#$apiCommand += "<account code='Assets' isAssumption='true' includeDescendants='false'/>";
		#$apiCommand += "<account code='Liabilities_Equities' isAssumption='false' includeDescendants='true'/>";
		#$apiCommand += "<account code='Expenses' isAssumption='false' includeDescendants='true'/>";
		#$apiCommand += "</accounts>";
		#$apiCommand += "<levels>";
		#$apiCommand += "<level name='001 IT Support' isRollup='false' includeDescendants='true'/>";
		#$apiCommand += "<level name='QA' isRollup='false' includeDescendants='false'/>";
		#$apiCommand += "</levels>";
		$apiCommand += "<timeSpan start='Jan-$Year' end='Dec-$Year'/>";
		#$apiCommand += "<dimensionValues>";
		#$apiCommand += "<dimensionValue dimName='Customer' name='A Corp' directChildren='true'/>";
		#$apiCommand += "<dimensionValue dimName='Region' name='' uncategorized='true' directChildren='false'/>";
		#$apiCommand += "</dimensionValues>";
		$apiCommand += "</filters>";
		#$apiCommand += "<dimensions>";
		#$apiCommand += "<dimension name='Region'/>";
		#$apiCommand += "<dimension name='CountryRegion'/>";
		#$apiCommand += "</dimensions>";
		#$apiCommand += "<rules includeZeroRows='false' includeRollups='true' markInvalidValues='false'	markBlanks='false' timeRollups='single'>";
		#$apiCommand += "<currency useCorporate='false' useLocal='false' override='USD'/>";
		#$apiCommand += "</rules>";
		$apiCommand += "</call>"; 

		LogWrite( $apiCommand ) | Write-Host -BackgroundColor gray -ForegroundColor blue

		$url = $script:AdaptiveAPI

		$http_request = New-Object -ComObject Msxml2.XMLHTTP
		#$xd =  New-Object -ComObject  MSXML2.DOMDocument.3.0
		[System.Xml.XmlDocument] $xd = New-Object System.Xml.XmlDocument

		$http_request.open('POST', $url, $false)
		$http_request.setRequestHeader("Content-type", "text/xml;charset=UTF-8")
		$http_request.setRequestHeader("Content-length", $apiCommand.length)
		$http_request.setRequestHeader("Connection", "close")
		$http_request.send($apiCommand)
		$http_request.statusText

		$xd.loadXML($http_request.responseXML.xml);

		[System.Xml.XmlElement]$parentnodelist = $xd.selectsinglenode("/response/output") # XPath is case sensitive

		$strToLog = "Parsing " + $parentnodelist.ChildNodes.Count + " records from AdaptivePlanning (" + $url + ")`n"
		LogWrite( $strToLog ) | Write-Host
		$rcnt = 0

		$strData = $parentnodelist."#cdata-section";

		$stringArray = $strData.Split("`n") | % {$_.trim()}

		#Create Header Row
		LogWrite(CsvWrite("`"GLCo`",`"GLAcct`",`"Mth`",`"BudgetAmt`",`"BudgetCode`"")) | Write-Host

		#TODO:  Sum Values if GLAccount+Level Combination are the same.
		#TODO: Parse Level value to get company prefix and department suffix as seperate values.
		

		for ( $i = 0; $i -lt $stringArray.length; $i++ )
		{
			#Write-Host $stringArray[$i].ToString();

			if ( $i -eq 0 )
			{
				#Do Headers
				$HeaderArray = $stringArray[$i].Split(",") | % {$_.trim()}
			}

			else
			{
				#Do Rows
				$DataArray = $stringArray[$i].Split(",") | % {$_.trim()}
				$acct = ($DataArray[0].ToString() -replace '"','') -replace "=",""
				$colevel = ($DataArray[1].ToString() -replace '"','') -replace "=",""
				
				$_GLCo=$colevel.Split(".")[0];
				$level=$colevel.Split(".")[1];
				
				
				#if ( IsNumeric($acct) -and IsNumeric($level) )
				#{
					$Jan = ($DataArray[2].ToString())
					$Feb = ($DataArray[3].ToString())
					$Mar = ($DataArray[4].ToString())
					$Apr = ($DataArray[5].ToString())
					$May = ($DataArray[6].ToString())
					$Jun = ($DataArray[7].ToString())
					$Jul = ($DataArray[8].ToString())
					$Aug = ($DataArray[9].ToString())
					$Sep = ($DataArray[10].ToString())
					$Oct = ($DataArray[11].ToString())
					$Nov = ($DataArray[12].ToString())
					$Dec = ($DataArray[13].ToString())

					#$_GLCo = calcCompanyFromDept($level);
					$_BudgetCode ="Final2014"

					#TODO : Strip Comma from Numerics for CSV conversion
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"1/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$Jan,$_GLCo,$_BudgetCode)) | Write-Host
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"2/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$Feb,$_GLCo,$_BudgetCode)) | Write-Host
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"3/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$Mar,$_GLCo,$_BudgetCode)) | Write-Host
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"4/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$Apr,$_GLCo,$_BudgetCode)) | Write-Host
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"5/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$May,$_GLCo,$_BudgetCode)) | Write-Host
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"6/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$Jun,$_GLCo,$_BudgetCode)) | Write-Host
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"7/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$Jul,$_GLCo,$_BudgetCode)) | Write-Host
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"8/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$Aug,$_GLCo,$_BudgetCode)) | Write-Host
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"9/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$Sep,$_GLCo,$_BudgetCode)) | Write-Host
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"10/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$Oct,$_GLCo,$_BudgetCode)) | Write-Host
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"11/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$Nov,$_GLCo,$_BudgetCode)) | Write-Host
					LogWrite(CsvWrite("`"{3}`",`"{0}-000-{1}-`",`"12/1/2014`",`"{2:f2}`",`"{4}`"" -f $acct, $level, [decimal]$Dec,$_GLCo,$_BudgetCode)) | Write-Host
				#}

			}


		}

	}
	catch [Exception] {
		LogWrite( $_.Exception.Message ) | Write-Host
		LogWrite( "Caught an exception:") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Type: $($_.Exception.GetType().FullName)") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red 
	}


}

function isNumeric ($x) {
	try {
		0 + $x | Out-Null
		return $true
	} catch [Exception] {
		return $false
	}
}

Function CsvWrite {
	Param ([string]$logstring)
	Add-content $CsvFile -value $logstring
	return $logstring


}

Function LogWrite {
	Param ([string]$logstring)

	$ts = (Get-Date).ToLongTimeString() + "`t" + $logstring
	Add-content $Logfile -value $ts
	return $ts


}

function doEmail {

	LogWrite("** Sending Email")
	
	#Creating a Mail object
	$msg = new-object Net.Mail.MailMessage

	# Email Variables
	$script:smptServer="mail.mckinstry.com"
	$script:smptPort=25
	$script:emailFrom="adaptiveplanning@mckinstry.com"
	$script:replyTo="billo@mckinstry.com"
	#$script:emailToList="mikesh@mckinstry.com"
	#$script:emailCcList="billo@mckinstry.com,howards@mckinstry.com,erics@mckinstry.com,c-davidmcc@mckinstry.com"
	$script:emailToList="billo@mckinstry.com"
	$script:emailCcList=  $Null
	$script:mailSubject = "Adaptive Planning Budget Export Processing Executed "
	$script:mailBody  = $Null
	
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
	
	$msg.subject = "DEV/TEST ONLY : Adaptive Planning Budget Export Export [" + $Server + "." + $Database + "]"
	
	$script:msgBody = "<B><FONT COLOR='RED'>DEV/TEST ONLY</FONT></B><BR/><HR/>"
	$script:msgBody += "<P><B>Export/Upload of Adaptive Planning Budget data.</B><BR/></P>"
	$script:msgBody += "<HR/><UL>"
	$script:msgBody += "<LI>" + $LogFile + "</LI>" 	
	$script:msgBody += "<LI>" + $CsvFile + "</LI>" 	
	$script:msgBody += "</UL>"	
	$script:msgBody +="<HR/>"
	$script:msgBody +="<P><FONT SIZE='-1'><I>"
	$script:msgBody += $script:compname + "<BR/>"
	$script:msgBody += $script:homeDir + "<BR/>"
	$script:msgBody += $script:AdaptiveAPI + "<BR/>"
	$script:msgBody += $instance + "<BR/>"
	$script:msgBody += $BudgetVersion + "<BR/>"
	$script:msgBody += $Year + "<BR/>"
	$script:msgBody += (Get-Date).ToLongDateString() + " " + (Get-Date).ToShortTimeString()
	$script:msgBody +="</I></FONT></P>"
	
	$msg.body = $script:msgBody
	
	$att = new-object Net.Mail.Attachment($LogFile)
	$msg.Attachments.Add($att)	
	
	$att2 = new-object Net.Mail.Attachment($CsvFile)
	$msg.Attachments.Add($att2)
	
	$msg.IsBodyHTML=$true
	
    #Sending email 
    $smtp.Send($msg)
	
	$att.Dispose();
	$att2.Dispose();
	$msg.Dispose();

}

#Main Application
try {
	cls

	# Production Site Default
	$script:compname = gc env:computername
	$script:homeDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
	$script:downloadDir = $script:homeDir + "\APDownloads\" 
	$script:AdaptiveAPI = "https://live.adaptiveplanning.com/api/v7";
	$instance = "MCKINSTRY2"
	$BudgetVersion =  'McKinstry Budget 2014'
	$Year = "2014"
	$strToday = (Get-Date -format "yyyyMMdd")
	$LogFile = $script:homeDir + "\Log\ProcessLog_{0}.txt" -f ($strToday) 
	$CsvFile = $script:downloadDir + "AdaptiveBudget_{0}.csv" -f ($strToday) 
	
	If (Test-Path $LogFile){
		Remove-Item $LogFile
	}

	If (Test-Path $CsvFile){
		Remove-Item $CsvFile
	}

	if ( $args.Length -lt 6 )
	{
		write-host ""
		write-host "        Usage: "
		write-host "               GetAdaptiveBudget.ps1 /u APUserName /p APPassword /i APInstance [/d]" -ForegroundColor Red
		write-host ""
	}
	else
	{
		for ( $i = 0; $i -lt $args.count; $i++ ) {
			if ($args[ $i ] -eq "/u"){ $username = $args[ $i + 1 ]}
			if ($args[ $i ] -eq "-u"){ $username = $args[ $i + 1 ]}
			if ($args[ $i ] -eq "/p"){ $password = $args[ $i + 1 ]}
			if ($args[ $i ] -eq "-p"){ $password = $args[ $i + 1 ]} 
			if ($args[ $i ] -eq "/i"){ $instance = $args[ $i + 1 ]}
			if ($args[ $i ] -eq "-i"){ $instance = $args[ $i + 1 ]} 
			if ($args[ $i ] -eq "/d"){ 
				$script:AdaptiveAPI = "https://test.adaptiveplanning.com/api/v7"; 
			} 
			if ($args[ $i ] -eq "-d"){ 
				$script:AdaptiveAPI = "https://test.adaptiveplanning.com/api/v7"; 
			} 
		}

		LogWrite($script:compname)| Write-Host
		LogWrite($script:homeDir)| Write-Host
		LogWrite($myInvocation.MyCommand.Definition)| Write-Host
		LogWrite($script:AdaptiveAPI)| Write-Host
		LogWrite($instance)| Write-Host
		LogWrite($LogFile)| Write-Host
		LogWrite($CsvFile)| Write-Host

		LogWrite(("-" * 100))| Write-Host 
		LogWrite("Start ==>" + (Get-Date).ToLongDateString() )| Write-Host -ForegroundColor GREEN
		LogWrite(("-" * 100))| Write-Host

		$ok = exportBudgetData -Login $username -Password $password -Instance $instance -BudgetVersion $BudgetVersion -Year $Year

		LogWrite(("-" * 100)) | Write-Host
		LogWrite("End ==>" + (Get-Date).ToLongDateString() ) | Write-Host -ForegroundColor GREEN 

	}
}
catch [Exception] {
	Write-Host LogWrite($_.Exception.Message_)
	Write-Host LogWrite("Caught an exception:") -ForegroundColor Red
	write-host LogWrite("Exception Type: $($_.Exception.GetType().FullName)") -ForegroundColor Red
	write-host LogWrite("Exception Message: $($_.Exception.Message)") -ForegroundColor Red

	exit 1
}
finally {

	doEmail
	
	exit 0
}

# SIG # Begin signature block
# MIITrgYJKoZIhvcNAQcCoIITnzCCE5sCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjFwWC3b8lo0iOTOA64LrksEZ
# DgGggg36MIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFG4CirvbAeRqyIXC
# AFFk+W04zT5SMA0GCSqGSIb3DQEBAQUABIIBAJLEh8fbmrpJJL/tuEH362OkIQuf
# dQPcbbMdK8rl0QML8cHKK2maLX3Ma8R3cLtB0GYROkmYv/IsK62VEkQJgScnaxXX
# 0kDRRQGFxUmS3dX/Cxj6lJC+5JCI5ytvfzC20L/wRHHCX1+FDi8bQb+XZG30GbNr
# 59x6FzmFsL4MsRWn8dDcHYenYkmerKz7ocwmxUAt7mWYDK8uLsJoyQBaJ4MMGMiM
# Uup7xCtvwpxAMnn0+zX6imZpuar0YAJLGmOJnDrCt9kTL0PD7y1KPyIUS4uAwlMs
# aqnUdu6qwvW5/s+x+cqXNtsezPO8t2EoX0maCThzxsJkEHs/BwMojS3VbLOhggKi
# MIICngYJKoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZMBcG
# A1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1l
# c3RhbXBpbmcgQ0EgLSBHMgISESFAXB8O0liIK+VNhoa6EepFMAkGBSsOAwIaBQCg
# gf0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTQw
# NjE4MTcyOTI0WjAjBgkqhkiG9w0BCQQxFgQU6Kr4aMj7VW4wdncq8gjAOkjgSQMw
# gZ0GCyqGSIb3DQEJEAIMMYGNMIGKMIGHMIGEBBSM5p9QEuHRqPs5Xi4x4rQr3js0
# OzBsMFakVDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1z
# YTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESFA
# XB8O0liIK+VNhoa6EepFMA0GCSqGSIb3DQEBAQUABIIBAEVPr7sXxcQ3vzzRzGqI
# fg02R+dxad1m1sxGUZLmd6TK6oJ/SQEZ6uWzIKvnbIT4Txd+xczOi8r5M6ZAY1KN
# wS34ntWFBng8oQ61B1dzWtaAgAcz5us5QjllFovEO7iRHArkcNX2qarkuoSRGAtg
# VmyZ743MUiArZUSLSOKfrlRLoVa95sfA/02YQPKjUzJz/HJpj5pQ9eoziI9RxWJ0
# hAlX4SDvSADBcDzznuXV9W4QX0jM2tPPTbtLQVsK4h3b+gyJfUs6GN1G9gzJE7zZ
# /tFVYjmUNcfilMhx1oX9onbELAuuHz1Zzbz/WvriwKfyLLLc2fuNQqgzq7UN7FFb
# ij0=
# SIG # End signature block
