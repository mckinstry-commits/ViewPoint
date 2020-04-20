SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRSQ] as select a.* from bPRSQ a    where  (suser_sname() = 'viewpointcs' or  suser_sname() = 'VCSPortal' or           exists(select top 1 1 from vDDDU c1 with (nolock)           where a.PRCo=c1.Qualifier and a.Employee = c1.Employee           and c1.Datatype ='bEmployee' and c1.VPUserName=suser_sname() )   )
GO
GRANT SELECT ON  [dbo].[PRSQ] TO [public]
GRANT INSERT ON  [dbo].[PRSQ] TO [public]
GRANT DELETE ON  [dbo].[PRSQ] TO [public]
GRANT UPDATE ON  [dbo].[PRSQ] TO [public]
GO
