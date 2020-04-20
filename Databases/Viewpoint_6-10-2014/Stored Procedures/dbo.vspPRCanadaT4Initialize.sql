SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspPRCanadaT4Initialize]
	/******************************************************
	* CREATED BY:	markh 
	* MODIFIED By:	AR 11/29/2010 - #142278 - removing old style joins replace with ANSI correct form
	*				MV	12/28/11 - TK-11180 init from master list even when itializing from previous year.
	*
	* Usage:  Initializes current year T4.  Can initialize from a prior year or from
	*		  the master list in PRCAItems and PRCACodes
	*
	*	
	*
	* Input params:
	*
	*	@prco -		PR Company
	*	@taxyear -	Tax Year
	*	@reinit -	Reinitialize (overrite) a current year.  The "do over" parameter.
	*	@useprev -	Use previous years mappings.  If Y and there is no previous year will
	*				use master list.
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @taxyear char(4), @reinit bYN, @useprev char(1), @msg varchar(250) output)
	as 
	set nocount on
	declare @rcode int, @prevtaxyear smallint
   	
	select @rcode = 0

	--Check PRCAItems to see if current year exists.  If not, build the list.  Use either 
	--previous years list or create a new list from scratch.
	if isnumeric(@taxyear) = 1
	begin

		if @reinit = 'N'
		begin
			if exists(select 1 from PRCAEmployerItems where PRCo = @prco and TaxYear = @taxyear)
			begin
				select @msg = 'T4 has already been initialized for the current tax year.  Proceeding will overwrite current tax year T4 data.', @rcode = 7
				goto vspexit
			end
		end

		--Make sure tables are clear
		delete PRCAEmployeeProvince where PRCo = @prco and TaxYear = @taxyear
		delete PRCAEmployeeCodes where PRCo = @prco and TaxYear = @taxyear
		delete PRCAEmployeeItems where PRCo = @prco and TaxYear = @taxyear
		delete PRCAEmployees where PRCo = @prco and TaxYear = @taxyear
		delete PRCAEmployerProvince where PRCo = @prco and TaxYear = @taxyear
		delete PRCAEmployerCodes where PRCo = @prco and TaxYear = @taxyear
		delete PRCAEmployerItems where PRCo = @prco and TaxYear = @taxyear
		delete PRCAItems where PRCo = @prco and TaxYear = @taxyear
		delete PRCACodes where PRCo = @prco and TaxYear = @taxyear


		if @useprev = 'Y'
		begin
		--	select @prevtaxyear = max(isnull(TaxYear,0)) from PRCAItems (nolock) where PRCo = @prco
		--	if not exists(select 1 from PRCAItems (nolock) where PRCo = @prco and TaxYear = @taxyear)
		--	begin
		--		if exists(select 1 from PRCAItems (nolock) where PRCo = @prco and TaxYear = @prevtaxyear)
		--		begin
		--			insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
		--			select PRCo, @taxyear, T4BoxNumber, T4BoxDescription, AmtType
		--			from PRCAItems (nolock) where PRCo = @prco and TaxYear = @prevtaxyear

		--			insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
		--			select PRCo, @taxyear, T4CodeNumber, T4CodeDescription, AmtType
		--			from PRCACodes (nolock) where PRCo = @prco and TaxYear = @prevtaxyear
		--		end
		--		else
		--		begin
		--		end
		--	end	
		--end
		--else
		--begin
			--	 PRCAItems and PRCACodes are used for F4 lookups and validation.  Initialize them against the master list
			exec vspPRCanadaT4BoxCodeInit @prco, @taxyear
		end

		if @useprev = 'Y'
		begin
		--	if not exists(select 1 from PRCAEmployerItems (nolock) where PRCo = @prco and TaxYear = @taxyear)
		--	begin
		--		if exists(select 1 from PRCAEmployerItems (nolock) where PRCo = @prco and TaxYear = @prevtaxyear)
		--		begin	
		--			select PRCo, TaxYear, T4BoxNumber, T4BoxNumberSeq, EDLType, EDLCode
		--			from PRCAEmployerItems (nolock) where PRCo = @prco and TaxYear = @prevtaxyear

		--			insert PRCAEmployerItems(PRCo, TaxYear, T4BoxNumber, T4BoxNumberSeq, EDLType, EDLCode)
		--			select PRCo, @taxyear, T4BoxNumber, T4BoxNumberSeq, EDLType, EDLCode
		--			from PRCAEmployerItems (nolock) where PRCo = @prco and TaxYear = @prevtaxyear
		--		end
		--		else
		--		begin
		--			insert PRCAEmployerItems(PRCo, TaxYear, T4BoxNumber, T4BoxNumberSeq)
		--			select PRCo, @taxyear, T4BoxNumber, 1
		--			from PRCAItems (nolock) where PRCo = @prco and TaxYear = @taxyear
		--		end
		--	end
		--end
		--else
		--begin
			insert PRCAEmployerItems(PRCo, TaxYear, T4BoxNumber, T4BoxNumberSeq)
			select PRCo, @taxyear, T4BoxNumber, 1
			from PRCAItems (nolock) where PRCo = @prco and TaxYear = @taxyear
		end

		if @useprev = 'Y'
		begin
		--	if not exists(select 1 from PRCAEmployerCodes (nolock) where PRCo = @prco and TaxYear = @taxyear)
		--	begin
		--		if exists(select 1 from PRCAEmployerCodes (nolock) where PRCo = @prco and TaxYear = @prevtaxyear)
		--		begin	
		--			insert PRCAEmployerCodes(PRCo, TaxYear, T4CodeNumber, T4CodeNumberSeq, EDLType, EDLCode)
		--			select PRCo, @taxyear, T4CodeNumber, T4CodeNumberSeq, EDLType, EDLCode
		--			from PRCAEmployerCodes (nolock) where PRCo = @prco and TaxYear = @prevtaxyear
		--		end
		--		else
		--		begin
		--			insert PRCAEmployerCodes(PRCo, TaxYear, T4CodeNumber, T4CodeNumberSeq)
		--			select PRCo, @taxyear, T4CodeNumber, 1
		--			from PRCACodes (nolock) where PRCo = @prco and TaxYear = @taxyear
		--		end
		--	end
		--end
		--else
		--begin
			insert PRCAEmployerCodes(PRCo, TaxYear, T4CodeNumber, T4CodeNumberSeq)
			select PRCo, @taxyear, T4CodeNumber, 1
			from PRCACodes (nolock) where PRCo = @prco and TaxYear = @taxyear
		end
	end

	--Create Province List
		
	INSERT    dbo.PRCAEmployerProvince
            ( PRCo,
              TaxYear,
              Province,
              DednCode,
              [Description],
              Initialize,
              Country
            )
            --#142278
            SELECT  i.PRCo,
                    TaxYear = @taxyear,
                    i.[State],
                    DednCode = i.TaxDedn,
                    d.[Description],
                    'Y',
                    'CA'
            FROM    dbo.PRSI i
						JOIN dbo.PRDL d ON d.PRCo = i.PRCo
										AND d.DLCode = i.TaxDedn
            WHERE   i.PRCo = @prco
                    AND i.TaxDedn IS NOT NULL
                     
                    
--		union  Canada does not have locals
--		select i.PRCo, TaxYear=@taxyear, i.State, DednCode=i.TaxDedn, d.Description, 'Y'
--		from PRLI i, PRDL d
--		where i.PRCo = @prco and i.TaxDedn is not null and d.PRCo = i.PRCo and d.DLCode = i.TaxDedn

	vspexit:

	return @rcode


GRANT EXECUTE ON vspPRCanadaT4Initialize TO public;
GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4Initialize] TO [public]
GO
