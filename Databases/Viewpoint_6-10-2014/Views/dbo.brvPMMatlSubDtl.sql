SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE VIEW [dbo].[brvPMMatlSubDtl] 
/*********************************************** 
	PM Material And Sub created 6/1/05 CR 

	View performs two separate select statements for both the 
	Material and Subcontract information.  

	Reports:  PM Contract Drilldown 
	
	Changes:	9/20/2011	TK-08511 hh	- Added POSL number to 3rd select statement in PMOI/PMOL

*************************************************/ 
AS 

--Select Material information 
SELECT PMCo, 
       Project, 
       Seq, 
       RecordType, 
       PCOType=ISNULL(PCOType, ''), 
       PCO=ISNULL(PCO, ''), 
       PCOItem=ISNULL(PCOItem, ''), 
       [Description]=MtlDescription, 
       Units, 
       CostUM=UM, 
       UnitCost, 
       PMMF.Phase, 
       ACO, 
       ACOItem, 
       Amount, 
       Location, 
       CostType, 
       PMMF.PhaseGroup, 
       Code=MaterialCode, 
       [Type]='M', 
       POSL=PO, 
       POSLType='PO', 
       InterfaceDate, 
       SendFlag, 
       Vendor=Vendor, 
       VendorGrp=VendorGroup, 
       SLItem=NULL, 
       SLItemType=NULL, 
       SLAddon=NULL, 
       SLAddonPct=NULL, 
       SubCO=NULL, 
       WCRetgPct=NULL, 
       SMRetgPct=NULL, 
       POItem, 
       Quote, 
       MO, 
       MOItem, 
       RequisitionNum, 
       RQLine, 
       MaterialOption, 
       ApprovedDate=NULL, 
       PendingAmount=0, 
       Issue=NULL, 
       FixedAmountYN=NULL, 
       FixedAmount=0, 
       Approved=NULL, 
       EstHours=0, 
       HourCost=0, 
       EstUnits=0, 
       RevUM=NULL, 
       UnitPrice=0, 
       EstCost=0, 
       [Contract]=NULL, 
       ContractItem=NULL, 
       PCOACO=NULL, 
       PMOLNotes=NULL 
FROM   PMMF 
--LEFT JOIN JCJP 
--ON PMMF.PMCo = JCJP.JCCo AND PMMF.Project = JCJP.Job AND PMMF.PhaseGroup = JCJP.PhaseGroup AND PMMF.Phase = JCJP.Phase
WHERE  RecordType = 'C' 
UNION ALL 
--Select Subcontract information  
SELECT PMCo, 
       Project, 
       Seq, 
       RecordType, 
       PCOType=ISNULL(PCOType, ''), 
       PCO=ISNULL(PCO, ''), 
       PCOItem=ISNULL(PCOItem, ''), 
       [Description]=SLItemDescription, 
       Units, 
       UM, 
       UnitCost, 
       Phase, 
       ACO, 
       ACOItem, 
       Amount, 
       Location=NULL, 
       CostType, 
       PhaseGroup, 
       NULL, 
       [Type]='S', 
       POSL=SL, 
       POSLType='SL', 
       InterfaceDate, 
       SendFlag, 
       Vendor, 
       VendorGroup, 
       SLItem, 
       SLItemType, 
       SLAddon, 
       SLAddonPct, 
       SubCO, 
       WCRetgPct, 
       SMRetgPct, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL 
FROM   PMSL 
WHERE  RecordType = 'C' 
UNION ALL 
SELECT I.PMCo, 
       I.Project, 
       NULL, 
       NULL, 
       I.PCOType, 
       I.PCO, 
       I.PCOItem, 
       I.[Description], 
       I.Units, 
       L.UM, 
       L.UnitCost, 
       L.Phase, 
       I.ACO, 
       I.ACOItem, 
       I.ApprovedAmt, 
       NULL, 
       L.CostType, 
       L.PhaseGroup, 
       NULL, 
       [Type]='CO', 
       CASE
			WHEN L.PO IS NOT NULL THEN L.PO
			WHEN L.Subcontract IS NOT NULL THEN L.Subcontract
			ELSE NULL
	   END,		
       NULL, 
       L.InterfacedDate, 
       L.SendYN, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       NULL, 
       I.ApprovedDate, 
       I.PendingAmount, 
       I.Issue, 
       I.FixedAmountYN, 
       I.FixedAmount, 
       I.Approved, 
       L.EstHours, 
       L.HourCost, 
       L.EstUnits, 
       RevUM=L.UM, 
       I.UnitPrice, 
       L.EstCost, 
       I.[Contract], 
       I.ContractItem, 
       CASE 
         WHEN I.ACO IS NULL THEN 'PCO' 
         ELSE 'ACO' 
       END AS PCOACO, 
       L.Notes 
FROM   PMOI I 
       LEFT OUTER JOIN PMOL L 
         ON I.PMCo = L.PMCo 
            AND I.Project = L.Project 
            AND ISNULL(I.PCOType, '') = ISNULL(L.PCOType, '') 
            AND ISNULL(I.PCO, '') = ISNULL(L.PCO, '') 
            AND ISNULL(I.PCOItem, '') = ISNULL(L.PCOItem, '') 
            AND ISNULL(I.ACO, '') = ISNULL(L.ACO, '') 
            AND ISNULL(I.ACOItem, '') = ISNULL(L.ACOItem, '') 


GO
GRANT SELECT ON  [dbo].[brvPMMatlSubDtl] TO [public]
GRANT INSERT ON  [dbo].[brvPMMatlSubDtl] TO [public]
GRANT DELETE ON  [dbo].[brvPMMatlSubDtl] TO [public]
GRANT UPDATE ON  [dbo].[brvPMMatlSubDtl] TO [public]
GRANT SELECT ON  [dbo].[brvPMMatlSubDtl] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPMMatlSubDtl] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPMMatlSubDtl] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPMMatlSubDtl] TO [Viewpoint]
GO
