SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRPretaxEDLLookup]
AS
select PRCo, bPRDL.DLType as [EDLType], bPRDL.DLCode as [EDLCode], bPRDL.Description, bPRDL.PreTax as [PreTax] from bPRDL
union
Select PRCo, 'E' as [EDLType], bPREC.EarnCode as [EDLCode], bPREC.Description, 'Y' as [PreTax] from bPREC


GO
GRANT SELECT ON  [dbo].[PRPretaxEDLLookup] TO [public]
GRANT INSERT ON  [dbo].[PRPretaxEDLLookup] TO [public]
GRANT DELETE ON  [dbo].[PRPretaxEDLLookup] TO [public]
GRANT UPDATE ON  [dbo].[PRPretaxEDLLookup] TO [public]
GO
