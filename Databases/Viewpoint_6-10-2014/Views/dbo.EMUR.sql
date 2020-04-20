SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMUR] as select a.* From bEMUR a
GO
GRANT SELECT ON  [dbo].[EMUR] TO [public]
GRANT INSERT ON  [dbo].[EMUR] TO [public]
GRANT DELETE ON  [dbo].[EMUR] TO [public]
GRANT UPDATE ON  [dbo].[EMUR] TO [public]
GRANT SELECT ON  [dbo].[EMUR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMUR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMUR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMUR] TO [Viewpoint]
GO
