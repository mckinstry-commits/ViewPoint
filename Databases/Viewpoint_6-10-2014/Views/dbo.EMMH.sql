SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMMH] as select a.* From bEMMH a

GO
GRANT SELECT ON  [dbo].[EMMH] TO [public]
GRANT INSERT ON  [dbo].[EMMH] TO [public]
GRANT DELETE ON  [dbo].[EMMH] TO [public]
GRANT UPDATE ON  [dbo].[EMMH] TO [public]
GRANT SELECT ON  [dbo].[EMMH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMMH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMMH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMMH] TO [Viewpoint]
GO
