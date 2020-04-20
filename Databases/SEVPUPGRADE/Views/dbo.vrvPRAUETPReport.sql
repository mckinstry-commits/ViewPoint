SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
CREATE view [dbo].[vrvPRAUETPReport]        
        
as        
--Added 01 April 2011 - DML - for ETP Report use only        
--Incorporates data from tables PRAUEmployerETP, PRAUEmployerMaster, PRAUEmployerETPAmounts    
        
        
Select    
PRAUEmployerMaster.PRCo    
, PRAUEmployerMaster.TaxYear    
, PRAUEmployerMaster.TaxFileNumber as 'CoTFN'    
, PRAUEmployerMaster.ABN    
, PRAUEmployerMaster.CompanyName    
, PRAUEmployerMaster.Address as 'CoAddress'    
, PRAUEmployerMaster.Address2 as 'CoAddress2'    
, PRAUEmployerMaster.City as 'CoCity'    
, PRAUEmployerMaster.State as 'CoState'    
, PRAUEmployerMaster.PostalCode as 'CoPostalcode'    
, PRAUEmployerMaster.Country    
--, PRAUEmployerMaster.ContactSurname as 'MstrSurname'    
--, PRAUEmployerMaster.ContactGivenName as 'MstrGivenName'    
--, PRAUEmployerMaster.ContactGivenName2 as 'MstrGivenName2'    
--, PRAUEmployerMaster.ContactPhone    
--, PRAUEmployerMaster.ContactEmail    
--, PRAUEmployerMaster.SignatureOfAuthPerson as 'MstrSig'    
, PRAUEmployerETP.SignatureOfAuthPerson as 'ETPSig'    
--, PRAUEmployerMaster.ReportDate as 'MstrDate'    
, PRAUEmployerETP.Date as 'ETPDate'    
, PRAUEmployerETP.BranchNbr    
, PRAUEmployerETP.LockETPAmounts    
, PRAUEmployeeETPAmounts.Employee    
, PRAUEmployeeETPAmounts.Seq    
, PRAUEmployeeETPAmounts.GivenName as 'EmpGivenName'    
, PRAUEmployeeETPAmounts.GivenName2 as 'EmpGivenName2'    
, PRAUEmployeeETPAmounts.Surname as 'EmpSurname'    
, PRAUEmployeeETPAmounts.Address as 'EmpAddress'    
, PRAUEmployeeETPAmounts.City as 'EmpCity'    
, PRAUEmployeeETPAmounts.State as 'EmpState'    
, PRAUEmployeeETPAmounts.Postcode as 'EmpPostcode'    
, PRAUEmployeeETPAmounts.DateofBirth    
, PRAUEmployeeETPAmounts.DateOfPayment    
, PRAUEmployeeETPAmounts.TaxFileNumber as 'EmpTFN'    
, PRAUEmployeeETPAmounts.TotalTaxWithheld    
, PRAUEmployeeETPAmounts.TaxableComponent    
, PRAUEmployeeETPAmounts.TaxFreeComponent    
, PRAUEmployeeETPAmounts.TransitionalPaymentYN    
, PRAUEmployeeETPAmounts.PartialPaymentYN    
, PRAUEmployeeETPAmounts.DeathBenefitYN    
, PRAUEmployeeETPAmounts.DeathBenefitType    
, PRAUEmployeeETPAmounts.Amended    
, PRAUEmployeeETPAmounts.AmendedATO    
, PRAUEmployeeETPAmounts.CompleteYN    
from PRAUEmployerETP        
      
full outer join PRAUEmployerMaster on PRAUEmployerETP.PRCo = PRAUEmployerMaster.PRCo     
 and PRAUEmployerETP.TaxYear = PRAUEmployerMaster.TaxYear        
full outer join PRAUEmployeeETPAmounts on PRAUEmployerETP.PRCo = PRAUEmployeeETPAmounts.PRCo     
 and PRAUEmployerETP.TaxYear = PRAUEmployeeETPAmounts.TaxYear      
GO
GRANT SELECT ON  [dbo].[vrvPRAUETPReport] TO [public]
GRANT INSERT ON  [dbo].[vrvPRAUETPReport] TO [public]
GRANT DELETE ON  [dbo].[vrvPRAUETPReport] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRAUETPReport] TO [public]
GO
