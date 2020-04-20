SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQCO] as select a.* from bHQCO a    where  (suser_sname() = 'viewpointcs' or  suser_sname() = 'VCSPortal' or           exists(select top 1 1 from vDDDU c1 with (nolock)           where a.HQCo=c1.Qualifier and convert(varchar(30),a.HQCo) = c1.Instance           and c1.Datatype ='bHQCo' and c1.VPUserName=suser_sname() )   )
GO
GRANT SELECT ON  [dbo].[HQCO] TO [public]
GRANT INSERT ON  [dbo].[HQCO] TO [public]
GRANT DELETE ON  [dbo].[HQCO] TO [public]
GRANT UPDATE ON  [dbo].[HQCO] TO [public]
GRANT SELECT ON  [dbo].[HQCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQCO] TO [Viewpoint]
GO
