SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPMProjCopySrcVal]
   /***********************************************************
    * Created By:  GF 05/23/2001
    * Modified By:  DC 4/11/03 added code to get the CustGroup based on ARCo from HQCO
*					GF 03/12/2008 - issue #127076 changed state to varchar(4)
*
    *
    * USAGE:
    * validates source projects from bJCJM and returns needed
    * information for the PMProjectCopy form.
    *
    * INPUT PARAMETERS
    *   PMCo   		PM Co to validate against
    *   Project    	Project to validate
    *
    * OUTPUT PARAMETERS
    *  @liabtemplate   Default liability template
    *  @prstate        Default PR state code
    *  @vendorgroup
    *  @custgroup
    *  @taxgroup
    *  @phasegroup
    *  @matlgroup
    *  @prco
    *  @msg            error message if error occurs otherwise Description of Project
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@pmco bCompany = 0, @project bJob = null, @liabtemplate smallint output, @prstate varchar(4) output,
    @vendorgroup bGroup output, @custgroup bGroup output, @taxgroup bGroup output, @phasegroup bGroup output,
    @matlgroup bGroup output, @prco bCompany output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @apco bCompany
   
   select @rcode = 0
   
   if @pmco is null
       begin
    	select @msg = 'Missing PM Company!', @rcode = 1
    	goto bspexit
    	end
   
   select @apco=APCo, @prco=PRCo from bPMCO with (nolock) where PMCo=@pmco
   if @@rowcount <> 1
        begin
        select @msg = 'PM Company is Invalid ', @rcode=1
        goto bspexit
        end
   
   if @project is null
    	begin
    	select @msg = 'Missing project!', @rcode = 1
    	goto bspexit
    	end
   
   select @msg = Description, @liabtemplate = LiabTemplate, @prstate = PRStateCode
   from bJCJM with (nolock) where JCCo=@pmco and Job=@project
   if @@rowcount = 0
       begin
       select @msg = 'Project not on file!', @rcode = 1
       goto bspexit
       end
   
   -- start: DC 4/11/03  issue 20818
   select @custgroup=h.CustGroup
   from bHQCO h with (nolock) JOIN bJCCO j with (nolock) ON (h.HQCo = j.ARCo)
   where j.JCCo = @pmco
   if @@rowcount <> 1
       begin
       select @msg='Invalid HQ Company ' + convert(varchar(3),@pmco) + '!', @rcode=1
       goto bspexit
       end
   -- End
   
   select @phasegroup=PhaseGroup, @matlgroup=MatlGroup, @taxgroup=TaxGroup
   from bHQCO with (nolock) where HQCo=@pmco
   if @@rowcount <> 1
       begin
       select @msg='Invalid HQ Company ' + convert(varchar(3),@pmco) + '!', @rcode=1
       goto bspexit
       end
   
   select @vendorgroup=VendorGroup from bHQCO with (nolock) where HQCo=@apco
   if @@rowcount <> 1
       begin
       select @msg='Missing vendor group for HQ Company ' + convert(varchar(3),@apco) + '!', @rcode = 1
       goto bspexit
       end
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg = isnull(@msg,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjCopySrcVal] TO [public]
GO
