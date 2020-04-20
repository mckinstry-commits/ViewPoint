SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INIB] as select a.* From bINIB a
GO
GRANT SELECT ON  [dbo].[INIB] TO [public]
GRANT INSERT ON  [dbo].[INIB] TO [public]
GRANT DELETE ON  [dbo].[INIB] TO [public]
GRANT UPDATE ON  [dbo].[INIB] TO [public]
GRANT SELECT ON  [dbo].[INIB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INIB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INIB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INIB] TO [Viewpoint]
GO
