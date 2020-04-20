##  Command Line Args:  /u billo@mckinstry.com /p <password> /d
#https://live.adaptiveplanning.com/api/v7


function exportAccounts {
	Param (
		[string]$Login
		, [string]$Password
	)

	try {

		LogWrite( $script:AdaptiveAPI + " [" + $Login + ":" + $Password + "]" ) | Write-Host
		$apiCommand = "<?xml version='1.0' encoding='UTF-8'?>";
		$apiCommand += "<call method='exportAccounts'>";
		$apiCommand += "<credentials login='$Login' password='$Password'/>";
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

		#ServiceNow has a hard limit of 250 records returned.
		$xd.loadXML($http_request.responseXML.xml);

		[System.Xml.XmlElement]$parentnodelist = $xd.selectsinglenode("/response/output/accounts") # XPath is case sensitive

		$strToLog = "Parsing " + $parentnodelist.ChildNodes.Count + " records from AdaptivePlanning (" + $url + ")`n"
		LogWrite( $strToLog ) | Write-Host
		$rcnt = 0

		$strToLog = "Level" + ((" " * (10 - "Level".length)))
		$strToLog += "SubLevel" + ((" " * (10 - "SubLevel".length)))
		$strToLog += "ID" + ((" " * (10 - "ID".length)))
		$strToLog += "ParentID" + ((" " * (10 - "ParentID".length)))
		$strToLog += "Code" + ((" " * (50 - "Code".length)))
		$strToLog += "Name" + ((" " * (50 - "Name".length)))
		LogWrite( $strToLog ) | Write-Host

		EnumNode -node $parentnodelist -level 0 
	}
	catch [Exception] {
		LogWrite( $_.Exception.Message ) | Write-Host
		LogWrite( "Caught an exception:") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Type: $($_.Exception.GetType().FullName)") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red 
	}


}

function exportLevels {
	Param (
		[string]$Login
		, [string]$Password
	)

	try {

		LogWrite( $script:AdaptiveAPI + " [" + $Login + ":" + $Password + "]" ) | Write-Host
		$apiCommand = "<?xml version='1.0' encoding='UTF-8'?>";
		$apiCommand += "<call method='exportLevels'>";
		$apiCommand += "<credentials login='$Login' password='$Password'/>";
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

		#ServiceNow has a hard limit of 250 records returned.
		$xd.loadXML($http_request.responseXML.xml);

		[System.Xml.XmlElement]$parentnodelist = $xd.selectsinglenode("/response/output/levels") # XPath is case sensitive

		$strToLog = "Parsing " + $parentnodelist.ChildNodes.Count + " records from AdaptivePlanning (" + $url + ")`n"
		LogWrite( $strToLog ) | Write-Host
		$rcnt = 0

		$strToLog = "Level" + ((" " * (10 - "Level".length)))
		$strToLog += "SubLevel" + ((" " * (10 - "SubLevel".length)))
		$strToLog += "ID" + ((" " * (10 - "ID".length)))
		$strToLog += "ParentID" + ((" " * (10 - "ParentID".length)))
		$strToLog += "Code" + ((" " * (50 - "Code".length)))
		$strToLog += "Name" + ((" " * (50 - "Name".length)))
		$strToLog += "Abbr" + ((" " * (30 - "abbr".length)))
		LogWrite( $strToLog ) | Write-Host

		EnumNode -node $parentnodelist -level 0 
	}
	catch [Exception] {
		LogWrite( $_.Exception.Message ) | Write-Host
		LogWrite( "Caught an exception:") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Type: $($_.Exception.GetType().FullName)") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red 
	}


}

function exportVersions {
	Param (
		[string]$Login
		, [string]$Password
	)

	try {

		LogWrite( $script:AdaptiveAPI + " [" + $Login + ":" + $Password + "]" ) | Write-Host
		$apiCommand = "<?xml version='1.0' encoding='UTF-8'?>";
		$apiCommand += "<call method='exportVersions'>";
		$apiCommand += "<credentials login='$Login' password='$Password'/>";
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

		#ServiceNow has a hard limit of 250 records returned.
		$xd.loadXML($http_request.responseXML.xml);

		[System.Xml.XmlElement]$parentnodelist = $xd.selectsinglenode("/response/output/versions") # XPath is case sensitive

		$strToLog = "Parsing " + $parentnodelist.ChildNodes.Count + " records from AdaptivePlanning (" + $url + ")`n"
		LogWrite( $strToLog ) | Write-Host
		$rcnt = 0

		$strToLog = "Level" + ((" " * (10 - "Level".length)))
		$strToLog += "SubLevel" + ((" " * (10 - "SubLevel".length)))
		$strToLog += "ID" + ((" " * (10 - "ID".length)))
		$strToLog += "ParentID" + ((" " * (10 - "ParentID".length)))
		$strToLog += "Code" + ((" " * (50 - "Code".length)))
		$strToLog += "Name" + ((" " * (50 - "Name".length)))
		LogWrite( $strToLog ) | Write-Host

		EnumNode -node $parentnodelist -level 0 
	}
	catch [Exception] {
		LogWrite( $_.Exception.Message ) | Write-Host
		LogWrite( "Caught an exception:") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Type: $($_.Exception.GetType().FullName)") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red 
	}


}

function exportDimensions {
	Param (
		[string]$Login
		, [string]$Password
	)

	try {

		LogWrite( $script:AdaptiveAPI + " [" + $Login + ":" + $Password + "]" ) | Write-Host
		$apiCommand = "<?xml version='1.0' encoding='UTF-8'?>";
		$apiCommand += "<call method='exportDimensions'>";
		$apiCommand += "<credentials login='$Login' password='$Password'/>";
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

		#ServiceNow has a hard limit of 250 records returned.
		$xd.loadXML($http_request.responseXML.xml);

		[System.Xml.XmlElement]$parentnodelist = $xd.selectsinglenode("/response/output/dimensions") # XPath is case sensitive

		$strToLog = "Parsing " + $parentnodelist.ChildNodes.Count + " records from AdaptivePlanning (" + $url + ")`n"
		LogWrite( $strToLog ) | Write-Host
		$rcnt = 0

		$strToLog = "Level" + ((" " * (10 - "Level".length)))
		$strToLog += "SubLevel" + ((" " * (10 - "SubLevel".length)))
		$strToLog += "ID" + ((" " * (10 - "ID".length)))
		$strToLog += "ParentID" + ((" " * (10 - "ParentID".length)))
		$strToLog += "Code" + ((" " * (50 - "Code".length)))
		$strToLog += "Name" + ((" " * (50 - "Name".length)))
		LogWrite( $strToLog ) | Write-Host

		EnumNode -node $parentnodelist -level 0 
	}
	catch [Exception] {
		LogWrite( $_.Exception.Message ) | Write-Host
		LogWrite( "Caught an exception:") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Type: $($_.Exception.GetType().FullName)") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red 
	}


}

function exportDimensionFamilies {
	Param (
		[string]$Login
		, [string]$Password
	)

	try {

		LogWrite( $script:AdaptiveAPI + " [" + $Login + ":" + $Password + "]" ) | Write-Host
		$apiCommand = "<?xml version='1.0' encoding='UTF-8'?>";
		$apiCommand += "<call method='exportDimensionFamilies'>";
		$apiCommand += "<credentials login='$Login' password='$Password'/>";
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

		#ServiceNow has a hard limit of 250 records returned.
		$xd.loadXML($http_request.responseXML.xml);

		[System.Xml.XmlElement]$parentnodelist = $xd.selectsinglenode("/response/output/families") # XPath is case sensitive

		$strToLog = "Parsing " + $parentnodelist.ChildNodes.Count + " records from AdaptivePlanning (" + $url + ")`n"
		LogWrite( $strToLog ) | Write-Host
		$rcnt = 0

		$strToLog = "Level" + ((" " * (10 - "Level".length)))
		$strToLog += "SubLevel" + ((" " * (10 - "SubLevel".length)))
		$strToLog += "ID" + ((" " * (10 - "ID".length)))
		$strToLog += "ParentID" + ((" " * (10 - "ParentID".length)))
		$strToLog += "Code" + ((" " * (50 - "Code".length)))
		$strToLog += "Name" + ((" " * (50 - "Name".length)))
		LogWrite( $strToLog ) | Write-Host

		EnumNode -node $parentnodelist -level 0 
	}
	catch [Exception] {
		LogWrite( $_.Exception.Message ) | Write-Host
		LogWrite( "Caught an exception:") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Type: $($_.Exception.GetType().FullName)") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red 
	}


}

function exportInstances {
	Param (
		[string]$Login
		, [string]$Password
	)

	try {

		LogWrite( $script:AdaptiveAPI + " [" + $Login + ":" + $Password + "]" ) | Write-Host
		$apiCommand = "<?xml version='1.0' encoding='UTF-8'?>";
		$apiCommand += "<call method='exportInstances'>";
		$apiCommand += "<credentials login='$Login' password='$Password'/>";
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

		#ServiceNow has a hard limit of 250 records returned.
		$xd.loadXML($http_request.responseXML.xml);

		[System.Xml.XmlElement]$parentnodelist = $xd.selectsinglenode("/response/output/instances") # XPath is case sensitive

		$strToLog = "Parsing " + $parentnodelist.ChildNodes.Count + " records from AdaptivePlanning (" + $url + ")`n"
		LogWrite( $strToLog ) | Write-Host
		$rcnt = 0

		$strToLog = "Level" + ((" " * (10 - "Level".length)))
		$strToLog += "SubLevel" + ((" " * (10 - "SubLevel".length)))
		$strToLog += "ID" + ((" " * (10 - "ID".length)))
		$strToLog += "ParentID" + ((" " * (10 - "ParentID".length)))
		$strToLog += "Code" + ((" " * (50 - "Code".length)))
		$strToLog += "Name" + ((" " * (50 - "Name".length)))
		LogWrite( $strToLog ) | Write-Host

		EnumNode -node $parentnodelist -level 0 
	}
	catch [Exception] {
		LogWrite( $_.Exception.Message ) | Write-Host
		LogWrite( "Caught an exception:") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Type: $($_.Exception.GetType().FullName)") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red 
	}


}

function exportPlans {
	Param (
		[string]$Login
		, [string]$Password
	)

	try {

		LogWrite( $script:AdaptiveAPI + " [" + $Login + ":" + $Password + "]" ) | Write-Host
		$apiCommand = "<?xml version='1.0' encoding='UTF-8'?>";
		$apiCommand += "<call method='exportPlans'>";
		$apiCommand += "<credentials login='$Login' password='$Password'/>";
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

		#ServiceNow has a hard limit of 250 records returned.
		$xd.loadXML($http_request.responseXML.xml);

		[System.Xml.XmlElement]$parentnodelist = $xd.selectsinglenode("/response/output/plans") # XPath is case sensitive

		$strToLog = "Parsing " + $parentnodelist.ChildNodes.Count + " records from AdaptivePlanning (" + $url + ")`n"
		LogWrite( $strToLog ) | Write-Host
		$rcnt = 0

		$strToLog = "Level" + ((" " * (10 - "Level".length)))
		$strToLog += "SubLevel" + ((" " * (10 - "SubLevel".length)))
		$strToLog += "ID" + ((" " * (10 - "ID".length)))
		$strToLog += "ParentID" + ((" " * (10 - "ParentID".length)))
		$strToLog += "Code" + ((" " * (50 - "Code".length)))
		$strToLog += "Name" + ((" " * (50 - "Name".length)))
		LogWrite( $strToLog ) | Write-Host

		EnumNode -node $parentnodelist -level 0 
	}
	catch [Exception] {
		LogWrite( $_.Exception.Message ) | Write-Host
		LogWrite( "Caught an exception:") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Type: $($_.Exception.GetType().FullName)") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red 
	}


}

function calcCompanyFromDept {
	Param (
		[string]$Department
	)
	$retCo = "1";

	switch ($Department) 
	{
		"0400" {$retCo = "20"} 
		"0401" {$retCo = "20"} 
		"0410" {$retCo = "20"} 
		"0412" {$retCo = "20"} 
		"0414" {$retCo = "20"} 
		"0420" {$retCo = "20"} 
		"0430" {$retCo = "20"} 
		"0432" {$retCo = "20"} 
		"0440" {$retCo = "20"} 
		"0442" {$retCo = "20"} 
		"0444" {$retCo = "20"} 
		"0450" {$retCo = "20"} 
		"0460" {$retCo = "20"} 
		"0501" {$retCo = "20"} 
		"0510" {$retCo = "20"} 
		"0511" {$retCo = "20"} 
		"0512" {$retCo = "20"} 
		"0520" {$retCo = "20"} 
		"0521" {$retCo = "20"} 
		"0523" {$retCo = "20"} 
		"0550" {$retCo = "20"} 
		"0810" {$retCo = "60"} 
		"0990" {$retCo = "3"} #???
		"0999" {$retCo = "4"} #???	
		default {$retCo = "1"}
	}

	return $retCo;

}

function exportData {
	Param (
		[string]$Login
		, [string]$Password
	)

	try {

		LogWrite( $script:AdaptiveAPI + " [" + $Login + ":" + $Password + "]" ) | Write-Host
		$apiCommand = "<?xml version='1.0' encoding='UTF-8'?>";
		$apiCommand += "<call method='exportData'>";
		$apiCommand += "<credentials login='$Login' password='$Password' instanceCode='MCKINSTRY2'/>";
		$apiCommand += "<version name='McKinstry Budget 2014' isDefault='false'/>";
		$apiCommand += "<format useInternalCodes='false' includeUnmappedItems='true'/>";
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
		$apiCommand += "<timeSpan start='Jan-2014' end='Dec-2014'/>";
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

		#ServiceNow has a hard limit of 250 records returned.
		$xd.loadXML($http_request.responseXML.xml);

		[System.Xml.XmlElement]$parentnodelist = $xd.selectsinglenode("/response/output") # XPath is case sensitive

		$strToLog = "Parsing " + $parentnodelist.ChildNodes.Count + " records from AdaptivePlanning (" + $url + ")`n"
		LogWrite( $strToLog ) | Write-Host
		$rcnt = 0

		$strData = $parentnodelist."#cdata-section";

		$stringArray = $strData.Split("`n") | % {$_.trim()}

		LogWrite("'GLCo','GLAcct','Mth','BudgetAmt','BudgetCode'") | Write-Host

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
				
				
				if ( IsNumeric($acct) -and IsNumeric($level) )
				{
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

					LogWrite("'{3}','{0}-000-{1}-','1/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$Jan,$_GLCo,$_BudgetCode) | Write-Host
					LogWrite("'{3}','{0}-000-{1}-','2/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$Feb,$_GLCo,$_BudgetCode) | Write-Host
					LogWrite("'{3}','{0}-000-{1}-','3/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$Mar,$_GLCo,$_BudgetCode) | Write-Host
					LogWrite("'{3}','{0}-000-{1}-','4/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$Apr,$_GLCo,$_BudgetCode) | Write-Host
					LogWrite("'{3}','{0}-000-{1}-','5/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$May,$_GLCo,$_BudgetCode) | Write-Host
					LogWrite("'{3}','{0}-000-{1}-','6/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$Jun,$_GLCo,$_BudgetCode) | Write-Host
					LogWrite("'{3}','{0}-000-{1}-','7/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$Jul,$_GLCo,$_BudgetCode) | Write-Host
					LogWrite("'{3}','{0}-000-{1}-','8/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$Aug,$_GLCo,$_BudgetCode) | Write-Host
					LogWrite("'{3}','{0}-000-{1}-','9/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$Sep,$_GLCo,$_BudgetCode) | Write-Host
					LogWrite("'{3}','{0}-000-{1}-','10/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$Oct,$_GLCo,$_BudgetCode) | Write-Host
					LogWrite("'{3}','{0}-000-{1}-','11/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$Nov,$_GLCo,$_BudgetCode) | Write-Host
					LogWrite("'{3}','{0}-000-{1}-','12/1/2014','{2:N2}','{4}'" -f $acct, $level, [decimal]$Dec,$_GLCo,$_BudgetCode) | Write-Host
				}
				<#
				else
				{
					for ( $di=0; $di -lt $DataArray.length; $di++ )
					{
						$dv = ($DataArray[$di].ToString() -replace '"','') -replace "=",""
						LogWrite("{0} = {1}" -f $HeaderArray[$di].ToString(), $dv) | Write-Host
					}
				}

#>
			}


		}





		#LogWrite( $strData ) | Write-Host
		#EnumDataNode -nodeList $parentnodelist -level 1

		<#
		$strToLog = "Level" + ((" " * (10-"Level".length)))
		$strToLog += "SubLevel" + ((" " * (10-"SubLevel".length)))
		$strToLog += "ID" + ((" " * (10-"ID".length)))
		$strToLog += "ParentID" + ((" " * (10-"ParentID".length)))
		$strToLog += "Code" + ((" " * (50-"Code".length)))
		$strToLog += "Name" + ((" " * (50-"Name".length)))
		LogWrite( $strToLog ) | Write-Host
		
		EnumNode -node $parentnodelist -level 0		

#>
	}
	catch [Exception] {
		LogWrite( $_.Exception.Message ) | Write-Host
		LogWrite( "Caught an exception:") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Type: $($_.Exception.GetType().FullName)") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red 
	}


}

function exportActiveCurrencies {
	Param (
		[string]$Login
		, [string]$Password
	)

	try {

		LogWrite( $script:AdaptiveAPI + " [" + $Login + ":" + $Password + "]" ) | Write-Host
		$apiCommand = "<?xml version='1.0' encoding='UTF-8'?>";
		$apiCommand += "<call method='exportActiveCurrencies'>";
		$apiCommand += "<credentials login='$Login' password='$Password'/>";
		$apiCommand += "<include ownedLevels='true' hiddenVersions='false'/>";
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

		#ServiceNow has a hard limit of 250 records returned.
		$xd.loadXML($http_request.responseXML.xml);

		[System.Xml.XmlElement]$parentnodelist = $xd.selectsinglenode("/response/output/currencies") # XPath is case sensitive

		$strToLog = "Parsing " + $parentnodelist.ChildNodes.Count + " records from AdaptivePlanning (" + $url + ")`n"
		LogWrite( $strToLog ) | Write-Host
		$rcnt = 0

		$strToLog = "Level" + ((" " * (10 - "Level".length)))
		$strToLog += "SubLevel" + ((" " * (10 - "SubLevel".length)))
		$strToLog += "ID" + ((" " * (10 - "ID".length)))
		$strToLog += "ParentID" + ((" " * (10 - "ParentID".length)))
		$strToLog += "Code" + ((" " * (50 - "Code".length)))
		$strToLog += "Name" + ((" " * (50 - "Name".length)))
		LogWrite( $strToLog ) | Write-Host

		EnumNode -node $parentnodelist -level 0 
	}
	catch [Exception] {
		LogWrite( $_.Exception.Message ) | Write-Host
		LogWrite( "Caught an exception:") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Type: $($_.Exception.GetType().FullName)") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red 
	}


}

function exportUsers {
	Param (
		[string]$Login
		, [string]$Password
	)

	try {

		LogWrite( $script:AdaptiveAPI + " [" + $Login + ":" + $Password + "]" ) | Write-Host
		$apiCommand = "<?xml version='1.0' encoding='UTF-8'?>";
		$apiCommand += "<call method='exportUsers'>";
		$apiCommand += "<credentials login='$Login' password='$Password'/>";
		$apiCommand += "<include ownedLevels='true' hiddenVersions='false'/>";
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

		#ServiceNow has a hard limit of 250 records returned.
		$xd.loadXML($http_request.responseXML.xml);

		[System.Xml.XmlElement]$parentnodelist = $xd.selectsinglenode("/response/output/users") # XPath is case sensitive

		$strToLog = "Parsing " + $parentnodelist.ChildNodes.Count + " records from AdaptivePlanning (" + $url + ")`n"
		LogWrite( $strToLog ) | Write-Host
		$rcnt = 0

		$strToLog = "Level" + ((" " * (10 - "Level".length)))
		$strToLog += "SubLevel" + ((" " * (10 - "SubLevel".length)))
		$strToLog += "ID" + ((" " * (10 - "ID".length)))
		$strToLog += "ParentID" + ((" " * (10 - "ParentID".length)))
		$strToLog += "Code" + ((" " * (50 - "Code".length)))
		$strToLog += "Name" + ((" " * (50 - "Name".length)))
		LogWrite( $strToLog ) | Write-Host

		EnumNode -node $parentnodelist -level 0 
	}
	catch [Exception] {
		LogWrite( $_.Exception.Message ) | Write-Host
		LogWrite( "Caught an exception:") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Type: $($_.Exception.GetType().FullName)") | Write-Host -ForegroundColor Red 
		LogWrite( "Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red 
	}


}

function EnumNode { 

	Param (
		[System.Xml.XmlElement]$nodeList
		, [int]$level
	)

	$Local:level = $level;

	$rcnt = $rcnt + 1

	$Local:nodeList = $nodeList; 

	foreach ($Local:testCaseNode in $Local:nodeList.ChildNodes) { 

		$Local:level = $Local:level + 1
		$id_Value = $Local:testCaseNode.getAttribute("id");
		$code_Value = $Local:testCaseNode.getAttribute("code");
		$name_Value = $Local:testCaseNode.getAttribute("name");
		if ( $name_Value -eq "001 IT Support" )
		{
			Write-Host "Here"
		}
		$abbr_Value = $Local:testCaseNode.getAttribute("abbr");

		$parent_id_Value = $Local:testCaseNode.ParentNode.getAttribute("id");
		if ( $parent_id_Value -eq "" ) { $parent_id_Value = "Root" } 

		$strToLog = $rcnt.ToString() + ((" " * (10 - $rcnt.ToString().length)))
		$strToLog += $Local:level.ToString() + ((" " * (10 - $Local:level.ToString().length)))
		$strToLog += $id_Value + ((" " * (10 - $id_Value.length)))
		$strToLog += $parent_id_Value + ((" " * (10 - $parent_id_Value.length)))
		$strToLog += $code_Value + ((" " * (50 - $code_Value.length)))
		$strToLog += $name_Value + ((" " * (50 - $name_Value.length)))
		$strToLog += $abbr_Value + ((" " * (30 - $abbr_Value.length)))
		LogWrite( $strToLog )| Write-Host

		if ( $Local:testCaseNode.HasChildNodes -eq "True" )
		{
			#$script:currentNode=$testCaseNode
			EnumNode -node $Local:testCaseNode -level $Local:level
		}
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

function EnumDataNode { 

	Param (
		[System.Xml.XmlElement]$nodeList
		, [int]$level
	)

	$Local:level = $level;

	$rcnt = $rcnt + 1

	$Local:nodeList = $nodeList; 

	foreach ($Local:testCaseNode in $Local:nodeList.ChildNodes) { 

		$Local:level = $Local:level + 1
		$id_Value = $Local:testCaseNode.getAttribute("id");
		$code_Value = $Local:testCaseNode.getAttribute("code");
		$name_Value = $Local:testCaseNode.getAttribute("name");
		if ( $name_Value -eq "001 IT Support" )
		{
			Write-Host "Here"
		}
		$abbr_Value = $Local:testCaseNode.getAttribute("abbr");

		$parent_id_Value = $Local:testCaseNode.ParentNode.getAttribute("id");
		if ( $parent_id_Value -eq "" ) { $parent_id_Value = "Root" } 

		<#
			if ( isNumeric($id_Value) -and isNumeric($code_Value) )
			{
				$strGLAccount="{0}-000-{1}-" -f $id_Value, $code_Value
				LogWrite( $strToLog )| Write-Host
			}

#>

		$strToLog = $rcnt.ToString() + ((" " * (10 - $rcnt.ToString().length)))
		$strToLog += $Local:level.ToString() + ((" " * (10 - $Local:level.ToString().length)))
		$strToLog += $id_Value + ((" " * (10 - $id_Value.length)))
		$strToLog += $parent_id_Value + ((" " * (10 - $parent_id_Value.length)))
		$strToLog += $code_Value + ((" " * (50 - $code_Value.length)))
		$strToLog += $name_Value + ((" " * (50 - $name_Value.length)))
		$strToLog += $abbr_Value + ((" " * (30 - $abbr_Value.length)))
		LogWrite( $strToLog )| Write-Host

		if ( $Local:testCaseNode.HasChildNodes -eq "True" )
		{
			#$script:currentNode=$testCaseNode
			EnumNode -node $Local:testCaseNode -level $Local:level
		}
	}
}

Function LogWrite {
	Param ([string]$logstring)

	$ts = (Get-Date).ToLongTimeString() + "`t" + $logstring
	Add-content $Logfile -value $ts
	return $ts


}

#Main Application
try {
	cls

	# Production Site Default
	$script:compname = gc env:computername
	$script:homeDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
	$script:downloadDir = $script:homeDir + "\APDownloads\" 
	$script:AdaptiveAPI = "https://live.adaptiveplanning.com/api/v7";
	$strToday = (Get-Date -format "yyyyMMdd")
	$script:fileSuffix = $strToday
	$script:logFile = $script:homeDir + "\Log\ProcessLog_{0}.txt" -f ($script:fileSuffix) 

	If (Test-Path $script:logFile){
		Remove-Item $script:logFile
	}

	$Logfile = $script:logFile

	if ( $args.Length -lt 4 )
	{
		write-host ""
		write-host "        Usage: "
		write-host "               GetAdaptiveBudget.ps1 /u APUserName /p APPassword [/d]" -ForegroundColor Red
		write-host ""
	}
	else
	{
		for ( $i = 0; $i -lt $args.count; $i++ ) {
			if ($args[ $i ] -eq "/u"){ $username = $args[ $i + 1 ]}
			if ($args[ $i ] -eq "-u"){ $username = $args[ $i + 1 ]}
			if ($args[ $i ] -eq "/p"){ $password = $args[ $i + 1 ]}
			if ($args[ $i ] -eq "-p"){ $password = $args[ $i + 1 ]} 
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
		LogWrite($script:logFile)| Write-Host

		LogWrite(("-" * 100))| Write-Host 
		LogWrite("Start ==>" + (Get-Date).ToLongDateString() )| Write-Host -ForegroundColor GREEN
		LogWrite(("-" * 100))| Write-Host

		##$ok = exportAccounts -Login $username -Password $password
		##$ok = exportLevels -Login $username -Password $password
		##$ok = exportVersions -Login $username -Password $password

		#Discontinued
		#$ok = exportPlans -Login $username -Password $password
		##$ok = exportDimensions -Login $username -Password $password
		##$ok = exportDimensionFamilies -Login $username -Password $password
		##$ok = exportInstances -Login $username -Password $password
		##$ok = exportActiveCurrencies -Login $username -Password $password
		$ok = exportData -Login $username -Password $password
		#Requires Admin Rights
		#$ok = exportUsers -Login $username -Password $password

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


	exit 0
}