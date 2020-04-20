SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[frl_trx_dtl] as select a.* From vfrl_trx_dtl a

GO
GRANT SELECT ON  [dbo].[frl_trx_dtl] TO [public]
GRANT INSERT ON  [dbo].[frl_trx_dtl] TO [public]
GRANT DELETE ON  [dbo].[frl_trx_dtl] TO [public]
GRANT UPDATE ON  [dbo].[frl_trx_dtl] TO [public]
GO
