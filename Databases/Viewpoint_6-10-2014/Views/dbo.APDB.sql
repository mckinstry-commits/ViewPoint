SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APDB] as select a.* From bAPDB a
GO
GRANT SELECT ON  [dbo].[APDB] TO [public]
GRANT INSERT ON  [dbo].[APDB] TO [public]
GRANT DELETE ON  [dbo].[APDB] TO [public]
GRANT UPDATE ON  [dbo].[APDB] TO [public]
GRANT SELECT ON  [dbo].[APDB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APDB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APDB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APDB] TO [Viewpoint]
GO
