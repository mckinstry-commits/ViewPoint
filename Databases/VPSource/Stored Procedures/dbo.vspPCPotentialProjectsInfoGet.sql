SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspPCPotentialProjectsInfoGet]
/*************************************
*  Created:		JVH	12/10/2008
*	Modified:	GP	01/10/2010 - needed Customer Group for PCPotentialProjectTeam
*				GP	12/02/2010 - needed PM Subcontract Cost Type for PCPotentialProjectsCreatePM (sub detail)
*
*  PC Information returned
*
*  Inputs:
*	 @company:		PC Company (Actually Menu Company which is HQCo)
*
*  Outputs:
*	 @vendorgroup:	Vendor Group from HQCo
*
* Error returns:
*	0 and PC Common information
*	1 and error message
**************************************/
	(@company bCompany, 
	@GLCo bCompany = NULL OUTPUT, 
	@vendorgroup bGroup = NULL OUTPUT,
	@phaseGroup bGroup = NULL OUTPUT,
	@CustomerGroup bGroup = NULL OUTPUT,
	@PMSubcontractCT bJCCType = NULL OUTPUT,
	@msg VARCHAR(255) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode INT, @ARCo bCompany
	SET @rcode = 0

	IF @company is null
	BEGIN
		SELECT @msg = 'Missing PC Company.', @rcode = 1
		GOTO vspexit
	END
	
	/* Get GL Common information */
	SELECT @GLCo = GLCo
		FROM APCO NOLOCK
		WHERE APCo = @company
	
	/* Get PC Common information */
	SELECT  @vendorgroup = VendorGroup, @phaseGroup = PhaseGroup
		FROM bHQCO (NOLOCK)
		WHERE HQCo = @company
	
	IF @vendorgroup IS NULL OR @phaseGroup IS NULL
	BEGIN
		SELECT @msg = 'Error getting PC Common information.', @rcode = 1
	END
	
	--Get ARCo to get CustomerGroup
	select @ARCo = ARCo from dbo.bJCCO with (nolock) where JCCo=@company
	if @ARCo is not null
	begin
		select @CustomerGroup = CustGroup from dbo.bHQCO with (nolock) where HQCo=@ARCo
	end
	
	--Get default Subcontract Cost Type from PM Company Parameters
	select @PMSubcontractCT = SLCostType from dbo.bPMCO where PMCo = @company
	if @PMSubcontractCT is null select @PMSubcontractCT = SLCostType2 from dbo.bPMCO where PMCo = @company
	
	
vspexit:
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspPCPotentialProjectsInfoGet] TO [public]
GO
