SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRLD] as select a.* From bPRLD a
GO
GRANT SELECT ON  [dbo].[PRLD] TO [public]
GRANT INSERT ON  [dbo].[PRLD] TO [public]
GRANT DELETE ON  [dbo].[PRLD] TO [public]
GRANT UPDATE ON  [dbo].[PRLD] TO [public]
GRANT SELECT ON  [dbo].[PRLD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRLD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRLD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRLD] TO [Viewpoint]
GO
