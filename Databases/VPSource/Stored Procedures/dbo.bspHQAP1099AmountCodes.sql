SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[bspHQAP1099AmountCodes]
    /************************************
    * Created: 10/25/99 DANF
    *        : 07/12/00 DANF Added check for Vendor 1099 flag
    *        : 10/20/00 DANF Added Ga parameter
    *        : 10/22/01 DANF Added New box amounts
    *	     : 07/02/2002 MV #16339 override min amt by vendor
    *         11/12/02 DANF #19293 - Dividends min amounts are zero
    *			: 03/17/03 - MV #20553 - include amt = min amt.
    *			: 04/08/03 - MV #20179 - remove GA filing code
    *			: 11/20/06 - MV 6X recode of AP1099Download Export
	*			07/06/09 - MV #132337 - total all boxes to evaluate
	*			07/15/09 - MV #124736 - corrected refiling
    * Returns totals and record count for the exporting of 1099 data
    * This procedure is used by the 1099 Download form.
    *
    *
    * Pass in:
    *	@APCo        Company
    *	@yemo        Month
    *	@Types       1099 Types
    *	@MinAmount   Mim Amount to be reported
    *
    * Returns:
    *	totals on Boxes 1 - 13, and the record count
    *
    ***********************************/
    (@APCo bCompany, @Yemo bMonth, @Types varchar(10), @MinAmount bDollar, @correctedfilingyn bYN, @errortype tinyint) --, @GA varchar(1))
   
   as
   set nocount on
   
   if @Types = 'DIV' select @MinAmount = 0
   
   
	if isnull(@correctedfilingyn,'N') = 'N'
	begin
    Select 'BoxAmt1'=Sum (a.Box1Amt), 'BoxAmt2'=sum (a.Box2Amt), 'BoxAmt3'=sum (a.Box3Amt), 'BoxAmt4'=sum (a.Box4Amt),
		 'BoxAmt5'=sum (a.Box5Amt), 'BoxAmt6'=sum (a.Box6Amt),'BoxAmt7'=Sum (a.Box7Amt), 'BoxAmt8'=Sum (a.Box8Amt),
		'BoxAmt9'= Sum (a.Box9Amt), 'BoxAmt10'=Sum (a.Box10Amt), 'BoxAmt11'=Sum (a.Box11Amt), 'BoxAmt12'=Sum (a.Box12Amt),
         'BoxAmt13'=Sum (a.Box13Amt), 'BoxAmt14'=Sum (a.Box14Amt), 'BoxAmt15'=Sum (a.Box15Amt), 'BoxAmt16'=Sum (a.Box16Amt),
		'BoxAmt17'=Sum (a.Box17Amt), 'BoxAmt18'=Sum (a.Box18Amt),'Count'=COUNT(*)
    from dbo.bAPFT a (nolock)
    inner join dbo.APVM b (nolock) on a.VendorGroup = b.VendorGroup and a.Vendor = b.Vendor
     where a.APCo = @APCo and a.YEMO = @Yemo and a.V1099Type= @Types and b.V1099YN = 'Y' and
	((isnull(a.Box1Amt,'0') + isnull(a.Box2Amt,'0') + isnull(a.Box3Amt,'0') + isnull(a.Box4Amt,'0') + isnull(a.Box5Amt,'0')
		+ isnull(a.Box6Amt,'0') + isnull(a.Box7Amt,'0') + isnull(a.Box8Amt,'0') + isnull(a.Box9Amt,'0') + isnull(a.Box10Amt,'0') 
		+ isnull(a.Box11Amt,'0') + isnull(a.Box12Amt,'0') + isnull(a.Box13Amt,'0') + isnull(a.Box14Amt,'0') + isnull(a.Box15Amt,'0')
		+ isnull(a.Box16Amt,'0') + isnull(a.Box17Amt,'0') + isnull(a.Box18Amt,'0'))>= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end)
		and a.CorrectedFilingYN = 'N'  
	Group By a.V1099Type
    Order By a.V1099Type
	end

	if isnull(@correctedfilingyn,'N') = 'Y'
	begin
	if @errortype = 1 -- 1099 Information
		begin
		Select 'BoxAmt1'=Sum (a.Box1Amt), 'BoxAmt2'=sum (a.Box2Amt), 'BoxAmt3'=sum (a.Box3Amt), 'BoxAmt4'=sum (a.Box4Amt),
			 'BoxAmt5'=sum (a.Box5Amt), 'BoxAmt6'=sum (a.Box6Amt),'BoxAmt7'=Sum (a.Box7Amt), 'BoxAmt8'=Sum (a.Box8Amt),
			'BoxAmt9'= Sum (a.Box9Amt), 'BoxAmt10'=Sum (a.Box10Amt), 'BoxAmt11'=Sum (a.Box11Amt), 'BoxAmt12'=Sum (a.Box12Amt),
			 'BoxAmt13'=Sum (a.Box13Amt), 'BoxAmt14'=Sum (a.Box14Amt), 'BoxAmt15'=Sum (a.Box15Amt), 'BoxAmt16'=Sum (a.Box16Amt),
			'BoxAmt17'=Sum (a.Box17Amt), 'BoxAmt18'=Sum (a.Box18Amt),'Count'=COUNT(*)
		from dbo.bAPFT a (nolock)
		inner join dbo.APVM b (nolock) on a.VendorGroup = b.VendorGroup and a.Vendor = b.Vendor
		 where a.APCo = @APCo and a.YEMO = @Yemo and a.V1099Type= @Types and b.V1099YN = 'Y' and
			a.CorrectedFilingYN = 'Y' and a.CorrectedErrorType = @errortype  
		Group By a.V1099Type
		Order By a.V1099Type
		end
	if @errortype = 2 -- vendor information or both
		begin
		Select 'BoxAmt1'=Sum (a.Box1Amt), 'BoxAmt2'=sum (a.Box2Amt), 'BoxAmt3'=sum (a.Box3Amt), 'BoxAmt4'=sum (a.Box4Amt),
			 'BoxAmt5'=sum (a.Box5Amt), 'BoxAmt6'=sum (a.Box6Amt),'BoxAmt7'=Sum (a.Box7Amt), 'BoxAmt8'=Sum (a.Box8Amt),
			'BoxAmt9'= Sum (a.Box9Amt), 'BoxAmt10'=Sum (a.Box10Amt), 'BoxAmt11'=Sum (a.Box11Amt), 'BoxAmt12'=Sum (a.Box12Amt),
			 'BoxAmt13'=Sum (a.Box13Amt), 'BoxAmt14'=Sum (a.Box14Amt), 'BoxAmt15'=Sum (a.Box15Amt), 'BoxAmt16'=Sum (a.Box16Amt),
			'BoxAmt17'=Sum (a.Box17Amt), 'BoxAmt18'=Sum (a.Box18Amt),'Count'=COUNT(*)
		from dbo.bAPFT a (nolock)
		inner join dbo.APVM b (nolock) on a.VendorGroup = b.VendorGroup and a.Vendor = b.Vendor
		 where a.APCo = @APCo and a.YEMO = @Yemo and a.V1099Type= @Types and b.V1099YN = 'Y' and
			a.CorrectedFilingYN = 'Y' and a.CorrectedErrorType > 1  
		Group By a.V1099Type
		Order By a.V1099Type
		end
	end


--        (a.Box1Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box2Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box3Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box4Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box5Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box6Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box7Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box8Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box9Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box10Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box11Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box12Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box13Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box14Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box15Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box16Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box17Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box18Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end )
      /*(a.Box1Amt>= @MinAmount or a.Box2Amt>= @MinAmount or a.Box3Amt>= @MinAmount or a.Box4Amt>= @MinAmount or
         a.Box5Amt>= @MinAmount or a.Box6Amt>= @MinAmount or a.Box7Amt>= @MinAmount or a.Box8Amt>= @MinAmount or
         a.Box9Amt>= @MinAmount or a.Box10Amt>= @MinAmount or a.Box11Amt>= @MinAmount or a.Box12Amt>= @MinAmount or
         a.Box13Amt>= @MinAmount or a.Box14Amt>= @MinAmount or a.Box15Amt>= @MinAmount or a.Box16Amt>= @MinAmount or
         a.Box17Amt>= @MinAmount or a.Box18Amt>= @MinAmount)*/
    
   /* END
   ELSE
    BEGIN
    Select Sum (a.Box1Amt), sum (a.Box2Amt), sum (a.Box3Amt), sum (a.Box4Amt), sum (a.Box5Amt), sum (a.Box6Amt),
          Sum (a.Box7Amt), Sum (a.Box8Amt), Sum (a.Box9Amt), Sum (a.Box10Amt), Sum (a.Box11Amt), Sum (a.Box12Amt),
          Sum (a.Box13Amt), Sum (a.Box14Amt), Sum (a.Box15Amt), Sum (a.Box16Amt), Sum (a.Box17Amt), Sum (a.Box18Amt), 
          COUNT(*)
    from bAPFT a
    inner join APVM b on a.VendorGroup = b.VendorGroup and a.Vendor = b.Vendor and b.State = 'GA'
    where a.APCo = @APCo and a.YEMO = @Yemo and a.V1099Type= @Types and b.V1099YN = 'Y' and
   	-- #16339 allow an override of the minimum amount by vendor
   	(a.Box1Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box2Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box3Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box4Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box5Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box6Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box7Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box8Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box9Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box10Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box11Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box12Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box13Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box14Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box15Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box16Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box17Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
   	 a.Box18Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end )
        /*( a.Box1Amt>= @MinAmount or a.Box2Amt>= @MinAmount or a.Box3Amt>= @MinAmount or a.Box4Amt>= @MinAmount or
         a.Box5Amt>= @MinAmount or a.Box6Amt>= @MinAmount or a.Box7Amt>= @MinAmount or a.Box8Amt>= @MinAmount or
         a.Box9Amt>= @MinAmount or a.Box10Amt>= @MinAmount or a.Box11Amt>= @MinAmount or a.Box12Amt>= @MinAmount or
         a.Box13Amt>= @MinAmount or a.Box14Amt>= @MinAmount or a.Box15Amt>= @MinAmount or a.Box16Amt>= @MinAmount or
         a.Box17Amt>= @MinAmount or a.Box18Amt>= @MinAmount)*/
    Group By a.V1099Type
    Order By a.V1099Type
    END*/

GO
GRANT EXECUTE ON  [dbo].[bspHQAP1099AmountCodes] TO [public]
GO
