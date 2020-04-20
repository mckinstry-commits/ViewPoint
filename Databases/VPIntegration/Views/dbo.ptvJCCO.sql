SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvJCCO] AS

-- JC Company 

SELECT JCCO.JCCo, HQCO.Name

FROM JCCO with (nolock)
	INNER JOIN HQCO with (nolock)ON (JCCO.JCCo = HQCO.HQCo)

GO
GRANT SELECT ON  [dbo].[ptvJCCO] TO [public]
GRANT INSERT ON  [dbo].[ptvJCCO] TO [public]
GRANT DELETE ON  [dbo].[ptvJCCO] TO [public]
GRANT UPDATE ON  [dbo].[ptvJCCO] TO [public]
GO
