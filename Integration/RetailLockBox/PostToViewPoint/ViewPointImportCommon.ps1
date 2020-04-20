# Common routines for Viewpoint data import

# Build setting values from configuration file
[string]$ConfigFile = $PSScriptRoot + "\ViewPointImportSettings.xml"
[xml]$Config = Get-Content $ConfigFile
[System.Xml.XmlElement]$Setting = $Config.Settings.Setting | Where  { $_.Name -eq $ConfigFileSettingsName }
[string]$Server = $Setting.Server
[string]$Database = $Setting.Database
[string]$IntegrationDatabase = "MCK_INTEGRATION"
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

function AddRLBImportData
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$MetaFileName,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$RecordType,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$Company,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$Number,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$VendorGroup,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$Vendor,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$VendorName,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$TransactionDate,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$JCCo,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$Job,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$JobDescription,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$Description,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$DetailLineCount,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$TotalOrigCost,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$TotalOrigTax,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$RemainingAmount,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$RemainingTax,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$CollectedInvoiceDate,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$CollectedInvoiceNumber,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$CollectedTaxAmount,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$CollectedShippingAmount,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$CollectedInvoiceAmount,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$CollectedImage,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$HeaderKeyID,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$FooterKeyID,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$AttachmentID,
        [Parameter(Mandatory=$true)]
        [AllowNull()][System.Guid]$UniqueAttachmentID,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$AttachmentFilePath,
        [Parameter(Mandatory=$true)]
        [AllowNull()][boolean]$FileCopied,
        [Parameter(Mandatory=$true)]
        [AllowNull()][AllowEmptyString()][string]$Notes
     )
     begin
     {
        $SqlConnectionString = "Data Source=$Server;Initial Catalog=$IntegrationDatabase;Integrated Security=True"
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection($SqlConnectionString)
     }
     process
     {
        try
        {
            $SqlConnection.Open() | Out-Null
            $SqlCommand = New-Object System.Data.SqlClient.SqlCommand("dbo.mckspAddRLBImportData", $SqlConnection)
            $SqlCommand.CommandType = [System.Data.CommandType]::StoredProcedure

            $SqlCommand.Parameters.Add("@rcode",  [System.Data.SqlDbType]::Int) | Out-Null
            $SqlCommand.Parameters["@rcode"].Direction = [System.Data.ParameterDirection]::ReturnValue;

            # Build SQL proc parameters from input values
            $SqlCommand.Parameters.Add("@MetaFileName",  [System.Data.SqlDbType]::VarChar, 100) | Out-Null
            $SqlCommand.Parameters["@MetaFileName"].Value = $(if ($MetaFileName) { $MetaFileName } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@RecordType",  [System.Data.SqlDbType]::VarChar, 30) | Out-Null
            $SqlCommand.Parameters["@RecordType"].Value = $(if ($RecordType) { $RecordType } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@Company",  [System.Data.SqlDbType]::TinyInt) | Out-Null
            $SqlCommand.Parameters["@Company"].Value = $(if ($Company) { $Company } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@Number",  [System.Data.SqlDbType]::VarChar, 30) | Out-Null
            $SqlCommand.Parameters["@Number"].Value = $(if ($Number) { $Number } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@VendorGroup",  [System.Data.SqlDbType]::TinyInt) | Out-Null
            $SqlCommand.Parameters["@VendorGroup"].Value = $(if ($VendorGroup) { $VendorGroup } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@Vendor", [System.Data.SqlDbType]::Int) | Out-Null
            $SqlCommand.Parameters["@Vendor"].Value = $(if ($Vendor) { $Vendor } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@VendorName", [System.Data.SqlDbType]::VarChar, 60) | Out-Null
            $SqlCommand.Parameters["@VendorName"].Value = $(if ($VendorName) { $VendorName } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@TransactionDate", [System.Data.SqlDbType]::DateTime) | Out-Null
            $SqlCommand.Parameters["@TransactionDate"].Value = $(if ($TransactionDate) { $TransactionDate } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@JCCo", [System.Data.SqlDbType]::TinyInt) | Out-Null
            $SqlCommand.Parameters["@JCCo"].Value = $(if ($JCCo) { $JCCo } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@Job", [System.Data.SqlDbType]::VarChar, 10) | Out-Null
            $SqlCommand.Parameters["@Job"].Value = $(if ($Job) { $Job } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@JobDescription", [System.Data.SqlDbType]::VarChar, 60) | Out-Null
            $SqlCommand.Parameters["@JobDescription"].Value = $(if ($JobDescription) { $JobDescription } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@Description", [System.Data.SqlDbType]::VarChar, 30) | Out-Null
            $SqlCommand.Parameters["@Description"].Value = $(if ($Description) { $Description } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@DetailLineCount", [System.Data.SqlDbType]::Int) | Out-Null
            $SqlCommand.Parameters["@DetailLineCount"].Value = $(if ($DetailLineCount) { $DetailLineCount } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@TotalOrigCost", [System.Data.SqlDbType]::Decimal) | Out-Null
            $SqlCommand.Parameters["@TotalOrigCost"].Precision = 12
            $SqlCommand.Parameters["@TotalOrigCost"].Scale = 2
            $SqlCommand.Parameters["@TotalOrigCost"].Value = $(if ($TotalOrigCost) { $TotalOrigCost } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@TotalOrigTax", [System.Data.SqlDbType]::Decimal) | Out-Null
            $SqlCommand.Parameters["@TotalOrigTax"].Precision = 12
            $SqlCommand.Parameters["@TotalOrigTax"].Scale = 2
            $SqlCommand.Parameters["@TotalOrigTax"].Value = $(if ($TotalOrigTax) { $TotalOrigTax } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@RemainingAmount", [System.Data.SqlDbType]::Decimal) | Out-Null
            $SqlCommand.Parameters["@RemainingAmount"].Precision = 12
            $SqlCommand.Parameters["@RemainingAmount"].Scale = 2
            $SqlCommand.Parameters["@RemainingAmount"].Value = $(if ($RemainingAmount) { $RemainingAmount } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@RemainingTax", [System.Data.SqlDbType]::Decimal) | Out-Null
            $SqlCommand.Parameters["@RemainingTax"].Precision = 12
            $SqlCommand.Parameters["@RemainingTax"].Scale = 2
            $SqlCommand.Parameters["@RemainingTax"].Value = $(if ($RemainingTax) { $RemainingTax } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@CollectedInvoiceDate", [System.Data.SqlDbType]::SmallDateTime) | Out-Null
            $SqlCommand.Parameters["@CollectedInvoiceDate"].Value = $(if ($CollectedInvoiceDate) { $CollectedInvoiceDate } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@CollectedInvoiceNumber", [System.Data.SqlDbType]::VarChar, 50) | Out-Null
            $SqlCommand.Parameters["@CollectedInvoiceNumber"].Value = $(if ($CollectedInvoiceNumber) { $CollectedInvoiceNumber } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@CollectedTaxAmount", [System.Data.SqlDbType]::Decimal) | Out-Null
            $SqlCommand.Parameters["@CollectedTaxAmount"].Precision = 12
            $SqlCommand.Parameters["@CollectedTaxAmount"].Scale = 2
            $SqlCommand.Parameters["@CollectedTaxAmount"].Value = $(if ($CollectedTaxAmount) { $CollectedTaxAmount } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@CollectedShippingAmount", [System.Data.SqlDbType]::Decimal) | Out-Null
            $SqlCommand.Parameters["@CollectedShippingAmount"].Precision = 12
            $SqlCommand.Parameters["@CollectedShippingAmount"].Scale = 2
            $SqlCommand.Parameters["@CollectedShippingAmount"].Value = $(if ($CollectedShippingAmount) { $CollectedShippingAmount } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@CollectedInvoiceAmount", [System.Data.SqlDbType]::Decimal) | Out-Null
            $SqlCommand.Parameters["@CollectedInvoiceAmount"].Precision = 12
            $SqlCommand.Parameters["@CollectedInvoiceAmount"].Scale = 2
            $SqlCommand.Parameters["@CollectedInvoiceAmount"].Value = $(if ($CollectedInvoiceAmount) { $CollectedInvoiceAmount } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@CollectedImage", [System.Data.SqlDbType]::VarChar, 255) | Out-Null
            $SqlCommand.Parameters["@CollectedImage"].Value = $(if ($CollectedImage) { $CollectedImage } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@HeaderKeyID", [System.Data.SqlDbType]::BigInt) | Out-Null
            $SqlCommand.Parameters["@HeaderKeyID"].Value = $(if ($HeaderKeyID) { $HeaderKeyID } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@FooterKeyID", [System.Data.SqlDbType]::BigInt) | Out-Null
            $SqlCommand.Parameters["@FooterKeyID"].Value = $(if ($FooterKeyID) { $FooterKeyID } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@AttachmentID", [System.Data.SqlDbType]::Int) | Out-Null
            $SqlCommand.Parameters["@AttachmentID"].Value = $(if ($AttachmentID) { $AttachmentID } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@UniqueAttachmentID", [System.Data.SqlDbType]::UniqueIdentifier) | Out-Null
            $SqlCommand.Parameters["@UniqueAttachmentID"].Value = $(if ($UniqueAttachmentID) { $UniqueAttachmentID } else { [System.Guid]::Empty })
            $SqlCommand.Parameters.Add("@AttachmentFilePath", [System.Data.SqlDbType]::VarChar, 512) | Out-Null
            $SqlCommand.Parameters["@AttachmentFilePath"].Value = $(if ($AttachmentFilePath) { $AttachmentFilePath } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@FileCopied", [System.Data.SqlDbType]::Bit) | Out-Null
            $SqlCommand.Parameters["@FileCopied"].Value = $(if ($FileCopied) { $FileCopied } else { [DBNull]::Value })
            $SqlCommand.Parameters.Add("@Notes", [System.Data.SqlDbType]::VarChar, 512) | Out-Null
            $SqlCommand.Parameters["@Notes"].Value = $(if ($Notes) { $Notes } else { [DBNull]::Value })
 
            $SqlCommand.ExecuteNonQuery() | Out-Null
            $ReturnValue = $SqlCommand.Parameters["@rcode"].Value;
            $SqlCommand.Dispose() | Out-Null

            return $ReturnValue
        }
        catch [Exception]
        {
            WriteToLog("Error Executing Procedure dbo.mckspAddRLBImportData: " + $_.Exception.Message)
            return -1
        }
    }
    end
    {
        $SqlConnection.Close() | Out-Null
        $SqlConnection.Dispose() | Out-Null
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

function CopyImageFileFullPath
{
    [CmdletBinding()]
    param (
     [Parameter(Mandatory=$true)]
     [string]$FullSourceFileName,
     [Parameter(Mandatory=$true)]
     [string]$FullDestinationFileName
     )
     try
     {
        $Results = CopyFileFullPath $FullSourceFileName $FullDestinationFileName
        [string]$Result = ""
        if ($Results -eq $true) {
            $Result = "Successful"
        }
        else {
            $Result = "Unsuccessful"
        }
        WriteToLog("Copying file '" + $FullSourceFileName + "' to '" + $FullDestinationFileName + "': " + $Result)
        return $Results
    }
    catch [Exception] {
        WriteToLog("Error copying image file: " + $_.Exception.Message)
        return $false
    }
}

function CopyFileFullPath
{
    param (
    [string]$FullSourceFilePath,
    [string]$FullDestinationFileName
    )
    try
    {
        $DocDirectory = $FullDestinationFileName.SubString(0, $FullDestinationFileName.LastIndexOf("\"))
        if ((Test-Path $DocDirectory) -eq 0) {
            New-Item -ItemType Directory -Force -Path $DocDirectory | Out-Null
        }
        Copy-Item $FullSourceFilePath $FullDestinationFileName -Force -ErrorAction SilentlyContinue
    }
    catch {
        return $false
    }
    return $?
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
