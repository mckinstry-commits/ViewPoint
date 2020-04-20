SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GP 10/20/2009 - Issue #136123 created to fix crash of Cost Type tab in PM Import Edit when
*									identical record of Item, Phase, and CT exist.
* Modfied By:
*
*
*****************************************/


CREATE view [dbo].[PMWDPhase] as 
select distinct d.PMCo, d.ImportId, d.Phase, min(p.Description) as [Description]
from dbo.bPMWD d with (nolock)
join dbo.bPMWP p with (nolock) on p.PMCo=d.PMCo and p.ImportId=d.ImportId and p.Phase=d.Phase
group by d.PMCo, d.ImportId, d.Phase

GO
GRANT SELECT ON  [dbo].[PMWDPhase] TO [public]
GRANT INSERT ON  [dbo].[PMWDPhase] TO [public]
GRANT DELETE ON  [dbo].[PMWDPhase] TO [public]
GRANT UPDATE ON  [dbo].[PMWDPhase] TO [public]
GO
