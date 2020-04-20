# Adds APUI header record, APUL detail records and associated attachment file from CSV import file.

# Script execution time stamp
[string]$ExecutionTimeStamp = Get-Date -Format u | foreach {$_ -replace ":", "."}

# ***********************************************************

# Config settings name
[string]$ConfigFileSettingsName = "AP Unapproved Invoice Settings"

# ***********************************************************

# Build setting values from configuration file
[string]$ConfigFile = $PSScriptRoot + "\ViewPointImportSettings.xml"
[xml]$Config = Get-Content $ConfigFile
[System.Xml.XmlElement]$Setting = $Config.Settings.Setting | Where  { $_.Name -eq $ConfigFileSettingsName }

# ***********************************************************

# Stored procedure name to execute
[string]$StoredProcedure = "dbo.mckspAPUIAddItemWithFile" 
# Stored procedure return parameter name
[string]$StoredProcedureReturnParameter = "@rcode"
# Stored procedure output parameter name
[string]$StoredProcedureOutputParameter = "@RetVal"
# Collection of stored procedure parameters and corresponding CSV data columns from import file
[System.Collections.Hashtable]$ProcParameterDataMappings = @{"@RecordType"="RecordType";"@Company"="Company";"@Number"="Number";"@VendorGroup"="VendorGroup";"@Vendor"="Vendor";"@CollectedInvoiceNumber"="CollectedInvoiceNumber";"@Description"="Description";"@CollectedInvoiceDate"="CollectedInvoiceDate";"@CollectedInvoiceAmount"="CollectedInvoiceAmount";"@CollectedTaxAmount"="CollectedTaxAmount";"@CollectedShippingAmount"="CollectedShippingAmount";"@ImageFileName"="CollectedImage"} 
# Collection of required data fields from CSV import file
[System.Array]$RequiredFields = @("CollectedImage") 
# Transaction Date
[string]$TransactionDate = "11/30/2014"
# Collection of stored procedure parameters and static values
[System.Collections.Hashtable]$ProcParameterValueMappings = @{"@TransactionDate"=$TransactionDate;"@Module"=$Setting.Module;"@FormName"=$Setting.Form;"@UserAccount"=$Setting.UserAccount;"@UnmatchedCompany"=$Setting.UnmatchedCompany;"@UnmatchedVendorGroup"=$Setting.UnmatchedVendorGroup;"@UnmatchedVendor"=$Setting.UnmatchedVendor}
# Record field to use as reference in log file
[string]$LogFileRecordField = "CollectedInvoiceNumber"
# Record field to use as reference for image file name
[string]$ImageFileNameRecordField = "CollectedImage"

# ***********************************************************

# Import common data routines
[string]$ScriptModuleFilePath = $PSScriptRoot + "\ViewPointImportCommon.ps1"
Import-Module -Global -Force -Name $ScriptModuleFilePath

function UploadDataRowAP
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

            $SqlCommand.Parameters.Add("@AttachmentID",  [System.Data.SqlDbType]::Int) | Out-Null
            $SqlCommand.Parameters["@AttachmentID"].Direction = [System.Data.ParameterDirection]::Output;

            $SqlCommand.Parameters.Add("@UniqueAttachmentID",  [System.Data.SqlDbType]::UniqueIdentifier) | Out-Null
            $SqlCommand.Parameters["@UniqueAttachmentID"].Direction = [System.Data.ParameterDirection]::Output;

            $SqlCommand.Parameters.Add("@AttachmentFilePath",  [System.Data.SqlDbType]::VarChar, 512) | Out-Null
            $SqlCommand.Parameters["@AttachmentFilePath"].Direction = [System.Data.ParameterDirection]::Output;

            $SqlCommand.Parameters.Add("@HeaderKeyID",  [System.Data.SqlDbType]::BigInt) | Out-Null
            $SqlCommand.Parameters["@HeaderKeyID"].Direction = [System.Data.ParameterDirection]::Output;

            $SqlCommand.Parameters.Add("@FooterKeyID",  [System.Data.SqlDbType]::BigInt) | Out-Null
            $SqlCommand.Parameters["@FooterKeyID"].Direction = [System.Data.ParameterDirection]::Output;

            $SqlCommand.Parameters.Add("@Message",  [System.Data.SqlDbType]::VarChar, 512) | Out-Null
            $SqlCommand.Parameters["@Message"].Direction = [System.Data.ParameterDirection]::Output;
            
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
            $AttachmentIDValue = $SqlCommand.Parameters["@AttachmentID"].Value;
            $UniqueAttachmentIDValue = $SqlCommand.Parameters["@UniqueAttachmentID"].Value;
            $AttachmentFilePathValue = $SqlCommand.Parameters["@AttachmentFilePath"].Value;
            $HeaderKeyIDValue = $SqlCommand.Parameters["@HeaderKeyID"].Value;
            $FooterKeyIDValue = $SqlCommand.Parameters["@FooterKeyID"].Value;
            $OutputMessage = $SqlCommand.Parameters["@Message"].Value;

            $SqlCommand.Dispose() | Out-Null

            [string]$Results = ""
            if ($ReturnValue -eq 0) {
                $Results = "Successful"
            }
            else {
                $Results = "Unsuccessful"
            }

            [object]$RowIndicator = $LogFileRecordField
            WriteToLog("Upload AP Header record ID: " + $HeaderKeyIDValue + ": " + $Results + " : " + $OutputMessage)

            [System.Collections.Hashtable]$OutputParameters = @{"@AttachmentID"=$AttachmentIDValue;"@UniqueAttachmentID"=$UniqueAttachmentIDValue;"@AttachmentFilePath"=$AttachmentFilePathValue;"@HeaderKeyID"=$HeaderKeyIDValue;"@FooterKeyID"=$FooterKeyIDValue;"@Message"=$OutputMessage}
            return $OutputParameters
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

function ProcessAPDataRecords
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
                        $File = Import-Csv -LiteralPath $DataFile.FullName
                        if ($File -ne $null) {
                            WriteToLog("Started import for data file: " + $DataFile.FullName)
                            WriteToLog("Environment: Server: " + $Server + " Database: " + $Database)
                            # Process each data record in CSV file
                            foreach ($DataRow in $File) {
                                if ((ValidateDataRow $DataRow) -eq $true) {
                                    [System.Collections.Hashtable]$OutputParameters = UploadDataRowAP $DataRow
                                    [string]$NewAttachmentID = $OutputParameters["@AttachmentID"]
                                    $AttachIDVal = $OutputParameters["@UniqueAttachmentID"]
                                    [System.Guid]$NewUniqueAttachmentID = $(if ($AttachIDVal -eq [DBNull]::Value) { [System.Guid]::Empty } else { $AttachIDVal })
                                    [string]$NewAttachmentPath = $OutputParameters["@AttachmentFilePath"]
                                    [string]$NewHeaderKeyID = $OutputParameters["@HeaderKeyID"]
                                    [string]$NewFooterKeyID = $OutputParameters["@FooterKeyID"]
                                    [string]$NewMessage = $OutputParameters["@Message"]
                                    [boolean]$FileCopiedValue = $false
                                    if ($NewAttachmentPath.Length -gt 0) {
                                        $ImageFilePath = $UnpackedFilePath + "\" + $DataRow.$ImageFileNameRecordField
                                        $FileCopied = CopyImageFileFullPath $ImageFilePath $NewAttachmentPath
                                        $FileCopiedValue = $FileCopied
                                    }
                                    $TransactionLogged = AddRLBImportData $DataFile.Name $DataRow.RecordType $DataRow.Company $DataRow.Number $DataRow.VendorGroup $DataRow.Vendor $DataRow.VendorName $DataRow.TransactionDate $DataRow.JCCo $DataRow.Job $DataRow.JobDescription $DataRow.Description $DataRow.DetailLineCount $DataRow.TotalOrigCost $DataRow.TotalOrigTax $DataRow.RemainingAmount $DataRow.RemainingTax $DataRow.CollectedInvoiceDate $DataRow.CollectedInvoiceNumber $DataRow.CollectedTaxAmount $DataRow.CollectedShippingAmount $DataRow.CollectedInvoiceAmount $DataRow.CollectedImage $NewHeaderKeyID $NewFooterKeyID $NewAttachmentID $NewUniqueAttachmentID $NewAttachmentPath $FileCopiedValue $NewMessage
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
                $DirectoryRemoved = RemoveDirectory $UnpackedFilePath
                # Archive zip file
                $ArchiveFilePath = $Setting.ArchiveFilePath + $ZIPFile.BaseName
                $FileArchived = ArchiveImageFile $ZIPFile.FullName $ArchiveFilePath
                if ($FileArchived -eq $true) {
                    $FileRemoved = RemoveFile $ZIPFile.FullName
                }
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
ProcessAPDataRecords