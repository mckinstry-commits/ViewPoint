SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCDL] as select a.* From bJCDL a

GO
GRANT SELECT ON  [dbo].[JCDL] TO [public]
GRANT INSERT ON  [dbo].[JCDL] TO [public]
GRANT DELETE ON  [dbo].[JCDL] TO [public]
GRANT UPDATE ON  [dbo].[JCDL] TO [public]
GO
