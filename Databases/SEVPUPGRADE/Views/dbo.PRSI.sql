SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRSI] as select a.* From bPRSI a
GO
GRANT SELECT ON  [dbo].[PRSI] TO [public]
GRANT INSERT ON  [dbo].[PRSI] TO [public]
GRANT DELETE ON  [dbo].[PRSI] TO [public]
GRANT UPDATE ON  [dbo].[PRSI] TO [public]
GO
