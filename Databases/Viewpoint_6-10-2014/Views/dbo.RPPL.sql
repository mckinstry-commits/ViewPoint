SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPPL] as select a.* From vRPPL a
GO
GRANT SELECT ON  [dbo].[RPPL] TO [public]
GRANT INSERT ON  [dbo].[RPPL] TO [public]
GRANT DELETE ON  [dbo].[RPPL] TO [public]
GRANT UPDATE ON  [dbo].[RPPL] TO [public]
GRANT SELECT ON  [dbo].[RPPL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPPL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPPL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPPL] TO [Viewpoint]
GO
