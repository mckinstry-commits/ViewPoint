SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRRN] as select a.* From bPRRN a
GO
GRANT SELECT ON  [dbo].[PRRN] TO [public]
GRANT INSERT ON  [dbo].[PRRN] TO [public]
GRANT DELETE ON  [dbo].[PRRN] TO [public]
GRANT UPDATE ON  [dbo].[PRRN] TO [public]
GRANT SELECT ON  [dbo].[PRRN] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRRN] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRRN] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRRN] TO [Viewpoint]
GO
