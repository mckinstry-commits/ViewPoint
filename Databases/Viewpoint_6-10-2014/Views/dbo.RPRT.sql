SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPRT] as select a.* From vRPRT a
GO
GRANT SELECT ON  [dbo].[RPRT] TO [public]
GRANT INSERT ON  [dbo].[RPRT] TO [public]
GRANT DELETE ON  [dbo].[RPRT] TO [public]
GRANT UPDATE ON  [dbo].[RPRT] TO [public]
GRANT SELECT ON  [dbo].[RPRT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPRT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPRT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPRT] TO [Viewpoint]
GO
