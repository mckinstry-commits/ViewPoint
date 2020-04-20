SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRDL] as select a.* From bPRDL a
GO
GRANT SELECT ON  [dbo].[PRDL] TO [public]
GRANT INSERT ON  [dbo].[PRDL] TO [public]
GRANT DELETE ON  [dbo].[PRDL] TO [public]
GRANT UPDATE ON  [dbo].[PRDL] TO [public]
GRANT SELECT ON  [dbo].[PRDL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRDL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRDL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRDL] TO [Viewpoint]
GO
