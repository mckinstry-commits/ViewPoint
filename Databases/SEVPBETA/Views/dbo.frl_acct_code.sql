SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[frl_acct_code] as select a.* From vfrl_acct_code a

GO
GRANT SELECT ON  [dbo].[frl_acct_code] TO [public]
GRANT INSERT ON  [dbo].[frl_acct_code] TO [public]
GRANT DELETE ON  [dbo].[frl_acct_code] TO [public]
GRANT UPDATE ON  [dbo].[frl_acct_code] TO [public]
GO
