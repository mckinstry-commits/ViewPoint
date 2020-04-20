SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HREC] as select a.* From bHREC a
GO
GRANT SELECT ON  [dbo].[HREC] TO [public]
GRANT INSERT ON  [dbo].[HREC] TO [public]
GRANT DELETE ON  [dbo].[HREC] TO [public]
GRANT UPDATE ON  [dbo].[HREC] TO [public]
GRANT SELECT ON  [dbo].[HREC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HREC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HREC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HREC] TO [Viewpoint]
GO
