SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE proc [dbo].[vspAPT5018PaymentExport]
/************************************
* Created By:	GF 06/13/2013 TFS-00000 T5018 'CA' contractor pay filing
* Modified By::	
*
* This SP is called from form APT5018EFileGenerate to return vendor payments information
*
***********************************/
(@APCo bCompany = NULL
,@PeriodEndDate SMALLDATETIME = NULL
,@ReportType CHAR(1) = 'O')

AS
SET NOCOUNT ON


---- T5018 SUMMARY INFORMATION
SELECT  SUBSTRING(ISNULL(HQCO.Name, ''), 1, 30)		AS [HQName_1],
		SUBSTRING(ISNULL(HQCO.Name, ''), 31, 60)	AS [HQName_2],
		'' AS [HQName_3],		----Attention
		SUBSTRING(ISNULL(HQCO.[Address], ''), 1, 30)	AS [HQAddress_1],
		SUBSTRING(ISNULL(HQCO.[Address2], ''), 1, 30)	AS [HQAddress_2],
		SUBSTRING(ISNULL(HQCO.City, ''), 1, 28)			AS [HQCity],
		CASE WHEN ISNULL(HQCO.Country, HQCO.DefaultCountry) NOT IN ('CA','US')
				THEN 'ZZ' 
				ELSE HQCO.[State] END AS [HQState],

		SUBSTRING(LTRIM(RTRIM(ISNULL(HQCO.Zip, ''))), 1, 10) AS [HQPostalCode],
		CASE ISNULL(HQCO.Country, HQCO.DefaultCountry)
				WHEN 'CA' THEN 'CAN'
				WHEN 'CAN' THEN 'CAN'
				WHEN 'US' THEN 'USA'
				WHEN 'USA' THEN 'USA'
				WHEN 'AU' THEN 'AUS'
				WHEN 'MX' THEN 'MEX'
				WHEN 'GB' THEN 'GBR'
				ELSE '   ' END AS [HQCountry],
				--ELSE ISNULL(HQCO.Country, HQCO.DefaultCountry) END AS [HQCountry],

		ISNULL(HQCO.FedTaxId, '') AS [HQBusNbr],
		ISNULL(HEADER.ContactName, '') AS [ContactName],
		ISNULL(HEADER.ContactAreaCode, '') AS [ContactAreaCode],
		ISNULL(HEADER.ContactPhone, '') AS [ContactPhone],
		ISNULL(HEADER.ContactExtension, '') AS [ContactExtension],
		ISNULL(HEADER.ContactEmail, '') AS [ContactEmail],
		ISNULL(HEADER.SubmissionReferenceId, '') AS [SubmissionReferenceId],
		ISNULL(HEADER.TransmitterNo, '') AS [TransmitterNo],

		DATEPART(dd, @PeriodEndDate) AS [PeriodEndDay],
		DATEPART(mm, @PeriodEndDate) AS [PeriodEndMth],
		DATEPART(yyyy, @PeriodEndDate) AS [PeriodEndYear],
		ISNULL(vendor.SlipCount, 0) AS [SlipCount],
		ISNULL(vendor.SlipTotal, 0) AS [SlipTotal],
		CASE WHEN @ReportType IN ('A','C') THEN 'A' ELSE 'O' END AS [ReportTypeCode],
		'3' AS [TransmitType],
		'1' AS [TransmitRecCount]

FROM dbo.vAPT5018Payment HEADER
INNER JOIN dbo.bHQCO HQCO ON HQCO.HQCo = HEADER.APCo
	CROSS APPLY  
	(
	SELECT  SUM(ISNULL(DETAIL.TotalPaid, 0)) SlipTotal
			,ISNULL(COUNT(*), 0) AS [SlipCount]
		FROM dbo.vAPT5018PaymentDetail DETAIL
		WHERE DETAIL.APCo = @APCo
			AND DETAIL.PeriodEndDate = @PeriodEndDate
			AND 1 = CASE WHEN @ReportType = 'O' AND DETAIL.ReportTypeCode = 'O' THEN 1
				 WHEN @ReportType = 'A' AND DETAIL.ReportTypeCode IN ('A','C') THEN 1
				 ELSE 0 END 
	) vendor

WHERE HEADER.APCo = @APCo
	AND HEADER.PeriodEndDate = @PeriodEndDate


---- detail applies for both original and refiling - will use case in where clause
---- get T5018 Payment Detail
SELECT 	ISNULL(DETAIL.VendorGroup, 0)	AS [VendorGroup],
		ISNULL(DETAIL.Vendor, 0)		AS [Vendor],
		SUBSTRING(ISNULL(DETAIL.VendorName, ''),1,30)  AS [VendorName_1],
		SUBSTRING(ISNULL(DETAIL.VendorName, ''),31,30) AS [VendorName_2],
		ISNULL(DETAIL.[Address], '')	AS [Address],
		ISNULL(DETAIL.[Address2], '')	AS [Address2],
		ISNULL(DETAIL.City, '')			AS [City],
		ISNULL(DETAIL.PostalCode, '')	AS [PostalCode],

		CASE WHEN ISNULL(DETAIL.Country, HQCO.DefaultCountry) NOT IN ('CA','US')
				THEN 'ZZ'
				ELSE DETAIL.[State] END AS [State],

		CASE ISNULL(DETAIL.Country, HQCO.DefaultCountry)
				WHEN 'CA' THEN 'CAN'
				WHEN 'CAN' THEN 'CAN'
				WHEN 'US' THEN 'USA'
				WHEN 'USA' THEN 'USA'
				WHEN 'AU' THEN 'AUS'
				WHEN 'MX' THEN 'MEX'
				WHEN 'GB' THEN 'GBR'
				ELSE '   ' END AS [Country],
				--ELSE ISNULL(DETAIL.Country, HQCO.DefaultCountry) END AS [Country],

		CASE ISNULL(DETAIL.T5BusTypeCode, 'C')
				WHEN 'I' THEN '1'
				WHEN 'C' THEN '3'
				WHEN 'P' THEN '4'
				END AS [T5BusTypeCode],

		CASE LEN(LTRIM(RTRIM(ISNULL(DETAIL.T5BusinessNbr, ''))))
				WHEN 0 THEN '000000000RZ0000'
				WHEN 9 THEN DETAIL.T5BusinessNbr + 'RZ0000'
				ELSE DETAIL.T5BusinessNbr
				END AS [T5BusinessNbr],

		ISNULL(DETAIL.T5PartnerFIN, '') AS [T5PartnerFIN],
		ISNULL(DETAIL.T5FirstName, '')	AS [T5FirstName],
		ISNULL(DETAIL.T5MiddleInit, '') AS [T5MiddleInit],
		ISNULL(DETAIL.T5LastName, '')	AS [T5LastName],
		CASE WHEN ISNULL(DETAIL.T5SocInsNbr, '') = '' 
				THEN '000000000' 
				ELSE DETAIL.T5SocInsNbr 
				END AS [T5SocInsNbr],

		ISNULL(DETAIL.TotalPaid, 0)	AS [TotalPaid], 
		ISNULL(DETAIL.ReportTypeCode, '') AS [ReportTypeCode]

FROM dbo.vAPT5018PaymentDetail DETAIL
INNER JOIN dbo.bHQCO HQCO ON HQCO.HQCo = DETAIL.APCo
WHERE DETAIL.APCo = @APCo
	AND DETAIL.PeriodEndDate = @PeriodEndDate
	AND 1 = CASE WHEN @ReportType = 'O' AND DETAIL.ReportTypeCode = 'O' THEN 1
				 WHEN @ReportType = 'A' AND DETAIL.ReportTypeCode IN ('A','C') THEN 1
				 ELSE 0 END 





---- OLD QUERY
--if @reporttype = 'A' --Amended refiling
--	begin
--	select isnull(c.Name,'')'HQName',isnull(c.Address,'') 'HQAddress', isnull(c.City,'') 'HQCity', isnull(c.State,'') 'HQState',
--		isnull(c.Country,'') 'HQCountry', isnull(c.Zip,'') 'HQPostal', isnull(c.FedTaxId,'') 'HQBusNbr',isnull(v.Name,'') 'VMName',
--		----TFS-47400
--     			CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Address]  ELSE v.[Address]	END AS [VMAddress],
--				CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[City]	 ELSE v.[City]		END AS [VMCity],
--				CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[State]    ELSE v.[State]		END AS [VMState],
--				CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Zip]      ELSE v.[Zip]		END AS [VMPostal],
--				CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Country]  ELSE v.Country		END AS [VMCountry], 
--		--isnull(v.Address,'') 'VMAddress', isnull(v.City,'') 'VMCity', isnull(v.State,'') 'VMState', isnull(v.Zip,'') 'VMPostal',
--		--isnull(v.Country,'') 'VMCountry',
--		isnull(v.T5BusTypeCode,'') 'VMBusTypeCode', isnull(v.T5BusinessNbr,'') 'VMBusinessNbr',
--		isnull(v.T5PartnerFIN,'') 'VMPartnerFIN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', isnull(v.T5FirstName,'') 'VMFirstName',
--		isnull(v.T5MiddleInit,'') 'VMMiddleInit', isnull(v.T5LastName,'') 'VMLastName', isnull(t.Amount,'0') 'T5Amount', isnull(t.Type,'') 'T5Type'
--	From dbo.bAPT5 t (nolock)
--	join dbo.bAPVM v (nolock) on t.VendorGroup=v.VendorGroup and t.Vendor=v.Vendor
--	join dbo.bHQCO c (nolock) on c.HQCo=t.APCo
--	----TFS-47480
--	LEFT JOIN dbo.bAPAA APAA ON APAA.VendorGroup = v.VendorGroup AND APAA.Vendor = v.Vendor AND APAA.AddressSeq = v.V1099AddressSeq
--	where t.APCo=@co and @perenddate=t.PeriodEndDate and t.VendorGroup=@vendorgroup and t.RefilingYN='Y' AND v.V1099YN = 'Y' 
--	end
--else
--	begin	--Original filing
--	select isnull(c.Name,'')'HQName',isnull(c.Address,'') 'HQAddress', isnull(c.City,'') 'HQCity', isnull(c.State,'') 'HQState',
--		isnull(c.Country,'') 'HQCountry', isnull(c.Zip,'') 'HQPostal', isnull(c.FedTaxId,'') 'HQBusNbr',isnull(v.Name,'') 'VMName',
--		----TFS-47400
--     			CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Address]  ELSE v.[Address]	END AS [VMAddress],
--				CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[City]	 ELSE v.[City]		END AS [VMCity],
--				CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[State]    ELSE v.[State]		END AS [VMState],
--				CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Zip]      ELSE v.[Zip]		END AS [VMPostal],
--				CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Country]  ELSE v.Country		END AS [VMCountry], 
--		--isnull(v.Address,'') 'VMAddress', isnull(v.City,'') 'VMCity', isnull(v.State,'') 'VMState', isnull(v.Zip,'') 'VMPostal',
--		--isnull(v.Country,'') 'VMCountry', 
--		isnull(v.T5BusTypeCode,'') 'VMBusTypeCode', isnull(v.T5BusinessNbr,'') 'VMBusinessNbr',
--		isnull(v.T5PartnerFIN,'') 'VMPartnerFIN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', isnull(v.T5FirstName,'') 'VMFirstName',
--		isnull(v.T5MiddleInit,'') 'VMMiddleInit', isnull(v.T5LastName,'') 'VMLastName', isnull(t.OrigAmount,'0') 'T5Amount', isnull(t.Type,'') 'T5Type'
--	From dbo.bAPT5 t (nolock)
--	join dbo.bAPVM v (nolock) on t.VendorGroup=v.VendorGroup and t.Vendor=v.Vendor
--	join dbo.bHQCO c (nolock) on c.HQCo=t.APCo
--	----TFS-47480
--	LEFT JOIN dbo.bAPAA APAA ON APAA.VendorGroup = v.VendorGroup AND APAA.Vendor = v.Vendor AND APAA.AddressSeq = v.V1099AddressSeq
--	where t.APCo=@co and @perenddate=t.PeriodEndDate and t.VendorGroup=@vendorgroup and t.RefilingYN='N'
--	end

   

RETURN











GO
GRANT EXECUTE ON  [dbo].[vspAPT5018PaymentExport] TO [public]
GO
