SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PREM] as select a.* from bPREM a    where  (suser_sname() = 'viewpointcs' or  suser_sname() = 'VCSPortal' or           exists(select top 1 1 from vDDDU c1 with (nolock)           where a.PRCo=c1.Qualifier and a.Employee = c1.Employee           and c1.Datatype ='bEmployee' and c1.VPUserName=suser_sname() )   )
GO
GRANT SELECT ON  [dbo].[PREM] TO [public]
GRANT INSERT ON  [dbo].[PREM] TO [public]
GRANT DELETE ON  [dbo].[PREM] TO [public]
GRANT UPDATE ON  [dbo].[PREM] TO [public]
GO
