SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 1/24/12
-- Description:	Validates a SM Agreement Service
-- =============================================
CREATE PROCEDURE [dbo].[vspSMAgreementServiceVal]
	@SMCo bCompany, 
	@Agreement varchar(15), 
	@Revision int, 
	@Service int,
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN

	SET NOCOUNT ON
	
	SELECT @msg = 
	CASE 
		WHEN @SMCo IS NULL THEN 'Missing SM Company!'
		WHEN @Agreement IS NULL THEN 'Missing Agreement!'
		WHEN @Revision IS NULL THEN 'Missing Revision!'
		WHEN @Service IS NULL THEN 'Missing Seq!'
	END
	
	IF @msg IS NOT NULL
	BEGIN
		RETURN 1
	END
	
	SELECT @msg = [Description]
	FROM dbo.SMAgreementService
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND [Service] = @Service
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = 'Agreement service has not been setup.'
		RETURN 1
    END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementServiceVal] TO [public]
GO
