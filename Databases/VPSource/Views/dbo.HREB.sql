SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HREB] as select a.* From bHREB a

GO
GRANT SELECT ON  [dbo].[HREB] TO [public]
GRANT INSERT ON  [dbo].[HREB] TO [public]
GRANT DELETE ON  [dbo].[HREB] TO [public]
GRANT UPDATE ON  [dbo].[HREB] TO [public]
GO
