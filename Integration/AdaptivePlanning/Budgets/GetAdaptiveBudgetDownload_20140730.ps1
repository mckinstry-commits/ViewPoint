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
		#LogWrite(CsvWrite("`"GLCo`",`"GLAcct`",`"Mth`",`"BudgetAmt`",`"BudgetCode`"")) | Write-Host

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
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`1/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$Jan,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`2/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$Feb,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`3/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$Mar,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`4/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$Apr,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`5/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$May,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`6/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$Jun,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`7/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$Jul,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`8/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$Aug,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`9/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$Sep,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`10/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$Oct,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`11/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$Nov,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
					LogWrite(CsvWrite("`{3}`,`{0}-000-{1}-    `,`12/1/{5}`,`{2:f2}`,{4}" -f $acct, $level, [decimal]$Dec,$_GLCo,$_BudgetCode,$strYear)) | Write-Host
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
	#$script:downloadDir = $script:homeDir + "\APDownloads\" 
	$script:downloadDir = "\\sestgviewpoint\Viewpoint Repository\bulk inserts\ETL\GL\AdaptivePlanning\AutoImport\" 
	$script:AdaptiveAPI = "https://live.adaptiveplanning.com/api/v7";
	$instance = "MCKINSTRY2"
	$strYear = (Get-Date -format "yyyy")
	$Year = $strYear #"2014"
	$strToday = (Get-Date -format "yyyyMMdd")
	
	$BudgetVersion =  'McKinstry Budget ' + $strYear
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

