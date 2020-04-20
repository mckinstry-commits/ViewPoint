SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PREL] as select a.* from bPREL a    where  (suser_sname() = 'viewpointcs' or  suser_sname() = 'VCSPortal' or           exists(select top 1 1 from vDDDU c1 with (nolock)           where a.PRCo=c1.Qualifier and a.Employee = c1.Employee           and c1.Datatype ='bEmployee' and c1.VPUserName=suser_sname() )   )
GO
GRANT SELECT ON  [dbo].[PREL] TO [public]
GRANT INSERT ON  [dbo].[PREL] TO [public]
GRANT DELETE ON  [dbo].[PREL] TO [public]
GRANT UPDATE ON  [dbo].[PREL] TO [public]
GRANT SELECT ON  [dbo].[PREL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PREL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PREL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PREL] TO [Viewpoint]
GO
