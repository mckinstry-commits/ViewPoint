SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTL] as select a.* from bPRTL a    where  (suser_sname() = 'viewpointcs' or  suser_sname() = 'VCSPortal' or           exists(select top 1 1 from vDDDU c1 with (nolock)           where a.PRCo=c1.Qualifier and a.Employee = c1.Employee           and c1.Datatype ='bEmployee' and c1.VPUserName=suser_sname() )   )
GO
GRANT SELECT ON  [dbo].[PRTL] TO [public]
GRANT INSERT ON  [dbo].[PRTL] TO [public]
GRANT DELETE ON  [dbo].[PRTL] TO [public]
GRANT UPDATE ON  [dbo].[PRTL] TO [public]
GRANT SELECT ON  [dbo].[PRTL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTL] TO [Viewpoint]
GO
