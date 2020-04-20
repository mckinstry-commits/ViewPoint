SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
    
CREATE view [dbo].[vrvPRAUBASReport]    
    
as    
--Added 08 March 2011 - DML - for BAS Report use only    
--Incorporates data from tables PRAUEmployerBAS, PRAUEmployerMaster, PRAUEmployerBASAmounts
    
    
Select    
PRAUEmployerMaster.PRCo     
, PRAUEmployerMaster.TaxYear    
, PRAUEmployerBAS.Seq as 'BASSeq'
, PRAUEmployerBASAmounts.Seq as 'BASAmtsSeq'  
, PRAUEmployerMaster.TaxFileNumber    
, PRAUEmployerMaster.ABN    
, PRAUEmployerMaster.CompanyName    
, PRAUEmployerMaster.Address    
, PRAUEmployerMaster.Address2    
, PRAUEmployerMaster.City    
, PRAUEmployerMaster.State    
, PRAUEmployerMaster.PostalCode    
, PRAUEmployerMaster.Country    
, PRAUEmployerBAS.ContactPerson    
, PRAUEmployerBAS.ContactPhone     
, PRAUEmployerMaster.ContactEmail    
, PRAUEmployerMaster.SignatureOfAuthPerson    
, PRAUEmployerBAS.Seq    
, PRAUEmployerBAS.FormDueOn    
, PRAUEmployerBAS.PaymentDueOn    
, PRAUEmployerBAS.GSTMethod    
, PRAUEmployerBAS.Signature    
, PRAUEmployerBAS.ReportDate    
, PRAUEmployerBAS.ReturnCompletedFormTo    
, PRAUEmployerBAS.Hours    
, PRAUEmployerBAS.Min    
, PRAUEmployerBAS.GSTStartDate    
, PRAUEmployerBAS.GSTEndDate    
, PRAUEmployerBAS.GSTOption    
, PRAUEmployerBAS.G1IncludesGST    
, PRAUEmployerBAS.G21    
, PRAUEmployerBAS.G22    
, PRAUEmployerBAS.G23    
, PRAUEmployerBAS.G24ReasonCode    
, PRAUEmployerBAS.PAYGWthStartDate    
, PRAUEmployerBAS.PAYGWthEndDate    
, PRAUEmployerBAS.PAYGWth4    
, PRAUEmployerBAS.PAYGWth3    
, PRAUEmployerBAS.PAYGITaxStartDate    
, PRAUEmployerBAS.PAYGITaxEndDate    
, PRAUEmployerBAS.PAYGITaxOption    
, PRAUEmployerBAS.PAYGITaxT7    
, PRAUEmployerBAS.PAYGITaxT8    
, PRAUEmployerBAS.PAYGITaxT9    
, PRAUEmployerBAS.PAYGITaxT1    
, PRAUEmployerBAS.PAYGITaxT2    
, PRAUEmployerBAS.PAYGITaxT3    
, PRAUEmployerBAS.PAYGITaxT11    
, PRAUEmployerBAS.PAYGITaxT4ReasonCode    
, PRAUEmployerBAS.FBTStartDate    
, PRAUEmployerBAS.FBTEndDate    
, PRAUEmployerBAS.FBTF1    
, PRAUEmployerBAS.FBTF2    
, PRAUEmployerBAS.FBTF3    
, PRAUEmployerBAS.FBTF4ReasonCode    
, PRAUEmployerBAS.Summ1C    
, PRAUEmployerBAS.Summ1E    
, PRAUEmployerBAS.Summ7C    
, PRAUEmployerBAS.Summ1D    
, PRAUEmployerBAS.Summ1F    
, PRAUEmployerBAS.Summ5B    
, PRAUEmployerBAS.Summ6B    
, PRAUEmployerBAS.Summ7D    
, PRAUEmployerBASAmounts.Item as 'BASAmtsItem'  
, PRAUEmployerBASAmounts.ItemDesc as 'BASAmtsItemDesc'  
, PRAUEmployerBASAmounts.SalesOrPurchAmt  
, PRAUEmployerBASAmounts.SalesOrPurchAmtGST  
, PRAUEmployerBASAmounts.GSTTaxAmt  
, PRAUEmployerBASAmounts.WithholdingAmt  
from PRAUEmployerBAS    
  
full outer join PRAUEmployerMaster on PRAUEmployerBAS.PRCo = PRAUEmployerMaster.PRCo 
	and PRAUEmployerBAS.TaxYear = PRAUEmployerMaster.TaxYear    
full outer join PRAUEmployerBASAmounts on PRAUEmployerBAS.PRCo = PRAUEmployerBASAmounts.PRCo 
	and PRAUEmployerBAS.TaxYear = PRAUEmployerBASAmounts.TaxYear  
	and PRAUEmployerBAS.Seq = PRAUEmployerBASAmounts.Seq  

GO
GRANT SELECT ON  [dbo].[vrvPRAUBASReport] TO [public]
GRANT INSERT ON  [dbo].[vrvPRAUBASReport] TO [public]
GRANT DELETE ON  [dbo].[vrvPRAUBASReport] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRAUBASReport] TO [public]
GO
