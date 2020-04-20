SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSHX] as select a.* From bMSHX a
GO
GRANT SELECT ON  [dbo].[MSHX] TO [public]
GRANT INSERT ON  [dbo].[MSHX] TO [public]
GRANT DELETE ON  [dbo].[MSHX] TO [public]
GRANT UPDATE ON  [dbo].[MSHX] TO [public]
GRANT SELECT ON  [dbo].[MSHX] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSHX] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSHX] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSHX] TO [Viewpoint]
GO
