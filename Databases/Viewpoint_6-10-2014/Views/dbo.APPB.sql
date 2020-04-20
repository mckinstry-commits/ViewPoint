SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APPB] as select a.* From bAPPB a
GO
GRANT SELECT ON  [dbo].[APPB] TO [public]
GRANT INSERT ON  [dbo].[APPB] TO [public]
GRANT DELETE ON  [dbo].[APPB] TO [public]
GRANT UPDATE ON  [dbo].[APPB] TO [public]
GRANT SELECT ON  [dbo].[APPB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APPB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APPB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APPB] TO [Viewpoint]
GO
