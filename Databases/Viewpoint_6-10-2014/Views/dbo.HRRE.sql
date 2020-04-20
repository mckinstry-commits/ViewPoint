SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRRE] as select a.* From bHRRE a

GO
GRANT SELECT ON  [dbo].[HRRE] TO [public]
GRANT INSERT ON  [dbo].[HRRE] TO [public]
GRANT DELETE ON  [dbo].[HRRE] TO [public]
GRANT UPDATE ON  [dbo].[HRRE] TO [public]
GRANT SELECT ON  [dbo].[HRRE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRRE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRRE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRRE] TO [Viewpoint]
GO
