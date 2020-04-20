SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCOR] as select a.* From bJCOR a
GO
GRANT SELECT ON  [dbo].[JCOR] TO [public]
GRANT INSERT ON  [dbo].[JCOR] TO [public]
GRANT DELETE ON  [dbo].[JCOR] TO [public]
GRANT UPDATE ON  [dbo].[JCOR] TO [public]
GO
