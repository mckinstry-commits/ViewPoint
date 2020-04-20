SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POCD] as select a.* From bPOCD a
GO
GRANT SELECT ON  [dbo].[POCD] TO [public]
GRANT INSERT ON  [dbo].[POCD] TO [public]
GRANT DELETE ON  [dbo].[POCD] TO [public]
GRANT UPDATE ON  [dbo].[POCD] TO [public]
GO
