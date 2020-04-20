SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMPB] as select a.* From bEMPB a
GO
GRANT SELECT ON  [dbo].[EMPB] TO [public]
GRANT INSERT ON  [dbo].[EMPB] TO [public]
GRANT DELETE ON  [dbo].[EMPB] TO [public]
GRANT UPDATE ON  [dbo].[EMPB] TO [public]
GRANT SELECT ON  [dbo].[EMPB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMPB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMPB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMPB] TO [Viewpoint]
GO
