SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************/
   CREATE  proc [dbo].[bspPMMaterialParamsGet]
   /********************************************************
    * CREATED BY:   GF 02/05/2002
    * MODIFIED BY:	GF 08/01/2003 - issue #21993 added JCCO.UseTaxOnMaterial to output params
    *					GF 08/20/2004 - issue #25482 added RQInUse to output params
    *
    * USAGE:
    * 	Retrieves PM company parameters, HQ company paramaters for PMCO.APCo
    *	for use in PM Material form.
    *
    * INPUT PARAMETERS:
    *	PM Company number
    *
    * OUTPUT PARAMETERS:
    *	APCO 			APCO from PMCO
    *	MtlCostType		Default material cost type from PMCO
    *
    *
    *
    *
    *	Error Message, if one
    *
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
    *
    **********************************************************/
   (@pmco bCompany = null, @apco bCompany output, @mtlcosttype bJCCType output, @phasegroup bGroup output,
    @vendorgroup bGroup output, @matlgroup bGroup output, @salestaxgroup bGroup output,
    @usetaxgroup bGroup output, @msinuse bYN output, @msco bCompany output, @ininuse bYN output, 
    @inco bCompany output, @inmatlgroup bGroup output, @msmatlgroup bGroup output, @usetaxonmaterial bYN output,
	@rqinuse bYN output,@msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0,  @usetaxonmaterial = 'N'
   
   if @pmco is null
   	begin
    	select @msg = 'Missing PM Company!', @rcode = 1
    	goto bspexit
    	end
   
   select @apco=APCo, @mtlcosttype=MtlCostType, @msinuse=MSInUse, @msco=MSCo, 
   		@ininuse=INInUse, @inco=INCo, @rqinuse=RQInUse
   from bPMCO with (nolock) where PMCo=@pmco
   if @@rowcount = 0
   	begin
   	select @msg = 'PM company does not exists!', @rcode=1
   	goto bspexit
   	end
   
   if isnull(@apco,0) = 0
   	begin
   	select @msg = 'AP company not setup for Company ' + convert(varchar(3), @pmco) + ' in PM!', @rcode=1
   	goto bspexit
   	end
   
   -- get UseTaxOnMaterial from bJCCO
   select @usetaxonmaterial = UseTaxOnMaterial from bJCCO with (nolock) where JCCo=@pmco
   if @@rowcount = 0 select @usetaxonmaterial = 'N'
   
   -- get PM groups from HQCO
   select @phasegroup=PhaseGroup, @vendorgroup=VendorGroup, @usetaxgroup=TaxGroup
   from bHQCO with (nolock) where HQCo=@pmco
   if @@rowcount = 0
   	begin
   	select @msg = 'Error retrieving groups from HQ for PM company', @rcode = 1
   	goto bspexit
   	end
   
   -- get AP groups from HQCO
   select @matlgroup=MatlGroup, @salestaxgroup=TaxGroup
   from bHQCO with (nolock) where HQCo=@apco
   if @@rowcount = 0
   	begin
   	select @msg = 'Error retrieving groups from HQ for AP company', @rcode = 1
   	goto bspexit
   	end
   
if isnull(@msco,0) <> 0
   	begin
   	select @msmatlgroup=MatlGroup from bHQCO with (nolock) where HQCo=@msco
   	end
   
if isnull(@inco,0) <> 0
   	begin
   	select @inmatlgroup=MatlGroup from bHQCO with (nolock) where HQCo=@inco
   	end


bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMaterialParamsGet] TO [public]
GO
