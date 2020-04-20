SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udProjectBuildings] as select a.* From budProjectBuildings a
GO
GRANT SELECT ON  [dbo].[udProjectBuildings] TO [public]
GRANT INSERT ON  [dbo].[udProjectBuildings] TO [public]
GRANT DELETE ON  [dbo].[udProjectBuildings] TO [public]
GRANT UPDATE ON  [dbo].[udProjectBuildings] TO [public]
GO
