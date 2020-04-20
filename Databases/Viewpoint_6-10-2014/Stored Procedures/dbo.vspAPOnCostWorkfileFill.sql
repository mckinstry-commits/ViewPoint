SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPOnCostWorkfileFill]
 /***********************************************************
 * CREATED BY:	MV 03/12/12 TK-12924
 * MODIFIED By:	MV 04/12/12 TK-14129 - add APCo to select where clause 
 *
 * USAGE:
 * Adds OnCost Workfile records for both GridFill and manual entry 
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
	@UserID bVPUserName,
	@ManualAddYN bYN,
	@Mth bDate = NULL,						-- used by manual add
	@APTrans bTrans = NULL,					-- used by manual add
	@SelectVendor bVendor = NULL,			-- used by gridfill
	@SelectMth bDate = NULL,				-- used by gridfill
	@SelectPayControl VARCHAR(10) = NULL,	-- used by gridfill
    @Msg varchar(90) output)

 AS
 SET NOCOUNT ON
 
 DECLARE @VendorGroup bGroup
 SELECT @VendorGroup = VendorGroup 
 FROM dbo.bHQCO 
 WHERE HQCo=@APCo
  
 IF @APCo IS NULL
 BEGIN
	SELECT @Msg = 'Missing AP Company#'
 	RETURN 1
 END
 
 IF @UserID IS NULL
 BEGIN
	SELECT @Msg = 'Missing User ID'
 	RETURN 1
 END
 
 IF ISNULL(@ManualAddYN, 'N') = 'Y'
 BEGIN
	-- validate Mth and APTrans
	IF @Mth IS NULL
	BEGIN
		SELECT @Msg = 'Missing transaction Mth'
 		RETURN 1
	END
	
	IF @APTrans IS NULL
	BEGIN
		SELECT @Msg = 'Missing AP Trans'
 		RETURN 1
	END
	
	-- add qualifying lines
	IF EXISTS
		(
			SELECT * 
			FROM dbo.bAPTL l
			WHERE l.APCo=@APCo AND l.Mth=@Mth AND l.APTrans=@APTrans 
			AND l.SubjToOnCostYN = 'Y'
		)
	BEGIN
		-- add only lines 'Subject to On Cost'
		INSERT INTO dbo.vAPOnCostWorkFileDetail
			(
				APCo,
				Mth,
				APTrans,
				APLine,
				UserID,
				Amount,
				OnCostAction
			)
		SELECT
			@APCo,
			@Mth,
			@APTrans,
			l.APLine,
			@UserID,
			l.GrossAmt,
			CASE l.OnCostStatus WHEN 0 THEN 1 ELSE NULL END
		FROM dbo.bAPTL l
		WHERE l.APCo=@APCo AND l.Mth=@Mth AND l.APTrans=@APTrans AND ISNULL(l.SubjToOnCostYN, 'N') = 'Y'
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @Msg = 'No transaction lines were added to the workfile.'
			RETURN 1
		END	
	END
	ELSE
	BEGIN
		-- Add all lines
		INSERT INTO dbo.vAPOnCostWorkFileDetail
			(
				APCo,
				Mth,
				APTrans,
				APLine,
				UserID,
				Amount,
				OnCostAction
			)
		SELECT
			@APCo,
			@Mth,
			@APTrans,
			l.APLine,
			@UserID,
			l.GrossAmt,
			l.OnCostStatus
		FROM dbo.bAPTL l
		WHERE l.APCo=@APCo AND l.Mth=@Mth AND l.APTrans=@APTrans 
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @Msg = 'No transaction lines were added to the workfile.'
			RETURN 1
		END	
	END		
 END
 ELSE -- GridFill
 BEGIN
	-- add only transactions with at least one line 'Subject to On Cost'
	BEGIN TRY
	BEGIN TRAN
		INSERT INTO dbo.vAPOnCostWorkFileHeader
			(
				APCo,
				Mth,
				APTrans,
				UserID
			)
		SELECT DISTINCT
			@APCo,
			t.Mth,
			t.APTrans,
			@UserID
		FROM dbo.bAPTH t
		JOIN dbo.bAPTL l 
		ON t.APCo=l.APCo AND t.Mth=l.Mth AND t.APTrans=l.APTrans
		WHERE t.APCo = @APCo AND t.Mth = ISNULL(@SelectMth, t.Mth) AND t.VendorGroup = @VendorGroup
		AND t.Vendor = ISNULL(@SelectVendor, t.Vendor) 
		AND iSNULL(t.PayControl,'') = ISNULL(@SelectPayControl, ISNULL(t.PayControl,''))
		AND ISNULL(l.SubjToOnCostYN, 'N') = 'Y' AND l.OnCostStatus = 0
		AND NOT EXISTS 
			(
			SELECT * FROM dbo.vAPOnCostWorkFileHeader c
			WHERE c.APCo=t.APCo AND c.Mth = t.Mth AND c.APTrans=t.APTrans 
			)
		
		-- add workfile detail 
		INSERT INTO dbo.vAPOnCostWorkFileDetail
			(
				APCo,
				Mth,
				APTrans,
				APLine,
				UserID,
				Amount,
				OnCostAction
			)
		SELECT
			@APCo,
			l.Mth,
			l.APTrans,
			l.APLine,
			@UserID,
			l.GrossAmt,
			1
		FROM dbo.bAPTL l
		JOIN dbo.bAPTH t
		ON t.APCo=l.APCo AND t.Mth=l.Mth AND t.APTrans=l.APTrans
		WHERE t.APCo = @APCo AND t.Mth = ISNULL(@SelectMth, t.Mth) AND t.VendorGroup = @VendorGroup
		AND t.Vendor = ISNULL(@SelectVendor, t.Vendor) 
		AND iSNULL(t.PayControl,'') = ISNULL(@SelectPayControl, ISNULL(t.PayControl,''))
		AND ISNULL(l.SubjToOnCostYN, 'N') = 'Y' AND l.OnCostStatus = 0
		AND NOT EXISTS 
			(
			SELECT * FROM dbo.vAPOnCostWorkFileDetail d
			WHERE d.APCo=l.APCo AND d.Mth = l.Mth AND d.APTrans=l.APTrans AND d.APLine = l.APLine
			)
		
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SELECT @Msg = 'Workfile records were not added.'
		RETURN 1
	END CATCH
	COMMIT TRAN
 END
 

RETURN



GO
GRANT EXECUTE ON  [dbo].[vspAPOnCostWorkfileFill] TO [public]
GO
