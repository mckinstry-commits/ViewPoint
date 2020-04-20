SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCDM] as select a.* From bJCDM a
GO
GRANT SELECT ON  [dbo].[JCDM] TO [public]
GRANT INSERT ON  [dbo].[JCDM] TO [public]
GRANT DELETE ON  [dbo].[JCDM] TO [public]
GRANT UPDATE ON  [dbo].[JCDM] TO [public]
GO
