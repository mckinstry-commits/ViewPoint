SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************
  Purpose:  
	

  Maintenance Log:
	Coder	Date			Issue#				Description of Change
	DML		09 July 2012	145989 / B-08959	New
********************************************************************/

CREATE  view [dbo].[vrvPRLocalEITWithholding]

as 

select HQ.HQCo  
, HQ.Name  
, HQ.Address as HQAddress  
, HQ.Address2 as HQAddress2  
, HQ.City as HQCity  
, HQ.State as HQState  
, HQ.Zip as HQZip  
, HQ.FedTaxId  
, PR.PRCo  
, LI.LocalCode as LILocalCode  
, LI.Description as LIDescription
, LI.TaxEntity as LITaxEntity
, 'ResidentPSDCode' = LI.TaxEntity
, LI.TaxID as LITaxID  
, LI.State as LIState 
, LI.TaxDedn as LITaxDedn
, EH.SortName
, EH.Employee  
, EH.LastName  
, EH.FirstName  
, EH.MidName  
, EH.Address as EHAddress  
, EH.Address2 as EHAddress2  
, EH.City as EHCity  
, EH.State as EHState  
, EH.Zip as EHZip  
, EH.LocalCode as EHLocalCode  
, EH.SSN  
, EA.Mth  
, EA.EDLType  
, EA.EDLCode  
, EA.SubjectAmt  
, EA.Amount 

From HQCO HQ
Join PRCO PR on PR.PRCo=HQ.HQCo
join PREA EA on EA.PRCo=PR.PRCo 
join PREH EH on EH.PRCo=EA.PRCo and EH.Employee=EA.Employee   
join PRLI LI on LI.PRCo=PR.PRCo and LI.TaxDedn = EA.EDLCode
 
where EA.EDLType <> 'L'

GO
GRANT SELECT ON  [dbo].[vrvPRLocalEITWithholding] TO [public]
GRANT INSERT ON  [dbo].[vrvPRLocalEITWithholding] TO [public]
GRANT DELETE ON  [dbo].[vrvPRLocalEITWithholding] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRLocalEITWithholding] TO [public]
GRANT SELECT ON  [dbo].[vrvPRLocalEITWithholding] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPRLocalEITWithholding] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPRLocalEITWithholding] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPRLocalEITWithholding] TO [Viewpoint]
GO
