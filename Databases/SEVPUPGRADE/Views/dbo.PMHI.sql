SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PMHI] as select a.* From bPMHI a

GO
GRANT SELECT ON  [dbo].[PMHI] TO [public]
GRANT INSERT ON  [dbo].[PMHI] TO [public]
GRANT DELETE ON  [dbo].[PMHI] TO [public]
GRANT UPDATE ON  [dbo].[PMHI] TO [public]
GO
