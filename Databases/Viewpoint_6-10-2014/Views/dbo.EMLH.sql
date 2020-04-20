SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMLH] as select a.* From bEMLH a
GO
GRANT SELECT ON  [dbo].[EMLH] TO [public]
GRANT INSERT ON  [dbo].[EMLH] TO [public]
GRANT DELETE ON  [dbo].[EMLH] TO [public]
GRANT UPDATE ON  [dbo].[EMLH] TO [public]
GRANT SELECT ON  [dbo].[EMLH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMLH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMLH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMLH] TO [Viewpoint]
GO
