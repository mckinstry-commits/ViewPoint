SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POCA] as select a.* From bPOCA a

GO
GRANT SELECT ON  [dbo].[POCA] TO [public]
GRANT INSERT ON  [dbo].[POCA] TO [public]
GRANT DELETE ON  [dbo].[POCA] TO [public]
GRANT UPDATE ON  [dbo].[POCA] TO [public]
GO
