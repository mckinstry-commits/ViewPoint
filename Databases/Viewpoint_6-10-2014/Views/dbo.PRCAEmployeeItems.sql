SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCAEmployeeItems] as select a.* from bPRCAEmployeeItems a    where  (suser_sname() = 'viewpointcs' or  suser_sname() = 'VCSPortal' or           exists(select top 1 1 from vDDDU c1 with (nolock)           where a.PRCo=c1.Qualifier and a.Employee = c1.Employee           and c1.Datatype ='bEmployee' and c1.VPUserName=suser_sname() )   )
GO
GRANT SELECT ON  [dbo].[PRCAEmployeeItems] TO [public]
GRANT INSERT ON  [dbo].[PRCAEmployeeItems] TO [public]
GRANT DELETE ON  [dbo].[PRCAEmployeeItems] TO [public]
GRANT UPDATE ON  [dbo].[PRCAEmployeeItems] TO [public]
GRANT SELECT ON  [dbo].[PRCAEmployeeItems] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCAEmployeeItems] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCAEmployeeItems] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCAEmployeeItems] TO [Viewpoint]
GO
