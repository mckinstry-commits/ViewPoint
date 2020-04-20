# Adds HQBC record, ARPH records and associated attachment file from CSV import file.

# Script execution time stamp
[string]$ExecutionTimeStamp = Get-Date -Format u | foreach {$_ -replace ":", "."}

# ***********************************************************

# Config settings name
[string]$ConfigFileSettingsName = "ExpenseWire AP Entry Settings"

# ***********************************************************

# Build setting values from configuration file
[string]$ConfigFile = $PSScriptRoot + "\ViewPointImportSettings.xml"
[xml]$Config = Get-Content $ConfigFile
[System.Xml.XmlElement]$Setting = $Config.Settings.Setting | Where  { $_.Name -eq $ConfigFileSettingsName }

# ***********************************************************

# Stored procedure return parameter name
[string]$StoredProcedureReturnParameter = "@rcode"
# Stored procedure output parameter name
[string]$StoredProcedureOutputParameter = "@RetVal"
# Collection of stored procedure output codes and messages
[System.Collections.Hashtable]$ProcOutputValueMessageMappings = @{}
$ProcOutputValueMessageMappings.Add(0,"Attachment record created successfully.")
$ProcOutputValueMessageMappings.Add(1,"No record created.  Attachment document already exists.")
$ProcOutputValueMessageMappings.Add(2,"No record created.  Missing attachment parameters.")
$ProcOutputValueMessageMappings.Add(3,"No record created.  Error creating attachment record.")

# ***********************************************************

# Import common data routines
[string]$ScriptModuleFilePath = $PSScriptRoot + "\ViewPointImportCommon.ps1"
Import-Module -Global -Force -Name $ScriptModuleFilePath

function FetchAPHBRecordId
{
    [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [AllowNull()][AllowEmptyString()][string]$ExpenseID
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
            $SqlCommand = New-Object System.Data.SqlClient.SqlCommand("dbo.mckspCheckAPHB", $SqlConnection)
            $SqlCommand.CommandType = [System.Data.CommandType]::StoredProcedure

            $SqlCommand.Parameters.Add($StoredProcedureReturnParameter,  [System.Data.SqlDbType]::Int) | Out-Null
            $SqlCommand.Parameters[$StoredProcedureReturnParameter].Direction = [System.Data.ParameterDirection]::ReturnValue;

            $SqlCommand.Parameters.Add("@KeyID",  [System.Data.SqlDbType]::BigInt) | Out-Null
            $SqlCommand.Parameters["@KeyID"].Direction = [System.Data.ParameterDirection]::Output;

            # Build SQL proc parameters from input values
            $SqlCommand.Parameters.Add("@ExpenseID",  [System.Data.SqlDbType]::VarChar, 13) | Out-Null
            $SqlCommand.Parameters["@ExpenseID"].Value = $(if ($ExpenseID) { $ExpenseID } else { [DBNull]::Value })
 
            $SqlCommand.ExecuteNonQuery() | Out-Null
            $ReturnValue = $SqlCommand.Parameters[$StoredProcedureReturnParameter].Value;
            $KeyID = $SqlCommand.Parameters["@KeyID"].Value;
            $SqlCommand.Dispose() | Out-Null

            return $KeyID
        }
        catch [Exception]
        {
            WriteToLog("APHBRecordExists Error: " + $_.Exception.Message)
            return 0
        }
    }
    end
    {
        $SqlConnection.Close() | Out-Null
        $SqlConnection.Dispose() | Out-Null
    }
}

function CreateAPHBAttachment
{
    [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [string]$KeyID,
     [Parameter(Mandatory=$true)]
     [string]$Module,
	 [Parameter(Mandatory=$true)]
     [string]$FormName,
	 [Parameter(Mandatory=$true)]
     [string]$ImageFileName,
	 [Parameter(Mandatory=$true)]
     [string]$UserAccount
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
            $SqlCommand = New-Object System.Data.SqlClient.SqlCommand("dbo.mckspAPHBAddFile", $SqlConnection)
            $SqlCommand.CommandType = [System.Data.CommandType]::StoredProcedure

            $SqlCommand.Parameters.Add($StoredProcedureReturnParameter,  [System.Data.SqlDbType]::Int) | Out-Null
            $SqlCommand.Parameters[$StoredProcedureReturnParameter].Direction = [System.Data.ParameterDirection]::ReturnValue;

            $SqlCommand.Parameters.Add("@Company",  [System.Data.SqlDbType]::TinyInt) | Out-Null
            $SqlCommand.Parameters["@Company"].Direction = [System.Data.ParameterDirection]::Output;

            $SqlCommand.Parameters.Add("@InvoiceDate",  [System.Data.SqlDbType]::SmallDateTime) | Out-Null
            $SqlCommand.Parameters["@InvoiceDate"].Direction = [System.Data.ParameterDirection]::Output;

            $SqlCommand.Parameters.Add("@RetVal",  [System.Data.SqlDbType]::Int) | Out-Null
            $SqlCommand.Parameters["@RetVal"].Direction = [System.Data.ParameterDirection]::Output;

            # Build SQL proc parameters from input values
            $SqlCommand.Parameters.Add("@KeyID",  [System.Data.SqlDbType]::BigInt) | Out-Null
            $SqlCommand.Parameters["@KeyID"].Value = $KeyID
            $SqlCommand.Parameters.Add("@Module",  [System.Data.SqlDbType]::VarChar, 30) | Out-Null
            $SqlCommand.Parameters["@Module"].Value = $Module
            $SqlCommand.Parameters.Add("@FormName",  [System.Data.SqlDbType]::VarChar, 30) | Out-Null
            $SqlCommand.Parameters["@FormName"].Value = $FormName
            $SqlCommand.Parameters.Add("@ImageFileName",  [System.Data.SqlDbType]::NVarChar, 512) | Out-Null
            $SqlCommand.Parameters["@ImageFileName"].Value = $ImageFileName 
            $SqlCommand.Parameters.Add("@UserAccount",  [System.Data.SqlDbType]::NVarChar, 200) | Out-Null
            $SqlCommand.Parameters["@UserAccount"].Value = $UserAccount            
 
            $SqlCommand.ExecuteNonQuery() | Out-Null
            $ReturnValue = $SqlCommand.Parameters[$StoredProcedureReturnParameter].Value;
            $OutputValue = $SqlCommand.Parameters["@RetVal"].Value;
            $CompanyValue = $SqlCommand.Parameters["@Company"].Value;
            $InvoiceDateValue = $SqlCommand.Parameters["@InvoiceDate"].Value;
            $SqlCommand.Dispose() | Out-Null

            if ($ReturnValue -eq 0) {
                $Results = "Successful"
            }
            else {
                $Results = "Unsuccessful"
            }

            [object]$RowIndicator = $LogFileRecordField
            WriteToLog("Create attachment: " + $ImageFileName + ": " + $Results + " : " + $ProcOutputValueMessageMappings[$OutputValue])

            # Return array of needed values
            return @{"ReturnValue"=$ReturnValue;"CompanyValue"=$CompanyValue;"InvoiceDateValue"=$InvoiceDateValue}
        }
        catch [Exception]
        {
            WriteToLog("CreateAPHBAttachment Error: " + $_.Exception.Message)
            return return @{"ReturnValue"=1;"CompanyValue"=$null;"InvoiceDateValue"=$null}
        }
    }
    end
    {
        $SqlConnection.Close() | Out-Null
        $SqlConnection.Dispose() | Out-Null
    }
}

function ProcessExpenseWireFiles
{
    begin
    {
        WriteToLog("Started import for zip files in folder: " + $DataFilePath)
        WriteToLog("Environment: Server: " + $Server + " Database: " + $Database)
    }
    process
    {
        [int]$ZIPIncrement = 1
        # Fetch all ZIP files in directory
        $ZIPFiles = Get-ChildItem -Path $DataFilePath | Where { $_.Extension -eq ".zip"  }
        foreach ($ZIPFile in $ZIPFiles) {
            $KeyID = FetchAPHBRecordId $ZIPFile.BaseName
            if ($KeyID -gt 0) {
                try {
                    WriteToLog("Started processing zip file: " + $ZIPFile.FullName)
                    $UnpackedFilePath = $DataFilePath + $ExecutionTimeStamp + "_" + $ZIPIncrement.ToString()
                    $ZipUnpackaged = UnpackageZip $ZIPFile.FullName $UnpackedFilePath
                    if ($ZipUnpackaged -eq $true) {
                        # Fetch all PDF files from unpacked files
                        $PDFFilePath = $UnpackedFilePath + "\" + $ZIPFile.BaseName
                        $DataFiles = Get-ChildItem -Path $PDFFilePath | Where { $_.Extension -eq ".pdf"  }
                        foreach ($DataFile in $DataFiles) {
                            $ResultsAry = CreateAPHBAttachment $KeyID $Setting.Module $Setting.Form $DataFile.Name $Setting.UserAccount
                            if ($ResultsAry["ReturnValue"] -eq 0) {
                                $FileCopied = CopyImageFile $DataFile.FullName $ResultsAry["CompanyValue"] $Setting.Module $Setting.Form $ResultsAry["InvoiceDateValue"]
                                if ($FileCopied -eq $true) {
                                    $ArchiveFilePath = $Setting.ArchiveFilePath + $ZIPFile.BaseName
                                    $FileArchived = ArchiveImageFile $DataFile.FullName $ArchiveFilePath
                                    if ($FileArchived -eq $true) {
                                        $FileRemoved = RemoveFile $DataFile.FullName
                                    }
                                }
                            }
                        }
                        # Delete original zip file. Move unprocessed files back to original zip file.
                        $UnprocessedImageCount = CountImageFiles $PDFFilePath
                        $OriginalZipPath = $DataFilePath + $ZIPFile.Name
                        WriteToLog("Found unprocessed image files: " + $UnprocessedImageCount)
                        if ($UnprocessedImageCount -gt 0) {
                            # Package unprocessed files into original zip location
                            $ZipCreated = CreateZip $PDFFilePath $OriginalZipPath
                        }
                        else {
                            $ZipRemoved = RemoveFile $OriginalZipPath
                        }
                    }
                    else {
                        WriteToLog("Unable to process zip file: " + $ZIPFile.FullName)
                    }
                }
                catch [Exception] {
                    WriteToLog("Error processing zip file: " + $_.Exception.Message)
                }
                finally 
                {
                    # Remove unzipped files
                    $DirectoryRemoved = RemoveDirectory $UnpackedFilePath
                    $ZIPIncrement ++
                    WriteToLog("Finished processing zip file: " + $ZIPFile.FullName)
                }
            }
            else {
                WriteToLog("Unable to process zip file " + $ZIPFile.Name + ". No APHB header. Expense ID: " + $ZIPFile.BaseName)
            }
        }
    }
    end
    {
        WriteToLog("Completed import for zip files in folder: " + $DataFilePath)
    }
}

# Call main file copy and data import function
ProcessExpenseWireFiles


