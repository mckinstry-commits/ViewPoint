SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPOnCostTransVal]
 /***********************************************************
 * CREATED BY: MV 03/08/12 
 * MODIFIED By: CHS 03/29/2012
 *
 * USAGE:
 * Validates AP Trans # for AP OnCost Workfile 
 * 
 *
 * INPUT PARAMETERS
 *   @apco	AP Company
 *   @mth	Month for transaction
 *   @aptrans	AP Transaction to validate from AP Transaction Header
 *
 * OUTPUT PARAMETERS
 *   @msg 	If Error, return error message.
 * RETURN VALUE
 *   0   success
 *   1   fail
 ****************************************************************************************/
  (@APCo bCompany,
	@Mth bDate,
	@APTrans bTrans,
	@Vendor bVendor OUTPUT,
	@APRef VARCHAR(15) OUTPUT,
	@InvDate bDate OUTPUT,
	@Desc bDesc OUTPUT,
	@OpenYN bYN OUTPUT,
	@Msg VARCHAR(90) OUTPUT)

 AS
 SET NOCOUNT ON
 
  
 IF @APCo IS NULL
 BEGIN
	SELECT @Msg = 'Missing AP Company#'
 	RETURN 1
 END
 
 IF @Mth IS NULL
 BEGIN
	SELECT @Msg = 'Missing Expense Month'
 	RETURN 1
 END
 
 IF NOT EXISTS(SELECT * FROM dbo.bAPTH WHERE APCo=@APCo AND Mth=@Mth AND APTrans=@APTrans)
 BEGIN
	SELECT @Msg = 'Invalid AP Trans.'
	RETURN 1
 END
 ELSE
 BEGIN
	IF EXISTS(SELECT * FROM dbo.APOnCostWorkFileHeader WHERE APCo=@APCo AND Mth=@Mth AND APTrans=@APTrans and UserID <> SYSTEM_USER)
	BEGIN
		SELECT @Msg = 'Invoice is already in an On-Cost Workfile. Cannot add to this workfile.'
	RETURN 1
	END
	ELSE
	BEGIN
		SELECT @Vendor = t.Vendor,
			@APRef = t.APRef,
			@InvDate = t.InvDate,
			@Desc = t.Description,
			@OpenYN = t.OpenYN,
			@Msg = t.Description
			FROM dbo.bAPTH t
			JOIN dbo.bAPVM v ON t.VendorGroup=v.VendorGroup AND t.Vendor=v.Vendor
			WHERE t.APCo = @APCo AND t.Mth = @Mth AND t.APTrans = @APTrans
	END
 END

RETURN




GO
GRANT EXECUTE ON  [dbo].[vspAPOnCostTransVal] TO [public]
GO
