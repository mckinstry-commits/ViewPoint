SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspAPT5018Init]
   /***************************************************
   * CREATED BY		: MV 06/10/09
   * MODIFIED BY	: MV 06/18/12 - TK15758 - clear table before initializing
   *				  MV 07/02/12 - TK15758 - added APCo to delete where clause
   *				  MV 11/20/12 - TK-19480 - Sum amounts from invoices (APTH) checked "Subj T5"
   * Usage:
   *   Called from APT5018 to initialize new recs into bAPT5 
   *	return a warning.
   *
   * Input:
   *	@perenddate 
    
   * Output:
   *   @msg          
   *
   * Returns:
   *	0            success
   *   5             warn
   *************************************************/
   	(@apco bCompany, @perstartdate bDate,@perenddate bDate,@vendorgroup bGroup,@reportdate bDate,@msg varchar(120) output)
	AS

	SET NOCOUNT ON

	DECLARE @rcode int

	SELECT @rcode = 0 
   
	-- Clear the table of existing records with a PeriodEndDate within the start and end date being initialized. TK-15758
	DELETE 
	FROM dbo. bAPT5
	WHERE APCo = @apco AND Type <> 'A' AND (PeriodEndDate >= @perstartdate and PeriodEndDate <= @perenddate)  

	-- Add records to T5 table 
	INSERT dbo.bAPT5
			(
				APCo,PeriodEndDate,VendorGroup, Vendor, OrigReportDate, OrigAmount,Type
			)
	SELECT DISTINCT @apco, @perenddate, @vendorgroup, h.Vendor,@reportdate,SUM(d.Amount - d.DiscTaken), 'O'
    FROM dbo.APTH h 
	JOIN dbo.APTD d ON h.APCo = d.APCo AND h.Mth=d.Mth AND h.APTrans=d.APTrans
	WHERE h.APCo=@apco AND (h.V1099YN='Y' AND h.V1099Type='T5018') AND (d.PaidMth >= @perstartdate AND d.PaidMth <= @perenddate)
		AND NOT EXISTS 
				(
					SELECT * 
					FROM dbo.APT5 t
					WHERE t.APCo = @apco AND t.PeriodEndDate = @perenddate AND t.VendorGroup = @vendorgroup AND t.Vendor = h.Vendor
				)
	GROUP BY h.VendorGroup, h.Vendor
	HAVING SUM(d.Amount - d.DiscTaken) >= 500.00
	
	--INSERT dbo.bAPT5
	--		(
	--			APCo,PeriodEndDate,VendorGroup, Vendor, OrigReportDate, OrigAmount,Type
	--		)
 --   SELECT DISTINCT @apco, @perenddate, @vendorgroup, a.Vendor,@reportdate,SUM(a.PaidAmt - a.DiscTaken), 'O'
 --   FROM dbo.APVA a (nolock)
	--JOIN dbo.APVM v (nolock) ON a.VendorGroup=v.VendorGroup AND a.Vendor=v.Vendor
	--WHERE a.APCo=@apco AND v.V1099YN='Y' AND v.V1099Type='T5018' AND a.Mth >= @perstartdate AND a.Mth <= @perenddate
	--	AND NOT EXISTS 
	--			(
	--				SELECT * 
	--				FROM dbo.APT5 t
	--				WHERE t.APCo = @apco AND t.PeriodEndDate = @perenddate AND t.VendorGroup = @vendorgroup AND t.Vendor = a.Vendor
	--			)
	--GROUP BY a.VendorGroup, a.Vendor
	--HAVING SUM(a.PaidAmt - a.DiscTaken) >= 500.00
   
   	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspAPT5018Init] TO [public]
GO
