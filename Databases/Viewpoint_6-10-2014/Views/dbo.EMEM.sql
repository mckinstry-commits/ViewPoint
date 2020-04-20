SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMEM] as select a.* From bEMEM a
GO
GRANT SELECT ON  [dbo].[EMEM] TO [public]
GRANT INSERT ON  [dbo].[EMEM] TO [public]
GRANT DELETE ON  [dbo].[EMEM] TO [public]
GRANT UPDATE ON  [dbo].[EMEM] TO [public]
GRANT SELECT ON  [dbo].[EMEM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMEM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMEM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMEM] TO [Viewpoint]
GO
