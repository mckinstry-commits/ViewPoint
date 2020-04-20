SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSHC] as select a.* From bMSHC a
GO
GRANT SELECT ON  [dbo].[MSHC] TO [public]
GRANT INSERT ON  [dbo].[MSHC] TO [public]
GRANT DELETE ON  [dbo].[MSHC] TO [public]
GRANT UPDATE ON  [dbo].[MSHC] TO [public]
GRANT SELECT ON  [dbo].[MSHC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSHC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSHC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSHC] TO [Viewpoint]
GO
