SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSIL] as select a.* From bMSIL a
GO
GRANT SELECT ON  [dbo].[MSIL] TO [public]
GRANT INSERT ON  [dbo].[MSIL] TO [public]
GRANT DELETE ON  [dbo].[MSIL] TO [public]
GRANT UPDATE ON  [dbo].[MSIL] TO [public]
GO
