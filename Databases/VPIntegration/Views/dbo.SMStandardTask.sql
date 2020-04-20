SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[SMStandardTask]
AS
SELECT     dbo.vSMStandardTask.*
FROM         dbo.vSMStandardTask
GO
GRANT SELECT ON  [dbo].[SMStandardTask] TO [public]
GRANT INSERT ON  [dbo].[SMStandardTask] TO [public]
GRANT DELETE ON  [dbo].[SMStandardTask] TO [public]
GRANT UPDATE ON  [dbo].[SMStandardTask] TO [public]
GO
