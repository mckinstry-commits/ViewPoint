SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[JCJM] as select a.* From bJCJM a
WHERE a.PCVisibleInJC = 'Y'
GO
GRANT SELECT ON  [dbo].[JCJM] TO [public]
GRANT INSERT ON  [dbo].[JCJM] TO [public]
GRANT DELETE ON  [dbo].[JCJM] TO [public]
GRANT UPDATE ON  [dbo].[JCJM] TO [public]
GO
