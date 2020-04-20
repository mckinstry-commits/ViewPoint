SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APHD] as select a.* From bAPHD a
GO
GRANT SELECT ON  [dbo].[APHD] TO [public]
GRANT INSERT ON  [dbo].[APHD] TO [public]
GRANT DELETE ON  [dbo].[APHD] TO [public]
GRANT UPDATE ON  [dbo].[APHD] TO [public]
GRANT SELECT ON  [dbo].[APHD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APHD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APHD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APHD] TO [Viewpoint]
GO
