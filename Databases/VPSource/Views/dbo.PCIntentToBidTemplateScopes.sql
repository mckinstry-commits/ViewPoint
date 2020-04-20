SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/*************************************
* Created BY:	
* Modified By:	GF 12/21/2010 - issue #142573 ADDITIONAL SCOPE COLUMNS
*
***************************************/

CREATE VIEW [dbo].[PCIntentToBidTemplateScopes]
AS

SELECT
	CASE WHEN dbo.PCBidPackageScopes.Phase IS NULL THEN PCBidPackageScopes.ScopeCode ELSE PCBidPackageScopes.Phase END AS ScopePhase,
	CASE WHEN dbo.PCBidPackageScopes.Phase IS NULL THEN PCScopeCodes.[Description] ELSE JCPM.[Description] END AS ScopePhaseDescription
FROM dbo.PCBidPackageScopes
LEFT JOIN dbo.PCScopeCodes ON PCBidPackageScopes.VendorGroup = PCScopeCodes.VendorGroup AND PCBidPackageScopes.ScopeCode = PCScopeCodes.ScopeCode
LEFT JOIN dbo.JCPM ON PCBidPackageScopes.PhaseGroup = JCPM.PhaseGroup AND PCBidPackageScopes.Phase = JCPM.Phase










GO
GRANT SELECT ON  [dbo].[PCIntentToBidTemplateScopes] TO [public]
GRANT INSERT ON  [dbo].[PCIntentToBidTemplateScopes] TO [public]
GRANT DELETE ON  [dbo].[PCIntentToBidTemplateScopes] TO [public]
GRANT UPDATE ON  [dbo].[PCIntentToBidTemplateScopes] TO [public]
GO
