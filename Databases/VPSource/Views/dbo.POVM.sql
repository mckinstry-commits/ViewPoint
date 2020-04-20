SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[POVM] as select a.* From bPOVM a

GO
GRANT SELECT ON  [dbo].[POVM] TO [public]
GRANT INSERT ON  [dbo].[POVM] TO [public]
GRANT DELETE ON  [dbo].[POVM] TO [public]
GRANT UPDATE ON  [dbo].[POVM] TO [public]
GO
