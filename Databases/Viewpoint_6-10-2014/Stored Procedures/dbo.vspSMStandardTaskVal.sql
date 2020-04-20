SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 12/12/11
-- Description:	Validation for SM Standard Task
-- Modified:	EricV 07/06/12 Added output parameters of Name and Description
-- =============================================

CREATE PROCEDURE [dbo].[vspSMStandardTaskVal]
	@SMCo AS bCompany, 
	@StandardTask AS varchar(15), 
	@Name AS varchar(25) = NULL OUTPUT,
	@Description AS varchar(max) = NULL OUTPUT,
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
	
	IF (@StandardTask IS NULL)
	BEGIN
		SET @msg = 'Missing SM Standard Task!'
		RETURN 1
	END
	
	SELECT @msg = [Name], @Name = [Name], @Description = Description
	FROM dbo.SMStandardTask 
	WHERE SMCo = @SMCo AND SMStandardTask = @StandardTask
	
	IF (@@ROWCOUNT = 0)
    BEGIN
		SET @msg = 'Standard Task has not been setup in SM Standard Task.'
		RETURN 1
    END
    
    RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMStandardTaskVal] TO [public]
GO
