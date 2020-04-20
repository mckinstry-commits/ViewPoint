SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMTC] as select a.* From bPMTC a
GO
GRANT SELECT ON  [dbo].[PMTC] TO [public]
GRANT INSERT ON  [dbo].[PMTC] TO [public]
GRANT DELETE ON  [dbo].[PMTC] TO [public]
GRANT UPDATE ON  [dbo].[PMTC] TO [public]
GO
