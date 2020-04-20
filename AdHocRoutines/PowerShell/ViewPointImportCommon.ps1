# Common routines for Viewpoint data import

# Build setting values from configuration file
[string]$ConfigFile = $PSScriptRoot + "\ViewPointImportSettings.xml"
[xml]$Config = Get-Content $ConfigFile
[System.Xml.XmlElement]$Setting = $Config.Settings.Setting | Where  { $_.Name -eq $ConfigFileSettingsName }
[string]$Server = $Setting.Server
[string]$Database = $Setting.Database
[string]$Module = $Setting.Module
[string]$Form = $Setting.Form
[string]$DataFilePath = $Setting.DataFilePath
[string]$FullLogFilePath = $Setting.LogFilePath + $Setting.LogFileName + $ExecutionTimeStamp + ".txt"
[string]$ImageDestinationFilePath = $Setting.ImageDestinationFilePath


function ValidateDataRow
{
    [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [System.Object]$DataRow
     )
     process
     {
        try 
        {
        # Validate required fields.  Use field data columns stored in $RequiredFields Array
        foreach ($Field in $RequiredFields)
        {
            [object] $DataColumnName = $Field
            if ($DataRow.$DataColumnName -eq "") {
                return $false
            }
        }
        }
        catch {
            return $false
        }
        return $true
     }
}

function GetAttachmentPath
{
    [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [AllowNull()][AllowEmptyString()][string]$Company,
     [Parameter(Mandatory=$true)]
     [AllowNull()][AllowEmptyString()][string]$Module,
     [Parameter(Mandatory=$true)]
     [AllowNull()][AllowEmptyString()][string]$Form,
     [Parameter(Mandatory=$true)]
     [AllowNull()][AllowEmptyString()][string]$Month
     )
     begin
     {
        $SqlConnectionString = "Data Source=$Server;Initial Catalog=$Database;Integrated Security=True"
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection($SqlConnectionString)
     }
     process
     {
        try
        {
            $SqlConnection.Open() | Out-Null
            $SqlCommand = New-Object System.Data.SqlClient.SqlCommand("dbo.mfnDMAttachmentPath", $SqlConnection)
            $SqlCommand.CommandType = [System.Data.CommandType]::StoredProcedure

            $SqlCommand.Parameters.Add("@DMAttachmentPath",  [System.Data.SqlDbType]::VarChar, 255) | Out-Null
            $SqlCommand.Parameters["@DMAttachmentPath"].Direction = [System.Data.ParameterDirection]::ReturnValue;

            # Build SQL proc parameters from input values
            $SqlCommand.Parameters.Add("@Company",  [System.Data.SqlDbType]::TinyInt) | Out-Null
            $SqlCommand.Parameters["@Company"].Value = $(if ($Company) { $Company } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@Module",  [System.Data.SqlDbType]::VarChar, 10) | Out-Null
            $SqlCommand.Parameters["@Module"].Value = $(if ($Module) { $Module } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@Form",  [System.Data.SqlDbType]::VarChar, 50) | Out-Null
            $SqlCommand.Parameters["@Form"].Value = $(if ($Form) { $Form } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@Month", [System.Data.SqlDbType]::SmallDateTime) | Out-Null
            $SqlCommand.Parameters["@Month"].Value = $(if ($Month) { $Month } else { [DBNull]::Value })
 
            $SqlCommand.ExecuteNonQuery() | Out-Null
            $ReturnValue = $SqlCommand.Parameters["@DMAttachmentPath"].Value;
            $SqlCommand.Dispose() | Out-Null

            return $ReturnValue
        }
        catch [Exception]
        {
            WriteToLog("GetAttachmentPath Error: " + $_.Exception.Message)
            return ""
        }
    }
    end
    {
        $SqlConnection.Close() | Out-Null
        $SqlConnection.Dispose() | Out-Null
    }
}


function UploadDataRow
{
    [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [System.Object]$DataRow
     )
     begin
     {
        $SqlConnectionString = "Data Source=$Server;Initial Catalog=$Database;Integrated Security=True"
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection($SqlConnectionString)
     }
     process
     {
        try
        {
            $SqlConnection.Open() | Out-Null
            $SqlCommand = New-Object System.Data.SqlClient.SqlCommand($StoredProcedure, $SqlConnection)
            $SqlCommand.CommandType = [System.Data.CommandType]::StoredProcedure

            $SqlCommand.Parameters.Add($StoredProcedureReturnParameter,  [System.Data.SqlDbType]::Int) | Out-Null
            $SqlCommand.Parameters[$StoredProcedureReturnParameter].Direction = [System.Data.ParameterDirection]::ReturnValue;

            $SqlCommand.Parameters.Add($StoredProcedureOutputParameter,  [System.Data.SqlDbType]::Int) | Out-Null
            $SqlCommand.Parameters[$StoredProcedureOutputParameter].Direction = [System.Data.ParameterDirection]::Output;

            # Build SQL proc parameters from values stored in $ProcParameterDataMappings Hashtable
            foreach ($ProcParameter in $ProcParameterDataMappings.Keys)
            {
                [object]$DataColumnName = $ProcParameterDataMappings[$ProcParameter]
                [object]$ColValue = $DataRow.$DataColumnName
                if ($ColValue -eq "") {
                    $ColValue = $null # Set empty values to null to avoid data type conversion errors
                }
                $SqlCommand.Parameters.Add($ProcParameter, $ColValue) | Out-Null
            }

            # Build SQL proc parameters from values stored in $ProcParameterValueMappings Hashtable
            foreach ($ProcParameter in $ProcParameterValueMappings.Keys)
            {
                $SqlCommand.Parameters.Add($ProcParameter, $ProcParameterValueMappings[$ProcParameter]) | Out-Null
            }
 
            $SqlCommand.ExecuteNonQuery() | Out-Null
            $ReturnValue = $SqlCommand.Parameters[$StoredProcedureReturnParameter].Value;
            $OutputValue = $SqlCommand.Parameters[$StoredProcedureOutputParameter].Value;
            $SqlCommand.Dispose() | Out-Null

            [string]$Results = ""
            if ($ReturnValue -eq 0) {
                $Results = "Successful"
            }
            else {
                $Results = "Unsuccessful"
            }

            [object]$RowIndicator = $LogFileRecordField
            WriteToLog("Upload record " + $DataRow.$RowIndicator + ": " + $Results + " : " + $ProcOutputValueMessageMappings[$OutputValue])
            return $OutputValue
        }
        catch [Exception]
        {
            WriteToLog("Error processing record: " + $_.Exception.Message)
            return -1
        }
    }
    end
    {
        $SqlConnection.Close() | Out-Null
        $SqlConnection.Dispose() | Out-Null
    }
}

function CopyImageFile
{
    [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [string]$FullFileName,
     [Parameter(Mandatory=$true)]
     [AllowNull()][AllowEmptyString()][string]$Company,
     [Parameter(Mandatory=$true)]
     [AllowNull()][AllowEmptyString()][string]$Module,
     [Parameter(Mandatory=$true)]
     [AllowNull()][AllowEmptyString()][string]$Form,
     [Parameter(Mandatory=$true)]
     [AllowNull()][AllowEmptyString()][string]$Month
     )
     try
     {
        $DestinationFolder = GetAttachmentPath $Company $Module $Form $Month
        $Results = CopyFile $FullFileName $DestinationFolder
        [string]$Result = ""
        if ($Results -eq $true) {
            $Result = "Successful"
        }
        else {
            $Result = "Unsuccessful"
        }
        WriteToLog("Copying file '" + $FullFileName + "' to '" + $DestinationFolder + "': " + $Result)
        return $Results
    }
    catch [Exception] {
        WriteToLog("Error copying image file: " + $_.Exception.Message)
        return $false
    }
}

function ArchiveImageFile
{
    [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [string]$FullFileName,
     [Parameter(Mandatory=$true)]
     [string]$ArchiveFilePath
     )
     try
     {
        $Results = CopyFile $FullFileName $ArchiveFilePath
        [string]$Result = ""
        if ($Results -eq $true) {
            $Result = "Successful"
        }
        else {
            $Result = "Unsuccessful"
        }
        WriteToLog("Archiving file '" + $FullFileName + "' to '" + $DestinationFolder + "': " + $Result)
        return $Results
    }
    catch [Exception] {
        WriteToLog("Error archiving image file: " + $_.Exception.Message)
        return $false
    }
}

function RemoveFile
{
    [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [string]$FilePath
     )
    try
    {
        $Results = DeleteFile $FilePath
        [string]$Result = ""
        if ($Results -eq $true) {
            $Result = "Successful"
        }
        else {
            $Result = "Unsuccessful"
        }
        WriteToLog("Removing file '" + $FilePath + "': " + $Result)
        return $Results
    }
    catch [Exception] {
        WriteToLog("Error removing file: " + $_.Exception.Message)
        return $false
    }
}

function WriteToLog
{
   param (
    [string]$LogString
   )
   [string]$Date = Get-Date -Format u
   $LogEntry = $Date + "`t" + $LogString
   Add-content $FullLogFilePath -value $LogEntry
}

function CopyFile
{
    param (
    [string]$FullSourceFilePath,
    [string]$DestinationFilePath
    )
    try
    {
        if ((Test-Path $DestinationFilePath) -eq 0) {
            New-Item -ItemType Directory -Force -Path $DestinationFilePath | Out-Null
        }
        Copy-Item $FullSourceFilePath $DestinationFilePath -Force -ErrorAction SilentlyContinue
    }
    catch {
        return $false
    }
    return $?
}

function DeleteFile
{
    param (
    [string]$FilePath
    )
    try
    {
        Remove-Item $FilePath -recurse -ErrorAction SilentlyContinue
    }
    catch {
        return $false
    }
    return $?
}

function UnpackageZip
{
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$true)]
    [string]$ZipPath,
    [Parameter(Mandatory=$true)]
    [string]$DestinationPath
    )
    $FolderOkay = EnsureDirectory($DestinationPath)
    if ($FolderOkay -eq $true) {
        try
        {
            WriteToLog("Unpackaging zip files to directory: " + $DestinationPath)
            $Shell = New-Object -com shell.application
            $Zip = $Shell.NameSpace($ZipPath)
            $Destination = $Shell.NameSpace($DestinationPath)
            $Destination.CopyHere($Zip.items(), 0x14)
        }
        catch [Exception]
        {
            WriteToLog("Error unpackaging zip files to directory: " + $_.Exception.Message)
            return $false;
        }
        finally {
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Shell)
            Remove-Variable Shell
        }
    }
    else {
        WriteToLog("Unable to unpackage zip files.  Cannot find directory: " + $DestinationPath)
        return $false;
    }
    return $?
}

function CreateZip
{
   [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [string]$SourceDirectory,
     [Parameter(Mandatory=$true)]
     [string]$FullZipFileName
     )
    try
    {
        $FileRemoved = RemoveFile $FullZipFileName
        Add-Type -Assembly System.IO.Compression.FileSystem
        $CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
        [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDirectory, $FullZipFileName, $CompressionLevel, $false)
    }
    catch [Exception] {
        WriteToLog("Error creating zip file: " + $_.Exception.Message)
        return $false
    }
    return $?
}

function CountImageFiles
{
   [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [string]$ImageDirectory
     )
    try
    {
        $DataFiles = Get-ChildItem -Path $ImageDirectory | Where { $_.Extension -eq ".pdf"  }
        return $DataFiles.Length
    }
    catch [Exception] {
        WriteToLog("Error counting images: " + $_.Exception.Message)
        return 0
    }
}

function EnsureDirectory
{
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$true)]
    [string]$FilePath
    )
    try
    {
        WriteToLog("Creating directory: " + $FilePath)
        if ((Test-Path $FilePath) -eq 0) {
            
            New-Item -ItemType Directory -Force -Path $FilePath | Out-Null
        }
        else {
            WriteToLog("Directory already exists: " + $FilePath)
        }
    }
    catch [Exception]
    {
        WriteToLog("Error creating directory: " + $_.Exception.Message)
        return $false;
    }
    return $?
}

function RemoveDirectory
{
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$true)]
    [string]$FilePath
    )
    try
    {
        WriteToLog("Removing directory: " + $FilePath)
        if ((Test-Path $FilePath) -eq 1) {
            Remove-Item -Recurse -Force -Path $FilePath | Out-Null
        }
        else {
            WriteToLog("Directory does not exist: " + $FilePath)
            return $false;
        }
    }
    catch [Exception]
    {
        WriteToLog("Error removing directory: " + $_.Exception.Message)
        return $false;
    }
    return $?
}

# SIG # Begin signature block
# MIITrgYJKoZIhvcNAQcCoIITnzCCE5sCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJgCKiiZB+Qn5z0Xn/A0dfGKJ
# rdqggg36MIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFOsIFJWixoEjdW7U
# Pk14c8XxhRjkMA0GCSqGSIb3DQEBAQUABIIBAFFF+5lCfVmoBnsYF4q1QZeMKQvZ
# oivFuvsAaMqxUEcUPHitp2wEsYp6oBqTmU6nlVcsqj25jtaht71jKOAxfDxYK3cy
# 5eXVJ81rYmaJm5RjgU3WXpnAhnP2OYWgyQd3fgWDZRR1WLzovVzuorxjjcpyhuiB
# GYNJunVomCPIRS2UJl1Z9q2/Z51t+UbO7qHoNMXdQXIIh+kyCVTQRa1IxflSyrQO
# cd3tvVJRTcFL7kJ2Y5fTU5OCDc/Arl/OsJx7WD8VqXm3z5bO4esL2VbWSxA7fd0O
# 03LTffEViCxIUpmmMelg5SiZPuLAdL5Cc59J93PhVb/mhtkU98okFJDhArKhggKi
# MIICngYJKoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZMBcG
# A1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1l
# c3RhbXBpbmcgQ0EgLSBHMgISESFAXB8O0liIK+VNhoa6EepFMAkGBSsOAwIaBQCg
# gf0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTQx
# MjEwMDA0NTMyWjAjBgkqhkiG9w0BCQQxFgQUlDx3PyhOktMSoxTCHgRdNOldg9Ew
# gZ0GCyqGSIb3DQEJEAIMMYGNMIGKMIGHMIGEBBSM5p9QEuHRqPs5Xi4x4rQr3js0
# OzBsMFakVDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1z
# YTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESFA
# XB8O0liIK+VNhoa6EepFMA0GCSqGSIb3DQEBAQUABIIBABu0mGAC8FXyXr+4bkBj
# YFrfdUPi5kk+v9KsMLuz/65Z4DtztXMUwJFNSGoDjy+l7SxlgCB2GFkduTJkrbGK
# jGZCnuqgnDWn6lGvDTWUc9JMeF4MmiaPaNgGGwOPvYO4/TLgLIGOgFuJn/CcvC7/
# dtVs7dglaGB8a0eeQ3Lm4l+t47NVGjQjsY624+6veZlQFuucLUBZYuuyoD8foFJK
# oMTl7VPCt60euLj4ZJbkEn+OEH/jR3GxUopM+mf7MgAydvczq/XyWXNuIinWFYOE
# d7wGKgWLSwnkpfjHn/0B7gx8QhQQCPQJjoBahA0lDTnhEugpkvDvtG4DetzGiFOU
# U4s=
# SIG # End signature block
