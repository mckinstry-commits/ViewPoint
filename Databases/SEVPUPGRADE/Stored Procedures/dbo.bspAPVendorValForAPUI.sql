SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[bspAPVendorValForAPUI]
(@apco bCompany, 
 @vendgroup bGroup = NULL, 
 @vendor varchar(15) = NULL, 
 @activeopt char(1) = NULL,
 @typeopt char(1) = NULL, 
 @invdate bDate = NULL, 
 @vendorout bVendor = NULL OUTPUT, 
 @payterms bPayTerms = NULL OUTPUT,
 @eft char(1) = NULL OUTPUT,
 @v1099yn bYN = NULL OUTPUT,
 @v1099Type varchar(10) = NULL OUTPUT,
 @v1099Box tinyint = NULL OUTPUT,
 @holdyn bYN = NULL OUTPUT, 
 @addnlinfo varchar(60) = NULL OUTPUT,
 @address varchar(60) = NULL OUTPUT, 
 @city varchar(30) = NULL OUTPUT,
 @state varchar(4) = NULL OUTPUT,
 @zip bZip = NULL OUTPUT, 
 @country char(2) = NULL OUTPUT, 
 @taxid varchar(12) = NULL OUTPUT,
 @taxcode bTaxCode = NULL OUTPUT,
 @apvmrefunqovr int = NULL OUTPUT, 
 @SeparatePayInvYN bYN OUTPUT,
 @complied bYN = NULL OUTPUT,
 @cmacct bCMAcct OUTPUT, 
 @paycontrol varchar(10) OUTPUT, 
 @VendorABN varchar(20) OUTPUT,  
 @paymethod char(1) = NULL OUTPUT,
 @msg varchar(60) OUTPUT)
/***********************************************************
* CREATED BY: ??
* MODIFIED By : GG 06/13/97
* MODIFIED By : EN 11/19/97
* MODIFIED By : SE 2/28/98
*               EN 1/22/00 - include AddnlInfo in output params
*			  	 MV 8/21/02 - include APRefUnqOvr from bAPVM for issue 18314
*               TV 09/24/02 - ADDED @SeparatePayInv to pass back to form
*               kb 10/29/2 - issue #18878 - fix double quotes
*			  	 MV 01/16/03 - #17821 - all invoice compliance checking
*				 MV 06/03/04 - #24723 - validate vendor for length.
*				MV 06/28/06 - #121302 order by SortName, upper(@vendor) 
*				MV 03/13/08 - #127347 - changed bState to varchar(4)
*				TJL 03/25/08 - #127347 Intl addresses 
*		TJL 02/04/09 - Issue #124739, Add CMAcct in APVM as default
*				MV 10/07/09 - #131826 return PayControl
*			CHS	09/29/2011	-	B-04930 - added ABN	
*			CHS	10/17/2011	-	D-03197 - fixed ABN		
*			EN 01/10/2012 B-08098 added APVM_PayMethod to output param list 
*									and reformatted code as per best practice
*
* Usage:
*	Used by most Vendor inputs to validate the entry by either Sort Name or number.
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
*			'A' = EFT Active
*			'P' = PreNote, waiting for confirmation of valid Bank Acct and Transit#s, payments
*				made by check only.'
* 	@v1099yn	Does vendor use 1099
*	@v1099Type	Default type for vendor's 1099
*	@v1099Box	Default box for vendor's 1099
*	@holdyn		Any hold codes in APVH for this vendor?
*  @addnlinfo  vendor additional info
*	@address	vendor payment address
*	@city		vendor payment city
*	@state		vendor payment state
*	@zip		vendor payment zip
*	@country	vendor payment country
*	@taxid		vendor tax ID
*	@taxcode	vendor tax Code
*	@paymethod	vendor payment method
*	@msg		Vendor Name or error message
*   @apvmrefunqovr APRefUnqOvr from bAPVM
*
* Return code:
*	0 = success, 1 = failure
*****************************************************/
AS
SET NOCOUNT ON

DECLARE @type char(1), 
		@active bYN, 
		@rc int, 
		@allcompchkyn bYN
		
SELECT @rc = 0

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
IF dbo.bfIsInteger(@vendor) = 1 AND LEN(@vendor) < 7 --#24723
BEGIN
	SELECT @vendorout = Vendor, 
		   @payterms = PayTerms, 
		   @msg = Name, 
		   @active = ActiveYN, 
		   @type = [Type],
		   @eft = EFT, 
		   @v1099yn = V1099YN, 
		   @v1099Type = V1099Type, 
		   @v1099Box = V1099Box,
		   @addnlinfo = AddnlInfo, 
		   @address = [Address],
		   @city = City, 
		   @state = [State],
		   @zip = Zip, 
		   @country = Country, 
		   @taxid = TaxId, 
		   @taxcode = TaxCode, 
		   @apvmrefunqovr = APRefUnqOvr, 
		   @SeparatePayInvYN = SeparatePayInvYN, 
		   @cmacct = CMAcct, 
		   @paycontrol = PayControl,
		   @VendorABN = AusBusNbr, 
		   @paymethod = PayMethod
	FROM dbo.APVM
	WHERE VendorGroup = @vendgroup AND Vendor = CONVERT(int, CONVERT(float, @vendor))
END
/* if not numeric or not found try to find as Sort Name */
IF @vendorout IS NULL	-- #24723
-- if @@rowcount = 0
BEGIN
	SELECT @vendorout = Vendor, 
		   @payterms = PayTerms, 
		   @msg = Name,  
		   @active = ActiveYN, 
		   @type = [Type],
		   @eft = EFT, 
		   @v1099yn = V1099YN, 
		   @v1099Type = V1099Type, 
		   @v1099Box = V1099Box,
		   @addnlinfo = AddnlInfo, 
		   @address = [Address],
		   @city = City, 
		   @state = [State],
		   @zip = Zip, 
		   @country = Country, 
		   @taxid = TaxId, 
		   @taxcode = TaxCode, 
		   @apvmrefunqovr = APRefUnqOvr, 
		   @SeparatePayInvYN = SeparatePayInvYN, 
		   @cmacct = CMAcct, 
		   @paycontrol = PayControl,
		   @VendorABN = AusBusNbr, 
		   @paymethod = PayMethod
	FROM dbo.APVM
	WHERE VendorGroup = @vendgroup AND SortName = UPPER(@vendor) ORDER BY SortName
	
	/* if not found,  try to find closest */
	IF @@rowcount = 0
	BEGIN
		SET ROWCOUNT 1
		SELECT @vendorout = Vendor, 
			   @payterms = PayTerms, 
			   @msg = Name, 
			   @active = ActiveYN, 
			   @type = [Type],
			   @eft = EFT, 
			   @v1099yn = V1099YN, 
			   @v1099Type = V1099Type, 
			   @v1099Box = V1099Box,
			   @addnlinfo = AddnlInfo, 
			   @address = [Address],
			   @city = City, 
			   @state = [State],
			   @zip = Zip, 
			   @country = Country, 
			   @taxid = TaxId, 
			   @taxcode = TaxCode, 
			   @apvmrefunqovr = APRefUnqOvr, 
			   @SeparatePayInvYN = SeparatePayInvYN, 
			   @cmacct = CMAcct, 
			   @paycontrol = PayControl,
			   @VendorABN = AusBusNbr, 
			   @paymethod = PayMethod
		FROM dbo.APVM
		WHERE VendorGroup = @vendgroup AND SortName LIKE UPPER(@vendor) + '%' ORDER BY SortName
		IF @@rowcount = 0
		BEGIN
			SELECT @msg = 'Not a valid Vendor'
			RETURN 1
		END
	END
END

IF @typeopt <> 'X' AND @type <> @typeopt
BEGIN
	SELECT @msg='Invalid type option!'
	IF @typeopt = 'R' SELECT @msg = 'Must be a regular Vendor.'
	IF @typeopt = 'S' SELECT @msg = 'Must be a Supplier.'
	RETURN 1
END

IF @activeopt <> 'X' AND @active <> @activeopt
BEGIN
	SELECT @msg='Invalid active status!'
	IF @activeopt = 'Y' SELECT @msg = 'Must be an active Vendor.'
	IF @activeopt = 'N' SELECT @msg = 'Must be an inactive Vendor.'
	RETURN 1
END

IF EXISTS (SELECT * FROM bAPVH WHERE APCo=@apco AND VendorGroup=@vendgroup AND Vendor=@vendorout)
BEGIN
	SELECT @holdyn='Y'
END
ELSE
BEGIN
	SELECT @holdyn='N'
END

--check all invoice compliance - returns @complied = 'N'if the vendor is not in compliance.
SELECT @allcompchkyn = AllCompChkYN FROM dbo.bAPCO WHERE APCo = @apco
SELECT @complied = 'Y'
IF @allcompchkyn = 'Y' AND @invdate IS NOT NULL
BEGIN
	EXEC @rc = bspAPComplyCheckAll @apco, @vendgroup, @vendorout, @invdate, @complied OUTPUT
END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[bspAPVendorValForAPUI] TO [public]
GO
