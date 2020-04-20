SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspAPVendorValForAPWH]

/***********************************************************
* CREATED BY:   MV 11/19/01
* MODIFIED By : kb 10/29/2 - issue #18878 - fix double quotes
*				MV 06/03/04 - #24723 - validate vendor for length.
*				MV 06/28/06 - #121302 order by SortName, upper(@vendor)
*				MV 12/19/06 - #28267 validate vendor agains vendor in APTH
*				MV 01/02/07 - #123358 - don't return @name param
*				KK 02/01/12 - TK-11581 Pass back Vendor CM Account [Reformatted code as per best practice] 
*
* Usage:
*	Used by 
*
* Input params:
*	@vendgroup	Vendor Group
*	@vendor		Vendor sort name or number
*
* Output params:
*	@vendorout		vendor number
*	@name			Vendor name
*	@vendorCMAcct	CM Account in Vendor Master
*	@msg			error message
*
* Return code:
*	0 = success, 1 = failure
*****************************************************/

(@co int, 
 @vendgroup bGroup = NULL, 
 @vendor varchar(15) = NULL, 
 @mth bMonth = NULL,
 @trans bTrans = NULL,
 @vendorout bVendor = NULL OUTPUT,
 @compliedyn bYN OUTPUT,
 @vendorCMAcct bCMAcct OUTPUT, 
 @msg varchar(60) OUTPUT)
 
AS
SET NOCOUNT ON

DECLARE @type char(1), 
		@active bYN, 
		@transvendor bVendor,
		@invdate bDate
		
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

/* If @vendor is numeric then try to find Vendor number */
IF dbo.bfIsInteger(@vendor) = 1 AND len(@vendor) < 7 --#24723
BEGIN
	SELECT @vendorout = Vendor, @vendorCMAcct = CMAcct, @msg = Name FROM APVM
	WHERE VendorGroup = @vendgroup AND Vendor = convert(int,convert(float, @vendor))
END

/* If @vendor is not numeric or not found try to find as Sort Name */
IF @vendorout IS NULL	--#24723
BEGIN
	SELECT @vendorout = Vendor, @vendorCMAcct = CMAcct, @msg = Name	FROM APVM
	WHERE VendorGroup = @vendgroup AND SortName = upper(@vendor) ORDER BY SortName
	/* if not found,  try to find closest */
	IF @@rowcount = 0
	BEGIN
		SET ROWCOUNT 1
		SELECT @vendorout = Vendor, @vendorCMAcct = CMAcct, @msg = Name FROM APVM
		WHERE VendorGroup = @vendgroup AND SortName LIKE upper(@vendor) + '%' ORDER BY SortName
		IF @@rowcount = 0
		BEGIN
			SELECT @msg = 'Not a valid Vendor'
			RETURN 1
		END
	END
END

--validate vendorout against APTH vendor  
IF @co IS NOT NULL AND @mth IS NOT NULL AND @trans IS NOT NULL
BEGIN
	SELECT @transvendor = Vendor FROM APTH 
	WHERE APCo = @co AND Mth = @mth AND APTrans = @trans
	IF @vendorout <> @transvendor 
	BEGIN
		SELECT @msg = 'Vendor does not match transaction vendor'
		RETURN 1
	END	
	-- get header info from APTH
	SELECT @invdate = InvDate FROM APTH 
	WHERE APCo = @co AND Mth = @mth AND APTrans = @trans 
	-- check if vendor is out of compliance
	IF EXISTS (SELECT 1 FROM bAPVC v 
						JOIN bHQCP h ON v.CompCode = h.CompCode
				WHERE v.APCo = @co 
					AND v.VendorGroup = @vendgroup 
					AND v.Vendor = @vendorout 
					AND h.AllInvoiceYN = 'Y'
					AND v.Verify = 'Y' 
					AND (	(CompType = 'D' AND (ExpDate < @invdate OR ExpDate IS NULL) ) 
						 OR (CompType = 'F' AND (Complied = 'N' OR Complied IS NULL) )
						 )
				)
	BEGIN
		SELECT @compliedyn='N'
	END
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspAPVendorValForAPWH] TO [public]
GO
