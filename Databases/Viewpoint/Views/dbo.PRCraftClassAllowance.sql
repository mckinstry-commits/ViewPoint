SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.PRCraftClassAllowance 
AS
SELECT * FROM dbo.vPRCraftClassAllowance
GO
GRANT SELECT ON  [dbo].[PRCraftClassAllowance] TO [public]
GRANT INSERT ON  [dbo].[PRCraftClassAllowance] TO [public]
GRANT DELETE ON  [dbo].[PRCraftClassAllowance] TO [public]
GRANT UPDATE ON  [dbo].[PRCraftClassAllowance] TO [public]
GO
