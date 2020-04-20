SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMStandardTaskCheckList]
AS
SELECT     *
FROM         dbo.vSMStandardTaskCheckList

GO
GRANT SELECT ON  [dbo].[SMStandardTaskCheckList] TO [public]
GRANT INSERT ON  [dbo].[SMStandardTaskCheckList] TO [public]
GRANT DELETE ON  [dbo].[SMStandardTaskCheckList] TO [public]
GRANT UPDATE ON  [dbo].[SMStandardTaskCheckList] TO [public]
GRANT SELECT ON  [dbo].[SMStandardTaskCheckList] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMStandardTaskCheckList] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMStandardTaskCheckList] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMStandardTaskCheckList] TO [Viewpoint]
GO
