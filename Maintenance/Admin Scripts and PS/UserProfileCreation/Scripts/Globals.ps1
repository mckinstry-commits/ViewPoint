#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------


#Sample function that provides the location of the script
function Get-ScriptDirectory
{ 
	if($hostinvocation -ne $null)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

#Sample variable that provides the location of the script
[string]$ScriptDirectory = Get-ScriptDirectory


function Import-Excel
{
	param (
		[string]$FileName,
		[string]$WorksheetName,
		[bool]$DisplayProgress = $true
	)
	
	if ($FileName -eq "")
	{
		throw "Please provide path to the Excel file"
		Exit
	}
	
	if (-not (Test-Path $FileName))
	{
		throw "Path '$FileName' does not exist."
		exit
	}
	
	$FileName = Resolve-Path $FileName
	$excel = New-Object -com "Excel.Application"
	$excel.Visible = $false
	$workbook = $excel.workbooks.open($FileName)
	
	if (-not $WorksheetName)
	{
		Write-Warning "Defaulting to the first worksheet in workbook."
		$sheet = $workbook.ActiveSheet
	}
	else
	{
		$sheet = $workbook.Sheets.Item($WorksheetName)
	}
	
	if (-not $sheet)
	{
		throw "Unable to open worksheet $WorksheetName"
		exit
	}
	
	$sheetName = $sheet.Name
	$columns = $sheet.UsedRange.Columns.Count
	$lines = $sheet.UsedRange.Rows.Count
	
	Write-Warning "Worksheet $sheetName contains $columns columns and $lines lines of data"
	
	$fields = @()
	
	for ($column = 1; $column -le $columns; $column++)
	{
		$fieldName = $sheet.Cells.Item.Invoke(1, $column).Value2
		if ($fieldName -eq $null)
		{
			$fieldName = "Column" + $column.ToString()
		}
		$fields += $fieldName
	}
	
	$line = 2
	
	
	for ($line = 2; $line -le $lines; $line++)
	{
		$values = New-Object object[] $columns
		for ($column = 1; $column -le $columns; $column++)
		{
			$values[$column - 1] = $sheet.Cells.Item.Invoke($line, $column).Value2
		}
		
		$row = New-Object psobject
		$fields | foreach-object -begin { $i = 0 } -process {
			$row | Add-Member -MemberType noteproperty -Name $fields[$i] -Value $values[$i]; $i++
		}
		$row
		$percents = [math]::round((($line/$lines) * 100), 0)
		if ($DisplayProgress)
		{
			Write-Progress -Activity:"Importing from Excel file $FileName" -Status:"Imported $line of total $lines lines ($percents%)" -PercentComplete:$percents
		}
	}
	$workbook.Close()
	$excel.Quit()
}

function Run-AllUsersAdd
{
	
	$FilePath = $textboxFile.Text
	$Group = "ViewpointUsers"
	$Package = "PM"
	#$Stuff = Import-CSV $FilePath
	#$Stuff = Import-Excel -FileName = $FilePath -DisplayProgress $true
	#WRITE $Group
	try
	{
		$members = @()
		Get-ADGroupMember -Identity $Group | Select-Object -ExpandProperty SamAccountName | ForEach-Object{ $members += $_.toLower() }
	}
	catch
	{
		$error.Message
	}
	#WRITE $members.mail
	
	$members -eq $NULL
	
	#ForEach ($member IN $members)
	#{
	#    WRITE-HOST $member
	#}
	
	$File = Import-Excel -FileName $FilePath -DisplayProgress $true
	ForEach ($Record IN $File)
	{
		
		$User = $Record.Email -replace '@mckinstry.com', ''
		
		If ($members -notcontains $User)
		{
			Add-ADGroupMember -Identity $Group -Member $User -PassThru -ErrorAction SilentlyContinue
			$members += $User
			WRITE-HOST $User "Added to domain group " $Group
			CONTINUE
		}
		Else
		{
			WRITE-HOST $User "Already a member of "$Group
			CONTINUE
		}
	}
	ForEach ($Record IN $File)
	{
		$DefCompany = $Record.PRCo.Substring(0, 2) -replace '"', ''
		$Name = $Record.Name
		$Employee = $Record.Employee
				
		#$AddUser = ADAddUser $Record.Email $Group
		#SProcs $User $Record.Email $DefCompany $Name $Employee $Package
		
		#Stored proc to execute
		[string]$StoredProcedure = "dbo.mckspAddUserAccount"
		
		# Stored procedure return parameter name
		[string]$StoredProcedureReturnParameter = "@rcode"
		# Stored procedure output parameter name
		[string]$StoredProcedureOutputParameter = "@ReturnMessage"
		
		
		[System.Collections.Hashtable]$ProcParameterValueMappings = @{ "@UserName" = $User; "Email" = $Record.Email; "@DefCompany" = $DefCompany; "@FullName" = $Name; "@Employee" = $Employee; "@Package" = $Package; }
		
		
		$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$SqlConnection.ConnectionString = "Server=VIEWPOINTAG\VIEWPOINT ;Database=Viewpoint; Integrated Security=SSPI"
		
		$SqlConnection.Open() | Out-Null
		$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
		$SqlCmd.Connection = $SqlConnection
		$SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
		$SqlCmd.CommandText = $StoredProcedure
		
		$SqlCmd.Parameters.Add($StoredProcedureReturnParameter, [System.Data.SqlDbType]::Int) | Out-Null
		$SqlCmd.Parameters[$StoredProcedureReturnParameter].Direction = [System.Data.ParameterDirection]::ReturnValue;
		
		$SqlCmd.Parameters.Add($StoredProcedureOutputParameter, [System.Data.SqlDbType]::VarChar, 255) | Out-Null
		$SqlCmd.Parameters[$StoredProcedureOutputParameter].Direction = [System.Data.ParameterDirection]::Output;
		
		
		foreach ($ProcParameter in $ProcParameterValueMappings.Keys)
		{
			$SqlCmd.Parameters.Add($ProcParameter, $ProcParameterValueMappings[$ProcParameter]) | Out-Null
		}
		
		$SqlCmd.ExecuteNonQuery() | Out-Null
		
		
		$OutputValue = $SqlCmd.Parameters[$StoredProcedureOutputParameter].Value;
		WRITE-HOST $OutputValue
		
		$SqlConnection.Close() | Out-Null
		$SqlCmd.Dispose() | Out-Null
		Write-Host "Proc Ran for " $User
		RETURN $OutputValue
		
	}
}