SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRLV] as select a.* From bPRLV a

GO
GRANT SELECT ON  [dbo].[PRLV] TO [public]
GRANT INSERT ON  [dbo].[PRLV] TO [public]
GRANT DELETE ON  [dbo].[PRLV] TO [public]
GRANT UPDATE ON  [dbo].[PRLV] TO [public]
GO
