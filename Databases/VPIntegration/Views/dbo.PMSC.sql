SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PMSC] as select a.* From bPMSC a

GO
GRANT SELECT ON  [dbo].[PMSC] TO [public]
GRANT INSERT ON  [dbo].[PMSC] TO [public]
GRANT DELETE ON  [dbo].[PMSC] TO [public]
GRANT UPDATE ON  [dbo].[PMSC] TO [public]
GO
