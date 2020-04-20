SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMPN] as select a.* From bPMPN a

GO
GRANT SELECT ON  [dbo].[PMPN] TO [public]
GRANT INSERT ON  [dbo].[PMPN] TO [public]
GRANT DELETE ON  [dbo].[PMPN] TO [public]
GRANT UPDATE ON  [dbo].[PMPN] TO [public]
GO
