SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[vspAPVendorSortNameValForSL]
/***********************************************************
* CREATED BY:	GF 10/01/2012 TK-18283
* MODIFIED By: 
*
* USAGE:
* validates Vendor Sort Name for SL Updates to AP Transaction and AP Unapproved Invoices.
* A beginning and ending vendor sort name range is an option in the AP update process
* forms. The sort name range requires the sort name, not the vendor number, so needed
* as an output
*
* an error is returned if any of the following occurs
* Vendor not found
*
* INPUT PARAMETERS
* VendorGroup		AP Vendor Group
* VendorSortName	Vendor Sort Name
*
* OUTPUT PARAMETERS
* CustomerOutput	vendor number
* SortNameOutput	vendor sort name
* @msg      error message if error occurs, otherwise Name of vendor
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/
(@VendorGroup tinyint = null, @Vendor bSortName,
 @VendorOutput bVendor output, @SortNameOutput bSortName OUTPUT,
 @msg varchar(255) output)
AS
SET NOCOUNT ON

DECLARE @rcode int, @SortNameChk bSortName
   
SET @rcode = 0
SET @VendorOutput = NULL
SET @SortNameOutput = NULL

IF @VendorGroup IS NULL
	BEGIN
	SELECT @msg = 'Missing Vendor Group!', @rcode = 1
	GOTO vspexit
	END
	
IF @Vendor IS NULL
	BEGIN
	SELECT @msg = 'Missing Vendor!', @rcode = 1
	goto vspexit
	END
 
/* If @Vendor input by user is numeric and is also the correct length allowed
	by bVendor Mask (max 6), then check for existing record in APVM.  No sense checking
	otherwise. */
	
IF ISNUMERIC(@Vendor) <> 0	-- If IsNumeric is True
	AND LEN(@Vendor) < 7		-- Maximum allowed by bVendor Mask #####0
  	BEGIN
  	/* Validate Vendor to make sure it is valid to post entries to */
  	SELECT @VendorOutput = Vendor,
  			@msg=Name,
  			@SortNameOutput = SortName
	FROM dbo.bAPVM with (nolock)
	WHERE VendorGroup = @VendorGroup
		AND Vendor = convert(int,convert(float, @Vendor))
	END

/* If @VendorOutput is null, then it was not looked for or found above.  We now
	will treat the Vendor input as a SortName and look for it as such. */
IF @VendorOutput IS NULL
	BEGIN	/* Begin SortName Check */
   	SET @SortNameChk = @Vendor
   
   	SELECT @VendorOutput = Vendor,
   			@msg=Name,
   			@SortNameOutput = SortName
   	FROM dbo.bAPVM with (nolock)
   	WHERE VendorGroup = @VendorGroup
   		AND SortName = @SortNameChk
   	IF @@ROWCOUNT = 0
		BEGIN
		/* Begin Approximate SortName Check */		
   		/* Approximate SortName Check.  Input is neither numeric or an exact SortName match. */
   		/* If not an exact SortName then bring back the first one that is close to a match.  */
   	   	SET @SortNameChk = @SortNameChk + '%'
   
   	   	SELECT TOP 1 @VendorOutput = Customer,
   	   				 @msg=Name,
   	   				 @SortNameOutput = SortName
   		FROM dbo.bAPVM with (nolock)
   		WHERE CustGroup = @VendorGroup
   			AND SortName LIKE @SortNameChk
   		ORDER BY Vendor	
   	   	IF @@ROWCOUNT = 0   /* if there is not a match then display message */
   	   		BEGIN
   	     	SELECT @msg = 'Vendor is not valid!', @rcode = 1
   			GOTO vspexit
   			END
   	 	END		/* End Approximate SortName Check */
	END		/* End SortName Check */
   
   



vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspAPVendorSortNameValForSL] TO [public]
GO
