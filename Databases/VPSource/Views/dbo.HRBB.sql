SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRBB] as select a.* From bHRBB a
GO
GRANT SELECT ON  [dbo].[HRBB] TO [public]
GRANT INSERT ON  [dbo].[HRBB] TO [public]
GRANT DELETE ON  [dbo].[HRBB] TO [public]
GRANT UPDATE ON  [dbo].[HRBB] TO [public]
GO
