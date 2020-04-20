SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMWorkOrderScope] as select a.* From vSMWorkOrderScope a
GO
GRANT SELECT ON  [dbo].[SMWorkOrderScope] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderScope] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderScope] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderScope] TO [public]
GRANT SELECT ON  [dbo].[SMWorkOrderScope] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWorkOrderScope] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWorkOrderScope] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWorkOrderScope] TO [Viewpoint]
GO
