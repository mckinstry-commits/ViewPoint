SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPCScopePhaseInit]   
/***********************************************************
* CREATED BY:	CHS	03/24/2010 - Issue #129020
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
(@PCCo bCompany = null, 
	@PotentialProject varchar(20) = null, 
	@BidPackage varchar(20) = null, 
	@VendorGroup bGroup = null, 
	@PhaseGroup bGroup = null, 
	@Scope varchar(10) = null, 
	@Phase bPhase = null, 
	@msg varchar(255) output)
	
   as
   set nocount on

	declare @rcode tinyint, @Seq int
	select @rcode = 0

	if @PCCo is null
		begin
		select @msg = 'PC Company missing, cannot initialize.', @rcode = 1
		goto vspexit
		end

	if @PCCo is null
		begin
		select @msg = 'PC Company missing, cannot initialize.', @rcode = 1
		goto vspexit
		end

	if @PCCo is null
		begin
		select @msg = 'PC Company missing, cannot initialize.', @rcode = 1
		goto vspexit
		end

	if @VendorGroup is null
		begin
		select @msg = 'Vendor Group missing, cannot initialize.', @rcode = 1
		goto vspexit
		end

	if @Scope is null and @Phase is null
		begin
		select @msg = 'Scope and Phase missing, cannot initialize.', @rcode = 1
		goto vspexit
		end

	if @Scope = '' set @Scope = null
	if @Phase = '' set @Phase = null

	-- get next Seq value
	select @Seq = 1 + isnull(max(Seq),0) from dbo.vPCBidPackageScopes with (nolock) 	
	where JCCo = @PCCo and PotentialProject = @PotentialProject and BidPackage = @BidPackage
	
	-- insert new record
	insert dbo.vPCBidPackageScopes(JCCo, PotentialProject, BidPackage, Seq, VendorGroup, ScopeCode, PhaseGroup, Phase)
	values (@PCCo, @PotentialProject, @BidPackage, @Seq, @VendorGroup, @Scope, @PhaseGroup, @Phase)
	


	vspexit:
		return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPCScopePhaseInit] TO [public]
GO
