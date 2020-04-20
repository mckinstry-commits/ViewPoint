SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPRS] as select a.* From vRPRS a
GO
GRANT SELECT ON  [dbo].[RPRS] TO [public]
GRANT INSERT ON  [dbo].[RPRS] TO [public]
GRANT DELETE ON  [dbo].[RPRS] TO [public]
GRANT UPDATE ON  [dbo].[RPRS] TO [public]
GRANT SELECT ON  [dbo].[RPRS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPRS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPRS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPRS] TO [Viewpoint]
GO
