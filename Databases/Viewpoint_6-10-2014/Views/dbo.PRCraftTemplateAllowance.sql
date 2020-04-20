SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.PRCraftTemplateAllowance 
AS
SELECT * FROM dbo.vPRCraftTemplateAllowance
GO
GRANT SELECT ON  [dbo].[PRCraftTemplateAllowance] TO [public]
GRANT INSERT ON  [dbo].[PRCraftTemplateAllowance] TO [public]
GRANT DELETE ON  [dbo].[PRCraftTemplateAllowance] TO [public]
GRANT UPDATE ON  [dbo].[PRCraftTemplateAllowance] TO [public]
GRANT SELECT ON  [dbo].[PRCraftTemplateAllowance] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCraftTemplateAllowance] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCraftTemplateAllowance] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCraftTemplateAllowance] TO [Viewpoint]
GO
