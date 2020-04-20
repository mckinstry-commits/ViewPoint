SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSIB] as select a.* From bMSIB a
GO
GRANT SELECT ON  [dbo].[MSIB] TO [public]
GRANT INSERT ON  [dbo].[MSIB] TO [public]
GRANT DELETE ON  [dbo].[MSIB] TO [public]
GRANT UPDATE ON  [dbo].[MSIB] TO [public]
GO
