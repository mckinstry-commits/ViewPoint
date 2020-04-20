SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POII] as select a.* From bPOII a

GO
GRANT SELECT ON  [dbo].[POII] TO [public]
GRANT INSERT ON  [dbo].[POII] TO [public]
GRANT DELETE ON  [dbo].[POII] TO [public]
GRANT UPDATE ON  [dbo].[POII] TO [public]
GO
