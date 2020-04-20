SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
/*********************************************************************
 * Created By:	JH 1/22/10 - Initial version for customer 
 *				report PM Contract Analysis DD
 *
 * Modfied By:  #138909 HH 1/5/11 - No modification, created in VPDev640 
 *				for customer report PM Contract Analysis DD to 
 *				become Standard report in PM
 *
 *				TK-06503 HH 7/5/11 - Added Attachments information from 
 *				ACO and PCO forms, i.e. PMOH and PMOP
 *
 *	Used on PM Contract Analysis DD report
 *
 *********************************************************************/  
  
   
   
CREATE VIEW [dbo].[vrvPMChangeOrderCostDetail] AS
    

    
SELECT I.PMCo
		, I.Project
		, I.PCOType
		, I.PCO
		, I.PCOItem
		, ACO=isnull(I.ACO,'')
		, I.ACOItem
		, I.Description
		, I.ApprovedDate
		, RevUM=I.UM
		, I.Units
		, I.UnitPrice
		, I.PendingAmount
		,  I.ApprovedAmt
		,  I.Issue
		, I.FixedAmountYN
		, I.FixedAmount
		, L.PhaseGroup
		, L.Phase
		, L.CostType
		, I.Approved
		, L.SendYN
		, L.EstHours
		, L.EstUnits
		, CostUM=L.UM
		, L.UnitCost
		, L.EstCost
		, L.InterfacedDate
		, CASE WHEN I.ACO is null 
				THEN 'PCO' 
				ELSE 'ACO' 
		  END AS PCOACO
		, SLUM=null
		, SLUnits=0.000
		, SLUnitCost=0.000
		, SLAmt=0.00
		, SL=null
		, SLItem=0
		, Vendor=0
		, InterfaceDate='1/1/1950'
		, NULL AS AttachmentID
		, NULL AS AttachmentDescription
FROM PMOI I WITH(NOLOCK) 
	LEFT OUTER JOIN PMOL L WITH(NOLOCK) ON I.PMCo=L.PMCo AND I.Project=L.Project AND 
				ISNULL(I.PCOType,'') = ISNULL(L.PCOType,'') AND 
				ISNULL(I.PCO,'') = ISNULL(L.PCO,'') AND 
				ISNULL(I.PCOItem,'') = ISNULL(L.PCOItem,'') AND 
				ISNULL(I.ACO,'') = ISNULL(L.ACO, '') AND 
				ISNULL(I.ACOItem, '') = ISNULL(L.ACOItem, '')
    
UNION ALL

--Sub Exposure
SELECT s.PMCo
		, s.Project
		, s.PCOType
		, s.PCO
		, s.PCOItem
		, isnull(s.ACO,'')
		, s.ACOItem
		, I.Description
		, I.ApprovedDate
		, RevUM=null
		, Units=0.00
		, UnitCost=0.00
		, PendingAmount=0
		, ApprovedAmt=0
		, Issue=null
		, FixedAmountYN='N'
		, FixedAmount=0
		, s.PhaseGroup
		, s.Phase
		, s.CostType
		, Approved=null
		, SendYN=null
		, EstHours=0
		, EstUnits=0
		, CostUM=null
		, UnitCost=0
		, EstCost=0
		, s.InterfaceDate
		, 'SL', SLUM=s.UM
		, SLUnits=s.Units
		, SLUnitCost=s.UnitCost
		, SLAmt=Amount
		, s.SL
		, s.SLItem
		, s.Vendor
		, ISNULL(s.InterfaceDate,'1/1/1950')
		, NULL AS AttachmentID
		, NULL AS AttachmentDescription
FROM PMSL s WITH(NOLOCK) 
	JOIN PMOI I WITH(NOLOCK) ON I.PMCo=s.PMCo and I.Project=s.Project 
				AND ISNULL(I.PCOType,'') = ISNULL(s.PCOType,'') 
				AND ISNULL(I.PCO,'') = ISNULL(s.PCO,'') 
				AND ISNULL(I.PCOItem,'') = ISNULL(s.PCOItem,'')
				AND ISNULL(I.ACO,'') = ISNULL(s.ACO, '') 
				AND ISNULL(I.ACOItem, '') = ISNULL(s.ACOItem, '')
WHERE (s.PCO IS NOT NULL OR s.ACO IS NOT NULL)
	AND s.SL IS NOT NULL

UNION ALL

-- Attachments for ACOs
SELECT p.PMCo
		, p.Project
		, NULL AS PCOType
		, NULL AS PCO
		, NULL AS PCOItem
		, p.ACO
		, NULL AS ACOItem
		, NULL AS Description
		, NULL AS ApprovedDate
		, NULL AS RevUM
		, NULL AS Units
		, NULL AS UnitCost
		, NULL AS PendingAmount
		, NULL AS ApprovedAmt
		, NULL AS Issue
		, NULL AS FixedAmountYN
		, NULL AS FixedAmount
		, NULL AS PhaseGroup
		, NULL AS Phase
		, NULL AS CostType
		, NULL AS Approved
		, NULL AS SendYN
		, NULL AS EstHours
		, NULL AS EstUnits
		, NULL AS CostUM
		, NULL AS UnitCost
		, NULL AS EstCost
		, (SELECT MAX(InterfacedDate) FROM PMOI WHERE PMCo = p.PMCo AND Project = p.Project and ACO = p.ACO) AS InterfaceDate
		, 'ACO' AS PCOACO
		, NULL AS SLUM
		, NULL AS SLUnits
		, NULL AS SLUnitCost
		, NULL AS SLAmt
		, NULL AS SL
		, NULL AS SLItem
		, NULL AS Vendor
		, ISNULL((SELECT MAX(InterfacedDate) FROM PMOI WHERE PMCo = p.PMCo AND Project = p.Project and ACO = p.ACO),'1/1/1950') AS InterfaceDate
		, h.AttachmentID
		, h.[Description]
FROM HQAT h
INNER JOIN PMOH p 
	ON h.HQCo = p.PMCo and h.UniqueAttchID = p.UniqueAttchID

UNION ALL

-- Attachments for PCOs
SELECT p.PMCo
		, p.Project
		, p.PCOType
		, p.PCO AS PCO
		, NULL AS PCOItem
		, NULL AS ACO
		, NULL AS ACOItem
		, NULL AS Description
		, NULL AS ApprovedDate
		, NULL AS RevUM
		, NULL AS Units
		, NULL AS UnitCost
		, NULL AS PendingAmount
		, NULL AS ApprovedAmt
		, NULL AS Issue
		, NULL AS FixedAmountYN
		, NULL AS FixedAmount
		, NULL AS PhaseGroup
		, NULL AS Phase
		, NULL AS CostType
		, NULL AS Approved
		, NULL AS SendYN
		, NULL AS EstHours
		, NULL AS EstUnits
		, NULL AS CostUM
		, NULL AS UnitCost
		, NULL AS EstCost
		, (SELECT MAX(InterfacedDate) FROM PMOI WHERE PMCo = p.PMCo AND Project = p.Project AND PCO = p.PCO AND PCOType = p.PCOType) AS InterfaceDate
		, 'PCO' AS PCOACO
		, NULL AS SLUM
		, NULL AS SLUnits
		, NULL AS SLUnitCost
		, NULL AS SLAmt
		, NULL AS SL
		, NULL AS SLItem
		, NULL AS Vendor
		, ISNULL((SELECT MAX(InterfacedDate) FROM PMOI WHERE PMCo = p.PMCo AND Project = p.Project and PCO = p.PCO AND PCOType = p.PCOType),'1/1/1950') AS InterfaceDate
		, h.AttachmentID
		, h.[Description]
FROM HQAT h
INNER JOIN PMOP p 
	ON h.HQCo = p.PMCo and h.UniqueAttchID = p.UniqueAttchID




GO
GRANT SELECT ON  [dbo].[vrvPMChangeOrderCostDetail] TO [public]
GRANT INSERT ON  [dbo].[vrvPMChangeOrderCostDetail] TO [public]
GRANT DELETE ON  [dbo].[vrvPMChangeOrderCostDetail] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMChangeOrderCostDetail] TO [public]
GRANT SELECT ON  [dbo].[vrvPMChangeOrderCostDetail] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMChangeOrderCostDetail] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMChangeOrderCostDetail] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMChangeOrderCostDetail] TO [Viewpoint]
GO
