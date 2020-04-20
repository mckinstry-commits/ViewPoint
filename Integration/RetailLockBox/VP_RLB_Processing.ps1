#RLB_Execute.ps1

# Load WinSCP .NET assembly
# Use "winscpnet.dll" for the releases before the latest beta version.
# c:\Windows\Microsoft.NET\Framework\v4.0.30319\RegAsm.exe WinSCPnet.dll /codebase /tlb


# TODO:
#  Read Variables from external config file and/or parameters
#   Review SQL to standardized datatypes
#     Deliver schema for uploaded files to RLB
#	Move Downloaded files to Archive on Remote server when download is complete.
#   Split script into ProcessAP and ProcessAR versions (rather than all in one)

[Reflection.Assembly]::LoadFrom("C:\WinSCP\WinSCPnet.dll") | Out-Null

# Global Variables
$script:lastFileName = $Null
$script:FilesToGet = 3

# Local Variables
$script:compname = gc env:computername
$script:homeDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
$script:downloadDir = $script:homeDir + "\Download\" 
$script:uploadDir = $script:homeDir + "\Upload\" 
$script:logFile = $script:homeDir + "\Log\ProcessLog.txt" 

$APAttachmentPath = $script:uploadDir + "RLB_AP_Header_Export.csv"
$ARAttachmentPath = $script:uploadDir + "RLB_AR_Header_Export.csv"

#Remote Variables
$script:Protocol = [WinSCP.Protocol]::Sftp
$script:HostName = "sftp.retaillockbox.com"
$script:UserName = "mckinstry"
$script:Password= "ch@ngem3"
$script:SshHostKeyFingerprint = "ssh-rsa 2048 60:2b:98:ed:8b:ff:96:1f:e8:1d:3e:fe:ec:1c:90:0f"
$script:remoteUploadPath = "/VPERP/Inbound/"
$script:remoteARUploadPath = $script:remoteUploadPath
$script:remoteARDownloadPath = "/VPERP/Outbound/AR/"
$script:remoteAPUploadPath = $script:remoteUploadPath
$script:remoteAPDownloadPath = "/VPERP/Outbound/AP/"

# Email Variables
$script:smptServer="mail.mckinstry.com"
$script:smptPort=25
$script:emailFrom="vpdev@mckinstry.com"
$script:emailToList="billo@mckinstry.com"
$script:emailCcList=$Null
#$script:emailToList="lockbox@mckinstry.com"
#$script:emailCcList="billo@mckinstry.com,terrya@mckinstry.com,howards@mckinstry.com"
$script:mailSubject = "VP RLB Processing Executed (STG)"
$script:mailBody  = $Null

#Database Connection Strings
$Database = "Viewpoint"
$Server = "VPSTAGINGAG\VIEWPOINT"

#Export File

function ExportAP
{	
	# Connect to SQL and query data, extract data to SQL Adapter
	$SqlQuery = "SELECT * FROM mvwRLBAPExport ORDER BY RecordType,Company, Number"
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
	$objTable = $DataSet.Tables[0]

	LogWrite("** AP Export """ + $SqlQuery + """ (" + $objTable.Rows.Count + " records)")
	LogWrite("`tto " + $APAttachmentPath)

	#Export Hash Table to CSV File
	$objTable | Export-CSV $APAttachmentPath -NoTypeInformation -Delimiter "|"
	
}

function ExportAR
{
	
	#$AttachmentPath = "C:\RLB_AP_Header_Export.csv"
	# Connect to SQL and query data, extract data to SQL Adapter
	$SqlQuery = "SELECT * FROM mvwRLBARExport ORDER BY Company, InvoiceNumber"
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
	$objTable = $DataSet.Tables[0]

	LogWrite("** AR Export """ + $SqlQuery + """ (" + $objTable.Rows.Count + " records)")
	LogWrite("`tto " + $ARAttachmentPath)
	
	#Export Hash Table to CSV File
	$objTable | Export-CSV $ARAttachmentPath -NoTypeInformation -Delimiter "|"
	
}

function UploadVPARFiles
{
	#LogWrite("-----------------------------------------------")
	#LogWrite("Upload File: " + $ARAttachmentPath + " to " + $sessionOptions.HostName + ":" + $script:remoteARUploadPath )
    #LogWrite("-----------------------------------------------")
	
	$session = New-Object WinSCP.Session
    try
    {
		 # Will continuously report progress of transfer
         $session.add_FileTransferProgress( { FileTransferProgress($_) } )

		 $session.Open($sessionOptions)
		 $fileToTransfer = $ARAttachmentPath
         $remotePath = $script:remoteARUploadPath
		 
		 # Upload the file and throw on any error
            #LogWrite("")
            LogWrite("** Upload " + $script:compname + ":" + """" + $fileToTransfer + """")
			LogWrite("`t -->> " + $sessionOptions.HostName + $remotePath  )
            $session.PutFiles($fileToTransfer, $remotePath).Check()
	
	}
	finally
    {       
        #LogWrite("-----------------------------------------------")
        # Disconnect, clean up
        $session.Dispose()
        
        #sendMail
    }
 
}

function UploadVPAPFiles
{
	#LogWrite("-----------------------------------------------")
	#LogWrite("Upload File: " + $APAttachmentPath + " to " + $sessionOptions.HostName + ":" + $script:remoteAPUploadPath )
    #LogWrite("-----------------------------------------------")

	$session = New-Object WinSCP.Session
    try
    {
		 # Will continuously report progress of transfer
         $session.add_FileTransferProgress( { FileTransferProgress($_) } )
 
		 $session.Open($sessionOptions)
		 $fileToTransfer = $APAttachmentPath
         $remotePath = $script:remoteAPUploadPath
		 
		 # Upload the file and throw on any error
            #LogWrite("")
            LogWrite("** Upload " + $script:compname + ":" + """" + $fileToTransfer + """" )
			LogWrite("`t -->> " + $sessionOptions.HostName + $remotePath  )
            $session.PutFiles($fileToTransfer, $remotePath).Check()
	
	}
	finally
    {                
        #LogWrite("-----------------------------------------------")
        # Disconnect, clean up
        $session.Dispose()
        
        #sendMail
    }

}

function GetVPARFiles
{

	#LogWrite("-----------------------------------------------")
	LogWrite("** Download AR Files from " + $sessionOptions.HostName + ":" + $script:remoteARDownloadPath)
	LogWrite("`t to " + $script:compname + ":" + $script:downloadDir + "AR\" )
    #LogWrite("-----------------------------------------------")		

    $session = New-Object WinSCP.Session
    try
    {
        # Will continuously report progress of transfer
        $session.add_FileTransferProgress( { FileTransferProgress($_) } )
 
        # Connect
        $session.Open($sessionOptions)
        $localPath = $script:downloadDir + "AR\"
        $remotePath = $script:remoteARDownloadPath

        # Gel list of files in the directory
        $files = $session.ListDirectory($remotePath)
        
        #LogWrite($files.toString())
        
        
        # Select the most recent file
        foreach( $file in 
            $files.Files |
            Where-Object { -not $_.IsDirectory } |
            Sort-Object LastWriteTime |
            Select-Object -Last $script:FilesToGet
        )
        {
            
            # Download the file and throw on any error
            #LogWrite("")
            LogWrite("`t" + $sessionOptions.HostName + $remotePath + $file.Name)
			LogWrite("`t -->> " + $script:compname + ":" + """" + $localPath + $file.Name + """")
            $session.GetFiles(($remotePath + $file.Name), $localPath).Check()
            
        }
    }
    finally
    {
        # Terminate line after the last file (if any)
        if ($script:lastFileName -ne $Null)
        {
            LogWrite("")
            Write-Host
        }
        
        LogWrite("")
        # Disconnect, clean up
        $session.Dispose()
        
        #sendMail
    }
 
}

function GetVPAPFiles
{
	#LogWrite("-----------------------------------------------")
	LogWrite("** Download AP Files from " + $sessionOptions.HostName + ":" + $script:remoteAPDownloadPath)
	LogWrite("`t to " + $script:compname + ":" + $script:downloadDir + "AP\" )
    #LogWrite("-----------------------------------------------")		
	
    $session = New-Object WinSCP.Session
    try
    {
        # Will continuously report progress of transfer
        $session.add_FileTransferProgress( { FileTransferProgress($_) } )
 
        # Connect
        $session.Open($sessionOptions)
        $localPath = $script:downloadDir + "AP\"
        $remotePath = $script:remoteAPDownloadPath
		
		
        # Gel list of files in the directory
        $files = $session.ListDirectory($remotePath)
        
        #LogWrite($files.toString())
        
        
        # Select the most recent file
        foreach( $file in 
            $files.Files |
            Where-Object { -not $_.IsDirectory } |
            Sort-Object LastWriteTime |
            Select-Object -Last $script:FilesToGet
        )
        {
            
            # Download the file and throw on any error
            
            LogWrite("`t" + $sessionOptions.HostName + $remotePath + $file.Name)
			LogWrite("`t -->> " + $script:compname + ":" + """" + $localPath + $file.Name + """")
            $session.GetFiles(($remotePath + $file.Name), $localPath).Check()
            
        }
    }
    finally
    {
        # Terminate line after the last file (if any)
        if ($script:lastFileName -ne $Null)
        {
            LogWrite("")
            Write-Host
        }
        
        LogWrite("")
        # Disconnect, clean up
        $session.Dispose()
        
        #sendMail
    }
 
}


# Session.FileTransferProgress event handler
function FileTransferProgress
{
    Param($e)
 
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


function sendMail{
     LogWrite("** Sending Email")

     if ( ($script:emailToList -ne $Null) -and ($script:emailToList -ne ""))
     {
         ForEach ( $emailTo in $script:emailToList.split(",") )
         {
            Write-Host "To: " + $emailTo
            LogWrite("`tTo: " + $emailTo)
         }
     }
     
     if ( ($script:emailCcList -ne $Null) -and ($script:emailCcList -ne ""))
     {
         ForEach ( $emailCc in $script:emailCcList.Split(",") )
         {
            Write-Host "Cc: " + $emailCc
            LogWrite("`tCc: " + $emailCc)
    	 }
     }
     
     $compname = $script:compname
	 
	 $file = $script:logFile
	 $att = new-object Net.Mail.Attachment($file)
	 $APAttachment = new-object Net.Mail.Attachment($APAttachmentPath)
	 $ARAttachment = new-object Net.Mail.Attachment($ARAttachmentPath)

     #Creating a Mail object
     $msg = new-object Net.Mail.MailMessage

     #Creating SMTP server object
     $smtp = new-object Net.Mail.SmtpClient
	 $smtp.Host = $script:smptServer
	 $smtp.Port = $script:smptPort
	 
     #Email structure 
     $msg.From = $script:emailFrom
     
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
	 
 	$msg.subject = "DEV/TEST ONLY : RLB Data Exchange [" + $Server + "." + $Database + "]"
	
	$msgBody = "<B>DEV/TEST ONLY</B><BR/><HR/>"
	$msgBody += "<P>Export/Upload of AP & AR Data for Retail Lock Box<BR/>"
	$msgBody += "and Download of Retail Lock Box supplied data/images.</P>"
    $msgBody +="Uploads:"
	$msgBody +="<UL>"
	$msgBody +="<LI><I>" + $script:compname + ":" + $APAttachmentPath + "</I></LI>"
	$msgBody +="<LI><I>" + $script:compname + ":" + $ARAttachmentPath + "</I></LI>"
	$msgBody +="</UL>"
	$msgBody +="<BR/>"
    $msgBody +="Downloads:"
	$msgBody +="<UL>"
	$msgBody +="<LI><I>" + $script:compname + ":" + $script:downloadDir + "AP\" + "</I></LI>"
	$msgBody +="<LI><I>" + $script:compname + ":" + $script:downloadDir + "AR\" + "</I></LI>"
	$msgBody +="</UL>"    
	$msgBody +="<HR/>"
	$msgBody +="<P><FONT SIZE='-1'><I>"
	$msgBody += $script:compname + "==>" + $script:HostName + "/" + $script:remoteUploadPath + "<BR/>"
    $msgBody += $script:HostName + "/" + $script:remoteDownloadPath + "==> " + $script:compname + "<BR/>"
	$msgBody += (Get-Date).ToLongDateString() + " " + (Get-Date).ToShortTimeString()
	$msgBody +="</I></FONT></P>"
	
	$msg.body = $msgBody

    #$msg.subject = $script:mailSubject
    #$msg.body = $script:mailBody
	$msg.Attachments.Add($APAttachment)
	$msg.Attachments.Add($ARAttachment)
    $msg.Attachments.Add($att)
	$msg.IsBodyHTML=$true
    #Sending email 
    $smtp.Send($msg)
	 
	$APAttachment.Dispose();
	$ARAttachment.Dispose();
	$msg.Dispose();
  
}

Function LogWrite
{
   Param ([string]$logstring)
  
   $ts = (Get-Date).ToLongTimeString() + "`t" + $logstring
   $script:mailBody=$script:mailBody+$ts+"`r`n"
   Add-content $Logfile -value $ts
}

Function archiveFile
{
	$targetDir=$script:homeDir + "\Archive"
	
	get-childitem$targetDir -include *.* -recurse | foreach ($_) {remove-item $_.fullname}
	
	Move-Item $APAttachmentPath $targetDir -Force
	Move-Item $ARAttachmentPath $targetDir -Force
	Move-Item $script:logFile $targetDir -Force
	
}

try
{
    If (Test-Path $script:logFile){
    	Remove-Item $script:logFile
    }
	
    LogWrite("-----------------------------------------------")
    LogWrite((Get-Date).ToLongDateString() )
	LogWrite("-----------------------------------------------")

    $sessionOptions = New-Object WinSCP.SessionOptions
    $sessionOptions.Protocol = $script:Protocol
    $sessionOptions.HostName = $script:HostName
    $sessionOptions.UserName = $script:UserName
    $sessionOptions.Password = $script:Password
    $sessionOptions.SshHostKeyFingerprint = $script:SshHostKeyFingerprint
 
    LogWrite("FTP Source:   " + $sessionOptions.HostName)
    LogWrite("FTP Protocol: " + $sessionOptions.Protocol)
    LogWrite("Remote AR Upload Dir:   " + $script:remoteARUploadPath)
	LogWrite("Remote AR Download Dir:   " + $script:remoteARDownloadPath)
	LogWrite("Remote AP Upload Dir:   " + $script:remoteAPUploadPath)
	LogWrite("Remote AP Download Dir:   " + $script:remoteAPDownloadPath)=
    LogWrite("Server:       " + $script:compname)
    LogWrite("Local Dir:    " + $script:downloadDir)

    LogWrite("SQL Server:    " + $Server)
    LogWrite("Database:    " + $Database)
	
	LogWrite("-----------------------------------------------")
	
	$Logfile = $script:logFile
	
	#LogWrite("----------------------------------------------------------------------------------------------")
	
	try
    {
		ExportAP
		ExportAR
		LogWrite("")
		UploadVPAPFiles
		UploadVPARFiles
		LogWrite("")
		GetVPAPFiles
		GetVPARFiles
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
		archiveFile
    }
	exit 0
}
catch [Exception]
{
    Write-Host $_.Exception.Message
    exit 1
}
