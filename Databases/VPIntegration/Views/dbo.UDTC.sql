SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[UDTC] as
select a.* From bUDTC a


GO
GRANT SELECT ON  [dbo].[UDTC] TO [public]
GRANT INSERT ON  [dbo].[UDTC] TO [public]
GRANT DELETE ON  [dbo].[UDTC] TO [public]
GRANT UPDATE ON  [dbo].[UDTC] TO [public]
GO
