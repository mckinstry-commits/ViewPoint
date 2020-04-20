SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  View [dbo].[vrvARInvoiceDetails]    Script Date: 04/29/2009 13:02:18 ******/

CREATE View [dbo].[vrvARInvoiceDetails] as
/*********
Created 15Oct2008 to replace vrvARInvoices in ARCustDrill.rpt (needed more detail)
Issue # 130150  DML
Altered 19Nov2009 to pull HQAT out for external linking [AR Cust DD] instead.  DML
***********/


SELECT    
ARTL.GLCo as Sort,
ARTL.ARCo, 
ARTL.Mth, 
ARTL.ARTrans, 
ARTH.ARTransType,
ARTL.ARLine,
ARTL.RecType, 
ARTL.LineType, 
ARTL.Description AS LineDesc, 
ARTL.TaxCode,
ARTL.Amount,
ARTL.TaxAmount, 
ARTL.Retainage,
ARTL.DiscOffered,
ARTL.TaxDisc,
ARTL.DiscTaken,
ARTL.ApplyMth, 
ARTL.ApplyTrans,
ARTL.Contract,
ARTL.Item,
ARTL.Notes AS LineNotes,
ARTH.CustGroup, 
ARTH.Customer, 
ARTH.Invoice, 
ARTH.CheckNo,
ARTH.TransDate, 
ARTH.DueDate, 
ARTH.CheckDate, 
ARTH.Description AS HeaderDesc, 
ARTH.Notes AS HeaderNotes, 
ARTH.ExcludeFC,
ARTH.UniqueAttchID, 
--HQAT.AttachmentID, 
--HQAT.Description AS HQATDescription,
--HQAT.DocName,
ARTL.CustJob,
ARTL.CustPO,
ARTL.ECM,
ARTL.GLAcct,
ARTL.GLCo,
ARTL.INCo,
ARTL.JCCo,
ARTL.JobUnits,
ARTL.Loc,
ARTL.Material,
ARTL.MatlGroup,
ARTL.MatlUnits,
ARTL.RetgPct,
ARTL.TaxBasis,
ARTL.TaxGroup,
ARTL.UnitPrice,
ARTL.UM,
JCCM.Description as JCCMDescription,
GLAC.Description as GLACDescription,
HQCOGL.Name as HQCOGLName, 
HQCOIN.Name as HQINName,
HQCOJC.Name as HQCOJCName,
JCCI.Description as JCCIDescription,
INLM.Description as INLMDescription,
HQMT.Description as HQMTDescription,
HQGPM.Description as HQGPMatDescription,
HQGPT.Description as HQGPTaxDescription,
ARRT.Description as ARRTDescription,
HQTX.Description as HQTXDescription,
HQGPT.Grp
FROM 
ARTL AS ARTL INNER JOIN 
ARTH AS ARTH ON ARTL.ARCo = ARTH.ARCo AND ARTL.Mth = ARTH.Mth AND ARTL.ARTrans = ARTH.ARTrans left JOIN
--HQAT ON ARTH.UniqueAttchID = HQAT.UniqueAttchID LEFT OUTER JOIN
ARRT ON ARTL.ARCo = ARRT.ARCo AND ARTL.RecType = ARRT.RecType INNER JOIN
HQCO as HQCOTH ON ARTL.ARCo = HQCOTH.HQCo LEFT OUTER JOIN
JCCM ON ARTL.JCCo = JCCM.JCCo AND ARTL.Contract = JCCM.Contract LEFT OUTER JOIN
GLAC ON ARTL.GLCo = GLAC.GLCo AND ARTL.GLAcct = GLAC.GLAcct LEFT OUTER JOIN
HQTX ON ARTL.TaxGroup = HQTX.TaxGroup AND ARTL.TaxCode = HQTX.TaxCode LEFT OUTER JOIN
HQGP as HQGPT ON ARTL.TaxGroup = HQGPT.Grp LEFT OUTER JOIN
JCCI ON ARTL.JCCo = JCCI.JCCo AND ARTL.Contract = JCCI.Contract AND ARTL.Item = JCCI.Item LEFT OUTER JOIN
INLM  ON ARTL.INCo = INLM.INCo AND ARTL.Loc = INLM.Loc LEFT OUTER JOIN
HQGP as HQGPM ON ARTL.MatlGroup = HQGPM.Grp LEFT OUTER JOIN
HQMT  ON ARTL.MatlGroup = HQMT.MatlGroup AND ARTL.Material = HQMT.Material LEFT OUTER JOIN
HQCO as HQCOGL ON ARTL.GLCo = HQCOGL.HQCo LEFT OUTER JOIN
HQCO as HQCOJC ON ARTL.JCCo = HQCOJC.HQCo LEFT OUTER JOIN
HQCO as HQCOIN ON ARTL.INCo = HQCOIN.HQCo INNER JOIN
ARCM  ON ARTH.CustGroup = ARCM.CustGroup AND ARTH.Customer = ARCM.Customer
--where ARTL.ARCo = 1
--and ARTH.Customer = 99
--and ARTH.Invoice = 20000




GO
GRANT SELECT ON  [dbo].[vrvARInvoiceDetails] TO [public]
GRANT INSERT ON  [dbo].[vrvARInvoiceDetails] TO [public]
GRANT DELETE ON  [dbo].[vrvARInvoiceDetails] TO [public]
GRANT UPDATE ON  [dbo].[vrvARInvoiceDetails] TO [public]
GRANT SELECT ON  [dbo].[vrvARInvoiceDetails] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvARInvoiceDetails] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvARInvoiceDetails] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvARInvoiceDetails] TO [Viewpoint]
GO
