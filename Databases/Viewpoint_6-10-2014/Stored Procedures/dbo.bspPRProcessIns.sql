SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRProcessIns]
/***********************************************************
* CREATED BY: 	GG  04/17/98
* MODIFIED BY: GG  04/09/99
*              LM  06/15/99 - Added username column to PRPE for SQL 7.0
*              GG 07/05/99 - Added routine procedure check
*              GG 01/06/00 - fixed AP Vendor info update to bPRDT
*              danf 08/17/00 - remove reference to system id
*              EN 9/7/00 - exec NY Worker's Comp routine
*              EN 9/14/00 - calculate NY Worker's Comp using STE wages
*              EN 9/29/00 - NY Worker's comp only needs eligible amt to be STE, not subj amount
*                              and WC is calculated off of that eligible amt
*              GG 01/30/01 - skip calculations for both dedns and liabs if calculation basis = 0 (#11690)
*              GG 03/30/01 - fix to update bPRIA.Amt with override amount one time only
*              GG 04/03/01 - added EligibleAmt to bPRIA (#12461)
*		MV 1/28/02 - issue 15711 - check for correct CalcCategory
*			   - issue 13977 - round @calcamt if RndToDollar flag is set.
*              EN 2/22/02 - issue 16377 - insert bPRIA was missing field list
*				EN 10/9/02 - issue 18877 change double quotes to single
*				GG 03/17/03 - #20441 - add BasisEarnings and CalcBasis to bPRIA 
*				EN 3/24/03 - issue 11030 rate of earnings liability limit
*				EN 7/28/04 - issue 24545  call new routine bspPRExemptRateOfGross
*				EN 9/24/04 - issue 20562  change from using bPRCO_LiabDist to bPREC_IncldLiabDist to determine whether an earnings code is included in liab distribs
*				EN 3/22/05 - issue 27058  for addon overtime earnings compute factor as rate/factor 1 rate to get true factor for STE D/L computations
*				EN 4/8/05 - issue 28379  added @@error check to see if SQL error occured when routine was called
*				GG 6/24/05 - #29079 - fix to STE calcs on variable rate addon earings (#27058)
*				GG 11/29/05 - #30687 - pull Craft Template for variable rate add-ons
*				EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
*				mh 1/24/09 - #124562 - Update bPRIA.Hours from bPRPE
*				EN 2/24/09 #132018 for Ohio worker's comp allow for pay periods other than just weekly
*				CHS 10/15/2010 - #140541 - change bPRDB.EarnCode to EDLCode 
*				MV 05/9/11 - #123529 - Factor based Add-ons not calcuating PRIA with STE earnings 
*				MV 10/14/2013	64211/64212 Incorrect deduction amt if bPRSI 'Post Deff to Resident State' = Y. Pass 2 more param values to bspPRProcessGetBasis
*
*
* USAGE:
* Calculates State Insurance deductions and liabilities for a select Employee and Pay Seq.
* Called from main bspPRProcess procedure.
* Will calculate most dedn/liab methods.
*
* INPUT PARAMETERS
*   @prco	    PR Company
*   @prgroup	PR Group
*   @prenddate	PR Ending Date
*   @employee	Employee to process
*   @payseq	Payment Sequence #
*   @ppds      # of pay periods in a year
*   @limitmth  Pay Period limit month
*   @stddays   standard # of days in Pay Period
*   @bonus     indicates a Bonus Pay Sequence - Y or N
*   @posttoall earnings posted to all days in Pay Period - Y or N
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
       @posttoall bYN, @errmsg varchar(255) output
   
   as
   set nocount on
   
   declare @rcode int, @rate bUnitCost, @calcamt bDollar, @procname varchar(30), @eligamt bDollar,
   @amt2dist bDollar, @accumelig bDollar, @accumsubj bDollar, @accumamt bDollar, @ytdelig bDollar,
   @ytdamt bDollar, @calcbasis bDollar, @accumbasis bDollar, @amtdist bDollar,
   @postseq smallint, @amt bDollar, @hrs bHrs, @factor bRate, @incldliabdist char(1), @overrate bUnitCost, --issue 20562
   @liabbasis bDollar, @state varchar(4), @inscode bInsCode, @earns bDollar, @earnlimit bDollar, @basisused bDollar,
   @basisearns bDollar,
   @exemptamt bDollar, --issue 24545
   @prpe_hrs bHrs -- 124562
   -- NY WC eligible amount
   declare @nycalcbasis bDollar
   
   -- Standard deduction/liability variables
   declare @dlcode bEDLCode, @dldesc bDesc, @dltype char(1), @method varchar(10), @routine varchar(10),
   @seq1only bYN, @ytdcorrect bYN, @bonusover bYN, @bonusrate bRate, @limitbasis char(1),
   @limitamt bDollar, @limitperiod char(1), @limitcorrect bYN, @autoAP bYN, @vendorgroup bGroup,
   @vendor bVendor, @apdesc bDesc, @calccategory varchar (1), @rndtodollar bYN,
   @limitrate bRate, @empllimitrate bRate, @outaccumbasis bDollar /*issue 11030*/
   
   -- Employee deduction/liability override variables
   declare @filestatus char(1), @regexempts tinyint, @overcalcs char(1), @emprateamt bUnitCost, @overlimit bYN,
   
   @emplimit bDollar, @addontype char(1), @addonrateamt bDollar, @empvendor bVendor
   
   -- Payment Sequence Total variables
   declare @dtvendorgroup bGroup, @dtvendor bVendor, @dtAPdesc bDesc, @useover bYN, @overprocess bYN, @overamt bDollar
   
   -- cursor flags
   declare @openIns tinyint, @openInsDL tinyint
   
   --27058
   declare @openVarAddon tinyint, @effectdate bDate, @template smallint, @steRate bUnitCost, @steFactor bRate,
   	@pePostSeq smallint, @pePostDate bDate, @peEarnCode bEDLCode, @peFactor bUnitCost, 
   	@peIncldLiabDist bYN, @peHours bHrs, @peRate bUnitCost, @peAmt bDollar, @peJCCo bCompany, @peJob bJob,
   	@peCraft bCraft, @peClass bClass, @oldrate bUnitCost, @newrate bUnitCost, @openFactoredAddon tinyint
   
   --#132018
   declare @weeks tinyint

   select @rcode = 0, @openFactoredAddon = 0
   
   -- create cursor for all posted State Insurance Codes
   declare bcIns cursor for select distinct InsState, InsCode
   
   from bPRTH
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
   	and PaySeq = @payseq and InsState is not null and InsCode is not null
   
   open bcIns
   select @openIns = 1
   
   -- loop through State Insurance Codes
   next_Ins:
       fetch next from bcIns into @state, @inscode
       if @@fetch_status = -1 goto end_Ins
       if @@fetch_status <> 0 goto next_Ins
   
       -- get std Insurance Code info - weekly earnings limit used only in Ohio
       select @earnlimit = isnull(EarnLimit,0.00)
       from dbo.bPRIN with (nolock)
       where PRCo = @prco and State = @state and InsCode = @inscode
       if @@rowcount = 0
           begin
           select @errmsg = 'Missing State Insurance code ' + @state + @inscode, @rcode = 1
           goto bspexit
           end
   
	   -- #132018 for Ohio worker's comp, find weeks in Pay Period Control
	   if @state = 'OH'
		begin
		select @weeks = Wks
		from dbo.bPRPC with (nolock)
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		if @@rowcount = 0
			begin
			select @errmsg = 'PR Group and Ending Date not setup in Pay Period Control!', @rcode = 1
			goto bspexit
			end
		end

       -- clear Process Earnings
       delete dbo.bPRPE where VPUserName = SUSER_SNAME()
   
      -- load Process Earnings with all earnings posted to this State Insurance Code
       insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt )   -- Timecards --issue 20562
           select SUSER_SNAME(), h.PostSeq, h.PostDate, h.EarnCode, e.Factor, e.IncldLiabDist, h.Hours, h.Rate, h.Amt --issue 20562
           from dbo.bPRTH h
           join dbo.bPREC e with (nolock) on e.PRCo = h.PRCo and e.EarnCode = h.EarnCode
           where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
               and h.Employee = @employee and h.PaySeq = @payseq
               and h.InsState = @state and h.InsCode = @inscode
   
       insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt )  -- Addons --issue 20562
           select SUSER_SNAME(), a.PostSeq, t.PostDate, a.EarnCode, e.Factor, e.IncldLiabDist, 0, a.Rate, a.Amt --issue 20562
           from dbo.bPRTA a
           join dbo.bPRTH t on t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate
               and t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
           join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
         where a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate
               and a.Employee = @employee and a.PaySeq = @payseq
               and t.InsState = @state and t.InsCode = @inscode
   
   	--#27058 check for any DLs based on STE 
   	if exists
   		(
   			select top 1 1 
   			from dbo.bPRID i (nolock)
   			join dbo.bPRDL d (nolock) on i.PRCo = d.PRCo and i.DLCode = d.DLCode
   			where i.PRCo = @prco and i.State = @state and i.InsCode = @inscode and d.Method = 'S'
   		)
   	BEGIN -- DLs based on STE
   		-- find any Craft/Class variable addon earnings posted with overtime subject to this Insurance code
   		declare bcVarAddon cursor for 
   		select a.PostSeq, t.PostDate, a.EarnCode, e1.Factor, e1.IncldLiabDist, 0, a.Rate, a.Amt, 
   			t.JCCo, t.Job, t.Craft, t.Class
   		from dbo.bPRTA a
   		join dbo.bPRTH t on t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate
   	    	and t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
   		join dbo.bPREC e1 with (nolock) on e1.PRCo = a.PRCo and e1.EarnCode = a.EarnCode
   		join dbo.bPREC e2 with (nolock) on e2.PRCo = t.PRCo and e2.EarnCode = t.EarnCode
   		where a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate and a.Employee = @employee and a.PaySeq = @payseq 
   			and t.InsState = @state and t.InsCode = @inscode and e1.Method='V' and e2.Factor<>1	-- overtime
   	
   		open bcVarAddon
   		select @openVarAddon = 1
   	
   		--loop through Variable Addon cursor
   		next_VarAddon:
   	    	fetch next from bcVarAddon into @pePostSeq, @pePostDate, @peEarnCode, @peFactor,
   				@peIncldLiabDist, @peHours, @peRate, @peAmt, @peJCCo, @peJob, @peCraft, @peClass
   	    	if @@fetch_status = -1 goto end_VarAddon
   	    	if @@fetch_status <> 0 goto next_VarAddon
   
   			-- get for Job Craft Template (if any) 
   			set @template = null
   			if @peJob is not null
   				select @template = CraftTemplate	-- #30687 pull Craft Template
   				from dbo.bJCJM (nolock)
   				where JCCo = @peJCCo and Job = @peJob
   
   			-- get Craft Class Addon Rate for Straight Time, possible override by Template
      			select @oldrate = 0.00, @newrate = 0.00
               select @oldrate = OldRate, @newrate = NewRate
   			from dbo.bPRCI (nolock)
   			where PRCo = @prco and Craft = @peCraft and EDLType = 'E' and EDLCode = @peEarnCode and Factor = 1
      			
   			select @oldrate = OldRate, @newrate = NewRate
   			from dbo.bPRCF (nolock)
   			where PRCo = @prco and Craft = @peCraft and Class = @peClass and EarnCode = @peEarnCode and Factor = 1
   
   			if @template is not null
   				begin
               	select @oldrate = OldRate, @newrate = NewRate
   				from dbo.bPRTI (nolock)
   				where PRCo = @prco and Craft = @peCraft and Template = @template and EDLType = 'E'
   					and EDLCode = @peEarnCode and Factor = 1
   
      				select @oldrate = OldRate, @newrate = NewRate
   				from dbo.bPRTF (nolock)
   				where PRCo = @prco and Craft = @peCraft and Class = @peClass and Template = @template
      					and EarnCode = @peEarnCode and Factor = 1
   				end
   
      			-- get Effective Date to determine rates 
   			select @effectdate = EffectiveDate
   			from dbo.bPRCM (nolock)
   			where PRCo = @prco and Craft = @peCraft
   			if @template is not null
   				select @effectdate = EffectiveDate
   				from dbo.bPRCT (nolock)
   				where PRCo=@prco and Craft = @peCraft and Template = @template and OverEffectDate = 'Y'
   	
      			-- Straight Time rate
      			select @steRate = case when @effectdate > @pePostDate then @oldrate else @newrate end
   
   			if @steRate <> 0
   				begin
    				-- calculate the true factor for addon earnings using posted and straight time rates
   				select @steFactor=@peRate/@steRate
   	
   				update dbo.bPRPE
   				set Factor=@steFactor
   				where VPUserName = suser_sname() and PostSeq=@pePostSeq and PostDate = @pePostDate
   					and EarnCode = @peEarnCode and Factor = @peFactor and IncldLiabDist = @peIncldLiabDist
   					and Hours = @peHours and Rate = @peRate and Amt = @peAmt
   				end
   	
   			goto next_VarAddon
   		--#27058 end
   	
   		end_VarAddon:
       		close bcVarAddon
       		deallocate bcVarAddon
       		select @openVarAddon = 0
   		--end
   		
		--BEGIN issue #123529 - Factor based Add-ons not calcuating PRIA with STE earnings
		-- find any Craft/Class factored addon earnings posted with overtime subject to this Insurance code #123529
   		DECLARE bcFactoredAddon CURSOR FOR 
   		SELECT a.PostSeq, t.PostDate, a.EarnCode, e1.Factor, e1.IncldLiabDist, 0, a.Rate, a.Amt, 
   			t.JCCo, t.Job, t.Craft, t.Class
   		FROM dbo.bPRTA a
   		JOIN dbo.bPRTH t ON t.PRCo = a.PRCo AND t.PRGroup = a.PRGroup AND t.PREndDate = a.PREndDate
   	    	AND t.Employee = a.Employee AND t.PaySeq = a.PaySeq AND t.PostSeq = a.PostSeq
   		JOIN dbo.bPREC e1 WITH (NOLOCK) ON e1.PRCo = a.PRCo AND e1.EarnCode = a.EarnCode
   		JOIN dbo.bPREC e2 WITH (NOLOCK) ON e2.PRCo = t.PRCo AND e2.EarnCode = t.EarnCode
   		WHERE a.PRCo = @prco AND a.PRGroup = @prgroup AND a.PREndDate = @prenddate AND a.Employee = @employee AND a.PaySeq = @payseq 
   			AND t.InsState = @state AND t.InsCode = @inscode AND e1.Method='F' AND e2.Factor<>1	-- overtime
   	
   		OPEN bcFactoredAddon
   		SELECT @openFactoredAddon = 1
   	
   		--loop through Factored Addon cursor
   		next_FactoredAddon:
   	    	FETCH NEXT FROM bcFactoredAddon INTO @pePostSeq, @pePostDate, @peEarnCode, @peFactor,
   				@peIncldLiabDist, @peHours, @peRate, @peAmt, @peJCCo, @peJob, @peCraft, @peClass
   	    	IF @@fetch_status = -1 GOTO end_FactoredAddon
   	    	IF @@fetch_status <> 0 GOTO next_FactoredAddon
   
   			-- get for Job Craft Template (if any) 
   			SET @template = NULL
   			IF @peJob IS NOT NULL
   			BEGIN
   				SELECT @template = CraftTemplate	-- #30687 pull Craft Template
   				FROM dbo.bJCJM (NOLOCK)
   				WHERE JCCo = @peJCCo AND Job = @peJob
   			END
   
   			-- get Craft Class Addon Rate for Straight Time, possible override by Template
      		SELECT @oldrate = 0.00, @newrate = 0.00
            SELECT @oldrate = OldRate, @newrate = NewRate
   			FROM dbo.bPRCI (NOLOCK)
   			WHERE PRCo = @prco AND Craft = @peCraft AND EDLType = 'E' AND EDLCode = @peEarnCode 
      			
   			SELECT @oldrate = OldRate, @newrate = NewRate
   			FROM dbo.bPRCF (NOLOCK)
   			WHERE PRCo = @prco AND Craft = @peCraft AND Class = @peClass AND EarnCode = @peEarnCode 
   
   			IF @template IS NOT NULL
   			BEGIN
               	SELECT @oldrate = OldRate, @newrate = NewRate
   				FROM dbo.bPRTI (NOLOCK)
   				WHERE PRCo = @prco AND Craft = @peCraft AND Template = @template AND EDLType = 'E'
   					AND EDLCode = @peEarnCode 
   
      			SELECT @oldrate = OldRate, @newrate = NewRate
   				FROM dbo.bPRTF (NOLOCK)
   				WHERE PRCo = @prco AND Craft = @peCraft AND Class = @peClass AND Template = @template
      				AND EarnCode = @peEarnCode 
   			END
   
      		-- get Effective Date to determine rates 
   			SELECT @effectdate = EffectiveDate
   			FROM dbo.bPRCM (NOLOCK)
   			WHERE PRCo = @prco AND Craft = @peCraft
   			
   			IF @template IS NOT NULL
   			BEGIN
   				SELECT @effectdate = EffectiveDate
   				FROM dbo.bPRCT (NOLOCK)
   				WHERE PRCo=@prco AND Craft = @peCraft AND Template = @template AND OverEffectDate = 'Y'
   			END
   			
      		-- Straight Time rate
      		SELECT @steRate = CASE WHEN @effectdate > @pePostDate THEN @oldrate ELSE @newrate END
   
   			IF @steRate <> 0
   			BEGIN
    			-- calculate the true factor for addon earnings using posted AND straight time rates
   				SELECT @steFactor=@peRate/@steRate
   	
   				UPDATE dbo.bPRPE
   				SET Factor=@steFactor
   				WHERE VPUserName = suser_sname() AND PostSeq=@pePostSeq AND PostDate = @pePostDate
   					AND EarnCode = @peEarnCode AND IncldLiabDist = @peIncldLiabDist
   					AND Hours = @peHours AND Rate = @peRate AND Amt = @peAmt
   			END
   	
   			GOTO next_FactoredAddon
   		
   	
   		end_FactoredAddon:
       		CLOSE bcFactoredAddon
       		DEALLOCATE bcFactoredAddon
       		SELECT @openFactoredAddon = 0
   	END -- DLs based on STE
  --END issue #123529
  
        -- create cursor for State Insurance Code DLs
       declare bcInsDL cursor for
       select DLCode, Rate
       from dbo.bPRID with (nolock)
       where PRCo = @prco and State = @state and InsCode = @inscode
   
       open bcInsDL
       select @openInsDL = 1
   
       -- loop through State Insurance Code DL cursor
       next_InsDL:
           fetch next from bcInsDL into @dlcode, @rate
           if @@fetch_status = -1 goto end_InsDL
           if @@fetch_status <> 0 goto next_InsDL
   
           -- get standard DL info
           select @dldesc = Description, @dltype = DLType, @method = Method, @routine = Routine,
               @seq1only = SeqOneOnly, @ytdcorrect = YTDCorrect, @bonusover = BonusOverride,
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
   
   	 /* validate calculation category*/
   	if @calccategory not in ('I','A')
   		begin
   		select @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' should be calculation category I or A!', @rcode = 1
    		goto bspexit
    	end
   
           -- check for Payment Sequence #1 restriction
           if @seq1only = 'Y' and @payseq <> 1 goto next_InsDL
   
           -- check for Weekly Earnings limit - applied to each DL associated with Insurance code
           if @earnlimit > 0.00 and @ppds = 52
               begin
               -- handle as a Subject based limit, use Earning Limit from bPRIN, applied each Pay Period
               select @limitbasis = 'S', @limitamt = @earnlimit, @limitperiod = 'P'
               end
   
           -- #132018  For Ohio worker's comp, allow for any length of pay period.  If pay period is not weekly, 
		   -- multiply the Weekly Earnings limit by the number of weeks assigned in Pay Period Control.
		   -- Apply limit to each DL associated with Insurance code
           if @earnlimit > 0.00 and @state = 'OH'
              begin
              -- handle as a Subject based limit, use Earning Limit from bPRIN, applied each Pay Period
              select @limitbasis = 'S', @limitamt = @earnlimit, @limitperiod = 'P'
			  -- if pay period is not weekly, adjust limit for # of weeks entered in Pay Period Control
			  if @ppds <> 52 select @limitamt = @earnlimit * @weeks
              end

           -- get Employee info and overrides for this dedn/liab
           select @filestatus = 'S', @regexempts = 0, @empvendor = null, @apdesc = null
           select @overcalcs = 'N', @overlimit = 'N', @addontype = 'N', @overrate = null
           select @filestatus = FileStatus, @regexempts = RegExempts, @empvendor = Vendor, @apdesc = APDesc,
               @overcalcs = OverCalcs, @emprateamt = isnull(RateAmt,0.00), @overlimit = OverLimit,
               @emplimit = isnull(Limit,0.00), @addontype = AddonType, @addonrateamt = isnull(AddonRateAmt,0.00),
   			@empllimitrate = isnull(LimitRate,0.00) /*issue 11030*/
           from dbo.bPRED with (nolock)
           where PRCo = @prco and Employee = @employee and DLCode = @dlcode
   
        -- check for calculation override on Bonus sequence
           if @bonus = 'Y' and @bonusover = 'Y' select @method = 'G', @overrate = @bonusrate
   
           -- check for Employee calculation and rate overrides
           if @overcalcs = 'M' select @method = 'G', @overrate = @emprateamt
           if @overcalcs = 'R' select @overrate = @emprateamt
           if @overlimit = 'Y' select @limitamt = @emplimit
   		if @overlimit = 'Y' select @limitrate = @empllimitrate /*issue 11030*/
   
           -- get STE wages for New York worker's comp
           if @method = 'R' and @routine = 'NY WC'
               begin
               exec @rcode = bspPRProcessGetBasis @prco, @prgroup, @prenddate, @employee, @payseq, 'S',
                   @posttoall, @dlcode, @dltype, @stddays, NULL, NULL, @calcbasis output, @accumbasis output, --issue 20562
                   @liabbasis output, @errmsg output
               if @rcode <> 0 goto bspexit
               select @nycalcbasis = @calcbasis
               end
   
           -- get calculation, accumulation, and liability distribution basis
           exec @rcode = bspPRProcessGetBasis @prco, @prgroup, @prenddate, @employee, @payseq, @method,
               @posttoall, @dlcode, @dltype, @stddays, NULL, NULL, @calcbasis output, @accumbasis output, --issue 20562
               @liabbasis output, @errmsg output
           if @rcode <> 0 goto bspexit
   
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
   
   
           /* Calculations */
           select @calcamt = 0.00, @eligamt = 0.00
           if @overrate is not null select @rate = @overrate
   
           /* Flat Amount */
           if @method = 'A'
   		  begin
             exec @rcode = bspPRProcessAmount @calcbasis, @rate, @limitbasis, @limitamt, @limitcorrect, @accumelig,
   		      @accumsubj, @accumamt, @ytdelig, @ytdamt, @calcamt output, @eligamt output, @errmsg output
   		  if @rcode<> 0 goto bspexit
             end
   
           -- Rate per Day, Factored Rate per Hour, Rate of Gross, Rate per Hour, Straight Time Equivalent, or Rate of Dedn
           if @method in ('D', 'F', 'G', 'H', 'S', 'DN')
               begin
               exec @rcode = bspPRProcessRateBased @calcbasis, @rate, @limitbasis, @limitamt,
                       @ytdcorrect, @limitcorrect, @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt,
   					@accumbasis, @limitrate, @outaccumbasis output, --issue 11030 adjust for changes in bspPRProcessRateBased
   					@calcamt=@calcamt output, @eligamt=@eligamt output, @errmsg=@errmsg output
               if @rcode <> 0 goto bspexit
   			select @accumbasis = @outaccumbasis --issue 11030 basis may be adjusted to fit rate of earnings limit scheme
               end
   
           -- Routine
           if @method = 'R'
               begin
               -- get procedure name
   		    select @procname = null
   		    select @procname = ProcName from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = @routine
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
   
               -- call Routine procedure
    		    if @procname like 'bspPRNYI%'
    		  	  begin
    		  	  exec @rcode = @procname @accumsubj, @nycalcbasis, @earnlimit, @rate, @basisused output, @calcamt output, @errmsg output
   			  -- please put no code between exec and @@error check!
   			  if @@error <> 0 select @rcode = 1 --28379 check for error when routine was called
          		  select @calcbasis = @basisused
    		  	  goto routine_end
    		  	  end
   
   		  -- issue 24545
   	         if @procname = 'bspPRExemptRateOfGross'   -- rate of gross with exemption ... tax calculation withheld until subject amount reaches exemption limit
   	             begin
   			exec @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
   			  @dlcode, @dltype, 'A', @limitmth, 'N', @accumamt output,
   			  @accumsubj output, @accumelig output, @ytdamt output, @ytdelig output, @errmsg output
   			if @rcode <> 0 goto bspexit
   
   			select @exemptamt = MiscAmt1 from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = @routine
   
    		  	exec @rcode = @procname @calcbasis, @rate, @accumsubj, @accumelig, @exemptamt, @calcamt output, @eligamt output, @errmsg output
   			-- please put no code between exec and @@error check!
   			if @@error <> 0 select @rcode = 1 --28379 check for error when routine was called
   			select @calcbasis = @eligamt
    		  	goto routine_end
    			end
    
   		    exec @rcode = @procname @calcbasis, @calcamt output, @errmsg output
  
   			-- please put no code between exec and @@error check!
   			if @@error <> 0 select @rcode = 1 --28379 check for error when routine was called
   
   		    routine_end:
               if @rcode <> 0 goto bspexit
   		    if @calcamt is null select @calcamt = 0.00
   		  select @eligamt = @calcbasis
               end
   
      	-- apply Employee calculation override
           if @overcalcs = 'A' select @calcamt = @emprateamt
   
           -- apply Employee addon amounts - only applied if calculated amount is positive
           if @calcamt > 0.00
               begin
   		    if @addontype = 'A' select @calcamt = @calcamt + @addonrateamt
   		    if @addontype = 'R' select @calcamt = @calcamt + (@calcbasis * @addonrateamt)
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
   
           -- check for Override processing
           select @useover = UseOver, @overamt = OverAmt, @overprocess = OverProcess
           from dbo.bPRDT with (nolock)
           where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
               and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
   
           -- get Earnings subject to this DL for Insurance Accums
           select @earns = isnull(sum(e.Amt),0.00), 
			@basisearns = isnull(sum(case b.SubjectOnly when 'N' then e.Amt else 0.00 end),0.00),
			@prpe_hrs = isnull(sum(e.Hours),0.00)
           from dbo.bPRPE e with (nolock)
           join dbo.bPRDB b with (nolock) on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode
   
           -- update Insurance Accumulations
           update dbo.bPRIA
           set Earnings = Earnings + @earns, SubjectAmt = SubjectAmt + @accumbasis, Rate = @rate,
               Amt = Amt + @calcamt, EligibleAmt = EligibleAmt + @eligamt, BasisEarnings = BasisEarnings + @basisearns,
   			CalcBasis = CalcBasis + @calcbasis,	-- #20441 - accum basis earnings and calculation basis
			Hours = Hours + @prpe_hrs
           where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
               and PaySeq = @payseq and State = @state and InsCode = @inscode and DLCode = @dlcode
           if @@rowcount = 0
               insert dbo.bPRIA (PRCo, PRGroup, PREndDate, Employee, PaySeq, State, InsCode, DLCode,
                   Earnings, SubjectAmt, Rate, Amt, EligibleAmt, BasisEarnings, CalcBasis, Hours)
                   values(@prco, @prgroup, @prenddate, @employee, @payseq, @state, @inscode, @dlcode,
                   @earns, @accumbasis, @rate, @calcamt, @eligamt, @basisearns, @calcbasis, @prpe_hrs)
   
           -- if overridden, replace calculated amount in Insurance Accums with override amount
           if @useover = 'Y'
               begin
               update dbo.bPRIA
               set Amt = case @overprocess when 'N' then @overamt else 0 end  -- 0 if already processed
               where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
               and PaySeq = @payseq and State = @state and InsCode = @inscode and DLCode = @dlcode
               end
   
           -- an overridden DL amount is processed only once
           if @overprocess = 'Y' goto next_InsDL
   
           if @useover = 'Y'
               begin
   		    update dbo.bPRDT set OverProcess = 'Y'
                   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                   and Employee = @employee and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
   		    end
   
           -- check for Liability distribution - needed even if basis and/or amount are 0.00
           if @dltype <> 'L' goto next_InsDL
   
           -- use calculated amount unless overridden
   		select @amt2dist = @calcamt
   		if @useover = 'Y' select @amt2dist = @overamt
   
   		-- no need to distribute if Basis <> 0 and Amt = 0, but will distibute if both are 0.00
           -- because of possible offsetting timecard entries
           if @calcbasis <> 0.00 and @amt2dist = 0.00 goto next_InsDL
   
           -- call procedure to distribute liability amount
           exec @rcode = bspPRProcessLiabDist @prco, @prgroup, @prenddate, @employee, @payseq, @dlcode,
                   @method, @rate, @liabbasis, @amt2dist, @posttoall, @errmsg output --issue 20562
   
           if @rcode <> 0 goto bspexit
   
   
           goto next_InsDL
   
       end_InsDL:
           close bcInsDL
           deallocate bcInsDL
           select @openInsDL = 0
           goto next_Ins
   
   end_Ins:
       close bcIns
       deallocate bcIns
       select @openIns = 0
   
   bspexit:
       -- clear Payroll Process entries
       delete dbo.bPRPE where VPUserName = SUSER_SNAME()
   
       if @openInsDL = 1
           begin
      		close bcInsDL
       	deallocate bcInsDL
         	end
       if @openIns = 1
           begin
      		close bcIns
       	deallocate bcIns
         	end
       if @openVarAddon = 1
           begin
      		close bcVarAddon
       	deallocate bcVarAddon
         	end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessIns] TO [public]
GO
