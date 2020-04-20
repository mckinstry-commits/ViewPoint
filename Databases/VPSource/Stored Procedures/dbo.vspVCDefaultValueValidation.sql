SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/24/09
-- Description:	Validation for a generic Connects Report parameter.
--				Constants and user/site parameters are valid.
-- =============================================
CREATE PROCEDURE [dbo].[vspVCDefaultValueValidation]
	(@defaultValue AS VARCHAR(60),
	@msg AS VARCHAR(150) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF SUBSTRING(@defaultValue, 1, 1) = '#' AND SUBSTRING(@defaultValue, LEN(@defaultValue), 1) = '#'
	BEGIN
		SET @msg = 'Cache parameters are not applicable at this level of the report'
		RETURN 1
	END
	
	--If we have a matching description in the user/site parameters we display that
	SELECT @msg = Description
	FROM pvPortalParameters
	WHERE KeyField = @defaultValue
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspVCDefaultValueValidation] TO [public]
GO
