SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPCValidateStateCountry]
	(@State VARCHAR(4), @Country VARCHAR(2))
AS
SET NOCOUNT ON;

BEGIN
	DECLARE @rcode INT, @msg VARCHAR(255)
	SELECT @rcode = 0

	IF NOT @State IS NULL AND NOT @Country IS NULL
	BEGIN
		IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[bHQST] WHERE [State] = @State AND [Country] = @Country)
		BEGIN
			SELECT @rcode = 1, @msg = @State + ' and ' + @Country + ' is an invalid State/Country combination.'
			RAISERROR(@msg, 11, -1);
		END
	END
	RETURN @rcode
END




GO
GRANT EXECUTE ON  [dbo].[vpspPCValidateStateCountry] TO [VCSPortal]
GO
