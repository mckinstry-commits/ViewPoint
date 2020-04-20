SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSHB] as select a.* From bMSHB a
GO
GRANT SELECT ON  [dbo].[MSHB] TO [public]
GRANT INSERT ON  [dbo].[MSHB] TO [public]
GRANT DELETE ON  [dbo].[MSHB] TO [public]
GRANT UPDATE ON  [dbo].[MSHB] TO [public]
GRANT SELECT ON  [dbo].[MSHB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSHB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSHB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSHB] TO [Viewpoint]
GO
