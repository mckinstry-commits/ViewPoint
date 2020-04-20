SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Jeremiah Barkley>
-- Create date: <1/20/09>
-- Description:	<PCStatesInsert Script>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCStatesInsert]
	(@Vendor bVendor, @VendorGroup bGroup, @Country CHAR(2), @State VARCHAR(30), @License VARCHAR(60), @Expiration bDate, @SalesTaxNo VARCHAR(60), @UINo VARCHAR(60))
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
	INSERT INTO PCStates
		(Vendor, VendorGroup, Country, [State], License, Expiration, SalesTaxNo, UINo)
	VALUES
		(@Vendor, @VendorGroup, @Country, @State, @License, @Expiration, @SalesTaxNo, @UINo)
		
vpspExit:
	RETURN @rcode
END


GO
GRANT EXECUTE ON  [dbo].[vpspPCStatesInsert] TO [VCSPortal]
GO
