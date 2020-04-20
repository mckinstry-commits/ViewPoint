SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Jeremiah Barkley>
-- Create date: <1/20/09>
-- Description:	<PCStatesUpdate Script>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCStatesUpdate]
	-- Add the parameters for the stored procedure here
	(@Original_KeyID INT, @Country CHAR(2), @State VARCHAR(30), @License VARCHAR(60), @Expiration bDate, @SalesTaxNo VARCHAR(60), @UINo VARCHAR(60))
AS
SET NOCOUNT ON;

BEGIN
	-- Validation
	DECLARE @rcode INT
	
	EXEC @rcode = vpspPCValidateStateCountry @State, @Country
	IF @rcode != 0
	BEGIN
		GOTO vpspExit
	END
	
	-- Validation successful
	UPDATE PCStates
	SET
		Country = @Country,
		[State] = @State,
		License = @License,
		Expiration = @Expiration,
		SalesTaxNo = @SalesTaxNo,
		UINo = @UINo
	WHERE KeyID = @Original_KeyID

vpspExit:
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCStatesUpdate] TO [VCSPortal]
GO
