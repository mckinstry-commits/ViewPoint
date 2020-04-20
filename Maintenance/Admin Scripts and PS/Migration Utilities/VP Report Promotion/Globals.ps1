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

function Load-ReportsGrid
{
	param (
		[string]$SelectedServer
	)
	
	$sqlconBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder;
	
	#$SelectedServer = 'MCKTESTSQL04\VIEWPOINT'
	If ($SelectedServer -eq 'VPSTAGINGAG\VIEWPOINT')
	{
		$SourceServer = 'MCKTESTSQL04\VIEWPOINT'
	}
	
	If ($SelectedServer -eq 'VIEWPOINTAG\VIEWPOINT')
	{
		$SourceServer = 'VPSTAGINGAG\VIEWPOINT'
	}
	
	
	$sqlconBuilder.psbase.DataSource = $SourceServer
	$sqlconBuilder.psbase.InitialCatalog = "Viewpoint"
	#$sqlconBuilder.psbase.ApplicationIntent = "readonly"
	$sqlconBuilder.psbase.IntegratedSecurity = $true
	
	#Write-Host $sqlconBuilder.psbase.ConnectionString
	
	$sqlconnection = New-Object System.Data.SqlClient.SqlConnection
	$sqlconnection.ConnectionString = $sqlconBuilder.psbase.ConnectionString
	
	#Write-Host $sqlconBuilder.psbase.ConnectionString
	#Write-Host $sqlconnection.ConnectionString
	
	
	
	$SqlQuery = @"
		SELECT t.Title
			, t.ReportID
			,t.AppType
			, CASE t.AppType
				WHEN 'SQL Reporting Services'
					THEN 'http://'+s.Server+'/'+s.ReportServerInstance +'/'+ l.Path + t.FileName 
				ELSE l.Path +'\'+ t.FileName 
			END AS ReportPath
		FROM dbo.RPRTc t
			JOIN dbo.RPRL l ON t.Location = l.Location
			LEFT JOIN dbo.RPRSServer s ON l.ServerName = s.ServerName
"@
	
	$SqlCommand = New-Object System.Data.SqlClient.SqlCommand
	$SqlCommand.Connection = $sqlconnection
	$SqlCommand.CommandText = $SqlQuery
	
	$sqlconnection.open() | Out-Null
	
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlQuery
	$SqlAdapter.SelectCommand.Connection = $sqlconnection
	$Dataset = New-Object System.Data.DataSet
	$SqlAdapter.Fill($Dataset)
	$sqlconnection.Close()
	
	Load-DataGridView -DataGridView $datagridview1 -Item $Dataset.Tables[0]
}

function Execute-SelectedPromotion
{
	param (
		[string]$RPTitle
	)
	
	
}