SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCID] as select a.* From bJCID a
GO
GRANT SELECT ON  [dbo].[JCID] TO [public]
GRANT INSERT ON  [dbo].[JCID] TO [public]
GRANT DELETE ON  [dbo].[JCID] TO [public]
GRANT UPDATE ON  [dbo].[JCID] TO [public]
GO
