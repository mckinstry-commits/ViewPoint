SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefEMCostType as select a.* From Viewpoint.dbo.budxrefEMCostType a;
GO
GRANT REFERENCES ON  [dbo].[udxrefEMCostType] TO [public]
GRANT SELECT ON  [dbo].[udxrefEMCostType] TO [public]
GRANT INSERT ON  [dbo].[udxrefEMCostType] TO [public]
GRANT DELETE ON  [dbo].[udxrefEMCostType] TO [public]
GRANT UPDATE ON  [dbo].[udxrefEMCostType] TO [public]
GO
