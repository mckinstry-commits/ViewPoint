SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PCOwners] as select a.* From vPCOwners a

GO
GRANT SELECT ON  [dbo].[PCOwners] TO [public]
GRANT INSERT ON  [dbo].[PCOwners] TO [public]
GRANT DELETE ON  [dbo].[PCOwners] TO [public]
GRANT UPDATE ON  [dbo].[PCOwners] TO [public]
GO
