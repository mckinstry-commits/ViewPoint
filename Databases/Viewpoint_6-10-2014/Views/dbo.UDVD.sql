SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[UDVD] as select a.* From bUDVD a
GO
GRANT SELECT ON  [dbo].[UDVD] TO [public]
GRANT INSERT ON  [dbo].[UDVD] TO [public]
GRANT DELETE ON  [dbo].[UDVD] TO [public]
GRANT UPDATE ON  [dbo].[UDVD] TO [public]
GRANT SELECT ON  [dbo].[UDVD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[UDVD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[UDVD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[UDVD] TO [Viewpoint]
GO
