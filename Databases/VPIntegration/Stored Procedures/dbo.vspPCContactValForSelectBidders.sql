SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspPCContactValForSelectBidders]
/*************************************
*  Created:		CHS 02/10/2010
* 
*  PC Contact validation
* 
*  Inputs:
*	@vendgroup:		vendorgroup
*	@vendor:		vendor number/vendor name/search for vendor name
*	@contact:		contact
* 
*  Outputs:
*	 @msg:			contact name
* 
* Error returns:
*	0 and contact name
*	1 and error message
**************************************/
(@vendgroup bGroup = NULL, 
	@vendor int = NULL, 
	@contact tinyint = NULL, 
	@msg VARCHAR(255) OUTPUT)
	
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rcode INT
	SELECT @rcode = 0
	
	-- Check required input params
	IF @vendgroup IS NULL
   	BEGIN
		SELECT @msg = 'Missing Vendor Group.', @rcode = 1
   		GOTO VspExit
   	END
   	
	IF @contact IS NULL
   	BEGIN
   		SELECT @msg = 'Missing Contact.', @rcode = 1
   		GOTO VspExit
   	END   	
   	
   	IF NOT EXISTS (select top 1 1 FROM PCContacts WITH (NOLOCK) WHERE VendorGroup = @vendgroup and Seq = @contact)
   	BEGIN
   	   	SELECT @msg = 'PC Contact ' + cast(@contact as varchar(10)) + ' not valid.', @rcode = 1
   		GOTO VspExit
   	END
   	
   	-- get and return the contact name if vendor is null
   	IF @vendor IS NULL
   	BEGIN
   		--SELECT select top 1 @msg = Name
  		--FROM PCContacts WITH (NOLOCK)
  		--WHERE VendorGroup = @vendgroup and Seq = @contact
   	   	GOTO VspExit
   	END 
   	
	-- get and return the contact name
	SELECT @msg = Name
	FROM PCContacts WITH (NOLOCK)
	WHERE VendorGroup = @vendgroup AND Vendor = @vendor and Seq = @contact
		

	VspExit:
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspPCContactValForSelectBidders] TO [public]
GO
