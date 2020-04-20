 
alter VIEW mvwCreateACheckVendorExport  
AS  
  
SELECT  
 v.Vendor AS VendorID  
, v.Name AS VendorName  
, e.Address AS AddressLine1  
, e.Address2 AS AddressLine2  
, null AS AddressLine3  
, e.City AS City  
, e.State AS State  
, COALESCE(e.Country,'US') AS Country  
, e.Zip as PostalCode  
, e.Phone AS PhoneNumber  
, COALESCE(v.EMail,e.Email) AS EmailAddress  
, 0 AS UseEmail  
, null AS GLAcct  
, 'VP Employee Expense Vendor Record' AS Memo  
, cast(coalesce(v.udPRCo,'XX') AS varchar(10)) + '.' + cast(coalesce(v.udEmployee,'XXXXXX') AS varchar(10)) as CustomData1  
, null AS CustomData2  
, case v.EFT when 'A' then 0 else 1 end ExcludeFromACH_YN  
, case v.EFT when 'A' then v.BankAcct ELSE null end AS BankAccountNumber  
, case v.EFT when 'A' then 'PPD' else null end AS SECCode     --PPD, CCD, CTX or IAT  
, case v.EFT when 'A''' then v.RoutingId ELSE null end AS RoutingNumber  
, case   
  when v.EFT='A' and v.AcctType='C' THEN 'Checking - Credit Entry'  
  when v.EFT='A' and v.AcctType <> 'C' THEN 'Savings - Credit Entry'  
  ELSE null  
 end as TransactionType   --Checking - Credit Entry; Checking - Credit Prenotification;Savings - Credit Entry;Savings - Credit Prenotification  
FROM   
 APVM v LEFT OUTER JOIN  
 PREH e ON  
	v.udPRCo=e.PRCo  
 AND v.udEmployee=e.Employee  
WHERE   
 v.VendorGroup=1  
--AND v.ActiveYN='Y'  
AND (v.udEmployee IS NOT NULL   
OR v.udEmployeeYN='Y')  
--ORDER BY   
-- v.NAME  







	