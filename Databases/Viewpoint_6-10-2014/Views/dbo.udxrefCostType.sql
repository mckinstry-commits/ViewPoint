SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefCostType as select a.* From Viewpoint.dbo.budxrefCostType a;
GO
GRANT REFERENCES ON  [dbo].[udxrefCostType] TO [public]
GRANT SELECT ON  [dbo].[udxrefCostType] TO [public]
GRANT INSERT ON  [dbo].[udxrefCostType] TO [public]
GRANT DELETE ON  [dbo].[udxrefCostType] TO [public]
GRANT UPDATE ON  [dbo].[udxrefCostType] TO [public]
GRANT SELECT ON  [dbo].[udxrefCostType] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udxrefCostType] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udxrefCostType] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udxrefCostType] TO [Viewpoint]
GO
