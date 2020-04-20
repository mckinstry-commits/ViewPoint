SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARAA] as select a.* From bARAA a
GO
GRANT SELECT ON  [dbo].[ARAA] TO [public]
GRANT INSERT ON  [dbo].[ARAA] TO [public]
GRANT DELETE ON  [dbo].[ARAA] TO [public]
GRANT UPDATE ON  [dbo].[ARAA] TO [public]
GRANT SELECT ON  [dbo].[ARAA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ARAA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ARAA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ARAA] TO [Viewpoint]
GO