SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                             procedure [dbo].[bspHRInitBenefits]
   /*************************************
   *Created by:  ae 12/4/99
   *Modified by: ae 1/21/99  Fixed per issue #5491
   *             ae 02/17/00 added 'skips'
   *				mh 2/1/01 Issue 11937:  Setting HREB.ActiveYN and HREB.EffectDate
   *							based on HRGI.ElectiveYN flag.
   *			mh 11/29/01 Issue 15232
   *				SR 07/30/02 Issue 18093 - ActiveYN not getting set in HREB
   *				mh 4/25/03 Issue 21002
   *				mh 8/8/03 Issue 22106
   *				mh 08/11/03 Issue 22111 - Sync up with bspHRResBenCodeInit.  Missing GLCo
   *					from insert into HRBL and GLCo and Department from insert into HRBE.
   *				mh 8/19/03 Issue 21706
   *				mh 10/03/03 Issue 22541
   *				mh 02/26/04 Issue 23759 - Default Processing Seq to 1 as opposed to 
   *					incrementing as before.
   *				mh 6/1/2005 Issue 28704 - Initialize @eligdate each time through the Benefit Code loop
   *				mh 7/7/2006 - Issue 121823.  Need to default 'N' for ReinstateYN, SmokerYN, 
   *					CafePlanYN in HREB
   *				mh 2/21/2008 - Issue 23347 - Removed UpdatePRYN.  4/18/08 implemented multiple options
   *				mh 5/23/2008 - Issue 23347 - Changed default value for insert to HRBL.OverrideCalc.  If there is
									a Benefit Option set up in HR Benefit Codes that I can default (that is only 1
									Benefit Option, I default in 'R', otherwise I leave it 'N'
   *				mh 12/18/08 Issue 131361 - Need to insert vendor group into bHRBL
   *			TJL 02/08/10 Issue 136991 - Add PRDept & InsCode as default values when EarnCodes are initialized
   *		TJL 06/25/10 - Issue #139274, Default "Override Calculation" Option to "N-Calc Amt" when Benefit Code Rates = 0.0000
   *
   * Desc:
   *Initializes the benefit codes for a Resource given a Benefit Group
   *
   *
   * Pass:
   *   HRCo
   *   HRRef
   *   BenefitGroup
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
	(@HRCo bCompany, @HRRef bHRRef, @BenefitGroup varchar(10), @EffectiveDate bDate, @msg varchar(500) output)
	as
	set nocount on
	declare @rcode int

	declare @Seq int, @BenefitCode varchar(10), @EDLType char(1),
	@EDLCode bEDLCode, @electiveYN bYN, @activeYN bYN, @eligdate bDate,
	@freq bFreq, @openedlcurs tinyint, @openbccurs tinyint, @freqerrmsg varchar(250), 
	@errbody varchar(250), @glco bCompany, @dept bDept, @emplbased bYN, @procseq tinyint,
	@hrblglco bCompany, @hrbeglco bCompany, @hrrmPRCo bCompany, @hrcoPRCo bCompany, 
	@prcoerrmsg varchar(500), @freqcodeerr tinyint, @prcoerr tinyint,
   	@bencodelist varchar(500), @benefitopt smallint, @oldrate bUnitCost, 
	@newrate bUnitCost, @ratechgdate bDate, @updatedyn bYN, @apco bCompany, @vendorgroup bGroup,
    --136991 02/08/10 TJL 
    @inscode bInsCode
    
   	select @freqcodeerr = 0, @prcoerr = 0, @rcode = 0
   
   	if @HRCo is null
   	begin
   		select @msg = 'Missing HR Company', @rcode = 1
   		goto bspexit
   	end
   
   	if @HRRef is null
   	begin
   		select @msg = 'Missing Resource Number', @rcode = 1
   		goto bspexit
   	end
   
   	if @BenefitGroup is null
   	begin
   		select @msg = 'Missing BenefitGroup', @rcode = 1
   		goto bspexit
   	end
   
--   	select @freqerrmsg = 'Warning:  The following Benefit Codes within Benefit Group ' + @BenefitGroup + char(13) +
--   	' contain Earnings codes that do not have a required frequency code. ' + char(13) + char(10) +
--   	'The following benefit code(s) will not be initialized:' + char(13) + char(10)

   	select @freqerrmsg = 'Warning:  The following Benefit Codes within Benefit Group contain Earnings codes that do not have a required frequency code.  The following benefit code(s) will not be initialized:'
      
   
--   	select @prcoerrmsg = 'Warning:  The Payroll company in HR Resource Master for Resource ' + convert(varchar(5), @HRRef) + char(13) +
--   	' differs from the Payroll company specified in HR Company Parameters.  ' + char(13) + 'Some Deduction/Liability/Earnings codes may ' +
--   	'not have been initialized.' + char(13)

   	select @prcoerrmsg = 'Warning:  The Payroll company in HR Resource Master for Resource differs from the Payroll company specified in HR Company Parameters.  Some Deduction/Liability/Earnings codes may not have been initialized.'
   
   	exec bspGLCOfromHRCO @HRCo, @glco output, @msg output
   
   	if @glco is null
   	begin
   		select @msg = 'Unable to get GL Company', @rcode = 1
   		goto bspexit
   	end
	
	select @apco = APCo from PRCO p (nolock)
	join HRRM h (nolock) on p.PRCo = h.PRCo
	where h.HRCo = @HRCo and h.HRRef = @HRRef
   
	--Get AP Vendor Group
	exec @rcode = dbo.bspAPVendorGrpGet @apco, @vendorgroup output, @msg output

	if @rcode <> 0
		goto bspexit
	else --Message coming back as not null.  Reset to null
		select @msg = null

	--136991 02/08/10 TJL - Add InsCode
   	select @dept = m.PRDept, @hrrmPRCo=m.PRCo, @hrcoPRCo = o.PRCo,
   		@inscode = m.StdInsCode
   	from HRRM m (nolock) join HRCO o on m.HRCo = o.HRCo
   	where m.HRCo = @HRCo and m.HRRef = @HRRef
   
   --outer cursor representing the Benefit codes comprising the Benefit group 
   	declare cBenefitCode cursor local fast_forward for 
   	select BenefitCode, ElectiveYN from dbo.HRGI with (nolock)
   	where HRCo = @HRCo and BenefitGroup = @BenefitGroup
   
   	open cBenefitCode
   	select @openbccurs = 1
   
   	fetch next from cBenefitCode into @BenefitCode, @electiveYN
   	
   	while @@fetch_status = 0
   	begin
		--Issue 28704
   		select @procseq = 0, @eligdate = null
   
   		if exists(select HRCo from dbo.HREB with (nolock) where HRCo = @HRCo and HRRef = @HRRef and BenefitCode = @BenefitCode and DependentSeq = 0)
   			goto nextbenefitcode  --if already there then skip.
   
   		/*Issue 21706 Frequency is required when EDLType = 'E'.  Before cycling through them
   		and adding Earnings codes to HRBE make sure each EDLCode for EDLType = 'E' has a 
   		frequency assigned.  If the following statement returns anything then go to the next
   		benefit */
   
   		if exists (Select 1 from dbo.HRBI with (nolock) 
   				where HRCo = @HRCo and BenefitCode = @BenefitCode and EDLType = 'E' and 
   		 		Frequency is null)
   		begin
   			--	develop error message
   
   			if @errbody is null
   				select @errbody = char(9) + @BenefitCode + char(13) + char(10)
				--select @errbody = @BenefitCode + char(13) + char(10)
   			else
   				select @errbody = @errbody + @BenefitCode + char(13) + char(10)
   		
   			select @rcode = 2, @freqcodeerr = 1
   			goto nextbenefitcode
   
   		end
   
   		if upper(@electiveYN) = 'Y'
   		begin
			select @activeYN = 'N'
   		end
   		else
   		begin
			--Issue 15232 11/29/01
			--need to calculate elig date.  shell out to procedure used in HRResourceBenefits to
			--calculate default elig date.  No longer populating ActiveYN and Effective Date.  This
			--in effect undoes some of the changes from 2/1/01.  mh
   			select @activeYN = 'Y'
   
   			exec bspHRBenDefltEligDate @HRCo, @HRRef, @BenefitCode, @eligdate output, @msg output
   			select @msg = null
   		end
   
		--begin 22106 08/08/03
		--begin 121823
   		--insert dbo.HREB(HRCo,HRRef,BenefitCode,DependentSeq, ActiveYN, EligDate,UpdatePRYN)
   		--values(@HRCo,@HRRef,@BenefitCode,0, @activeYN, @eligdate, @UpdatePRYN)
  
   		insert dbo.HREB(HRCo,HRRef,BenefitCode,DependentSeq, ActiveYN, EligDate, 
		ReinstateYN, SmokerYN, CafePlanYN, EffectDate)
   		values(@HRCo,@HRRef,@BenefitCode,0, @activeYN, @eligdate, 'N', 'N', 'N', @EffectiveDate)
		--end 121823
		--end 22106 08/08/03 mh

		--end 11/29/01
		--end 02/01/01
   
   		if @@rowcount = 0
   		begin
   			select @msg = 'Error inserting Benefit Code',@rcode=1
   			goto bspexit
   		end

		--Inner cursor representing the D/L/E codes for a specific Benefit Code 
   		declare cEDLCursor cursor local fast_forward for
/*
   		Select EDLCode, EDLType, Frequency
   		from dbo.HRBI with (nolock) 
   		where HRCo = @HRCo and BenefitCode = @BenefitCode
*/
		select distinct EDLCode, EDLType
   		from dbo.HRBI with (nolock) 
   		where HRCo = @HRCo and BenefitCode = @BenefitCode
		   
   		open cEDLCursor
   		select @openedlcurs = 1
   		
   		fetch next from cEDLCursor into
   		--@EDLCode, @EDLType, @freq, @benefitopt
		@EDLCode, @EDLType
   
   		while @@fetch_status = 0
   		begin
   			select @oldrate = 0, @newrate = 0
   			
			if @EDLType = 'E'
			begin
				select @hrbeglco = @glco

				if @hrrmPRCo <> @hrcoPRCo
				begin
				--@EDLCode is for HRCO.PRCo.  Make sure it is in HRRM.PRCo
					if not exists(select 1 from PREC where PRCo = @hrrmPRCo
					and EarnCode = @EDLCode)
					begin
						select @rcode = 2, @prcoerr = 1
						goto nextdlecode
					end
					else
					begin
					--the HRRef's PRCo and HRCO's PRCo differ.  If the Earnings code exists in
					--both companies and we are going to add it to HRBE use the HRRef's PRCo as
					--the GLCo.
						select @hrbeglco = @hrrmPRCo
					end
				end

				if exists(select HRCo from HRBE with (nolock) where HRCo = @HRCo and 
				HRRef = @HRRef and BenefitCode = @BenefitCode and DependentSeq = 0 
				and EarnCode = @EDLCode)
					goto nextdlecode  --if already there then skip.


				if (select count(1) from HRBI (nolock) 
					where HRCo = @HRCo and BenefitCode = @BenefitCode and
					EDLCode = @EDLCode and EDLType = 'E') > 1
				begin
					select top 1 @freq = Frequency, @benefitopt = null
					from dbo.HRBI with (nolock) where HRCo = @HRCo and BenefitCode = @BenefitCode and
					EDLCode = @EDLCode and EDLType = 'E'
				end
				else
				begin
					select @benefitopt = BenefitOption, @freq = Frequency, @oldrate = isnull(OldRate,0), @newrate = isnull(NewRate,0),
					@ratechgdate = EffectiveDate, @updatedyn = UpdatedYN   
					from dbo.HRBI with (nolock) where HRCo = @HRCo and BenefitCode = @BenefitCode and
					EDLCode = @EDLCode and EDLType = 'E'
				end

--				insert dbo.HRBE(HRCo,HRRef,BenefitCode,DependentSeq, EarnCode,AutoEarnSeq, 
--				RateAmount,AnnualLimit, Frequency,ReadyYN, GLCo, BenefitOption)
--				values(@HRCo,@HRRef,@BenefitCode,0, @EDLCode,1,0,0, @freq,'N', @hrbeglco, @benefitopt)

				--136991 02/08/10 TJL - Add Department &InsCode
				insert dbo.HRBE(HRCo,HRRef,BenefitCode,DependentSeq, EarnCode,AutoEarnSeq, 
				RateAmount,AnnualLimit, Frequency,ReadyYN, GLCo, BenefitOption, Department, InsCode)
				values(@HRCo,@HRRef,@BenefitCode,0,
				@EDLCode,1, case when @updatedyn = 'N' then @oldrate when @updatedyn = 'Y' then
				(case when @EffectiveDate < @ratechgdate then @oldrate else @newrate end) else 0 end,0,
				@freq,'N', @hrbeglco, @benefitopt, @dept, @inscode)
			end

			else
			--@EDLType = 'D' or 'L'   
			begin
				select @emplbased = 'N', @hrblglco = @glco

				if exists(select HRCo from dbo.HRBL with (nolock) where HRCo = @HRCo and 
				HRRef = @HRRef and BenefitCode = @BenefitCode and DependentSeq = 0 
				and DLCode = @EDLCode)
				begin
					--goto nextbenefitcode  --if already there then skip.
					goto nextdlecode
				end
				--begin 22541

				--if the HRCO.PRCo differs from HRRM.PRCo, revalidate the code.  
				if @hrrmPRCo <> @hrcoPRCo
				begin
					--dl code/dl type exists in both HRCO.PRCo and HRRM.PRCo

					--the dlcode/dltype in @EDLCode and @EDLType are for HRCO.PRCo
					--check to see if they are in PRDL for HRRM.PRCo

					if not exists(select 1 from dbo.PRDL 
						where PRCo = @hrrmPRCo and DLCode = @EDLCode and DLType = @EDLType)
					begin
						select @rcode = 2, @prcoerr = 1
						goto nextdlecode
					end

					--dl code exists in both HRCO.PRCo and HRRM.PRCo but the dl type
					--does not match.

					if ((select DLType from dbo.PRDL 
					where PRCo = @hrrmPRCo and DLCode = @EDLCode) <> 
					(select DLType from PRDL where PRCo = @hrcoPRCo and DLCode = @EDLCode))
					begin
						select @rcode = 2, @prcoerr = 1
						goto nextdlecode
					end

					--dl code exists in HRCO.PRCo but not HRRM.PRCo.

					if not exists(select 1 from dbo.PRDL 
						where PRCo = @hrrmPRCo and DLCode = @EDLCode 
						and DLType = @EDLType)
					begin
						select @rcode = 2, @prcoerr = 1
						goto nextdlecode
					end

					--the HRRef's PRCo and HRCO's PRCo differ.  If the D/L code exists in
					--both companies and we are going to add it to HRBL use the HRRef's PRCo as
					--the GLCo.
					select @hrblglco = @hrrmPRCo
				end
				--end 22541

				if (select count(1) from HRBI (nolock) 
					where HRCo = @HRCo and BenefitCode = @BenefitCode and
					EDLCode = @EDLCode and EDLType <> 'E') > 1
				begin
					select top 1 @freq = Frequency, @benefitopt = null
					from HRBI (nolock) 
					where HRCo = @HRCo and BenefitCode = @BenefitCode and
					EDLCode = @EDLCode and EDLType <> 'E'
				end
				else
				begin
					select @benefitopt = BenefitOption, @freq = Frequency, @oldrate = isnull(OldRate,0), 
					@newrate = isnull(NewRate,0), @ratechgdate = EffectiveDate, @updatedyn = UpdatedYN	
					from dbo.HRBI with (nolock) 
					where HRCo = @HRCo and BenefitCode = @BenefitCode and
					EDLCode = @EDLCode and EDLType <> 'E'
				end

				if @freq is not null
				begin
					--select @emplbased = 'Y', @procseq = @procseq + 1
					select @emplbased = 'Y', @procseq = 1

					insert dbo.HRBL(HRCo,HRRef,BenefitCode,DependentSeq,DLCode,
						DLType,EmplBasedYN,OverrideCalc,RateAmt,OverrideLimit,
						ReadyYN, GLCo, Frequency, ProcessSeq, BenefitOption, VendorGroup)
					values(@HRCo,@HRRef,@BenefitCode,0,@EDLCode,
						@EDLType,@emplbased, 
						case when @benefitopt is null then 'N' 
							else (case when (@oldrate = 0 and @newrate = 0) then 'N' else 'R' end) end,
						isnull(case when (@oldrate = 0 and @newrate = 0) then 0 
							else 
								(case when @updatedyn = 'N' then @oldrate 
								when @updatedyn = 'Y' then (case when @EffectiveDate < @ratechgdate then @oldrate else @newrate end) end) 
							end,0),
						0, 'N', @hrblglco, @freq, @procseq, @benefitopt, @vendorgroup)
				end
				else
				begin
					insert dbo.HRBL(HRCo,HRRef,BenefitCode,DependentSeq,DLCode,
						DLType,EmplBasedYN,OverrideCalc,RateAmt,OverrideLimit,
						ReadyYN, GLCo, Frequency, BenefitOption, VendorGroup)
					values(@HRCo,@HRRef,@BenefitCode,0,@EDLCode,
						@EDLType,@emplbased, 
						case when @benefitopt is null then 'N' 
							else (case when (@oldrate = 0 and @newrate = 0) then 'N' else 'R' end) end,
						isnull(case when (@oldrate = 0 and @newrate = 0) then 0 
							else 
								(case when @updatedyn = 'N' then @oldrate 
								when @updatedyn = 'Y' then (case when @EffectiveDate < @ratechgdate then @oldrate else @newrate end) end) 
							end,0),
						0, 'N', @hrblglco, @freq, @benefitopt, @vendorgroup)
				end

				if (select count(HRCo) from HRBL with (nolock)
				where HRCo = @HRCo and HRRef = @HRRef and BenefitCode <> @BenefitCode and DependentSeq = 0 and
				DLCode = @EDLCode and DLType = @EDLType) > 0
				begin
					if @bencodelist is null
						select @bencodelist = @BenefitCode
					else
						select @bencodelist = @bencodelist + @BenefitCode
					
				end

			end

   
   nextdlecode: 
   			fetch next from cEDLCursor into @EDLCode, @EDLType --, @freq
   
   		end
   
   		if @openedlcurs = 1
   		begin
   			close cEDLCursor
   			deallocate cEDLCursor
   			select @openedlcurs = 0
   		end
   
   		nextbenefitcode:
   
   		fetch next from cBenefitCode into @BenefitCode, @electiveYN
   	end
   
   
   bspexit:
   
   
   	if @openedlcurs = 1
   	begin
   		close cEDLCursor
   		deallocate cEDLCursor
   		select @openedlcurs = 0
   	end
   
   	if @openbccurs = 1
   	begin
   		close cBenefitCode 	
   		deallocate cBenefitCode
   		select @openbccurs = 0
   	end
   
   	if @rcode = 2
   	begin
   		if @freqcodeerr = 1
   		begin
   			if @errbody is not null
   				select @msg = @freqerrmsg + @errbody
   		end
   
   		--if @prcoerrmsg is not null
   		if @prcoerr = 1
   		begin
   			if @msg is not null 
   				select @msg = @msg  + char(13) + char(10) + @prcoerrmsg
   			else
   				select @msg = @prcoerrmsg
   		end
   
   	end
   
   
   declare @dupmsg varchar(1000), @duprcode tinyint
   
   exec @duprcode = bspHRDLEDupCheck @HRCo, @HRRef, @dupmsg output
   
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
GRANT EXECUTE ON  [dbo].[bspHRInitBenefits] TO [public]
GO
