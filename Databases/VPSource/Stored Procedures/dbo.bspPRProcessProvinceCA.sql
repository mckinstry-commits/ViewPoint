
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[bspPRProcessProvinceCA]
/***********************************************************
* CREATED BY:	EN 3/28/08  #127015  added for Canada
* MODIFIED BY:	EN 5/15/09 #133697  default total claim passed to tax routines to null if filing status not set up
*				EN #137138  pass @capstock parameter to Northwest Territories tax routine (bspPR_CA_NTTxx)
*				CHS 10/15/2010 - #140541 - change bPRDB.EarnCode to EDLCode
*				EN 5/31/2013 - User Story 39007 / Task 51803 declare @addonrateamt as bUnitCost so that addon rates with more than 2 decimal places will work properly
*
* USAGE:
* Calculates Tax Province deductions and liabilities for a select Employee and Pay Seq.
* Called from main bspPRProcess procedure.  Based on bspPRProcessProvinceCA.
* Will  calculate most dedn/liab methods
*
* INPUT PARAMETERS
*   @prco		PR Company
*   @prgroup	PR Group
*   @prenddate	PR Ending Date
*   @employee	Employee to process
*   @payseq		Payment Sequence #
*   @ppds		# of pay periods in a year
*   @limitmth	Pay Period limit month
*   @stddays	standard # of days in Pay Period
*   @bonus		indicates a Bonus Pay Sequence - Y or N
*   @posttoall	earnings posted to all days in Pay Period - Y or N
*	@A			Annual Taxable Amount (Canada)
*   @PP			Canada Pension Plan or Quebec Pension Plan contribution for the pay period (Canada)
*   @maxCPP		maximum pension contribution
*   @EI			Employment Insurance premium for the pay period (Canada)
*   @maxEI		maximum EI contribution
*   @capstock	YTD deduction for acquisition of approved shares of the capital stock of a prescribed labour-sponsored venture capital corporation
*	@HD			annual deduction for living in a prescribed zone
*
* OUTPUT PARAMETERS
*   @errmsg  	Error message if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
     	@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
         @ppds tinyint, @limitmth bMonth, @stddays tinyint, @bonus bYN,
         @posttoall bYN, @A bDollar, @PP bDollar, @maxCPP bDollar,
		 @EI bDollar, @maxEI bDollar, @capstock bDollar, @HD bDollar, @errmsg varchar(255) output
     as
     set nocount on
    
     declare @rcode int, @resprovince varchar(4), @restaxdedn bEDLCode, @taxdedn bEDLCode, @res char(1),
     @province varchar(4), @rate bUnitCost, @calcdiff char(1), @calcamt bDollar, @procname varchar(30),
     @eligamt bDollar, @amt2dist bDollar, @accumelig bDollar, @accumsubj bDollar, @accumamt bDollar,
     @ytdelig bDollar, @ytdamt bDollar, @calcbasis bDollar, @accumbasis bDollar,
     @liabbasis bDollar, @provincetaxamt bDollar, @taxdiff char(1), @diff char(1), @basedon char(1),
     @sutaliab bEDLCode, @ytdsuielig bDollar, @miscamt bDollar, @overmiscamt bYN, @empmiscamt bDollar,
     @accumhrswks char(1), @sutahrswks bHrs, @fedtaxdedn bEDLCode, @fedfilestatus char(1), @fedexempts tinyint,
     @routineprovince varchar(4), @resident varchar(1),
     @exemptamt bDollar --issue 24545
    
    
     -- Standard deduction/liability variables
     declare @dlcode bEDLCode, @dldesc bDesc, @dltype char(1), @method varchar(10), @routine varchar(10),
     @rate1 bUnitCost, @rate2 bUnitCost, @seq1only bYN, @ytdcorrect bYN, @bonusover bYN, @bonusrate bRate,
     @limitbasis char(1), @limitamt bDollar, @limitperiod char(1), @limitcorrect bYN, @autoAP bYN,
     @vendorgroup bGroup, @vendor bVendor, @apdesc bDesc, @calccategory varchar (1), @rndtodollar bYN,
     @limitrate bRate, @empllimitrate bRate, @outaccumbasis bDollar /*issue 11030*/
    
     -- Employee deduction/liability override variables
     declare @filestatus char(1), @regexempts tinyint, @addexempts tinyint, @overcalcs char(1), @emprateamt bUnitCost,
     @overlimit bYN, @emplimit bDollar, @addontype char(1), @addonrateamt bUnitCost, @empvendor bVendor,
     @miscfactor bRate
    
     -- Payment Sequence Total variables
     declare @dtvendorgroup bGroup, @dtvendor bVendor, @dtAPdesc bDesc, @useover bYN, @overprocess bYN, @overamt bDollar

	-- declarations specific to Canada Taxes
	declare @TCP bDollar, @Scapstock bDollar
   
    -- cursor flags
    declare @openProvince tinyint, @openProvinceDL tinyint
    
    select @rcode = 0
 
    -- get Fed Tax and Filing Status for defaults
    select @fedfilestatus = 'S', @fedexempts = 0
    select @fedtaxdedn = TaxDedn
    from dbo.bPRFI with (nolock) where PRCo = @prco  -- already validated
    select @fedfilestatus = FileStatus, @fedexempts = RegExempts
    from dbo.bPRED with (nolock)
    where PRCo = @prco and Employee = @employee and DLCode = @fedtaxdedn
    
    -- get Employee's Resident Tax Province info ... #127015 also get info needed for Saskatchewan tax computation
    select @resprovince = TaxState, @Scapstock = isnull(LCPStock,0)
    from dbo.bPREH with (nolock)
    where PRCo = @prco and Employee = @employee
     if @@rowcount = 0
         begin
         select @errmsg = 'Missing Employee header entry!', @rcode = 1
         goto bspexit
         end
    
     -- see if difference between posted and resident Province Tax will need to be calculated
     select @restaxdedn = null, @taxdiff = 'N'
    
     if @resprovince is not null
         begin
         select @restaxdedn = TaxDedn, @taxdiff = TaxDiff
         from dbo.bPRSI with (nolock) where PRCo = @prco and State = @resprovince
         end
    
     -- create cursor for posted Provinces
     declare bcProvince cursor for
      select distinct TaxState, 'T'       -- 'T' used for Tax Province
         from dbo.bPRTH
         where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
         union
         select distinct UnempState, 'U'    -- 'U' used for Unemployment Province
         from dbo.bPRTH
         where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq

    
     open bcProvince
    
     select @openProvince = 1
    
     -- loop through Provinces
     next_Province:
    
         fetch next from bcProvince into @province, @basedon
         if @@fetch_status = -1 goto end_Province
         if @@fetch_status <> 0 goto next_Province
    
         -- save Province's Tax Dedn for possible difference calculation
         if @basedon = 'T'
             begin
             select @taxdedn = TaxDedn from dbo.bPRSI with (nolock) where PRCo = @prco and State = @province
             end
    
         -- save Province's Unemployment liability - needs special limit handling
         if @basedon = 'U'
             begin
             select @sutaliab = SUTALiab, @accumhrswks = AccumHrsWks
             from dbo.bPRSI with (nolock) where PRCo = @prco and State = @province
             end
    
         -- check for residency - controls rates
         select @res = 'N'
         if @province = @resprovince select @res = 'Y'
    
         -- clear Process Earnings
         delete dbo.bPRPE where VPUserName = SUSER_SNAME()
    
         if @basedon = 'T'
         	begin
         	-- load Process Earnings with all earnings posted to this Tax Province
         	insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt ) --issue 20562
            select SUSER_SNAME(), t.PostSeq, t.PostDate, t.EarnCode, e.Factor, e.IncldLiabDist, t.Hours, t.Rate, t.Amt --issue 20562
            from dbo.bPRTH t
            join dbo.bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
            where t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
                     and t.PaySeq = @payseq and t.TaxState = @province
         	insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt )    -- Addons --issue 20562
            select SUSER_SNAME(), t.PostSeq, t.PostDate, a.EarnCode, e.Factor, e.IncldLiabDist, 0, a.Rate, a.Amt --issue 20562
            from dbo.bPRTA a
            join dbo.bPRTH t on t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate and
                 t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
            join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
            where a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate and a.Employee = @employee
    
                 and a.PaySeq = @payseq and t.TaxState = @province
            end
    
         if @basedon = 'U'
         	begin
         	-- load Process Earnings with all earnings posted to this Unemployment Province
         	insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt )   -- Timecards --issue 20562
            select SUSER_SNAME(), t.PostSeq, t.PostDate, t.EarnCode, e.Factor, e.IncldLiabDist, t.Hours, t.Rate, t.Amt --issue 20562
            from dbo.bPRTH t
            join dbo.bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
            where t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
          and t.PaySeq = @payseq and t.UnempState = @province
         	insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt )   -- Addons --issue 20562
            select SUSER_SNAME(), t.PostSeq, t.PostDate, a.EarnCode, e.Factor, e.IncldLiabDist, 0, a.Rate, a.Amt --issue 20562
        from dbo.bPRTA a
            join dbo.bPRTH t on t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate and
                 t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
            join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
            where a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate and a.Employee = @employee
                 and a.PaySeq = @payseq and t.UnempState = @province
            end
    
    
         -- create cursor for Tax Province DLs - resident 'N' or 'Y' and Dedn/Liab code and Difference flag - 'N' = don't calc diff, 'Y' = calc diff
         -- process resident 'Y' last for correct calculation of tax difference.
         if @basedon = 'T'
             begin
             declare bcProvinceDL cursor for
             select 'N' AS CalcDiff, TaxDedn from dbo.bPRSI with (nolock) where PRCo = @prco and State = @province and TaxDedn is not null
             union
             select 'N' AS CalcDiff, DLCode from dbo.bPRSD with (nolock) where PRCo = @prco and State = @province and BasedOn = 'T'
             union
             select 'Y' AS CalcDiff, @restaxdedn where @restaxdedn is not null and @taxdiff = 'Y' and @taxdedn <> @restaxdedn
             Order by CalcDiff, TaxDedn
             end
    
         -- create a cursor for Unemployment Province DLs - no difference calculations
         if @basedon = 'U'
             begin
             declare bcProvinceDL cursor for
             select 'N' AS CalcDiff,SUTALiab from dbo.bPRSI with (nolock) where PRCo = @prco and State = @province and SUTALiab is not null
             union
             select 'N' AS CalcDiff,DLCode from dbo.bPRSD with (nolock) where PRCo = @prco and State = @province and BasedOn = 'U'
             end

   
         open bcProvinceDL
         select @openProvinceDL = 1
    
         -- loop through Province DL cursor
         next_ProvinceDL:
             fetch next from bcProvinceDL into @calcdiff,@dlcode
             if @@fetch_status = -1 goto end_ProvinceDL
    
             if @@fetch_status <> 0 goto next_ProvinceDL
    
    
             -- get standard DL info
             select @dldesc = Description, @dltype = DLType, @method = Method, @routine = Routine, @rate1 = RateAmt1,
                 @rate2 = RateAmt2, @seq1only = SeqOneOnly, @ytdcorrect = YTDCorrect, @bonusover = BonusOverride,
                 @bonusrate = BonusRate, @limitbasis = LimitBasis, @limitamt = LimitAmt, @limitperiod = LimitPeriod,
                 @limitcorrect = LimitCorrect, @autoAP = AutoAP, @vendorgroup = VendorGroup, @vendor = Vendor,
    	     @calccategory = CalcCategory, @rndtodollar=RndToDollar, @limitrate = LimitRate /*issue 11030*/
             from dbo.bPRDL with (nolock)
             where PRCo = @prco and DLCode = @dlcode
             if @@rowcount = 0
                 begin
     		    select @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' not setup!', @rcode = 1
    
     		    goto bspexit
     		    end
    
    	 /* validate calccategory*/
    	if @calccategory not in ('S','A')
    		begin
    		select @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' should be calculation category S or A!', @rcode = 1
     		goto bspexit
     		end
    
             -- check for Payment Sequence #1 restriction
             if @seq1only = 'Y' and @payseq <> 1 goto next_ProvinceDL
    
             select @rate = @rate2       -- non-resident rate
             if @res = 'Y' or @dlcode = @restaxdedn select @rate = @rate1    -- resident rate
    
             -- get Employee info and overrides for this dedn/liab
             select @filestatus = @fedfilestatus, @regexempts = @fedexempts, @addexempts = 0, @overmiscamt = 'N',
             	@empmiscamt = 0.00, @miscfactor = 0.00, @empvendor = null, @apdesc = null,
             	@overcalcs = 'N', @overlimit = 'N', @addontype = 'N'
             select @filestatus = FileStatus, @regexempts = RegExempts, @addexempts = AddExempts, @overmiscamt = OverMiscAmt,
             	@empmiscamt = MiscAmt, @miscfactor = MiscFactor, @empvendor = Vendor, @apdesc = APDesc,
             	@overcalcs = OverCalcs, @emprateamt = isnull(RateAmt,0.00), @overlimit = OverLimit, @emplimit = isnull(Limit,0.00),
             	@addontype = AddonType, @addonrateamt = isnull(AddonRateAmt,0.00),
    			@empllimitrate = isnull(LimitRate,0.00), /*issue 11030*/
				@TCP = MiscAmt2 --#127015 Total Claim amount
             from dbo.bPRED with (nolock)
             where PRCo = @prco and Employee = @employee and DLCode = @dlcode
    
     	if @regexempts is null select @regexempts = 0
     	if @addexempts is null select @addexempts = 0
    
             -- check for calculation override on Bonus sequence
             if @bonus = 'Y' and @bonusover = 'Y' select @method = 'G', @rate = @bonusrate
    
             -- check for Employee calculation and rate overrides
             if @overcalcs = 'M' select @method = 'G', @rate = @emprateamt
             if @overcalcs = 'R' select @rate = @emprateamt
             if @overlimit = 'Y' select @limitamt = @emplimit
    		 if @overlimit = 'Y' select @limitrate = @empllimitrate /*issue 11030*/
    
             -- get calculation, accumulation, and liability distribution basis
             exec @rcode = bspPRProcessGetBasis @prco, @prgroup, @prenddate, @employee, @payseq, @method,
                 @posttoall, @dlcode, @dltype, @stddays, @calcbasis output, @accumbasis output, --issue 20562
                 @liabbasis output, @errmsg output
             if @rcode <> 0 goto bspexit
    
     	 select @sutahrswks = 0		-- initialize SUTA hrs/weeks
    
             -- check for 0 basis - skip accumulations and calculations
             if @calcbasis = 0.00
                 begin
                 select @calcamt = 0.00, @eligamt = 0.00
                 goto calc_end
                 end
    
             -- accumulate actual, subject, and eligible amounts if needed
             if @limitbasis = 'C' or @limitbasis = 'S' or @ytdcorrect = 'Y'
                 begin
                 exec @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
                     @dlcode, @dltype, @limitperiod, @limitmth, @ytdcorrect, @accumamt output,
    
                     @accumsubj output, @accumelig output, @ytdamt output, @ytdelig output, @errmsg output
                 if @rcode <> 0 goto bspexit
                 end
    
             -- if SUTA liability accum year-to-date eligible earnings for all SUTA liabilities
    
             -- assumes reciprocal agreements among all Provinces, method is 'G',
             -- limit based on 'subject earnings', applied 'annually', limit and ytd correct are both 'N'
             if @dlcode = @sutaliab
                 begin
    
                 exec @rcode = bspPRProcessGetYTDSUIElig @prco, @prgroup, @prenddate, @employee, @payseq,
                 	@ytdsuielig output, @errmsg output
                 if @rcode <> 0 goto bspexit
    
                 select @accumelig = @ytdsuielig	-- use ytd sui eligible for accumulated eligible
    
    
                 -- get Hours or Weeks for Unemployement Liab
                 if @accumhrswks = 'H'
                 	begin
    
                 	 -- accumulate subject hours
         		select @sutahrswks = isnull(sum(e.Hours),0.00)
    
         		from dbo.bPRPE e with (nolock)
         		join dbo.bPRDB b with (nolock) on b.EDLCode = e.EarnCode
         		where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
                 	end
                 if @accumhrswks = 'W' and @payseq = 1	-- only count weeks on Pay Seq #1
                 	begin
                 	select @sutahrswks = Wks
                 	from dbo.bPRPC with (nolock) where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                 	end
                 end
    
    
             -- Calculations
    
             select @calcamt = 0.00, @eligamt = 0.00
    
             -- Flat Amount
    
             if @method = 'A'
     		  begin
     		  exec @rcode = bspPRProcessAmount @calcbasis, @rate, @limitbasis, @limitamt, @limitcorrect, @accumelig,
     			 @accumsubj, @accumamt, @ytdelig, @ytdamt, @calcamt output, @eligamt output, @errmsg output
     		  if @rcode<> 0 goto bspexit
     		  end
    
     	   -- Rate per Day, Factored Rate per Hour, Rate of Gross, Rate per Hour, Straight Time Equivalent, or Rate of Dedn
             if @method in ('D', 'F', 'G', 'H', 'S', 'DN')
     		  begin
     		  exec @rcode = bspPRProcessRateBased @calcbasis, @rate, @limitbasis, @limitamt, @ytdcorrect,
                     @limitcorrect, @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt,
    				 @accumbasis, @limitrate, @outaccumbasis output, --issue 11030 adjust for changes in bspPRProcessRateBased
    				 @calcamt=@calcamt output, @eligamt=@eligamt output, @errmsg=@errmsg output
              if @rcode<> 0 goto bspexit
    		  select @accumbasis = @outaccumbasis --issue 11030 basis may be adjusted to fit rate of earnings limit scheme
     		  end
    
     	   -- Routine
     	   if @method = 'R'
     		  begin
     		  -- get procedure name
     		  select @procname = null
     		  select @procname = ProcName, @miscamt = MiscAmt1
     		  from dbo.bPRRM with (nolock)
     		  where PRCo = @prco and Routine = @routine
     		  if @procname is null
     			 begin
     			 select @errmsg = 'Missing Routine procedure name for dedn/liab ' + convert(varchar(4),@dlcode), @rcode = 1
     			 goto bspexit
    			 end
              if not exists(select * from sysobjects where name = @procname and type = 'P')
                 begin
                 select @errmsg = 'Invalid Routine procedure - ' + @procname, @rcode = 1
                 goto bspexit
                 end
    
     		  if @overmiscamt = 'Y' select @miscamt = @empmiscamt	-- use Employee override
    
              -- assign Tax Routine Province, may be posted Province or resident
              select @routineprovince = @province
              if @calcdiff = 'Y' select @routineprovince = @resprovince
   
			  -- Call various provincial/territorial tax routines
     		  if @routineprovince in ('NL', 'NS', 'NB', 'MB', 'NT', 'YT')
     		  	begin
     		  	exec @rcode = @procname @ppds, @A, @TCP, @PP, @maxCPP, @EI, @maxEI, @miscamt, @capstock, @calcamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				if @@error <> 0 select @rcode = 1
     		  	goto routine_end
     		  	end 

     		  if @routineprovince in ('SK')
     		  	begin
     		  	exec @rcode = @procname @ppds, @A, @TCP, @PP, @maxCPP, @EI, @maxEI, @miscamt, @Scapstock, @capstock, @calcamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				if @@error <> 0 select @rcode = 1
     		  	goto routine_end
     		  	end 

     		  if @routineprovince in ('PE', 'AB', 'NU')
     		  	begin
     		  	exec @rcode = @procname @ppds, @A, @TCP, @PP, @maxCPP, @EI, @maxEI, @miscamt, @calcamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				if @@error <> 0 select @rcode = 1
     		  	goto routine_end
     		  	end 

     		  if @routineprovince in ('ON')
     		  	begin
     		  	exec @rcode = @procname @ppds, @A, @TCP, @addexempts, @PP, @maxCPP, @EI, @maxEI, @miscamt, @capstock, 
					@calcamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				if @@error <> 0 select @rcode = 1
     		  	goto routine_end
     		  	end 

     		  if @routineprovince in ('BC')
     		  	begin
     		  	exec @rcode = @procname @ppds, @A, @TCP, @PP, @maxCPP, @EI, @maxEI, @miscamt, @HD, @capstock, 
					@calcamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				if @@error <> 0 select @rcode = 1
     		  	goto routine_end
     		  	end 

        	  select @errmsg = 'Missing or invalid province/territory routine for Dedn/liab code ' + convert(varchar(4),@dlcode), @rcode = 1
    		  goto bspexit

     		  routine_end:
     		  	if @rcode <> 0 goto bspexit
     		  	if @calcamt is null select @calcamt = 0.00
     		  	select @eligamt = @calcbasis
     		  end
    
             -- apply Employee calculation override
             if @overcalcs = 'A' select @calcamt = @emprateamt
    
             -- apply Employee addon amounts - only applied if calculated amount is positive
             if @calcbasis > 0.00
    
                 begin
     		    if @addontype = 'A' select @calcamt = @calcamt + @addonrateamt
     		    if @addontype = 'R' select @calcamt = @calcamt + (@calcbasis * @addonrateamt)
     		    end
    
    
             -- save calculated Province Tax amount
             if @dlcode = @taxdedn select @provincetaxamt = @calcamt
    
             -- check for Resident Province Tax difference - set to 0 if equal or less than posted Province tax
             if @dlcode = @restaxdedn and @calcdiff = 'Y'
                 begin
                 if @calcamt <= @provincetaxamt select @calcamt = 0.00
                 if @calcamt > @provincetaxamt select @calcamt = @calcamt - @provincetaxamt
                 end
    
    	if @rndtodollar='Y'	select @calcamt = ROUND(@calcamt,0) --round to the nearest dollar
    	
     	   calc_end:	 -- Finished with calculations
     	   -- get AP Vendor and Transaction description
     	   select @dtvendorgroup = null, @dtvendor = null, @dtAPdesc = null
    
     	   if @autoAP = 'Y'
     		  begin
     		  select @dtvendorgroup = @vendorgroup, @dtvendor = @vendor, @dtAPdesc = @dldesc
     		  if @empvendor is not null select @dtvendor = @empvendor
     		  if @apdesc is not null select @dtAPdesc = @apdesc
     		 end
    
     	   -- update Payment Sequence Totals
     	   update dbo.bPRDT
            set Amount = Amount + @calcamt, SubjectAmt = SubjectAmt + @accumbasis, EligibleAmt = EligibleAmt + @eligamt,
            	VendorGroup = @dtvendorgroup, Vendor = @dtvendor, APDesc = @dtAPdesc
     		  where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
     		      and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
     	   if @@rowcount = 0
     		  begin
     		  insert dbo.bPRDT (PRCo, PRGroup, PREndDate, Employee, PaySeq, EDLType, EDLCode, Hours, Amount, SubjectAmt, EligibleAmt,
    
     			 UseOver, OverAmt, OverProcess, VendorGroup, Vendor, APDesc, OldHours, OldAmt, OldSubject, OldEligible, OldMth,
                  			OldVendor, OldAPMth, OldAPAmt)
     		  values (@prco, @prgroup, @prenddate, @employee, @payseq, @dltype, @dlcode, 0, @calcamt, @accumbasis, @eligamt,
     			 'N', 0, 'N', @dtvendorgroup, @dtvendor, @dtAPdesc, 0, 0, 0, 0, null, null, null, 0)
    	       	if @@rowcount <> 1
    			begin
    			select @errmsg = 'Unable to add PR Detail Entry for Employee ' + convert(varchar(6),@employee), @rcode = 1
    			goto bspexit
    			end
     		  end
    		
     	-- SUTA updates
     	if @dlcode = @sutaliab
     		begin
     		-- update SUTA Hours/Weeks to Payment Sequence Totals
     		update dbo.bPRDT
     		set Hours = Hours + @sutahrswks
     		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
     		      and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
     	 	end
    
    
             -- check for Override processing
             select @useover = UseOver, @overamt = OverAmt, @overprocess = OverProcess
             from dbo.bPRDT with (nolock)
             where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
     		  and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
    
             if @overprocess = 'Y' goto next_ProvinceDL
    
    
             -- an overridden DL amount is processed only once
     	    if @useover = 'Y'
     		  begin
     		  update dbo.bPRDT
               set OverProcess = 'Y' where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                 and Employee = @employee and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
     		  end
    
             -- check for Liability distribution - needed even if basis and/or amount are 0.00
             if @dltype <> 'L' goto next_ProvinceDL
    
             -- use calculated amount unless overridden
     		select @amt2dist = @calcamt
    		-- #23655 fix to use override amt even if calc basis = 0
     		if @useover = 'Y' /*and @calcbasis <> 0.00*/ select @amt2dist = @overamt
    
     		-- no need to distribute if Basis <> 0 and Amt = 0, but will distibute if both are 0.00
             -- because of possible offsetting timecard entries
             if @calcbasis <> 0.00 and @amt2dist = 0.00 goto next_ProvinceDL
    
             -- call procedure to distribute liability amount
             exec @rcode = bspPRProcessLiabDist @prco, @prgroup, @prenddate, @employee, @payseq, @dlcode,
                     @method, @rate, @liabbasis, @amt2dist, @posttoall, @errmsg output --issue 20562
             if @rcode <> 0 goto bspexit
    
             goto next_ProvinceDL
    
         end_ProvinceDL:
             close bcProvinceDL
             deallocate bcProvinceDL
             select @openProvinceDL = 0
             goto next_Province
    
     end_Province:
    
         close bcProvince
         deallocate bcProvince
    
    
         select @openProvince = 0
    
    
     bspexit:
         -- clear Process Earnings
    
         delete dbo.bPRPE where VPUserName = SUSER_SNAME()
    
         if @openProvinceDL = 1
             begin
        		close bcProvinceDL
         	deallocate bcProvinceDL
           	end
         if @openProvince = 1
             begin
        		close bcProvince
         	deallocate bcProvince
           	end
     	return @rcode

GO

GRANT EXECUTE ON  [dbo].[bspPRProcessProvinceCA] TO [public]
GO
