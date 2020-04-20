SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSAR] as select a.* From bMSAR a

GO
GRANT SELECT ON  [dbo].[MSAR] TO [public]
GRANT INSERT ON  [dbo].[MSAR] TO [public]
GRANT DELETE ON  [dbo].[MSAR] TO [public]
GRANT UPDATE ON  [dbo].[MSAR] TO [public]
GO
