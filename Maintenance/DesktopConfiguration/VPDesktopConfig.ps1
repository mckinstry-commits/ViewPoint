<#
2014.09.10 - LWO - VPDesktopConfig.ps1

Requirements:
	Viewpoint must be installed on local computer to either C:\Program Files\Viewpoint Construction Software or C:\Program Files (x86)\Viewpoint Construction Software directory.
	Script must be run with Administrator priviledges (e.g. "Run as Administrator").
	Runs based on the current logged in user and uses current users profile for configuration settings (e.g. config and shortcuts).
	Only performs actions based on current users membership in AD Security Groups.  If user is not a member of at least one of these groups, no actions will be performed.
		Integration : "ERP Integration Team"
		Development : "ERP Integration Team"
		Staging 	: "ViewpointTestUsers"
		Production : "ViewpointUsers"

Summary of Activites:
	Verifies that the script is running with elevated permissions.
	Verifies and identifies Viewpoint Installation
	Tests current user group membership for each identified AD security group.
	For each group that the user is a member of:
		Copy the base Viewpoint client installation directory to an environment specific directory.
		Copy the applicable configuraiton file for the environment to the user specific profile location.
		Create a desktop shortcut for each applicable environment.  Users should delete existing desktop shortcuts to see this change.

2014.09.11 - LWO - Updates
	Updated to clean up some variable settings and placement of group membership checking.
	Added additional group membership check to create Payroll configuration.
	Also added alternate icons for created shortcuts.

#>


#TODO:  If VP Not Installed, prompt with instructions (installation location).
#TODO:  If membership failes, prompt with instructions (request access process).
#TODO:  Run RDSRemoteAppConfig.wcx to register AppGw on Win7/8 Systems

function isMemberOfADGroup
{
	Param ([string]$GroupName)
	
	Add-Type -AssemblyName System.DirectoryServices.AccountManagement
	$ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
	
	$user = [System.DirectoryServices.AccountManagement.UserPrincipal]::Current
	$group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($ct, $GroupName)
	
	$retVal = $false
	
	if (!$group)
	{
		$retVal = $false
	
	}
	else
	{
		if ($user.IsMemberOf($group))
		{
			$retVal = $true
		}
	}
	
	return $retVal	
}

function getViewpointInstallationDirectory
{
	$ViewpointPath = ""
	
	if (Test-Path "C:\Program Files (x86)\Viewpoint Construction Software\Client\VPLaunch_Host.exe")
	{
		$ViewpointPath = "C:\Program Files (x86)\Viewpoint Construction Software"
	}
	elseif (Test-Path "C:\Program Files\Viewpoint Construction Software\Client\VPLaunch_Host.exe")
	{
		$ViewpointPath = "C:\Program Files\Viewpoint Construction Software"
	}
	else
	{
		$ViewpointPath = ""
		Write-Host "Viewpoint Installation could not be found."
	}
	
	return $ViewpointPath		
}

function createDesktopShortcut
{
	Param (
		[string]$Environment
	,	[string]$Commandline
	)
	
	#$vpDir = getViewpointInstallationDirectory
	
	$ws = New-Object -com WScript.Shell
	$Dt = $ws.SpecialFolders.Item("Desktop")
	$Scp = Join-Path -Path $Dt -ChildPath "Viewpoint $Environment.lnk"
	$Sc = $ws.CreateShortcut($Scp)
	$Sc.TargetPath = $Commandline
	$icon = "$vpDir\$vpEnv\" + "$Environment.ico"
	$Sc.IconLocation = $icon
	$Sc.WorkingDirectory = $Commandline.Replace("\VPLaunch_Host.exe", "")
	$Sc.Description = "Viewpoint $Environment"
	$Sc.Save()
}

function doProduction
{
	Write-Host "Production"
	

	$vpEnv = "Production"
	
	#Write-Host "Current user is member of $groupToTest"
	#Write-Host "Viewpoint is installed at $vpDir"
	
	Write-Host "Copy $vpDir\Client to  $vpDir\$vpEnv"
	
	if (!(Test-Path -Path "$vpDir\$vpEnv"))
		{ New-Item "$vpDir\$vpEnv" -Type Directory }
	
	if (!(Test-Path -Path "$vpDir\$vpEnv\DownloadedFiles"))
		{ New-Item "$vpDir\$vpEnv\DownloadedFiles" -Type Directory }
	
	Copy-Item -Path "$vpDir\Client\*.*" -Destination "$vpDir\$vpEnv" -Force
	
	Write-Host "Copy .\$vpEnv.ico to  $vpDir\$vpEnv"
	Copy-Item -Path ".\$vpEnv.ico" -Destination "$vpDir\$vpEnv" -Force
	
	$configFile = $vpDir.Replace("\", "^").Replace(":","") + "^$vpEnv^VpUserConfig.xml"
	Write-Host "Copy $vpEnvVpUserConfig.xml to $appdata\Viewpoint Construction Software\$configFile"
	
	if (!(Test-Path -path "$appdata\Viewpoint Construction Software"))
		{ New-Item "$appdata\Viewpoint Construction Software" -Type Directory }
	
	Copy-Item -Path ".\ProductionVpUserConfig.xml" -Destination "$appdata\Viewpoint Construction Software\$configFile" -Force
	
	Write-Host "Create Desktop Shortcut to $vpDir\$vpEnv\VPLaunch_Host.exe" -Environment
	createDesktopShortcut -Environment $vpEnv -Commandline "$vpDir\$vpEnv\VPLaunch_Host.exe"

	
}

function doStaging
{
	Write-Host "Staging"
	#$vpDir = getViewpointInstallationDirectory
	$vpEnv = "Staging"
	
	#Write-Host "Current user is member of $groupToTest"
	#Write-Host "Viewpoint is installed at $vpDir"
	
	if (!(Test-Path -Path "$vpDir\$vpEnv"))
	{ New-Item "$vpDir\$vpEnv" -Type Directory }
	
	if (!(Test-Path -Path "$vpDir\$vpEnv\DownloadedFiles"))
	{ New-Item "$vpDir\$vpEnv\DownloadedFiles" -Type Directory }
	
	Copy-Item -Path "$vpDir\Client\*.*" -Destination "$vpDir\$vpEnv" -Force
	
	Write-Host "Copy .\$vpEnv.ico to  $vpDir\$vpEnv"
	Copy-Item -Path ".\$vpEnv.ico" -Destination "$vpDir\$vpEnv" -Force
	
	$configFile = $vpDir.Replace("\", "^").Replace(":", "") + "^$vpEnv^VpUserConfig.xml"
	Write-Host "Copy $vpEnvVpUserConfig.xml to $appdata\Viewpoint Construction Software\$configFile"
	
	if (!(Test-Path -path "$appdata\Viewpoint Construction Software"))
	{ New-Item "$appdata\Viewpoint Construction Software" -Type Directory }
	
	Copy-Item -Path ".\StagingVpUserConfig.xml" -Destination "$appdata\Viewpoint Construction Software\$configFile" -Force
	
	Write-Host "Create Desktop Shortcut to $vpDir\$vpEnv\VPLaunch_Host.exe"
	
	createDesktopShortcut -Environment $vpEnv -Commandline "$vpDir\$vpEnv\VPLaunch_Host.exe"
		
}

function doDevelopment
{

	Write-Host "Development"
	#$vpDir = getViewpointInstallationDirectory
	$vpEnv = "Development"
	
	#Write-Host "Current user is member of $groupToTest"
	#Write-Host "Viewpoint is installed at $vpDir"
	
	if (!(Test-Path -Path "$vpDir\$vpEnv"))
	{ New-Item "$vpDir\$vpEnv" -Type Directory }
	
	if (!(Test-Path -Path "$vpDir\$vpEnv\DownloadedFiles"))
	{ New-Item "$vpDir\$vpEnv\DownloadedFiles" -Type Directory }
	
	Copy-Item -Path "$vpDir\Client\*.*" -Destination "$vpDir\$vpEnv" -Force
	
	Write-Host "Copy .\$vpEnv.ico to  $vpDir\$vpEnv"
	Copy-Item -Path ".\$vpEnv.ico" -Destination "$vpDir\$vpEnv" -Force
	
	$configFile = $vpDir.Replace("\", "^").Replace(":", "") + "^$vpEnv^VpUserConfig.xml"
	Write-Host "Copy $vpEnvVpUserConfig.xml to $appdata\Viewpoint Construction Software\$configFile"
	
	if (!(Test-Path -path "$appdata\Viewpoint Construction Software"))
	{ New-Item "$appdata\Viewpoint Construction Software" -Type Directory }
	
	Copy-Item -Path ".\DevelopmentVpUserConfig.xml" -Destination "$appdata\Viewpoint Construction Software\$configFile" -Force
	
	Write-Host "Create Desktop Shortcut to $vpDir\$vpEnv\VPLaunch_Host.exe"
	
	createDesktopShortcut -Environment $vpEnv -Commandline "$vpDir\$vpEnv\VPLaunch_Host.exe"
}

function doIntegration
{
	Write-Host "Integration"
	#$vpDir = getViewpointInstallationDirectory
	$vpEnv = "Integration"
	
	#Write-Host "Current user is member of $groupToTest"
	#Write-Host "Viewpoint is installed at $vpDir"
	
	if (!(Test-Path -Path "$vpDir\$vpEnv"))
	{ New-Item "$vpDir\$vpEnv" -Type Directory }
	
	if (!(Test-Path -Path "$vpDir\$vpEnv\DownloadedFiles"))
	{ New-Item "$vpDir\$vpEnv\DownloadedFiles" -Type Directory }
	
	Copy-Item -Path "$vpDir\Client\*.*" -Destination "$vpDir\$vpEnv" -Force
	
	Write-Host "Copy .\$vpEnv.ico to  $vpDir\$vpEnv"
	Copy-Item -Path ".\$vpEnv.ico" -Destination "$vpDir\$vpEnv" -Force
	
	$configFile = $vpDir.Replace("\", "^").Replace(":", "") + "^$vpEnv^VpUserConfig.xml"
	Write-Host "Copy $vpEnvVpUserConfig.xml to $appdata\Viewpoint Construction Software\$configFile"
	
	if (!(Test-Path -path "$appdata\Viewpoint Construction Software"))
	{ New-Item "$appdata\Viewpoint Construction Software" -Type Directory }
	
	Copy-Item -Path ".\IntegrationVpUserConfig.xml" -Destination "$appdata\Viewpoint Construction Software\$configFile" -Force
	
	Write-Host "Create Desktop Shortcut to $vpDir\$vpEnv\VPLaunch_Host.exe"
	
	createDesktopShortcut -Environment $vpEnv -Commandline "$vpDir\$vpEnv\VPLaunch_Host.exe"
}

function doPayroll
{
	Write-Host "Payroll"
	#$vpDir = getViewpointInstallationDirectory
	$vpEnv = "Payroll"
	
	#Write-Host "Current user is member of $groupToTest"
	#Write-Host "Viewpoint is installed at $vpDir"
	
	if (!(Test-Path -Path "$vpDir\$vpEnv"))
	{ New-Item "$vpDir\$vpEnv" -Type Directory }
	
	if (!(Test-Path -Path "$vpDir\$vpEnv\DownloadedFiles"))
	{ New-Item "$vpDir\$vpEnv\DownloadedFiles" -Type Directory }
	
	Copy-Item -Path "$vpDir\Client\*.*" -Destination "$vpDir\$vpEnv" -Force
	
	Write-Host "Copy .\$vpEnv.ico to  $vpDir\$vpEnv"
	Copy-Item -Path ".\$vpEnv.ico" -Destination "$vpDir\$vpEnv" -Force
	
	$configFile = $vpDir.Replace("\", "^").Replace(":", "") + "^$vpEnv^VpUserConfig.xml"
	Write-Host "Copy $vpEnvVpUserConfig.xml to $appdata\Viewpoint Construction Software\$configFile"
	
	if (!(Test-Path -path "$appdata\Viewpoint Construction Software"))
	{ New-Item "$appdata\Viewpoint Construction Software" -Type Directory }
	
	Copy-Item -Path ".\PayrollVpUserConfig.xml" -Destination "$appdata\Viewpoint Construction Software\$configFile" -Force
	
	Write-Host "Create Desktop Shortcut to $vpDir\$vpEnv\VPLaunch_Host.exe"
	
	createDesktopShortcut -Environment $vpEnv -Commandline "$vpDir\$vpEnv\VPLaunch_Host.exe"
}
# Main script


try
{
	
	# Get the ID and security principal of the current user account
	$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
	
	# Get the security principal for the Administrator role
	$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
	
	# Check to see if we are currently running "as Administrator"
	if ($myWindowsPrincipal.IsInRole($adminRole))
	{
		# We are running "as Administrator" - so change the title and background color to indicate this
		$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
		$Host.UI.RawUI.BackgroundColor = "DarkBlue"
		clear-host
		
		$appdata = Get-Childitem env:APPDATA | %{ $_.Value }
		$vpDir = getViewpointInstallationDirectory
		
		Write-Host "Viewpoint is installed at $vpDir"
		
		if (isMemberOfADGroup -GroupName "ViewpointUsers")
		{
			Write-Host "Configuring Production for 'ViewpointUsers'"
			doProduction
		}
		
		if (isMemberOfADGroup -GroupName "ViewpointTestUsers")
		{
			Write-Host "Configuring Staging for 'ViewpointTestUsers'"
			doStaging
		}
		
		if (isMemberOfADGroup -GroupName "ViewpointDevUsers")
		{
			Write-Host "Configuring Development for 'ViewpointDevUsers'"
			doDevelopment
			Write-Host "Configuring Integration for 'ViewpointDevUsers'"
			doIntegration
		}
		
		if (isMemberOfADGroup -GroupName "ERP Integration Team")
		{
			Write-Host "Configuring Integration for 'ERP Integration Team'"
			doIntegration
		}
		
		if (isMemberOfADGroup -GroupName "ERP Reporting Team")
		{
			Write-Host "Configuring Integration for 'ERP Reporting Team'"
			doIntegration
		}
		
		if (isMemberOfADGroup -GroupName "ViewpointPayrollUsers")
		{
			Write-Host "Configuring Payroll for 'ViewpointPayrollUsers'"
			doPayroll
		}
		
	}
	else
	{
		Write-Host "Must run as 'Administrator'"
		#TODO: Find a way to elevate permissions and RunAs Administrator automatically.
		exit
	}
	
}
catch [Exception]
{
    Write-Host $_.Exception.Message
    exit 1
}
# SIG # Begin signature block
# MIITrgYJKoZIhvcNAQcCoIITnzCCE5sCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1hGmA6F5+BHXZPmAGQDA+5sD
# iqGggg36MIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BJ8wggOHoAMCAQICEhEhQFwfDtJYiCvlTYaGuhHqRTANBgkqhkiG9w0BAQUFADBS
# MQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UE
# AxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjAeFw0xMzA4MjMwMDAw
# MDBaFw0yNDA5MjMwMDAwMDBaMGAxCzAJBgNVBAYTAlNHMR8wHQYDVQQKExZHTU8g
# R2xvYmFsU2lnbiBQdGUgTHRkMTAwLgYDVQQDEydHbG9iYWxTaWduIFRTQSBmb3Ig
# TVMgQXV0aGVudGljb2RlIC0gRzEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQCwF66i07YEMFYeWA+x7VWk1lTL2PZzOuxdXqsl/Tal+oTDYUDFRrVZUjtC
# oi5fE2IQqVvmc9aSJbF9I+MGs4c6DkPw1wCJU6IRMVIobl1AcjzyCXenSZKX1GyQ
# oHan/bjcs53yB2AsT1iYAGvTFVTg+t3/gCxfGKaY/9Sr7KFFWbIub2Jd4NkZrItX
# nKgmK9kXpRDSRwgacCwzi39ogCq1oV1r3Y0CAikDqnw3u7spTj1Tk7Om+o/SWJMV
# TLktq4CjoyX7r/cIZLB6RA9cENdfYTeqTmvT0lMlnYJz+iz5crCpGTkqUPqp0Dw6
# yuhb7/VfUfT5CtmXNd5qheYjBEKvAgMBAAGjggFfMIIBWzAOBgNVHQ8BAf8EBAMC
# B4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEFBQcCARYmaHR0cHM6
# Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYDVR0TBAIwADAWBgNV
# HSUBAf8EDDAKBggrBgEFBQcDCDBCBgNVHR8EOzA5MDegNaAzhjFodHRwOi8vY3Js
# Lmdsb2JhbHNpZ24uY29tL2dzL2dzdGltZXN0YW1waW5nZzIuY3JsMFQGCCsGAQUF
# BwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNv
# bS9jYWNlcnQvZ3N0aW1lc3RhbXBpbmdnMi5jcnQwHQYDVR0OBBYEFNSihEo4Whh/
# uk8wUL2d1XqH1gn3MB8GA1UdIwQYMBaAFEbYPv/c477/g+b0hZuw3WrWFKnBMA0G
# CSqGSIb3DQEBBQUAA4IBAQACMRQuWFdkQYXorxJ1PIgcw17sLOmhPPW6qlMdudEp
# Y9xDZ4bUOdrexsn/vkWF9KTXwVHqGO5AWF7me8yiQSkTOMjqIRaczpCmLvumytmU
# 30Ad+QIYK772XU+f/5pI28UFCcqAzqD53EvDI+YDj7S0r1txKWGRGBprevL9DdHN
# fV6Y67pwXuX06kPeNT3FFIGK2z4QXrty+qGgk6sDHMFlPJETiwRdK8S5FhvMVcUM
# 6KvnQ8mygyilUxNHqzlkuRzqNDCxdgCVIfHUPaj9oAAy126YPKacOwuDvsu4uyom
# jFm4ua6vJqziNKLcIQ2BCzgT90Wj49vErKFtG7flYVzXMIIFOzCCBCOgAwIBAgIH
# KxAqSxlENDANBgkqhkiG9w0BAQUFADCByjELMAkGA1UEBhMCVVMxEDAOBgNVBAgT
# B0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHku
# Y29tLCBJbmMuMTMwMQYDVQQLEypodHRwOi8vY2VydGlmaWNhdGVzLmdvZGFkZHku
# Y29tL3JlcG9zaXRvcnkxMDAuBgNVBAMTJ0dvIERhZGR5IFNlY3VyZSBDZXJ0aWZp
# Y2F0aW9uIEF1dGhvcml0eTERMA8GA1UEBRMIMDc5NjkyODcwHhcNMTIwNDAzMTYy
# OTE3WhcNMTUwNTIwMTg0NzI0WjBmMQswCQYDVQQGDAJVUzELMAkGA1UECAwCV0Ex
# EDAOBgNVBAcMB1NlYXR0bGUxGzAZBgNVBAoMEk1jS2luc3RyeSBDby4sIExMQzEb
# MBkGA1UEAwwSTWNLaW5zdHJ5IENvLiwgTExDMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEAmUKpZO0+EmXweMLx/cl1x+Fp0QYe2Y2pNwl5P96sy92Nz/JW
# QBtVCjgME+CfSTQH5Ud5MtbTjrqbfZvU6HwSKVl0gbRZkdgItjYLWJ3VDZelKex3
# rbmwwiJ/5CtGo4PanYPLIfjksApfXWQwOJ4drhVHCJtgDJFZmax5UeJ2k3Jw03eN
# UzWU3R5DSaUBvOgIdMLlvpbalO3bmLlOD9HEVclHDLvp4KMdVMvgcIl/zX7PvlvM
# R5aoi3HYUjUinaNyUWzPIF1pwfvemief2i+AaXoFgxkjNRv/MYC16/YR8un02ADp
# v3Y5UirhEToQgLpBq8EEhNoALc5Ah7YYp3s1HQIDAQABo4IBhzCCAYMwDwYDVR0T
# AQH/BAUwAwEBADATBgNVHSUEDDAKBggrBgEFBQcDAzAOBgNVHQ8BAf8EBAMCB4Aw
# MwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2NybC5nb2RhZGR5LmNvbS9nZHM1LTE2
# LmNybDBTBgNVHSAETDBKMEgGC2CGSAGG/W0BBxcCMDkwNwYIKwYBBQUHAgEWK2h0
# dHA6Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8wgYAGCCsG
# AQUFBwEBBHQwcjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZ29kYWRkeS5jb20v
# MEoGCCsGAQUFBzAChj5odHRwOi8vY2VydGlmaWNhdGVzLmdvZGFkZHkuY29tL3Jl
# cG9zaXRvcnkvZ2RfaW50ZXJtZWRpYXRlLmNydDAfBgNVHSMEGDAWgBT9rGEyk2xF
# 1uLuhV+auud2mWjM5zAdBgNVHQ4EFgQUk93pM4DzXTsE+jgTx8VLJ5PIEcEwDQYJ
# KoZIhvcNAQEFBQADggEBALPObKoLjdPEtBmVthOIJIIM/JRAE00B72RTLLECQZZe
# nPmIyJVQs/s/VzQ9biIc9mYtvUnqRrp/kQIScjISpgufPWUrs/4xOhfRpIKumCOs
# I1uDTQZF7Ezp4CxMuo2+o5fS9SaKzChiMNtEJdaOU5ldr7DFClILnqIA7TUpktMp
# tmdocLmNty+eMY5OY2r4/74msBzutEvy8iUfX8LnpL0IK5tN/neY5y0Pwhu4Xdt9
# GB12HFJ0F4UhienVc6IaMtQFxn3Vl7AX9/dc+qsRzobIiHjQoBnnEzLLPuzsSdNe
# kH9ag+klkIEP8s1laqz6fI/aRrDPT6e91wt+mHIWaU0xggUeMIIFGgIBATCB1jCB
# yjELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0
# c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMTMwMQYDVQQLEypodHRw
# Oi8vY2VydGlmaWNhdGVzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkxMDAuBgNVBAMT
# J0dvIERhZGR5IFNlY3VyZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTERMA8GA1UE
# BRMIMDc5NjkyODcCBysQKksZRDQwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFiA9cCq11j3lpni
# TxGnGz0p0piKMA0GCSqGSIb3DQEBAQUABIIBAA+85mye4WgTYlAZRD1sLmAM+aiT
# nFQWHv/xQpzNIzbRes6m5vnhqzARwdepNNUHLY4oO1+vmy6kbwjmNA9AaiR5VRto
# w1LyIHfn+tS0JHaetGlkDhCq5yNUTDVwkSLLiTQqdNxiz+2HFWpBQb3fkK0bI2DQ
# fmgjEwzsxHPAARb96voqAzLmgGEDnDPHHVBav5NoB+DoY7jIOVdPitqRF9KQofNt
# xwWUmnHutVR55tK6bXy+FMRbdLP7wkVUXaEgXGk8lUYlu/XbCNhGNoH79BhlnZTf
# vK1nHhf3Qwa3Kaleb4XHzcflRNeXXUU45hW5/4+UDoWQV0EuswBDRb4s/yWhggKi
# MIICngYJKoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZMBcG
# A1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1l
# c3RhbXBpbmcgQ0EgLSBHMgISESFAXB8O0liIK+VNhoa6EepFMAkGBSsOAwIaBQCg
# gf0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTQw
# OTEyMTg0MjI1WjAjBgkqhkiG9w0BCQQxFgQUGT7AiW7CXPIt+qjVg8JT3KvIhXsw
# gZ0GCyqGSIb3DQEJEAIMMYGNMIGKMIGHMIGEBBSM5p9QEuHRqPs5Xi4x4rQr3js0
# OzBsMFakVDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1z
# YTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESFA
# XB8O0liIK+VNhoa6EepFMA0GCSqGSIb3DQEBAQUABIIBAA31GtXw4Kif8tR88f52
# txvwttmCaKxZKQTv9pvPQbPdjVkV5wRBjjEJsQnPhspvVmMbmx8XKsfv4FjgTjY0
# mC12BtSyiM64qkjj2aJA21vdo2MQdh1xJVebdlqO4/nFAZzDVD7SKVHg6j+lysTC
# MpvpujDPTGlbH4VesMcd+vb2OxYqLJmW+9aig0c080MfMrt4tblpeDwm5tpg4O6j
# EepFiLg85kBDl+OhSuRefGwonYx5x834G2JKHNay1XzMfhGfbm3qpfjqMzm4PsYc
# k6e/cQEsAN+DLh3tWfUtvf66s8qIF7pdyiStzfa8+Ep99KcUw/zPFDxUlajbgyOQ
# 2rE=
# SIG # End signature block
