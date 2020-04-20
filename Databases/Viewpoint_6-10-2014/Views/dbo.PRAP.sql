SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRAP] as select a.* From bPRAP a
GO
GRANT SELECT ON  [dbo].[PRAP] TO [public]
GRANT INSERT ON  [dbo].[PRAP] TO [public]
GRANT DELETE ON  [dbo].[PRAP] TO [public]
GRANT UPDATE ON  [dbo].[PRAP] TO [public]
GRANT SELECT ON  [dbo].[PRAP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAP] TO [Viewpoint]
GO
