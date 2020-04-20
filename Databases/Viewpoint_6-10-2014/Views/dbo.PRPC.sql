SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRPC] as select a.* From bPRPC a
GO
GRANT SELECT ON  [dbo].[PRPC] TO [public]
GRANT INSERT ON  [dbo].[PRPC] TO [public]
GRANT DELETE ON  [dbo].[PRPC] TO [public]
GRANT UPDATE ON  [dbo].[PRPC] TO [public]
GRANT SELECT ON  [dbo].[PRPC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRPC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRPC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRPC] TO [Viewpoint]
GO
