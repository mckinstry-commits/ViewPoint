SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMXH] as select a.* From bIMXH a

GO
GRANT SELECT ON  [dbo].[IMXH] TO [public]
GRANT INSERT ON  [dbo].[IMXH] TO [public]
GRANT DELETE ON  [dbo].[IMXH] TO [public]
GRANT UPDATE ON  [dbo].[IMXH] TO [public]
GRANT SELECT ON  [dbo].[IMXH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[IMXH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[IMXH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[IMXH] TO [Viewpoint]
GO
