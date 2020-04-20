SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.PRAUEmployerETP
AS
SELECT     PRCo, TaxYear, BranchNbr, SignatureOfAuthPerson, Date, LockETPAmounts, Notes, KeyID, UniqueAttchID
FROM         dbo.vPRAUEmployerETP

GO
GRANT SELECT ON  [dbo].[PRAUEmployerETP] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerETP] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerETP] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerETP] TO [public]
GRANT SELECT ON  [dbo].[PRAUEmployerETP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAUEmployerETP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAUEmployerETP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAUEmployerETP] TO [Viewpoint]
GO
