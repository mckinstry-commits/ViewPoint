SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INAB] as select a.* From bINAB a
GO
GRANT SELECT ON  [dbo].[INAB] TO [public]
GRANT INSERT ON  [dbo].[INAB] TO [public]
GRANT DELETE ON  [dbo].[INAB] TO [public]
GRANT UPDATE ON  [dbo].[INAB] TO [public]
GRANT SELECT ON  [dbo].[INAB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INAB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INAB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INAB] TO [Viewpoint]
GO
