SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                         procedure [dbo].[bspHRResBenCodeInit]
/************************************************************************
* CREATED:	MH 4/30/01
* MODIFIED: MH 5/15/01  Was bringing over the deds but not the liabs. Issue 12367
*			mh 08/12/03 Issue 21706
*			mh 10/03/03 Issue 22541
*			mh 02/19/04 Issue 23759
*			mh 02/05/08 Issue 23347
*			mh 12/18/08 Issue 131361 - Need to insert vendor group into bHRBL
*			mh 04/20/09 Issue 133339 - Getting Vendor Group using PRCO.APCO for HRRM's PRCo.
*			TJL 02/08/10 Issue 136991 - Add PRDept & InsCode as default values when EarnCodes are initialized
   *		TJL 06/25/10 - Issue #139274, Default "Override Calculation" Option to "N-Calc Amt" when Benefit Code Rates = 0.0000
*
* Purpose of Stored Procedure
*
*	Initialize grids on HR Resource Benefits
*
*
* Notes about Stored Procedure
*
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
    
	(@hrco bCompany, @hrref bHRRef, @dependseq int, @benefitcode varchar(10), @effdate bDate,
	@msg varchar(500) = '' output)
    
    as
    set nocount on
    
	declare @rcode int, @cnt int, @glco bCompany, @dept bDept, @emplbased bYN,
	@edltype char(1), @edlcode bEDLCode, @freq bFreq, @procseq tinyint, 
	@openHRBIcursor tinyint, @errheader varchar(250), @errbody varchar(250),
	@hrrmPRCo bCompany, @hrcoPRCo bCompany, @freqcodeerr tinyint, @prcoerr tinyint, @errprco varchar(500),
	@hrblglco bCompany, @hrbeglco bCompany, @benefitoption smallint, @oldrate bUnitCost, 
	@newrate bUnitCost, @ratechgdate bDate, @updatedyn bYN, @apco bCompany, @vendorgroup bGroup,
	--136991, 02/08/10 TJL
	@inscode bInsCode

	select @rcode = 0, @procseq = 0
   
	select @freqcodeerr = 0, @prcoerr = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company!', @rcode = 1
		goto bspexit
	end

	if @hrref is null
	begin
		select @msg = 'Missing HR Resource!', @rcode = 1
		goto bspexit
	end

	if @dependseq is null
		select @dependseq = 0

	if @dependseq <> 0
	begin
		select @msg = 'Invalid Dependent Sequence!', @rcode = 1
		goto bspexit
	end
    
	select @errheader = 'The Benefit Code ' + @benefitcode + ' contains Earnings codes that do not have a required frequency code.' + char(13) +
	'Please review this Benefit Code''s setup in HR Benefit Codes.' + char(13) + char(10) +
	'Deduction/Liability and Earnings codes for this benefit will not be initialized.'

   
   	select @errprco = 'Warning:  The Payroll company in HR Resource Master for Resource ' + convert(varchar(5), @hrref) + char(13) +
   	'differs from the Payroll company specified in HR Company Parameters.  ' + char(13) + char(10) + 'Some Deduction/Liability/Earnings codes may ' +
   	'not have been initialized.' 
    

	--If Deductions/Liabilities or Earnings codes have aleady been set up in HRBL or HRBE then
	--not initializing.  
	if exists (select 1 from dbo.HRBL with (nolock) where HRCo = @hrco and HRRef = @hrref and
		DependentSeq = @dependseq and BenefitCode = @benefitcode)
	begin
		select @rcode = 0
		goto bspexit
	end

	if exists(select 1 from dbo.HRBE with (nolock) where HRCo = @hrco and HRRef = @hrref and
		BenefitCode = @benefitcode and DependentSeq = @dependseq)
	begin
		select @rcode = 0
		goto bspexit
	end
    
    --Get GLCo
	exec @rcode = bspGLCOfromHRCO @hrco, @glco output, @msg output

	if @rcode <> 0
		goto bspexit
	else --Message coming back as not null.  Reset to null
		select @msg = null

	--Issue 133339 Get APCo from PRCO using Resource's PRCo.  Use that APCo to get Vendor Group.
	select @apco = APCo from PRCO p (nolock)
	join HRRM h (nolock) on p.PRCo = h.PRCo
	where h.HRCo = @hrco and h.HRRef = @hrref

	--Get AP Vendor Group
	exec @rcode = dbo.bspAPVendorGrpGet @apco, @vendorgroup output, @msg output

	if @rcode <> 0
		goto bspexit
	else --Message coming back as not null.  Reset to null
		select @msg = null
   
   --09/29/03 mh - Get the PR Company associated with the HRRef.  Could be different then HRCO.PRCo
   	--136991, 02/08/10 TJL - Get PRDept & InsCode from HRRM
   	select @hrrmPRCo=m.PRCo, @hrcoPRCo = o.PRCo, @dept = m.PRDept, @inscode = m.StdInsCode
   	from dbo.HRRM m join HRCO o on m.HRCo = o.HRCo
   	where m.HRCo = @hrco and m.HRRef = @hrref
   
    
	if exists (Select 1 from dbo.HRBI with (nolock) where HRCo = @hrco and BenefitCode = @benefitcode and EDLType = 'E' and 
	Frequency is null)
	begin
		select @rcode = 2, @freqcodeerr = 1
		goto bspexit
	end
    
    
	declare HRBIcursor cursor local fast_forward for 
	select EDLType, EDLCode, Frequency 
	from dbo.HRBI with (nolock) where HRCo = @hrco and BenefitCode = @benefitcode

	open HRBIcursor
	select @openHRBIcursor = 1

	fetch next from HRBIcursor into @edltype, @edlcode, @freq

	while @@fetch_status = 0
	begin
		--Initializing @ratechgdate to @effdate.  Check will be made to determine if more then
		--one BenefitOption exists for EDLCode.  If so then @oldrate and @newrate will remain
		--zero.  Benefitoption will be inserted as null and Rate will be inserted as 0.
		select @emplbased = 'N', @oldrate = 0, @newrate = 0, @ratechgdate = @effdate

		if @edltype = 'E'
		begin
			--Give @hrbeglco an initial value....assume the HRCO.PRCo GL company.
			select @hrbeglco = @glco

				if @hrrmPRCo <> @hrcoPRCo
				begin
				--@EDLCode is for HRCO.PRCo.  Make sure it is in HRRM.PRCo
					if not exists(select 1 from dbo.PREC where PRCo = @hrrmPRCo
					and EarnCode = @edlcode)
					begin
						select @rcode = 2, @prcoerr = 1
						goto nextdlecode
					end
					else
						/*If HRCO.PRCo differs from HRRM.PRCo, we will allow the earnings code to 
						be added provided the Earnings code exists in both PR Companies.  However,
						since the Earnings code will be interfaced to the HRRM.PRCo we want to use
						the GLCo for that PR Company...which is assumed to be the PR Company number.
						*/
						select @hrbeglco = @hrrmPRCo
				end

--23347 If there is only one benefit option then we will initialize that option.  Otherwise, user must specify.
				if (select count(1) from dbo.HRBI where HRCo = @hrco and BenefitCode = @benefitcode and EDLCode = @edlcode and
				EDLType = @edltype) = 1
				begin
					select @benefitoption = BenefitOption, @oldrate = OldRate, @newrate = NewRate,
					@ratechgdate = EffectiveDate, @updatedyn = UpdatedYN 
					from dbo.HRBI (nolock)
					where HRCo = @hrco and BenefitCode = @benefitcode and EDLCode = @edlcode and
					EDLType = @edltype
				end

			--what if frequency is null?	
				if not exists(select 1 from dbo.HRBE where HRCo = @hrco and HRRef = @hrref and BenefitCode = @benefitcode
				and DependentSeq = @dependseq and EarnCode = @edlcode)

--23347 Include benefit option.  Rate is conditional based on effective date/rate change date comparison.
--					insert dbo.HRBE(HRCo,HRRef,BenefitCode,DependentSeq,
--					EarnCode,AutoEarnSeq, RateAmount,AnnualLimit,
--					Frequency,ReadyYN, GLCo)
--					values(@hrco,@hrref,@benefitcode,@dependseq,
--					@edlcode,1,0,0,
--					@freq,'N', @hrbeglco)

--					insert dbo.HRBE(HRCo,HRRef,BenefitCode,DependentSeq,
--					EarnCode,AutoEarnSeq, RateAmount,AnnualLimit,
--					Frequency,ReadyYN, GLCo, BenefitOption)
--					values(@hrco,@hrref,@benefitcode,@dependseq,
--					@edlcode,1, case when @effdate < @ratechgdate then @oldrate else @newrate end,0,
--					@freq,'N', @hrbeglco, @benefitoption)
	
					--	--136991, 02/08/10 TJL - Added PRDept & InsCode default values
					insert dbo.HRBE(HRCo,HRRef,BenefitCode,DependentSeq,
					EarnCode,AutoEarnSeq, RateAmount,AnnualLimit,
					Frequency,ReadyYN, GLCo, BenefitOption, Department, InsCode)
					values(@hrco,@hrref,@benefitcode,@dependseq,
					@edlcode,1, case when @updatedyn = 'N' then @oldrate when @updatedyn = 'Y' then
					(case when @effdate < @ratechgdate then @oldrate else @newrate end) else 0 end,0,
					@freq,'N', @hrbeglco, @benefitoption, @dept, @inscode)

		end
    	else  --EDLType = 'L'
		begin
	    	if not exists(select 1 from dbo.HRBL where HRCo = @hrco and HRRef = @hrref and 
			BenefitCode = @benefitcode and DependentSeq = @dependseq and 
			DLCode = @edlcode and DLType = @edltype)
			begin
				--begin 22541
				--Give @hrblglco an initial value....assume the HRCO.PRCo GL company.
				select @hrblglco = @glco
   
				--if the HRCO.PRCo differs from HRRM.PRCo, revalidate the code.  
				if @hrrmPRCo <> @hrcoPRCo
				begin
					--dl code/dl type exists in both HRCO.PRCo and HRRM.PRCo

					--the dlcode/dltype in @EDLCode and @EDLType are for HRCO.PRCo
					--check to see if they are in PRDL for HRRM.PRCo

					if not exists(select 1 from dbo.PRDL 
						where PRCo = @hrrmPRCo and DLCode = @edlcode and DLType = @edltype)
					begin
						select @rcode = 2, @prcoerr = 1
						goto nextdlecode
					end
	   
					--dl code exists in both HRCO.PRCo and HRRM.PRCo but the dl type
					--does not match.

					if ((select DLType from dbo.PRDL 
					where PRCo = @hrrmPRCo and DLCode = @edlcode) <> 
					(select DLType from dbo.PRDL where PRCo = @hrcoPRCo and DLCode = @edlcode))
					begin
						select @rcode = 2, @prcoerr = 1
						goto nextdlecode
					end
	   
					--dl code exists in HRCO.PRCo but not HRRM.PRCo.

					if not exists(select 1 from dbo.PRDL 
						where PRCo = @hrrmPRCo and DLCode = @edlcode 
						and DLType = @edltype)
					begin
						select @rcode = 2, @prcoerr = 1
						goto nextdlecode
					end
					/*If HRCO.PRCo differs from HRRM.PRCo, we will allow the D/L code to 
					be added provided the D/L code exists in both PR Companies and the type
					matches.  However, since the D/L code will be interfaced to the 
					HRRM.PRCo we want to use the GLCo for that PR Company...which is assumed 
					to be the PR Company number.
					*/
					select @hrblglco = @hrrmPRCo

				end

			--end 22541

--23347 If there is only one benefit option then we will initialize that option.  Otherwise, user must specify.
				if (select count(1) from dbo.HRBI where HRCo = @hrco and BenefitCode = @benefitcode and 
					EDLCode = @edlcode and EDLType = @edltype) = 1
				begin
					select @benefitoption = BenefitOption, @oldrate = isnull(OldRate,0), @newrate = isnull(NewRate,0),
					@ratechgdate = EffectiveDate, @updatedyn = UpdatedYN   
					from dbo.HRBI (nolock)
					where HRCo = @hrco and BenefitCode = @benefitcode and EDLCode = @edlcode and
					EDLType = @edltype
				end
				else
				begin
					select @updatedyn = 'N', @oldrate = 0, @newrate = 0
				end

				if @freq is not null
				begin
				--Issue 23759
				--select @emplbased = 'Y', @procseq = @procseq + 1
					select @emplbased = 'Y', @procseq = 1
--23347 Include benefit option.  Rate is conditional based on effective date/rate change date comparison.
--					insert dbo.HRBL(HRCo,HRRef,BenefitCode,DependentSeq,DLCode,
--					DLType,EmplBasedYN,OverrideCalc,RateAmt,OverrideLimit, 
--					ReadyYN, GLCo, Frequency, ProcessSeq, BenefitOption)
--					values(@hrco,@hrref,@benefitcode,@dependseq,@edlcode,
--					@edltype,@emplbased, case when @benefitoption is null then 'N' else 'R' end,
--					case when @effdate < @ratechgdate then @oldrate else @newrate end,0,
--					'N', @hrblglco, @freq, @procseq, @benefitoption)

--					insert dbo.HRBL(HRCo,HRRef,BenefitCode,DependentSeq,DLCode,
--					DLType,EmplBasedYN,OverrideCalc,RateAmt,OverrideLimit, 
--					ReadyYN, GLCo, Frequency, ProcessSeq, BenefitOption, VendorGroup)
--					values(@hrco,@hrref,@benefitcode,@dependseq,@edlcode,
--					@edltype,@emplbased, case when @benefitoption is null then 'N' else 'R' end,
--					case when @updatedyn = 'N' then @oldrate when @updatedyn = 'Y' then
--					(case when @effdate < @ratechgdate then @oldrate else @newrate end) end,0,
--					'N', @hrblglco, @freq, @procseq, @benefitoption, @vendorgroup)
select @benefitoption 'Benefit Option'
					insert dbo.HRBL(HRCo,HRRef,BenefitCode,DependentSeq,DLCode,
					DLType,EmplBasedYN,OverrideCalc,RateAmt,OverrideLimit, 
					ReadyYN, GLCo, Frequency, ProcessSeq, BenefitOption, VendorGroup)
					values(@hrco,@hrref,@benefitcode,@dependseq,@edlcode,
					@edltype,@emplbased, 
					case when @benefitoption is null then 'N'
						else (case when (@oldrate = 0 and @newrate = 0) then 'N' else 'R' end) end,
					isnull(case when (@oldrate = 0 and @newrate = 0) then 0
						else
							(case when @updatedyn = 'N' then @oldrate 
							when @updatedyn = 'Y' then (case when @effdate  < @ratechgdate then @oldrate else @newrate end) end) 
						end,0),
					0, 'N', @hrblglco, case when @benefitoption is not null then @freq else null end, 
					@procseq, @benefitoption, @vendorgroup)

				end
				else
				begin

--23347 Include benefit option.  Rate is conditional based on effective date/rate change date comparison.
--					insert dbo.HRBL(HRCo,HRRef,BenefitCode,DependentSeq,DLCode,
--					DLType,EmplBasedYN,OverrideCalc,RateAmt,OverrideLimit,
--					ReadyYN, GLCo, Frequency, BenefitOption)
--					values(@hrco,@hrref,@benefitcode,@dependseq,@edlcode,
--					@edltype,@emplbased, case when @benefitoption is null then 'N' else 'R' end,
--					case when @effdate < @ratechgdate then @oldrate else @newrate end,0,
--					'N', @hrblglco, @freq, @benefitoption)

--					insert dbo.HRBL(HRCo,HRRef,BenefitCode,DependentSeq,DLCode,
--					DLType,EmplBasedYN,OverrideCalc,RateAmt,OverrideLimit,
--					ReadyYN, GLCo, Frequency, BenefitOption, VendorGroup)
--					values(@hrco,@hrref,@benefitcode,@dependseq,@edlcode,
--					@edltype,@emplbased, case when @benefitoption is null then 'N' else 'R' end,
--					isnull(case when @updatedyn = 'N' then @oldrate when @updatedyn = 'Y' then(					
--					case when @effdate < @ratechgdate then @oldrate else @newrate end) end,0),0,
--					'N', @hrblglco, @freq, @benefitoption, @vendorgroup)

					insert dbo.HRBL(HRCo,HRRef,BenefitCode,DependentSeq,DLCode,
					DLType,EmplBasedYN,OverrideCalc,RateAmt,OverrideLimit,
					ReadyYN, GLCo, Frequency, BenefitOption, VendorGroup)
					values(@hrco,@hrref,@benefitcode,@dependseq,@edlcode,
					@edltype,@emplbased, 
					case when @benefitoption is null then 'N'
						else (case when (@oldrate = 0 and @newrate = 0) then 'N' else 'R' end) end,
					isnull(case when (@oldrate = 0 and @newrate = 0) then 0
						else
							(case when @updatedyn = 'N' then @oldrate 
							when @updatedyn = 'Y' then (case when @effdate  < @ratechgdate then @oldrate else @newrate end) end) 
						end,0),
					0,'N', @hrblglco, case when @benefitoption is not null then @freq else null end,
					@benefitoption, @vendorgroup)

				end

			end			
		end
   
		nextdlecode: 		
		fetch next from HRBIcursor into @edltype, @edlcode, @freq
    
	end
    
    bspexit:
    
    	if @openHRBIcursor = 1
    	begin
    		close HRBIcursor
    		deallocate HRBIcursor
    	end
   
    	if @rcode = 2
   		begin
   			if @freqcodeerr = 1
   				select @msg = @errheader + char(13) + char(10)
   
   			if @prcoerr = 1
   			begin
   				if @msg is not null 
   					select @msg = @msg  + @errprco
   				else
   					select @msg = @errprco
   			end
   
   			select @msg = ltrim(@msg)
   		end 
   
   		declare @dupmsg varchar(1000), @duprcode tinyint
   	
   		exec @duprcode = bspHRDLEDupCheck @hrco, @hrref, @dupmsg output
   	
   		if @duprcode = 2
   		begin
   			if @msg is not null
   				select @msg = @msg + char(13) + @dupmsg
   			else
   				select @msg = @dupmsg
	   	
   			select @rcode = 2
   		end
    
   	return @rcode





GO
GRANT EXECUTE ON  [dbo].[bspHRResBenCodeInit] TO [public]
GO
