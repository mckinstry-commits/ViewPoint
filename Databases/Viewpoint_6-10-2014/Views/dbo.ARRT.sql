SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARRT] as select a.* From bARRT a
GO
GRANT SELECT ON  [dbo].[ARRT] TO [public]
GRANT INSERT ON  [dbo].[ARRT] TO [public]
GRANT DELETE ON  [dbo].[ARRT] TO [public]
GRANT UPDATE ON  [dbo].[ARRT] TO [public]
GRANT SELECT ON  [dbo].[ARRT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ARRT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ARRT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ARRT] TO [Viewpoint]
GO
