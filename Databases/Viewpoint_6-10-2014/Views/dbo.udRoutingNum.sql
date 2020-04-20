SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udRoutingNum] as select a.* From budRoutingNum a
GO
GRANT SELECT ON  [dbo].[udRoutingNum] TO [public]
GRANT INSERT ON  [dbo].[udRoutingNum] TO [public]
GRANT DELETE ON  [dbo].[udRoutingNum] TO [public]
GRANT UPDATE ON  [dbo].[udRoutingNum] TO [public]
GRANT SELECT ON  [dbo].[udRoutingNum] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udRoutingNum] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udRoutingNum] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udRoutingNum] TO [Viewpoint]
GO
