SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 1/25/12
-- Description:	Get a list of revisions for a specified agreement.
-- Modified:	
-- =============================================

CREATE FUNCTION [dbo].[vfSMAgreementGetRevisions]
(
	@SMCo AS bCompany, 
	@Agreement AS varchar(15)
)
RETURNS TABLE
AS
RETURN
(
	SELECT Revision, DisplayValue, EffectiveDate, EndDate
	FROM dbo.SMAgreementExtended
		INNER JOIN dbo.DDCI ON DDCI.ComboType = 'SMAgreementStatus' AND DDCI.DatabaseValue = SMAgreementExtended.RevisionStatus
	WHERE SMAgreementExtended.SMCo = @SMCo AND SMAgreementExtended.Agreement = @Agreement
)
GO
GRANT SELECT ON  [dbo].[vfSMAgreementGetRevisions] TO [public]
GO
