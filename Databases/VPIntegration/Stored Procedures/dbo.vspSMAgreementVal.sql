SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 1/11/12
-- Description:	Validation for SM Agreements
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMAgreementVal]
	@SMCo AS bCompany, 
	@Agreement AS varchar(15), 
	@Revision int,
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
	
	IF (@Agreement IS NULL)
	BEGIN
		SET @msg = 'Missing SM Agreement!'
		RETURN 1
	END
	
	SELECT 
		@msg = [Description]
	FROM dbo.SMAgreement
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
    
	IF (@@ROWCOUNT = 0)
	BEGIN
		SELECT @msg = 'Agreement/Revision has not yet been setup in SM Agreement.'
		RETURN 1
	END
    
    RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementVal] TO [public]
GO
