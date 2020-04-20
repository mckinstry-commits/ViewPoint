SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INXJ] as select a.* From bINXJ a
GO
GRANT SELECT ON  [dbo].[INXJ] TO [public]
GRANT INSERT ON  [dbo].[INXJ] TO [public]
GRANT DELETE ON  [dbo].[INXJ] TO [public]
GRANT UPDATE ON  [dbo].[INXJ] TO [public]
GRANT SELECT ON  [dbo].[INXJ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INXJ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INXJ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INXJ] TO [Viewpoint]
GO
