SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                procedure [dbo].[bspHRBBPost]
/************************************************************************
* Posts a validated batch of HRBB entries
* Created:	7/27/99 kb
* Modified: 1/2/01 kb
* Modified: 7/24/01 kb - issue #12542 - pass in Co#, Month, Batch ID#, and Posting Date
*			9/20/01 mh Issue 13797.  See comment notes below.
*			10/01/01 mh Issue 14755.  Need to remove entries from HRBD after they are posted.
*			11/16/01, 1/24/02 MH Issue 14939
*			7/30/02. Issue 18122. bPRAE AnnualLimit column was re-named LimitOvrAmt MH
*			5/23/03 - Issue 20411.  See below. mh
*			7/8/03 - Issue 20772 - If LimitOvrAmt > 0 then OvrStdLimitYN needs to be 'Y'
*			1/8/04	- Issue 23438 - Correct @salaryamt from bDollar to bUnitCost
*			9/27/2004	- Issue 25620 - HRSH not updated correctly after post to PREH.
*			2/7/2005	- Issue 26940 - See comment tag below.
*			3/16/2005	- Issue 27387 - need to include BenefitCode in HREB update statement
*			9/20/2005	- Issue 27009 - Set OverStdLimit = 'N' when OverRideLimit = 0.
*			09/28/2007	- Issue 122300 - Grab Craft/Class from PREH and insert/update to PRAE
*			05/20/2008	- Issue 128304 - Corrected insert to PRED to set CSMedCov to 'N'
*			07/09/2008	- Issue 23347 - Correct CSAllocYN to default 'N'
*			04/14/2011	- #142843 - refactored to not use @transtype								
*
* clears bHQCC when complete
*
* returns 1 and message if error
************************************************************************/
    
   	(@co bCompany, @mth bMonth, @batchid bBatchID,
   	@dateposted bDate = null, @source bSource, @errmsg varchar(60) output)
   
   	as
   	set nocount on
   	
   	declare @rcode int, @opencursor tinyint, @tablename char(20), @inuseby bVPUserName, @status tinyint,
   	@emplbased bYN, @freq bFreq, @edlcode bEDLCode, @earncode bEDLCode, @seq int, @lastseq int, 
   	@transtype char(1), @hrref bHRRef, @prco bCompany, @employee bEmployee, @benefitcode varchar(10), 
   	@benefitsalaryflag char(1), @salaryrateflag char(1), @salaryamt bUnitCost, @errors varchar(60), 
   	@effectivedate bDate, @glco bCompany, @autoearnseq tinyint, @department bDept, @batchtranstype char(1), 
   	@inscode bInsCode, @earnrateamt bUnitCost, @payseq tinyint, @annuallimit bDollar, @edltype char(1), 
   	@processseq tinyint, @overridecalc bYN, @rateamt bUnitCost, @overrideglacct bGLAcct, 
   	@vendorgroup bGroup, @vendor bVendor, @aptransdesc bDesc, @stdhours bYN, @hours bHrs, 
   	@overridelimit bDollar, @overstdlimitPRED bYN, @overstdlimitPRAE bYN
    
   	select @rcode = 0
   	
   	/* set open cursor flag to false */
   	select @opencursor = 0
   	
   	/* check for date posted */
   	if @dateposted is null
   	begin
   		select @errmsg = 'Missing posting date!', @rcode = 1
   		goto bspexit
   	end
    
   	/* validate HQ Batch */
   	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'HRBB', 
   	@errmsg output, @status output
   	
   	if @rcode <> 0
   	begin
   		select @errmsg = @errmsg, @rcode = 1
   		goto bspexit
   	end
   	
   	/* valid - OK to post, or posting in progress */
   	if @status <> 3 and @status <> 4	
   	begin
   		select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
   		goto bspexit
   	end
    
   	/* set HQ Batch status to 4 (posting in progress) */
   	update dbo.bHQBC
   	set Status = 4, DatePosted = @dateposted
   	where Co = @co and Mth = @mth and BatchId = @batchid
   	
   	if @@rowcount = 0
   	begin
   		select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   		goto bspexit
   	end
    
   	declare bcHRBB cursor local fast_forward for 
   	select BatchSeq, BatchTransType, HRRef, PRCo, Employee,
   	BenefitCode, BenefitSalaryFlag, SalaryRateFlag, SalaryAmt, EffectiveDate
   	from dbo.bHRBB where Co = @co and Mth = @mth and BatchId = @batchid 
   	
   	/* open cursor */
   	open bcHRBB
   	
   	/* set open cursor flag to true */
   	select @opencursor = 1
   	
   	/* loop through all rows in this batch */
   	posting_loop:
   	fetch next from bcHRBB into @seq, @transtype, @hrref, @prco, @employee,
   	@benefitcode, @benefitsalaryflag, @salaryrateflag, @salaryamt, @effectivedate
    
   	if @@fetch_status = -1 goto posting_loop_end
   	
   	if @@fetch_status <> 0 goto posting_loop
   	
   	if (@lastseq=@seq)
   	begin
   		select @errmsg='Same Seq repeated, cursor error.', @rcode=1
   		goto bspexit
   	end
   	
   	begin transaction
   
   	if @benefitsalaryflag = 'S'
   	begin
   		update dbo.bPREH set HrlyRate = case @salaryrateflag when 'H' 
   		then isnull(@salaryamt,0) else HrlyRate end, SalaryAmt = case 
   		@salaryrateflag when 'S' then isnull(@salaryamt,0)
   		else SalaryAmt end 
   		where PRCo = @prco and Employee = @employee
   
   /*	
   		--25620 - Unk why EffectiveDate was commented out.  Is part of the key for
   		--HRSH.  Commented out as far back as 5.71  mh 9/27/2004
   		update dbo.bHRSH 
   		set UpdatedYN = 'Y', BatchId = @batchid 
   		where HRCo = @co and HRRef = @hrref  
   		and EffectiveDate = @effectivedate
   */
   		--26940 - Update Resources with an effective date less then or equal to the
   		--effective date we are interfacing to PR.  Only update those records that 
   		--have not been previously updated (BatchID = null and UpdatedYN flag = N)
   		update dbo.bHRSH 
   		set UpdatedYN = 'Y', BatchId = @batchid 
   		where HRCo = @co and HRRef = @hrref  
   		and EffectiveDate <= @effectivedate and BatchId is null and UpdatedYN = 'N'
   
   
   	end
    
   	if @benefitsalaryflag = 'B'
     	begin
   		declare cEDLCurs Cursor local fast_forward for
    
   		select EDLCode, Frequency, GLCo, AutoEarnSeq, Department, InsCode, RateAmt,
   		PaySeq, AnnualLimit, BatchTransType, StdHours, Hours
   		from dbo.bHRBD
   		where Co = @co and Mth = @mth and BatchId = @batchid 
   		and BatchSeq = @seq and EDLType ='E' order by AutoEarnSeq
    
    		open cEDLCurs
    
    		fetch next from cEDLCurs into @edlcode, @freq, @glco, 
    		@autoearnseq, @department, @inscode, @earnrateamt, 
    		@payseq, @annuallimit, @batchtranstype, @stdhours, @hours
    
    		while @@fetch_status = 0
     		begin
    
   			--Issue 20772
   			if @annuallimit <> 0
   				select @overstdlimitPRAE = 'Y'
   			else
   				select @overstdlimitPRAE = 'N'
   			
   			
			-- #142843 - refactored to not use @transtype	   			
			IF EXISTS(SELECT 1 FROM dbo.bPRAE WHERE PRCo = @prco 
							AND Employee = @employee 
							AND EarnCode = @edlcode 
							AND Seq = @autoearnseq)
				BEGIN
				UPDATE dbo.bPRAE 
				SET PaySeq = @payseq, 
					PRDept = @department, 
					InsCode = @inscode, 
					GLCo = @glco, 
					RateAmt = @earnrateamt, 
					LimitOvrAmt = @annuallimit, 
					Frequency = @freq, 
					StdHours = @stdhours, 
					Hours = @hours, 
					OvrStdLimitYN = @overstdlimitPRAE,
					Craft = p.Craft, 
					Class = p.Class
				FROM bPRAE a
					JOIN bPREH p ON a.PRCo = p.PRCo and a.Employee = p.Employee
				WHERE a.PRCo = @prco 
					AND a.Employee = @employee 
					AND a.EarnCode = @edlcode 
					AND a.Seq = @autoearnseq


				IF @@ROWCOUNT <> 1 GOTO posting_error
				
				END
	   			
   			ELSE
   				BEGIN
	   			
	     		insert dbo.bPRAE (PRCo, Employee, EarnCode, Seq, PaySeq, 
				PRDept, InsCode, GLCo, StdHours, Hours, RateAmt, 
				LimitOvrAmt, Frequency, OvrStdLimitYN, Craft, Class)
				select @prco, @employee, @edlcode, @autoearnseq, 
				@payseq, @department, @inscode, @glco, @stdhours, 
				@hours, @earnrateamt, @annuallimit, @freq, @overstdlimitPRAE, Craft, Class 
				from dbo.bPREH p where p.PRCo = @prco AND p.Employee = @employee

				if @@rowcount = 0 goto posting_error
				
   				END
   			

   			
			--mh 27387 3/16/2005 - need to include BenefitCode in update statement.
   			update dbo.bHREB 
   			set UpdatedYN = 'Y', BatchId = @batchid 
   			where HRCo = @co and EffectDate = @effectivedate 
   			and HRRef = @hrref and BenefitCode = @benefitcode
    
			--mark 10/1/01 - need to delete entry from HRBD
			delete dbo.bHRBD 
			where Co = @co and Mth = @mth and
 	 	  	BatchId = @batchid and BatchSeq = @seq and EDLType = 'E' 
			and EDLCode = @edlcode and AutoEarnSeq = @autoearnseq

			fetch next from cEDLCurs into @edlcode, @freq, @glco, 
			@autoearnseq, @department, @inscode, @earnrateamt, 
			@payseq, @annuallimit, @batchtranstype, @stdhours, @hours
    
     		end
    
   		close cEDLCurs
   		deallocate cEDLCurs
    
   		select @edlcode = min(EDLCode) 
   		from dbo.bHRBD with (nolock)
   		where Co = @co and Mth = @mth and BatchId = @batchid and 
   		BatchSeq = @seq and EDLType <>'E'
    
    	while @edlcode is not null
     		begin
    
     			select @edltype = EDLType, @edlcode = EDLCode, 
    			@emplbased = EmplBasedYN, @freq = Frequency,
     		  	@processseq = ProcessSeq, @overridecalc = OverrideCalc, 
    			@rateamt = RateAmt, @glco = GLCo, 
    			@overrideglacct = OverrideGLAcct, 
    			@vendorgroup = VendorGroup,
     		  	@vendor = Vendor, @aptransdesc = APTransDesc, 
    			@annuallimit = AnnualLimit,
    			@overridelimit = OverrideLimit,
     		  	@batchtranstype = BatchTransType
     		  	from dbo.bHRBD with (nolock)
    			where Co = @co and Mth = @mth and BatchId = @batchid and
     		  	BatchSeq = @seq and EDLCode = @edlcode and EDLType <> 'E'
    
    			--select @overstdlimitPRED = 'N'
   			--Issue 27009 MH 9/20/05 - If OverRideLimit is 0 then OverStdLimit was be "N".
   			--Issue 14939 MH 1/24/02 			
    			--if @overridelimit > 0
   			--Issue 27009 MH 9/20/05 - If OverRideLimit is 0 then OverStdLimit was be "N".
   			if @overridelimit <> 0
    				select @overstdlimitPRED = 'Y'
   			else
   				select @overstdlimitPRED = 'N'
   
			
   			
			-- #142843 - refactored to not use @transtype	   			
			IF EXISTS(SELECT 1 FROM dbo.bPRED WHERE PRCo = @prco 
						AND Employee = @employee 
						AND	DLCode = @edlcode)
				BEGIN
				
				UPDATE dbo.bPRED 
				SET EmplBased = @emplbased, 
					Frequency = @freq, 
					ProcessSeq = @processseq, 
					VendorGroup = @vendorgroup, 
					Vendor = @vendor, 
					APDesc = @aptransdesc, 
					GLCo = @glco,
					OverGLAcct = @overrideglacct, 
					OverCalcs = @overridecalc, 
					RateAmt = @rateamt, 
					OverLimit = @overstdlimitPRED, 
					Limit=@overridelimit
				WHERE PRCo = @prco 
					AND Employee = @employee 
					AND DLCode = @edlcode


				if @@rowcount <> 1 goto posting_error
			
    		END
    		
    	ELSE
    		BEGIN
    		
			insert dbo.bPRED (PRCo, Employee, DLCode, EmplBased, Frequency, 
			ProcessSeq, VendorGroup, Vendor, APDesc, GLCo, OverGLAcct, 
			OverCalcs, RateAmt, OverLimit, Limit, NetPayOpt, MiscAmt, 
			AddonType, OverMiscAmt, CSMedCov,CSAllocYN)
			select @prco, @employee, @edlcode, @emplbased, @freq, 
			@processseq, @vendorgroup, 	@vendor, @aptransdesc, @glco, 
			@overrideglacct, @overridecalc, @rateamt, @overstdlimitPRED, @overridelimit, 
			'N',   0, 'N','N', 'N','N'

			if @@rowcount = 0 goto posting_error
			
    		END			
   

    
    --mh 27387 3/16/2005 - need to include BenefitCode in update statement.
   			update dbo.bHREB 
   			set UpdatedYN = 'Y', BatchId = @batchid 
   			where HRCo = @co and EffectDate = @effectivedate 
   			and HRRef = @hrref and BenefitCode = @benefitcode
    
   			--mark 10/1/01 - need to delete entry from HRBD
    			delete dbo.bHRBD 
    			where Co = @co and Mth = @mth and BatchId = @batchid 
    			and BatchSeq = @seq and EDLType <> 'E' 
    			and EDLCode = @edlcode
   
    	 		select @edlcode = min(EDLCode) 
    			from bHRBD with (nolock)
    			where Co = @co and Mth = @mth and
     			BatchId = @batchid and BatchSeq = @seq and 
    			EDLType <> 'E' and EDLCode > @edlcode
     		
    			if @@rowcount = 0 select @edlcode = null
     		end
    	end
    
         	/* delete current row from cursor */
   	delete from dbo.bHRBB 
   	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   	
   	if @@rowcount = 0
   	begin
   		rollback transaction
   		select @errmsg = 'Error removing batch sequence ' + 
   	
   		convert(varchar(10), @seq) + ' from batch.'
   		goto bspexit
   	end
    
     	/* commit transaction */
     	commit transaction
    
     	goto posting_loop
    
   	/* error occured within transaction - rollback any updates and continue */
   posting_error:		
   	rollback transaction
   	goto posting_loop
   	
   posting_loop_end:	/* no more rows to process */
     	/* make sure batch is empty */
    
    
    	--Check bHRBB
   	if exists(select 1 from dbo.bHRBB where Co = @co and Mth = @mth 
   	and BatchId = @batchid)
   	begin
   		select @errmsg = @errors + 'Not all batch entries were posted - unable to close batch!', @rcode = 1
   		goto bspexit
   	end
    
     	/* delete HQ Close Control entries */
     	delete dbo.bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
    
     	/* set HQ Batch status to 5 (posted) */
     	update dbo.bHQBC
     	set Status = 5, DateClosed = getdate()
     	where Co = @co and Mth = @mth and BatchId = @batchid
    
     	if @@rowcount = 0
    	begin
     		select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
     		goto bspexit
    	end
    
   bspexit:
    
   	if @opencursor = 1
   	begin
   		close bcHRBB
   		deallocate bcHRBB
   	end
    
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRBBPost] TO [public]
GO
