﻿#------------------------------------------------------------------------
# Source File Information (DO NOT MODIFY)
# Source ID: 7aae12de-7fec-48fa-8e64-a53811324944
# Source File: C:\TFSLocal\Viewpoint\Maintenance\Admin Scripts and PS\ViewpointUserCreate\ViewpointUserCreate.psproj
#------------------------------------------------------------------------
<#
    .NOTES
    --------------------------------------------------------------------------------
     Code generated by:  SAPIEN Technologies, Inc., PowerShell Studio 2014 v4.1.74
     Generated on:       11/26/2014 12:31 PM
     Generated by:       EricS
     Organization:       McKinstry Co
    --------------------------------------------------------------------------------
    .DESCRIPTION
        Script generated by PowerShell Studio 2014
#>


#region Source: Startup.pss
#----------------------------------------------
#region Import Assemblies
#----------------------------------------------
[void][Reflection.Assembly]::Load('mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][Reflection.Assembly]::Load('System.Xml, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.DirectoryServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][Reflection.Assembly]::Load('System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.ServiceProcess, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
#endregion Import Assemblies

#Define a Param block to use custom parameters in the project
#Param ($CustomParameter)

function Main {
	Param ([String]$Commandline)
	#Note: This function starts the application
	#Note: $Commandline contains the complete argument string passed to the packager 
	#Note: To get the script directory in the Packager use: Split-Path $hostinvocation.MyCommand.path
	#Note: To get the console output in the Packager (Forms Mode) use: $ConsoleOutput (Type: System.Collections.ArrayList)
	#TODO: Initialize and add Function calls to forms
	
	if((Call-MainForm_psf) -eq "OK")
	{
		
	}
	
	$global:ExitCode = 0 #Set the exit code for the Packager
}






#endregion Source: Startup.pss

#region Source: MainForm.psf
function Call-MainForm_psf
{
	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	[void][reflection.assembly]::Load('System.Xml, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.DirectoryServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	[void][reflection.assembly]::Load('System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.ServiceProcess, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	#endregion Import Assemblies

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$MainForm = New-Object 'System.Windows.Forms.Form'
	$buttonExecute = New-Object 'System.Windows.Forms.Button'
	$buttonBrowse = New-Object 'System.Windows.Forms.Button'
	$textboxFile = New-Object 'System.Windows.Forms.TextBox'
	$imagelistButtonBusyAnimation = New-Object 'System.Windows.Forms.ImageList'
	$openfiledialog1 = New-Object 'System.Windows.Forms.OpenFileDialog'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$OnLoadFormEvent={
	#TODO: Initialize Form Controls here
	
	}
	
	
	
	
	$buttonBrowse_Click={
	
		if($openfiledialog1.ShowDialog() -eq 'OK')
		{
			$textboxFile.Text = $openfiledialog1.FileName
			$ExcelPath = $textboxFile.Text
		}
	}
	
	
	
	###################################
	$buttonExecute_Click = {
		$this.Enabled = $False
		#TODO: Place custom script here
		
		#Script
		###############################################
		$User = ""
		$Email = ""
		$CellPhone = ""
		$OfficePhone = 1
		$EmployeeNumber = ""
		$EmployeeName = ""
		$EmployeeCo = ""
		$ViewpointYN = ""
		$Package = ""
		$ReturnMessage = ""
		$Return = ""
		
		$Return = Get-ExcelOnboardingDetails $ExcelPath
		#([ref]$User) ([ref]$Email) ([ref]$CellPhone) ([ref]$OfficePhone) ([ref]$EmployeeNumber.Value) ([ref]$EmployeeCo) ([ref]$EmployeeName) ([ref]$ViewpointYN) ([ref]$Package)
		$UserExc = $Return[0]
		$Email = $Return[1]
		$CellPhone = $Return[2]
		$OfficePhone = $Return[3]
		$EmployeeNumber = $Return[4]
		$EmployeeCo = $Return[5].substring(0, 2) -replace '"', ''
		$EmployeeName = $Return[6]
		$ViewpointYN = $Return[7]
		$Package = $Return[8]
		
		#Write-Host 'ExcelImport' $User $Email
		
		$Group = 'ViewpointUsers'
		If ($ViewpointYN = 'Yes')
		{
			$ReturnAD = ADCheckAndAddUser $Group $UserExc
	#		$ReturnAD.Message = $ReturnAD[0]
	#		$ReturnAD.User = $ReturnAD[1]
		}
		$User = $ReturnAD
		#$User = $Return
		#Write-Host $Return 'RETURN'
		#Write-Host $User 'USER bla'
		
		If ($User -ine $null)
		{
			#Write-Host 'User Not Null' $User
			If ($ViewpointYN = 'Yes')
			{
				#Write-Host 'VP = Yes' $User
				$ReturnSQL = ExecSQLUserProfile $User $Package $Email $EmployeeNumber $EmployeeCo $EmployeeName $OfficePhone $CellPhone
				#[ref]$ReturnSQL
				#Write-Host $Return	$User
			}
		}
		
		#$ReturnMessage = $Return[0]
		
		$FinalReturn = $Return + " - " + $ReturnAD + " - " + $ReturnSQL
		[void][System.Windows.Forms.MessageBox]::Show( $MainForm.Owner, $FinalReturn)
		$this.Enabled = $True
	}
	
		#Write-Host $Return
		
		#[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
		
		
		#Process the pending messages before enabling the button
		#[System.Windows.Forms.Application]::DoEvents()
		
	
	
	
	
		# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$MainForm.WindowState = $InitialFormWindowState
	}
	
	$Form_StoreValues_Closing=
	{
		#Store the control values
		$script:MainForm_textboxFile = $textboxFile.Text
	}

	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonExecute.remove_Click($buttonExecute_Click)
			$buttonBrowse.remove_Click($buttonBrowse_Click)
			$MainForm.remove_Load($OnLoadFormEvent)
			$MainForm.remove_Load($Form_StateCorrection_Load)
			$MainForm.remove_Closing($Form_StoreValues_Closing)
			$MainForm.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$MainForm.SuspendLayout()
	#
	# MainForm
	#
	$MainForm.Controls.Add($buttonExecute)
	$MainForm.Controls.Add($buttonBrowse)
	$MainForm.Controls.Add($textboxFile)
	$MainForm.ClientSize = '292, 266'
	#region Binary Data
	$MainForm.Icon = [System.Convert]::FromBase64String('
AAABAAEAICAAAAEACACoCAAAFgAAACgAAAAgAAAAQAAAAAEACAAAAAAAAAQAAAAAAAAAAAAAAAEA
AAABAAAAAAAAUz4JAFQ/CgBVQAsAVUAMAFZBDQBXQg4AWEMQAFlFEQBcSBYAXUkXAF1KGABfTBsA
YU4dAGJPHwBjUCAAZVIjAGdUJgBoVSYAaFYoAGlWKABqVykAalgqAGtaLABsWiwAblwwAG9dMQBw
XzMAcWA0AHJhNgBzYjcAdGM5AHVkOgB2ZTwAd2Y9AHlpPwB6aUAAfW1FAH9wSACAcEkAgnJMAIZ3
UQCHeFMAiHlVAIh6VQCJe1YAi3xZAI1/WwCPgl8AkINhAJGDYQCRhGIAkoVjAJOFZACThmUAlIdm
AJWIZwCXimoAm45wAJyPcQCeknQAn5N2AKCVeAChlXgAopd7AKOYewCkmX0AppuAAKecgAConYIA
qqCGAKuhhwCsoogAraOKAK+ljACwpo0As6qTALSrlAC1rJYAtq2WALevmQC4r5kAubGbALuzngC9
taEAv7ejAMK7qADDvKoAxb6sAMfArwDHwbAAyMGwAMjCsQDJwrEAysS0AMvFtgDMxbYAzMa2AM7I
uQDQyrsA0Mq8ANHMvgDTzcAA087AANTPwQDV0MMA2NTIANnUyADa1coA2tbKANvWywDc2M0A3trP
AN7a0ADf29EA4N3TAOHd1ADj39cA4+DXAOPg2ADl4dkA5eLaAOfk3ADo5d4A6ufhAOzq5ADv7egA
8O7qAPLx7QDz8e4A8/LuAPTy7wD08/AA9vXyAPj39QD5+PYA+vn4APr6+AD7+/oA/Pv6APz8+wD9
/PwA/v7+AP/+/gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAA////////////////MhwLAQELHDL///////////////////////////8vBQEBAQEBAQEBAQEF
L/////////////////////85AgEBAQEBAQEBAQEBAQEBAjn/////////////////FAEBAQEBAQEB
AQEBAQEBAQEBARb//////////////woBAQEBAQEBAQEBAQEBAQEBAQEBAQr///////////8KAQEB
AQEBAQEBAQEBAQEBAQEBAQEBAQr/////////FwEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBARf/////
/zoBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBATr/////AwEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB
AQEBA////zMBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBM///BhAtLRgBJy0UASctKQEUSFVM
LgQQLS0dAQ0tLScG//8BII+PTwF0j1wBW4+PEn6Pj4+PZCSPj2IBM4+PYAH/NwEGh49pAXaPjBU/
j49Ej49mQY6PO4iPfwFIj49GATgfAQFrj4QCd4+PSyKPj1GOj1IBa49lbY+PGFqPjy4BHwwBAUyP
jxNxj4+ACYWPY3qPcAEpQz5Pj49ido+PFAEMAQEBMY+PK2+Pi481Yo+CV4+KCAEBATWPj4+Pj4MC
AQEBAQEYj49Fbo9dj2tCj49Qj48kCTxCMI+Pj4+PZwEBAgwBAQKBj1psjzZ/jz2Pj02Pj0AKj49L
hY+Pj49TAQEMHwEBAWSPeWqPMkmPWIePTnGPhWGPj0toj498j4MPAR83AQEBR4+NcY8zEo2JeI9r
GXWPj49+GkuPj0qGj1YBOP8BAQEqj4+HjzYBWY+Mj4cGBCIsJQgBLo+PVEOPjyj//wYBAQ6Pj4+P
NwElj4+Pjx4BAQEBAQEQj49yB3ePX///MwEBAXuPj480AQFzj4+POQEBAQEBAQF9j4wIJo9e////
AwEBGiMjIw0BARQjIyMRAQEBAQEBARsjIwgBIf////86AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB
AQE6//////8XAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBF/////////8KAQEBAQEBAQEBAQEBAQEB
AQEBAQEBAQr///////////8KAQEBAQEBAQEBAQEBAQEBAQEBAQEK//////////////8WAQEBAQEB
AQEBAQEBAQEBAQEBFv////////////////85AgEBAQEBAQEBAQEBAQEBAjn/////////////////
////LwUBAQEBAQEBAQEBBS////////////////////////////8yGwkBAQscMv//////////////
///wD///gAH//gAAf/wAAD/4AAAf8AAAD+AAAAfAAAADwAAAA4AAAAGAAAABgAAAAQAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAYAAAAGAAAABwAAAA8AAAAPgAAAH8AAAD/gAAB/8
AAA//gAAf/+AAf//8A//')
	#endregion
	$MainForm.Name = "MainForm"
	$MainForm.StartPosition = 'CenterScreen'
	$MainForm.Text = "Viewpoint User Create"
	$MainForm.add_Load($OnLoadFormEvent)
	#
	# buttonExecute
	#
	$buttonExecute.Location = '150, 163'
	$buttonExecute.Name = "buttonExecute"
	$buttonExecute.Size = '75, 23'
	$buttonExecute.TabIndex = 1
	$buttonExecute.Text = "Execute"
	$buttonExecute.UseVisualStyleBackColor = $True
	$buttonExecute.add_Click($buttonExecute_Click)
	#
	# buttonBrowse
	#
	$buttonBrowse.Location = '246, 83'
	$buttonBrowse.Name = "buttonBrowse"
	$buttonBrowse.Size = '30, 23'
	$buttonBrowse.TabIndex = 1
	$buttonBrowse.Text = "..."
	$buttonBrowse.UseVisualStyleBackColor = $True
	$buttonBrowse.add_Click($buttonBrowse_Click)
	#
	# textboxFile
	#
	$textboxFile.AutoCompleteMode = 'SuggestAppend'
	$textboxFile.AutoCompleteSource = 'FileSystem'
	$textboxFile.Location = '12, 85'
	$textboxFile.Name = "textboxFile"
	$textboxFile.Size = '228, 20'
	$textboxFile.TabIndex = 0
	#
	# imagelistButtonBusyAnimation
	#
	$Formatter_binaryFomatter = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
	#region Binary Data
	$System_IO_MemoryStream = New-Object System.IO.MemoryStream (,[byte[]][System.Convert]::FromBase64String('
AAEAAAD/////AQAAAAAAAAAMAgAAAFdTeXN0ZW0uV2luZG93cy5Gb3JtcywgVmVyc2lvbj00LjAu
MC4wLCBDdWx0dXJlPW5ldXRyYWwsIFB1YmxpY0tleVRva2VuPWI3N2E1YzU2MTkzNGUwODkFAQAA
ACZTeXN0ZW0uV2luZG93cy5Gb3Jtcy5JbWFnZUxpc3RTdHJlYW1lcgEAAAAERGF0YQcCAgAAAAkD
AAAADwMAAAB2CgAAAk1TRnQBSQFMAgEBCAEAAXABAAFwAQABEAEAARABAAT/ASEBAAj/AUIBTQE2
BwABNgMAASgDAAFAAwABMAMAAQEBAAEgBgABMP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/
AP8AugADwgH/Az0B/wM9Af8DwgH/MAADwgH/A10B/wOCAf8DwgH/sAADPQH/AwAB/wMAAf8DPQH/
MAADggH/Az0B/wM9Af8DXQH/gAADwgH/Az0B/wM9Af8DwgH/IAADPQH/AwAB/wMAAf8DPQH/A8IB
/wNdAf8DggH/A8IB/xAAA8IB/wM9Af8DPQH/A8IB/wNdAf8DPQH/Az0B/wNdAf8EAAOSAf8DkgH/
A8IB/3AAAz0B/wMAAf8DAAH/Az0B/yAAA8IB/wM9Af8DPQH/A8IB/wOCAf8DPQH/Az0B/wOCAf8Q
AAM9Af8DAAH/AwAB/wM9Af8DwgH/A10B/wOCAf8DwgH/A5IB/wOCAf8DggH/A5IB/3AAAz0B/wMA
Af8DAAH/Az0B/zAAA10B/wM9Af8DPQH/A10B/xAAAz0B/wMAAf8DAAH/Az0B/xAAA5IB/wOSAf8D
kgH/A8IB/3AAA8IB/wM9Af8DPQH/A8IB/zAAA8IB/wNdAf8DggH/A8IB/xAAA8IB/wM9Af8DPQH/
A8IB/xAAA8IB/wOSAf8DkgH/A8IB/zgAA8IB/wM9Af8DPQH/A8IB/zAAA8IB/wOCAf8DXQH/A8IB
/zAAA8IB/wPCAf8DkgH/A8IB/zQAA8IB/wPCAf80AAM9Af8DAAH/AwAB/wM9Af8wAANdAf8DPQH/
Az0B/wNdAf8wAAOSAf8DggH/A4IB/wOSAf8wAAPCAf8DwgH/A8IB/wPCAf8wAAM9Af8DAAH/AwAB
/wM9Af8wAAOCAf8DPQH/Az0B/wOCAf8wAAPCAf8DggH/A5IB/wOSAf8wAAPCAf8DwgH/A8IB/wPC
Af8wAAPCAf8DPQH/Az0B/wPCAf8wAAPCAf8DggH/A10B/wPCAf8wAAPCAf8DkgH/A5IB/wPCAf80
AAPCAf8DwgH/EAADwgH/A8IB/xQAA8IB/wOCAf8DXQH/A8IB/zAAA8IB/wOSAf8DkgH/A8IB/zQA
A8IB/wPCAf9UAAPCAf8DwgH/A8IB/wPCAf8QAANdAf8DPQH/Az0B/wNdAf8wAAOSAf8DggH/A5IB
/wOSAf8wAAPCAf8DwgH/A8IB/wPCAf9QAAPCAf8DwgH/A8IB/wPCAf8DwgH/A8IB/wOSAf8DwgH/
A4IB/wM9Af8DPQH/A4IB/yQAA8IB/wPCAf8EAAPCAf8DggH/A5IB/wOSAf8wAAPCAf8DwgH/A8IB
/wPCAf9UAAPCAf8DwgH/BAADkgH/A4IB/wOCAf8DkgH/A8IB/wOCAf8DXQH/A8IB/yAAA8IB/wPC
Af8DwgH/A8IB/wPCAf8DkgH/A5IB/wPCAf80AAPCAf8DwgH/ZAADkgH/A5IB/wOSAf8DkgH/MAAD
wgH/A8IB/wPCAf8DwgH/sAADwgH/A5IB/wOSAf8DwgH/NAADwgH/A8IB/7QAA8IB/wPCAf8DkgH/
A8IB/zQAA8IB/wPCAf+0AAOSAf8DggH/A4IB/wOSAf8wAAPCAf8DwgH/A8IB/wPCAf+gAAPCAf8D
XQH/A4IB/wPCAf8DkgH/A5IB/wOSAf8DwgH/BAADwgH/A8IB/xQAA8IB/wPCAf8DkgH/A8IB/wPC
Af8DwgH/A8IB/wPCAf8kAAPCAf8DwgH/dAADggH/Az0B/wM9Af8DggH/A8IB/wOSAf8DkgH/A8IB
/wPCAf8DwgH/A8IB/wPCAf8QAAOSAf8DggH/A4IB/wOSAf8EAAPCAf8DwgH/JAADwgH/A8IB/wPC
Af8DwgH/cAADXQH/Az0B/wM9Af8DggH/EAADwgH/A8IB/wPCAf8DwgH/EAADkgH/A5IB/wOSAf8D
kgH/MAADwgH/A8IB/wPCAf8DwgH/cAADwgH/A10B/wNdAf8DwgH/FAADwgH/A8IB/xQAA8IB/wOS
Af8DkgH/A8IB/zQAA8IB/wPCAf9sAAPCAf8DPQH/Az0B/wPCAf8wAAPCAf8DXQH/A4IB/wPCAf8w
AAPCAf8DwgH/A5IB/wPCAf80AAPCAf8DwgH/NAADPQH/AwAB/wMAAf8DPQH/MAADggH/Az0B/wM9
Af8DXQH/MAADkgH/A4IB/wOCAf8DkgH/MAADwgH/A8IB/wPCAf8DwgH/MAADPQH/AwAB/wMAAf8D
PQH/MAADXQH/Az0B/wM9Af8DggH/MAADkgH/A5IB/wOSAf8DkgH/MAADwgH/A8IB/wPCAf8DwgH/
MAADwgH/Az0B/wM9Af8DwgH/MAADwgH/A10B/wNdAf8DwgH/MAADwgH/A5IB/wOSAf8DwgH/NAAD
wgH/A8IB/3wAA8IB/wM9Af8DPQH/A8IB/zAAA8IB/wNdAf8DggH/A8IB/zAAA8IB/wPCAf8DkgH/
A8IB/xAAA8IB/wM9Af8DPQH/A8IB/1AAAz0B/wMAAf8DAAH/Az0B/zAAA4IB/wM9Af8DPQH/A10B
/zAAA5IB/wOCAf8DggH/A5IB/xAAAz0B/wMAAf8DAAH/Az0B/1AAAz0B/wMAAf8DAAH/Az0B/zAA
A10B/wM9Af8DPQH/A4IB/wOSAf8DPQH/Az0B/wPCAf8gAAOSAf8DkgH/A5IB/wOSAf8DwgH/A10B
/wOCAf8DwgH/Az0B/wMAAf8DAAH/Az0B/1AAA8IB/wM9Af8DPQH/A8IB/zAAA8IB/wOCAf8DXQH/
A8IB/wM9Af8DAAH/AwAB/wM9Af8gAAPCAf8DkgH/A5IB/wPCAf8DggH/Az0B/wM9Af8DXQH/A8IB
/wM9Af8DPQH/A8IB/6AAAz0B/wMAAf8DAAH/Az0B/zAAA10B/wM9Af8DPQH/A4IB/7AAA8IB/wM9
Af8DPQH/A8IB/zAAA8IB/wOCAf8DXQH/A8IB/xgAAUIBTQE+BwABPgMAASgDAAFAAwABMAMAAQEB
AAEBBQABgAEBFgAD/4EABP8B/AE/AfwBPwT/AfwBPwH8AT8D/wHDAfwBAwHAASMD/wHDAfwBAwHA
AQMD/wHDAf8DwwP/AcMB/wPDAf8B8AH/AfAB/wHwAf8B+QH/AfAB/wHwAf8B8AH/AfAB/wHwAf8B
8AH/AfAB/wHwAf8B8AH/AfAB/wHwAf8B+QHnAcMB/wHDAf8B5wL/AsMB/wHDAf8BwwL/AcABAwH+
AUMB/wHDAv8B5AEDAfwBAwH/AecC/wH8AT8B/AE/BP8B/AE/Af4BfwT/AfwBPwH+AX8E/wH8AT8B
/AE/BP8BwAEnAcABPwHnA/8BwAEDAcIBfwHDA/8DwwH/AcMD/wHDAecBwwH/AecD/wEPAf8BDwH/
AQ8B/wGfAf8BDwH/AQ8B/wEPAf8BDwH/AQ8B/wEPAf8BDwH/AQ8B/wEPAf8BDwH/AQ8B/wGfA/8B
wwH/AcMB/wLDAv8BwwH/AcMB/wLDAv8BwwH/AcABPwHAAQMC/wHDAf8BwAE/AcABAwT/AfwBPwH8
AT8E/wH8AT8B/AE/Cw=='))
	#endregion
	$imagelistButtonBusyAnimation.ImageStream = $Formatter_binaryFomatter.Deserialize($System_IO_MemoryStream)
	$Formatter_binaryFomatter = $null
	$System_IO_MemoryStream = $null
	$imagelistButtonBusyAnimation.TransparentColor = 'Transparent'
	#
	# openfiledialog1
	#
	$openfiledialog1.DefaultExt = "xlsm"
	$openfiledialog1.Filter = "Excel File (.xlsm)|*.xls*|All Files|*.*"
	$openfiledialog1.ShowHelp = $True
	$MainForm.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $MainForm.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$MainForm.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$MainForm.add_FormClosed($Form_Cleanup_FormClosed)
	#Store the control values when form is closing
	$MainForm.add_Closing($Form_StoreValues_Closing)
	#Show the Form
	return $MainForm.ShowDialog()
}
#endregion Source: MainForm.psf

#region Source: Globals.ps1
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
	#$User = 'EricS'
	
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
		If ($Package -eq "No Data")
		{
			$Package = ''
		}
		#$ViewpointYN.Value
		#$Package.Value
		
		$HRSheet = $Workbook.sheets.item("HR")
		$EmployeeName = $HRsheet.Range("EMPNAME").Text
		$EmployeeCo = $HRsheet.Range("EMPCO").Text
		$EmployeeNumber = $HRsheet.Range("EMPNUMBER").Text
		
		
		$ITSheet = $Workbook.sheets.item("IT")
		$User = $ITSheet.Range("UserName").Text
		$Email = $ITSheet.Range("Email").Text
		$CellPhone = $ITSheet.Range("CellPhone").Text
		$OfficePhone = $ITSheet.Range("DeskPhone").Text
		
		
	
		
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
			#Write-Host $User.Value + ' added to group ' + $Group
			$User.Value
			
		}
		Else
		{
			#Write-Host $User.Value ' already a member of group ' $Group
			$User.Value
		}
	}
	
	
	function ExecSQLUserProfile
	{
		param (
				[string]$User
				, [string]$Package
				, [string]$Email
				, [string]$EmployeeNumber
				, [string]$EmployeeCo
				, [string]$EmployeeName
				, [string]$OfficePhone
				, [string]$CellPhone
				#, [ref]$ReturnMessage
			)
		
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
		#Write-Output $OutputValue
		
		$SqlConnection.Close() | Out-Null
		$SqlCmd.Dispose() | Out-Null
		
		#RETURN $OutputValue
		$ReturnMessage = $OutputValue
		
		$ReturnMessage
	}
	
		
		#Write-Host 'User: '$User ' - Email: ' $Email ' - Employee Number: ' $EmployeeNumber ' - Employee Name: ' $EmployeeName ' - Employee Co: ' $EmployeeCo
	#Write-Host 'Cell Phone: ' $CellPhone ' - Desk Phone: ' $OfficePhone
	#endregion Source: Globals.ps1

#Start the application
Main ($CommandLine)

# SIG # Begin signature block
# MIITrgYJKoZIhvcNAQcCoIITnzCCE5sCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUTAZ36/Zm0wkBD4AZr4wRBbp
# aG6ggg36MIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPS2jxccGo41WA7x
# 0cQtNM/zgpWoMA0GCSqGSIb3DQEBAQUABIIBAEtC9JPj5Fzvo6MVJeX1T9am4xbr
# kVoGpcnv2ABPendjeh3fBPqohWjlEt0n0s7vwVo2UVPfQK4Oh0EXuuG66h35IJcP
# oOJsV0tnyJ8ArP1sPFTiZX+laO9ktrc5904BA3bjI6A4s8w6LR4k46l6AM8VEvUu
# OEzUmhdvHHnB/Wd0PDmQXPprSkPzJ1ZcTjOmaxtDKTru0TiaI6M0nYNwCjOuMucr
# ZR+kSQ6yG96NIG4/3KrCk2ZzSenoH5hcBjA+ERIS71xwXMW/fBNoTalcZ/9o/ndA
# Vg0xFdIzgvR/0l/IAkuve7Vdibb6caNrfokguMK4I5USTx0F0YS45TR8VcChggKi
# MIICngYJKoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZMBcG
# A1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1l
# c3RhbXBpbmcgQ0EgLSBHMgISESFAXB8O0liIK+VNhoa6EepFMAkGBSsOAwIaBQCg
# gf0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTQx
# MTI2MjAzMTE4WjAjBgkqhkiG9w0BCQQxFgQUy77H1Ml6IGkMOsJqae/3r60z++Ew
# gZ0GCyqGSIb3DQEJEAIMMYGNMIGKMIGHMIGEBBSM5p9QEuHRqPs5Xi4x4rQr3js0
# OzBsMFakVDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1z
# YTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESFA
# XB8O0liIK+VNhoa6EepFMA0GCSqGSIb3DQEBAQUABIIBABXwmM9NSoB60u/CqL7Z
# ZK3BuMOvso6cmcECfgwOHBkzREjUqFF0VAFxr4HGOo3zZW2WCXHmMjgeTg9M2eNZ
# oHG+xWYdeQJ3Rq8kwNDRxVdzAlzomXentLgT9Teo/NYHTtF/dRnwmYuMgZDXxiYs
# fYX+26GqhuT2OMK7DuQ3KiN6hIGp259GFR9KC5I0OG/i1eBeT8/N4EnuA1J7/SQZ
# NL3z7/wOfNZigajR3FTz9FneB6XSCpv2nVOS3/RfHD6+xHk00qSRR6GvhfLd3x+i
# v94z7bu8ckn8UukDw1PbUZ7C1bmwClJ/xzrv9skt0rqRk8aeyvhZgo9np3Fqgaqx
# nHY=
# SIG # End signature block
