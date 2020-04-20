SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[RPTM] as select a.* From vRPTM a

GO
GRANT SELECT ON  [dbo].[RPTM] TO [public]
GRANT INSERT ON  [dbo].[RPTM] TO [public]
GRANT DELETE ON  [dbo].[RPTM] TO [public]
GRANT UPDATE ON  [dbo].[RPTM] TO [public]
GO
