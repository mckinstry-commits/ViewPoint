SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPCValidateYearField]
	(@Year SMALLINT)
AS
SET NOCOUNT ON;

BEGIN
	DECLARE @rcode INT, @msg VARCHAR(255), @MinYear SMALLINT, @MaxYear SMALLINT
	SELECT @rcode = 0, @MinYear = 1900, @MaxYear = 2999
	
	-- Validation
	IF @Year < @MinYear OR @Year > @MaxYear
	BEGIN
		SELECT @rcode = 1, @msg = 'Invalid year value.  The year must be ' + CONVERT(VARCHAR, @MinYear) + ' and ' + CONVERT(VARCHAR, @MaxYear) + '.'
		RAISERROR(@msg, 11, -1);
	END
	
	return @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCValidateYearField] TO [VCSPortal]
GO
