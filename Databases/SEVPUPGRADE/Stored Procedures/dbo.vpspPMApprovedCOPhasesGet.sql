SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMApprovedCOPhasesGet]
/************************************************************
* CREATED:     1/10/06  RWH
* MODIFIED:    2/14/06  chs
* MODIFIED:    7/20/06  chs
* MODIFIED:		6/7/07	CHS
*				GF 01/09/2011 TK-11594
*
* USAGE:
*   Returns the PM Approved Change Orders Phase
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, ACO, ACOItem
*
************************************************************/
(@JCCo bCompany, @Job bJob, @ACO bACO, @ACOItem bACOItem,
	@KeyID int = Null)

AS

SET NOCOUNT ON;

Select l.KeyID, l.PMCo, l.Project, l.PCO, 
	u.Description as 'PendingCODescription', 
	l.PCOItem, i.Description as 'PendingCOItemDescription',
	l.PCOType, t.Description as 'PCOTypeDescription',
	l.ACO, a.Description as 'ApprovedCODescription', 
	l.ACOItem, i.Description as 'ACOItemDescription', l.PhaseGroup, l.Phase, 
	p.Description as 'PhaseDescription', l.CostType, 
	ct.Description as 'CostTypeDescription',
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
		Left Join PMOP u with (nolock) on u.PMCo=l.PMCo 
			and u.Project=l.Project 
			and u.PCOType=l.PCOType 
			and u.PCO=l.PCO 
		left Join PMOI i with (nolock) on i.PMCo=l.PMCo 
			and i.Project=l.Project 
			and i.ACO=l.ACO 
			and i.ACOItem=l.ACOItem
		left Join PMDT t with (nolock) on t.DocType=l.PCOType
		left Join PMOH a with (nolock) on a.PMCo=l.PMCo 
			and a.Project=l.Project 
			and a.ACO=l.ACO
		left Join JCJP p with (nolock) on p.JCCo=l.PMCo 
			and p.Job=l.Project 
			and p.PhaseGroup=l.PhaseGroup 
			and p.Phase=l.Phase
		Left Join JCCH c with (nolock) on c.JCCo=l.PMCo 
			and c.Job=l.Project 
			and c.PhaseGroup=l.PhaseGroup 
			and c.Phase=l.Phase
			and c.CostType = l.CostType
		Left join JCCT ct with (nolock) on ct.PhaseGroup=l.PhaseGroup 
			and ct.CostType = l.CostType 
		
	Where l.PMCo=@JCCo and l.Project=@Job and l.ACO = @ACO and l.ACOItem = @ACOItem
and l.KeyID = IsNull(@KeyID, l.KeyID)





GO
GRANT EXECUTE ON  [dbo].[vpspPMApprovedCOPhasesGet] TO [VCSPortal]
GO
