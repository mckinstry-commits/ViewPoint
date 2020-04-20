SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--SELECT * FROM APVM WHERE udEmployee IS NOT NULL OR udEmployeeYN='Y'

CREATE VIEW [dbo].[mvwCreateACheckVendorExport]
AS

SELECT
	v.Vendor AS VendorID
,	v.Name AS VendorName
,	v.Address AS AddressLine1
,	v.Address2 AS AddressLine2
,	null AS AddressLine3
,	v.City AS City
,	v.State AS State
,	COALESCE(v.Country,'US') AS Country
,	v.Zip as PostalCode
,	v.Phone AS PhoneNumber
,	COALESCE(v.EMail,e.Email) AS EmailAddress
,	'N' AS UseEmail
,	null AS GLAcct
,	'VP Employee Expense Vendor Record' AS Memo
,	cast(coalesce(v.udPRCo,'XX') AS varchar(10)) + '.' + cast(coalesce(v.udEmployee,'XXXXXX') AS varchar(10)) as CustomData1
,	null AS CustomData2
,	case v.EFT when 'A' then 'N' else 'Y' end ExcludeFromACH_YN
,	case v.EFT when 'A' then v.BankAcct ELSE null end AS BankAccountNumber
,	case v.EFT when 'A' then 'PPD' else null end AS SECCode					--PPD, CCD, CTX or IAT
,	case v.EFT when 'A' then v.RoutingId ELSE null end AS RoutingNumber
,	case 
		when v.EFT='A' and v.AcctType='C' THEN 'Checking - Credit Entry'
		when v.EFT='A' and v.AcctType <> 'C' THEN 'Savings - Credit Entry'
		ELSE null
	end as TransactionType			--Checking - Credit Entry; Checking - Credit Prenotification;Savings - Credit Entry;Savings - Credit Prenotification
FROM 
	APVM v LEFT OUTER JOIN
	PREH e ON
		v.udEmployee=e.Employee
	AND v.udPRCo=e.PRCo 
WHERE 
	v.VendorGroup=1
--AND v.ActiveYN='Y'
AND	(v.udEmployee IS NOT NULL 
OR	v.udEmployeeYN='Y')
--ORDER BY 
--	v.NAME
GO
GRANT SELECT ON  [dbo].[mvwCreateACheckVendorExport] TO [public]
GRANT INSERT ON  [dbo].[mvwCreateACheckVendorExport] TO [public]
GRANT DELETE ON  [dbo].[mvwCreateACheckVendorExport] TO [public]
GRANT UPDATE ON  [dbo].[mvwCreateACheckVendorExport] TO [public]
GO
