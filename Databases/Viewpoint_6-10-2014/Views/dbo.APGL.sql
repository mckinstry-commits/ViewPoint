SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APGL] as select a.* From bAPGL a
GO
GRANT SELECT ON  [dbo].[APGL] TO [public]
GRANT INSERT ON  [dbo].[APGL] TO [public]
GRANT DELETE ON  [dbo].[APGL] TO [public]
GRANT UPDATE ON  [dbo].[APGL] TO [public]
GRANT SELECT ON  [dbo].[APGL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APGL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APGL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APGL] TO [Viewpoint]
GO
