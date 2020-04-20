SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMUD] as select a.* From bEMUD a
GO
GRANT SELECT ON  [dbo].[EMUD] TO [public]
GRANT INSERT ON  [dbo].[EMUD] TO [public]
GRANT DELETE ON  [dbo].[EMUD] TO [public]
GRANT UPDATE ON  [dbo].[EMUD] TO [public]
GRANT SELECT ON  [dbo].[EMUD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMUD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMUD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMUD] TO [Viewpoint]
GO
