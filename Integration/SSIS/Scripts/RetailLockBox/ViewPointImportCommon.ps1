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
