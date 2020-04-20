SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 CREATE          view [dbo].[brvPMChangeOrders] as
    
    /********************************
    PM Change Orders
    Created:		8/4/03 CR
    
    NOTE:  View may need to be modified when PM issue 138206 is fixed.  Where clause 
       starting on line 221 considered temporary.

	Modified:		TMS 02/24/2009 - Issue #131099: reformatted, changed Unit and 
							Unit Price from PMOI to Est Units and Unit Cost from PMOL
							(respectively).
					DH 2/15/10:  Issue #137216.  Added AddOn costs.
    
    This view links PMOI and PMOL together since PCOType, PCO and PCOItem may be NULL.
    Used on PMACONotInterfaced.rpt
    ********************************/

/***
 PMOA_Cost CTE: Combines AddOns to change order lines (PMOI).  
 Includes Addons only assigned to a cost type in PM Project Addons (PMPA).
 AddOns assigned to cost type need to be included as cost on various PM reports.
****/

With PMCOItems

as

(select   PMCo
		, Project
         /*Set null PCO data to empty string.  Allows PMOI data without PCO
           to be returned in last select statement in this view */
		, isnull(PCOType,'') as PCOType 
		, isnull(PCO,'') as PCO         
		, isnull(PCOItem,'') as PCOItem 
		, ACO
		, ACOItem
		, Description
		, ApprovedDate
		, InterfacedDate
		, UM
		, Units
		, UnitPrice
		, PendingAmount
		, ApprovedAmt
		, Issue
		, FixedAmountYN
		, FixedAmount
		, Approved
 from PMOI),

PMOA_Cost

as   


(Select	  PMOA.PMCo
		, PMOA.Project
		, PMOA.PCOType
		, PMOA.PCO
		, PMOA.PCOItem
		, PMOI.ACO
		, PMOI.ACOItem
		, PMOI.Approved
		, PMOA.AddOn
		, PMOA.Basis
		, PMOA.AddOnPercent
		, PMOA.AddOnAmount
		, PMOA.Status
		, PMOA.TotalType
		, PMOA.UniqueAttchID
		, PMOA.Include
		, PMOA.NetCalcLevel
		, PMOA.KeyID
		, PMOA.BasisCostType
		, PMOA.PhaseGroup
		, PMOA.RevACOItemId
		, PMOA.RevACOItemAmt
		, PMPA.Phase
		, PMPA.CostType

From PMOA

INNER JOIN	PMPA With (NoLock)
	ON  PMPA.PMCo = PMOA.PMCo 
	AND PMPA.Project = PMOA.Project 
	AND PMPA.AddOn = PMOA.AddOn
INNER JOIN	PMOI With (NoLock)
	ON	PMOI.PMCo = PMOA.PMCo
	AND PMOI.Project = PMOA.Project
	AND PMOI.PCOType = PMOA.PCOType
	AND PMOI.PCO = PMOA.PCO
	AND PMOI.PCOItem = PMOA.PCOItem
Where PMPA.CostType is not null )

SELECT 
	Src=1
,	I.PMCo
,	I.Project
,	I.PCOType
,	I.PCO  --5
,	I.PCOItem
,	I.ACO
,	I.ACOItem
,	I.UM
,	L.EstUnits AS Units  --10
,	L.UnitCost AS UnitPrice
,	I.PendingAmount
,	I.ApprovedAmt
,	I.Issue
,	I.FixedAmountYN --15
,	I.FixedAmount
,	I.Approved
,	L.PhaseGroup
,	L.Phase
,	L.CostType --20
,	'N' AS AddOn
,	L.SendYN
,	L.InterfacedDate
,	L.EstCost
,	Date= (case when L.InterfacedDate is not null then L.InterfacedDate else 
          (case when I.InterfacedDate is not null then I.InterfacedDate else '12/31/2050' end)end)
,	CostOrigUnits=0	--26
,	CostOrigCost=0		
,	PhaseDesc=J.Description

FROM 
	PMCOItems I With (NoLock)
		LEFT OUTER JOIN
	PMOL L With (NoLock)
		ON	I.PMCo=L.PMCo 
		AND I.Project				= L.Project 
		AND I.PCOType				= isnull(L.PCOType,'') 
		AND I.PCO					= isnull(L.PCO,'') 
		AND I.PCOItem				= isnull(L.PCOItem,'') 
		AND isnull(I.ACO,'')		= isnull(L.ACO, '') 
		AND isnull(I.ACOItem, '')	= isnull(L.ACOItem, '')
		LEFT OUTER JOIN 
	JCJP J With (NoLock) 
		ON	L.PMCo			= J.JCCo 
		AND L.Project		= J.Job 
		AND L.PhaseGroup	= J.PhaseGroup 
		AND L.Phase			= J.Phase

UNION ALL

/**
 Select statement returns AddOns for 
  1. Unapproved change orders  OR
  2. Approved change orders that were not updated to PMOL based on PMOA status.  
     PMOA Status = 'N' signifies Addons that were not updated to PMOL.

**/

SELECT 
	Src=1
,	A.PMCo
,	A.Project
,	A.PCOType
,	A.PCO  --5
,	A.PCOItem
,	A.ACO
,	A.ACOItem
,	I.UM
,	0 AS Units --10
,	0 AS UnitPrice
,	0 AS PendingAmount
,	0 AS ApprovedAmt
,	NULL AS Issue
,	'N' AS FixedAmountYN  --15
,	0 AS FixedAmount
,	A.Approved
,	A.PhaseGroup
,	A.Phase
,	A.CostType --20
,	'Y' AS AddOn
,	NULL AS SendYN
,	NULL AS InterfacedDate
,	A.AddOnAmount AS EstCost
,	isnull(I.InterfacedDate,'12/31/2050') AS Date
,	CostOrigUnits=0	--26
,	CostOrigCost=0		
,	PhaseDesc=J.Description

From PMOA_Cost A

JOIN PMOI I With (NoLock) ON
	I.PMCo=A.PMCo 
	AND I.Project	= A.Project 
	AND I.PCOType	= A.PCOType
	AND I.PCO		= A.PCO
	AND I.PCOItem	= A.PCOItem


LEFT JOIN	PMOL With (NoLock)
	ON  A.PMCo = PMOL.PMCo
	AND A.Project = PMOL.Project
	AND A.PCOType = PMOL.PCOType
	AND A.PCO = PMOL.PCO
	AND A.PCOItem = PMOL.PCOItem
	AND A.Phase = PMOL.Phase
	AND A.CostType = PMOL.CostType

LEFT OUTER JOIN 
	JCJP J With (NoLock) 
		ON	A.PMCo			= J.JCCo 
		AND A.Project		= J.Job 
		AND A.PhaseGroup	= J.PhaseGroup 
		AND A.Phase			= J.Phase

Where 
	(A.Approved = 'N'
	 OR (A.Approved = 'Y' 
		 and A.Status = 'N')
     )

--Temporary Fix:  Includes unapproved COs or approved COs where AddOn Phase does not exist in PMOL
/*Where 
	(A.Approved = 'N'

	 OR (A.Approved = 'Y'
		 and A.Phase is not null
		 and PMOL.Phase is null))*/

UNION ALL


 
SELECT 

	--Place Holders for UNION
	Src=2	,H.JCCo		,H.Job	,null	,null	
	,null	,null		,null	,UM		,0
	,0		,0			,0		,0		,null
	,0		,null

,	H.PhaseGroup
,	H.Phase
,	H.CostType
,	'N' AS AddOn
,	null
,	InterfaceDate
,	0
,	Date='12/31/2050'
,	OrigUnits
,	OrigCost
,	JCJP.Description

FROM
	JCCH H	With (NoLock) 
		LEFT OUTER JOIN 
	JCJP	With (NoLock) 
		ON	H.JCCo			= JCJP.JCCo 
		AND H.Job			= JCJP.Job 
		AND H.PhaseGroup	= JCJP.PhaseGroup 
		AND H.Phase			= JCJP.Phase
WHERE 
	H.SourceStatus NOT IN('J','I')


GO
GRANT SELECT ON  [dbo].[brvPMChangeOrders] TO [public]
GRANT INSERT ON  [dbo].[brvPMChangeOrders] TO [public]
GRANT DELETE ON  [dbo].[brvPMChangeOrders] TO [public]
GRANT UPDATE ON  [dbo].[brvPMChangeOrders] TO [public]
GO
