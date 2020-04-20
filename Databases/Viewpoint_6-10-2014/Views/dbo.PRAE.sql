SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRAE] as select a.* from bPRAE a    where  (suser_sname() = 'viewpointcs' or  suser_sname() = 'VCSPortal' or           exists(select top 1 1 from vDDDU c1 with (nolock)           where a.PRCo=c1.Qualifier and a.Employee = c1.Employee           and c1.Datatype ='bEmployee' and c1.VPUserName=suser_sname() )   )
GO
GRANT SELECT ON  [dbo].[PRAE] TO [public]
GRANT INSERT ON  [dbo].[PRAE] TO [public]
GRANT DELETE ON  [dbo].[PRAE] TO [public]
GRANT UPDATE ON  [dbo].[PRAE] TO [public]
GRANT SELECT ON  [dbo].[PRAE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAE] TO [Viewpoint]
GO
