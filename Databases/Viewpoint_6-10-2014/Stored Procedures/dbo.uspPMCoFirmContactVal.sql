SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspPMCoFirmContactVal] /** User Defined Validation Procedure **/
@Company bCompany = 0, 
	@Contact bEmployee = 0
	, @msg VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @rcode INT = 0
	, @OurFirm INT
	, @VendorGroup TINYINT
	SELECT @OurFirm = OurFirm FROM PMCO WHERE PMCo = @Company
	SELECT @VendorGroup = VendorGroup FROM HQCO WHERE HQCo = @Company

	IF EXISTS(SELECT TOP 1 1 FROM PMPM WHERE FirmNumber = @OurFirm AND VendorGroup = @VendorGroup AND ContactCode = @Contact)
	BEGIN
		SELECT @msg = FullContactName 
			FROM PMPM2 
			WHERE FirmNumber = @OurFirm AND VendorGroup = @VendorGroup AND ContactCode = @Contact
		GOTO uspexit
	END
	ELSE
	BEGIN
		SELECT @msg = 'Not a valid Contact from firm: '+ CONVERT(VARCHAR(3),@OurFirm)+' - '+FirmName, @rcode=1 
			FROM PMFM WHERE FirmNumber = @OurFirm AND VendorGroup = @VendorGroup
		GOTO uspexit
	END
	uspexit:
	RETURN @rcode
END
GO
GRANT EXECUTE ON  [dbo].[uspPMCoFirmContactVal] TO [public]
GO
