SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APPG] as select a.* From bAPPG a
GO
GRANT SELECT ON  [dbo].[APPG] TO [public]
GRANT INSERT ON  [dbo].[APPG] TO [public]
GRANT DELETE ON  [dbo].[APPG] TO [public]
GRANT UPDATE ON  [dbo].[APPG] TO [public]
GRANT SELECT ON  [dbo].[APPG] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APPG] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APPG] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APPG] TO [Viewpoint]
GO
