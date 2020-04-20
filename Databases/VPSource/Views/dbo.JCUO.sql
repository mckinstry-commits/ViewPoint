SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCUO] as select a.* From bJCUO a

GO
GRANT SELECT ON  [dbo].[JCUO] TO [public]
GRANT INSERT ON  [dbo].[JCUO] TO [public]
GRANT DELETE ON  [dbo].[JCUO] TO [public]
GRANT UPDATE ON  [dbo].[JCUO] TO [public]
GO
