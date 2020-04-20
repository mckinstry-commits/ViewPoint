SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBTC] as select a.* From bJBTC a
GO
GRANT SELECT ON  [dbo].[JBTC] TO [public]
GRANT INSERT ON  [dbo].[JBTC] TO [public]
GRANT DELETE ON  [dbo].[JBTC] TO [public]
GRANT UPDATE ON  [dbo].[JBTC] TO [public]
GO
