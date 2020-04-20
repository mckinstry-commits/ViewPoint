SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[SMNamedDispatchBoardTechnician] as select a.* From vSMNamedDispatchBoardTechnician a







GO
GRANT SELECT ON  [dbo].[SMNamedDispatchBoardTechnician] TO [public]
GRANT INSERT ON  [dbo].[SMNamedDispatchBoardTechnician] TO [public]
GRANT DELETE ON  [dbo].[SMNamedDispatchBoardTechnician] TO [public]
GRANT UPDATE ON  [dbo].[SMNamedDispatchBoardTechnician] TO [public]
GRANT SELECT ON  [dbo].[SMNamedDispatchBoardTechnician] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMNamedDispatchBoardTechnician] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMNamedDispatchBoardTechnician] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMNamedDispatchBoardTechnician] TO [Viewpoint]
GO
