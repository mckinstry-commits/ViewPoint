SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMServiceSiteContact] as select a.* From vSMServiceSiteContact a
GO
GRANT SELECT ON  [dbo].[SMServiceSiteContact] TO [public]
GRANT INSERT ON  [dbo].[SMServiceSiteContact] TO [public]
GRANT DELETE ON  [dbo].[SMServiceSiteContact] TO [public]
GRANT UPDATE ON  [dbo].[SMServiceSiteContact] TO [public]
GRANT SELECT ON  [dbo].[SMServiceSiteContact] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMServiceSiteContact] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMServiceSiteContact] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMServiceSiteContact] TO [Viewpoint]
GO
