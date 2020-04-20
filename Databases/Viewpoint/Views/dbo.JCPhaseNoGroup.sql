SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[JCPhaseNoGroup] 
--with SCHEMABINDING
as 
/***********************************
* Created: ??
* Modified: GG 04/10/08 - added top 100 percent and order by
*
* Used to list Phase codes across all Phase Groups
*
***************************************/
select top 100 percent Phase, min(Description) as Description 
from bJCPM (nolock)
group by Phase
order by Phase

GO
GRANT SELECT ON  [dbo].[JCPhaseNoGroup] TO [public]
GRANT INSERT ON  [dbo].[JCPhaseNoGroup] TO [public]
GRANT DELETE ON  [dbo].[JCPhaseNoGroup] TO [public]
GRANT UPDATE ON  [dbo].[JCPhaseNoGroup] TO [public]
GO
