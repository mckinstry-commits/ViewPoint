USE [Viewpoint]
GO

/****** Object:  View [dbo].[mrvPOCurCostByVendor3]    Script Date: 6/1/2017 2:07:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[mrvPOCurCostByVendor3]      
     
/******************************  
*
* View is used by report PO Purchase Orders by Job (ReportID 751)
*
* Revision history
* Date		Author	Issue		Description
* 2/13/2008	CR		127005		Include the Tax in both CurCost and InvCost.
* 1/28/2010	MV		136500		Changed APTD TaxAmount to GSTtaxAmt.
* 9/21/2011	Czeslaw	V1-B-06463	Reworked query to select data from POItemLine instead of POIT; improved formatting.
*
*
*******************************/      
    
AS       
/***************************************
CREATED:	12/21/2014
PURPOSE:	MCK PO Purchase Orders by Job 
MODIFIED:	copy brvPOCurCostByVendor add udMCKPONumber from POHD
			add nolocks
TEST:		select * From mrvPOCurCostByVendor where POCo=1
grant all on mrvPOCurCostByVendor to public
UPDATE: ES 1/16/2015 - WITH (NOLOCK) hints removed because they are not effective in this case.  
	Parallelism is causing the table locks.  That is what must be addressed.
	POHD.Job IS NOT NULL was replaced with ISNULL(POIT.Job,'-1') = POIT.Job because it's much less expensive
	APTL.PO IS NOT NULL was replaced with ISNULL(APTL.PO, '-1') = APTL.PO... much better performance.
***************************************/
-- ========================================================================
-- Object Name: dbo].[mrvPOCurCostByVendor3
-- Author:		Ziebell, Jonathan
-- Create date: 05/24/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	05/24/2017 Initial Build
--				J.Ziebell   05/31/2017 New Fields And Logic
-- ========================================================================

SELECT     
POHD.POCo, --1
POHD.PO, --2
PODesc = (POHD.Description), --3
POHD.VendorGroup, --4
POHD.Vendor, --5
POHD.JCCo, --6
POHD.Status, --7
ItemDesc = (POIT.Description), --8
POItemLine.POItem, --POIT.POItem, --9
POItemLine.POItemLine, --10
POItemLine.Job, --POIT.Job, --11
POItemLine.SMWorkOrder,
POItemLine.TaxType, --POIT.TaxType, --12
POItemLine.PhaseGroup, --POIT.PhaseGroup, --13
POItemLine.Phase, --POIT.Phase, --14
POItemLine.JCCType,
POItemLine.PostToCo, --POIT.PostToCo, --15
SUM(POItemLine.CurCost) + SUM(POItemLine.CurTax) AS 'CurCost', --16
	--SUM(POIT.CurCost) + SUM(POIT.CurTax) AS 'CurCost', --16
SUM(POItemLine.CurTax) AS 'CurTax', --17
	--SUM(POIT.CurTax) AS 'CurTax', --17
SUM(POItemLine.InvCost) + SUM(POItemLine.InvTax) AS 'InvCost', --18
	--SUM(POIT.InvCost) + SUM(POIT.InvTax) AS 'InvCost', --18
SUM(POItemLine.InvTax) AS 'InvCostTax', --19
	--SUM(POIT.InvTax) AS 'InvCostTax', --19
SUM(POItemLine.JCCmtdTax) AS 'JCCmtdTax', --20
	--SUM(POIT.JCCmtdTax) AS 'JCCmtdTax', --20
0 AS 'APPaidAmt', --21
0 AS 'APTaxAmount', --22
0 AS 'APTotTaxAmount', --23
0 AS 'APJCCommittedVATtax', --24
SUM(POItemLine.JCRemCmtdTax) AS 'JCRemCmtdTax', --25
	--SUM(POIT.JCRemCmtdTax) AS 'JCRemCmtdTax', --25
RecType = 'PO' --26
,--12/21/2014 
POHD.udMCKPONumber
FROM	POHD --WITH (NOLOCK)
		INNER JOIN	POIT --WITH (NOLOCK)	
			ON POIT.POCo = POHD.POCo AND POIT.PO = POHD.PO
		INNER JOIN	POItemLine	--WITH (NOLOCK)
			ON POItemLine.POCo = POIT.POCo	AND POItemLine.PO = POIT.PO	AND	POItemLine.POItem = POIT.POItem
WHERE ISNULL(POItemLine.Job,'-1') = POItemLine.Job --IS NOT NULL
GROUP BY	POHD.POCo, POHD.PO, POHD.Description,
			POHD.VendorGroup, POHD.Vendor, POHD.JCCo, 
			POHD.Status, POIT.Description, POItemLine.POItem, 
			POItemLine.POItemLine, POItemLine.Job, POItemLine.TaxType, POItemLine.SMWorkOrder,  
			POItemLine.PhaseGroup, POItemLine.Phase, POItemLine.JCCType, POItemLine.PostToCo
			,--12/21/2014
			POHD.udMCKPONumber
         
UNION ALL      
    
SELECT     
APTL.APCo, --1
APTL.PO, --2
NULL AS 'PODesc', --3
APTH.VendorGroup, --4
APTH.Vendor, --5
APTL.JCCo, --6
NULL AS 'Status', --7
NULL AS 'ItemDesc', --8
APTL.POItem, --9
APTL.POItemLine, --10
APTL.Job, --11
APTL.SMWorkOrder,
APTL.TaxType, --12
APTL.PhaseGroup, --13
APTL.Phase, --14
APTL.JCCType, 
APTL.JCCo, --15
0 AS 'CurCost', --16
0 AS 'CurTax', --17
0 AS 'InvCost', --18
0 AS 'InvCostTax', --19
0 AS 'JCCmtdTax', --20
SUM(CASE WHEN APTD.Status > 2 THEN APTD.Amount ELSE 0 END) AS 'APPaidAmt', --21
SUM(CASE WHEN APTD.Status > 2 THEN APTD.GSTtaxAmt ELSE 0 END) AS 'APTaxAmount', --22
SUM(CASE WHEN APTD.Status > 2 THEN APTD.TotTaxAmount ELSE 0 END) AS 'APTotTaxAmount', --23
SUM(CASE WHEN APTD.Status > 2 THEN (APTD.TotTaxAmount - APTD.GSTtaxAmt) ELSE 0 END)AS 'APJCCommittedVATtax', --24
0 AS 'JCRemCmtdTax', --25
RecType = 'AP' --26
,--12/21/2014 
POHD.udMCKPONumber
FROM	APTL --WITH (NOLOCK)
		INNER JOIN 	APTD --WITH (NOLOCK)	
			ON APTL.APCo = APTD.APCo 
				AND APTL.Mth = APTD.Mth 
				AND APTL.APTrans = APTD.APTrans 
				AND APTL.APLine = APTD.APLine
		INNER JOIN 	APTH --WITH (NOLOCK)	
			ON APTL.APCo = APTH.APCo 
				AND APTL.Mth = APTH.Mth 
				AND APTL.APTrans = APTH.APTrans
		INNER JOIN POHD --WITH (NOLOCK) 
			ON POHD.POCo=APTL.APCo 
				and POHD.PO=APTL.PO
WHERE ISNULL(APTL.PO, '-1') = APTL.PO -- IS NOT NULL 
	AND ISNULL(APTL.Job, '-1') = APTL.Job --IS NOT NULL
GROUP BY	APTL.APCo, APTL.PO, APTH.VendorGroup, 
			APTH.Vendor, APTL.JCCo, APTL.POItem, 
			APTL.POItemLine, APTL.Job, APTL.SMWorkOrder, APTL.TaxType, 
			APTL.PhaseGroup, APTL.Phase, APTL.JCCType, APTL.JCCo
			,--12/21/2014
			POHD.udMCKPONumber

UNION ALL
SELECT     
POHD.POCo, --1
POHD.PO, --2
PODesc = (POHD.Description), --3
POHD.VendorGroup, --4
POHD.Vendor, --5
SMW.SMCo, --6
POHD.Status, --7
ItemDesc = (POIT.Description), --8
POItemLine.POItem, --POIT.POItem, --9
POItemLine.POItemLine, --10
SMW.Job, --POIT.Job, --11
POItemLine.SMWorkOrder,
POItemLine.TaxType, --POIT.TaxType, --12
POItemLine.SMPhaseGroup, --POIT.PhaseGroup, --13
POItemLine.SMPhase, --POIT.Phase, --14
POItemLine.SMJCCostType,
POItemLine.PostToCo, --POIT.PostToCo, --15
SUM(POItemLine.CurCost) + SUM(POItemLine.CurTax) AS 'CurCost', --16
	--SUM(POIT.CurCost) + SUM(POIT.CurTax) AS 'CurCost', --16
SUM(POItemLine.CurTax) AS 'CurTax', --17
	--SUM(POIT.CurTax) AS 'CurTax', --17
SUM(POItemLine.InvCost) + SUM(POItemLine.InvTax) AS 'InvCost', --18
	--SUM(POIT.InvCost) + SUM(POIT.InvTax) AS 'InvCost', --18
SUM(POItemLine.InvTax) AS 'InvCostTax', --19
	--SUM(POIT.InvTax) AS 'InvCostTax', --19
SUM(POItemLine.JCCmtdTax) AS 'JCCmtdTax', --20
	--SUM(POIT.JCCmtdTax) AS 'JCCmtdTax', --20
0 AS 'APPaidAmt', --21
0 AS 'APTaxAmount', --22
0 AS 'APTotTaxAmount', --23
0 AS 'APJCCommittedVATtax', --24
SUM(POItemLine.JCRemCmtdTax) AS 'JCRemCmtdTax', --25
	--SUM(POIT.JCRemCmtdTax) AS 'JCRemCmtdTax', --25
RecType = 'PO' --26
,--12/21/2014 
POHD.udMCKPONumber
FROM	POHD --WITH (NOLOCK)
		INNER JOIN	POIT --WITH (NOLOCK)	
			ON POIT.POCo = POHD.POCo AND POIT.PO = POHD.PO
		INNER JOIN	POItemLine	--WITH (NOLOCK)
			ON POItemLine.POCo = POIT.POCo	AND POItemLine.PO = POIT.PO	AND	POItemLine.POItem = POIT.POItem
		INNER JOIN SMWorkOrder SMW
			ON POItemLine.SMWorkOrder = SMW.WorkOrder
WHERE ISNULL(POItemLine.Job,'X') = 'X' --IS NULL
	AND ISNULL(SMW.Job,'-1') = SMW.Job --IS NOT NULL
--AND SMW.Job ='105205-001'   
GROUP BY	POHD.POCo, POHD.PO, POHD.Description,
			POHD.VendorGroup, POHD.Vendor, SMW.SMCo, 
			POHD.Status, POIT.Description, POItemLine.POItem, 
			POItemLine.POItemLine, SMW.Job, POItemLine.TaxType, POItemLine.SMWorkOrder,  
			POItemLine.SMPhaseGroup, POItemLine.SMPhase, POItemLine.SMJCCostType, POItemLine.PostToCo
			,--12/21/2014
			POHD.udMCKPONumber

UNION ALL      
    
SELECT     
APTL.APCo, --1
APTL.PO, --2
NULL AS 'PODesc', --3
APTH.VendorGroup, --4
APTH.Vendor, --5
SMW.SMCo, --6
NULL AS 'Status', --7
NULL AS 'ItemDesc', --8
APTL.POItem, --9
APTL.POItemLine, --10
SMW.Job, --11
APTL.SMWorkOrder,
APTL.TaxType, --12
APTL.SMPhaseGroup, --POIT.PhaseGroup, --13
APTL.SMPhase, --POIT.Phase, --14
APTL.SMJCCostType,
SMW.SMCo, --15
0 AS 'CurCost', --16
0 AS 'CurTax', --17
0 AS 'InvCost', --18
0 AS 'InvCostTax', --19
0 AS 'JCCmtdTax', --20
SUM(CASE WHEN APTD.Status > 2 THEN APTD.Amount ELSE 0 END) AS 'APPaidAmt', --21
SUM(CASE WHEN APTD.Status > 2 THEN APTD.GSTtaxAmt ELSE 0 END) AS 'APTaxAmount', --22
SUM(CASE WHEN APTD.Status > 2 THEN APTD.TotTaxAmount ELSE 0 END) AS 'APTotTaxAmount', --23
SUM(CASE WHEN APTD.Status > 2 THEN (APTD.TotTaxAmount - APTD.GSTtaxAmt) ELSE 0 END)AS 'APJCCommittedVATtax', --24
0 AS 'JCRemCmtdTax', --25
RecType = 'AP' --26
,--12/21/2014 
POHD.udMCKPONumber
FROM	APTL --WITH (NOLOCK)
		INNER JOIN 	APTD --WITH (NOLOCK)	
			ON APTL.APCo = APTD.APCo 
				AND APTL.Mth = APTD.Mth 
				AND APTL.APTrans = APTD.APTrans 
				AND APTL.APLine = APTD.APLine
		INNER JOIN 	APTH --WITH (NOLOCK)	
			ON APTL.APCo = APTH.APCo 
				AND APTL.Mth = APTH.Mth 
				AND APTL.APTrans = APTH.APTrans
		INNER JOIN POHD --WITH (NOLOCK) 
			ON POHD.POCo=APTL.APCo 
				and POHD.PO=APTL.PO
		INNER JOIN SMWorkOrder SMW
			ON APTL.SMWorkOrder = SMW.WorkOrder
--WHERE ISNULL(APTL.PO, '-1') = APTL.PO -- IS NOT NULL 
	--AND ISNULL(APTL.Job, '-1') = APTL.Job --IS NOT NULL
WHERE ISNULL(APTL.Job,'X') = 'X' --IS NULL
		AND ISNULL(SMW.Job,'-1') = SMW.Job --IS NOT NULL
		--AND SMW.Job ='105205-001'   
GROUP BY	APTL.APCo, APTL.PO, APTH.VendorGroup, 
			APTH.Vendor, APTL.JCCo,SMW.SMCo, APTL.POItem, 
			APTL.POItemLine, SMW.Job, APTL.SMWorkOrder, APTL.TaxType, 
			APTL.SMPhaseGroup, APTL.SMPhase, APTL.SMJCCostType, APTL.JCCo
			,--12/21/2014
			POHD.udMCKPONumber




GO

Grant SELECT ON dbo.mrvPOCurCostByVendor3 TO [MCKINSTRY\Viewpoint Users]

