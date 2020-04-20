SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspAPVendorValAPHB]
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
 @addendatypeid smallint = NULL OUTPUT, 
 @separatepayyn bYN OUTPUT, 
 @aprefunq tinyint = NULL OUTPUT,
 @compliedout bYN = NULL OUTPUT, 
 @cmacct bCMAcct OUTPUT, 
 @paycontrol varchar(10) OUTPUT, 
 @VendorABN varchar(20) OUTPUT,
 @paymethod char(1) = NULL OUTPUT,
 @SubjToOnCostYN char(1) OUTPUT,
 @OnCostCostType bJCCType OUTPUT,
 @msg varchar(60) OUTPUT)
/***********************************************************
* CREATED BY: MV 08/23/01 - Copied from bspAPVendorVal, added output param @addendatypeid
* Modified by:  kb 2/12/2 - issue #16252
*			MV 08/05/02 - #15113 return aprefunqovr
*              kb 10/29/2 - issue #18878 - fix double quotes
*			MV 01/13/03 - #17821 - all invoice compliance
*			MV 06/02/04 - #24723 - validate numeric vendor for length.
*			MV 06/28/06 - #121302 order by SortName, upper(@vendor)
*			MV 03/13/08 - #127347 bState to varchar(4) international addresses
*			TJL 03/25/08 - #127347 Intl addresses 
*		TJL 02/04/09 - Issue #124739, Add CMAcct in APVM as default
*			MV 10/06/09 - #131826 return PayControl
*			CHS	09/29/2011	-	B-04930 - added ABN
*			CHS	10/17/201	-	D-03197 - fixed ABN	
*			EN 01/04/2012 B-08098 added APVM_PayMethod to output param list 
*									and reformatted code as per best practice
*			CHS	01/26/2012	B-08286 added output parameter for subject to on-cost checkbox.
*			CHS	01/26/2012	B-09267 added output parameter for on-cost cost type.
*
* Usage:
*	Used by AP Entry for vendor input to validate the entry by either Sort Name or number.
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
*	@paymethod	vendor payment method
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
*	@addendatypeid vendor EFT addenda type id number
*	@aprefunq		APRef uniqueness level 
*   @compliedout	flag indicating if vendor is in compliance
*	@msg		Vendor Name or error message
*
* Return code:
*	0 = success, 1 = failure
*****************************************************/
AS
SET NOCOUNT ON

DECLARE @type char(1), 
		@active bYN, 
		@rc int,
		@allcompchkyn bYN,
		@complied bYN
		
SELECT @rc = 0, @complied = 'Y'

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
-- if isnumeric(@vendor) = 1 
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
			@addendatypeid = AddendaTypeId,
			@separatepayyn = SeparatePayInvYN, 
			@aprefunq = APRefUnqOvr, 
			@cmacct = CMAcct, 
			@paycontrol = PayControl,
			@VendorABN = AusBusNbr,
			@paymethod = PayMethod,
			@SubjToOnCostYN = SubjToOnCostYN,
			@OnCostCostType = OnCostCostType	
	FROM dbo.APVM
	WHERE VendorGroup = @vendgroup AND Vendor = CONVERT(int, CONVERT(float, @vendor))
END
/* if not numeric or not found try to find as Sort Name */
IF @vendorout IS NULL -- #24723 non numeric or invalid numeric length
--if @@rowcount = 0
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
			@addendatypeid = AddendaTypeId,
			@separatepayyn = SeparatePayInvYN, 
			@aprefunq = APRefUnqOvr, 
			@cmacct = CMAcct, 
			@paycontrol = PayControl,
			@VendorABN = AusBusNbr,
			@paymethod = PayMethod,
			@SubjToOnCostYN = SubjToOnCostYN		   
	FROM dbo.APVM
	WHERE VendorGroup = @vendgroup AND SortName = UPPER(@vendor) 
	ORDER BY SortName
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
			@addendatypeid = AddendaTypeId,
			@separatepayyn = SeparatePayInvYN, 
			@aprefunq = APRefUnqOvr, 
			@cmacct = CMAcct, 
			@paycontrol = PayControl,
			@VendorABN = AusBusNbr,
			@paymethod = PayMethod,
			@SubjToOnCostYN = SubjToOnCostYN			   
		FROM dbo.APVM
		WHERE VendorGroup = @vendgroup AND SortName LIKE UPPER(@vendor) + '%' 
		ORDER BY SortName
		
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
IF exists(SELECT * FROM dbo.bAPVH WHERE APCo=@apco AND VendorGroup=@vendgroup AND Vendor=@vendorout)
BEGIN
	SELECT @holdyn = 'Y'
	END
ELSE
BEGIN
	SELECT @holdyn='N'
END

--check all invoice compliance - returns @complied = 'N'if the vendor is not in compliance.
SELECT @allcompchkyn=AllCompChkYN FROM dbo.bAPCO WHERE APCo = @apco
IF @allcompchkyn='Y'
BEGIN
	EXEC @rc = bspAPComplyCheckAll @apco, @vendgroup, @vendorout, @invdate, @complied OUTPUT
	IF @complied = 'N' 
	BEGIN
		SELECT @compliedout = @complied
	END
	ELSE
	BEGIN
		SELECT @compliedout = 'Y'
	END
END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[bspAPVendorValAPHB] TO [public]
GO
