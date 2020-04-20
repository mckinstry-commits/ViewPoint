SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSDX] as select a.* From bMSDX a
GO
GRANT SELECT ON  [dbo].[MSDX] TO [public]
GRANT INSERT ON  [dbo].[MSDX] TO [public]
GRANT DELETE ON  [dbo].[MSDX] TO [public]
GRANT UPDATE ON  [dbo].[MSDX] TO [public]
GRANT SELECT ON  [dbo].[MSDX] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSDX] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSDX] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSDX] TO [Viewpoint]
GO
