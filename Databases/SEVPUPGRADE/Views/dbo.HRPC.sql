SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRPC] as select a.* From bHRPC a
GO
GRANT SELECT ON  [dbo].[HRPC] TO [public]
GRANT INSERT ON  [dbo].[HRPC] TO [public]
GRANT DELETE ON  [dbo].[HRPC] TO [public]
GRANT UPDATE ON  [dbo].[HRPC] TO [public]
GO
