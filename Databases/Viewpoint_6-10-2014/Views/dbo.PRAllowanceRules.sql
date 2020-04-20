SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.PRAllowanceRules 
AS
SELECT * FROM dbo.vPRAllowanceRules 
GO
GRANT SELECT ON  [dbo].[PRAllowanceRules] TO [public]
GRANT INSERT ON  [dbo].[PRAllowanceRules] TO [public]
GRANT DELETE ON  [dbo].[PRAllowanceRules] TO [public]
GRANT UPDATE ON  [dbo].[PRAllowanceRules] TO [public]
GRANT SELECT ON  [dbo].[PRAllowanceRules] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAllowanceRules] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAllowanceRules] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAllowanceRules] TO [Viewpoint]
GO
