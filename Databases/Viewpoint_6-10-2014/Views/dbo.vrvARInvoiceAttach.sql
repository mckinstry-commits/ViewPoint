SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE View [dbo].[vrvARInvoiceAttach] as

/*==================================================================================          
    
Author:       
??      
    
Create date:       
11/30/2009       
    
Usage:
Created to allow the related report to show multiple attachments
    
Things to keep in mind regarding this report and proc:
    
Related reports: 
AR Customer Drilldown (ID: 90)     
    
Revision History          
Date  Author   Issue      Description 
07/09/2012	ScottAlvey	CL-NA / V1-B-10098: Add SM Work Order field to select reports.
This was originally done by Koslickistan on 10/24/2011 and I am updating the rev log
to reflect his changes.
  
==================================================================================*/   

Select Src= 'ARTL'
, ARTL.GLCo as Sort
, ARTL.ARCo
, 0 as SortTrans 
, ARTL.Mth 
, ARTL.ARTrans 
, ARTH.ARTransType
, ARTL.ARLine
, ARTL.RecType 
, ARTL.LineType 
, ARTL.Description AS LineDesc 
, ARTL.TaxCode
, ARTL.Amount
, ARTL.TaxAmount 
, ARTL.Retainage
, ARTL.DiscOffered
, ARTL.TaxDisc
, ARTL.DiscTaken
, ARTL.ApplyMth 
, ARTL.ApplyTrans
, ARTL.Contract
, ARTL.Item
, ARTL.Notes AS LineNotes
, ARTH.Customer
, ARTH.CustGroup
, ARTH.Invoice
, ARTH.CheckNo
, ARTH.TransDate
, ARTH.DueDate
, ARTH.CheckDate
, ARTH.Description as HeaderDesc
, ARTH.Notes as HeaderNotes
, ARTH.ExcludeFC
, ARTH.UniqueAttchID
, NULL as HQATAttachmentID
, NULL as HQATDescription
, NULL as HQATDocName
, NULL as HQATDocAttchYN
, ARTL.CustJob
, ARTL.CustPO
, ARTL.ECM
, ARTL.GLAcct
, ARTL.GLCo
, ARTL.INCo
, ARTL.JCCo
, ARTL.JobUnits
, ARTL.Loc
, ARTL.Material
, ARTL.MatlGroup
, ARTL.MatlUnits
, ARTL.RetgPct
, ARTL.TaxBasis
, ARTL.TaxGroup
, ARTL.UnitPrice
, ARTL.UM
, JCCM.Description as JCCMDescription 
, GLAC.Description as GLACDescription
, HQCOGL.Name as HQCOGLName
, HQCOIN.Name as HQCOINName
, HQCOJC.Name as HQCOJCName
, JCCI.Description as JCCIDescription
, INLM.Description as INLMDescription
, HQMT.Description as HQMTDescription
, HQGPM.Description as HQGPMMatDescription
, HQGPT.Description as HQGPTTaxDescription
, ARRT.Description as ARRTDescription
, HQTX.Description as HQTXDescription
, HQTX.TaxGroup as Grp
, ARTL.SMWorkCompletedID
--start B-10098 change
, SMWC.SMCo			AS SMCo
, SMWC.WorkOrder	AS SMWorkOrder
, HQCOSM.Name AS HQCOSMName
, SMWO.Description AS SMWODescription
--end B-10098 change



From ARTL
INNER JOIN ARTH with (nolock) 
	on ARTL.ARCo=ARTH.ARCo 
	and ARTL.Mth=ARTH.Mth 
	and ARTL.ARTrans=ARTH.ARTrans
--LEFT JOIN HQAT 
--	ON ARTH.UniqueAttchID = HQAT.UniqueAttchID 
LEFT OUTER JOIN ARRT 
	ON ARTL.ARCo = ARRT.ARCo 
	AND ARTL.RecType = ARRT.RecType 
INNER JOIN HQCO as HQCOTH 
	ON ARTL.ARCo = HQCOTH.HQCo
LEFT OUTER JOIN JCCM 
	ON ARTL.JCCo = JCCM.JCCo 
	AND ARTL.Contract = JCCM.Contract 
LEFT OUTER JOIN GLAC 
	ON ARTL.GLCo = GLAC.GLCo 
	AND ARTL.GLAcct = GLAC.GLAcct 
LEFT OUTER JOIN HQTX 
	ON ARTL.TaxGroup = HQTX.TaxGroup 
	AND ARTL.TaxCode = HQTX.TaxCode
LEFT OUTER JOIN HQGP as HQGPT 
	ON ARTL.TaxGroup = HQGPT.Grp 
LEFT OUTER JOIN JCCI 
	ON ARTL.JCCo = JCCI.JCCo 
	AND ARTL.Contract = JCCI.Contract 
	AND ARTL.Item = JCCI.Item 
LEFT OUTER JOIN INLM  
	ON ARTL.INCo = INLM.INCo 
	AND ARTL.Loc = INLM.Loc 
LEFT OUTER JOIN HQGP as HQGPM 
	ON ARTL.MatlGroup = HQGPM.Grp 
LEFT OUTER JOIN HQMT  
	ON ARTL.MatlGroup = HQMT.MatlGroup 
	AND ARTL.Material = HQMT.Material 
LEFT OUTER JOIN HQCO as HQCOGL 
	ON ARTL.GLCo = HQCOGL.HQCo 
LEFT OUTER JOIN HQCO as HQCOJC 
	ON ARTL.JCCo = HQCOJC.HQCo 
LEFT OUTER JOIN HQCO as HQCOIN 
	ON ARTL.INCo = HQCOIN.HQCo 
--start B-10098 change
LEFT OUTER JOIN SMWorkCompleted SMWC
	ON SMWC.SMWorkCompletedID = ARTL.SMWorkCompletedID
LEFT OUTER JOIN HQCO as HQCOSM 
	ON SMWC.SMCo = HQCOSM.HQCo 
LEFT OUTER JOIN SMWorkOrder SMWO
	ON SMWO.SMCo = SMWC.SMCo
	AND SMWO.WorkOrder = SMWC.WorkOrder
--end B-10098 change

Union All

Select Src= 'ARTH'
, NULL as Sort
, ARTH.ARCo
, 1 as SortTrans 
, ARTH.Mth
, ARTH.ARTrans
, ARTH.ARTransType
, ARTL.ARLine
, ARTL.RecType 
, ARTL.LineType 
, ARTL.Description as LineDesc
, ARTL.TaxCode
, NULL AS Amount
, NULL AS TaxAmount 
, NULL AS Retainage
, NULL AS DiscOffered
, NULL AS TaxDisc
, NULL AS DiscTaken
, ARTL.ApplyMth 
, ARTL.ApplyTrans
, ARTH.Contract
, ARTL.Item
, ARTL.Notes as LineNotes 
, ARTH.Customer
, ARTH.CustGroup
, ARTH.Invoice
, ARTH.CheckNo
, ARTH.TransDate
, ARTH.DueDate
, ARTH.CheckDate
, ARTH.Description as HeaderDesc
, ARTH.Notes as HeaderNotes
, ARTH.ExcludeFC
, ARTH.UniqueAttchID
, HQAT.AttachmentID as HQATAttachmentID
, HQAT.Description as HQATDescription
, HQAT.DocName as HQATDocName
, HQAT.DocAttchYN as DocAttch
, ARTL.CustJob
, ARTH.CustPO
, ARTL.ECM
, ARTL.GLAcct
, ARTL.GLCo
, ARTL.INCo
, ARTH.JCCo
, ARTL.JobUnits
, ARTL.Loc
, ARTL.Material
, ARTL.MatlGroup
, ARTL.MatlUnits
, ARTL.RetgPct
, NULL AS TaxBasis
, ARTL.TaxGroup
, ARTL.UnitPrice
, ARTL.UM
, JCCM.Description as JCCMDescription 
, GLAC.Description as GLACDescription
, HQCOGL.Name as HQCOGLName
, HQCOIN.Name as HQCOINName
, HQCOJC.Name as HQCOJCName
, JCCI.Description as JCCIDescription
, INLM.Description as INLMDescription
, HQMT.Description as HQMTDescription
, HQGPM.Description as HQGPMMatDescription
, HQGPT.Description as HQGPTTaxDescription
, ARRT.Description as ARRTDescription
, HQTX.Description as HQTXDescription
, HQTX.TaxGroup as Grp
, ARTL.SMWorkCompletedID
--start B-10098 change
, SMWC.SMCo			AS SMCo
, SMWC.WorkOrder	AS SMWorkOrder
, HQCOSM.Name AS HQCOSMName
, SMWO.Description AS SMWODescription
--end B-10098 change

From ARTH


INNER JOIN ARTL with (nolock) -- previously rem'd out
	on ARTH.ARCo=ARTL.ARCo -- previously rem'd out
	and ARTH.Mth=ARTL.Mth -- previously rem'd out
	and ARTH.ARTrans=ARTL.ARTrans-- previously rem'd out
INNER JOIN HQAT -- WAS outer 
	ON ARTH.UniqueAttchID = HQAT.UniqueAttchID 
LEFT OUTER JOIN ARRT 
	ON ARTL.ARCo = ARRT.ARCo 
	AND ARTL.RecType = ARRT.RecType 
INNER JOIN HQCO as HQCOTH 
	ON ARTL.ARCo = HQCOTH.HQCo
LEFT OUTER JOIN JCCM 
	ON ARTL.JCCo = JCCM.JCCo 
	AND ARTL.Contract = JCCM.Contract ---- Contract
LEFT OUTER JOIN GLAC 
	ON ARTL.GLCo = GLAC.GLCo 
	AND ARTL.GLAcct = GLAC.GLAcct 
LEFT OUTER JOIN HQTX 
	ON ARTL.TaxGroup = HQTX.TaxGroup 
	AND ARTL.TaxCode = HQTX.TaxCode
LEFT OUTER JOIN HQGP as HQGPT 
	ON ARTL.TaxGroup = HQGPT.Grp 
LEFT OUTER JOIN JCCI 
	ON ARTL.JCCo = JCCI.JCCo 
	AND ARTL.Contract = JCCI.Contract 
	AND ARTL.Item = JCCI.Item 
LEFT OUTER JOIN INLM  
	ON ARTL.INCo = INLM.INCo 
	AND ARTL.Loc = INLM.Loc 
LEFT OUTER JOIN HQGP as HQGPM 
	ON ARTL.MatlGroup = HQGPM.Grp 
LEFT OUTER JOIN HQMT  
	ON ARTL.MatlGroup = HQMT.MatlGroup 
	AND ARTL.Material = HQMT.Material 
LEFT OUTER JOIN HQCO as HQCOGL 
	ON ARTL.GLCo = HQCOGL.HQCo 
LEFT OUTER JOIN HQCO as HQCOJC 
	ON ARTL.JCCo = HQCOJC.HQCo 
LEFT OUTER JOIN HQCO as HQCOIN 
	ON ARTL.INCo = HQCOIN.HQCo
--start B-10098 change 
LEFT OUTER JOIN SMWorkCompleted SMWC
	ON SMWC.SMWorkCompletedID = ARTL.SMWorkCompletedID
LEFT OUTER JOIN HQCO as HQCOSM 
	ON SMWC.SMCo = HQCOSM.HQCo 
LEFT OUTER JOIN SMWorkOrder SMWO
	ON SMWO.SMCo = SMWC.SMCo
	AND SMWO.WorkOrder = SMWC.WorkOrder
--end B-10098 change












GO
GRANT SELECT ON  [dbo].[vrvARInvoiceAttach] TO [public]
GRANT INSERT ON  [dbo].[vrvARInvoiceAttach] TO [public]
GRANT DELETE ON  [dbo].[vrvARInvoiceAttach] TO [public]
GRANT UPDATE ON  [dbo].[vrvARInvoiceAttach] TO [public]
GRANT SELECT ON  [dbo].[vrvARInvoiceAttach] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvARInvoiceAttach] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvARInvoiceAttach] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvARInvoiceAttach] TO [Viewpoint]
GO
