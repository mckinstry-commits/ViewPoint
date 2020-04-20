SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************
 * Created By:	GF 08/21/2007
 * Modfied By:
 *
 * Provides a view of JC Jobs and contract items from JCCI
 * for PM to be used in PM Phase Cost Types flags form.
 * Need to alias JCCo as PMCo and Job as Project
 *
 *****************************************/

CREATE view [dbo].[PMJCJMItems] as
select a.JCCo as [PMCo], a.Job as [Project], a.JCCo, a.Job, a.Contract,
	b.Item, b.UM, b.OrigContractUnits, b.ContractUnits,c.Description as [ContractDesc]
from dbo.JCJM a
join dbo.JCCI b on b.JCCo=a.JCCo and b.Contract=a.Contract
left join dbo.JCCM c on c.JCCo=a.JCCo and c.Contract=a.Contract



GO
GRANT SELECT ON  [dbo].[PMJCJMItems] TO [public]
GRANT INSERT ON  [dbo].[PMJCJMItems] TO [public]
GRANT DELETE ON  [dbo].[PMJCJMItems] TO [public]
GRANT UPDATE ON  [dbo].[PMJCJMItems] TO [public]
GRANT SELECT ON  [dbo].[PMJCJMItems] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMJCJMItems] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMJCJMItems] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMJCJMItems] TO [Viewpoint]
GO
