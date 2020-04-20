# Load WinSCP .NET assembly
# Use "winscpnet.dll" for the releases before the latest beta version.
# c:\Windows\Microsoft.NET\Framework\v4.0.30319\RegAsm.exe WinSCPnet.dll /codebase /tlb

 [Reflection.Assembly]::LoadFrom("E:\WinSCP\WinSCPnet.dll") | Out-Null

# Global Variables
$script:lastFileName = $Null
$script:FilesToGet = 3
$script:recCount = 0
# Local Variables
$script:compname = gc env:computername
$script:homeDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$script:downloadDir = $script:homeDir + "\Download\" 
$script:uploadDir = $script:homeDir + "\Upload\" 
$script:logFile = $script:homeDir + "\Log\HealthCompProcessLog_" + + (Get-Date -format "yyyyMMdd") + ".txt" 

#$AttachmentPath = $script:uploadDir + "McKinstry_MetLife_Benefits_Elligible_" + (Get-Date -format "yyyyMMdd") + ".csv"
$AttachmentPath = $script:uploadDir + "mckins_mah_elig.xls"
#Remote Variables
$script:Protocol = [WinSCP.Protocol]::Ftp
$script:HostName = "ftp.healthcomp.com"
$script:UserName = "mckinstry"
#Testing
$script:Password = "Pb397m$4j"
#Production
#$script:Password= "Dkny002!"
#$script:SshHostKeyFingerprint = "ssh-rsa 2048 60:2b:98:ed:8b:ff:96:1f:e8:1d:3e:fe:ec:1c:90:0f"
$script:remoteUploadPath = "/ToMet/"
$script:remoteDownloadPath = "/ToXT17130478/"

# Email Variables
$script:smptServer = "mail.mckinstry.com"
$script:smptPort = 25
$script:emailFrom = "benefitsdev@mckinstry.com"
$script:emailToList = "billo@mckinstry.com"
$script:emailCcList = ""
#$script:emailToList="karenmc@mckinstry.com"
#$script:emailCcList="billo@mckinstry.com,beckys@mckinstry.com"
#$script:emailToList="lockbox@mckinstry.com"
#$script:emailCcList="billo@mckinstry.com,terrya@mckinstry.com,howards@mckinstry.com"
$script:mailSubject = "McKinstry Benefits Eligible Roster (DEV)"
$script:mailBody = $Null

#VP Dev Database Connection Strings
#$Database = "Viewpoint"
#$Server = "MCKTESTSQL04\VIEWPOINT"

#VP Staging Database Connection Strings
#$Database = "Viewpoint"
#$Server = "VPSTAGINGAG\VIEWPOINT"

#Database Connection Strings
$Database = "HRNET"
$Server = "SESQL08"

#Export File

function Export
{
	#LogWrite("-----------------------------------------------")
	#LogWrite("Export Benefits Eligible Roster")
	#LogWrite("-----------------------------------------------")
	
	[Int]$index = Get-Date | Select-Object -ExpandProperty DayOfWeek
	$daysSinceLastSunday = $index + 7  # Get Sunday before last
	$LastSunday = (Get-Date) - (New-TimeSpan -Days $daysSinceLastSunday)
	
	# Query for getting data from Viewpoint
	#$SqlQuery = "SELECT * FROM dbo.mfnBenefitEligibleEmployeesFromVP('" + $LastSunday.ToString("MM/dd/yyyy") + "')"
	
	# Query for getting data from CGC
	$SqlQuery = "SELECT * FROM dbo.mfnBenefitEligibleEmployees(" + $LastSunday.ToString("yyyyMMdd") + ")"
	
	# Connect to SQL and query data, extract data to SQL Adapter
	
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "Data Source=$Server;Initial Catalog=$Database;Integrated Security = True"
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = $SqlQuery
	$SqlCmd.CommandTimeout = 0
	$SqlCmd.Connection = $SqlConnection
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCmd
	$DataSet = New-Object System.Data.DataSet
	$nRecs = $SqlAdapter.Fill($DataSet)
	$nRecs | Out-Null
	
	#Populate Hash Table
	$objTable = $DataSet.Tables[0]
	$script:recCount = $objTable.Rows.Count
	LogWrite("** Benefits Eligible Roster Export """ + $SqlQuery + """ (" + $recCount + " records)")
	LogWrite("`tto " + $AttachmentPath)
	
	#Export Hash Table to CSV File
	$objTable | Export-CSV $AttachmentPath -NoTypeInformation
	
}

function UploadFiles
{
	LogWrite("-----------------------------------------------")
	LogWrite("Upload File: " + $AttachmentPath + " to " + $sessionOptions.HostName + ":" + $script:remoteUploadPath)
	LogWrite("-----------------------------------------------")
	
	# Run PGP Encoding using gpg4win-2.2.1
	#C:\TFS\ViewPoint\Integration\MetLife\gnupgp>gpg2.exe -e -u "McKinstry Co., LLC" -r "MetLife Voluntary Benefits Group (VBG)" ..\Upload\McKinstry_MetLife_Benefits_Elligible_20140224.csv
	$pgpcmd = $script:homeDir + "\gnupgp\gpg2.exe -q -e -u McKinstry -r 96765440 " + $AttachmentPath
	
	# Need to install GNUPGP on Server and install MetLife Public Key ( MetLife PGP Key.asc ) to its keystore.
	# Also need to edit the key and define it as ultimately trusted (e.g. gpg2.exe --edit-key; use trust command and set to level 5).
	
	LogWrite("Encypting " + $AttachmentPath + " for secured delivery.")
	LogWrite($pgpcmd)
	
	cmd.exe /C $pgpcmd
	
	Rename-Item -Path ($AttachmentPath + ".gpg") -NewName ($AttachmentPath + ".pgp")
	
	$session = New-Object WinSCP.Session
	try
	{
		$session.add_FileTransferProgress({ FileTransferProgress($_) })
		
		$session.Open($sessionOptions)
		$fileToTransfer = $AttachmentPath + ".pgp"
		$remotePath = $script:remoteUploadPath
		
		# Upload the file and throw on any error
		#LogWrite("")
		LogWrite("** Upload " + $script:compname + ":" + """" + $fileToTransfer + """" + " -->> " + $sessionOptions.HostName + $remotePath)
		$session.PutFiles($fileToTransfer, $remotePath).Check()
		
	}
	finally
	{
		#LogWrite("-----------------------------------------------")
		# Disconnect, clean up
		#$session.Dispose()
		
		#sendMail
	}
	
	
}

# Session.FileTransferProgress event handler
function FileTransferProgress
{
	Param ($e)
	
	# New line for every new file
	if (($script:lastFileName -ne $Null) -and
	($script:lastFileName -ne $e.FileName))
	{
		LogWrite("")
		Write-Host
	}
	
	# Print transfer progress
	LogWrite("        `t{0} ({1:P0}) ... " -f $e.FileName, $e.FileProgress)
	
	Write-Host -NoNewline ("`r{0} ({1:P0}) ... " -f $e.FileName, $e.FileProgress)
	
	# Remember a name of the last file reported
	$script:lastFileName = $e.FileName
	
}


function sendMail
{
	LogWrite("")
	LogWrite("** Sending Email")
	#Write-Host "Sending Email"
	
	if (($script:emailToList -ne $Null) -and ($script:emailToList -ne ""))
	{
		ForEach ($emailTo in $script:emailToList.split(","))
		{
			Write-Host "To: " + $emailTo
			LogWrite("`tTo: " + $emailTo)
		}
	}
	
	if (($script:emailCcList -ne $Null) -and ($script:emailCcList -ne ""))
	{
		ForEach ($emailCc in $script:emailCcList.Split(","))
		{
			Write-Host "Cc: " + $emailCc
			LogWrite("`tCc: " + $emailCc)
		}
	}
	
	#$arg1 = $args[0]
	
	#$scriptPath = $args[1]
	$compname = $script:compname
	
	$file = $script:logFile
	$att = new-object Net.Mail.Attachment($file)
	#$Attachment = new-object Net.Mail.Attachment($AttachmentPath)
	
	$Attachment2 = new-object Net.Mail.Attachment($AttachmentPath + ".pgp")
	#$Attachment3 = new-object Net.Mail.Attachment($AttachmentPath + ".gpg")
	
	#Creating a Mail object
	$msg = new-object Net.Mail.MailMessage
	
	#Creating SMTP server object
	$smtp = new-object Net.Mail.SmtpClient
	$smtp.Host = $script:smptServer
	$smtp.Port = $script:smptPort
	
	#Email structure 
	$msg.From = $script:emailFrom
	
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
	
	$msg.subject = "Benefits Eligible Roster Export for MetLife" #"from " + $Server + " " + $Database
	$msg.body = "<p>Export of Benefits Eligible Roster for delivery to MetLife</p><br/><UL><LI><I>" + $AttachmentPath + " (" + $script:recCount + " records)" + "</I></LI></UL>"
	
	#$msg.subject = $script:mailSubject
	#$msg.body = $script:mailBody
	#$msg.Attachments.Add($Attachment)
	$msg.Attachments.Add($Attachment2)
	#$msg.Attachments.Add($Attachment3)
	$msg.Attachments.Add($att)
	$msg.IsBodyHTML = $true
	#Sending email 
	$smtp.Send($msg)
	
	#$Attachment.Dispose();
	$Attachment2.Dispose();
	#$Attachment3.Dispose();
	$att.Dispose();
	$msg.Dispose();
}

Function archiveFile
{
	LogWrite("")
	
	$targetDir = $script:homeDir + "\Archive"
	Move-Item $AttachmentPath $targetDir -Force
	LogWrite("Archive " + $AttachmentPath + " to " + $targetDir)
	Move-Item ($AttachmentPath + ".pgp") $targetDir -Force
	LogWrite("Archive " + $AttachmentPath + ".pgp" + " to " + $targetDir)
	#Move-Item ($AttachmentPath + ".pgp") $targetDir -Force
	#LogWrite("Archive " + $AttachmentPath + ".gpg" + " to " + $targetDir )
}

Function LogWrite
{
   Param ([string]$logstring)
  
   $ts = (Get-Date).ToLongTimeString() + "`t" + $logstring
   $script:mailBody=$script:mailBody+$ts+"`r`n"
   Add-content $Logfile -value $ts
}
try
{
	If (Test-Path $script:logFile)
	{
		Remove-Item $script:logFile
	}
	
	LogWrite("-----------------------------------------------")
	LogWrite((Get-Date).ToLongDateString())
	LogWrite("-----------------------------------------------")
	
	$sessionOptions = New-Object WinSCP.SessionOptions
	$sessionOptions.Protocol = $script:Protocol
	$sessionOptions.HostName = $script:HostName
	$sessionOptions.UserName = $script:UserName
	$sessionOptions.Password = $script:Password
	#$sessionOptions.SshHostKeyFingerprint = $script:SshHostKeyFingerprint
	
	LogWrite("FTP Server:   " + $sessionOptions.HostName)
	LogWrite("FTP Protocol: " + $sessionOptions.Protocol)
	LogWrite("Remote Upload Dir:   " + $script:remoteUploadPath)
	LogWrite("Remote Download Dir:   " + $script:remoteDownloadPath)
	LogWrite("Server:       " + $script:compname)
	LogWrite("Local Dir:    " + $script:downloadDir)
	LogWrite("-----------------------------------------------")
	
	$Logfile = $script:logFile
	
	#LogWrite("----------------------------------------------------------------------------------------------")
	
	try
	{
		Export
		LogWrite("")
		UploadFiles
	}
	finally
	{
		# Terminate line after the last file (if any)
		#if ($script:lastFileName -ne $Null)
		#{
		#    LogWrite("")
		#    Write-Host
		#}
		
		#LogWrite("----------------------------------------------------------------------------------------------")
		# Disconnect, clean up
		#$session.Dispose()
		
		sendMail
		#Start-Sleep -Second 30 
		#GET-Openfile $Logfile | Close-Openfile
		archiveFile
	}
	exit 0
}
catch [Exception]
{
	Write-Host $_.Exception.Message
	exit 1
}