[System.AppDomain]::CurrentDomain.GetAssemblies() | Out-File C:\Temp\Assem.txt

[System.Reflection.Assembly]::LoadFrom("C:\Program Files (x86)\IBM\Client Access\IBM.Data.DB2.iSeries.dll") | Out-Null

function ExportData {
	Param (
		[string]$ServerName
	,	[string]$Login
	,	[string]$Password
	,	[int]$WeekEnding
	)

	LogWrite("Server:      {0}" -f $ServerName)| Write-Host
	LogWrite("Week Ending: {0}" -f $WeekEnding)| Write-Host
	
	$ConnectionString="DataSource={0};UserID={1};Password={2};DataCompression=True;" -f  $ServerName,$Login, $Password
	$SqlQuery="select * from CMSFIL.PRPTCH where CHDTWE={0}" -f $WeekEnding
	LogWrite("SQL:         {0}" -f $SqlQuery)| Write-Host
	LogWrite("Connection:  {0}" -f $ConnectionString)| Write-Host
	
	try	{
		$SqlConnection = New-Object IBM.Data.DB2.iSeries.iDB2Connection;
		$SqlConnection.ConnectionString="DataSource={0};UserID={1};Password={2};DataCompression=True;" -f  $ServerName,$Login, $Password
		#$SqlConnection.ConnectionString = "Data Source={0};Initial Catalog=$Database;UID={1};Password={2}" -f $ServerName,$Login, $Password
		$SqlCmd = New-Object IBM.Data.DB2.iSeries.iDB2Command
		$SqlCmd.CommandText = $SqlQuery
		$SqlCmd.Connection = $SqlConnection
		$SqlAdapter = New-Object IBM.Data.DB2.iSeries.iDB2DataAdapter
		$SqlAdapter.SelectCommand = $SqlCmd
		$DataSet = New-Object System.Data.DataSet
		$nRecs = $SqlAdapter.Fill($DataSet)
		$nRecs | Out-Null
		
		LogWrite("Records:      {0}" -f $nRecs) | Write-Host
	
		$outFile = $script:downloadDir + "DataFile.csv"
		$objTable = $DataSet.Tables[0]
		#Export Hash Table to CSV File
		$objTable | Export-CSV $outFile -NoTypeInformation -Delimiter ","				
			
		#$SqlAdapter.Dispose();
		#$SqlCmd.Dispose();
		#$SqlConnection.Dispose();

		
	}
	catch [Exception] {
		LogWrite($_.Exception.Message_) | Write-Host
		LogWrite("Caught an exception:")  | Write-Host -ForegroundColor Red
		LogWrite("Exception Type: $($_.Exception.GetType().FullName)")  | Write-Host -ForegroundColor Red
		LogWrite("Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red
	}
	finally
	{
		if ($SqlConnection.State -eq [System.Data.ConnectionState]::ConnectionState.Open)
		{
            $SqlConnection.Close();
		}
		if ( !($SqlAdapter -eq $Null) )
		{
			$SqlAdapter.Dispose
        $SqlConnection.Dispose();
        $DataSet.Dispose();
	}
	
	
<#
	
	$curAttachmentPath1 = $AttachmentPath -f $WeekEnding,"PRPBCH"
	$curAttachmentPath2 = $AttachmentPath -f $WeekEnding,"PRPBCI"
	$curAttachmentPath3 = $AttachmentPath -f $WeekEnding,"PRPIND"
	
	#LogWrite($curAttachmentPath)
	
	$SqlQuery = "exec mspGetCGCPayrollBatch @WeekEnding=" + $WeekEnding.ToString()
				
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "Data Source=$Server;Initial Catalog=$Database;Integrated Security = True"
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = $SqlQuery
	$SqlCmd.Connection = $SqlConnection
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCmd
	$DataSet = New-Object System.Data.DataSet
	$nRecs = $SqlAdapter.Fill($DataSet)
	$nRecs | Out-Null
	
	#Populate Hash Table
	$objPRPBCHTable = $DataSet.Tables[0]
	$objPRPBCITable = $DataSet.Tables[1]
	$objPRPINDTable = $DataSet.Tables[2]

	LogWrite("** CGC Payroll Batch Export PRPBCH """ + $SqlQuery + """ (" + $DataSet.Tables[0].Rows.Count + " records)")
	LogWrite("`tto " + $curAttachmentPath1)
	LogWrite("** CGC Payroll Batch Export PRPBCI """ + $SqlQuery + """ (" + $DataSet.Tables[1].Rows.Count + " records)")
	LogWrite("`tto " + $curAttachmentPath2)
	LogWrite("** CGC Payroll Batch Export PRPIND """ + $SqlQuery + """ (" + $DataSet.Tables[2].Rows.Count + " records)")
	LogWrite("`tto " + $curAttachmentPath3)

	#Export Hash Table to CSV File
	$objPRPBCHTable | Export-CSV $curAttachmentPath1 -NoTypeInformation -Delimiter ","				
	$objPRPBCITable | Export-CSV $curAttachmentPath2 -NoTypeInformation -Delimiter ","	
	$objPRPINDTable | Export-CSV $curAttachmentPath3 -NoTypeInformation -Delimiter ","	
	
	updateEmail $curAttachmentPath1 $DataSet.Tables[0].Rows.Count
	updateEmail $curAttachmentPath2 $DataSet.Tables[1].Rows.Count
	updateEmail $curAttachmentPath3 $DataSet.Tables[2].Rows.Count

#>
}

Function LogWrite {
   Param ([string]$logstring)
  
   $ts = (Get-Date).ToLongTimeString() + "`t" + $logstring
   Add-content $Logfile -value $ts
   return $ts   
}

#Main Application
try {
	#cls
	
	# Production Site Default
	$script:compname = gc env:computername
	$script:homeDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
	$script:downloadDir = $script:homeDir + "\Download\" 
	$strToday = (Get-Date -format "yyyyMMdd")
	$script:fileSuffix = $strToday
	$script:logFile = $script:homeDir + "\Log\ProcessLog_{0}.txt" -f ($script:fileSuffix)	
	
	If (Test-Path $script:logFile){
    	Remove-Item $script:logFile
    }
	
	$serverName="S1017192.mckinstry.com"
	
	$Logfile = $script:logFile

	if ($env:Processor_Architecture -ne "x86")   
	{ LogWrite('Launching x86 PowerShell') | write-warning
		&"$env:windir\syswow64\windowspowershell\v1.0\powershell.exe" -noninteractive -noprofile -file $myinvocation.Mycommand.path $args -executionpolicy bypass
	exit
	}
	
	"Always running in 32bit PowerShell at this point."
	$env:Processor_Architecture
	[IntPtr]::Size

	LogWrite($script:compname)| Write-Host
	LogWrite($script:homeDir)| Write-Host
	LogWrite($myInvocation.MyCommand.Definition)| Write-Host
	LogWrite($serverName)| Write-Host
	LogWrite($script:logFile)| Write-Host
	
	LogWrite(("-" * 100))| Write-Host	
    LogWrite("Start ==>" + (Get-Date).ToLongDateString() )| Write-Host -ForegroundColor GREEN
	LogWrite(("-" * 100))| Write-Host
	

	
	if ( $args.Length -lt 4 )
	{
		write-host ""
		write-host "        Usage: "
		write-host "               DataExtractTemplate.ps1 /u APUserName /p APPassword [/d]" -ForegroundColor Red
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
	
		$ok = ExportData -ServerName $serverName -Login $username -Password $password -WeekEnding 20140420
		LogWrite(("-" * 100)) | Write-Host
		LogWrite("End ==>" + (Get-Date).ToLongDateString() ) | Write-Host -ForegroundColor GREEN

	}
}
catch [Exception] {
	LogWrite($_.Exception.Message_) | Write-Host
	LogWrite("Caught an exception:")  | Write-Host -ForegroundColor Red
	LogWrite("Exception Type: $($_.Exception.GetType().FullName)")  | Write-Host -ForegroundColor Red
	LogWrite("Exception Message: $($_.Exception.Message)") | Write-Host -ForegroundColor Red
}