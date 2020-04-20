SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[SLIB] as select a.* From bSLIB a



GO
GRANT SELECT ON  [dbo].[SLIB] TO [public]
GRANT INSERT ON  [dbo].[SLIB] TO [public]
GRANT DELETE ON  [dbo].[SLIB] TO [public]
GRANT UPDATE ON  [dbo].[SLIB] TO [public]
GO
