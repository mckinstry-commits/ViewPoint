SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


   
CREATE  view [dbo].[vrvPMCommitmentCO]
    
/**************************************************************************************
Created:		6/23/2011 HH - TK-05764

Description:	Lists all POs/SLs and each of their change orders by projects and vendors.
				
				     
 Usage:			Used by the PM Vendor Register Drilldown - ChangeOrderDD report 

**************************************************************************************/

AS

WITH vrvCommitmentCO ( PMCo, Project, VendorGroup, Vendor, DocType, DocSubType, DocID, [SubCO/POCONum], DocItem 
     , [Description], DocDate, InterfaceDate, OrigAmt, OrigAmtWithTax, ChangeAmt, ChangeAmtWithTax) 
     AS (
     /* PMMF: PO Originals and non-interfaced POCOs */
			SELECT	o.PMCo, 
					o.Project,
					o.VendorGroup,
					o.Vendor,
					'PO' AS DocType,
					CASE 
						WHEN o.RecordType = 'O' AND o.POCONum IS NULL THEN 'PO'
						ELSE 'POCO'
					END AS DocSubType,
					o.PO,
					o.POCONum,
					o.POItem,
					o.MtlDescription,
					CASE 
						WHEN o.RecordType = 'O' AND o.POCONum IS NULL THEN poh.OrderDate 
						WHEN o.RecordType  = 'C' OR o.POCONum IS NOT NULL THEN poi.DateApproved 
						ELSE NULL 
					END AS DocDate,
					o.InterfaceDate,
					CASE 
						WHEN o.RecordType = 'O' AND o.POCONum IS NULL THEN o.Amount 
						ELSE 0
					END AS OrigAmt,
					
					CASE
						WHEN o.RecordType = 'C' OR o.POCONum IS NOT NULL THEN 0
						WHEN o.TaxCode IS NULL THEN ISNULL(Amount,0)
						WHEN o.TaxType = 2 THEN ISNULL(Amount,0)
						ELSE ISNULL(Amount,0) + ISNULL(ROUND(ISNULL(o.Amount, 0) * ISNULL(dbo.vfHQTaxRate(o.TaxGroup, o.TaxCode, GetDate()),0),2),0)
					END AS OrigAmtWithTax,
					
					CASE 
						WHEN o.RecordType = 'C' OR o.POCONum IS NOT NULL THEN o.Amount 
						ELSE 0
					END AS ChangeAmt,
					
					CASE
						WHEN o.RecordType = 'O' AND o.POCONum IS NULL THEN 0
						WHEN o.TaxCode IS NULL THEN 0
						WHEN o.TaxType = 2 THEN 0
						ELSE ISNULL(Amount,0) + ISNULL(ROUND(ISNULL(o.Amount, 0) * ISNULL(dbo.vfHQTaxRate(o.TaxGroup, o.TaxCode, GetDate()),0),2),0)
					END AS ChangeAmtWithTax
					
         FROM   PMMF o 
                LEFT JOIN POHDPM poh 
                  ON poh.PMCo = o.PMCo 
                     AND poh.Project = o.Project 
                     AND poh.PO = o.PO 
                     AND poh.Vendor = o.Vendor 
                LEFT JOIN PMPOCO poi
				  ON poi.PMCo = o.PMCo
					 AND poi.PO = o.PO
					 AND poi.POCONum = o.POCONum
         WHERE  o.POCONum IS NULL OR (o.POCONum IS NOT NULL AND o.InterfaceDate IS NULL)
         
         UNION ALL 
         
         /* POCD: interfaced POCOs */
			SELECT o.POCo, 
                (SELECT Job FROM POHD WHERE o.POCo = POHD.POCo AND o.PO= POHD.PO), 
                (SELECT VendorGroup FROM POHD WHERE o.POCo = POHD.POCo AND o.PO= POHD.PO), 
				(SELECT Vendor FROM POHD WHERE o.POCo = POHD.POCo AND o.PO= POHD.PO), 
                'PO'AS DocType, 
                'POCO'AS DocSubType, 
                o.PO AS DocID,
                o.POCONum,
                o.POItem, 
                o.[Description],						
                o.ActDate AS DocDate,					
                o.PostedDate, 
                0 AS OrigAmt, 
                0 AS OrigAmtWithTax, 
                o.ChgTotCost AS ChangeAmt,
                o.ChgTotCost + o.ChgToTax AS ChangeAmt
         FROM   POCD o 

         UNION ALL
         
     /* PMSL: SL Originals and non-interfaced SubCOs */
         SELECT o.PMCo, 
                o.Project, 
                o.VendorGroup,
                o.Vendor, 
                'SL' AS DocType,
                CASE 
					WHEN o.RecordType = 'O' AND o.SubCO IS NULL THEN 'SL'
					ELSE 'SubCO'
				END AS DocSubType,
                o.SL,
                o.SubCO, 
                o.SLItem, 
                o.SLItemDescription, 
                CASE 
					WHEN o.RecordType = 'O' AND o.SubCO IS NULL THEN slh.OrigDate 
					WHEN o.RecordType = 'C' OR o.SubCO IS NOT NULL THEN poi.DateApproved 
					ELSE NULL 
                END AS DocDate, 
                o.InterfaceDate, 
                CASE 
					WHEN o.RecordType = 'O' AND o.SubCO IS NULL THEN o.Amount 
					ELSE 0
				END AS OrigAmt,
				
				CASE
					WHEN o.RecordType = 'C' OR o.SubCO IS NOT NULL THEN 0
					WHEN o.TaxCode IS NULL THEN ISNULL(Amount,0) 
					WHEN o.TaxType = 2 THEN ISNULL(Amount,0)
					ELSE ISNULL(Amount,0) + ISNULL(ROUND(ISNULL(o.Amount, 0) * ISNULL(dbo.vfHQTaxRate(o.TaxGroup, o.TaxCode, GetDate()),0),2),0)
				END AS OrigAmtWithTax,
				
				CASE 
					WHEN o.RecordType = 'C' OR o.SubCO IS NOT NULL THEN o.Amount 
					ELSE 0
				END AS ChangeAmt,
				
				CASE
					WHEN o.RecordType = 'O' AND o.SubCO IS NULL THEN 0
					WHEN o.TaxCode IS NULL THEN 0 
					WHEN o.TaxType = 2 THEN 0
					ELSE ISNULL(Amount,0) + ISNULL(ROUND(ISNULL(o.Amount, 0) * ISNULL(dbo.vfHQTaxRate(o.TaxGroup, o.TaxCode, GetDate()),0),2),0)
				END AS OrigAmtWithTax
               
         FROM   PMSL o 
                LEFT JOIN SLHDPM slh 
                  ON slh.PMCo = o.PMCo 
                     AND slh.Project = o.Project 
                     AND slh.SL = o.SL 
                     AND slh.Vendor = o.Vendor 
				LEFT JOIN vPMSubcontractCO poi
				  ON poi.SLCo = o.SLCo
					 AND poi.SL = o.SL
					 AND poi.SubCO = o.SubCO
         WHERE  o.SubCO IS NULL OR (o.SubCO IS NOT NULL AND o.InterfaceDate IS NULL)
                
		UNION ALL     
		
		/* SLCD: interfaced SubCOs */          
         SELECT o.SLCo, 
                (SELECT Job FROM SLHD WHERE o.SLCo = SLHD.SLCo AND o.SL= SLHD.SL), 
                (SELECT VendorGroup FROM SLHD WHERE o.SLCo = SLHD.SLCo AND o.SL= SLHD.SL), 
				(SELECT Vendor FROM SLHD WHERE o.SLCo = SLHD.SLCo AND o.SL= SLHD.SL), 
                'SL'AS DocType, 
                'SubCO'AS DocSubType, 
                o.SL AS DocID,
                o.SLChangeOrder,
                o.SLItem, 
                o.[Description],						
                o.ActDate AS DocDate,					
                o.PostedDate, 
                0 AS OrigAmt, 
                0 AS OrigAmtWithTax, 
                o.ChangeCurCost AS ChangeAmt,
                o.ChangeCurCost + o.ChgToTax AS ChangeAmtWithTax
         FROM   SLCD o        
                
)SELECT PMCo, Project, VendorGroup, Vendor, DocType, DocSubType, DocID, [SubCO/POCONum], DocItem 
     , [Description], DocDate, InterfaceDate, OrigAmt, ChangeAmt, OrigAmtWithTax, ChangeAmtWithTax
FROM   vrvCommitmentCO 

          
          
          
          
--select * from vrvPMCommitmentCO  where DocID like 'ddPO2tax%' 


GO
GRANT SELECT ON  [dbo].[vrvPMCommitmentCO] TO [public]
GRANT INSERT ON  [dbo].[vrvPMCommitmentCO] TO [public]
GRANT DELETE ON  [dbo].[vrvPMCommitmentCO] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMCommitmentCO] TO [public]
GRANT SELECT ON  [dbo].[vrvPMCommitmentCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMCommitmentCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMCommitmentCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMCommitmentCO] TO [Viewpoint]
GO
