SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*NOTE: THIS SP DOES NOT RETURN COUNTRY. FOR VENDOR VALIDATION THAT RETURNS
  COUNTRY USE bspAPVendorValWithAddressDflts */ 

/****** Object:  Stored Procedure dbo.bspAPVendorValForAPVM    Script Date: 8/28/99 9:34:06 AM ******/
CREATE PROC [dbo].[bspAPVendorValForAPVM]
(@apco bCompany, 
@vendgroup bGroup = NULL, 
@vendor varchar(15) = NULL, 
@activeopt char(1) = NULL, 
@typeopt char(1) = NULL,
@vendorout bVendor = NULL OUTPUT, 
@payterms bPayTerms = NULL OUTPUT, 
@eft char(1)= NULL OUTPUT,
@v1099yn bYN = NULL OUTPUT,
@v1099Type varchar(10) = NULL OUTPUT, 
@v1099Box tinyint = NULL OUTPUT,
@holdyn bYN = NULL OUTPUT, 
@address varchar(60) = NULL OUTPUT, 
@city varchar(30) = NULL OUTPUT,
@state varchar(4) = NULL OUTPUT, 
@zip bZip = NULL OUTPUT, 
@taxid varchar(12) = NULL OUTPUT,
@taxcode bTaxCode=NULL OUTPUT, 
@POExistsYN bYN = NULL OUTPUT, 
@PCExistsYN bYN = NULL OUTPUT,
@msg varchar(150) OUTPUT)
/***********************************************************
* CREATED BY: ??
* MODIFIED By : GG 06/13/97
* MODIFIED By : EN 11/19/97
* MODIFIED By : SE 2/28/98
* 		        EN 02/23/00 - changed to return message 'Not a Valid Vendor' if vendor couldn't be found either by the vendor number or sort name (was inadvertantly giving a confusing datatype conversion error)
*               kb 1/21/2 - issue #15968
*               kb 10/29/2 - issue #18878 - fix double quotes
*				ES 03/12/04 - #23061 isNULL wrapping
*				MV 06/02/04 - #24723 - validate for length if vendor is numeric. Over 11 char causes arithmetic overflow.
*				MV 03/04/05 - #26388 - set @vendorout to NULL it if comes in 0
*				MV 05/31/05 - #26388 - set @vendor to uppercase when SELECTing by sortname.
*				MV 06/28/06 - #121302 order by sortname
*				MV 03/13/08 - #127347 - changed bState to varchar(4)
*				TJL 10/28/08 - Issue #130622, Auto sequence next Vendor number.
*				KK/EN 07/06/11 - TK-06612, do not allow vendor delete when attached to an open PO
*				KK/EN 07/08/11 - TK-06618, do not allow vendor delete when attached to a Qualified PC
*
* Usage:
*	Used by APVM vendor input to validate the entry by either Sort Name or number.
*	Ignores validation for new vendor numbers.
* 	Checks Active flag and Vendor Type, based on options passed as input params.
*
* Input params:
*	@apco		AP company
*	@vendgroup	Vendor Group
*	@vendor		Vendor sort name or number
*	@activeopt	Controls validation based on Active flag
*			'Y' = must be an active
*			'N' = must be inactive
*			'X' = can be any value
*	@typeopt	Controls validation based on Vendor Type
*			'R' = must be Regular
*			'S' = must be Supplier
*			'X' = can be any value
*
* Output params:
*	@vendorout	Vendor number
*	@payterms       payment terms for this vendor
*  	@eft		'N' = Not used, payments made by check only.
*			    'A' = EFT Active
*			    'P' = PreNote, waiting for confirmation of valid Bank Acct and Transit#s, payments
*				made by check only.'
* 	@v1099yn	Does vendor use 1099
*	@v1099Type	Default type for vendor's 1099
*	@v1099Box	Default box for vendor's 1099
*	@holdyn		Any hold codes in APVH for this vendor?
*	@address	vendor payment address
*	@city		vendor payment city
*	@state		vendor payment state
*	@zip		vendor payment zip
*	@taxid		vendor tax ID
*	@taxcode	vendor tax Code
*	@POExistsYN 'Y' = purchase order exists for this vendor
*   @PCExistsYN 'Y' = qualified pre-construction file exists for this vendor
*	@msg		Vendor Name or error message
*
* Return code:
*	0 = success, 1 = failure
*****************************************************/
AS
SET NOCOUNT ON
DECLARE @type char(1), 
		@active bYN,
		@VendorKeyID bigint

IF @vendorout = 0	-- #26388
BEGIN
	SELECT @vendorout = NULL
END

/* check required input params */
IF @vendgroup IS NULL
BEGIN
	SELECT @msg = 'Missing Vendor Group.'
	RETURN 1
END
IF @vendor IS NULL
BEGIN
	SELECT @msg = 'Missing Vendor.'
	RETURN 1
END
IF @activeopt IS NULL
BEGIN
	SELECT @msg = 'Missing Active option for Vendor validation.'
	RETURN 1
END
IF @typeopt IS NULL
BEGIN
	SELECT @msg = 'Missing Type option for Vendor validation.'
	RETURN 1
END
/* If @vendor is numeric then try to find Vendor number */

/* Auto Numbering for new Vendors */
IF substring(@vendor,1,1) = char(39) AND substring(@vendor,2,1) = '+'
BEGIN	
	IF len(convert(varchar, (SELECT isNULL(Max(Vendor), 0) + 1
							 FROM APVM WITH(NOLOCK) 
							 WHERE VendorGroup = @vendgroup))) > 6
	BEGIN
		SELECT @msg = 'Next Vendor value exceeds the maximum value allowed for this input.'
		SELECT @msg = @msg +'  You must enter a specific Vendor value less than 999999.'
		RETURN 1
	END
	ELSE
	BEGIN
		SELECT @vendorout = isNULL(Max(Vendor), 0) + 1
		FROM APVM WITH(NOLOCK)
		WHERE VendorGroup = @vendgroup
	END
END
ELSE 
BEGIN
	IF dbo.bfIsInteger(@vendor) = 1 and len(@vendor) < 7 --#24723
	BEGIN -- if isnumeric(@vendor) = 1 
		SELECT @vendorout = Vendor, 
			   @VendorKeyID = KeyID,
			   @payterms=PayTerms, 
			   @msg = Name, 
			   @active = ActiveYN, 
			   @type = Type,
			   @eft=EFT, 
			   @v1099yn=V1099YN, 
			   @v1099Type=V1099Type, 
			   @v1099Box=V1099Box, 
			   @address=Address,
			   @city=City, 
			   @state=State, 
			   @zip=Zip, 
			   @taxid=TaxId, 
			   @taxcode=TaxCode
		FROM APVM
		WHERE VendorGroup = @vendgroup AND Vendor = convert(int,convert(float, @vendor))
	END
	
	/* if not numeric or not found try to find as Sort Name */
	IF @vendorout IS NULL
	BEGIN -- if @@rowcount = 0
   		SELECT @vendorout = Vendor, 
   			   @VendorKeyID = KeyID,
   			   @payterms=PayTerms, 
   			   @msg = Name,  
   			   @active = ActiveYN, 
   			   @type = Type,
   			   @eft=EFT, 
   			   @v1099yn=V1099YN, 
   			   @v1099Type=V1099Type, 
   			   @v1099Box=V1099Box, 
   			   @address=Address,
   			   @city=City, 
   			   @state=State, 
   			   @zip=Zip, 
   			   @taxid=TaxId, 
   			   @taxcode=TaxCode
		FROM APVM
		WHERE VendorGroup = @vendgroup and SortName = upper(@vendor) order by SortName
			
		/* if not found, try to find closest */
		IF @@rowcount = 0
		BEGIN
			SET ROWCOUNT 1
			SELECT @vendorout = Vendor, 
				   @VendorKeyID = KeyID,
				   @payterms=PayTerms, 
				   @msg = Name, 
				   @active = ActiveYN, 
				   @type = Type,
   				   @eft=EFT, 
   				   @v1099yn=V1099YN, 
   				   @v1099Type=V1099Type, 
   				   @v1099Box=V1099Box, 
   				   @address=Address,
   				   @city=City, 
   				   @state=State, 
   				   @zip=Zip, 
   				   @taxid=TaxId, 
   				   @taxcode=TaxCode
   			FROM APVM
   			WHERE VendorGroup = @vendgroup AND SortName LIKE upper(@vendor) + '%' ORDER BY SortName
   			IF @@rowcount = 0
    		BEGIN
				SELECT @msg = 'AP Vendor ' + isNULL(Convert(varchar(6), @vendor), '') + ' is not on file.'
   				IF dbo.bfIsInteger(@vendor) = 1 AND len(@vendor) < 7 --#24723
				BEGIN
					SELECT @vendorout = @vendor
				END
   	    		ELSE
				BEGIN
					SELECT @vendorout = NULL
					SELECT @msg = 'Not a valid Vendor.'
   					RETURN 1
				END
   			END
   		END
   	END
   	--TK-06612: Is there an Open PO for this Vendor
	IF EXISTS(SELECT TOP 1 1 FROM dbo.bPOHD
			  WHERE VendorGroup=@vendgroup AND Vendor=@vendorout)
   	BEGIN
   		SELECT @POExistsYN = 'Y'
   	END
   	ELSE
   	BEGIN 
   		SELECT @POExistsYN = 'N'
   	END
   	--TK-06618: Is there a Qualified PC for this Vendor
   	IF EXISTS(SELECT TOP 1 1 FROM dbo.vPCQualifications
			  WHERE APVMKeyID=@VendorKeyID)
   	BEGIN
   		SELECT @PCExistsYN = 'Y'
   	END
   	ELSE
   	BEGIN 
   		SELECT @PCExistsYN = 'N'
   	END
END

IF @typeopt <> 'X' AND @type <> @typeopt
BEGIN
	SELECT @msg='Invalid type option!'
	IF @typeopt = 'R' SELECT @msg = 'Must be a regular Vendor.'
	IF @typeopt = 'S' SELECT @msg = 'Must be a Supplier.'
	RETURN 1
END

IF @activeopt <> 'X' and @active <> @activeopt
BEGIN
	SELECT @msg='Invalid active status!'
	IF @activeopt = 'Y' SELECT @msg = 'Must be an active Vendor.'
	IF @activeopt = 'N' SELECT @msg = 'Must be an inactive Vendor.'
	RETURN 1
END

IF EXISTS(SELECT * FROM bAPVH 
		  WHERE APCo=@apco 
			AND VendorGroup=@vendgroup 
			AND Vendor=@vendorout)
BEGIN
	SELECT @holdyn='Y'
END
ELSE
BEGIN
	SELECT @holdyn='N'
END
   	
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspAPVendorValForAPVM] TO [public]
GO
