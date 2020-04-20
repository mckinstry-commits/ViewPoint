SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HREG] as select a.* From bHREG a
GO
GRANT SELECT ON  [dbo].[HREG] TO [public]
GRANT INSERT ON  [dbo].[HREG] TO [public]
GRANT DELETE ON  [dbo].[HREG] TO [public]
GRANT UPDATE ON  [dbo].[HREG] TO [public]
GRANT SELECT ON  [dbo].[HREG] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HREG] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HREG] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HREG] TO [Viewpoint]
GO
