SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPCScopePhaseInitFill]
/***********************************************************
* CREATED BY:	CHS	03/23/2010 - Issue #129020
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
*
* OUTPUT PARAMETERS
*	Dataset containing Phases and Descriptions.
*
* RETURN VALUE
*   0         Success
*   1         Failure or nothing to format
*****************************************************/
(@PCCo bCompany = null, 
	@VendorGroup bGroup = null, 
	@PotentialProject varchar(20) = null, 
	@BidPackage varchar(20) = null, 
	@Scope varchar(10) = null, 
	@msg varchar(255) output)
	
	
   as
   set nocount on
   
	declare @rcode tinyint, @PhaseGroup bGroup
	select @rcode = 0



	if @PCCo is null
	begin
		select @msg = 'PC Company missing, cannot fill Phase list view.', @rcode = 1
		goto vspexit
	end

	if @VendorGroup is null
	begin
		select @msg = 'Vendor Group missing, cannot fill Phase list view.', @rcode = 1
		goto vspexit
	end
	


	-- get phase group
	select @PhaseGroup = PhaseGroup from dbo.HQCO with (nolock) where HQCo=@PCCo
	
	---- get scope code phases
	select
		s.ScopeCode as [Scope], 
		c.Description as [ScopeDesc], 
		p.Phase as [Phase], 
		p.Description as [PhaseDesc]
	
	from dbo.JCPM p with (nolock)
		left join dbo.PCScopePhases s with (nolock) on @PhaseGroup = s.PhaseGroup and p.Phase = s.Phase
		left join dbo.PCScopeCodes c with (nolock) on s.VendorGroup = c.VendorGroup and s.ScopeCode = c.ScopeCode 
		
	where 
		((@Scope is not null and @Scope = s.ScopeCode) or (@Scope is null))
		and @PhaseGroup = p.PhaseGroup
		and not exists(select top 1 1 from dbo.PCBidPackageScopes b where @PCCo = b.JCCo 
								and @PotentialProject = b.PotentialProject 
								and @BidPackage = b.BidPackage 
								and @VendorGroup = b.VendorGroup 
								and @PhaseGroup = b.PhaseGroup
								and ((s.Phase is not null and b.Phase = s.Phase) or (s.Phase is null and b.ScopeCode = s.ScopeCode)))
	
	Union
	
	select
		ss.ScopeCode as [Scope], 
		ss.Description as [ScopeDesc], 
		null as [Phase], 
		null as [PhaseDesc]
		
	from dbo.PCScopeCodes ss (nolock)
	
	where 
		ss.ScopeCode = isnull(@Scope, ss.ScopeCode)
		and not exists(select top 1 1 from dbo.PCBidPackageScopes b where @PCCo = b.JCCo 
						and @PotentialProject = b.PotentialProject 
						and @BidPackage = b.BidPackage 
						and @VendorGroup = b.VendorGroup 
						and @PhaseGroup = b.PhaseGroup
						and b.Phase is null 
						and b.ScopeCode = ss.ScopeCode)
	
	order by Scope, Phase



	vspexit:
		select @rcode as [rcode], @msg as [msg]

GO
GRANT EXECUTE ON  [dbo].[vspPCScopePhaseInitFill] TO [public]
GO
