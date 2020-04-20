#VP_CAC_VendorExport.ps1

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

$AttachmentPath = $script:uploadDir + "XVP{0}_Adaptive_TrialBalance_Export.csv"
$Attachment1Path = $script:uploadDir + "VP1_Adaptive_TrialBalance_Export.csv"
$Attachment4Path = $script:uploadDir + "VP4_Adaptive_TrialBalance_Export.csv"
$Attachment11Path = $script:uploadDir + "VP11_Adaptive_TrialBalance_Export.csv"
$Attachment12Path = $script:uploadDir + "VP12_Adaptive_TrialBalance_Export.csv"
$Attachment20Path = $script:uploadDir + "VP20_Adaptive_TrialBalance_Export.csv"
$Attachment21Path = $script:uploadDir + "VP21_Adaptive_TrialBalance_Export.csv"
$Attachment22Path = $script:uploadDir + "VP22_Adaptive_TrialBalance_Export.csv"
$Attachment60Path = $script:uploadDir + "VP60_Adaptive_TrialBalance_Export.csv"


#Remote Variables
$script:Protocol = [WinSCP.Protocol]::Sftp
$script:HostName = "sftp.server.com"
$script:UserName = "login"
$script:Password= "password"
$script:SshHostKeyFingerprint = "ssh-rsa 2048 60:2b:98:ed:8b:ff:96:1f:e8:1d:3e:fe:ec:1c:90:0f"
$script:remoteUploadPath = "/Inbound/"
$script:remoteDownloadPath = "/Outbound/"

# Email Variables
$script:smptServer="mail.mckinstry.com"
$script:smptPort=25
$script:emailFrom="vpdev@mckinstry.com"
$script:emailToList="billo@mckinstry.com"
$script:emailCcList=$Null
#$script:emailToList="lockbox@mckinstry.com"
#$script:emailCcList="billo@mckinstry.com,terrya@mckinstry.com,howards@mckinstry.com"
$script:mailSubject = "VP Adaptive Trial Balance Export Processing Executed (DEV)"
$script:mailBody  = $Null

#Database Connection Strings
$Database = "Viewpoint"
$Server = "MCKTESTSQL04\VIEWPOINT"

#Export File

function ExportData 
{
	Param (
		[string]$Company
	,	[DateTime]$BeginningMonth
	,	[DateTime] $EndingMonth
	)
	
	$curAttachmentPath = $AttachmentPath -f $Company
	LogWrite($curAttachmentPath)
	
	$SqlQuery = "exec brptGLFinDet 
					@GLCo			=	" + $Company.ToString() + "
				,	@BegAcct 		=	'          '
				,	@EndAcct		=	'zzzzzzzzzz'
				,	@BegMonth		=	'" + $BeginningMonth.ToString("MM/dd/yyyy") -f $BeginningMonth + "'
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
	
	return $curAttachmentPath
}

function ExportData1
{	
	# Connect to SQL and query data, extract data to SQL Adapter
	#$SqlQuery = "SELECT * FROM mvwCreateACheckVendorExport ORDER BY VendorName"
	
	# SAMPLE DATA
	$SqlQuery = "exec brptGLFinDet 
					@GLCo			=	1
				,	@BegAcct 		=	'          '
				,	@EndAcct		=	'zzzzzzzzzz'
				,	@BegMonth		=	'1/1/2014'
				,	@EndMonth		=	'2/1/2014'
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
	LogWrite("`tto " + $AttachmentPath)

	#Export Hash Table to CSV File
	$objTable | Export-CSV $Attachment1Path -NoTypeInformation -Delimiter ","
	
}

function ExportData4
{	
	# Connect to SQL and query data, extract data to SQL Adapter
	#$SqlQuery = "SELECT * FROM mvwCreateACheckVendorExport ORDER BY VendorName"
	
	# SAMPLE DATA
	$SqlQuery = "exec brptGLFinDet 
					@GLCo			=	4
				,	@BegAcct 		=	'          '
				,	@EndAcct		=	'zzzzzzzzzz'
				,	@BegMonth		=	'1/1/2014'
				,	@EndMonth		=	'2/1/2014'
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
	LogWrite("`tto " + $AttachmentPath)

	#Export Hash Table to CSV File
	$objTable | Export-CSV $Attachment4Path -NoTypeInformation -Delimiter ","
	
}

function ExportData11
{	
	# Connect to SQL and query data, extract data to SQL Adapter
	#$SqlQuery = "SELECT * FROM mvwCreateACheckVendorExport ORDER BY VendorName"
	
	# SAMPLE DATA
	$SqlQuery = "exec brptGLFinDet 
					@GLCo			=	11
				,	@BegAcct 		=	'          '
				,	@EndAcct		=	'zzzzzzzzzz'
				,	@BegMonth		=	'1/1/2014'
				,	@EndMonth		=	'2/1/2014'
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
	LogWrite("`tto " + $AttachmentPath)

	#Export Hash Table to CSV File
	$objTable | Export-CSV $Attachment11Path -NoTypeInformation -Delimiter ","
	
}

function ExportData12
{	
	# Connect to SQL and query data, extract data to SQL Adapter
	#$SqlQuery = "SELECT * FROM mvwCreateACheckVendorExport ORDER BY VendorName"
	
	# SAMPLE DATA
	$SqlQuery = "exec brptGLFinDet 
					@GLCo			=	12
				,	@BegAcct 		=	'          '
				,	@EndAcct		=	'zzzzzzzzzz'
				,	@BegMonth		=	'1/1/2014'
				,	@EndMonth		=	'2/1/2014'
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
	LogWrite("`tto " + $AttachmentPath)

	#Export Hash Table to CSV File
	$objTable | Export-CSV $Attachment12Path -NoTypeInformation -Delimiter ","
	
}


function ExportData20
{	
	# Connect to SQL and query data, extract data to SQL Adapter
	#$SqlQuery = "SELECT * FROM mvwCreateACheckVendorExport ORDER BY VendorName"
	
	# SAMPLE DATA
	$SqlQuery = "exec brptGLFinDet 
					@GLCo			=	20
				,	@BegAcct 		=	'          '
				,	@EndAcct		=	'zzzzzzzzzz'
				,	@BegMonth		=	'1/1/2014'
				,	@EndMonth		=	'2/1/2014'
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
	LogWrite("`tto " + $AttachmentPath)

	#Export Hash Table to CSV File
	$objTable | Export-CSV $Attachment20Path -NoTypeInformation -Delimiter ","
	
}


function ExportData21
{	
	# Connect to SQL and query data, extract data to SQL Adapter
	#$SqlQuery = "SELECT * FROM mvwCreateACheckVendorExport ORDER BY VendorName"
	
	# SAMPLE DATA
	$SqlQuery = "exec brptGLFinDet 
					@GLCo			=	21
				,	@BegAcct 		=	'          '
				,	@EndAcct		=	'zzzzzzzzzz'
				,	@BegMonth		=	'1/1/2014'
				,	@EndMonth		=	'2/1/2014'
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
	LogWrite("`tto " + $AttachmentPath)

	#Export Hash Table to CSV File
	$objTable | Export-CSV $Attachment21Path -NoTypeInformation -Delimiter ","
	
}

function ExportData22
{	
	# Connect to SQL and query data, extract data to SQL Adapter
	#$SqlQuery = "SELECT * FROM mvwCreateACheckVendorExport ORDER BY VendorName"
	
	# SAMPLE DATA
	$SqlQuery = "exec brptGLFinDet 
					@GLCo			=	22
				,	@BegAcct 		=	'          '
				,	@EndAcct		=	'zzzzzzzzzz'
				,	@BegMonth		=	'1/1/2014'
				,	@EndMonth		=	'2/1/2014'
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
	LogWrite("`tto " + $AttachmentPath)

	#Export Hash Table to CSV File
	$objTable | Export-CSV $Attachment22Path -NoTypeInformation -Delimiter ","
	
}

function ExportData60
{	
	# Connect to SQL and query data, extract data to SQL Adapter
	#$SqlQuery = "SELECT * FROM mvwCreateACheckVendorExport ORDER BY VendorName"
	
	# SAMPLE DATA
	$SqlQuery = "exec brptGLFinDet 
					@GLCo			=	60
				,	@BegAcct 		=	'          '
				,	@EndAcct		=	'zzzzzzzzzz'
				,	@BegMonth		=	'1/1/2014'
				,	@EndMonth		=	'2/1/2014'
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
	LogWrite("`tto " + $AttachmentPath)

	#Export Hash Table to CSV File
	$objTable | Export-CSV $Attachment60Path -NoTypeInformation -Delimiter ","
	
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
	 
	 #$Attachment1 = new-object Net.Mail.Attachment($Attachment1Path)
	 #$Attachment4 = new-object Net.Mail.Attachment($Attachment4Path)
	 #$Attachment11 = new-object Net.Mail.Attachment($Attachment11Path)
	 #$Attachment12 = new-object Net.Mail.Attachment($Attachment12Path)
	 #$Attachment20 = new-object Net.Mail.Attachment($Attachment20Path)
	 #$Attachment21 = new-object Net.Mail.Attachment($Attachment21Path)
	 #$Attachment22 = new-object Net.Mail.Attachment($Attachment22Path)
	 #$Attachment60 = new-object Net.Mail.Attachment($Attachment60Path)
	 

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
	 
 	$msg.subject = "DEV/TEST ONLY : VP Adaptive Trial Balance Export [" + $Server + "." + $Database + "]"
	
	$msgBody = "<B>DEV/TEST ONLY</B><BR/><HR/>"
	$msgBody += "<P>Export/Upload of VP Trial Balance data for Adaptive Planning<BR/></P>"
	$msgBody +="<UL>"
	$msgBody +="<LI><I>" + $AttachmentPath + "</I></LI>"
	$msgBody +="</UL>"
	#$msgBody +="<BR/>"
	$msgBody +="<HR/>"
	$msgBody +="<P><FONT SIZE='-1'><I>"
	$msgBody += $script:compname + "==>" + $script:HostName + "/" + $script:remoteUploadPath + "<BR/>"
	$msgBody += (Get-Date).ToLongDateString() + " " + (Get-Date).ToShortTimeString()
	$msgBody +="</I></FONT></P>"
	
	$msg.body = $msgBody

    #$msg.subject = $script:mailSubject
    #$msg.body = $script:mailBody
	
	#$msg.Attachments.Add($Attachment1)
	#$msg.Attachments.Add($Attachment4)
	#$msg.Attachments.Add($Attachment11)
	#$msg.Attachments.Add($Attachment12)
	#$msg.Attachments.Add($Attachment20)
	#$msg.Attachments.Add($Attachment21)
	#$msg.Attachments.Add($Attachment22)
	#$msg.Attachments.Add($Attachment60)
	
    $msg.Attachments.Add($att)
	$msg.IsBodyHTML=$true
    #Sending email 
    $smtp.Send($msg)
	
	 $att.Dispose();
	#$Attachment1.Dispose();
	#$Attachment4.Dispose();
	#$Attachment11.Dispose();
	#$Attachment12.Dispose();
	#$Attachment20.Dispose();
	#$Attachment21.Dispose();
	#$Attachment22.Dispose();
	#$Attachment60.Dispose();
	
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

Function archiveFile
{
	$targetDir=$script:homeDir + "\Archive"
	Move-Item $Attachment1Path $targetDir -Force
	Move-Item $Attachment4Path $targetDir -Force
	Move-Item $Attachment11Path $targetDir -Force
	Move-Item $Attachment12Path $targetDir -Force
	Move-Item $Attachment20Path $targetDir -Force
	Move-Item $Attachment21Path $targetDir -Force
	Move-Item $Attachment22Path $targetDir -Force
	Move-Item $Attachment60Path $targetDir -Force
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
		ExportData "1" "1/1/2014" "3/1/2014" 
		#ExportData1
		#ExportData4
		#ExportData11
		#ExportData12
		#ExportData20
		#ExportData21
		#ExportData22
		#ExportData60
		
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
    exit 1
}
