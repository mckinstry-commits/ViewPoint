SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMTC] as select a.* From bEMTC a
GO
GRANT SELECT ON  [dbo].[EMTC] TO [public]
GRANT INSERT ON  [dbo].[EMTC] TO [public]
GRANT DELETE ON  [dbo].[EMTC] TO [public]
GRANT UPDATE ON  [dbo].[EMTC] TO [public]
GO
