SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRJC] as select a.* from bPRJC a    where  (suser_sname() = 'viewpointcs' or  suser_sname() = 'VCSPortal' or           exists(select top 1 1 from vDDDU c1 with (nolock)           where a.PRCo=c1.Qualifier and a.Employee = c1.Employee           and c1.Datatype ='bEmployee' and c1.VPUserName=suser_sname() )   )
GO
GRANT SELECT ON  [dbo].[PRJC] TO [public]
GRANT INSERT ON  [dbo].[PRJC] TO [public]
GRANT DELETE ON  [dbo].[PRJC] TO [public]
GRANT UPDATE ON  [dbo].[PRJC] TO [public]
GRANT SELECT ON  [dbo].[PRJC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRJC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRJC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRJC] TO [Viewpoint]
GO
