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
# Collection of stored procedure parameters and static values
[System.Collections.Hashtable]$ProcParameterValueMappings = @{"@Module"=$Setting.Module;"@FormName"=$Setting.Form;"@UserAccount"=$Setting.UserAccount}
# Collection of stored procedure output codes and messages
[System.Collections.Hashtable]$ProcOutputValueMessageMappings = @{}
$ProcOutputValueMessageMappings.Add(0,"Header, Footer and Attachment records created successfully.")
$ProcOutputValueMessageMappings.Add(1,"Header, Footer records created successfully. Attachment not created, already exists.")
$ProcOutputValueMessageMappings.Add(2,"Standalone attachment created.  Missing header parameters.")
$ProcOutputValueMessageMappings.Add(3,"Standalone attachment created.  Missing footer parameters.")
$ProcOutputValueMessageMappings.Add(4,"Standalone attachment created.  Error creating header record.")
$ProcOutputValueMessageMappings.Add(5,"Standalone attachment created.  Error creating footer record.")
$ProcOutputValueMessageMappings.Add(6,"No records created.  Missing attachment parameters.")
$ProcOutputValueMessageMappings.Add(7,"No records created.  Attachment exists.")
$ProcOutputValueMessageMappings.Add(8,"No records created.  Error creating attachment record.")
$ProcOutputValueMessageMappings.Add(9,"Header and Footer records created successfully. Error creating attachment record.")
# Record field to use as reference in log file
[string]$LogFileRecordField = "CollectedInvoiceNumber"
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
        3 {$ShouldCopy=$true}
        4 {$ShouldCopy=$true} 
        5 {$ShouldCopy=$true} 
        default {$ShouldCopy=$false}
    }
    return $ShouldCopy
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
                                    $OutputValue = UploadDataRow $DataRow
                                    $ShouldCopyImage = ShouldCopyImage($OutputValue)
                                    if ($ShouldCopyImage -eq $true) {
                                        $ImageFilePath = $UnpackedFilePath + "\" + $DataRow.$ImageFileNameRecordField
                                        $FileCopied = CopyImageFile $ImageFilePath $DataRow.Company $Setting.Module $Setting.Form $DataRow.CollectedInvoiceDate
                                    }
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