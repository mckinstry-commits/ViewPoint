SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PCBidPackageScopeNotes] as select a.* From vPCBidPackageScopeNotes a
GO
GRANT SELECT ON  [dbo].[PCBidPackageScopeNotes] TO [public]
GRANT INSERT ON  [dbo].[PCBidPackageScopeNotes] TO [public]
GRANT DELETE ON  [dbo].[PCBidPackageScopeNotes] TO [public]
GRANT UPDATE ON  [dbo].[PCBidPackageScopeNotes] TO [public]
GRANT SELECT ON  [dbo].[PCBidPackageScopeNotes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCBidPackageScopeNotes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCBidPackageScopeNotes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCBidPackageScopeNotes] TO [Viewpoint]
GO
