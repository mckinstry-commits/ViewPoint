SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRRS] as select a.* From bHRRS a

GO
GRANT SELECT ON  [dbo].[HRRS] TO [public]
GRANT INSERT ON  [dbo].[HRRS] TO [public]
GRANT DELETE ON  [dbo].[HRRS] TO [public]
GRANT UPDATE ON  [dbo].[HRRS] TO [public]
GO
