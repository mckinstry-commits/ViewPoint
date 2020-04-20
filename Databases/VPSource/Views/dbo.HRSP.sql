SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRSP] as select a.* From bHRSP a

GO
GRANT SELECT ON  [dbo].[HRSP] TO [public]
GRANT INSERT ON  [dbo].[HRSP] TO [public]
GRANT DELETE ON  [dbo].[HRSP] TO [public]
GRANT UPDATE ON  [dbo].[HRSP] TO [public]
GO
