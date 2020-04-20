SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefEMCostCodes as select a.* From Viewpoint.dbo.budxrefEMCostCodes a;
GO
GRANT REFERENCES ON  [dbo].[udxrefEMCostCodes] TO [public]
GRANT SELECT ON  [dbo].[udxrefEMCostCodes] TO [public]
GRANT INSERT ON  [dbo].[udxrefEMCostCodes] TO [public]
GRANT DELETE ON  [dbo].[udxrefEMCostCodes] TO [public]
GRANT UPDATE ON  [dbo].[udxrefEMCostCodes] TO [public]
GRANT SELECT ON  [dbo].[udxrefEMCostCodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udxrefEMCostCodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udxrefEMCostCodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udxrefEMCostCodes] TO [Viewpoint]
GO
