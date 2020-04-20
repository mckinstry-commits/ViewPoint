SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCraftMasterAllowance] as select a.* From vPRCraftMasterAllowance a

GO
GRANT SELECT ON  [dbo].[PRCraftMasterAllowance] TO [public]
GRANT INSERT ON  [dbo].[PRCraftMasterAllowance] TO [public]
GRANT DELETE ON  [dbo].[PRCraftMasterAllowance] TO [public]
GRANT UPDATE ON  [dbo].[PRCraftMasterAllowance] TO [public]
GO
