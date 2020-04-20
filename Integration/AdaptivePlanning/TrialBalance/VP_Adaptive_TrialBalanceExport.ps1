#VP_CAC_VendorExport.ps1

# Load WinSCP .NET assembly
# Use "winscpnet.dll" for the releases before the latest beta version.
# c:\Windows\Microsoft.NET\Framework\v4.0.30319\RegAsm.exe WinSCPnet.dll /codebase /tlb

[Reflection.Assembly]::LoadFrom("C:\WinSCP\WinSCPnet.dll") | Out-Null

# Global Variables
$script:lastFileName = $Null
$script:FilesToGet = 3

# Local Variables
$script:compname = gc env:computername
$script:homeDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
$script:downloadDir = $script:homeDir + "\Download\" 
$script:uploadDir = $script:homeDir + "\Upload\" 
$script:logFile = $script:homeDir + "\Log\ExportProcessLog_{0:yyyyMMdd}.txt"  -f (Get-Date)

$AttachmentPath = $script:uploadDir + "VP{0}_Adaptive_TrialBalance_Export.csv"

#Remote Variables
$script:Protocol = [WinSCP.Protocol]::Sftp
$script:HostName = "file:"
$script:UserName = "login"
$script:Password= "password"
$script:SshHostKeyFingerprint = "ssh-rsa 2048 60:2b:98:ed:8b:ff:96:1f:e8:1d:3e:fe:ec:1c:90:0f"
$script:remoteUploadPath = "\\SOME\NETWORK\Location\TBD"
$script:remoteDownloadPath = "/Outbound/"

# Email Variables
$script:smptServer="mail.mckinstry.com"
$script:smptPort=25
$script:emailFrom="vpdev@mckinstry.com"
$script:replyTo="mikes@mckinstry.com"
#$script:emailToList="mikesh@mckinstry.com"
#$script:emailCcList="billo@mckinstry.com,howards@mckinstry.com,erics@mckinstry.com,c-davidmcc@mckinstry.com"
$script:emailToList="billo@mckinstry.com"
$script:emailCcList=$Null
$script:mailSubject = "VP Adaptive Trial Balance Export Processing Executed (DEV)"
$script:mailBody  = $Null

#Database Connection Strings
$Database = "Viewpoint"
$Server = "MCKTESTSQL04\VIEWPOINT"

#Creating a Mail object
$msg = new-object Net.Mail.MailMessage

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

$msg.subject = "DEV/TEST ONLY : VP Adaptive Trial Balance Export [" + $Server + "." + $Database + "]"

$script:msgBody = "<B><FONT COLOR='RED'>DEV/TEST ONLY</FONT></B><BR/><HR/>"
$script:msgBody += "<P><B>Export/Upload of VP Trial Balance data for Adaptive Planning</B><BR/></P>"
$script:msgBody += "<HR/><UL>"
	
#Export File

function ExportData 
{
	Param (
		[int]$Company
	,	[DateTime]$BeginningMonth
	,	[DateTime] $EndingMonth
	)
	
	$curAttachmentPath = $AttachmentPath -f $Company
	LogWrite($curAttachmentPath)
	
	$SqlQuery = "exec msprptGLFinDet 
					@GLCo			=	" + $Company.ToString() + "
				,	@BegAcct 		=	'          '
				,	@EndAcct		=	'zzzzzzzzzz'
				,	@BegMonth		=	'" + $BeginningMonth.ToString("MM/dd/yyyy") + "'
				,	@EndMonth		=	'" + $EndingMonth.ToString("MM/dd/yyyy") +"'
				,	@IncludeInactive=	'N'
				,	@Source			=	' '
				,	@Journal		=	' '
				,	@DetailLevel	=	'D'"
				
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

	LogWrite("** VP Adaptive Trial Balance Export """ + $SqlQuery + """ (" + $objTable.Rows.Count + " records)")
	LogWrite("`tto " + $curAttachmentPath)

	#Export Hash Table to CSV File
	$objTable | Export-CSV $curAttachmentPath -NoTypeInformation -Delimiter ","				
	
	updateEmail $curAttachmentPath $objTable.Rows.Count
}

function UploadVPFiles
{
	#LogWrite("-----------------------------------------------")
	#LogWrite("Upload File: " + $AttachmentPath + " to " + $sessionOptions.HostName + ":" + $script:remoteUploadPath )
    #LogWrite("-----------------------------------------------")
	
	$session = New-Object WinSCP.Session
    try
    {
		 # Will continuously report progress of transfer
         $session.add_FileTransferProgress( { FileTransferProgress($_) } )

		 $session.Open($sessionOptions)
		 $fileToTransfer = $AttachmentPath
         $remotePath = $script:remoteUploadPath
		 
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

function GetFiles
{

	#LogWrite("-----------------------------------------------")
	LogWrite("** Download Files from " + $sessionOptions.HostName + ":" + $script:remoteDownloadPath)
	LogWrite("`t to " + $script:compname + ":" + $script:downloadDir)
    #LogWrite("-----------------------------------------------")		

    $session = New-Object WinSCP.Session
    try
    {
        # Will continuously report progress of transfer
        $session.add_FileTransferProgress( { FileTransferProgress($_) } )
 
        # Connect
        $session.Open($sessionOptions)
        $localPath = $script:downloadDir
        $remotePath = $script:remoteDownloadPath

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

function updateEmail{
	Param (
		[string]$FileName,
		[int]$RowCount
	)

	$script:msgBody += "<LI>"
	#$script:msgBody += "<A href='file:\\"+ $FileName + "'>" + $FileName + "</a>"
	$script:msgBody += $FileName + " (" + $RowCount + " records)"
	$script:msgBody += "</LI>"
	
	#$FileAttachment = new-object Net.Mail.Attachment($FileName) 
	#$msg.Attachments.Add($FileAttachment)
	#$FileAttachment.Dispose();

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
	$msg.Attachments.Add($att)	
	
	$att2 = new-object Net.Mail.Attachment($script:zipfilename)
	$msg.Attachments.Add($att2)
	
	$script:msgBody +="</UL>"
	$script:msgBody +="<HR/>"
	$script:msgBody +="<P><FONT SIZE='-1'><I>"
	$script:msgBody += $script:compname + "==><a href='" + $script:HostName + $script:remoteUploadPath + "'>" + $script:HostName + $script:remoteUploadPath + "</a><BR/>"
	$script:msgBody += (Get-Date).ToLongDateString() + " " + (Get-Date).ToShortTimeString()
	$script:msgBody +="</I></FONT></P>"
	
	$msg.body = $script:msgBody

	$msg.IsBodyHTML=$true
    #Sending email 
    $smtp.Send($msg)
	
	$att.Dispose();
	$att2.Dispose();
	$msg.Dispose();
  
}

Function LogWrite
{
   Param ([string]$logstring)
  
   $ts = (Get-Date).ToLongTimeString() + "`t" + $logstring
   $script:mailBody=$script:mailBody+$ts+"`r`n"
   Add-content $Logfile -value $ts
   Write-Host $logstring
}


function Zip-Files (){
    $script:zipfilename = $AttachmentPath -f "" -replace ".csv", ("_{0:yyyyMMdd}.zip" -f (Get-Date))	
	LogWrite( "Achive File: " + $script:zipfilename )
	
	if(-not (test-path($zipfilename)))
    {
        set-content $zipfilename ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
        (dir $zipfilename).IsReadOnly = $false 
     
        $shellApplication = new-object -com shell.application
	}
	    $zipPackage = $shellApplication.NameSpace($script:zipfilename)
        foreach ($file in (Get-Childitem $script:uploadDir -filter *.csv | Sort-Object Name )){
			$curFile =  $file.FullName
			#(Get-Childitem $script:uploadDir).count			
			$zipPackage.MoveHere($curFile)
			LogWrite( "* Zipping $file" )
			Start-sleep -milliseconds 500
		}
        #do {
        #    $zipCount = $zipPackage.Items().count
        #    "Waiting for compression to complete ..."
        #    Start-sleep -Seconds 5
        #}
        #While($zippackage.Items().count -lt (Get-Childitem $script:uploadDir).count)
        LogWrite( "Finished zipping successfully" )
    
}

Function archiveFile
{
	$targetDir=$script:homeDir + "\Archive"		
	
	Move-Item $script:zipfilename $targetDir -Force
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
	LogWrite("Remote Upload Dir:   " + $script:remoteUploadPath)
	LogWrite("Remote Download Dir:   " + $script:remoteDownloadPath)
    LogWrite("Server:       " + $script:compname)
    LogWrite("Local Dir:    " + $script:downloadDir)

    LogWrite("SQL Server:    " + $Server)
    LogWrite("Database:    " + $Database)
	
	LogWrite("-----------------------------------------------")
	
	$Logfile = $script:logFile
	
	#LogWrite("----------------------------------------------------------------------------------------------")
	
	try
    {
		if ( $args.Count -eq 2 )
		{
			[DateTime]$StartMonth = $args[0]
			[DateTime]$EndMonth = $args[1]
		}
		else
		{ 
			[DateTime]$StartMonth = "1/1/2014" 
			[DateTime]$EndMonth = "3/1/2014"
		}
		
		$Co1File  = ExportData -Company 1  -BeginningMonth $StartMonth -EndingMonth $EndMonth 		
		#$Co4File  = ExportData -Company 4  -BeginningMonth $StartMonth -EndingMonth $EndMonth 
		#$Co11File = ExportData -Company 11 -BeginningMonth $StartMonth -EndingMonth $EndMonth 
		#$Co12File = ExportData -Company 12 -BeginningMonth $StartMonth -EndingMonth $EndMonth 
		$Co20File = ExportData -Company 20 -BeginningMonth $StartMonth -EndingMonth $EndMonth 
		#$Co21File = ExportData -Company 21 -BeginningMonth $StartMonth -EndingMonth $EndMonth 
		#$Co22File = ExportData -Company 22 -BeginningMonth $StartMonth -EndingMonth $EndMonth 
		$Co60File = ExportData -Company 60 -BeginningMonth $StartMonth -EndingMonth $EndMonth 
		
		Zip-Files 
		
		#LogWrite("")
		#UploadVPFiles
		#LogWrite("")
		#GetFiles
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
	write-host "Caught an exception:" -ForegroundColor Red
    write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
	
    exit 1
}
