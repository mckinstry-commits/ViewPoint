SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSWH] as select a.* From bMSWH a
GO
GRANT SELECT ON  [dbo].[MSWH] TO [public]
GRANT INSERT ON  [dbo].[MSWH] TO [public]
GRANT DELETE ON  [dbo].[MSWH] TO [public]
GRANT UPDATE ON  [dbo].[MSWH] TO [public]
GRANT SELECT ON  [dbo].[MSWH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSWH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSWH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSWH] TO [Viewpoint]
GO
