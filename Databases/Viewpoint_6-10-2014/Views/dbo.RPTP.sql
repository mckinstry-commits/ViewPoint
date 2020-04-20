SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPTP] as select a.* From vRPTP a
GO
GRANT SELECT ON  [dbo].[RPTP] TO [public]
GRANT INSERT ON  [dbo].[RPTP] TO [public]
GRANT DELETE ON  [dbo].[RPTP] TO [public]
GRANT UPDATE ON  [dbo].[RPTP] TO [public]
GRANT SELECT ON  [dbo].[RPTP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPTP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPTP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPTP] TO [Viewpoint]
GO
