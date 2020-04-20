SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[APOnCostWorkFileDetail]
AS
SELECT     dbo.vAPOnCostWorkFileDetail.*
FROM         dbo.vAPOnCostWorkFileDetail

GO
GRANT SELECT ON  [dbo].[APOnCostWorkFileDetail] TO [public]
GRANT INSERT ON  [dbo].[APOnCostWorkFileDetail] TO [public]
GRANT DELETE ON  [dbo].[APOnCostWorkFileDetail] TO [public]
GRANT UPDATE ON  [dbo].[APOnCostWorkFileDetail] TO [public]
GO
