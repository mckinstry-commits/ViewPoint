SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    Procedure [dbo].[vspAPVendorMasterOnCostUpdate]
  /***************************************************
  * CREATED BY    : MV  01/19/12 TK-11880 - AP OnCost 
  * LAST MODIFIED : MV	02/07/12 TK-11880 - add APCo
  * Usage:
  *   Called from frmAPVendorMasterOnCost. Addes OnCost
  *		types to vAPVendorMasterOnCost table or clears it.
  *
  * Input:
  * @APCo
  *	@VendorGroup
  *	@Vendor
  * @OnCostGroup
  * @AddorClear     
  *
  * Output:
  *   @Msg           
  *
  * Returns:
  *	0             success
  * 1             error
  *************************************************/
    (
	  @APCo bCompany,
      @VendorGroup INT,
      @Vendor bVendor,
      @OnCostGroup TINYINT,
      @AddorClear VARCHAR(1),
      @Msg VARCHAR(60) OUTPUT
    )
AS 
    SET nocount ON
  
    DECLARE @rcode INT
  
    SELECT  @rcode = 0
  
   
    IF @VendorGroup IS NULL
    BEGIN
		SELECT  @Msg = 'Missing vendor group!',
		@rcode = 1
		RETURN
    END
    
    IF @Vendor IS NULL
    BEGIN
		SELECT  @Msg = 'Missing vendor!',
		@rcode = 1
		RETURN
    END
    
    IF @AddorClear IS NULL
    BEGIN
		SELECT  @Msg = 'Missing Add or Clear flag!',
		@rcode = 1
		RETURN
    END
    
    IF @AddorClear = 'A' AND @OnCostGroup IS NULL
    BEGIN
		SELECT  @Msg = 'Missing On-Cost Group!',
		@rcode = 1
		RETURN
    END
    
    IF @AddorClear = 'C'
    BEGIN
		DELETE FROM vAPVendorMasterOnCost
		WHERE APCo=@APCo AND VendorGroup = @VendorGroup AND Vendor = @Vendor
		RETURN
    END
    
    IF @AddorClear = 'A'
    BEGIN
		INSERT INTO vAPVendorMasterOnCost
			(
				VendorGroup,
				Vendor,
				OnCostID,
				CalcMethod,
				Rate,
				Amount,
				PayType,
				OnCostVendor,
				ATOCategory,
				SchemeID,
				MemberShipNumber,
				APCo
			)
		SELECT 
			@VendorGroup,
			@Vendor,
			t.OnCostID,
			t.CalcMethod,
			t.Rate,
			t.Amount,
			t.PayType,
			t.OnCostVendor, 
			t.ATOCategory,
			NULL,
			NULL,
			@APCo
		FROM dbo.vAPOnCostGroupTypes g
		JOIN dbo.vAPOnCostType t ON t.APCo=g.APCo AND g.OnCostID=t.OnCostID
		WHERE g.APCo=@APCo AND g.GroupID = @OnCostGroup
		AND NOT EXISTS
			(
				SELECT * 
				FROM dbo.vAPVendorMasterOnCost v
				WHERE v.APCo= @APCo AND v.VendorGroup=@VendorGroup AND v.Vendor=@Vendor
				AND v.OnCostID=g.OnCostID
			)
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @Msg = 'No On-Cost types were added to vendor.',
			@rcode = 5
		END
    END 
    
    RETURN @rcode
    
    GRANT EXECUTE ON vspAPVendorMasterOnCostUpdate TO public;
GO
GRANT EXECUTE ON  [dbo].[vspAPVendorMasterOnCostUpdate] TO [public]
GO
