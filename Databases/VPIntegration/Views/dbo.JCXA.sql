SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCXA] as select a.* From bJCXA a

GO
GRANT SELECT ON  [dbo].[JCXA] TO [public]
GRANT INSERT ON  [dbo].[JCXA] TO [public]
GRANT DELETE ON  [dbo].[JCXA] TO [public]
GRANT UPDATE ON  [dbo].[JCXA] TO [public]
GO
