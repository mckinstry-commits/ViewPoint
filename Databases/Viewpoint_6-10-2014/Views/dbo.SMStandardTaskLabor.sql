SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMStandardTaskLabor]
AS
SELECT    *
FROM         dbo.vSMStandardTaskLabor

GO
GRANT SELECT ON  [dbo].[SMStandardTaskLabor] TO [public]
GRANT INSERT ON  [dbo].[SMStandardTaskLabor] TO [public]
GRANT DELETE ON  [dbo].[SMStandardTaskLabor] TO [public]
GRANT UPDATE ON  [dbo].[SMStandardTaskLabor] TO [public]
GRANT SELECT ON  [dbo].[SMStandardTaskLabor] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMStandardTaskLabor] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMStandardTaskLabor] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMStandardTaskLabor] TO [Viewpoint]
GO
