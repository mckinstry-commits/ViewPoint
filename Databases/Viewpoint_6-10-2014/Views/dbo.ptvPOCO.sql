SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPOCO]
AS
SELECT POCO.POCo, HQCO.Name
FROM POCO with (nolock)
	INNER JOIN HQCO with (nolock) ON (POCO.POCo = HQCO.HQCo)

GO
GRANT SELECT ON  [dbo].[ptvPOCO] TO [public]
GRANT INSERT ON  [dbo].[ptvPOCO] TO [public]
GRANT DELETE ON  [dbo].[ptvPOCO] TO [public]
GRANT UPDATE ON  [dbo].[ptvPOCO] TO [public]
GRANT SELECT ON  [dbo].[ptvPOCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ptvPOCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ptvPOCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ptvPOCO] TO [Viewpoint]
GO
