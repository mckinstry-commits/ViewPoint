SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspAPICRptUpdate]
     /*************************************
     * CREATED BY    : MV  07/10/2003 for Issue #15528
     * LAST MODIFIED : MV	09/02/05 #26723 - for 6x
	 *					MV	07/25/08 - #129095 - fix update to bAPVM		 
     *
     * Updates bAPFT with ICRptDate for all vendors in
     * bAPFT that meet the Independent Contractor reporting
     * requirements. The I.C. Report uses the date in bAPFT
     * to get independent contractors for the report.
     *
     * Pass:
     *	APCompany, IC Report date, ReprintYN, Reprint date
     *
     * Returns:
     *	
     *
     * Success returns:
     *   0
     *
     * Error returns:
     *	1 
     **************************************/
     (@APCo bCompany, @ICRptDate bDate = null , @ReprintYN bYN = null , @ReprintDate bDate = null, @msg varchar(255) output)
     as
     set nocount on
     
     declare @rcode int, @ICPayAmt bDollar, @APFTrowcount int
     
     select @rcode = 0
     select @ICPayAmt = isnull(ICPayAmt,0) from bAPCO with (nolock) where APCo=@APCo
     if @@rowcount = 0
     	begin
     	select @msg = 'Invalid AP Company', @rcode=1
     	goto bspexit
     	end
     
     if isnull(@ReprintYN,'N') = 'N'
     begin
     	-- update bAPFT with the IC report date 
     	BEGIN TRANSACTION
     	update bAPFT set ICRptDate = @ICRptDate from bAPFT f
     	join bAPVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
     	where f.APCo=@APCo and year(YEMO)= Year(@ICRptDate)and f.V1099Type='MISC'
     	 and (isnull(Box1Amt,0) + isnull(Box2Amt,0) + isnull(Box3Amt,0) + isnull(Box4Amt,0) + isnull(Box5Amt,0) +
     		isnull(Box6Amt,0) + isnull(Box7Amt,0) + isnull(Box8Amt,0) + isnull(Box9Amt,0) + isnull(Box10Amt,0) + 
     		isnull(Box11Amt,0) + isnull(Box12Amt,0) + isnull(Box13Amt,0) + isnull(Box14Amt,0) + isnull(Box15Amt,0) +
     		isnull(Box16Amt,0) + isnull(Box17Amt,0) + isnull(Box18Amt,0))>=@ICPayAmt 
     		and f.ICRptDate is null 
     		and (v.ICSocSecNbr is not null or v.ICState is not null or v.ICZip is not null)	--identifies a vendor as an IC
		select @APFTrowcount
     	if @APFTrowcount = 0
     		begin
     		select @msg = 'No vendors qualify for the I.C. Report at this time. ', @rcode=1
     		goto bspexit
     		end
     	
     	-- update bAPVM with the IC report date - it identifies an I.C. as being reported for the year
     	update bAPVM set ICLastRptDate = @ICRptDate from bAPVM v 
     	join bAPFT f on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
     	where f.APCo=@APCo and year(YEMO)= Year(@ICRptDate)and f.V1099Type='MISC'
     	 and (isnull(Box1Amt,0) + isnull(Box2Amt,0) + isnull(Box3Amt,0) + isnull(Box4Amt,0) + isnull(Box5Amt,0) +
     		isnull(Box6Amt,0) + isnull(Box7Amt,0) + isnull(Box8Amt,0) + isnull(Box9Amt,0) + isnull(Box10Amt,0) + 
     		isnull(Box11Amt,0) + isnull(Box12Amt,0) + isnull(Box13Amt,0) + isnull(Box14Amt,0) + isnull(Box15Amt,0) +
     		isnull(Box16Amt,0) + isnull(Box17Amt,0) + isnull(Box18Amt,0))>=@ICPayAmt
     		and f.ICRptDate = @ICRptDate 
     		and (v.ICSocSecNbr is not null or v.ICState is not null or v.ICZip is not null)--identifies a vendor as an IC
     	if @@rowcount < @APFTrowcount 
     		begin
     		select @msg = 'IC Report Date was not updated in bAPVM ', @rcode=1
     		goto bspexit
     		end
     	COMMIT
     end
     
     if isnull(@ReprintYN,'N') = 'Y'
     begin
   	BEGIN TRANSACTION
     	if isnull(@ReprintDate,'')= ''
     	begin
     	select @msg = 'Invalid reprint date.', @rcode=1
     	goto bspexit
     	end 
     	-- update bAPFT with the IC report date - it's used in printing the I.C. report
     	update bAPFT set ICRptDate = @ICRptDate from bAPFT f
     	join bAPVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
     	where f.APCo=@APCo and year(YEMO)= Year(@ICRptDate)and f.V1099Type='MISC'
     	 and (isnull(Box1Amt,0) + isnull(Box2Amt,0) + isnull(Box3Amt,0) + isnull(Box4Amt,0) + isnull(Box5Amt,0) +
     		isnull(Box6Amt,0) + isnull(Box7Amt,0) + isnull(Box8Amt,0) + isnull(Box9Amt,0) + isnull(Box10Amt,0) + 
     		isnull(Box11Amt,0) + isnull(Box12Amt,0) + isnull(Box13Amt,0) + isnull(Box14Amt,0) + isnull(Box15Amt,0) +
     		isnull(Box16Amt,0) + isnull(Box17Amt,0) + isnull(Box18Amt,0))>=@ICPayAmt 
     		and (f.ICRptDate is null or f.ICRptDate >= @ReprintDate)
     		and (v.ICSocSecNbr is not null or v.ICState is not null or v.ICZip is not null)	--identifies a vendor as an IC	
     	if @APFTrowcount = 0
     		begin
     		select @msg = 'No vendors qualify for the I.C. Report reprint at this time. ', @rcode=1
     		goto bspexit
     		end
     	
     
     	-- update bAPVM with the IC report date - it identifies an I.C. as being reported for the year
     	update bAPVM set ICLastRptDate = @ICRptDate from bAPVM v 
     	join bAPFT f on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
     	where f.APCo=@APCo and year(YEMO)= Year(@ICRptDate)and f.V1099Type='MISC'
     	 and (isnull(Box1Amt,0) + isnull(Box2Amt,0) + isnull(Box3Amt,0) + isnull(Box4Amt,0) + isnull(Box5Amt,0) +
     		isnull(Box6Amt,0) + isnull(Box7Amt,0) + isnull(Box8Amt,0) + isnull(Box9Amt,0) + isnull(Box10Amt,0) + 
     		isnull(Box11Amt,0) + isnull(Box12Amt,0) + isnull(Box13Amt,0) + isnull(Box14Amt,0) + isnull(Box15Amt,0) +
     		isnull(Box16Amt,0) + isnull(Box17Amt,0) + isnull(Box18Amt,0))>=@ICPayAmt
     		and f.ICRptDate = @ICRptDate
     		and (v.ICSocSecNbr is not null or v.ICState is not null or v.ICZip is not null)	--identifies a vendor as an IC
     	if @@rowcount < @APFTrowcount 
     		begin
     		select @msg = 'IC Report Date was not updated in bAPVM on reprint ', @rcode=1
     		goto bspexit
     		end
     	COMMIT
     end
     
     bspexit:
     	if @rcode = 1
     	begin
     		ROLLBACK TRANSACTION
     	end
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPICRptUpdate] TO [public]
GO
