SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCXB] as select a.* From bJCXB a

GO
GRANT SELECT ON  [dbo].[JCXB] TO [public]
GRANT INSERT ON  [dbo].[JCXB] TO [public]
GRANT DELETE ON  [dbo].[JCXB] TO [public]
GRANT UPDATE ON  [dbo].[JCXB] TO [public]
GO
