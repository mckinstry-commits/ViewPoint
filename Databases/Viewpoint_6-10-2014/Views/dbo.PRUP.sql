SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRUP] as select a.* From bPRUP a
GO
GRANT SELECT ON  [dbo].[PRUP] TO [public]
GRANT INSERT ON  [dbo].[PRUP] TO [public]
GRANT DELETE ON  [dbo].[PRUP] TO [public]
GRANT UPDATE ON  [dbo].[PRUP] TO [public]
GRANT SELECT ON  [dbo].[PRUP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRUP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRUP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRUP] TO [Viewpoint]
GO
