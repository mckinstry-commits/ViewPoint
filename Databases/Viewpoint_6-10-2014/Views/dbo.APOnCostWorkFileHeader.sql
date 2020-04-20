SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[APOnCostWorkFileHeader]
AS
SELECT     dbo.vAPOnCostWorkFileHeader.*
FROM         dbo.vAPOnCostWorkFileHeader

GO
GRANT SELECT ON  [dbo].[APOnCostWorkFileHeader] TO [public]
GRANT INSERT ON  [dbo].[APOnCostWorkFileHeader] TO [public]
GRANT DELETE ON  [dbo].[APOnCostWorkFileHeader] TO [public]
GRANT UPDATE ON  [dbo].[APOnCostWorkFileHeader] TO [public]
GRANT SELECT ON  [dbo].[APOnCostWorkFileHeader] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APOnCostWorkFileHeader] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APOnCostWorkFileHeader] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APOnCostWorkFileHeader] TO [Viewpoint]
GO
