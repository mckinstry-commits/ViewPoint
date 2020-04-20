SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRAW] as select a.* From bHRAW a

GO
GRANT SELECT ON  [dbo].[HRAW] TO [public]
GRANT INSERT ON  [dbo].[HRAW] TO [public]
GRANT DELETE ON  [dbo].[HRAW] TO [public]
GRANT UPDATE ON  [dbo].[HRAW] TO [public]
GO
