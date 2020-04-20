SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[bspHQAP1099Export]
    /************************************
    * Created: 10/25/99 DANF
    * Modified: 07/11/00 DANF Added check for APVM 1099YN
    *           10/20/00 DANF Added GA
    *           06/29/01 DANF Added Rtrim to 1099 type
    *           10/22/01 DANF Added New box totals 14-18
    *		   07/02/2002 MV #16339 - override min amt by vendor
    *         11/12/02 DANF #19293 - Dividends min amounts are zero
    *			03/18/03 MV #20553 - select amounts = 0
    *			04/08/03 MV #20179 - remove GA filing
    *			08/19/05 MV #26693 - return TIN2 from bAPFT
    *			11/20/06 - MV 1099download recode
	*			07/06/09 - MV #132337 - total all boxes to evaluate
	*			08/04/09 - #124736 - update APFT with vendor info
	*			02/15/10 - #137772 - return CombinedYN flag to indicate if any of the
	*								records to be returned is for a participating fed/st filing
	*			10/01/2010 CHS - #138377 Added oregon	
	*			10/03/2011 CHS - D-03052 removed oregon
	*			10/17/11 - MV - TK-09070 get mailing address from APVM V1099AddressSeq else APVM Payment Address
	*
	*			PLEASE NOTE: IF YOU UPDATE LIST OF PARTICIPATING STATES HERE YOU MUST UPDATE FORM CODE FUNCTION 'StateNumericCodes'
    *
    * Pass in:
    *	@APCo        AP Company
    *	@YEMO        YEMO
    *	@Types       Type of 1099 being reported
    *	@MinAmount   Min amount of dollars to be reported
    *
    * Returns:
    *	Data related to the exporting of 1099 data
    *
    ***********************************/
    (@APCo bCompany, @Yemo bMonth, @Types varchar(10), @MinAmount bDollar) --, @GA VARCHAR(1))
   
   as
   set nocount on

	declare @combinedyn bYN
   
   if @Types = 'DIV' select @MinAmount = 0

-- return CombinedYN = 'Y' if any state included in the select below participates in the combined fed/state filing
	if exists (
	select * from bAPFT a
    inner join bAPVM b on b.VendorGroup = a.VendorGroup and b.Vendor = a.Vendor
    inner join bHQCO c on a.APCo = c.HQCo
    where a.APCo = @APCo and a.YEMO = @Yemo and RTRIM(a.V1099Type)= @Types and b.V1099YN = 'Y' and
		((isnull(a.Box1Amt,'0') + isnull(a.Box2Amt,'0') + isnull(a.Box3Amt,'0') + isnull(a.Box4Amt,'0') + isnull(a.Box5Amt,'0')
		+ isnull(a.Box6Amt,'0') + isnull(a.Box7Amt,'0') + isnull(a.Box8Amt,'0') + isnull(a.Box9Amt,'0') + isnull(a.Box10Amt,'0') 
		+ isnull(a.Box11Amt,'0') + isnull(a.Box12Amt,'0') + isnull(a.Box13Amt,'0') + isnull(a.Box14Amt,'0') + isnull(a.Box15Amt,'0')
		+ isnull(a.Box16Amt,'0') + isnull(a.Box17Amt,'0') + isnull(a.Box18Amt,'0'))>= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end) 
	and b.State in ('AL','AZ','AR','CA','CO','CT','DE','DC','GA','HI','ID','IN','IA','KS','LA','ME','MD','MA','MN','MS','MO','MT','NE',
		'NJ','NM','NC','ND','OH',
		--'OR', D-03052 -- 10/03/2011 CHS
		'SC','VA','WI','UT' ))
		
		begin
		Select @combinedyn = 'Y'
		end
	else
		begin
		select @combinedyn = 'N'
		end
   
    Select 'APCo'=a.APCo, 'VendorGroup'=a.VendorGroup, 'APFTVendor'=a.Vendor, 'YEMO'=a.YEMO ,'1099Type'=RTRIM(a.V1099Type),
          'Box1Amt'=a.Box1Amt, 'Box2Amt'=a.Box2Amt, 'Box3Amt'=a.Box3Amt, 'Box4Amt'=a.Box4Amt, 'Box5Amt'=a.Box5Amt,
		  'Box6Amt'=a.Box6Amt, 'Box7Amt'=a.Box7Amt,'Box8Amt'=a.Box8Amt, 'Box9Amt'=a.Box9Amt,'Box10Amt'=a.Box10Amt,
		  'Box11Amt'= a.Box11Amt,'Box12Amt'= a.Box12Amt,'Box13Amt'= a.Box13Amt,'Box14Amt'=a.Box14Amt,'Box15Amt'=a.Box15Amt,
		  'Box16Amt'=a.Box16Amt,'Box17Amt'= a.Box17Amt,'Box18Amt'=a.Box18Amt,'OtherData'= a.OtherData,'DivBox7FC'=a.DIVBox7FC,
		  'TIN2'=a.TIN2,'APVMVendor'=b.Vendor, 'APVMName'=b.Name,
		  'APVMAddress'= ISNULL(d.Address,b.Address),
		  'APVMCity'= ISNULL(d.City,b.City),
		  'APVMState'= ISNULL(d.State,b.State),
		  'APVMZip'= ISNULL(d.Zip,b.Zip),
		  'APVMAddress2'= ISNULL(d.Address2,b.Address2),
		  'TaxId'=b.TaxId ,'Prop'=b.Prop,'HQCoName'=c.Name, 'HQCoAddress'=c.Address,
		  'HQCOCity'=c.City,'HQCOState'=c.State, 'HQCOZip'=c.Zip, 'HQCOAddress2'=c.Address2,'FedTaxId'=c.FedTaxId,
		  'CombinedYN' = @combinedyn
   
    from bAPFT a
    inner join bAPVM b on b.VendorGroup = a.VendorGroup and b.Vendor = a.Vendor
    inner join bHQCO c on a.APCo = c.HQCo
    LEFT JOIN dbo.bAPAA d ON d.VendorGroup = a.VendorGroup and d.Vendor = a.Vendor AND b.V1099AddressSeq = d.AddressSeq
   
    where a.APCo = @APCo and a.YEMO = @Yemo and RTRIM(a.V1099Type)= @Types and b.V1099YN = 'Y' and
		((isnull(a.Box1Amt,'0') + isnull(a.Box2Amt,'0') + isnull(a.Box3Amt,'0') + isnull(a.Box4Amt,'0') + isnull(a.Box5Amt,'0')
		+ isnull(a.Box6Amt,'0') + isnull(a.Box7Amt,'0') + isnull(a.Box8Amt,'0') + isnull(a.Box9Amt,'0') + isnull(a.Box10Amt,'0') 
		+ isnull(a.Box11Amt,'0') + isnull(a.Box12Amt,'0') + isnull(a.Box13Amt,'0') + isnull(a.Box14Amt,'0') + isnull(a.Box15Amt,'0')
		+ isnull(a.Box16Amt,'0') + isnull(a.Box17Amt,'0') + isnull(a.Box18Amt,'0'))>= case b.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end)
    Order By a.V1099Type

	
	-- Update APFT with current vendor info
	Update a SET 
	OldVendorName=v.Name,
	OldVendorAddr= ISNULL(d.Address,v.Address),
	OldVendorCity= ISNULL(d.City,v.City),
	OldVendorState= ISNULL(d.State, v.State),
	OldVendorZip= ISNULL(d.Zip,v.Zip),
	OldVendorTaxId=v.TaxId
	From dbo.bAPFT a
	Join dbo.bAPVM v on v.VendorGroup=a.VendorGroup and v.Vendor=a.Vendor
	LEFT JOIN dbo.bAPAA d ON d.VendorGroup = a.VendorGroup and d.Vendor = a.Vendor AND v.V1099AddressSeq = d.AddressSeq
	where a.APCo = @APCo and a.YEMO = @Yemo and RTRIM(a.V1099Type)= @Types and v.V1099YN = 'Y' and
		((isnull(a.Box1Amt,'0') + isnull(a.Box2Amt,'0') + isnull(a.Box3Amt,'0') + isnull(a.Box4Amt,'0') + isnull(a.Box5Amt,'0')
		+ isnull(a.Box6Amt,'0') + isnull(a.Box7Amt,'0') + isnull(a.Box8Amt,'0') + isnull(a.Box9Amt,'0') + isnull(a.Box10Amt,'0') 
		+ isnull(a.Box11Amt,'0') + isnull(a.Box12Amt,'0') + isnull(a.Box13Amt,'0') + isnull(a.Box14Amt,'0') + isnull(a.Box15Amt,'0')
		+ isnull(a.Box16Amt,'0') + isnull(a.Box17Amt,'0') + isnull(a.Box18Amt,'0'))>= case v.OverrideMinAmtYN when 'Y' then 0 else @MinAmount end)  


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
         /*( a.Box1Amt>= @MinAmount or a.Box2Amt>= @MinAmount or a.Box3Amt>= @MinAmount or a.Box4Amt>= @MinAmount or
         a.Box5Amt>= @MinAmount or a.Box6Amt>= @MinAmount or a.Box7Amt>= @MinAmount or a.Box8Amt>= @MinAmount or
         a.Box9Amt>= @MinAmount or a.Box10Amt>= @MinAmount or a.Box11Amt>= @MinAmount or a.Box12Amt>= @MinAmount or
         a.Box13Amt>= @MinAmount or a.Box14Amt>= @MinAmount or a.Box15Amt>= @MinAmount or a.Box16Amt>= @MinAmount or
         a.Box17Amt>= @MinAmount or a.Box18Amt>= @MinAmount)*/
   /* END
   ELSE
    BEGIN
    Select a.APCo, a.VendorGroup, a.Vendor, a.YEMO ,RTRIM(a.V1099Type),
          a.Box1Amt, a.Box2Amt, a.Box3Amt, a.Box4Amt, a.Box5Amt, a.Box6Amt,
          a.Box7Amt, a.Box8Amt, a.Box9Amt, a.Box10Amt, a.Box11Amt, a.Box12Amt, a.Box13Amt,
          a.Box14Amt, a.Box15Amt, a.Box16Amt, a.Box17Amt, a.Box18Amt, a.OtherData,
          b.Vendor, b.Name, b.Address, b.City, b.State, b.Zip, b.Address2,
          b.TaxId , b.Prop, c.Name, c.Address, c.City, c.State, c.Zip, c.Address2, c.FedTaxId
   
    from bAPFT a
    inner join bAPVM b on b.VendorGroup = a.VendorGroup and b.Vendor = a.Vendor AND b.State = 'GA'
    inner join bHQCO c on a.APCo = c.HQCo
   
    where a.APCo = @APCo and a.YEMO = @Yemo and RTRIM(a.V1099Type)= @Types and b.V1099YN = 'Y' and
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
    Order By a.V1099Type
    END*/


GO
GRANT EXECUTE ON  [dbo].[bspHQAP1099Export] TO [public]
GO
