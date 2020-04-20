SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMFT] as select a.* From bPMFT a

GO
GRANT SELECT ON  [dbo].[PMFT] TO [public]
GRANT INSERT ON  [dbo].[PMFT] TO [public]
GRANT DELETE ON  [dbo].[PMFT] TO [public]
GRANT UPDATE ON  [dbo].[PMFT] TO [public]
GO
