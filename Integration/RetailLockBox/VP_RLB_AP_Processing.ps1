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
$script:FilesToGet = 1

# Local Variables
$script:compname = gc env:computername
$script:homeDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
$script:downloadDir = $script:homeDir + "\Download\" 
$script:uploadDir = $script:homeDir + "\Upload\" 
$script:logFile = $script:homeDir + "\Log\ProcessLog.txt" 

$APAttachmentPath = $script:uploadDir + "RLB_AP_Header_Export.csv"

#Remote Variables
$script:Protocol = [WinSCP.Protocol]::Sftp
$script:HostName = "sftp.retaillockbox.com"
$script:UserName = "mckinstry"
$script:Password= "ch@ngem3"
$script:SshHostKeyFingerprint = "ssh-rsa 2048 60:2b:98:ed:8b:ff:96:1f:e8:1d:3e:fe:ec:1c:90:0f"
$script:remoteUploadPath = "/VPERP/Inbound/"
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
$script:mailSubject = "VP RLB Processing Executed (DEV)"
$script:mailBody  = $Null

#Database Connection Strings
$Database = "Viewpoint"
$Server = "MCKTESTSQL04\VIEWPOINT"

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

function sendMailAP
{
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
	 
 	$msg.subject = "RLB AP Data Exchange [" + $Server + "." + $Database + "]"
	
	$msgBody = "<BR/><HR/>"
	$msgBody += "<P>Export/Upload of AP Data for Retail Lock Box<BR/>"
	$msgBody += "and Download of Retail Lock Box supplied data/images.</P>"
    $msgBody +="Uploads:"
	$msgBody +="<UL>"
	$msgBody +="<LI><I>" + $script:compname + ":" + $APAttachmentPath + "</I></LI>"
	$msgBody +="</UL>"
	$msgBody +="<BR/>"
    $msgBody +="Downloads:"
	$msgBody +="<UL>"
	$msgBody +="<LI><I>" + $script:compname + ":" + $script:downloadDir + "AP\" + "</I></LI>"
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
    $msg.Attachments.Add($att)
	$msg.IsBodyHTML=$true
    #Sending email 
    $smtp.Send($msg)
	 
	$APAttachment.Dispose();
	$msg.Dispose();
  
}

Function LogWrite
{
   Param ([string]$logstring)
  
   $ts = (Get-Date).ToLongTimeString() + "`t" + $logstring
   $script:mailBody=$script:mailBody+$ts+"`r`n"
   Add-content $Logfile -value $ts
}

Function archiveFileAP
{
	$targetDir=$script:homeDir + "\Archive"
	
	get-childitem$targetDir -include *.* -recurse | foreach ($_) {remove-item $_.fullname}
	
	Move-Item $APAttachmentPath $targetDir -Force
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
	LogWrite("Remote AP Upload Dir:   " + $script:remoteAPUploadPath)
	LogWrite("Remote AP Download Dir:   " + $script:remoteAPDownloadPath)
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
		LogWrite("")
		UploadVPAPFiles
		LogWrite("")
		GetVPAPFiles
        [string]$APViewPointImportFilePath = $PSScriptRoot + "\APViewPointImport.ps1"
        Import-Module -Global -Force -Name $APViewPointImportFilePath
	}
	finally
    {       
        sendMailAP
		archiveFileAP
    }
	exit 0
}
catch [Exception]
{
    Write-Host $_.Exception.Message
    exit 1
}

# SIG # Begin signature block
# MIITrgYJKoZIhvcNAQcCoIITnzCCE5sCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8IIuvGXhAYDU/q5AGgncAC6k
# mN2ggg36MIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFAVHikPjiqVL2n+z
# WrLQpNnRmrWQMA0GCSqGSIb3DQEBAQUABIIBABeZyt5K4daFc5RZso+F3EAvf66d
# GAwHH1cs3OCtGvd1Un6pAa8MTlOvOGFiL/QehWMqkR0jnG2kHw/mzaJNMnD7F4EZ
# paEksNTb12guQoossC2MTwMPqhZdXMvB9Ajr9SJer0MJHkmJAGUFAPOZNpdDxaz/
# 6TJWRdk7i3By/5UfKLUpiSleMEQglK4cpo+yknVhAKdYPjFIFW+SRmiQ1r04FITm
# oIaBWvh5Z6VLVBNoahaw1O2xxTPT8rvkm2lsJD/N+AoMK5i0UVzjGW7RKIFyioBJ
# vvubDvXVTgYyd98lzg2kA/anXcaEwvuZITJlGRByWuzYBYUNQoZ8uXY7SmqhggKi
# MIICngYJKoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZMBcG
# A1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1l
# c3RhbXBpbmcgQ0EgLSBHMgISESFAXB8O0liIK+VNhoa6EepFMAkGBSsOAwIaBQCg
# gf0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTQx
# MDAzMDAyMjM3WjAjBgkqhkiG9w0BCQQxFgQUF2gA6E+1GTd+N73M72gNzSvREnMw
# gZ0GCyqGSIb3DQEJEAIMMYGNMIGKMIGHMIGEBBSM5p9QEuHRqPs5Xi4x4rQr3js0
# OzBsMFakVDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1z
# YTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESFA
# XB8O0liIK+VNhoa6EepFMA0GCSqGSIb3DQEBAQUABIIBAH/LWL9vmRHOQnO3TLQY
# 9KKs6UM2gAkFsEjRRHetzWmBafGQj9krS1DNwxoHhbpx1UW+bphNulefDwTPEt5C
# GROYX917qWrLcvHwmsQE6ojI7FkLVC48idqZOiWwb3tnsaNKbWIdLINaDauYIahH
# echT/v0YZLKvVrlFZhlFO90mP9gW2yxn15n2LBEGnZXH7BJ6bR5LIpCgluBqmehK
# 4xpvZRrSe6o4cBe2Pw5yRu2Dywkt06jlmU24Ls9vffcP3HddDXJZZL7i01HYiTeY
# ka9/6YGZ5jiSg2ZG7kYK5XoJF+uRk8Kffp9d6vAxvxTyo+MSAdApJnqOgmcqhGN6
# fhc=
# SIG # End signature block
