SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[SMNamedDispatchBoardQuery] as 
	select a.*
	from vSMNamedDispatchBoardQuery a







GO
GRANT SELECT ON  [dbo].[SMNamedDispatchBoardQuery] TO [public]
GRANT INSERT ON  [dbo].[SMNamedDispatchBoardQuery] TO [public]
GRANT DELETE ON  [dbo].[SMNamedDispatchBoardQuery] TO [public]
GRANT UPDATE ON  [dbo].[SMNamedDispatchBoardQuery] TO [public]
GRANT SELECT ON  [dbo].[SMNamedDispatchBoardQuery] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMNamedDispatchBoardQuery] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMNamedDispatchBoardQuery] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMNamedDispatchBoardQuery] TO [Viewpoint]
GO
