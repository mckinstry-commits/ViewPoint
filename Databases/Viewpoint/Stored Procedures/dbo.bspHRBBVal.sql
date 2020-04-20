SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRBBVal]
/************************************************************************
*Created by: kb
*Modified by: mh 3/28/03
*				mh 4/3/03 Issue 19254
*				mh 5/5/03 Issue 21212
*				mh 5/23/03 Issue 21348 - Add HRRef to error msg
*				mh 6/10/03 Issue 21455 - Added prevalidation
*				mh 6/11/03 Issue 21385 - Added @batchtype return param
*				mh 6/11/03 Issue 21266 - If EmpBased is "N" then you cannot have a Processing Seq.
*				mh 6/11/03 Issue 21500 - If EmpBased is "N" then you cannot have a Frequency code.
*				mh 7/25/03 Issue 21697 - Validate Frequency code against HQFC for EDLType = 'E'
*				mh 10/29/03 Issue 22844 - Only validate BatchTransType for Benefit entries - BenefitSalaryFlag = 'B'
*       		  DANF 03/15/05 - #27294 - Remove scrollable cursor.
*				mh 03/30/10 Issue 132283 - Check if Earnings and DL Codes are set up for Employee if we are doing an update.
*				CHS	04/14/2011	- #142843 - refactored to not use @transtype	
*
*************************************************************************/
    
     	@co bCompany, @mth bMonth, @batchid bBatchID, @source bSource, @batchtype char(1) = null output,@errmsg varchar(255) output
    
     as
     set nocount on
    
   	declare @opencursor tinyint, @rcode tinyint, @errortext varchar(255), @status tinyint,
   	@seq int, @dovalidation tinyint, @transtype char(1), @hrref bHRRef, @prco bCompany,
   	@employee bEmployee, @benefitcode varchar(10), @benefitsalaryflag char(1), @salaryrateflag char(1),
    	@salaryamt bDollar, @errorhdr varchar(255), @errorstart varchar(60), @Dept bDept,
    	@InsCode bInsCode, @vendor bVendor, @autoapyn bYN, @edlcode bEDLCode, @overridecalc varchar(1),
    	@rateamt bUnitCost, @dltype char(1), @emplbased bYN, @calccat varchar(1), @displaydate varchar(10),
   	@preval tinyint, @procseq tinyint, @freq bFreq, @autoearnseq tinyint
    
    
   	declare @overridecalccursor tinyint, @deptvalcursor tinyint, @inscodevalcursor tinyint,
   	@apvendvalcursor tinyint, @aptransdescvalcursor tinyint, @dlevalidatecursor tinyint
    
    
   	/* set open cursor flag to false */
   	select @opencursor = 0, @dovalidation=1
    
   	select @overridecalccursor = 0, @deptvalcursor = 0, @inscodevalcursor = 0,
   	@apvendvalcursor = 0, @aptransdescvalcursor = 0, @dlevalidatecursor = 0
    
   	/* validate HQ Batch */
   	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'HRBB', @errmsg output, @status output
   	if @rcode <> 0
   	begin
   		select @errmsg = @errmsg, @rcode = 1
   		goto bspexit
   	end
    
   	if @status < 0 or @status > 3
   	begin
   		select @errmsg = 'Invalid Batch status!', @rcode = 1
   		goto bspexit
   	end
    
   	/* set HQ Batch status to 1 (validation in progress) */
   	update bHQBC
   	set Status = 1
   	where Co = @co and Mth = @mth and BatchId = @batchid
   	if @@rowcount = 0
   	begin
   		select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   		goto bspexit
   	end
    
   	/* clear HQ Batch Errors */
   	delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   
   	--Issue 21385.  What kind of batch is this.  Does it have benefit/salary/ or both.
   	if (select count(Co) from bHRBB where Co = @co and Mth = @mth and BatchId = @batchid and BenefitSalaryFlag = 'S') > 0
   		select @batchtype = 'S'
   	
   	if (select count(Co) from bHRBB where Co = @co and Mth = @mth and BatchId = @batchid and BenefitSalaryFlag = 'B') > 0
   	begin
   		if @batchtype = 'S'
   			select @batchtype = 'A'
   		else
   			select @batchtype = 'B'
   	end
   
   --Issue 21455 PreVal Test
   
   select @rcode = 0
   	declare @batchseq int, @edltype char(1), @hrblerr tinyint, @hrbeerr tinyint, 
   	@hrbberr tinyint, @effectivedate bDate
   	
   	declare cHRBBPreVal cursor for
   	select BenefitCode, BatchSeq, HRRef, BenefitSalaryFlag, EffectiveDate
   	from HRBB where Co = @co and Mth = @mth and BatchId = @batchid
   
   	open cHRBBPreVal
   	fetch next from cHRBBPreVal into @benefitcode, @batchseq, @hrref, @benefitsalaryflag, @effectivedate
   	
   	while @@fetch_status = 0
   	begin
   	
   		select @errorhdr = 'Seq#' + convert(varchar(6),@batchseq)
   	
   		if @benefitsalaryflag = 'B'
   		begin
   			--HRBB to HREB....Validate the Header.
   			if not exists(select b.Co
   			from HRBB b
   			join HREB e on b.Co = e.HRCo and b.HRRef = e.HRRef and b.BenefitCode = e.BenefitCode
   			where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq 
   			and b.HRRef = @hrref and e.DependentSeq = 0
   			and b.EffectiveDate = e.EffectDate)
   			begin
   				select @hrbberr = 1, @preval = 1
   			end
   		
   			declare cHRInSync cursor for
   			select EDLType, EDLCode from HRBD where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   		
   			open cHRInSync
   			fetch next from cHRInSync into @edltype, @edlcode
   	
   			while @@fetch_status = 0
   			begin
   				--HRBD to HRBL --Validate the detail....EDLType = 'D'
   				
   				if @edltype = 'D'
   				begin
   					if not exists(select b.Co
   					from HRBB b
   					join HRBD d on b.Co = d.Co and b.Mth = d.Mth and b.BatchId = d.BatchId 
   					join HREB e on b.Co = e.HRCo and b.HRRef = e.HRRef and b.BenefitCode = e.BenefitCode
   					join HRBL l on e.HRCo = l.HRCo and e.HRRef = l.HRRef and e.BenefitCode = l.BenefitCode and 
   					e.DependentSeq = l.DependentSeq and b.BatchSeq = d.BatchSeq
   
   					where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq 
   					and d.EDLType = @edltype and d.EDLCode = @edlcode and b.HRRef = @hrref and e.DependentSeq = 0 
   					and l.DLCode = d.EDLCode
   					
   					--These are the data sync fields we are concerned with
   					and l.EmplBasedYN = d.EmplBasedYN and l.DLType = d.EDLType and l.DLCode = d.EDLCode
   					and isnull(l.Frequency, '') = isnull(d.Frequency, '') and isnull(l.ProcessSeq, '') = isnull(d.ProcessSeq, '') 
   					and isnull(l.OverrideCalc, '') = isnull(d.OverrideCalc, '') and l.RateAmt = d.RateAmt
   					and isnull(l.GLCo, '') = isnull(d.GLCo, '') and isnull(l.OverrideGLAcct, '') = isnull(d.OverrideGLAcct, '')
   					and l.OverrideLimit = d.OverrideLimit and isnull(l.VendorGroup, '') = isnull(d.VendorGroup, '')
   					and isnull(l.Vendor, '') = isnull(d.Vendor, '') and isnull(l.APTransDesc, '') = isnull(d.APTransDesc, ''))
   					begin
   						select @hrblerr = 1, @preval = 1
   					end
   				end
   			
   				if @edltype = 'E'
   				begin	
   					--HRBD to HRBE test  
   					if not exists(select b.Co
   					from HRBB b
   					join HRBD d on b.Co = d.Co and b.Mth = d.Mth and b.BatchId = d.BatchId 
   					join HREB e on b.Co = e.HRCo and b.HRRef = e.HRRef and b.BenefitCode = e.BenefitCode
   					join HRBE l on e.HRCo = l.HRCo and e.HRRef = l.HRRef and e.BenefitCode = l.BenefitCode 
   					and e.DependentSeq = l.DependentSeq and b.BatchSeq = d.BatchSeq
   					where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq 
   					and d.EDLType = @edltype and d.EDLCode = @edlcode
   					and b.HRRef = @hrref and e.DependentSeq = 0 and l.EarnCode = d.EDLCode  
   					
   					--These are the data sync fields we are concerned with
   					and l.EarnCode = d.EDLCode and l.Frequency = d.Frequency 
   					and l.RateAmount  = d.RateAmt and isnull(l.GLCo, '')  = isnull(d.GLCo, '') and 
   					isnull(l.Department, '')  = isnull(d.Department , '') and isnull(l.InsCode, '')  = isnull(d.InsCode, '') 
   					and l.AnnualLimit  = d.AnnualLimit and l.AutoEarnSeq  = d.AutoEarnSeq and l.StdHours  = d.StdHours 
   					and isnull(l.Hours, 0)  = isnull(d.Hours, 0) and isnull(l.PaySeq, '')  = isnull(d.PaySeq, ''))
   					begin
   						select @hrbeerr = 1, @preval = 1
   					end
   				end
   			
   				fetch next from cHRInSync into @edltype, @edlcode
   		
   			end
   		
   			close cHRInSync
   			deallocate cHRInSync
   		
   			if @hrblerr = 1 or @hrbeerr = 1 or @hrbberr = 1
   			begin
   				select @errortext = @errorhdr + ', HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit ' + isnull(convert(varchar(10), @benefitcode), '') + ' - Data in HRResourceBenefits has changed since batch created.'
   		
   				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				select @hrblerr = 0, @hrbeerr = 0, @hrbberr = 0
   			end
   
   		end
   		else if @benefitsalaryflag = 'S'
   		begin
   			if not exists(select b.Co
   			from HRBB b
   			join HRSH h on b.Co = h.HRCo and b.HRRef = h.HRRef and b.EffectiveDate = h.EffectiveDate
   			where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq
   			and b.HRRef = @hrref
   			and isnull(b.SalaryAmt, 0) = isnull(h.NewSalary, 0)
   			and b.SalaryRateFlag = h.Type)
   
   			begin
   				select @preval = 1
   				select @displaydate = (select convert(varchar(10), (select datepart(mm, @effectivedate))) + '/' + convert(varchar(2), (select datename(dd, @effectivedate))) + '/' + convert(varchar(4), (select datename(yyyy, @effectivedate))))
   
   				select @errortext = @errorhdr + ', HRRef ' + isnull(convert(varchar(10), @hrref), '') + 
   				', Effective Date '  + @displaydate  + 
   				' - Salary Data in HR Resource Salary History has changed since batch created.'
   		
   				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output				
   			end	
   		end
   
   
   		fetch next from cHRBBPreVal into @benefitcode, @batchseq, @hrref, @benefitsalaryflag, @effectivedate
   	end
   
   	close cHRBBPreVal
   	deallocate cHRBBPreVal
   	
   	--these variables are used below so reinialize them here.
   	select @batchseq = null, @hrref = null, @edltype = null, @edlcode = null, 
   	@benefitcode = null, @benefitsalaryflag = null
   
   	if @preval = 1
   	begin
   		goto updateBatchStatus
   	end
   
   --End PreVal Test
    
   	/* declare cursor on SL Change Batch for validation */
   	declare bcHRBB cursor local fast_forward for select BatchSeq, BatchTransType, HRRef, PRCo,
   	Employee, BenefitCode, BenefitSalaryFlag, SalaryRateFlag, SalaryAmt
   	from bHRBB where Co = @co and Mth = @mth and BatchId = @batchid
    
   	/* open cursor */
   	open bcHRBB
    
   	/* set open cursor flag to true */
   	select @opencursor = 1
    
   HRBBLoop:
    
   	fetch next from bcHRBB into @seq, @transtype, @hrref, @prco,
   	@employee, @benefitcode, @benefitsalaryflag, @salaryrateflag, @salaryamt
    
   	/* loop through all rows */
   	while (@@fetch_status = 0)
   	begin
   		select @dovalidation=1
   		/* validate SL Change Batch info for each entry */
   		select @errorhdr = 'Seq#' + convert(varchar(6),@seq)
   		select @errorstart = @errorhdr
   		/* validate transaction type */
   --22844
   		If @benefitsalaryflag = 'B'
   		begin
   			if @transtype <> 'A' and @transtype <> 'C'
   			begin
   				select @errortext = @errorhdr + ' -  Invalid transaction type, must be (A) or (C).'
   				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				if @rcode <> 0 goto bspexit
   			end
   		end
   
   		if not exists(select HRCo from bHRCO where HRCo=@co)
   		begin
   			select @errortext = @errorhdr + ' - Invalid HR Company.'
   			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   			if @rcode <> 0 goto bspexit
   		end
    
   		/* validate HRRef# */
   		if @hrref is null
   		begin
   			select @errortext = @errorhdr + ' - HR Ref# is missing!'
   			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   			select @dovalidation=0
   			if @rcode <> 0 goto bspexit
   		end
   
   		if not exists(select HRCo from HRRM where HRCo=@co and HRRef=@hrref)
   		begin
   			--select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Invalid HR Ref#.'
   			select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Invalid HR Ref#.'
   			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   			if @rcode <> 0 goto bspexit
   		end
    
   		/* validate Employee	*/
   		if @employee is null
     		begin
   			--select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Employee number is missing!'
   			select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Employee number is missing!'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			select @dovalidation=0
     			if @rcode <> 0 goto bspexit
     		end
   
   		if not exists(select PRCo from bPREH where PRCo=@prco and Employee = @employee)
     		begin
     			--select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Invalid Employee number.'
   			select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Invalid Employee number.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
     		end
    
   		/* validate benefit code*/
   		if @benefitsalaryflag <>'B' and @benefitsalaryflag <>'S'
    		begin
    			--select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Benefit Salary Flag must be (B) or (S)'
   			select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Benefit Salary Flag must be (B) or (S)'
    			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    			select @dovalidation = 0
    			if @rcode <> 0 goto bspexit
    		end
    
   		if @benefitsalaryflag = 'B'
   		begin
   			if @benefitcode is null
   			begin
     				--select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Benefit Code is missing!'
   				select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Benefit Code is missing!'
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    	 			select @dovalidation=0
     				if @rcode <> 0 goto bspexit
     			end
    			else
    			begin
   				if not exists(select HRCo from bHRBC where HRCo = @co and BenefitCode = @benefitcode)
    				begin
    					--select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Invalid BenefitCode.'
   					select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + ' - Invalid BenefitCode.'
    					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    					if @rcode <> 0 goto bspexit
    				end
    
    			end
    
   			--this is incomplete.  If you have more then one entry in HRBD for this where clause
   			--only the last one gets validated.  Need to loop through them.  Acutally I don't know
   			--why this does not blow up here.  mh 4/11
   			/*
   			select @Dept = Department from HRBD where Co = @co and Mth = @mth and
   			BatchId = @batchid and BatchSeq = @seq and EDLType = 'E'
   			if @Dept is not null
   			begin
   				exec @rcode = bspPRDeptVal @prco, @Dept, @errmsg output
   				if @rcode <> 0
   				begin
   					select @errortext = @errorhdr + ' - PR Department not on file!'
   					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   					select @dovalidation = 0
   					if @rcode <> 0 goto bspexit
   				end
   			end
   			*/
    
   			declare cDeptVal cursor for 
   			select Department from HRBD where Co = @co and Mth = @mth and
   			BatchId = @batchid and BatchSeq = @seq and EDLType = 'E'
    
   			open cDeptVal 
   			fetch next from cDeptVal into @Dept
    
   			select @deptvalcursor = 1
    
   			while @@fetch_status = 0
   			begin
   				if @Dept is not null
   				begin
   					exec @rcode = bspPRDeptVal @prco, @Dept, @errmsg output
   					if @rcode <> 0
   					begin
   						--select @errortext = @errorhdr + ' - PR Department not on file!'
   						--select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - PR Department ' + @Dept + ' not on file!'
   						select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - PR Department ' + @Dept + ' not on file!'
   						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   						select @dovalidation = 0
   						if @rcode <> 0 goto bspexit
   					end
   				end	
   				fetch next from cDeptVal into @Dept
   			end
    
   			if @deptvalcursor = 1
   			begin
   				close cDeptVal
   				deallocate cDeptVal
   				select @deptvalcursor = 0
   			end
    
   			--Issue 15958 validate InsCode mh 4/10
   			declare cInsCode cursor for 
    			select InsCode from HRBD where Co = @co and Mth = @mth and
    	             BatchId = @batchid and BatchSeq = @seq and EDLType = 'E'
    
   			open cInsCode
   			fetch next from cInsCode into @InsCode
    
   			select @inscodevalcursor = 1
    		
   			while @@fetch_status = 0
   			begin
   	 			if @InsCode is not null
    				begin
    					exec @rcode = bspHQInsCodeVal @InsCode, @errmsg
    					if @rcode <> 0
    					begin	
    						--select @errortext = @errorhdr + ' - InsCode not on file!'	
   	 					--select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') +  'InsCode ' + @InsCode + ' not on file!'
   						select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') +  ' - InsCode ' + @InsCode + ' not on file!'
    		 			    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    				    	select @dovalidation = 0
    			     		if @rcode <> 0 goto bspexit
   					end
   				end	
   				fetch next from cInsCode into @InsCode
   			end
    
   			if @inscodevalcursor = 1
   			begin 
   				close cInsCode
   				deallocate cInsCode
   				select @inscodevalcursor = 0
   			end
    
   			if @salaryrateflag is not null
    	 		begin
     				--select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Salary/Rate flag must be null!'
   				select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Salary/Rate flag must be null!'
     				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    	 			select @dovalidation=0
     				if @rcode <> 0 goto bspexit
     			end
    
    
    			--Issue 17609, Validate Vendor entered for Dedn/Liab code.  If not set up for
    			--Auto updates to AP then it must be null.
    			declare cAPVendorVal cursor for 
    			select HRBD.EDLCode
    			from HRBD 
    			join PRDL on HRBD.EDLCode = PRDL.DLCode 
    			where HRBD.Co = @co and HRBD.Mth = @mth and HRBD.BatchId = @batchid and
    			BatchSeq = @seq and PRDL.PRCo = @prco and PRDL.AutoAP = 'N' and 
    			HRBD.Vendor is not null 
    
    			open cAPVendorVal
    			select @apvendvalcursor = 1
    
    			fetch next from cAPVendorVal into @edlcode
    
    			while @@fetch_status = 0
    			begin
    				--select @errortext = @errorhdr  + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Dedn/Liab Code ' + 
   				select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + ' - Dedn/Liab Code ' + 
    				convert(varchar(10), @edlcode) + ' is not set up for Auto updates to AP - Vendor must be null.'
    				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    				select @dovalidation = 0
    				if @rcode <> 0 goto bspexit
    
    				select @edlcode = null
    				fetch next from cAPVendorVal into @edlcode
    			end
    
    			if @apvendvalcursor = 1
    			begin
    				close cAPVendorVal
    				deallocate cAPVendorVal
    				select @apvendvalcursor = 0
    			end
    
    			declare cAPTransDescVal cursor for
    			select HRBD.EDLCode
    			from HRBD 
    			join PRDL on HRBD.EDLCode = PRDL.DLCode 
    			where HRBD.Co = @co and HRBD.Mth = @mth and HRBD.BatchId = @batchid and
    			BatchSeq = @seq and PRDL.PRCo = @prco and PRDL.AutoAP = 'N' and 
    			HRBD.APTransDesc is not null 
    
    			open cAPTransDescVal
    
    			select @aptransdescvalcursor = 1
    			select @edlcode = null
    
    			fetch next from cAPTransDescVal into @edlcode
   
    			while @@fetch_status = 0
    			begin
    				--select @errortext = @errorhdr  + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Dedn/Liab Code ' + 
   				select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + ' - Dedn/Liab Code ' + 
    				convert(varchar(10),@edlcode) + ' is not set up for Auto updates to AP - AP Trans Description must be null.'
    				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    				select @dovalidation = 0
    				if @rcode <> 0 goto bspexit
    				select @edlcode = null
   
    				fetch next from cAPTransDescVal into @edlcode
    			end
    
    			if @aptransdescvalcursor = 1
    			begin
    				close cAPTransDescVal
    				deallocate cAPTransDescVal
   
    				select @aptransdescvalcursor = 0
    			end
    
    			--If overridecalc is 'N' then rateamt must be '0.00'
    			declare cOverRideCalc cursor for
    			select OverrideCalc, RateAmt, EDLCode
    			from bHRBD 
    			where Co = @co and BatchId = @batchid and BatchSeq = @seq and EDLType in ('D','L')
    
    			open cOverRideCalc
    
    			select @overridecalccursor = 1
    			select @edlcode = null
    
    			fetch next from cOverRideCalc into @overridecalc, @rateamt, @edlcode
    
    			while @@fetch_status = 0
    			begin
    				if @overridecalc = 'N' and @rateamt <> 0.00
    				begin
    					--select @errortext = @errorhdr  + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Dedn/Liab Code ' + 
   					select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + ' - Dedn/Liab Code ' + 
    					convert(varchar(10), @edlcode) + '.  Rate/Amount must be zero when Calculation Override Option is set to ''N''. '
    					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    				end
    
    				select @dovalidation = 0
    				if @rcode <> 0 goto bspexit
    				select @edlcode = null
    				fetch next from cOverRideCalc into @overridecalc, @rateamt, @edlcode
    			end
    
    			if @overridecalccursor = 1
    			begin
    				close cOverRideCalc
    				deallocate cOverRideCalc
    				select @overridecalccursor = 0
    			end
    
    			declare cDLEvalidate cursor for
    			select EDLType, EDLCode, EmplBasedYN, ProcessSeq, Frequency, AutoEarnSeq
    			from bHRBD 
    			where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	
    			open cDLEvalidate
    			select @dlevalidatecursor = 1
    			fetch next from cDLEvalidate into @dltype, @edlcode, @emplbased, @procseq, @freq, @autoearnseq
    
    			while @@fetch_status = 0
    			begin
    			
    				if (select Method from bPRDL where PRCo = @prco and DLType = @dltype and DLCode = @edlcode) <> 'R'
    				begin
    					if exists (select HRCo from HRWI where HRCo = @co and HRRef = @hrref and DednCode = @edlcode and FileStatus is not null)
    					begin
    						--select @errortext = @errorhdr  + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Dedn/Liab Code ' + 
   						select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + ' - Dedn/Liab Code ' + 
    						convert(varchar(10), @edlcode) + ' is not Routine.  Filing status must be null.'
    						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    					end
    				end
   
   				--Issue 21266  If EmpBased is "N" then you cannot have a Processing Seq.
   				if (@dltype = 'D' or @dltype = 'L') and @emplbased = 'N'
   				begin
   					if @procseq is not null
   					begin
   						select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + ' - Dedn/Liab Code ' + convert(varchar(10), @edlcode) + 
   						' Processing sequence must be null when Employee Based YN = ''N'''
   						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
   					end
   
   				--Issue 21500  If EmpBased is "N" then you cannot have a Frequency Code.
   					if @freq is not null
   					begin
   						select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + ' - Dedn/Liab Code ' + convert(varchar(10), @edlcode) + 
   						' Frequency must be null when Employee Based YN = ''N'''
   						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output						
   					end
   
   				end
   
   				if (@dltype = 'D' or @dltype = 'L') and @emplbased = 'Y' and @freq is not null
   				begin
   					if not exists(select 1 from HQFC where Frequency = @freq)
    					begin
   						select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + ' - Dedn/Liab Code ' + convert(varchar(10), @edlcode) +
   						' Frequency code ''' + @freq + ''' is not a valid HQ Frequency code. '
   						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   					end
   				end
   
    				--Issue 19254 Expanding validation here to look at CalcCategory in bPRDL.  If 
    				--Employee Based is 'Y' then CalcCategory for this DLCode must be A=Any or E=Employee.
    				if @emplbased = 'Y'
    				begin
    					select @calccat = CalcCategory from bPRDL where PRCo = @prco and DLType = @dltype and DLCode = @edlcode 
    					if @calccat <> 'A' and @calccat <> 'E'
    					begin
   	 					--select @errortext = @errorhdr  + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Dedn/Liab Code ' + convert(varchar(10), @edlcode) + 
   						select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + ' - Dedn/Liab Code ' + convert(varchar(10), @edlcode) + 
   	 					' is Employee based in HR.  Calculation Category must be A (Any) or E (Employee) in Payroll.'  
   	 					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output 
   	 				end
    				end
   	 			--end issue 19254
   
   				--Issue 21697 - Frequency is required when DL Type is 'E' and it must be valid
   				if @dltype = 'E' and @freq is null
   				begin
   					select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + ' - Earnings Code ' + convert(varchar(10), @edlcode) +
   					' Frequency is required for Earnings codes. '
   					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				end
   
   
   				if @dltype = 'E' and @freq is not null
   				begin
   					if not exists(select 1 from HQFC where Frequency = @freq)
   					begin
   						select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + ' - Earnings Code ' + convert(varchar(10), @edlcode) +
   						' Frequency code ''' + @freq + ''' is not a valid HQ Frequency code. '
   						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   					end
   				end
   
					--142843 commented out 132283 - the posting routine is now dealing with it
					--132283 Need to check that Employee and EDLCode exist in PR Automatic Earnings (PRAE) if batchtranstype = 'C'.  
					----Otherwise there is nothing to update.
					--if @transtype = 'C' and @dltype = 'E'
					--begin
					--	if not exists(Select 1 from bPRAE where PRCo = @prco and Employee = @employee and 
					--	EarnCode = @edlcode and Seq = @autoearnseq)
					--	begin
					--		select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + 
					--		' - Earnings Code ' + convert(varchar(10), @edlcode) + ' is not set up in PR Automatic Earnings.'
					--		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					--	end	
					--end
					
					----132283 Likewise, if Employee and EDLCode exist in PRAE and batch transtype is 'A' then we cannot add.
					--if @transtype = 'A' and @dltype = 'E'
					--begin
					--	if exists(Select 1 from bPRAE where PRCo = @prco and Employee = @employee and 
					--	EarnCode = @edlcode and Seq = @autoearnseq)
					--	begin
					--		select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + 
					--		' - Earnings Code ' + convert(varchar(10), @edlcode) + ' has already been set up in PR Automatic Earnings.  Cannot add.'
					--		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					--	end	
					--end
					
					----132283 Need to check that Employee and EDLCode exist in PR Employee Deduction/Liabilities (PRED) if batchtranstype = 'C'.
					----Otherwise there is nothing to update.
					--if @transtype = 'C' and @dltype = 'D'
					--begin
					--	if not exists(Select 1 from bPRED where PRCo = @prco and Employee = @employee and DLCode = @edlcode)
					--	begin
					--		select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + 
					--		' - Deduction/Liability Code ' + convert(varchar(10), @edlcode) + ' is not set up in PR Employee Dedns/Liabs.'
					--		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					--	end
					--end
					
					----132283 Likewise, if Employee and EDLCode exist in PRED and batch transtype is 'A' then we cannot add.
					--if @transtype = 'A' and @dltype = 'D'
					--begin
					--	if exists(Select 1 from bPRED where PRCo = @prco and Employee = @employee and DLCode = @edlcode)
					--	begin
					--		select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ', Benefit Code ' + @benefitcode + 
					--		' - Deduction/Liability Code ' + convert(varchar(10), @edlcode) + ' has already been set up in PR Employee Dedns/Liabs.  Cannot add.'
					--		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					--	end
					--end
					
					----End Issue 132283
					
					
   	 			select @dltype = null, @edlcode = null, @emplbased = null, @calccat = null, @procseq = null, @freq = null
   	 			fetch next from cDLEvalidate into @dltype, @edlcode, @emplbased, @procseq, @freq, @autoearnseq
    			end
    
   	 		if @dlevalidatecursor = 1
   	 		begin
   	 			close cDLEvalidate
   	 			deallocate cDLEvalidate
   	 			select @dlevalidatecursor = 0
   	 		end
   		end
    
    		else
    		if @benefitsalaryflag = 'S'
   		begin
   			if @benefitcode is not null
   			begin
    				--select @errortext = @errorhdr  + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Benefit Code must be null!'
   				select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Benefit Code must be null!'
   	 			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    				select @dovalidation = 0
    				if @rcode <> 0 goto bspexit
    			end
   
    			if @salaryrateflag is null
    			begin
   	  			--select @errortext = @errorhdr  + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Salary/Rate flag is missing!'
   				select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Salary/Rate flag is missing!'
   	  			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	 	 		select @dovalidation=0
   	  			if @rcode <> 0 goto bspexit
     			end
   
    			if @salaryrateflag <> 'H' and @salaryrateflag <>'S'
    			begin
   	  			--select @errortext = @errorhdr  + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Salary/Rate flag must be (H) or (S)!'
   				select @errortext = @errorhdr + ' HRRef ' + isnull(convert(varchar(10), @hrref), '') + ' - Salary/Rate flag must be (H) or (S)!'
   	  			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	 	 		select @dovalidation=0
   	  			if @rcode <> 0 goto bspexit
     			end
    		end
    
     		goto HRBBLoop
    
     	end
   
   --6/10/03 Issue 21455
   updateBatchStatus:
   
   	/* check HQ Batch Errors and update HQ Batch Control status */
     	select @status = 3	/* valid - ok to post */
     	if exists(select Co from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
     	begin
   	  	select @status = 2	/* validation errors */
     	end
   
   	update bHQBC
     	set Status = @status
   	where Co = @co and Mth = @mth and BatchId = @batchid
     	if @@rowcount <> 1
     		begin
   	  	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
     		goto bspexit
   	end
    
   bspexit:
    
    	if @aptransdescvalcursor = 1
    	begin
    		close cAPTransDescVal
    		deallocate cAPTransDescVal
    		select @aptransdescvalcursor = 0
    	end
    
    	if @apvendvalcursor = 1
    	begin
    		close cAPVendorVal
    		deallocate cAPVendorVal
    		select @apvendvalcursor = 0
    	end
    
    	if @inscodevalcursor = 1
    	begin 
    		close cInsCode
    		deallocate cInsCode
    		select @inscodevalcursor = 0
    	end
    
    	if @deptvalcursor = 1
    	begin
    		close cDeptVal
    		deallocate cDeptVal
    		select @deptvalcursor = 0
    	end
    
    	if @overridecalccursor = 1
    	begin
    		close cOverRideCalc
    		deallocate cOverRideCalc
    		select @overridecalccursor = 0
    	end
    
   	if @dlevalidatecursor = 1
   	begin
   		close cDLEvalidate
   		deallocate cDLEvalidate
   		select @dlevalidatecursor = 0
   	end
    
     	if @opencursor = 1
   	begin
     		close bcHRBB
     		deallocate bcHRBB
   	end
    
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRBBVal] TO [public]
GO
