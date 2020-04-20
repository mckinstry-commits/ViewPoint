SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMSS] as select a.* From bPMSS a

GO
GRANT SELECT ON  [dbo].[PMSS] TO [public]
GRANT INSERT ON  [dbo].[PMSS] TO [public]
GRANT DELETE ON  [dbo].[PMSS] TO [public]
GRANT UPDATE ON  [dbo].[PMSS] TO [public]
GO
