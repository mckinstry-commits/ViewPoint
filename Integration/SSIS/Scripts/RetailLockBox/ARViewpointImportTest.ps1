# Adds HQBC record, ARPH records and associated attachment file from CSV import file.

# Script execution time stamp
[string]$ExecutionTimeStamp = Get-Date -Format u | foreach {$_ -replace ":", "."}

# ***********************************************************

# Config settings name
[string]$ConfigFileSettingsName = "AR Cash Receipts Settings"

# ***********************************************************

# Build setting values from configuration file
[string]$ConfigFile = $PSScriptRoot + "\ViewPointImportSettings.xml"
[xml]$Config = Get-Content $ConfigFile
[System.Xml.XmlElement]$Setting = $Config.Settings.Setting | Where  { $_.Name -eq $ConfigFileSettingsName }

# ***********************************************************

# Stored procedure name to execute
[string]$StoredProcedure = "dbo.mckspARBHAddItemWithFile" 
# Stored procedure return parameter name
[string]$StoredProcedureReturnParameter = "@rcode"
# Stored procedure output parameter name
[string]$StoredProcedureOutputParameter = "@RetVal"
# Collection of stored procedure parameters and corresponding CSV data columns from import file
[System.Collections.Hashtable]$ProcParameterDataMappings = @{"@Company"="Company";"@TransactionDate"="TransactionDate";"@Customer"="Customer";"@CustomerGroup"="CustGroup";"@InvoiceNumber"="InvoiceNumber";"@CheckNumber"="CollectedCheckNumber";"@CheckDate"="CollectedCheckDate";"@ImageFileName"="CollectedImage"} 
# Collection of required data fields from CSV import file
[System.Array]$RequiredFields = @("CollectedImage")
# Collection of stored procedure parameters and static values
[System.Collections.Hashtable]$ProcParameterValueMappings = @{"@Module"=$Setting.Module;"@FormName"=$Setting.Form;"@UserAccount"=$Setting.UserAccount}
# Collection of stored procedure output codes and messages
[System.Collections.Hashtable]$ProcOutputValueMessageMappings = @{}
$ProcOutputValueMessageMappings.Add(0,"Batch, Header and Attachment records created successfully.")
$ProcOutputValueMessageMappings.Add(1,"Batch, Header records created successfully.  Attachment exists.")
$ProcOutputValueMessageMappings.Add(2,"Header and Attachment records created successfully.")
$ProcOutputValueMessageMappings.Add(3,"Header record created successfully.  Attachment exists.")
$ProcOutputValueMessageMappings.Add(4,"Standalone attachment created.  Missing batch parameters.")
$ProcOutputValueMessageMappings.Add(5,"Standalone attachment created.  Missing header parameters.")
$ProcOutputValueMessageMappings.Add(6,"Standalone attachment created.  Error creating batch record.")
$ProcOutputValueMessageMappings.Add(7,"Standalone attachment created.  Error creating header record.")
$ProcOutputValueMessageMappings.Add(8,"No records created.  Missing attachment parameters.")
$ProcOutputValueMessageMappings.Add(9,"No records created.  Attachment exists.")
$ProcOutputValueMessageMappings.Add(10,"No records created.  Error creating attachment record.")
$ProcOutputValueMessageMappings.Add(11,"Header record created successfully. Error creating attachment record.")
$ProcOutputValueMessageMappings.Add(12,"Batch and Header records created successfully. Error creating attachment record.")
# Record field to use as reference in log file
[string]$LogFileRecordField = "InvoiceNumber"
# Record field to use as reference for image file name
[string]$ImageFileNameRecordField = "CollectedImage"

# ***********************************************************

# Import common data routines
[string]$ScriptModuleFilePath = $PSScriptRoot + "\ViewPointImportCommon.ps1"
Import-Module -Global -Force -Name $ScriptModuleFilePath

function ShouldCopyImage
{
    [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [int]$TestValue
     )
    $ShouldCopy=$false
    switch ($TestValue) 
    { 
        0 {$ShouldCopy=$true} 
        2 {$ShouldCopy=$true} 
        4 {$ShouldCopy=$true} 
        5 {$ShouldCopy=$true} 
        6 {$ShouldCopy=$true} 
        7 {$ShouldCopy=$true}
        default {$ShouldCopy=$false}
    }
    return $ShouldCopy
}

function UploadDataRowAR
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

            $SqlCommand.Parameters.Add("@BatchId",  [System.Data.SqlDbType]::Int) | Out-Null
            $SqlCommand.Parameters["@BatchId"].Direction = [System.Data.ParameterDirection]::Output;

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
            $BatchIDValue = $SqlCommand.Parameters["@BatchId"].Value;

            $SqlCommand.Dispose() | Out-Null

            [string]$Results = ""
            if ($ReturnValue -eq 0) {
                $Results = "Successful"
            }
            else {
                $Results = "Unsuccessful"
            }

            [object]$RowIndicator = $LogFileRecordField
            WriteToLog("Upload record " + $DataRow.$RowIndicator + ", Batch ID " + $BatchIDValue + " : " + $Results + " : " + $ProcOutputValueMessageMappings[$OutputValue])
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


function ProcessARDataRecords
{
    begin
    {
        WriteToLog("Started import for data files in folder: " + $DataFilePath)
    }
    process
    {
        [int]$ZIPIncrement = 1
        # Fetch all ZIP files in directory
        $ZIPFiles = Get-ChildItem -Path $DataFilePath | Where { $_.Extension -eq ".zip"  }
        foreach ($ZIPFile in $ZIPFiles) {
            try
            {
                WriteToLog("Started processing zip file: " + $ZIPFile.FullName)
                $UnpackedFilePath = $DataFilePath + $ExecutionTimeStamp + "_" + $ZIPIncrement.ToString()
                $ZipUnpackaged = UnpackageZip $ZIPFile.FullName $UnpackedFilePath
                if ($ZipUnpackaged -eq $true) {
                    # Fetch all CSV files from unpacked files
                    $DataFiles = Get-ChildItem -Path $UnpackedFilePath | Where { $_.Extension -eq ".csv"  }
                    foreach ($DataFile in $DataFiles) {
                        $File = Import-Csv -LiteralPath $DataFile.FullName -delimiter "$([char]0x7C)" | Sort-Object {[int] $_.Company}
                        if ($File -ne $null) {
                            WriteToLog("Started import for data file: " + $DataFile.FullName)
                            WriteToLog("Environment: Server: " + $Server + " Database: " + $Database)
                            # Process each data record in CSV file
                            foreach ($DataRow in $File) {
                                if ((ValidateDataRow $DataRow) -eq $true) {
                                    Write-Host "CollectedImage: " $DataRow.CollectedImage
                                    #$OutputValue = UploadDataRowAR $DataRow
                                    #$ShouldCopyImage = ShouldCopyImage($OutputValue)
                                    #if ($ShouldCopyImage -eq $true) {
                                        #$ImageFilePath = $UnpackedFilePath + "\" + $DataRow.$ImageFileNameRecordField
                                        #$FileCopied = CopyImageFile $ImageFilePath $DataRow.Company $Setting.Module $Setting.Form $DataRow.CollectedCheckDate
                                    #}
                                }
                                else {
                                    WriteToLog("Unable to process record. Missing minimum required data.")
                                }
                            }
                            WriteToLog("Completed import for data file: " + $DataFile.FullName)
                        }
                        else {
                            WriteToLog("Unable to process data file. Missing File.")
                        }
                    }  
                }
                else {
                    WriteToLog("Unable to process zip file: " + $ZIPFile.FullName)
                }
            }
            catch [Exception] {
                WriteToLog("Error processing zip file: " + $_.Exception.Message)
            }
            finally {
                # Remove unzipped files
                #$DirectoryRemoved = RemoveDirectory $UnpackedFilePath
                # Archive zip file
                #$ArchiveFilePath = $Setting.ArchiveFilePath + $ZIPFile.BaseName
                #$FileArchived = ArchiveImageFile $ZIPFile.FullName $ArchiveFilePath
                #if ($FileArchived -eq $true) {
                    #$FileRemoved = RemoveFile $ZIPFile.FullName
                #}
                $ZIPIncrement ++
                WriteToLog("Finished processing zip file: " + $ZIPFile.FullName)
            }
        }
    }
    end
    {
        WriteToLog("Completed import for data files in folder: " + $DataFilePath)
    }
}

# Call main file copy and data import function
ProcessARDataRecords
