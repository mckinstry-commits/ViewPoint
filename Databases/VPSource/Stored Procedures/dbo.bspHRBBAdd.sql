SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                       proc [dbo].[bspHRBBAdd]
    /***********************************************************
    * CREATED BY: kb 7/24/99
    * MODIFIED BY: ae 09/27/99
    *              ae 02/03/00 -- Fixed issue 6048
    *              ae 3/27/00 -- Fixed issue 6390
    *              kb 7/24/01 - issue #12542
    *              allenn 2/28/2002 - issue 13002
    *              bc 4/30/2 - Made bsp readable (supportable).  Hopefully Kate won't recompile it using Rapid SQL
    *			  mh 5/23/02 - @earncode loop was getting stuck in infinite loop.  initializing
    *					@earncode to null prior to fetch next.  Also, fixed @@rowcount logic error.
    *			GG 09/20/02 - #18522 ANSI nulls
    *
    *             bc 12/30/2 - #19798.  Initialize @hrshdate for every pass through the cursor
    *	      kb 2/24/3 - issue #20137 removed restriction for employee based DL's from HRBL this should not have been a restriction
    *	      kb 3/7/3 - issue #20137 changed so that employee based DL's have to have a processseq, non-empl based ones do not
    *			mh 5/22/03 Issue 20411...see notes below.
    *
    *			mh 5/30/03 Reversed out Issue 20411.  See issue 21371.  Not bringing in HRRefs/Employees that exist in 
    *			another batch.  Origial design was to use InUseMth and InUseBatchId in HREB and HRSH.  However, queries
    *			used to populate HRBB not looking at these fields in the loop control.  It would look at them to start the 
    *			loop for the first Employee but not at the bottom of the loop for the subsequent employees.
    *
    *			Rewrote this procedure.  It was making too many redundent calls to the tables to get info it could 
    *			have been obtained in previous calls.  Given the current restrictions on form HRUpdatePR 1 of 6 possible 
    *			data sets will be created for Benefits and 1 of 3 possible data sets will be created for Salary History.
    *
    *			mh 7/25/03 #21436 - Return a count of records inserted to HRBB to calling procedure.
    *			mh 8/15/03 #22167 - Unk why I had < Effective date for salary when it should be <= 
    *
    *			mh 8/18/03 #21371 - Rejection correction...making an incorrect comparison of HRRef to HRCo.
    *			mh 10/29/03 #22844 - When inserting Salary record into HRBB, no longer including BatchTransType.
	*			mh 2/21/08 #23347 - Removing references to HREB.UpdatePRYN
	*			mh 09/21/09 #135255 - Excludes HR Resources that are not "ActiveYN = 'Y'"
	*			MH 03/03/11 #142997 - Reverse out issue #135255.  Users will need to control the exclusion of inactive
	*								  employees in the forms 	
    *
    *
    * USAGE:
    * creates HRBB entries
    * an error is returned if any goes wrong.
    *
    *  INPUT PARAMETERS
    *
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   	(@hrco bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
   	@restrictbyemp bYN = null, @usepr bYN = null, @prco bCompany = null, @employee bEmployee = null,
   	@salaryYN bYN = null, @benefitsYN bYN = null, @restrictbyben bYN = null, @restrictbenefitcode varchar(10) = null,
   	@effectivedate bDate = null, @addordelete char(1) = null, @reccount int output,
   	@msg varchar(250) output)
   	as
   	set nocount on
   	
   	--verify the datatypes....do they match the destination tables?
   	declare @rcode tinyint, @hrebemployee bHRRef, @hrrmprco bCompany, @hrrmprempl
   	bEmployee, @benefitcode varchar(10), @hrebeffdate bDate, @batchseq int,
   	@dlcode bEDLCode, @dltype char(1), @empbased bYN, @freq bFreq, @procseq int, @overridecalc bYN,
   	@dlrateamt bUnitCost, @glco bCompany, @overrideglacct bGLAcct, @overridelimit bDollar, 
   	@vendorgroup bGroup, @vendor bVendor, @aptransdesc bDesc,
   	
   	@earncode bEDLCode, @autoearnseq int, @department bDept, @inscode bInsCode,
   	@earnrateamt bUnitCost, @annuallimit bDollar, @stdhours bYN, @hours bHrs, @payseq tinyint,
   	
   	@hrshhrref bHRRef, @hrshprco bCompany, @hrshpremp bEmployee, @hrshsalrateflag char(1),
   	@hrshnewsal bUnitCost, @hrsheffdate bDate, @batchtranstype char(1)
   	
   	--cursor control variables
   	declare @openhrbbcurs tinyint, @openhrblcursor tinyint, @openhrbecursor tinyint, @openhrshcursor tinyint
   	
   	select @openhrbbcurs = 0, @openhrblcursor = 0, @openhrbecursor = 0, @openhrshcursor = 0
   
   	select @rcode = 0
    
   	if @restrictbyemp = 'Y' and @addordelete = 'D'
   	begin
   		--this is for removing a specific resource.  Otherwise you would want to 
   		--clear the entire batch and just bring in those resource you want...some or all.
   		delete from HRBD where Co = @hrco and Mth = @mth and BatchId = @batchid 
   		and BatchSeq in (select BatchSeq from HRBB where Co = @hrco and Mth = @mth and BatchId = @batchid
   		and HRRef = @employee and BenefitSalaryFlag = 'B')
   
   		delete from HRBB where Co = @hrco and Mth = @mth and BatchId = @batchid and HRRef = @employee
   	end
   	else if @restrictbyemp = 'N' or @addordelete = 'D'
   	begin
   		delete from HRBD where Co = @hrco and Mth = @mth and BatchId = @batchid
   		delete from HRBB where Co = @hrco and Mth = @mth and BatchId = @batchid
   	end
   
   
   	if @addordelete='D'
   	--data was deleted above.  Just exit the procedure
   		goto bspexit
   
   	if @benefitsYN = 'Y' --work the benefits.  
   	--Currently, the code ignores the Expiration date.  Per Carol, this is ok.  Just concerned with
   	--effective date.
   	begin
   
   		if @restrictbyemp = 'Y'
   		begin
   			if @usepr = 'Y' --We are restricting by employee and using a specific PR number.
   			begin
   
   				if @restrictbyben = 'Y' --We are restricting by employee and using a 
   										--specific PR number AND restricting by BenefitCode.
   				begin --set 1
   					declare cHRBBAdd cursor local fast_forward for
   					select e.HRRef, r.PRCo, r.PREmp, e.BenefitCode, e.EffectDate
   					From dbo.HREB (nolock) e Join dbo.HRRM (nolock) r on e.HRCo = r.HRCo and e.HRRef = r.HRRef 
   					where r.HRCo = @hrco and r.PRCo = @prco and r.PREmp = @employee 
   						and e.DependentSeq = 0 and e.UpdatedYN = 'N' and e.EffectDate <= @effectivedate 
   						and r.ExistsInPR = 'Y' and e.InUseMth is null 
   						and e.InUseBatchId is null and BenefitCode = @restrictbenefitcode order by e.HRRef
   				end
   				else--We are restricting by employee and using a 
   					--specific PR number AND not restricting by BenefitCode.
   					-- 1 PR emp can have 1 to many benefits
   				begin --set 2
   					declare cHRBBAdd cursor local fast_forward for
   					select e.HRRef, r.PRCo, r.PREmp, e.BenefitCode, e.EffectDate
   					From dbo.HREB (nolock) e Join HRRM r on e.HRCo = r.HRCo and e.HRRef = r.HRRef 
   					where r.HRCo = @hrco and r.PRCo = @prco and r.PREmp = @employee 
   						and e.DependentSeq = 0 and e.UpdatedYN = 'N' and e.EffectDate <= @effectivedate 
   						and r.ExistsInPR = 'Y' and e.InUseMth is null 
   						and e.InUseBatchId is null order by e.HRRef
   				end
   			end
   			else
   			begin	--We are restricting by employee and using a specific HRRef number.
   				if @restrictbyben = 'Y' --We are restricting by employee and using a 
   										--specific HRRef number AND restricting by BenefitCode.
   				begin  --set 3
   					declare cHRBBAdd cursor local fast_forward for 
   					select e.HRRef, r.PRCo, r.PREmp, e.BenefitCode, e.EffectDate
   					from dbo.HREB (nolock) e join dbo.HRRM (nolock) r on e.HRCo = r.HRCo and e.HRRef = r.HRRef
   					where r.HRCo = @hrco and e.HRRef = @employee and e.DependentSeq = 0 
   						and e.EffectDate <= @effectivedate 
   						and r.PREmp is not null and r.ExistsInPR = 'Y' 
   						and e.InUseMth is null and e.InUseBatchId is null 
   						and BenefitCode = @restrictbenefitcode order by e.HRRef   
   				end
   				else--We are restricting by employee and using a 
   					--specific HRRef number AND not restricting by BenefitCode.
   					-- 1 HRRef can have 1 to many benefits
   				begin  --set 4
   					if exists(select e.HRRef
   					from dbo.HREB (nolock) e join dbo.HRRM (nolock) r on e.HRCo = r.HRCo and e.HRRef = r.HRRef
   					where r.HRCo = @hrco and e.HRRef = @employee and e.DependentSeq = 0 
   						and e.UpdatedYN = 'N' and e.EffectDate <= @effectivedate 
   						and r.PREmp is not null and r.ExistsInPR = 'Y'  
   						and e.HRCo in (select b.Co from dbo.HRBB (nolock) b where b.Co = e.HRCo and 
   						b.HRRef = e.HRRef and b.BenefitCode = e.BenefitCode))
   					begin
   						select @rcode = 1
   					end
   					declare cHRBBAdd cursor local fast_forward for 
   					select e.HRRef, r.PRCo, r.PREmp, e.BenefitCode, e.EffectDate
   					from dbo.HREB (nolock) e join dbo.HRRM (nolock) r on e.HRCo = r.HRCo and e.HRRef = r.HRRef
   					where r.HRCo = @hrco and e.HRRef = @employee and e.DependentSeq = 0 
   						and e.UpdatedYN = 'N' and e.EffectDate <= @effectivedate 
   						and r.PREmp is not null and r.ExistsInPR = 'Y'  
   						and e.InUseMth is null and e.InUseBatchId is null order by e.HRRef 
   				end
   			end
   		end
   		else	--We are not restricting by Employee but we could restrict by Benefit
   		begin
   			if @restrictbyben = 'Y'  --All Resources for a specific Benefit.
   			begin --set 5
   				declare cHRBBAdd cursor local fast_forward for 

   				select e.HRRef, r.PRCo, r.PREmp, e.BenefitCode, e.EffectDate
   				from dbo.HREB (nolock) e join dbo.HRRM (nolock) r on e.HRCo = r.HRCo and e.HRRef = r.HRRef 
   				where e.HRCo = @hrco and e.DependentSeq = 0 and e.UpdatedYN = 'N' 
   					and e.EffectDate <= @effectivedate  
   					and r.PREmp is not null and r.ExistsInPR = 'Y' and e.InUseMth is null 
   					and e.InUseBatchId is null and BenefitCode = @restrictbenefitcode
   					order by e.HRRef   
   			end
   			else	--All Resources and all benefits.
   			begin  --set 6
   				declare cHRBBAdd cursor local fast_forward for
   				select e.HRRef, r.PRCo, r.PREmp, e.BenefitCode, e.EffectDate
   				from dbo.HREB (nolock) e join dbo.HRRM (nolock) r on e.HRCo = r.HRCo and e.HRRef = r.HRRef 
   				where e.HRCo = @hrco and e.DependentSeq = 0 and e.UpdatedYN = 'N' 
   					and e.EffectDate <= @effectivedate 
   					and r.PREmp is not null and r.ExistsInPR = 'Y' and e.InUseMth is null 
   					and e.InUseBatchId is null order by e.HRRef
   			end
   		end
   
   /*
   		Only one of the six possible sets will be created.  Two sets will only 
   		have zero or one record.  They are Sets 
   			1.  Restrict by PR Employee number and BenefitCode
   			3.  Restrict by HR Employee number and BenefitCode.
   		The others will have zero, one or many records.
   
   */
   		open cHRBBAdd
   		select @openhrbbcurs = 1
   
   		fetch next from cHRBBAdd into
   		@hrebemployee, @hrrmprco, @hrrmprempl, @benefitcode, @hrebeffdate		
   
   		while @@fetch_status = 0
   		begin
   
   			--if this Resource exists in another batch skip it....redundent check
   			if exists(select 1 from dbo.HRBB (nolock) where Co = @hrco and HRRef = @hrebemployee and 
   			BenefitCode = @benefitcode and Mth <> @mth and BatchId <> @batchid )
   			begin
   				select @rcode = 1
   				goto nextresource
   			end
   
   			--Question...what if HREB.EffectiveDate is null?
   			--Answer...it does not show up in the set. 
   			select @batchseq = isnull(max(BatchSeq),0)+1 
   			from bHRBB 
   			where Co = @hrco and Mth = @mth and BatchId = @batchid
   
   			begin transaction
   			--Create HRBB header entry.  This is your batch header record.  The assumption is
   			--that the batch transaction type will be 'A-Add'.  It may be changed to 'C-Change' later.
   			insert bHRBB (Co, Mth, BatchId, BatchSeq, HRRef, PRCo, Employee, BenefitCode,
   			BenefitSalaryFlag, SalaryRateFlag, SalaryAmt, BatchTransType, EffectiveDate)
   			select @hrco, @mth, @batchid, @batchseq, @hrebemployee, @hrrmprco, @hrrmprempl, @benefitcode,
   			'B', null, 0, 'A', @hrebeffdate
   
   			--Create a set of DL Codes for this HRRef/Benefit
   /*
   6/9 What was the outcome of Carol/Kate 6/9 e-mail?  May need to remove ReadyYN out of the where clause
   and into the select list.  Check ReadyYN and if 'N' rollback the current transaction and goto the
   next resource.
   */
   			declare cHRBL cursor local fast_forward for
   			select DLCode, DLType, EmplBasedYN, Frequency, ProcessSeq, OverrideCalc, 
   			RateAmt, GLCo, OverrideGLAcct, OverrideLimit, VendorGroup, Vendor, 
   			APTransDesc
   			from HRBL
   			where HRCo = @hrco and HRRef = @hrebemployee and DependentSeq = 0 
   				and BenefitCode = @benefitcode and ReadyYN = 'Y' 
   				and ((EmplBasedYN = 'Y' and ProcessSeq is not null) or EmplBasedYN = 'N')
   
   			open cHRBL 
   			select @openhrblcursor = 1
   
   			fetch next from cHRBL into
   			@dlcode, @dltype, @empbased, @freq, @procseq, @overridecalc, 
   			@dlrateamt, @glco, @overrideglacct, @overridelimit, @vendorgroup,
   			@vendor, @aptransdesc
   
   			while @@fetch_status = 0
   			begin
   
   				/*see if exists in PRED */
   				if exists(select PRCo from bPRED where PRCo = @hrrmprco and 
   					Employee = @hrrmprempl and DLCode = @dlcode)
   				begin
   					select @batchtranstype='C'
   				end
   				else
   				begin
   					select @batchtranstype='A'
   				end
   
   
   
   
   				insert bHRBD (Co,Mth,BatchId,BatchSeq,EDLType, EDLCode,EmplBasedYN, Frequency,
   				ProcessSeq, OverrideCalc, RateAmt, GLCo, OverrideGLAcct,
   				OverrideLimit, VendorGroup, Vendor, APTransDesc, AnnualLimit,
   				AutoEarnSeq,BatchTransType, StdHours, Hours)
   				select @hrco, @mth, @batchid, @batchseq, @dltype, @dlcode, @empbased, @freq,
   				@procseq, @overridecalc, @dlrateamt, @glco, @overrideglacct,
   				@overridelimit, @vendorgroup, @vendor, @aptransdesc,0,
   				@autoearnseq, @batchtranstype, 'N', 0
   
   				if @batchtranstype ='C'
   				begin
   					update bHRBB 
   					set BatchTransType = @batchtranstype
   					where Co = @hrco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   				end
   				
   				fetch next from cHRBL into
   
   				@dlcode, @dltype, @empbased, @freq, @procseq, @overridecalc, 
   				@dlrateamt, @glco, @overrideglacct, @overridelimit, @vendorgroup,
   				@vendor, @aptransdesc
   
   			end 
   
   			if @openhrblcursor = 1
   			begin
   				close cHRBL
   				deallocate cHRBL
   				select @openhrblcursor = 0
   			end
   
   			--loop through earnings codes
   /*
   See 6/9 comment above.  The following select statement will need to be changed too.  If 
   ReadyYN = 'N' we will need to rollback the transaction and goto the next Resource.
   */
   			declare cHRBE cursor local fast_forward for 
   			select EarnCode, AutoEarnSeq, Department, InsCode, GLCo, RateAmount,
   			AnnualLimit, Frequency, StdHours, Hours, PaySeq 
   			from HRBE 
   			where HRCo = @hrco and HRRef = @hrebemployee and DependentSeq = 0 and 
   			BenefitCode = @benefitcode and ReadyYN = 'Y' order by AutoEarnSeq
   
   			open cHRBE
   			select @openhrbecursor = 1
   
   			fetch next from cHRBE into 
   			@earncode, @autoearnseq, @department, @inscode,
   			@glco, @earnrateamt, @annuallimit, @freq, @stdhours, @hours, @payseq      
     
   			while @@fetch_status = 0
   			begin
   				/*see if exists in PRAE */
   				if exists(select PRCo from bPRAE where PRCo = @hrrmprco and 
   					Employee = @hrrmprempl and EarnCode = @earncode and Seq = @autoearnseq)
   				begin
   					select @batchtranstype='C'
   				end
   				else
   				begin
   					select @batchtranstype='A'
   				end
   
   				insert bHRBD (Co,Mth,BatchId,BatchSeq,EDLType, EDLCode,EmplBasedYN, Frequency,
   				OverrideCalc, RateAmt, GLCo, Department, InsCode, AnnualLimit,
   				AutoEarnSeq, BatchTransType, StdHours, Hours, PaySeq)
   				select @hrco, @mth, @batchid, @batchseq, 'E', @earncode, 'N', @freq,
   				'N', @earnrateamt, @glco, @department, @inscode, @annuallimit,
   				@autoearnseq, @batchtranstype, @stdhours, @hours, @payseq
   
   				if @batchtranstype ='C'
   				begin
   					update bHRBB 
   					set BatchTransType = @batchtranstype
   					where Co = @hrco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   				end
   
   				fetch next from cHRBE into @earncode, @autoearnseq, @department, @inscode,
   				@glco, @earnrateamt, @annuallimit, @freq, @stdhours, @hours, @payseq      
   			end
   
   			if @openhrbecursor = 1
   			begin  
   				close cHRBE
   				deallocate cHRBE
   				select @openhrbecursor = 0
   			end
   
   			--changed to use commit/rollback transaction.  Delete was causing InUseMth/InUseBatchId 
   			--to be set to null for all HREB entries for this HRCo/HRRef in the HRBB delete trigger.  
   			--orig code.  If nothing inserted in HRBD for this header then delete the header
   			if (select count(Co) from HRBD 
   				where Co = @hrco and Mth = @mth and BatchId = @batchid  and BatchSeq = @batchseq) > 0
   				commit transaction
   			else
   				rollback transaction
   				
   nextresource:
   
   			fetch next from cHRBBAdd into
   			@hrebemployee, @hrrmprco, @hrrmprempl, @benefitcode, @hrebeffdate
   		end
   
   		if @openhrbbcurs = 1
   		begin 
   			close cHRBBAdd
   			deallocate cHRBBAdd
   			select @openhrbbcurs = 0
   		end
   	end
   
   --**************************************************************************************
   --#22167 corrected .EffectiveDate < @effectivedate to .EffectiveDate <= @effectivedate
   
   	if @salaryYN = 'Y' --work the salary
   	begin
   		if @restrictbyemp = 'Y'
   		begin
   			if @usepr = 'Y'
   			begin
   				--Restrict by Emp, using PR Emp.  1 PR, 1 Salary
   				declare cHRSH cursor for
   				Select s.HRRef, r.PRCo, r.PREmp, s.Type, s.NewSalary, s.EffectiveDate 
   				from HRSH s join HRRM r on s.HRCo = r.HRCo and s.HRRef = r.HRRef
   				where s.HRCo = @hrco and r.PRCo = @prco and r.PREmp = @employee and r.ExistsInPR = 'Y' and 
   				s.UpdatedYN = 'N' and s.InUseMth is null and s.InUseBatchId is null and s.EffectiveDate = 
   				(select max(s1.EffectiveDate) from HRSH s1 Join HRRM r1 on r1.HRCo = s1.HRCo and 
   				r1.HRRef = s1.HRRef where s1.HRCo = @hrco and r1.PREmp = @employee and 
   				s1.EffectiveDate <= @effectivedate and s1.InUseBatchId is null and s1.InUseMth is null and
   				s1.UpdatedYN = 'N')
   			end
   			else
   			begin
   				--Restrict by Emp, using HR Res. 1 HR, 1 Salary
   				declare cHRSH cursor for
   				Select s.HRRef, r.PRCo, r.PREmp, s.Type, s.NewSalary, s.EffectiveDate 
   				from HRSH s join HRRM r on s.HRCo = r.HRCo and s.HRRef = r.HRRef
   				where s.HRCo = @hrco and r.HRRef = @employee and r.PRCo is not null and r.PREmp is not null and 
   				r.ExistsInPR = 'Y' and s.UpdatedYN = 'N' and s.InUseMth is null and s.InUseBatchId is null and 
   				s.EffectiveDate = 
   				(select max(EffectiveDate) from HRSH s1 where s1.HRCo = @hrco and s1.HRRef = @employee and 
   				s1.EffectiveDate <= @effectivedate and s1.InUseBatchId is null and s1.InUseMth is null and 
   				s1.UpdatedYN = 'N')
   			end
   		end
   		else
   		begin
   			--No restriction, 1 salary
   			declare cHRSH cursor for
   			Select s.HRRef, r.PRCo, r.PREmp, s.Type, s.NewSalary, s.EffectiveDate
   			from HRSH s
   			join HRRM r on s.HRCo = r.HRCo and s.HRRef = r.HRRef
   			where s.HRCo = @hrco  and r.PRCo is not null and r.PREmp is not null
   			and r.ExistsInPR = 'Y' and s.UpdatedYN = 'N' and s.InUseMth is null
   			and s.EffectiveDate = (select max(EffectiveDate) from HRSH s1 where s1.HRCo = r.HRCo and s1.HRRef = r.HRRef
   			and s1.EffectiveDate <= @effectivedate and s1.InUseBatchId is null and s1.UpdatedYN = 'N' and s1.InUseMth is null)
   		end
   
   		open cHRSH
   		select @openhrshcursor = 1
   
   		fetch next from cHRSH into @hrshhrref, @hrshprco, @hrshpremp, @hrshsalrateflag, @hrshnewsal, @hrsheffdate
   
   		while @@fetch_status = 0
   		begin
   
   			--if this Resource exists in another batch skip it....
   			if exists(select 1 from HRBB where Co = @hrco and HRRef = @hrshhrref and 
   			Mth <> @mth and BatchId <> @batchid )
   				goto nextsalaryresource
   
   			select @batchseq = isnull(max(BatchSeq),0)+1 
   			from bHRBB 
   			where Co = @hrco and Mth = @mth and BatchId = @batchid
   
   			/*
   			Check that there is not an unposted entry in HRBB for this resource.  
   			If so, do not add the new entry.  
   			*/
   			if exists(Select Co from bHRBB where Co = @hrshprco and HRRef = @hrshhrref and BenefitSalaryFlag = 'S')
   			begin
   				select @rcode = 1
   			end
     			else
   			begin
   --22844
   				insert bHRBB (Co, Mth, BatchId, BatchSeq, HRRef, PRCo, Employee, BenefitCode,
   				BenefitSalaryFlag, SalaryRateFlag, SalaryAmt, EffectiveDate)
   				select @hrco, @mth, @batchid, @batchseq, @hrshhrref, @hrshprco, @hrshpremp, null,
   				'S', @hrshsalrateflag, @hrshnewsal, @hrsheffdate
   			end
   
   nextsalaryresource:
   
   			fetch next from cHRSH into @hrshhrref, @hrshprco, @hrshpremp, @hrshsalrateflag, @hrshnewsal, @hrsheffdate
   		end
   
   		if @openhrshcursor = 1
   		begin	
   			close cHRSH
   			deallocate cHRSH
   			select @openhrshcursor = 0
   		end
   	end
   
   	select @reccount = count(Co) from bHRBB where Co = @hrco and Mth = @mth and BatchId = @batchid
   
   	
   bspexit:
   
   	if @openhrbbcurs = 1
   	begin 
   		close cHRBBAdd
   		deallocate cHRBBAdd
   	end
   	
   	if @openhrblcursor = 1
   	begin
   		close cHRBL
   		deallocate cHRBL
   	end
   	
   	if @openhrshcursor = 1
   	begin	
   		close cHRSH
   		deallocate cHRSH
   	end
   
   	
   	/*If @rcode = 1 it's because there are Resources residing in unposted batches. It's not 
   	really an error.  Just want to flash a warning message.*/
   	if @rcode = 1
   		select @msg = 'There are eligible Resources residing in unposted batches.  ' + char(13) + 'Those Resources will not be added to this batch.'  
   
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspHRBBAdd] TO [public]
GO
