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

$Group = 'ViewpointUsers'
$User = 'EricS'

#Functions
###########


function Get-ExcelOnboardingDetails (
		[string]$filepath
		, [ref]$User
		, [ref]$Email
		, [ref]$CellPhone
		, [ref]$OfficePhone
		, [ref]$EmployeeNumber
		, [ref]$EmployeeCo
		, [ref]$EmployeeName
		, [ref]$ViewpointYN
		, [ref]$Package
	)
{
	#$filepath = 'C:\Users\erics\Documents\ERP\Documentation\Onboarding\AA New Hire Set Up Form 2014.xlsm'
	$objExcel = New-Object -ComObject Excel.Application
	$objExcel.Visible = $false
	
	$Workbook = $objExcel.Workbooks.Open($filepath)
	
	$Managersheet = $Workbook.sheets.item("Manager")
	$ViewpointYN = $ManagerSheet.Range("ViewPointYN").Text
	$Package = $ManagerSheet.Range("VPPACK").Text
	
	
	#$ViewpointYN.Value
	#$Package.Value
	
	$HRSheet = $Workbook.sheets.item("HR")
	$EmployeeName = $HRsheet.Range("EMPNAME").Text
	$EmployeeCo = $HRsheet.Range("EMPCO").Text
	$EmployeeNumber.Value = $HRsheet.Range("EMPNUMBER").Text
	
	
	$ITSheet = $Workbook.sheets.item("IT")
	$User.Value = $ITSheet.Range("UserName").Text
	$Email.Value = $ITSheet.Range("Email").Text
	$CellPhone.Value = $ITSheet.Range("CellPhone").Text
	$OfficePhone.Value = $ITSheet.Range("DeskPhone").Text
	
	

	
	$User.Value
	$Email.Value
	$CellPhone.Value
	$OfficePhone.Value
	$EmployeeNumber.Value
	$EmployeeCo.Value
	$EmployeeName.Value
	$ViewpointYN.Value
	$Package.Value

	$objExcel.quit()
}

function ADCheckAndAddUser
{
	param (
		[string]$Group,
		[string]$UserName,
		[ref]$User
	)
	
	Import-Module ActiveDirectory
	
	#Get-ADGroupMember
	
	$User = Get-ADUser -Identity $UserName | Select-Object -ExpandProperty SamAccountName
	
	$Members = Get-ADGroupMember -Identity $Group | Select-Object -ExpandProperty SamAccountName
	
	If ($Members -notcontains $User.Value)
	{
		Add-ADGroupMember -Identity $Group -Member $User.Value
		Write-Host $User.Value ' added to group '$Group
		$User.Value
	}
	Else
	{
		Write-Host $User.Value ' already a member of group '$Group
		$User.Value
	}
}


function ExecSQLUserProfile
{
	param (
		[string]$User
		, [string]$Email
		, [string]$EmployeeNumber
		, [string]$EmployeeCo
		, [string]$EmployeeName
		, [string]$OfficePhone
		, [string]$CellPhone
		, [string]$Package
		, [ref]$ReturnMessage
	)
	
	#$DefCompany = $EmployeeCo
	
	
	
	
	#$AddUser = ADAddUser $Record.Email $Group
	#SProcs $User $Record.Email $DefCompany $Name $Employee $Package
	
	
	
	
	
	#Stored proc to execute
	[string]$StoredProcedure = "dbo.mckspVASecApprovalAdd"
	
	# Stored procedure return parameter name
	[string]$StoredProcedureReturnParameter = "@rcode"
	# Stored procedure output parameter name
	[string]$StoredProcedureOutputParameter = "@ReturnMessage"
	
	
	
	[System.Collections.Hashtable]$ProcParameterValueMappings = @{ "@User" = $User; "@Package" = $Package; "@Email" = $Email; "@EmployeeNumber" = $EmployeeNumber; "@EmployeeCo" = $EmployeeCo; "@EmployeeName" = $EmployeeName; "@OfficePhone" = $OfficePhone; "@CellPhone" = $CellPhone; }
	
	
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "Server=MCKTESTSQL04\VIEWPOINT ;Database=Viewpoint; Integrated Security=SSPI"
	
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
	Write-Output $OutputValue
	
	$SqlConnection.Close() | Out-Null
	$SqlCmd.Dispose() | Out-Null
	
	#RETURN $OutputValue
	$ReturnMessage = $OutputValue
}

	
	#Write-Host 'User: '$User ' - Email: ' $Email ' - Employee Number: ' $EmployeeNumber ' - Employee Name: ' $EmployeeName ' - Employee Co: ' $EmployeeCo
#Write-Host 'Cell Phone: ' $CellPhone ' - Desk Phone: ' $OfficePhone
