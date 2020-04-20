SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMType] as select a.* From vSMType a
GO
GRANT SELECT ON  [dbo].[SMType] TO [public]
GRANT INSERT ON  [dbo].[SMType] TO [public]
GRANT DELETE ON  [dbo].[SMType] TO [public]
GRANT UPDATE ON  [dbo].[SMType] TO [public]
GRANT SELECT ON  [dbo].[SMType] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMType] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMType] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMType] TO [Viewpoint]
GO
