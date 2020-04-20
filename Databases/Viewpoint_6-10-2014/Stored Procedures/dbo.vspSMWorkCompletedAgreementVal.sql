SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 4/13/12
-- Description:	Validation for SM Work Completed Agreement/Revision fields.
-- Modified:	
--		07/11/13 - ScottAlvey - TFS53479 - Imports use this val and if no Revision input is supplied
--			then it needs to return the current Revision. Added the @AgainstCur to determine if we
--			we need to return the current revision (for imports) or just validate the revision
--			against the agreeemnt
-- =============================================

CREATE PROCEDURE [dbo].[vspSMWorkCompletedAgreementVal]
	@SMCo AS bCompany,
	@WorkOrder as int,
	@Agreement AS varchar(15),
	@Revision int,
	@AgainstCur bYN = NULL,
	@RevisionOut int = NULL OUTPUT,
	@msg AS varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF (@SMCo IS NULL)
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF (@WorkOrder IS NULL)
	BEGIN
		SET @msg = 'Missing Work Order!'
		RETURN 1
	END
	
	IF (@Agreement IS NULL)
	BEGIN
		SET @msg = 'Missing SM Agreement!'
		RETURN 1
	END
		
	-- Verify that the agreement is valid - Will also check Revision if supplied and
	-- return the NEWEST or the CURRENT (based on the value of the @AgainstCur flag) revision if not supplied.
	SELECT TOP 1
		@msg = SMAgreement.[Description],
		@RevisionOut = CASE WHEN ISNULL(@AgainstCur,'N') = 'N' AND @Revision IS NOT NULL THEN SMAgreement.Revision ELSE SMAgreement.CurrentActiveRevision END
	FROM dbo.SMAgreementExtended SMAgreement
	INNER JOIN dbo.SMWorkOrder ON SMWorkOrder.SMCo = SMAgreement.SMCo 
		AND SMWorkOrder.CustGroup = SMAgreement.CustGroup 
		AND SMWorkOrder.Customer = SMAgreement.Customer
	WHERE SMAgreement.SMCo = @SMCo
		AND SMWorkOrder.WorkOrder = @WorkOrder
		AND SMAgreement.Agreement = @Agreement
		AND SMAgreement.Revision = ISNULL(@Revision, SMAgreement.Revision)
		AND SMAgreement.DateActivated IS NOT NULL
	ORDER BY SMAgreement.Revision DESC
    
	IF (@@ROWCOUNT = 0)
	BEGIN
		SELECT @msg = 'Invalid Agreement/Revision for this customer.'
		RETURN 1
	END
    
    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedAgreementVal] TO [public]
GO
