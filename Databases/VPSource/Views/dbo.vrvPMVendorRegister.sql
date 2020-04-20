SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



   
CREATE  VIEW [dbo].[vrvPMVendorRegister]
    
/**************************************************************************************
Created:		6/23/2011 HH - TK-05764

Description:	Lists all POs/SLs, their original, change, current, invoiced and 
				remaining amounts by projects and vendors.
				
				     
 Usage:			Used by the PM Vendor Register Drilldown report 

**************************************************************************************/

AS


WITH PMVendorRegister ( PMCo, Project, VendorGroup, Vendor, DocType, DocID, [Description], DocDate, OrigAmt, OrigAmtWithTax, ChgAmt, ChgAmtWithTax, InvAmt, InvAmtWithTax, ComplianceYN ) 
AS 
(
/* SLs Header*/
SELECT  sh.SLCo,
		sh.Job,
		sh.VendorGroup,
		sh.Vendor,
		'SL' AS DocType,
		sh.SL,
		sh.[Description],
		sh.OrigDate,								
		0 AS OrigAmt,
		0 AS OrigAmtWithTax, 
		0 AS ChgAmt, 
		0 AS ChgAmtWithTax, 
		0 AS InvAmt, 
		0 AS InvAmtWithTax,
		(SELECT Complied
					FROM brvSLCT_DistinctSL
					WHERE brvSLCT_DistinctSL.SLCo = sh.SLCo
					AND brvSLCT_DistinctSL.SL = sh.SL
		)
		AS ComplianceYN
FROM SLHD sh 
WHERE sh.SL IS NOT NULL

UNION ALL

/* SL's Originals: PMSL that are not interfaced and do not have a SubCO */
SELECT  sh.SLCo,
		sh.Project,
		sh.VendorGroup,
		sh.Vendor,
		'SL' AS DocType,
		sh.SL,
		(SELECT [Description] FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		(SELECT OrigDate FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL),
		ISNULL(Amount,0) AS OrigAmt,
		--ISNULL(Amount,0) AS OrigAmtWithTax, 
		CASE WHEN sh.TaxCode IS NULL 
				 THEN ISNULL(Amount,0)
			 WHEN sh.TaxType = 2 
				 THEN ISNULL(Amount,0)
			 ELSE ISNULL(Amount,0) + ISNULL(ROUND(ISNULL(sh.Amount, 0) * ISNULL(dbo.vfHQTaxRate(sh.TaxGroup, sh.TaxCode, GetDate()),0),2),0)
		END AS OrigAmtWithTax,
		0 AS ChgAmt, 
		0 AS ChgAmtWithTax, 
		0 AS InvAmt,
		0 AS InvAmtWithTax,
		(SELECT Complied
					FROM brvSLCT_DistinctSL
					WHERE brvSLCT_DistinctSL.SLCo = sh.SLCo
					AND brvSLCT_DistinctSL.SL = sh.SL
		)
		AS ComplianceYN
FROM PMSL sh		
WHERE sh.SL IS NOT NULL AND sh.InterfaceDate IS NULL AND sh.SubCO IS NULL

UNION ALL

/* SL's Originals: SLIT */
SELECT  sh.SLCo,
		sh.Job,
		(SELECT VendorGroup FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		(SELECT Vendor FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		'SL' AS DocType,
		sh.SL,
		(SELECT [Description] FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		(SELECT OrigDate FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL),
		ISNULL(OrigCost,0) AS OrigAmt,
		ISNULL(OrigCost,0) + ISNULL(OrigTax,0) AS OrigAmtWithTax, 
		0 AS ChgAmt, 
		0 AS ChgAmtWithTax, 
		0 AS InvAmt,
		0 AS InvAmtWithTax,
		(SELECT Complied
					FROM brvSLCT_DistinctSL
					WHERE brvSLCT_DistinctSL.SLCo = sh.SLCo
					AND brvSLCT_DistinctSL.SL = sh.SL
		)
		AS ComplianceYN
FROM SLIT sh		

UNION ALL 

/* SL's Changes: vrvPMSCOTotal (non-interfaced SubCOs) */
SELECT  sh.SLCo,
		(SELECT Job FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		(SELECT VendorGroup FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		(SELECT Vendor FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		'SL' AS DocType,
		sh.SL,
		(SELECT [Description] FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		(SELECT OrigDate FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL),
		0 AS OrigAmt,
		0 AS OrigAmtWithTax, 
		ISNULL(sh.PMSLAmtCurrent,0) - ISNULL(sh.PMSLTaxCurrent,0) AS ChgAmt, 
		ISNULL(sh.PMSLAmtCurrent,0) AS ChgAmtWithTax, 
		0 AS InvAmt,
		0 AS InvAmtWithTax,
		(SELECT Complied
					FROM brvSLCT_DistinctSL
					WHERE brvSLCT_DistinctSL.SLCo = sh.SLCo
					AND brvSLCT_DistinctSL.SL = sh.SL
		)
		AS ComplianceYN
FROM vrvPMSCOTotal sh		

UNION ALL

/* SL's Changes: SLCD (interfaced SubCOs) */
SELECT  sh.SLCo,
		(SELECT Job FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		(SELECT VendorGroup FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		(SELECT Vendor FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		'SL' AS DocType,
		sh.SL,
		(SELECT [Description] FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		(SELECT OrigDate FROM SLHD WHERE sh.SLCo = SLHD.SLCo AND sh.SL= SLHD.SL),
		0 AS OrigAmt,
		0 AS OrigAmtWithTax, 
		ISNULL(sh.ChangeCurCost,0) AS ChgAmt, 
		ISNULL(sh.ChangeCurCost,0) + ISNULL(sh.ChgToTax,0) AS ChgAmtWithTax, 
		0 AS InvAmt,
		0 AS InvAmtWithTax,
		(SELECT Complied
					FROM brvSLCT_DistinctSL
					WHERE brvSLCT_DistinctSL.SLCo = sh.SLCo
					AND brvSLCT_DistinctSL.SL = sh.SL
		)
		AS ComplianceYN
FROM SLCD sh		

UNION ALL
/* SL Invoiced: APTD/APTL */
SELECT  sh.JCCo,
		sh.Job, 
		(SELECT VendorGroup FROM SLHD WHERE sh.JCCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		(SELECT Vendor FROM SLHD WHERE sh.JCCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		'SL' AS DocType,
		sh.SL,
		(SELECT [Description] FROM SLHD WHERE sh.JCCo = SLHD.SLCo AND sh.SL= SLHD.SL), 
		(SELECT OrigDate FROM SLHD WHERE sh.JCCo = SLHD.SLCo AND sh.SL= SLHD.SL),
		0 AS OrigAmt,
		0 AS OrigAmtWithTax, 
		0 AS ChgAmt, 
		0 AS ChgAmtWithTax, 
		CASE
			WHEN sh.TaxType in (1,3) THEN a.Amount - a.TotTaxAmount
			ELSE a.Amount 
		END AS InvAmt,
		CASE
			WHEN sh.TaxType in (1,3) THEN a.Amount
			ELSE a.Amount 
		END AS InvAmtWithTax,
		(SELECT Complied
					FROM brvSLCT_DistinctSL
					WHERE brvSLCT_DistinctSL.SLCo = sh.JCCo
					AND brvSLCT_DistinctSL.SL = sh.SL
		)
		AS ComplianceYN
FROM APTL sh		
LEFT OUTER JOIN APTD a ON	sh.APCo = a.APCo 
							AND sh.Mth = a.Mth 
							AND sh.APTrans = a.APTrans 
							AND sh.APLine = a.APLine
WHERE sh.SL IS NOT NULL and sh.Job IS NOT NULL

/* --------------------- */
UNION ALL

/* POs Header*/
SELECT  ph.POCo,
		ph.Job,
		ph.VendorGroup,
		ph.Vendor,
		'PO' AS DocType,
		ph.PO,
		ph.[Description],
		ph.OrderDate,								
		0 AS OrigAmt,
		0 AS OrigAmtWithTax, 
		0 AS ChgAmt, 
		0 AS ChgAmtWithTax, 
		0 AS InvAmt, 
		0 AS InvAmtWithTax,
		(SELECT Complied
					FROM brvPOCT_DistinctPO
					WHERE brvPOCT_DistinctPO.POCo = ph.POCo
					AND brvPOCT_DistinctPO.PO = ph.PO
		)
		AS ComplianceYN
FROM POHD ph 
WHERE ph.PO IS NOT NULL

UNION ALL

/* PO's Originals: PMMF that are not interfaced and do not have a POCONum */
SELECT  ph.PMCo,
		ph.Project,
		ph.VendorGroup,
		ph.Vendor,
		'PO' AS DocType,
		ph.PO,
		(SELECT [Description] FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO), 
		(SELECT OrderDate FROM POHD WHERE ph.PMCo = POHD.POCo AND ph.PO= POHD.PO),
		ISNULL(Amount,0) AS OrigAmt,
		CASE WHEN ph.TaxCode IS NULL 
				 THEN ISNULL(Amount,0)
			 WHEN ph.TaxType = 2 
				 THEN ISNULL(Amount,0)
			 ELSE 
				 ISNULL(Amount,0) + ISNULL(ROUND(ISNULL(ph.Amount, 0) * ISNULL(dbo.vfHQTaxRate(ph.TaxGroup, ph.TaxCode, GetDate()),0),2),0)
		END AS OrigAmtWithTax,
		0 AS ChgAmt, 
		0 AS ChgAmtWithTax, 
		0 AS InvAmt,
		0 AS InvAmtWithTax,
		(SELECT Complied
					FROM brvPOCT_DistinctPO
					WHERE brvPOCT_DistinctPO.POCo = ph.POCo
					AND brvPOCT_DistinctPO.PO = ph.PO
		)
		AS ComplianceYN
FROM PMMF ph		
WHERE ph.PO IS NOT NULL AND ph.InterfaceDate IS NULL AND ph.POCONum IS NULL

UNION ALL

/* PO's Originals: POIT */
SELECT  ph.POCo,
		ph.Job,
		(SELECT VendorGroup FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO),
		(SELECT Vendor FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO), 
		'PO' AS DocType,
		ph.PO,
		(SELECT [Description] FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO), 
		(SELECT OrderDate FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO),
		ISNULL(OrigCost,0) AS OrigAmt,
		ISNULL(OrigCost,0) + ISNULL(OrigTax,0) AS OrigAmtWithTax, 
		0 AS ChgAmt, 
		0 AS ChgAmtWithTax, 
		0 AS InvAmt,
		0 AS InvAmtWithTax,
		(SELECT Complied
					FROM brvPOCT_DistinctPO
					WHERE brvPOCT_DistinctPO.POCo = ph.POCo
					AND brvPOCT_DistinctPO.PO = ph.PO
		)
		AS ComplianceYN
FROM POIT ph		

UNION ALL 

/* PO's Changes: vrvPMPOCOTotal (non-interfaced POCOs) */
SELECT  ph.POCo,
		(SELECT Job FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO), 
		(SELECT VendorGroup FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO), 
		(SELECT Vendor FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO), 
		'PO' AS DocType,
		ph.PO,
		(SELECT [Description] FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO), 
		(SELECT OrderDate FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO),
		0 AS OrigAmt,
		0 AS OrigAmtWithTax, 
		ISNULL(ph.PMMFAmtCurrent,0) - ISNULL(ph.PMMFTaxCurrent,0) AS ChgAmt, 
		ISNULL(ph.PMMFAmtCurrent,0) AS ChgAmtWithTax, 
		0 AS InvAmt,
		0 AS InvAmtWithTax,
		(SELECT Complied
					FROM brvPOCT_DistinctPO
					WHERE brvPOCT_DistinctPO.POCo = ph.POCo
					AND brvPOCT_DistinctPO.PO = ph.PO
		)
		AS ComplianceYN
FROM vrvPMPOCOTotal ph		

UNION

/* PO's Changes: POCD (interfaced POCOs) */
SELECT  ph.POCo,
		(SELECT Job FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO), 
		(SELECT VendorGroup FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO), 
		(SELECT Vendor FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO), 
		'PO' AS DocType,
		ph.PO,
		(SELECT [Description] FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO), 
		(SELECT OrderDate FROM POHD WHERE ph.POCo = POHD.POCo AND ph.PO= POHD.PO),
		0 AS OrigAmt,
		0 AS OrigAmtWithTax, 
		ISNULL(ph.ChgTotCost,0) AS ChgAmt, 
		ISNULL(ph.ChgTotCost,0) + ISNULL(ph.ChgToTax,0) AS ChgAmtWithTax, 
		0 AS InvAmt,
		0 AS InvAmtWithTax,
		(SELECT Complied
					FROM brvPOCT_DistinctPO
					WHERE brvPOCT_DistinctPO.POCo = ph.POCo
					AND brvPOCT_DistinctPO.PO = ph.PO
		)
		AS ComplianceYN
FROM POCD ph
	
UNION ALL
/* PO Invoiced: APTD/APTL */
SELECT  ph.JCCo,
		ph.Job, 
		(SELECT VendorGroup FROM POHD WHERE ph.JCCo = POHD.POCo AND ph.PO= POHD.PO), 
		(SELECT Vendor FROM POHD WHERE ph.JCCo = POHD.POCo AND ph.PO= POHD.PO), 
		'PO' AS DocType,
		ph.PO,
		(SELECT [Description] FROM POHD WHERE ph.JCCo = POHD.POCo AND ph.PO= POHD.PO), 
		(SELECT OrderDate FROM POHD WHERE ph.JCCo = POHD.POCo AND ph.PO= POHD.PO),
		0 AS OrigAmt,
		0 AS OrigAmtWithTax, 
		0 AS ChgAmt, 
		0 AS ChgAmtWithTax, 
		CASE
			WHEN ph.TaxType in (1,3) THEN a.Amount - a.TotTaxAmount
			ELSE a.Amount 
		END AS InvAmt,
		CASE
			WHEN ph.TaxType in (1,3) THEN a.Amount
			ELSE a.Amount 
		END AS InvAmtWithTax,
		(SELECT Complied
					FROM brvPOCT_DistinctPO
					WHERE brvPOCT_DistinctPO.POCo = ph.JCCo
					AND brvPOCT_DistinctPO.PO = ph.PO
		)
		AS ComplianceYN
FROM APTL ph		
LEFT OUTER JOIN APTD a ON	ph.APCo = a.APCo 
							AND ph.Mth = a.Mth 
							AND ph.APTrans = a.APTrans 
							AND ph.APLine = a.APLine
WHERE ph.PO IS NOT NULL and ph.Job IS NOT NULL


)
SELECT		PMCo, 
			Project, 
			VendorGroup, 
			Vendor, 
			DocType, 
			DocID, 
			[Description], 
			DocDate, 
			SUM(OrigAmt) AS OrigAmt, 
			SUM(ChgAmt) AS ChgAmt, 
			SUM(OrigAmt) + SUM(ChgAmt) AS CurrAmt,
			SUM(OrigAmtWithTax) AS OrigAmtWithTax, 
			SUM(ChgAmtWithTax) AS ChgAmtWithTax, 
			SUM(OrigAmtWithTax) + SUM(ChgAmtWithTax) AS CurrAmtWithTax,
			SUM(InvAmt) AS InvAmt, 
			SUM(InvAmtWithTax) AS InvAmtWithTax,
			SUM(OrigAmt) + SUM(ChgAmt) - SUM(InvAmt) AS RemAmt,
			SUM(OrigAmtWithTax) + SUM(ChgAmtWithTax) - SUM(InvAmt) AS RemAmtWithTax,
			ComplianceYN
FROM PMVendorRegister
WHERE Project IS NOT NULL AND VendorGroup IS NOT NULL AND Vendor IS NOT NULL
GROUP BY PMCo, Project, VendorGroup, Vendor, DocType, DocID, [Description], DocDate, ComplianceYN



GO
GRANT SELECT ON  [dbo].[vrvPMVendorRegister] TO [public]
GRANT INSERT ON  [dbo].[vrvPMVendorRegister] TO [public]
GRANT DELETE ON  [dbo].[vrvPMVendorRegister] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMVendorRegister] TO [public]
GO
