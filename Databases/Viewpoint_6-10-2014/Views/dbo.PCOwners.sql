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
GRANT SELECT ON  [dbo].[PCOwners] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCOwners] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCOwners] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCOwners] TO [Viewpoint]
GO
