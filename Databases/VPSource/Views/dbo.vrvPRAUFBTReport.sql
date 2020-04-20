SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[vrvPRAUFBTReport]  
  
as  
  
----Added 25 Feb 2011 - DML - for FBT Report use only  
--Incorporates data from tables PRAUEmployerFBT and PRAUEmployerMaster  
  
select PRAUEmployerFBT.PRCo as 'FBTPRCo'  
, PRAUEmployerMaster.PRCo as 'MSTRPRCo'  
, PRAUEmployerFBT.TaxYear as 'FBTTaxYear'  
, PRAUEmployerMaster.TaxYear as 'MSTRTaxYear'  
, PRAUEmployerMaster.TaxFileNumber   
, PRAUEmployerMaster.ABN   
, PRAUEmployerMaster.CompanyName  
, PRAUEmployerMaster.Address  
, PRAUEmployerMaster.Address2  
, PRAUEmployerMaster.City  
, PRAUEmployerMaster.State  
, PRAUEmployerMaster.PostalCode  
, PRAUEmployerMaster.Country  
, PRAUEmployerFBT.ContactSurname as 'FBTContactSurname'  
, PRAUEmployerMaster.ContactSurname as 'MSTRContactSurname'  
, PRAUEmployerFBT.ContactGivenName as 'FBTContactGivenName'  
, PRAUEmployerMaster.ContactGivenName as 'MSTRContactGivenName'  
, PRAUEmployerFBT.ContactGivenName2 as 'FBTContactGivenName2'  
, PRAUEmployerMaster.ContactGivenName2 as 'MSTRContactGivenName2'  
, PRAUEmployerFBT.ContactPhone as 'FBTContactPhone'  
, PRAUEmployerMaster.ContactPhone as 'MSTRContactPhone'  
, PRAUEmployerFBT.ContactEmail as 'FBTContactEmail'  
, PRAUEmployerMaster.ContactEmail as 'MSTRContactEmail'  
, PRAUEmployerFBT.NbrOfEmployeesRecFB  
, PRAUEmployerFBT.HoursToPrepare  
, PRAUEmployerFBT.LodgingFBTReturnYN  
, PRAUEmployerFBT.SignatureOfAuthPerson as 'FBTAuthPerson'  
, PRAUEmployerMaster.SignatureOfAuthPerson as 'MSTRAuthPerson'  
, PRAUEmployerFBT.ReportDate as 'FBTRptDate'  
, PRAUEmployerMaster.ReportDate as 'MSTRRptDate'  
, PRAUEmployerFBT.UniqueAttchID  
, PRAUEmployerFBT.Notes  
, PRAUEmployerFBT.KeyID  
, PRAUEmployerFBT.NumberA  
, PRAUEmployerFBT.NumberB  
, PRAUEmployerFBT.NumberC  
, PRAUEmployerFBT.NumberF  
, PRAUEmployerFBT.NumberG  
, PRAUEmployerFBT.BASAmount1  
, PRAUEmployerFBT.BASAmount2  
, PRAUEmployerFBT.BASAmount3  
, PRAUEmployerFBT.BASAmount4  
, PRAUEmployerFBT.LockFBTAmounts  
, PRAUEmployerFBT.CMAcct
, PRAUEmployerFBT.BSBNumber
, PRAUEmployerFBT.CMBankAcct
, PRAUEmployerFBT.CMAUAcctName
, PRAUEmployerFBT.CMCo
from PRAUEmployerFBT  
  
Inner join PRAUEmployerMaster  
 on PRAUEmployerMaster.PRCo = PRAUEmployerFBT.PRCo  
  and PRAUEmployerMaster.TaxYear = PRAUEmployerFBT.TaxYear  
  

GO
GRANT SELECT ON  [dbo].[vrvPRAUFBTReport] TO [public]
GRANT INSERT ON  [dbo].[vrvPRAUFBTReport] TO [public]
GRANT DELETE ON  [dbo].[vrvPRAUFBTReport] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRAUFBTReport] TO [public]
GO
