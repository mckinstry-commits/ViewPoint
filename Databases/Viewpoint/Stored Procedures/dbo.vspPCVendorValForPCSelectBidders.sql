SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspPCVendorValForPCSelectBidders]
/*************************************
*  Created:		CHS 02/10/2010
*
*  PC Vendor validation
*
*  Inputs:
*	@vendgroup:		vendorgroup
*	@vendor:		vendor number/vendor name/search for vendor name
*
*  Outputs:
*	 @vendorout:	vendor number
*
* Error returns:
*	0 and vendor name
*	1 and error message
**************************************/
(@vendgroup bGroup = NULL, 
	@vendor VARCHAR(15) = NULL, 
	@vendorout bVendor = NULL OUTPUT,
	@msg VARCHAR(150) OUTPUT)
	
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rcode INT, @vendorAsInt INT
	SELECT @rcode = 0, @vendorAsInt = NULL
	

	BEGIN TRY
		-- Try to convert the vendor input into an integer
		SET @vendorAsInt = CAST(@vendor AS INT)
		
		-- If we were succesful at converting try finding based on the vendor number
		SELECT @vendorout = Vendor, @msg = Name
		FROM PCQualifications WITH (NOLOCK)
		WHERE VendorGroup = @vendgroup AND Vendor = @vendorAsInt
		
		IF NOT @vendorout IS NULL
		BEGIN
			GOTO VspExit
		END
	END TRY
	BEGIN CATCH
	END CATCH

	-- Either the vendor input is not an int or there doesn't exist a vendor with the vendor number
	-- Therefore try to find a vendor by the SortName
	SELECT @vendorout = Vendor, @msg = Name
	FROM PCQualifications WITH (NOLOCK)
	WHERE VendorGroup = @vendgroup AND SortName = UPPER(@vendor)
	
	IF NOT @vendorout IS NULL
	BEGIN
		GOTO VspExit
	END
	
	-- We didn't find a vendor by the exact vendor name
	-- Therefore do a search to find the first record that is as close as possible
	SELECT TOP 1 @vendorout = Vendor, @msg = Name
	FROM PCQualifications WITH (NOLOCK)
	WHERE VendorGroup = @vendgroup AND SortName LIKE UPPER(@vendor) + '%' ORDER BY SortName
	
	IF NOT @vendorout IS NULL
	BEGIN
		GOTO VspExit
	END
	
	IF NOT @vendorAsInt IS NULL
	BEGIN
		-- Our vendor input turned out to be an INT so allow the user to create a new vendor record
		SELECT @msg = 'AP Vendor ' + ISNULL(@vendor, '') + ' is not on file.', @vendorout = @vendor, @rcode = 1
		GOTO VspExit
	END
	
	/* Check required input params now. Done here so we don't waste time checking these on code that is working properly */
	IF @vendgroup IS NULL
   	BEGIN
		SELECT @msg = 'Missing Vendor Group.', @rcode = 1
   		GOTO VspExit
   	END
	IF @vendor IS NULL
   	BEGIN
   		SELECT @msg = 'Missing Vendor.', @rcode = 1
   		GOTO VspExit
   	END
   	
	-- No vendors found and inputs were valid
	SELECT @msg = 'Not a valid Vendor.', @rcode = 1


	VspExit:
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspPCVendorValForPCSelectBidders] TO [public]
GO
