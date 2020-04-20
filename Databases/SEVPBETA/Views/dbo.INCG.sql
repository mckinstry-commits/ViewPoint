SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INCG] as select a.* From bINCG a

GO
GRANT SELECT ON  [dbo].[INCG] TO [public]
GRANT INSERT ON  [dbo].[INCG] TO [public]
GRANT DELETE ON  [dbo].[INCG] TO [public]
GRANT UPDATE ON  [dbo].[INCG] TO [public]
GO
