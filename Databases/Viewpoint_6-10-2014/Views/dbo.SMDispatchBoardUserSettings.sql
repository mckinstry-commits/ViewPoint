SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMDispatchBoardUserSettings]
AS
SELECT        dbo.vSMDispatchBoardUserSettings.*
FROM            dbo.vSMDispatchBoardUserSettings

GO
GRANT SELECT ON  [dbo].[SMDispatchBoardUserSettings] TO [public]
GRANT INSERT ON  [dbo].[SMDispatchBoardUserSettings] TO [public]
GRANT DELETE ON  [dbo].[SMDispatchBoardUserSettings] TO [public]
GRANT UPDATE ON  [dbo].[SMDispatchBoardUserSettings] TO [public]
GRANT SELECT ON  [dbo].[SMDispatchBoardUserSettings] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMDispatchBoardUserSettings] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMDispatchBoardUserSettings] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMDispatchBoardUserSettings] TO [Viewpoint]
GO
