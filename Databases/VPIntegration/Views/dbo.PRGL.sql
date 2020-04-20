SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRGL] as select a.* from bPRGL a    where  (suser_sname() = 'viewpointcs' or  suser_sname() = 'VCSPortal' or           exists(select top 1 1 from vDDDU c1 with (nolock)           where a.PRCo=c1.Qualifier and a.Employee = c1.Employee           and c1.Datatype ='bEmployee' and c1.VPUserName=suser_sname() )   )
GO
GRANT SELECT ON  [dbo].[PRGL] TO [public]
GRANT INSERT ON  [dbo].[PRGL] TO [public]
GRANT DELETE ON  [dbo].[PRGL] TO [public]
GRANT UPDATE ON  [dbo].[PRGL] TO [public]
GO
