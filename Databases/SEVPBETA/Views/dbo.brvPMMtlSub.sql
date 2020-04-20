SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[brvPMMtlSub]  
/***********************************************   
*  PM Material And Sub Not Interfaced View    
*  Created 3/27/2002 AA   
*  
*  View performs two separate select statements for both the   
*  Material and Subcontract information.    
*  
*  Reports:  PM Mal & SubCo Not Interfaced   
*  
*  Changes: HH B-04852 - Added a SubCO/POCONum column
*						 Added a column for Approved:
*						 a. For Purchase Order Original items, Approved = POHDPM.Approved
*						 b. For Purchase Order Change Order items, Approved = PMPOCO.ReadyForAcctg view.
*						 c. For Subcontract Original items, Approved = SLHDPM.Approved
*						 d. For Subcontract Change Order items, Approved = PMSubcontractCO.ReadyForAcctg view.
*			HH TK-13981	 Added PMSL.SLItemType which provides information about (Regular, Change, BackCharge, AddOn)
*  
*************************************************/ 
As 

--PO/Change Order information
SELECT m.PMCo, 
       m.Project, 
       m.Seq, 
       m.RecordType, 
       Isnull(PCOType, '') AS PCOType, 
       Isnull(PCO, '')     AS PCO, 
       Isnull(PCOItem, '') AS PCOItem, 
       m.POCONum           AS POSubCO, 
       m.MtlDescription    AS [Description], 
       m.Units, 
       m.UM, 
       m.UnitCost, 
       m.Phase, 
       m.ACO, 
       m.ACOItem, 
       m.Amount, 
       m.Location, 
       m.CostType, 
       m.MaterialCode      AS Code, 
       'M'                 AS TYPE, 
       m.PO                AS POSL, 
       'PO'                AS POSLType, 
       m.InterfaceDate, 
       m.SendFlag, 
       CASE 
         WHEN m.POCONum IS NULL THEN po.Approved 
         ELSE poco.ReadyForAcctg 
       END                 AS Approved,
       NULL				   AS POSLItemType
FROM   PMMF m 
       LEFT OUTER JOIN POHDPM po 
         ON m.PMCo = po.PMCo 
            AND m.POCo = po.POCo 
            AND m.Project = po.Project 
            AND m.PO = po.PO 
       LEFT OUTER JOIN PMPOCO poco 
         ON m.PMCo = poco.PMCo 
            AND m.POCo = poco.POCo 
            AND m.POCONum = poco.POCONum 
            AND m.Project = poco.Project 
            AND m.PO = poco.PO 

UNION ALL 

--SL/Change Order information   
SELECT p.PMCo, 
       p.Project, 
       p.Seq, 
       p.RecordType, 
       Isnull(p.PCOType, '') AS PCOType, 
       Isnull(p.PCO, '')     AS PCO, 
       Isnull(p.PCOItem, '') AS PCOItem, 
       p.SubCO               AS POSubCO, 
       SLItemDescription     AS [Description], 
       p.Units, 
       p.UM, 
       p.UnitCost, 
       p.Phase, 
       p.ACO, 
       p.ACOItem, 
       p.Amount, 
       NULL                  AS Location, 
       p.CostType, 
       Phase                 AS Code, 
       'S'                   AS [TYPE], 
       p.SL                  AS POSL, 
       'SL'                  AS POSLType, 
       p.InterfaceDate, 
       p.SendFlag, 
       CASE 
         WHEN p.SubCO IS NULL THEN s.Approved 
         ELSE ps.ReadyForAcctg 
       END                   AS Approved,
       p.SLItemType			 AS POSLItemType
FROM   PMSL p 
       LEFT OUTER JOIN SLHDPM s 
         ON p.PMCo = s.PMCo 
            AND p.SLCo = s.SLCo 
            AND p.Project = s.Project 
            AND p.SL = s.SL 
       LEFT OUTER JOIN PMSubcontractCO ps 
         ON p.PMCo = ps.PMCo 
            AND p.SLCo = ps.SLCo 
            AND p.SubCO = ps.SubCO 
            AND p.Project = ps.Project 
            AND p.SL = ps.SL 


GO
GRANT SELECT ON  [dbo].[brvPMMtlSub] TO [public]
GRANT INSERT ON  [dbo].[brvPMMtlSub] TO [public]
GRANT DELETE ON  [dbo].[brvPMMtlSub] TO [public]
GRANT UPDATE ON  [dbo].[brvPMMtlSub] TO [public]
GO
