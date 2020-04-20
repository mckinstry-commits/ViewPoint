SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APPD] as select a.* From bAPPD a
GO
GRANT SELECT ON  [dbo].[APPD] TO [public]
GRANT INSERT ON  [dbo].[APPD] TO [public]
GRANT DELETE ON  [dbo].[APPD] TO [public]
GRANT UPDATE ON  [dbo].[APPD] TO [public]
GRANT SELECT ON  [dbo].[APPD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APPD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APPD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APPD] TO [Viewpoint]
GO
