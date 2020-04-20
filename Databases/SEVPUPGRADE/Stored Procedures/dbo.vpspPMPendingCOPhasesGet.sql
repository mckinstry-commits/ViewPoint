SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMPendingCOPhasesGet]
/************************************************************
* CREATED:		1/10/06		RWH
* MODIFIED:		2/14/06		chs
* MODIFIED:		6/7/07		CHS
* MODIFIED:		12/11/07	CHS
*
* USAGE:
*   Returns PM Approved Change Orders Item Phase
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, PCO, PCOItem, PCOType, DocType
*
************************************************************/
(@JCCo bCompany, @Job bJob, @PCO bPCO, @PCOItem bPCOItem, @PCOType bDocType,
	@KeyID int = Null )

AS

SET NOCOUNT ON;

Select l.KeyID, l.PMCo, l.Project, l.PCO, 
	u.Description as 'Pending CO Description', l.PCO,
	l.PCOItem, 

	i.Description as 'PCOItemDescription',

	l.PCOType, t.Description as 'PCO Type Description',
	l.ACO, l.ACOItem, i.Description as 'ACO Item Description', 
	l.PhaseGroup, l.Phase, 	p.Description as 'PhaseDescription', 
	l.CostType, ct.Description as 'CostTypeDescription', 
	l.EstUnits, l.UM, l.UnitHours, l.EstHours, l.HourCost, 
	l.UnitCost, l.ECM, l.EstCost, l.SendYN, l.InterfacedDate, 
	l.Notes, l.UniqueAttchID,
	c.BillFlag, c.ItemUnitFlag, c.PhaseUnitFlag, c.ActiveYN,
	
	case l.SendYN 
		when 'Y' then 'Yes' 
		when 'N' then 'No' 
		else '' 
		end as 'SendDescription',

	case c.ActiveYN 
		when 'Y' then 'Yes' 
		when 'N' then 'No' 
		else '' 
		end as 'ActiveDescription',

	case c.ItemUnitFlag 
		when 'Y' then 'Yes' 
		when 'N' then 'No' 
		else '' 
		end as 'ItemUnitsDescription',

	case c.PhaseUnitFlag 
		when 'Y' then 'Yes' 
		when 'N' then 'No' 
		else '' 
		end as 'PhaseUnitsDescription',
		
	case c.BillFlag 
		when 'Y' then 'Units & Cost' 
		when 'C' then 'Cost' 
		when 'N' then 'Neither'
		else '' 
		end as 'BillFlagDescription'
			
	from PMOL l with (nolock)
		Left Join PMOI i with (nolock) on i.PMCo=l.PMCo 
			and i.Project=l.Project 
			and i.PCOType=l.PCOType 
			and i.PCO=l.PCO 
			and i.PCOItem=l.PCOItem
		Left Join PMOP u with (nolock) on u.PMCo=l.PMCo 
			and u.Project=l.Project 
			and u.PCOType=l.PCOType 
			and u.PCO=l.PCO 
		Left Join PMDT t with (nolock) on t.DocType=l.PCOType
		Left Join JCJP p with (nolock) on p.JCCo=l.PMCo 
			and p.Job=l.Project 
			and p.PhaseGroup=l.PhaseGroup 
			and p.Phase=l.Phase
		Left Join JCCH c with (nolock) on c.JCCo=l.PMCo 
			and c.Job=l.Project 
			and c.PhaseGroup=l.PhaseGroup 
			and c.Phase=l.Phase
			and c.CostType = l.CostType
		Left Join JCCT ct with (nolock) on ct.PhaseGroup=l.PhaseGroup 
			and ct.CostType = l.CostType
		
	Where l.PMCo=@JCCo and l.Project=@Job  and l.PCO = @PCO 
and l.PCOType = @PCOType and l.PCOItem = @PCOItem
and l.KeyID = IsNull(@KeyID, l.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspPMPendingCOPhasesGet] TO [VCSPortal]
GO
