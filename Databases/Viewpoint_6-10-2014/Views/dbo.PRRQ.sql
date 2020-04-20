SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRRQ] as select a.* From bPRRQ a
GO
GRANT SELECT ON  [dbo].[PRRQ] TO [public]
GRANT INSERT ON  [dbo].[PRRQ] TO [public]
GRANT DELETE ON  [dbo].[PRRQ] TO [public]
GRANT UPDATE ON  [dbo].[PRRQ] TO [public]
GRANT SELECT ON  [dbo].[PRRQ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRRQ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRRQ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRRQ] TO [Viewpoint]
GO
