SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
 * Created By:	GF 08/23/2007
 * Modfied By:	GF 12/05/2008 - issue #131336 need current estimate units from JCCH
 *				GF 06/28/2010 - issue #140104 get PMOL estimate units when not interfaced for accurate current.
 *
 *
 * Provides a view of JC Job Phase cost header with
 * a join to JCJP for JCJP.Item
 * Used in PM Project Items Phase Flags form.
 *
 *****************************************/

CREATE view [dbo].[JCCHPMItems] as 
select a.JCCo as [PMCo], a.Job as [Project], b.Item, a.*,
	'CurrEstUnits' = (select isnull(sum(EstUnits),0) from dbo.bJCCD p where p.JCCo=a.JCCo and p.Job=a.Job
				and p.PhaseGroup=a.PhaseGroup and p.Phase=a.Phase and p.CostType=a.CostType and p.UM=a.UM),
	---- #140104
	'PMOLEstUnits' = (select isnull(sum(EstUnits),0) from dbo.bPMOL l where l.PMCo=a.JCCo and l.Project=a.Job
				and l.PhaseGroup=a.PhaseGroup and l.Phase=a.Phase and l.CostType=a.CostType and l.UM=a.UM
				and l.InterfacedDate is null)

from dbo.JCCH a
join dbo.JCJP b on b.JCCo=a.JCCo and b.Job=a.Job and b.PhaseGroup=a.PhaseGroup and b.Phase=a.Phase


GO
GRANT SELECT ON  [dbo].[JCCHPMItems] TO [public]
GRANT INSERT ON  [dbo].[JCCHPMItems] TO [public]
GRANT DELETE ON  [dbo].[JCCHPMItems] TO [public]
GRANT UPDATE ON  [dbo].[JCCHPMItems] TO [public]
GRANT SELECT ON  [dbo].[JCCHPMItems] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCCHPMItems] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCCHPMItems] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCCHPMItems] TO [Viewpoint]
GO
