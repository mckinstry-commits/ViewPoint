SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPRCO]
AS
SELECT PRCO.PRCo, HQCO.Name
FROM PRCO with (nolock)
	INNER JOIN HQCO with (nolock) ON (PRCO.PRCo = HQCO.HQCo)

GO
GRANT SELECT ON  [dbo].[ptvPRCO] TO [public]
GRANT INSERT ON  [dbo].[ptvPRCO] TO [public]
GRANT DELETE ON  [dbo].[ptvPRCO] TO [public]
GRANT UPDATE ON  [dbo].[ptvPRCO] TO [public]
GRANT SELECT ON  [dbo].[ptvPRCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ptvPRCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ptvPRCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ptvPRCO] TO [Viewpoint]
GO
