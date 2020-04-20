SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[bspHQAP1099State]
    /************************************
    * Created: 10/25/99 DANF
    * Modified: 07/11/00 DANF Added check for b.V1099YN = 'Y'
    *           10/22/01 DANF Added new boxes 14-18 
    *		   07/02/2002 MV #16339 override min amt by vendor
    *         11/12/02 DANF #19293 - Dividends min amounts are zero
    *         01/07/02 MARY ANN #19848 - Add states CO, LA, MD, NE, NC, VA
    *			03/18/03 - MV #20553 select amounts = 0
    *			02/16/05 - MV #27142 - add CT state
    *			11/21/06 - 6X AP1099Download recode 
    *			10/04/07 - #125613 Add Utah
	*			07/06/09 - MV #132337 total all boxes to evaluate
	*			07/21/09 - MV #124736 - corrected filings
    *
    * This procedure is used for the exporting of 1099 data.
    * This will return a total record for each state and only applies to combined/federal state reporting
    *
    *
    * Pass in:
    *	@APCo        Company
    *	@YEMO        Year endig month
    *	@Types       Type of 1099 being reported
    *	@MinAmount   Min amount of dollars to be reported
    *
    * Returns:
    *	Totals for 1099 boxes 1-12, state, 1099 Type, and record count
    *
    ***********************************/
   
   (@APCo bCompany, @Yemo bMonth, @Types varchar(10), @MinAmount bDollar,@correctedfilingyn bYN, @errortype tinyint)
   
   as
   set nocount on
   
   if @Types = 'DIV' select @MinAmount = 0
   
	if @correctedfilingyn = 'N' 
	begin
   Select 'Box1Amt'=Sum (a.Box1Amt), 'Box2Amt'=sum (a.Box2Amt), 'Box3Amt'=sum (a.Box3Amt), 'Box4Amt'=sum (a.Box4Amt),
	 'Box5Amt'=sum (a.Box5Amt), 'Box6Amt'=sum (a.Box6Amt),'Box7Amt'=Sum (a.Box7Amt), 'Box8Amt'=Sum (a.Box8Amt), 
	 'Box9Amt'=Sum (a.Box9Amt),'Box10Amt'=Sum (a.Box10Amt), 'Box11Amt'=Sum (a.Box11Amt), 'Box12Amt'=Sum (a.Box12Amt),
     'Box13Amt'=Sum (a.Box13Amt),'Box14Amt'=Sum (a.Box14Amt),'Box15Amt'=Sum (a.Box15Amt),'Box16Amt'=Sum (a.Box16Amt),
	 'Box17Amt'=Sum (a.Box17Amt),'Box18Amt'=Sum (a.Box18Amt),'State'=b.State,'1099Type'=a.V1099Type, 'Count'=count(*)
   from bAPFT a
   inner join bAPVM b on b.VendorGroup = a.VendorGroup and b.Vendor = a.Vendor
   
   where a.APCo = @APCo and a.YEMO = @Yemo and a.V1099Type= @Types and b.V1099YN = 'Y' and
	((isnull(a.Box1Amt,'0') + isnull(a.Box2Amt,'0') + isnull(a.Box3Amt,'0') + isnull(a.Box4Amt,'0') + isnull(a.Box5Amt,'0')
		+ isnull(a.Box6Amt,'0') + isnull(a.Box7Amt,'0') + isnull(a.Box8Amt,'0') + isnull(a.Box9Amt,'0') + isnull(a.Box10Amt,'0') 
		+ isnull(a.Box11Amt,'0') + isnull(a.Box12Amt,'0') + isnull(a.Box13Amt,'0') + isnull(a.Box14Amt,'0') + isnull(a.Box15Amt,'0')
		+ isnull(a.Box16Amt,'0') + isnull(a.Box17Amt,'0') + isnull(a.Box18Amt,'0'))>= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end)
	Group By a.V1099Type, b.State
	Order By a.V1099Type, b.State
	end

	if @correctedfilingyn = 'Y' 
	begin
	if @errortype = 1 -- 1099 info
		begin
	   Select 'Box1Amt'=Sum (a.Box1Amt), 'Box2Amt'=sum (a.Box2Amt), 'Box3Amt'=sum (a.Box3Amt), 'Box4Amt'=sum (a.Box4Amt),
		 'Box5Amt'=sum (a.Box5Amt), 'Box6Amt'=sum (a.Box6Amt),'Box7Amt'=Sum (a.Box7Amt), 'Box8Amt'=Sum (a.Box8Amt), 
		 'Box9Amt'=Sum (a.Box9Amt),'Box10Amt'=Sum (a.Box10Amt), 'Box11Amt'=Sum (a.Box11Amt), 'Box12Amt'=Sum (a.Box12Amt),
		 'Box13Amt'=Sum (a.Box13Amt),'Box14Amt'=Sum (a.Box14Amt),'Box15Amt'=Sum (a.Box15Amt),'Box16Amt'=Sum (a.Box16Amt),
		 'Box17Amt'=Sum (a.Box17Amt),'Box18Amt'=Sum (a.Box18Amt),'State'=b.State,'1099Type'=a.V1099Type, 'Count'=count(*)
	   from bAPFT a
	   inner join bAPVM b on b.VendorGroup = a.VendorGroup and b.Vendor = a.Vendor
	   where a.APCo = @APCo and a.YEMO = @Yemo and a.V1099Type= @Types and b.V1099YN = 'Y' and a.CorrectedFilingYN = 'Y' and
			a.CorrectedErrorType = 1
		Group By a.V1099Type, b.State
		Order By a.V1099Type, b.State
		end
	if @errortype = 2 -- vendor info or both
		begin
	   Select 'Box1Amt'=Sum (a.Box1Amt), 'Box2Amt'=sum (a.Box2Amt), 'Box3Amt'=sum (a.Box3Amt), 'Box4Amt'=sum (a.Box4Amt),
		 'Box5Amt'=sum (a.Box5Amt), 'Box6Amt'=sum (a.Box6Amt),'Box7Amt'=Sum (a.Box7Amt), 'Box8Amt'=Sum (a.Box8Amt), 
		 'Box9Amt'=Sum (a.Box9Amt),'Box10Amt'=Sum (a.Box10Amt), 'Box11Amt'=Sum (a.Box11Amt), 'Box12Amt'=Sum (a.Box12Amt),
		 'Box13Amt'=Sum (a.Box13Amt),'Box14Amt'=Sum (a.Box14Amt),'Box15Amt'=Sum (a.Box15Amt),'Box16Amt'=Sum (a.Box16Amt),
		 'Box17Amt'=Sum (a.Box17Amt),'Box18Amt'=Sum (a.Box18Amt),'State'=b.State,'1099Type'=a.V1099Type, 'Count'=count(*)
	   from bAPFT a
	   inner join bAPVM b on b.VendorGroup = a.VendorGroup and b.Vendor = a.Vendor
	   where a.APCo = @APCo and a.YEMO = @Yemo and a.V1099Type= @Types and b.V1099YN = 'Y' and a.CorrectedFilingYN = 'Y' and
			a.CorrectedErrorType > 1
		Group By a.V1099Type, b.State
		Order By a.V1099Type, b.State
		end
	end


--        (a.Box1Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box2Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
--   	 a.Box3Amt >= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end or
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
--         /*( a.Box1Amt>= @MinAmount or a.Box2Amt>= @MinAmount or a.Box3Amt>= @MinAmount or a.Box4Amt>= @MinAmount or
--         a.Box5Amt>= @MinAmount or a.Box6Amt>= @MinAmount or a.Box7Amt>= @MinAmount or a.Box8Amt>= @MinAmount or
--         a.Box9Amt>= @MinAmount or a.Box10Amt>= @MinAmount or a.Box11Amt>= @MinAmount or a.Box12Amt>= @MinAmount or
--         a.Box13Amt>= @MinAmount or a.Box14Amt>= @MinAmount or a.Box15Amt>= @MinAmount or a.Box16Amt>= @MinAmount or
--         a.Box17Amt>= @MinAmount or a.Box18Amt>= @MinAmount)*/ and 
--        (b.State = 'AL' or b.State = 'AZ' or b.State = 'AR' or b.State = 'CA' or b.State = 'CO' or b.State = 'DE' or 
--         b.State = 'DC' or b.State = 'GA' or b.State = 'HI' or b.State = 'ID' or b.State = 'IN' or b.State = 'IA' or 
--         b.State = 'KS' or b.State = 'ME' or b.State = 'MA' or b.State = 'MN' or b.State = 'MS' or b.State = 'MO' or
--         b.State = 'MT' or b.State = 'NJ' or b.State = 'NM' or b.State = 'ND' or b.State = 'SC' or b.State = 'WI' or 
--         b.State = 'LA' or b.State = 'MD' or b.State = 'NE' or b.State = 'NC' or b.State = 'VA' or b.State = 'CT' or
--		 b.State = 'UT')
--   Group By a.V1099Type, b.State
--   Order By a.V1099Type, b.State

GO
GRANT EXECUTE ON  [dbo].[bspHQAP1099State] TO [public]
GO
