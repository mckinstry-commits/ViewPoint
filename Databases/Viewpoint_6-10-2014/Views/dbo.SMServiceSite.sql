SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMServiceSite] as select a.* From vSMServiceSite a
GO
GRANT SELECT ON  [dbo].[SMServiceSite] TO [public]
GRANT INSERT ON  [dbo].[SMServiceSite] TO [public]
GRANT DELETE ON  [dbo].[SMServiceSite] TO [public]
GRANT UPDATE ON  [dbo].[SMServiceSite] TO [public]
GRANT SELECT ON  [dbo].[SMServiceSite] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMServiceSite] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMServiceSite] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMServiceSite] TO [Viewpoint]
GO
