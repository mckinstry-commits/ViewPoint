SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APRL] as select a.* From bAPRL a
GO
GRANT SELECT ON  [dbo].[APRL] TO [public]
GRANT INSERT ON  [dbo].[APRL] TO [public]
GRANT DELETE ON  [dbo].[APRL] TO [public]
GRANT UPDATE ON  [dbo].[APRL] TO [public]
GRANT SELECT ON  [dbo].[APRL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APRL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APRL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APRL] TO [Viewpoint]
GO
