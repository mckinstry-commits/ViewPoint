# Moves unmatched APUI records between companies.

# Script execution time stamp
[string]$ExecutionTimeStamp = Get-Date -Format u | foreach {$_ -replace ":", "."}

# ***********************************************************

# Config settings name
[string]$ConfigFileSettingsName = "AP Unmatched Company Move Settings"

# ***********************************************************

# Build setting values from configuration file
[string]$ConfigFile = "C:\Scripts\RetailLockBox\ViewPointImportSettings.xml"
[xml]$Config = Get-Content $ConfigFile
[System.Xml.XmlElement]$Setting = $Config.Settings.Setting | Where  { $_.Name -eq $ConfigFileSettingsName }

# ***********************************************************

# Stored procedure name to execute
[string]$StoredProcedure = "dbo.mckspAPUIMoveCo" 
# Stored procedure return parameter name
[string]$StoredProcedureReturnParameter = "@rcode"
# Stored procedure output parameter name
[string]$StoredProcedureOutputParameter = "@RetVal"
# Collection of stored procedure output codes and messages
[System.Collections.Hashtable]$ProcOutputValueMessageMappings = @{}
$ProcOutputValueMessageMappings.Add(0,"Batch processed successfully.")
$ProcOutputValueMessageMappings.Add(1,"Batch not processed.  Missing parameters.")

# ***********************************************************

# Import common data routines
[string]$ScriptModuleFilePath = "C:\Scripts\RetailLockBox\ViewPointImportCommon.ps1"
Import-Module -Global -Force -Name $ScriptModuleFilePath

function MoveImageFile
{
    [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [string]$SourceFileName,
     [Parameter(Mandatory=$true)]
     [string]$DestinationFileName
     )
     try
     {
        $DestinationFolder = $DestinationFileName.SubString(0, $DestinationFileName.LastIndexOf("\"))
        $Results = CopyFile $SourceFileName $DestinationFolder
        [string]$Result = ""
        if ($Results -eq $true) {
            $Result = "Successful"
        }
        else {
            $Result = "Unsuccessful"
        }
        WriteToLog("Copying file '" + $SourceFileName + "' to '" + $DestinationFolder + "': " + $Result)
        return $Results
    }
    catch [Exception] {
        WriteToLog("Error copying image file: " + $_.Exception.Message)
        return $false
    }
}

function ProcessOutput
{
    param (
    [string]$Success,
    [string]$Copy,
    [string]$Failure
    )
    if ($Success) {
        [string[]]$SuccessResults = $Success.Split(';',[System.StringSplitOptions]::RemoveEmptyEntries)
        foreach ($SuccessItem in $SuccessResults) {
            [string[]]$MovedItems = $SuccessItem.Split('|',[System.StringSplitOptions]::RemoveEmptyEntries)
            WriteToLog("'APRef " + $MovedItems[1] + "' successfully moved from Company " + $MovedItems[0] + " to Company " + $MovedItems[2])
        }
    }
    else {
        WriteToLog("No AP header records moved.")
    }
    if ($Copy) {
        [string[]]$CopyResults = $Copy.Split(';',[System.StringSplitOptions]::RemoveEmptyEntries)
        foreach ($CopyItem in $CopyResults) {
            [string[]]$CopyItems = $CopyItem.Split('|',[System.StringSplitOptions]::RemoveEmptyEntries)
            $FileCopied = MoveImageFile $CopyItems[0] $CopyItems[1]
        }
    }
    if ($Failure) {
        [string[]]$FailureResults = $Failure.Split(';',[System.StringSplitOptions]::RemoveEmptyEntries)
        foreach ($FailureItem in $FailureResults) {
            [string[]]$FailureItems = $FailureItem.Split('|',[System.StringSplitOptions]::RemoveEmptyEntries)
            WriteToLog("APRef: " + $FailureItems[0] + " --> Exception: " + $FailureItems[1])
        }
    }
}

function ExecuteCompanyMove
{
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

            $SqlCommand.Parameters.Add("@Module",  [System.Data.SqlDbType]::VarChar, 30)| Out-Null
            $SqlCommand.Parameters["@Module"].Value = $(if ($Setting.Module) { $Setting.Module } else { [DBNull]::Value })

            $SqlCommand.Parameters.Add("@FormName",  [System.Data.SqlDbType]::VarChar, 30)| Out-Null
            $SqlCommand.Parameters["@FormName"].Value = $(if ($Setting.Form) { $Setting.Form } else { [DBNull]::Value })

            $SqlCommand.Parameters.Add("@UserAccount",  [System.Data.SqlDbType]::VarChar, 200)| Out-Null
            $SqlCommand.Parameters["@UserAccount"].Value = $(if ($Setting.UserAccount) { $Setting.UserAccount } else { [DBNull]::Value })

            $SqlCommand.Parameters.Add("@Success",  [System.Data.SqlDbType]::VarChar, -1)| Out-Null
            $SqlCommand.Parameters["@Success"].Direction = [System.Data.ParameterDirection]::Output;

            $SqlCommand.Parameters.Add("@FileCopy",  [System.Data.SqlDbType]::VarChar, -1)| Out-Null
            $SqlCommand.Parameters["@FileCopy"].Direction = [System.Data.ParameterDirection]::Output;

            $SqlCommand.Parameters.Add("@Failure",  [System.Data.SqlDbType]::VarChar, -1)| Out-Null
            $SqlCommand.Parameters["@Failure"].Direction = [System.Data.ParameterDirection]::Output;
 
            $SqlCommand.ExecuteNonQuery() | Out-Null
            $ReturnValue = $SqlCommand.Parameters[$StoredProcedureReturnParameter].Value;
            $OutputValue = $SqlCommand.Parameters[$StoredProcedureOutputParameter].Value;

            $SuccessValue = $SqlCommand.Parameters["@Success"].Value;
            $FileCopyValue = $SqlCommand.Parameters["@FileCopy"].Value;
            $FailureValue = $SqlCommand.Parameters["@Failure"].Value;

            $SqlCommand.Dispose() | Out-Null

            [string]$Results = ""
            if ($ReturnValue -eq 0) {
                $Results = "Successful"
            }
            else {
                $Results = "Unsuccessful"
            }

            WriteToLog("Processing batch: " + $Results + " : " + $ProcOutputValueMessageMappings[$OutputValue])

            ProcessOutput $SuccessValue $FileCopyValue $FailureValue
        }
        catch [Exception]
        {
            WriteToLog("Error executing function ExecuteCompanyMove : " + $_.Exception.Message)
        }
    }
    end
    {
        $SqlConnection.Close() | Out-Null
        $SqlConnection.Dispose() | Out-Null
    }
}


function ProcessAPUnmatchedCompanies
{
    begin
    {
        WriteToLog("Starting AP Unmatched Company Move bach process.")
        WriteToLog("Environment: Server: " + $Server + " Database: " + $Database)
    }
    process
    {
        try {
            ExecuteCompanyMove
        }
        catch [Exception] {
            WriteToLog("Error processing batch: " + $_.Exception.Message)
        }
    }
    end
    {
        WriteToLog("Completed AP Unmatched Company Move bach process.")
    }
}

# Call main function
ProcessAPUnmatchedCompanies
