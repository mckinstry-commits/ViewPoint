SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APHR] as select a.* From bAPHR a

GO
GRANT SELECT ON  [dbo].[APHR] TO [public]
GRANT INSERT ON  [dbo].[APHR] TO [public]
GRANT DELETE ON  [dbo].[APHR] TO [public]
GRANT UPDATE ON  [dbo].[APHR] TO [public]
GRANT SELECT ON  [dbo].[APHR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APHR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APHR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APHR] TO [Viewpoint]
GO
