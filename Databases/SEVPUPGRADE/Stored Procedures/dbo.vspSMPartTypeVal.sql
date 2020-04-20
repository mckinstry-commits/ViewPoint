SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/23/11
-- Description:	Validation for SM Part Types
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMPartTypeVal]
	@SMCo AS bCompany, @SMPartType AS varchar(15), @msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	IF (@SMCo IS NULL)
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF (@SMPartType IS NULL)
	BEGIN
		SET @msg = 'Missing SM Part Type!'
		RETURN 1
	END
	
	SELECT @msg = [Description]
	FROM dbo.SMPartType
	WHERE SMCo = @SMCo AND SMPartType = @SMPartType
	
    IF (@@ROWCOUNT = 0)
    BEGIN
		SET @msg = 'Part type has not been setup in SM Part Type.'
		RETURN 1
    END
    
    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMPartTypeVal] TO [public]
GO
