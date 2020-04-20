<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.165
	 Created on:   	7/24/2019 7:28 AM
	 Created by:   	Bill Orebaugh
	 Organization: 	McKinstry
	 Filename:     	VistaScrub.ps1
	===========================================================================
	.DESCRIPTION
		Script to be run against various Viewpoint database to "scrub" sensative 
		information or set emails to "test" email addresses so uses, customers 
		and partners to not receive non-production email.


	#TODO:  Add conditional logic to determine which udpates should be run on
			which databases.  Each environment may have unique requirements
			so flags are needed to indicate what is run on which system.
			Could be a configuration file managed set of rules.  For
			each environment, a list of fields to "scrub" with appropriate values
			could allow this to read the list and loop through the valid items.
			This would make the script much more utilitarian.

#>

Param (
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ConfigFile = ".\MCKTESTSQL05_Viewpoint_Settings.xml",
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$SMTPUser = "billo@mckinstry.com",
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$SMTPPassword,
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[boolean]$Evaluate = $true
)

# NOTE:  Setting the $Evaluate to $true (the default) will produce a log file and email of what is planned to be run,
#        without actually performing any data modification.  To actuall perform updates, the $Evaluate parameter
#        must be set to $false.

<#
TODO:
	Uncomment actual update/execute statements and actually test against a valid Viewpoint database.
#>

# Check to ensure specified configuration file exists.
if ( -not (Test-Path -Path $ConfigFile))
{
	throw ('Configuration File {0} does not exist' -f $ConfigFile)
}

# Simple function to force console output size.
if ($Host -and $Host.UI -and $Host.UI.RawUI)
{
	$rawUI = $Host.UI.RawUI
	$oldSize = $rawUI.BufferSize
	$typeName = $oldSize.GetType().FullName
	$newSize = New-Object $typeName (500, $oldSize.Height)
	$rawUI.BufferSize = $newSize
}

#Set initial Script Variables
$ComputerName = gc env:computername
$HomeDir = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
$ThisScript = [System.IO.Path]::GetFileName($MyInvocation.MyCommand.Definition)
$curDateTime = Get-Date -Format "yyyyMMdd_hhmmss"
$LogFile = "{0}\{1}" -f $HomeDir, ($ThisScript -replace ".ps1", ("_Log_{0}.txt" -f $curDateTime))
$global:mailBody = ""

# Utility Function to record activity to a log file that is emailed to a configured list of users.
function LogWrite
{
	Param ([string]$logstring)
	
	$ts = (Get-Date).ToLongTimeString() + "`t" + $logstring
	Add-Content $LogFile -Value $ts
	Write-Host $logstring
	
}

# Utility funciton to run and log various Table/Field scrub updates to a provided Value. Use by reading table,
# field and value from specified configuration file and using those values to call this funciton.
function ScrubTableField
{
	param
	(
		[Parameter(Mandatory = $true)]
		[System.String]$TableName,
		[Parameter(Mandatory = $true)]
		[System.String]$FieldName,
		[Parameter(Mandatory = $true)]
		[System.String]$FieldValue
	)
	try
	{
		$rowsReturned = (invoke-sqlcmd -server $global:sqlServer -Database $global:sqlDatabase  ("select count(*) as RCnt from [{0}] where [{1}] <> {2}" -f $TableName, $FieldName, $FieldValue)).Rcnt
		LogWrite -logstring ("[{0}].[{1}] Rows to be updated to {2} : {3}" -f $TableName, $FieldName, $FieldValue, $rowsReturned)
		LogWrite -logstring ("`t {0}" -f ("select count(*) as RCnt from [{0}] where [{1}] <> {2}" -f $TableName, $FieldName, $FieldValue))
		$global:mailBody = $global:mailBody + ("`r`n * [{0}].[{1}] Rows to be updated to {2} : {3}" -f $TableName, $FieldName, $FieldValue, $rowsReturned)
		
		if (($Evaluate -eq $false) -and ($rowsReturned -gt 0))
		{
			
			LogWrite -logstring "`t***** Perform Update !!! ******"
			LogWrite -logstring ("`tupdate [{0}] set {1}={2} where {3}<>{4}" -f $TableName, $FieldName, $FieldValue, $FieldName, $FieldValue)
			
			<# 2019.07.27 - LWO Uncomment when read to actually do data updates #>
			$global:dbCmd.CommandText = ("update [{0}] set {1}={2} where {3}<>{4}" -f $TableName, $FieldName, $FieldValue, $FieldName, $FieldValue)
			$rows_affected = $global:dbCmd.ExecuteNonQuery()
			LogWrite -logstring ("[{0}].[{1}] Rows UPDATED to {2} : {3}" -f $TableName, $FieldName, $FieldValue, $rows_affected)
						
		}
	}
	catch
	{
		LogWrite(("ERROR Resetting {0}.{1}'" -f $TableName, $FieldName))
		$global:mailBody = $global:mailBody + ("`r`nERROR Resetting [{0}].[{1}]" -f $TableName, $FieldName)
		LogWrite($_.Exception.Message)
		$global:mailBody = $global:mailBody + ("`r`n`t{0}" -f $_.Exception.Message)
	}
	
}

# Utility funciton to run and log specified SQL statements.  Used for configured PRE and POST steps in 
# specified configuration file.
function DoSQLTask
{
	param
	(
		[Parameter(Mandatory = $true)]
		[System.String]$SQLStatement
	)
	
	try
	{
		LogWrite -logstring ("Execute : {0}" -f $SQLStatement)
		$global:mailBody = $global:mailBody + ("`r`n * '{0}' Executed" -f $SQLStatement)
		
		if ( $Evaluate -eq $false )
		{
			
			LogWrite -logstring "`t***** Run SQL Task !!! ******"
			LogWrite -logstring ("`t{0}" -f $SQLStatement)
			
			<# 2019.07.27 - LWO Uncomment when read to actually do data updates #>
			$global:dbCmd.CommandText = ("{0}" -f $SQLStatement)
            
            #PAK
            $global:dbCmd.CommandTimeout = 240

			$rows_affected = $global:dbCmd.ExecuteNonQuery()
			LogWrite -logstring ("{0}" -f $rows_affected)
			
		}
	}
	catch
	{
		LogWrite(("ERROR Resetting {0}.{1}'" -f $TableName, $FieldName))
		$global:mailBody = $global:mailBody + ("`r`nERROR Resetting [{0}].[{1}]" -f $TableName, $FieldName)
		LogWrite($_.Exception.Message)
		$global:mailBody = $global:mailBody + ("`r`n`t{0}" -f $_.Exception.Message)
	}
	
}

LogWrite -logstring ("Run From: {0}" -f $ComputerName)
LogWrite -logstring ("Directory: {0}" -f $HomeDir)
LogWrite -logstring ("Script File: {0}" -f $ThisScript)
LogWrite -logstring ("Log File: {0}" -f $LogFile)
LogWrite -logstring ("Vista Environment: {0} = {1}" -f $VistaEnvironment, $sqlServer)
LogWrite -logstring "========================================================================================================================================="

# Read configuration file for runtime parameters
[xml]$Configuration = Get-Content "$HomeDir\$ConfigFile"

# Set email parameters from configuration file.
$mailServer = $Configuration.Settings.EmailSettings.SMTPServer
$mailPort = $Configuration.Settings.EmailSettings.SMTPPort
$mailFrom = $Configuration.Settings.EmailSettings.MailFrom
$mailTo = $Configuration.Settings.EmailSettings.MailTo.Recipient

# Enumerate all "Environments" defined in provided configuration file.
$Configuration.Settings.VistaEnvironments.Environment | ft -AutoSize


# Read Envornments and Scrub Details from Config File
# Configuration file can provide 1->N Environments, 0->N Pre/Post steps per environment
# and 1->N ScrubFields per environment.
foreach ($ve in $Configuration.Settings.VistaEnvironments.Environment)
{
	# Set Name and SQL Server/Database for current environment
	$global:VistaEnvironment = $ve.Name
	$global:sqlServer = $ve.SQLServer
	$global:sqlDatabase = $ve.Database
	
	# Compose beginning of email message body
	$global:mailBody = $global:mailBody + ("`r`nVista Environment: {0}" -f $global:VistaEnvironment)
	$global:mailBody = $global:mailBody + ("`r`nSQL Server: {0}" -f $global:sqlServer)
	$global:mailBody = $global:mailBody + ("`r`nSQL Database: {0}" -f $global:sqlDatabase)
	$global:mailBody = $global:mailBody + ("`r`n{0}" -f "=========================================================================================================================================")
	
	# Initialize a connection to the specified SQL Server/Database
	try
	{
		$global:dbConn = New-Object System.Data.SQLClient.SqlConnection ("Persist Security Info=False;Integrated Security=true;Initial Catalog={1};server={0}" -f $global:sqlServer, $global:sqlDatabase)
		$global:dbConn.Open()
		$global:dbCmd = New-Object System.Data.SQLClient.SQLCommand
		$global:dbCmd.Connection = $global:dbConn
		
		LogWrite -logstring ("Database Connection to : {0} = {1}" -f $global:dbConn.ConnectionString, $global:dbConn.State)
	}
	catch
	{
		LogWrite -logstring ("ERROR on Connection to : {0} = {1}" -f $global:dbConn.ConnectionString, $global:dbConn.State)
		break
	}
	
	# Read "PRE" steps for the current Environment from the specified configuration file.
	$presteps = $ve.PRESTEPS.SQL | Sort-Object -Property Order
	
	# Loop through each PRESTEP and run the provided SQL (if present)
	foreach ($ps in $presteps)
	{
		if ($ps.innerText -ne $null)
		{	
			LogWrite -logstring ("PreStep #{0} : {1}" -f $ps.Order, $ps.innerText)		
			DoSQLTask -SQLStatement $ps.innerText
		}
	}
	
	
	# Read "ScrubField" table/field/value options for the current Environment from the specified configuration file.
	$sf = $ve.ScrubFields.Field
	
	# Loop through each configured "FIELD" and invoke the function to update the Table/Field to the specified value.
	# The configured value can be a literal value or a valid SQL statment, therefor any provided values must include any required
	# quotations.
	foreach ($f in $sf)
	{
		LogWrite -logstring ("[{0}].[{1}] = '{2}'" -f $f.TableName, $f.FieldName, $f.FieldValue)
		ScrubTableField -TableName ($f.TableName) -FieldName ($f.FieldName) -FieldValue ($f.FieldValue)
		
	}
	
	# Read "PRE" steps for the current Environment from the specified configuration file.
	$poststeps = $ve.POSTSTEPS.SQL | Sort-Object -Property Order
	
	# Loop through each POSTSTEP and run the provided SQL (if present)
	foreach ($pst in $poststeps)
	{
		if ($pst.innerText -ne $null)
		{
			LogWrite -logstring ("PostStep #{0} : {1}" -f $pst.Order, $pst.innerText)
			DoSQLTask -SQLStatement $pst.innerText
		}
		
	}
	
	# Close the active connection for the current environment being processed.
	try
	{
		if ($global:dbConn.State -eq 'Open')
		{
			$global:dbConn.Close()
			LogWrite -logstring ("Database Connection to : {0} = {1}" -f $global:dbConn.ConnectionString, $global:dbConn.State)
		}
	}
	catch
	{
		LogWrite -logstring ("ERROR Closing Connection to : {0} = {1}" -f $global:dbConn.ConnectionString, $global:dbConn.State)
		LogWrite($_.Exception.Message)
		
		break
	}
	
}


# Close the  connection if it is still Open.
try
{
	if ($global:dbConn.State -eq 'Open')
	{
		$global:dbConn.Close()
		LogWrite -logstring ("Database Connection to : {0} = {1}" -f $global:dbConn.ConnectionString, $global:dbConn.State)
	}
}
catch
{
	LogWrite -logstring ("ERROR Closing Connection to : {0} = {1}" -f $global:dbConn.ConnectionString, $global:dbConn.State)
	LogWrite($_.Exception.Message)
	
	break
}

# Send an email to the configured recipients (including log file as an attachment.)
try
{
	$secpasswd = ConvertTo-SecureString $SMTPPassword -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential ($SMTPUser, $secpasswd)
	
	Send-MailMessage -Credential $cred -UseSsl  -From $mailFrom -To $mailTo -SMTPServer $mailServer -Port $mailPort -Subject ("Vista {0} Environment Scrub Log - {2} : {1}" -f $VistaEnvironment, $curDateTime, $sqlServer) -Body ("Attached file is the log showing the refresh results for the Vista Scrub script on {0} [{1}]`r`n`r`n{2}" -f $VistaEnvironment,$sqlServer, $global:mailBody) -Attachments $LogFile
}
catch
{
	LogWrite -logstring ("ERROR Sending Execution Log" -f $global:dbConn.ConnectionString, $global:dbConn.State)
	LogWrite($_.Exception.Message)
}


# SIG # Begin signature block
# MIIcVAYJKoZIhvcNAQcCoIIcRTCCHEECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAyCCpFGkNWoQg7
# N2zOkyKd9b8R+sNeIJz5zvWFOlTq66CCFrEwggPFMIICraADAgECAgEAMA0GCSqG
# SIb3DQEBCwUAMIGDMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEG
# A1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMRR29EYWRkeS5jb20sIEluYy4xMTAv
# BgNVBAMTKEdvIERhZGR5IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIw
# HhcNMDkwOTAxMDAwMDAwWhcNMzcxMjMxMjM1OTU5WjCBgzELMAkGA1UEBhMCVVMx
# EDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoT
# EUdvRGFkZHkuY29tLCBJbmMuMTEwLwYDVQQDEyhHbyBEYWRkeSBSb290IENlcnRp
# ZmljYXRlIEF1dGhvcml0eSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEAv3FiCPH6WTT3G8kYo/eASVjpIoMTpsUgQwE7hPHmhUmfJ+r2hBtOoLTb
# cJjHMgGxBT4HTu70+k8vWTAi56sZVmvigAf88xZ1gDlRe+X5NbZ0TqmNghPktj+p
# A4P6or6KFWp/3gvDthkUBcrqw6gElDtGfDIN8wBmIsiNaW02jBEYt9OyHGC0OPoC
# jM7T3UYH3go+6118yHz7sCtTpJJiaVElBWEaRIGMLKlDliPfrDqBmg4pxRyp6V0e
# tp6eMAo5zvGIgPtLXcwy7IViQyU0AlYnAZG0O3AqP26x6JyIAX2f1PnbU21gnb8s
# 51iruF9G/M7EGwM8CetJMVxpRrPgRwIDAQABo0IwQDAPBgNVHRMBAf8EBTADAQH/
# MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQUOpqFBxBnKLbv9r0FQW4gwZTaD94w
# DQYJKoZIhvcNAQELBQADggEBAJnbXXnV+ZdZZwNh8X47BjF1LaEgjk9lh7T3ppy8
# 2Okv0Nta7s90jHO0OELaBXv4AnW4/aWx1672194Ty1MQfopG0Zf6ty4rEauQsCeA
# +eifWuk3n6vk32yzhRedPdkkT3mRNdZfBOuAg6uaAi21EPTYkMcEc0DtciWgqZ/s
# nqtoEplXxo8SOgmkvUT9BhU3wZvkMqPtOOjYZPMsfhT8Auqfzf8HaBfbIpA4LXqN
# 0VTxaeNfM8p6PXsK48p/Xznl4nW6xXYYM84s8C9Mrfex585PqMSbSlQGxX991QgP
# 4hz+fhe4rF721BayQwkMTfana7SZhGXKeoji4kS+XPfqHPUwggQVMIIC/aADAgEC
# AgsEAAAAAAExicZQBDANBgkqhkiG9w0BAQsFADBMMSAwHgYDVQQLExdHbG9iYWxT
# aWduIFJvb3QgQ0EgLSBSMzETMBEGA1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMK
# R2xvYmFsU2lnbjAeFw0xMTA4MDIxMDAwMDBaFw0yOTAzMjkxMDAwMDBaMFsxCzAJ
# BgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhH
# bG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQSAtIFNIQTI1NiAtIEcyMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqpuOw6sRUSUBtpaU4k/YwQj2RiPZRcWV
# l1urGr/SbFfJMwYfoA/GPH5TSHq/nYeer+7DjEfhQuzj46FKbAwXxKbBuc1b8R5E
# iY7+C94hWBPuTcjFZwscsrPxNHaRossHbTfFoEcmAhWkkJGpeZ7X61edK3wi2BTX
# 8QceeCI2a3d5r6/5f45O4bUIMf3q7UtxYowj8QM5j0R5tnYDV56tLwhG3NKMvPSO
# dM7IaGlRdhGLD10kWxlUPSbMQI2CJxtZIH1Z9pOAjvgqOP1roEBlH1d2zFuOBE8s
# qNuEUBNPxtyLufjdaUyI65x7MCb8eli7WbwUcpKBV7d2ydiACoBuCQIDAQABo4Ho
# MIHlMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQW
# BBSSIadKlV1ksJu0HuYAN0fmnUErTDBHBgNVHSAEQDA+MDwGBFUdIAAwNDAyBggr
# BgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8w
# NgYDVR0fBC8wLTAroCmgJ4YlaHR0cDovL2NybC5nbG9iYWxzaWduLm5ldC9yb290
# LXIzLmNybDAfBgNVHSMEGDAWgBSP8Et/qC5FJK5NUPpjmove4t0bvDANBgkqhkiG
# 9w0BAQsFAAOCAQEABFaCSnzQzsm/NmbRvjWek2yX6AbOMRhZ+WxBX4AuwEIluBjH
# /NSxN8RooM8oagN0S2OXhXdhO9cv4/W9M6KSfREfnops7yyw9GKNNnPRFjbxvF7s
# tICYePzSdnno4SGU4B/EouGqZ9uznHPlQCLPOc7b5neVp7uyy/YZhp2fyNSYBbJx
# b051rvE9ZGo7Xk5GpipdCJLxo/MddL9iDSOMXCo4ldLA1c3PiNofKLW6gWlkKrWm
# otVzr9xG2wSukdduxZi61EfEVnSAR3hYjL7vK/3sbL/RlPe/UOB74JD9IBh4GCJd
# CC6MHKCX8x2ZfaOdkdMGRE4EbnocIOM28LZQuTCCBMYwggOuoAMCAQICDCRUuH8e
# FFOtN/qheDANBgkqhkiG9w0BAQsFADBbMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTExMC8GA1UEAxMoR2xvYmFsU2lnbiBUaW1lc3RhbXBp
# bmcgQ0EgLSBTSEEyNTYgLSBHMjAeFw0xODAyMTkwMDAwMDBaFw0yOTAzMTgxMDAw
# MDBaMDsxOTA3BgNVBAMMMEdsb2JhbFNpZ24gVFNBIGZvciBNUyBBdXRoZW50aWNv
# ZGUgYWR2YW5jZWQgLSBHMjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# ANl4YaGWrhL/o/8n9kRge2pWLWfjX58xkipI7fkFhA5tTiJWytiZl45pyp97DwjI
# Kito0ShhK5/kJu66uPew7F5qG+JYtbS9HQntzeg91Gb/viIibTYmzxF4l+lVACjD
# 6TdOvRnlF4RIshwhrexz0vOop+lf6DXOhROnIpusgun+8V/EElqx9wxA5tKg4E1o
# 0O0MDBAdjwVfZFX5uyhHBgzYBj83wyY2JYx7DyeIXDgxpQH2XmTeg8AUXODn0l7M
# jeojgBkqs2IuYMeqZ9azQO5Sf1YM79kF15UgXYUVQM9ekZVRnkYaF5G+wcAHdbJL
# 9za6xVRsX4ob+w0oYciJ8BUCAwEAAaOCAagwggGkMA4GA1UdDwEB/wQEAwIHgDBM
# BgNVHSAERTBDMEEGCSsGAQQBoDIBHjA0MDIGCCsGAQUFBwIBFiZodHRwczovL3d3
# dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAJBgNVHRMEAjAAMBYGA1UdJQEB
# /wQMMAoGCCsGAQUFBwMIMEYGA1UdHwQ/MD0wO6A5oDeGNWh0dHA6Ly9jcmwuZ2xv
# YmFsc2lnbi5jb20vZ3MvZ3N0aW1lc3RhbXBpbmdzaGEyZzIuY3JsMIGYBggrBgEF
# BQcBAQSBizCBiDBIBggrBgEFBQcwAoY8aHR0cDovL3NlY3VyZS5nbG9iYWxzaWdu
# LmNvbS9jYWNlcnQvZ3N0aW1lc3RhbXBpbmdzaGEyZzIuY3J0MDwGCCsGAQUFBzAB
# hjBodHRwOi8vb2NzcDIuZ2xvYmFsc2lnbi5jb20vZ3N0aW1lc3RhbXBpbmdzaGEy
# ZzIwHQYDVR0OBBYEFNSHuI3m5UA8nVoGY8ZFhNnduxzDMB8GA1UdIwQYMBaAFJIh
# p0qVXWSwm7Qe5gA3R+adQStMMA0GCSqGSIb3DQEBCwUAA4IBAQAkclClDLxACabB
# 9NWCak5BX87HiDnT5Hz5Imw4eLj0uvdr4STrnXzNSKyL7LV2TI/cgmkIlue64We2
# 8Ka/GAhC4evNGVg5pRFhI9YZ1wDpu9L5X0H7BD7+iiBgDNFPI1oZGhjv2Mbe1l9U
# oXqT4bZ3hcD7sUbECa4vU/uVnI4m4krkxOY8Ne+6xtm5xc3NB5tjuz0PYbxVfCMQ
# tYyKo9JoRbFAuqDdPBsVQLhJeG/llMBtVks89hIq1IXzSBMF4bswRQpBt3ySbr5O
# kmCCyltk5lXT0gfenV+boQHtm/DDXbsZ8BgMmqAc6WoICz3pZpendR4PvyjXCSMN
# 4hb6uvM0MIIE0DCCA7igAwIBAgIBBzANBgkqhkiG9w0BAQsFADCBgzELMAkGA1UE
# BhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAY
# BgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMTEwLwYDVQQDEyhHbyBEYWRkeSBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTExMDUwMzA3MDAwMFoXDTMx
# MDUwMzA3MDAwMFowgbQxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMw
# EQYDVQQHEwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjEt
# MCsGA1UECxMkaHR0cDovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMTMw
# MQYDVQQDEypHbyBEYWRkeSBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0g
# RzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC54MsQ1K92vdSTYusw
# ZLiBCGzDBNliF44v/z5lz4/OYuY8UhzaFkVLVat4a2ODYpDOD2lsmcgaFItMzEUz
# 6ojcnqOvK/6AYZ15V8TPLvQ/MDxdR/yaFrzDN5ZBUY4RS1T4KL7QjL7wMDge87Am
# +GZHY23ecSZHjzhHU9FGHbTj3ADqRay9vHHZqm8A29vNMDp5T19MR/gd71vCxJ1g
# O7GyQ5HYpDNO6rPWJ0+tJYqlxvTV0KaudAVkV4i1RFXULSo6Pvi4vekyCgKUZMQW
# OlDxSq7neTOvDCAHf+jfBDnCaQJsY1L6d8EbyHSHyLmTGFBUNUtpTrw700kuH9zB
# 0lL7AgMBAAGjggEaMIIBFjAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIB
# BjAdBgNVHQ4EFgQUQMK9J47MNIMwojPX+2yz8LQsgM4wHwYDVR0jBBgwFoAUOpqF
# BxBnKLbv9r0FQW4gwZTaD94wNAYIKwYBBQUHAQEEKDAmMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5nb2RhZGR5LmNvbS8wNQYDVR0fBC4wLDAqoCigJoYkaHR0cDov
# L2NybC5nb2RhZGR5LmNvbS9nZHJvb3QtZzIuY3JsMEYGA1UdIAQ/MD0wOwYEVR0g
# ADAzMDEGCCsGAQUFBwIBFiVodHRwczovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9z
# aXRvcnkvMA0GCSqGSIb3DQEBCwUAA4IBAQAIfmyTEMg4uJapkEv/oV9PBO9sPpyI
# BslQj6Zz91cxG7685C/b+LrTW+C05+Z5Yg4MotdqY3MxtfWoSKQ7CC2iXZDXtHwl
# TxFWMMS2RJ17LJ3lXubvDGGqv+QqG+6EnriDfcFDzkSnE3ANkR/0yBOtg2DZ2HKo
# cyQetawiDsoXiWJYRBuriSUBAA/NxBti21G00w9RKpv0vHP8ds42pM3Z2Czqrpv1
# KrKQ0U11GIo/ikGQI31bS/6kA1ibRrLDYGCD+H1QQc7CoZDDu+8CL9IVVO5EFdkK
# rqeKM+2xLXY2JtwE65/3YR8V3Idv7kaWKK2hJn0KCacuBKONvPi8BDABMIIFLTCC
# BBWgAwIBAgIJAL+YzoJOOTe0MA0GCSqGSIb3DQEBCwUAMIG0MQswCQYDVQQGEwJV
# UzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UE
# ChMRR29EYWRkeS5jb20sIEluYy4xLTArBgNVBAsTJGh0dHA6Ly9jZXJ0cy5nb2Rh
# ZGR5LmNvbS9yZXBvc2l0b3J5LzEzMDEGA1UEAxMqR28gRGFkZHkgU2VjdXJlIENl
# cnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTE5MDIyMjAwMDIwMFoXDTIyMDQx
# NTIxMDMzOFowbjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1NlYXR0bGUxGzAZBgNVBAoTEk1jS2luc3RyeSBDby4sIExMQzEbMBkG
# A1UEAxMSTWNLaW5zdHJ5IENvLiwgTExDMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEAmUKpZO0+EmXweMLx/cl1x+Fp0QYe2Y2pNwl5P96sy92Nz/JWQBtV
# CjgME+CfSTQH5Ud5MtbTjrqbfZvU6HwSKVl0gbRZkdgItjYLWJ3VDZelKex3rbmw
# wiJ/5CtGo4PanYPLIfjksApfXWQwOJ4drhVHCJtgDJFZmax5UeJ2k3Jw03eNUzWU
# 3R5DSaUBvOgIdMLlvpbalO3bmLlOD9HEVclHDLvp4KMdVMvgcIl/zX7PvlvMR5ao
# i3HYUjUinaNyUWzPIF1pwfvemief2i+AaXoFgxkjNRv/MYC16/YR8un02ADpv3Y5
# UirhEToQgLpBq8EEhNoALc5Ah7YYp3s1HQIDAQABo4IBhTCCAYEwDAYDVR0TAQH/
# BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzAOBgNVHQ8BAf8EBAMCB4AwNQYDVR0f
# BC4wLDAqoCigJoYkaHR0cDovL2NybC5nb2RhZGR5LmNvbS9nZGlnMnM1LTQuY3Js
# MF0GA1UdIARWMFQwSAYLYIZIAYb9bQEHFwIwOTA3BggrBgEFBQcCARYraHR0cDov
# L2NlcnRpZmljYXRlcy5nb2RhZGR5LmNvbS9yZXBvc2l0b3J5LzAIBgZngQwBBAEw
# dgYIKwYBBQUHAQEEajBoMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5nb2RhZGR5
# LmNvbS8wQAYIKwYBBQUHMAKGNGh0dHA6Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5j
# b20vcmVwb3NpdG9yeS9nZGlnMi5jcnQwHwYDVR0jBBgwFoAUQMK9J47MNIMwojPX
# +2yz8LQsgM4wHQYDVR0OBBYEFJPd6TOA8107BPo4E8fFSyeTyBHBMA0GCSqGSIb3
# DQEBCwUAA4IBAQAafYkC5Pu5IY+NEDkec/R+LD0NaGysQPSXcBBkIpi6l47LWCML
# Mzt5vvV5JRMjag52/BLFjnG/rrF+JtASr/hltSRqu2CvHspJyrVimPhURc9Ovclf
# bBdiLtXeoOvsQVtZtgtZBsu63wS4Co4dKNXFVz5aQAQGdrUQihXRrKPFtXw/0nLw
# Y5z7UfDba+yYBfgp5hszxl/PDl35QrKQiOfYYmOERVFJFtChr953PTgxyXMKnbhp
# HNTE033Rxlfohy4x8+g7QlZ3x3X1be5cVUSxLJ1FEDiwZSFpbiWfJrzgOVh9Wn1k
# JAIQ4VYVgCRCy1OXIQ9PS95tI+q2Cqm/zZhxMYIE+TCCBPUCAQEwgcIwgbQxCzAJ
# BgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxl
# MRowGAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjEtMCsGA1UECxMkaHR0cDovL2Nl
# cnRzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMTMwMQYDVQQDEypHbyBEYWRkeSBT
# ZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzICCQC/mM6CTjk3tDANBglg
# hkgBZQMEAgEFAKBMMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMC8GCSqGSIb3
# DQEJBDEiBCBgO/28QDbRb+WP8Sad8zEgbQ1X6AP1SOTJG9K2rzcNkDANBgkqhkiG
# 9w0BAQEFAASCAQAiN/nnnchRT6gMDM8QZ1VOr9u4aA5kL+ayQlDVsLsB4hAaWU4/
# lAP6668A+1J+kZ4IUSyLiNktW07yJOs8pbn0OAU0n9WQwNDLFgN1j2uyhSkTiSVk
# qGHPyqUEObLCxvJYQJmmJcj1pbwaBHA2jGkJVGBgqAERrvWW+32y/1BmwEp982PY
# ojUGMnvEkRitC4m0MYXNXpN3phv7b67sH62qGSvKIEIKv5lDwszE8HDuFMVrFLbI
# b+BYLLWLLO3I5kA4MWq861HaGVjkZhT9S55D5DkFjyEY6g6Z4c6neJUKs3ESNV5C
# XrTyrBGChSwt6bd81+hbnu0DzxyheYRhLMQ7oYICuTCCArUGCSqGSIb3DQEJBjGC
# AqYwggKiAgEBMGswWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hB
# MjU2IC0gRzICDCRUuH8eFFOtN/qheDANBglghkgBZQMEAgEFAKCCAQwwGAYJKoZI
# hvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTkwODA3MDQ1NTI1
# WjAvBgkqhkiG9w0BCQQxIgQgNFAJ54AZ5V+VCz/Cmn6MM1E09AZqk13Zb9Bvabmi
# pqcwgaAGCyqGSIb3DQEJEAIMMYGQMIGNMIGKMIGHBBQ+x2bV1NRy4hsfIUNSHDG3
# kNlLaDBvMF+kXTBbMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBu
# di1zYTExMC8GA1UEAxMoR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBTSEEy
# NTYgLSBHMgIMJFS4fx4UU603+qF4MA0GCSqGSIb3DQEBAQUABIIBAI9Lhrh62WOx
# AjEFmZt5SDwe0CPJnErMVMXMSoLzWLZ27POT4qNptyuKQl9rSQzGZJisWQLhc6T/
# mKBRRzT6l7WSDSaGc1taeyxvD+bG4VSq1588hrS/hz/VM2G3DW1FURr39pWjfGHH
# S8xa7w5SmHnfMQ+vZ88x1DZvwwlc3FhktaLgVbsiOZ5X+/NmqrOlICXBPtE2hjsY
# KQr88AIG36NnfB/MAL4ZwKkotwi24DRNthVVIxAjsO0NHG8bf039HZR+3yLGZitB
# i9oxfE7ncuygPxOMp5MZ2+7nYRp3FkWGc81C80l0iTGhjE6zdMC0DlgsYUGGD7uv
# e40jBpys5NU=
# SIG # End signature block
