SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMXD] as select a.* From bIMXD a

GO
GRANT SELECT ON  [dbo].[IMXD] TO [public]
GRANT INSERT ON  [dbo].[IMXD] TO [public]
GRANT DELETE ON  [dbo].[IMXD] TO [public]
GRANT UPDATE ON  [dbo].[IMXD] TO [public]
GRANT SELECT ON  [dbo].[IMXD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[IMXD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[IMXD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[IMXD] TO [Viewpoint]
GO
