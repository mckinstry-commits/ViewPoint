SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udDocLocations] as select a.* From budDocLocations a
GO
GRANT SELECT ON  [dbo].[udDocLocations] TO [public]
GRANT INSERT ON  [dbo].[udDocLocations] TO [public]
GRANT DELETE ON  [dbo].[udDocLocations] TO [public]
GRANT UPDATE ON  [dbo].[udDocLocations] TO [public]
GO
