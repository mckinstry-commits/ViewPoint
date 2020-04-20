SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBBM] as select a.* From bJBBM a

GO
GRANT SELECT ON  [dbo].[JBBM] TO [public]
GRANT INSERT ON  [dbo].[JBBM] TO [public]
GRANT DELETE ON  [dbo].[JBBM] TO [public]
GRANT UPDATE ON  [dbo].[JBBM] TO [public]
GO
