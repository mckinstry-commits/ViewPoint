SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udGeographicLookup] as select a.* From budGeographicLookup a
GO
GRANT SELECT ON  [dbo].[udGeographicLookup] TO [public]
GRANT INSERT ON  [dbo].[udGeographicLookup] TO [public]
GRANT DELETE ON  [dbo].[udGeographicLookup] TO [public]
GRANT UPDATE ON  [dbo].[udGeographicLookup] TO [public]
GO
