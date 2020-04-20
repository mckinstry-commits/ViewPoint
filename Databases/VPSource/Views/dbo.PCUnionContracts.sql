SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PCUnionContracts] as select a.* From vPCUnionContracts a

GO
GRANT SELECT ON  [dbo].[PCUnionContracts] TO [public]
GRANT INSERT ON  [dbo].[PCUnionContracts] TO [public]
GRANT DELETE ON  [dbo].[PCUnionContracts] TO [public]
GRANT UPDATE ON  [dbo].[PCUnionContracts] TO [public]
GO
