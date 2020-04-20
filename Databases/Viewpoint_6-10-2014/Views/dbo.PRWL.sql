SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRWL] as select a.* from bPRWL a    where  (suser_sname() = 'viewpointcs' or  suser_sname() = 'VCSPortal' or           exists(select top 1 1 from vDDDU c1 with (nolock)           where a.PRCo=c1.Qualifier and a.Employee = c1.Employee           and c1.Datatype ='bEmployee' and c1.VPUserName=suser_sname() )   )
GO
GRANT SELECT ON  [dbo].[PRWL] TO [public]
GRANT INSERT ON  [dbo].[PRWL] TO [public]
GRANT DELETE ON  [dbo].[PRWL] TO [public]
GRANT UPDATE ON  [dbo].[PRWL] TO [public]
GRANT SELECT ON  [dbo].[PRWL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRWL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRWL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRWL] TO [Viewpoint]
GO
