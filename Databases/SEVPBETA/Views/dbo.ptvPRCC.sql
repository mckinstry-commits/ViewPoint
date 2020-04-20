SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPRCC]
AS

-- PR Crafts
SELECT PRCC.Class, PRCC.Description, PRCC.PRCo, PRCC.Craft

FROM PRCC with (nolock)

GO
GRANT SELECT ON  [dbo].[ptvPRCC] TO [public]
GRANT INSERT ON  [dbo].[ptvPRCC] TO [public]
GRANT DELETE ON  [dbo].[ptvPRCC] TO [public]
GRANT UPDATE ON  [dbo].[ptvPRCC] TO [public]
GO
