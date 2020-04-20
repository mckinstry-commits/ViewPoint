SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--TRL 11/14/2011 TK-09986 Added VendorGroup to Join State to prevent duplicate rows
--				TK-15926 Sequence needs to be cast as varchar
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCScopesGet]
	-- Add the parameters for the stored procedure here
	(@VendorGroup bGroup, @Vendor bVendor, @JCCo INT, @Seq TINYINT = NULL)
AS
SET NOCOUNT ON;

BEGIN
	SELECT 
		PCScopes.[VendorGroup] AS Key_VendorGroup
		,[Vendor]  AS Key_Vendor
		----TK-15926
		,CAST([Seq] AS VARCHAR(3)) AS Key_Seq 
		----,CONVERT(TINYINT, [Seq] + 0) AS Key_Seq
		,[PhaseCode]
		,PCScopes.[ScopeCode]
		,[SelfPerformed]
		--,CASE WHEN SelfPerformed = 'Y' THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS SelfPerformed
		,dbo.vpfYesNo(SelfPerformed) AS SelfPerformedDescription
		,[WorkPrevious]
		,[WorkNext]
		,[NoPriorWork]
		,dbo.vpfYesNo(NoPriorWork) AS NoPriorWorkDescription
		,PCScopes.[KeyID]
		,PCScopes.[PhaseGroup]
		,pcsc.Description AS ScopeCodeDescription
		,jcpm.Description AS PhaseCodeDescription
		,@JCCo AS JCCo
	FROM dbo.PCScopes
	LEFT JOIN dbo.PCScopeCodes pcsc ON PCScopes.VendorGroup = pcsc.VendorGroup and PCScopes.ScopeCode = pcsc.ScopeCode
	LEFT JOIN JCPM jcpm ON PCScopes.PhaseCode = jcpm.Phase AND PCScopes.PhaseGroup = jcpm.PhaseGroup
	WHERE PCScopes.VendorGroup = @VendorGroup AND PCScopes.Vendor = @Vendor AND (PCScopes.Seq = @Seq OR @Seq IS NULL)
END



GO
GRANT EXECUTE ON  [dbo].[vpspPCScopesGet] TO [VCSPortal]
GO
