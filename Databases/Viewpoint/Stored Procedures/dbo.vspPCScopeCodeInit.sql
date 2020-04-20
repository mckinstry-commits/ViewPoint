SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE proc [dbo].[vspPCScopeCodeInit]
   
   /***********************************************************
    * CREATED BY:	GP	03/22/2010 - Issue #129020
    * MODIFIED BY:	
    *
    * USAGE:
    * Return dataset to fill list view in PCScopeCodesInitialize
    *
    *
    * INPUT PARAMETERS
    *	@PCCo
    *	@VendorGroup
    *   @Scope
    *	@PhaseList
    *
    * OUTPUT PARAMETERS
    *	Dataset containing Phases and Descriptions.
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure or nothing to format
    *****************************************************/
   (@PCCo bCompany = null, @VendorGroup bGroup = null, @Scope varchar(10) = null, @PhaseList varchar(max), 
	@msg varchar(255) output)
   as
   set nocount on

	declare @rcode tinyint, @PhaseGroup bGroup, @PhaseListEdit varchar(max), @CurrPhase bPhase, @ValidPhase bYN,
		@DisplayPhaseError bYN
	select @rcode = 0, @PhaseListEdit = @PhaseList, @ValidPhase = 'N', @DisplayPhaseError = 'N'

	if @PCCo is null
	begin
		select @msg = 'PC Company missing, cannot add.', @rcode = 1
		goto vspexit
	end

	if @VendorGroup is null
	begin
		select @msg = 'Vendor Group missing, cannot add.', @rcode = 1
		goto vspexit
	end
	
	if @Scope is null
	begin
		select @msg = 'Scope missing, cannot add.', @rcode = 1
		goto vspexit
	end
	
	if isnull(@PhaseList,'') = ''
	begin
		select @msg = 'Phase List missing, cannot add.', @rcode = 1
		goto vspexit
	end	


	--get phase group
	select @PhaseGroup = PhaseGroup from dbo.HQCO with (nolock) where HQCo=@PCCo

	--if blank set to null, loop through list until null
	if @PhaseListEdit = '' set @PhaseListEdit = null
	while @PhaseListEdit is not null
	begin
		--if contains delimiter, else assumes last phase
		if charindex('|', @PhaseListEdit) <> 0
		begin
			select @CurrPhase = substring(@PhaseListEdit, 1, charindex('|', @PhaseListEdit) - 1)
		end	
		else
		begin
			select @CurrPhase = @PhaseListEdit, @PhaseListEdit = null
			if @CurrPhase = '' goto vspexit
		end		

		--shorten phase list, minus currphase
		select @PhaseListEdit = substring(@PhaseListEdit, charindex('|', @PhaseListEdit) + 1, len(@PhaseListEdit))
		
		--validate phase against bJCPM
		if exists(select top 1 1 from dbo.JCPM with (nolock) where PhaseGroup=@PhaseGroup and Phase=@CurrPhase) 
			set @ValidPhase = 'Y' else set @ValidPhase = 'N'
			
		--ensure phase does not currently exist in vPCScopePhases
		if not exists(select top 1 1 from dbo.PCScopePhases with (nolock) where PhaseGroup=@PhaseGroup and Phase=@CurrPhase and VendorGroup=@VendorGroup)
			set @ValidPhase = 'Y' else set @ValidPhase = 'N'

		--if phase is valid perform insert, else set error message flag
		if @ValidPhase = 'Y'
		begin
			insert dbo.vPCScopePhases(VendorGroup, ScopeCode, PhaseGroup, Phase)
			values(@VendorGroup, @Scope, @PhaseGroup, @CurrPhase)
		end
		else
		begin
			set @DisplayPhaseError = 'Y'
		end
		
		set @ValidPhase = ''
	end --end while loop
	
	--display error if phases skipped
	if @DisplayPhaseError = 'Y'
	begin
		select @msg = 'Some of the phases selected do not exist in JC Phase Master or are already in PC Scope Phases and were not added.'
		goto vspexit
	end
	
	

	vspexit:
		return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPCScopeCodeInit] TO [public]
GO
