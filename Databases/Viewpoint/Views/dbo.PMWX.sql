SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMWX] as select a.* From bPMWX a

GO
GRANT SELECT ON  [dbo].[PMWX] TO [public]
GRANT INSERT ON  [dbo].[PMWX] TO [public]
GRANT DELETE ON  [dbo].[PMWX] TO [public]
GRANT UPDATE ON  [dbo].[PMWX] TO [public]
GO
