SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POXI] as select a.* From bPOXI a

GO
GRANT SELECT ON  [dbo].[POXI] TO [public]
GRANT INSERT ON  [dbo].[POXI] TO [public]
GRANT DELETE ON  [dbo].[POXI] TO [public]
GRANT UPDATE ON  [dbo].[POXI] TO [public]
GO
