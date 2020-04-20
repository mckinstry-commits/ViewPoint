SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMTA] as select a.* From bCMTA a

GO
GRANT SELECT ON  [dbo].[CMTA] TO [public]
GRANT INSERT ON  [dbo].[CMTA] TO [public]
GRANT DELETE ON  [dbo].[CMTA] TO [public]
GRANT UPDATE ON  [dbo].[CMTA] TO [public]
GO
