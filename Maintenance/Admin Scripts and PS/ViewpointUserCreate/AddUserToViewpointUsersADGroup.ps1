<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2014 v4.1.66
	 Created on:   	9/22/2014 2:21 PM
	 Created by:   	EricS
	 Organization: 	McKinstry Co
	 Filename:     	AddUserToViewpointUsersADGroup.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>


$Group = 'ViewpointUsers'
$User = 'EricS'


function ADCheckAndAddUser
{
	param (
		[string]$Group,
		[string]$UserName
	)
	
	Import-Module ActiveDirectory
	
	#Get-ADGroupMember
	
	
	
	$Members = Get-ADGroupMember -Identity ViewpointUsers | Select-Object -ExpandProperty SamAccountName
	
	If ($Members -notcontains $User)
	{
		Add-ADGroupMember -Identity $Group -Member $User
		Write-Host $User ' added to group '$Group
	}
	Else
	{
		Write-Host $User ' already a member of group '$Group
	}
	
}


