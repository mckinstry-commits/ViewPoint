SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRTS] as select a.* From bHRTS a

GO
GRANT SELECT ON  [dbo].[HRTS] TO [public]
GRANT INSERT ON  [dbo].[HRTS] TO [public]
GRANT DELETE ON  [dbo].[HRTS] TO [public]
GRANT UPDATE ON  [dbo].[HRTS] TO [public]
GO
