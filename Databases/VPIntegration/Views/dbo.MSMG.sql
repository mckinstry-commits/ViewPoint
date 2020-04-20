SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSMG] as select a.* From bMSMG a

GO
GRANT SELECT ON  [dbo].[MSMG] TO [public]
GRANT INSERT ON  [dbo].[MSMG] TO [public]
GRANT DELETE ON  [dbo].[MSMG] TO [public]
GRANT UPDATE ON  [dbo].[MSMG] TO [public]
GO
