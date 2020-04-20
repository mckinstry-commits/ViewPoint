SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PORH] as select a.* From bPORH a
GO
GRANT SELECT ON  [dbo].[PORH] TO [public]
GRANT INSERT ON  [dbo].[PORH] TO [public]
GRANT DELETE ON  [dbo].[PORH] TO [public]
GRANT UPDATE ON  [dbo].[PORH] TO [public]
GRANT SELECT ON  [dbo].[PORH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PORH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PORH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PORH] TO [Viewpoint]
GO
