SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCCI] as select a.* From bJCCI a
GO
GRANT SELECT ON  [dbo].[JCCI] TO [public]
GRANT INSERT ON  [dbo].[JCCI] TO [public]
GRANT DELETE ON  [dbo].[JCCI] TO [public]
GRANT UPDATE ON  [dbo].[JCCI] TO [public]
GO
