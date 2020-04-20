SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRBenefitCodeUpdate]
	/******************************************************
	* CREATED BY:	MH 2/6/2008 
	* MODIFIED By:  TJL 06/25/10 - Issue #139274, Default "Override Calculation" Option to "N-Calc Amt" when Benefit Code Rates = 0.0000 
	*
	* Usage:	Using a Benefit Code passed in, update all
	*			applicable Resources in HR Resource Benefits.
	*	
	*
	* Input params:
	*	
	*			@hrco - HR Company 
	*			@benefitcode - Benefit Code from HRBC to be updated
	*			in HREB
	*			@inactiveyn - Flag to include Inactive Resources in HRRM
	*			@matchratesyn - Flag to only update those HRBL and HRBE
	*			records where the rates match the old rate in HRBI.  (This 
	*			prevents and override in HRBL/HRBE from being overwritten
	*			during the update process.) 
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*
	*
	*			Developed four update statement groups corresponding
	*			to the possible combinations of Inactive Resources
	*			and Matching Rates.	First determine if we are including
	*			inactive Resources as defined by HRRM.ActiveYN.  Then within
	*			those two groups determine if we are only updating those records
	*			where the current rate in HRBL/HRBE matches the old rate in
	*			HRBI.  HRBL and HRBE will be updated independently.
	*
	*			Upon completion HRBI.UpdatedYN flag will be updated.
	*
	*******************************************************/
   
   	(@hrco bCompany, @benefitcode varchar(10), @hrref bHRRef = null, @inactiveyn bYN = 'N', @matchratesyn bYN = 'Y', @msg varchar(100) output)

	as 
	set nocount on
	declare @rcode tinyint
   	
	select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company.', @rcode = 1
		goto vspexit
	end

	if @benefitcode is null
	begin
		select @msg = 'Missing Benefit Code.', @rcode = 1
		goto vspexit
	end

	if @hrref is null
	begin

		if @inactiveyn = 'Y' 
		--Include Inactive Employees
		begin
			if @matchratesyn = 'Y'
			--Update only matching rates
			begin

				--Update Deductions and Liabilities
				update dbo.HRBL
				set RateAmt = case when (i.OldRate = 0 and i.NewRate = 0) then l.RateAmt else i.NewRate end, 
				OverrideCalc = case when (i.OldRate = 0 and i.NewRate = 0) then l.OverrideCalc else 'R' end, 
				ReadyYN = 'Y'
				from dbo.HREB b
				join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
				left join dbo.HRBL l on b.HRCo = l.HRCo and b.HRRef = l.HRRef and 
					b.BenefitCode = l.BenefitCode and b.DependentSeq = l.DependentSeq
				left join dbo.HRBI i on l.HRCo = i.HRCo and l.BenefitCode = i.BenefitCode and 
					l.BenefitOption = i.BenefitOption  and l.DLType = i.EDLType and l.DLCode = i.EDLCode 
					and l.RateAmt = i.OldRate and i.UpdatedYN = 'N'
				where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and i.EDLType <> 'E' 

				--Update Earnings Codes
				update dbo.HRBE
				set RateAmount = i.NewRate, ReadyYN = 'Y'
				from dbo.HREB b
				join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
				left join dbo.HRBE e on b.HRCo = e.HRCo and b.HRRef = e.HRRef and 
					b.BenefitCode = e.BenefitCode and b.DependentSeq = e.DependentSeq
				left join dbo.HRBI i on e.HRCo = i.HRCo and e.BenefitCode = i.BenefitCode and
					e.BenefitOption = i.BenefitOption and e.EarnCode = i.EDLCode and e.RateAmount = i.OldRate 
					and i.UpdatedYN = 'N'
				where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and i.EDLType = 'E'

			end
			else --@matchratesyn = 'N'
			--Update all rates
			begin
				--Update Deductions and Liabilities
				update dbo.HRBL
				set RateAmt = case when (i.OldRate = 0 and i.NewRate = 0) then l.RateAmt else i.NewRate end, 
				OverrideCalc = case when (i.OldRate = 0 and i.NewRate = 0) then l.OverrideCalc else 'R' end, 
				ReadyYN = 'Y'
				from dbo.HREB b
				join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
				left join dbo.HRBL l on b.HRCo = l.HRCo and b.HRRef = l.HRRef and 
					b.BenefitCode = l.BenefitCode and b.DependentSeq = l.DependentSeq
				left join dbo.HRBI i on l.HRCo = i.HRCo and l.BenefitCode = i.BenefitCode and 
					l.BenefitOption = i.BenefitOption and l.DLType = i.EDLType and l.DLCode = i.EDLCode
					and i.UpdatedYN = 'N'
				where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and i.EDLType <> 'E'

				--Update Earnings Codes
				update dbo.HRBE
				set RateAmount = i.NewRate, ReadyYN = 'Y'
				from dbo.HREB b
				join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
				left join dbo.HRBE e on b.HRCo = e.HRCo and b.HRRef = e.HRRef and 
					b.BenefitCode = e.BenefitCode and b.DependentSeq = e.DependentSeq
				left join dbo.HRBI i on e.HRCo = i.HRCo and e.BenefitCode = i.BenefitCode and
					e.BenefitOption = i.BenefitOption and e.EarnCode = i.EDLCode
					and i.UpdatedYN = 'N'
				where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and i.EDLType = 'E'

			end
		end
		else	--@inactiveyn = 'N'
		--Exclude Inactive Employees
		begin
			if @matchratesyn = 'Y'
			--Update only matching rates
			begin
				--Update Deductions and Liabilities
				update dbo.HRBL
				set RateAmt = case when (i.OldRate = 0 and i.NewRate = 0) then l.RateAmt else i.NewRate end, 
				OverrideCalc = case when (i.OldRate = 0 and i.NewRate = 0) then l.OverrideCalc else 'R' end, 
				ReadyYN = 'Y'
				from dbo.HREB b
				join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
				left join dbo.HRBL l on b.HRCo = l.HRCo and b.HRRef = l.HRRef and 
					b.BenefitCode = l.BenefitCode and b.DependentSeq = l.DependentSeq
				left join dbo.HRBI i on l.HRCo = i.HRCo and l.BenefitCode = i.BenefitCode and 
					l.BenefitOption = i.BenefitOption  and l.DLType = i.EDLType and l.DLCode = i.EDLCode
					and l.RateAmt = i.OldRate and i.UpdatedYN = 'N'
				where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and 
					m.ActiveYN = 'Y' and i.EDLType <> 'E'

				--Update Earnings Codes
				update dbo.HRBE
				set RateAmount = i.NewRate, ReadyYN = 'Y'
				from dbo.HREB b
				join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
				left join dbo.HRBE e on b.HRCo = e.HRCo and b.HRRef = e.HRRef and 
					b.BenefitCode = e.BenefitCode and b.DependentSeq = e.DependentSeq
				left join dbo.HRBI i on e.HRCo = i.HRCo and e.BenefitCode = i.BenefitCode and
					e.BenefitOption = i.BenefitOption and e.EarnCode = i.EDLCode and e.RateAmount = i.OldRate
					 and i.UpdatedYN = 'N'
				where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and 
					m.ActiveYN = 'Y' and i.EDLType = 'E'

			end
			else --@matchratesyn = 'N'
			begin
			--Update all rates
				--Update Deductions and Liabilities
				update dbo.HRBL
				set RateAmt = case when (i.OldRate = 0 and i.NewRate = 0) then l.RateAmt else i.NewRate end, 
				OverrideCalc = case when (i.OldRate = 0 and i.NewRate = 0) then l.OverrideCalc else 'R' end, 
				ReadyYN = 'Y'
				from dbo.HREB b
				join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
				left join dbo.HRBL l on b.HRCo = l.HRCo and b.HRRef = l.HRRef and 
					b.BenefitCode = l.BenefitCode and b.DependentSeq = l.DependentSeq
				left join dbo.HRBI i on l.HRCo = i.HRCo and l.BenefitCode = i.BenefitCode and 
					l.BenefitOption = i.BenefitOption and l.DLType = i.EDLType and l.DLCode = i.EDLCode and i.UpdatedYN = 'N'
				where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and
					m.ActiveYN = 'Y' and i.EDLType <> 'E'

				--Update Earnings Codes
				update dbo.HRBE
				set RateAmount = i.NewRate, ReadyYN = 'Y'
				from dbo.HREB b
				join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
				left join dbo.HRBE e on b.HRCo = e.HRCo and b.HRRef = e.HRRef and 
					b.BenefitCode = e.BenefitCode and b.DependentSeq = e.DependentSeq
				left join dbo.HRBI i on e.HRCo = i.HRCo and e.BenefitCode = i.BenefitCode and
					e.BenefitOption = i.BenefitOption and e.EarnCode = i.EDLCode and i.UpdatedYN = 'N'
				where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and 
					m.ActiveYN = 'Y' and i.EDLType = 'E'
			end
		end

		update dbo.HRBI set UpdatedYN = 'Y' where HRCo = @hrco and BenefitCode = @benefitcode
	end
	else
	begin
		if @matchratesyn = 'N'
			--Update only matching rates
		begin

			--Update Deductions and Liabilities
			update dbo.HRBL
			set RateAmt =  case when (i.OldRate = 0 and i.NewRate = 0) then l.RateAmt else
				(case b.ActiveYN when 'Y' then 
				(case i.UpdatedYN when 'Y' then i.NewRate else i.OldRate end) end) end,
			OverrideCalc = case when (i.OldRate = 0 and i.NewRate = 0) then l.OverrideCalc else 'R' end, 
			ReadyYN = 'Y'
			from dbo.HREB b
			join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
			left join dbo.HRBL l on b.HRCo = l.HRCo and b.HRRef = l.HRRef and 
			b.BenefitCode = l.BenefitCode and b.DependentSeq = l.DependentSeq
			left join dbo.HRBI i on l.HRCo = i.HRCo and l.BenefitCode = i.BenefitCode and 
			l.BenefitOption = i.BenefitOption  and l.DLType = i.EDLType and l.DLCode = i.EDLCode 
			/*and l.RateAmt = i.OldRate and i.UpdatedYN = 'N'*/
			where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and i.EDLType <> 'E' 
			and b.HRRef = @hrref

			--Update Earnings Codes
			update dbo.HRBE
			set RateAmount = case b.ActiveYN when 'Y' then
			(case i.UpdatedYN when 'Y' then i.NewRate else i.OldRate end) end, ReadyYN = 'Y'
			from dbo.HREB b
			join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
			left join dbo.HRBE e on b.HRCo = e.HRCo and b.HRRef = e.HRRef and 
			b.BenefitCode = e.BenefitCode and b.DependentSeq = e.DependentSeq
			left join dbo.HRBI i on e.HRCo = i.HRCo and e.BenefitCode = i.BenefitCode and
			e.BenefitOption = i.BenefitOption and e.EarnCode = i.EDLCode /*and e.RateAmount = i.OldRate 
			and i.UpdatedYN = 'N'*/
			where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and i.EDLType = 'E'
			and b.HRRef = @hrref
		end
--		else --@matchratesyn = 'N'
--		--Update all rates
--		begin
--			--Update Deductions and Liabilities
--			update dbo.HRBL
--			set RateAmt = case when (i.OldRate = 0 and i.NewRate = 0) then l.RateAmt else i.NewRate end, 
--			OverrideCalc = case when (i.OldRate = 0 and i.NewRate = 0) then l.OverrideCalc else 'R' end, 
--			ReadyYN = 'Y'
--			from dbo.HREB b
--			join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
--			left join dbo.HRBL l on b.HRCo = l.HRCo and b.HRRef = l.HRRef and 
--			b.BenefitCode = l.BenefitCode and b.DependentSeq = l.DependentSeq
--			left join dbo.HRBI i on l.HRCo = i.HRCo and l.BenefitCode = i.BenefitCode and 
--			l.BenefitOption = i.BenefitOption and l.DLType = i.EDLType and l.DLCode = i.EDLCode
--			and i.UpdatedYN = 'N'
--			where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and i.EDLType <> 'E'
--			and b.HRRef = @hrref
--
--			--Update Earnings Codes
--			update dbo.HRBE
--			set RateAmount = i.NewRate, ReadyYN = 'Y'
--			from dbo.HREB b
--			join dbo.HRRM m on b.HRCo = m.HRCo and b.HRRef = m.HRRef
--			left join dbo.HRBE e on b.HRCo = e.HRCo and b.HRRef = e.HRRef and 
--			b.BenefitCode = e.BenefitCode and b.DependentSeq = e.DependentSeq
--			left join dbo.HRBI i on e.HRCo = i.HRCo and e.BenefitCode = i.BenefitCode and
--			e.BenefitOption = i.BenefitOption and e.EarnCode = i.EDLCode
--			and i.UpdatedYN = 'N'
--			where b.HRCo = @hrco and b.BenefitCode = @benefitcode and b.DependentSeq = 0 and i.EDLType = 'E'
--			and b.HRRef = @hrref
--		end
	end

 
	vspexit:

	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspHRBenefitCodeUpdate] TO [public]
GO
