# Local Variables
$script:compname = gc env:computername
$script:homeDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$script:logFile = $script:homeDir + "\Log\ProcessLog_{0:yyyyMMdd}.txt" -f (Get-Date)
$script:srcDir = "\\mckviewpoint\c$\Scripts\RetailLockBox\20141209_Cleanup\RetailLockBox"
$script:tmpDir = "\\mckviewpoint\c$\Scripts\RetailLockBox\20141209_Cleanup\RetailLockBox\Temp"

function Get-ZipChildItems
{
	param ([string] $zZipFileName)
	$shap = new-object -com shell.application
	$zipFile = $shap.Namespace($zZipFileName)
	$i = $zipFile.Items()
	Get-ZipChildItems_Recurse $i
}

function Get-ZipChildItems_Recurse
{
	param ([object]$items)
	foreach ($si in $items)
	{
		if ($si.getfolder -ne $null)
		{
			#loop through subfolders
			#-------------------------
			Get-ZipChildItems_Recurse $si.getfolder.items()
		}
		#spit out the object
		#---------------------
		#$si
		LogWrite ("{0:yyyyMMdd} : {1}" -f ($si.ModifyDate, $si.Path))
		
		
		if ($si.Name -eq "McKinstryRLBAP_20141103.csv")
		{
			
			LoadCsv $si
		}
		
		
	}
}

Function LoadCsv
{
	param ([object]$item)
	
	if (!(Test-Path -Path $script:tmpDir ))
	{
		New-Item -ItemType directory -Path $script:tmpDir
	}
	
	$tmpFile = $script:tmpDir + "\" + $item.Name
	
	$Shell = New-Object -com shell.application
	$destinationFolder = $Shell.NameSpace($script:tmpDir)

	$destinationFolder.CopyHere($item, 0x14)
	
	
	$Data = Import-Csv -Path $tmpFile
	
	$a =
		@{ Expression = { $_.RecordType }; Label = "RT"; width = 5 }, `
	 @{ Expression = { $_.Company }; Label = "CO"; width = 5 }, `
	 @{ Expression = { $_.Number }; Label = "InvNumber"; width = 15 }, `
	 @{ Expression = { $_.VendorGroup }; Label = "VG"; width = 5 }, `
	 @{ Expression = { $_.Vendor }; Label = "Vendor"; width = 10 }, `
	 @{ Expression = { $_.VendorName }; Label = "VendorName"; width = 30 }, `
	 @{ Expression = { $_.TransactionDate }; Label = "TransactionDate"; width = 15 }, `
	 @{ Expression = { $_.JCCo }; Label = "JCCo"; width = 5 }, `
	 @{ Expression = { $_.Job }; Label = "Job"; width = 20 }, `
	 @{ Expression = { $_.JobDescription }; Label = "JobDescription"; width = 50 }, `
	 @{ Expression = { $_.Description }; Label = "Description"; width = 50 }, `
	@{ Expression = { $_.DetailLineCount }; Label = "LineCnt"; width = 5 }, `
	@{ Expression = { $_.TotalOriginalCost }; Label = "OrigCost"; width = 15 }, `
	@{ Expression = { $_.TotalOrigTax }; Label = "OrigTax"; width = 15 }, `
	@{ Expression = { $_.RemainingAmount }; Label = "RemAmt"; width = 15 }, `
	@{ Expression = { $_.RemainingTax }; Label = "RemTax"; width = 15 }, `
	@{ Expression = { $_.CollectedInvoiceDate }; Label = "RLBInvDate"; width = 15 }, `
	@{ Expression = { $_.CollectedInvoiceNumber }; Label = "RLBInvNumber"; width = 15 }, `
	@{ Expression = { $_.CollectedTaxAmount }; Label = "RLBTaxAmt"; width = 15 }, `
	@{ Expression = { $_.CollectedShippingAmount }; Label = "RLBShipAmt"; width = 15 }, `
	@{ Expression = { $_.CollectedInvoiceAmount }; Label = "RLBInvoiceAmt"; width = 15 }, `
	@{ Expression = { $_.CollectedImage }; Label = "RLBImage"; width = 50 }
	
	$Data | Format-Table $a 
}

Function LogWrite
{
	Param ([string]$logstring)	
	$ts = (Get-Date).ToLongTimeString() + "`t" + $logstring	
	Add-content $Logfile -value $ts
	Write-Host $logstring
}


try
{
	If (Test-Path $script:logFile)
	{
		Remove-Item $script:logFile
	}
	
	LogWrite("-----------------------------------------------")
	LogWrite((Get-Date).ToLongDateString())
	LogWrite("-----------------------------------------------")
	
	Get-ChildItem $script:srcDir -Filter McKinstryRLBAP_20141103_1.zip  | `
	Foreach-Object{
		$content = Get-Content $_.FullName
		
		LogWrite("-----------------------------------------------")
		LogWrite($_.FullName)
		LogWrite("-----------------------------------------------")
		
		Get-ZipChildItems $_.FullName
		
	}
	
	#Get-ZipChildItems "\\mckviewpoint\c$\Scripts\RetailLockBox\20141209_Cleanup\RetailLockBox\McKinstryRLBAP_20141103_1.zip"
}
catch [Exception]
{
	Write-Host $_.Exception.Message
	write-host "Caught an exception:" -ForegroundColor Red
	write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
	write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
	
	exit 1
}

# SIG # Begin signature block
# MIITrgYJKoZIhvcNAQcCoIITnzCCE5sCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDGA9bshbAUvjwNfg+cRlYBwQ
# 9Omggg36MIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPka+n4ZanID2aqv
# KDuQjlv8hnrRMA0GCSqGSIb3DQEBAQUABIIBAIPOZk32Wf1LYgJfiAFSdWdTpYKN
# OquEmf+UHzSO7Bq1j6Hp3IU3esUsOJAox/nV5LrdWkBqxaUKAHkpECSUMs5A7D31
# 8IfJqLe+W8z+Zxr/E2yeXJxpmsj4dsMorza4bll95kubnUQj53NFGYbP5nB64riM
# J1Gmu4fYwXLc9bwpyuqDS0ak7USp3yJU5FS18Dk2LxKerAzEaxnOeOnoe11JMiLE
# xK6zJdHpTO5Dnwz8jf4Z8lVpQV8K+q4nsFCGw3jIlgY9CUrS5seBenjskX2lwACt
# q9Qv8o+ZKtmHtqrypEq5mjb6tN/6jkI//cp0cQmuG6gAxGkfoUQIAyDIN4KhggKi
# MIICngYJKoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZMBcG
# A1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1l
# c3RhbXBpbmcgQ0EgLSBHMgISESFAXB8O0liIK+VNhoa6EepFMAkGBSsOAwIaBQCg
# gf0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTQx
# MjEwMDEyNjQzWjAjBgkqhkiG9w0BCQQxFgQUXBo1WasG0Ti2XML8FEfRQrLjexEw
# gZ0GCyqGSIb3DQEJEAIMMYGNMIGKMIGHMIGEBBSM5p9QEuHRqPs5Xi4x4rQr3js0
# OzBsMFakVDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1z
# YTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESFA
# XB8O0liIK+VNhoa6EepFMA0GCSqGSIb3DQEBAQUABIIBAAn+E0UounvI+/tJwIkC
# NksPUi+72brHhSAfq1gLz1QOJeE7GV+gMb2Uw728Yu93dTb3hNuyI9QrXy7tO39T
# XRdqC1kWsbd7LUZcqXPRlQjuKiZOL4tSzjs1a21YQoawh/H3fEU4/PuFSQt/3XgT
# LVxC2gNxNPn28/PomXEgwXE1LEH970nkrG9DAyM4iS+aAnMrM8rBGq5vzx81tG9D
# irjT5xAK9EjtSCqZfaJnNs144/zQi6wwgzgTd4YAQG5jlGzn+y99Fu5q75XhFiat
# 8lfYW2qjBEo2kp9RuXeXFi46Rp9YJvFnA2rIIkyyXjHrg7HCb2S5pJb+Ck5BfKCn
# PNY=
# SIG # End signature block
