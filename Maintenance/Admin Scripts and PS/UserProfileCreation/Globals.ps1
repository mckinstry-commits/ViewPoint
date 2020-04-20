#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------


#Sample function that provides the location of the script
Import-Module ActiveDirectory
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
	param
	(
		[string]$Server
	)
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
	
	$File = Import-Excel -FileName $FilePath -DisplayProgress $false
	ForEach ($Record IN $File)
	{
		#Write-Host $Record.Email
		[string]$Email = $Record.Email -replace "`n", "" -replace "`r", ""
		
		If ($Email -eq $null)
		{
			CONTINUE
		}
		$User = Get-ADUser -Filter { EmailAddress -eq $Email } -Properties * | Select-Object -ExpandProperty SamAccountName
		
		If ($members -notcontains $User)
		{
			Add-ADGroupMember -Identity $Group -Member $User -PassThru -ErrorAction SilentlyContinue
			$members += $User
			Write-Host $User "Added to domain group " $Group
			#CONTINUE
		}
		Else
		{
			Write-Host $User "Already a member of " $Group
			#CONTINUE
		}
		$progressbar1.PerformStep()
	}
	
	ForEach ($Record IN $File)
	{
		[string]$Email = $Record.Email
		
		If ($Email -eq $null)
		{
			CONTINUE
		}
		$User = Get-ADUser -Filter { EmailAddress -eq $Email } -Properties * | Select-Object -ExpandProperty SamAccountName
		$DefCompany = $Record.PRCo.Trim() 
		$DefCompany = $DefCompany.Substring(0, 2) -replace '"', ''
		
		#Write-Host $DefCompany
		If ($Server -eq 'Training')
		{
			$SqlConnectString = "Server=VPTRAININGAG\VPTRAINING;Database=Viewpoint; Integrated Security=SSPI"
		}
		
		If ($Server -eq 'Production')
		{
			$SqlConnectString = "Server=VIEWPOINTAG\VIEWPOINT;Database=Viewpoint; Integrated Security=SSPI"
		}
		
		If ($Server -eq 'Development')
		{
			$SqlConnectString = "Server=MCKTESTSQL04\VIEWPOINT;Database=Viewpoint; Integrated Security=SSPI"
		}
		
		Write-Host $SqlConnectString
		
		[string]$Name = $Record.Name -replace "`n", "" -replace "`r", ""
		[string]$Employee = $Record.Employee -replace "`n", "" -replace "`r", ""
			
		#$AddUser = ADAddUser $Record.Email $Group
		#SProcs $User $Record.Email $DefCompany $Name $Employee $Package
		
		#Stored proc to execute
		[string]$StoredProcedure = "dbo.mckspAddUserAccount"
		
		# Stored procedure return parameter name
		[string]$StoredProcedureReturnParameter = "@rcode"
		# Stored procedure output parameter name
		[string]$StoredProcedureOutputParameter = "@ReturnMessage"
		
		
		[System.Collections.Hashtable]$ProcParameterValueMappings = @{ "@UserName" = $User; "Email" = $Email; "@DefCompany" = $DefCompany; "@FullName" = $Name; "@Employee" = $Employee; "@Package" = $Package; }
		
		
		$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$SqlConnection.ConnectionString = $SqlConnectString
		
		
		echo $SqlConnectString
		
		Write-Host "opening sql connection..."
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
		
		Write-Host "Executing proc..."
		$SqlCmd.ExecuteNonQuery() | Out-Null
		
		
		$OutputValue = $SqlCmd.Parameters[$StoredProcedureOutputParameter].Value;
		echo $SqlCmd.Parameters[$StoredProcedureOutputParameter].Value;
		
		
		Write-Host "Proc Ran for " $Name "," $User
		Write-Host $OutputValue
		$progressbar1.PerformStep()
		$SqlConnection.Close() | Out-Null
		$SqlCmd.Dispose() | Out-Null
		CONTINUE
	}
	
	#RETURN $OutputValue
}