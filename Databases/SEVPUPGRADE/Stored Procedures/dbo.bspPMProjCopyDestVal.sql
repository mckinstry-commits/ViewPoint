SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspPMProjCopyDestVal]
/***********************************************************
* Created By:  GF 05/23/2001
* Modified By:  DC 4/11/03  - Added code to get CustGroup based on ARCo from HQCO
*				CHS 11/20/08 - #130774
*
* USAGE:
* validates destination projects are not in bJCJM and returns needed
* information for the PMProjectCopy form.
*
* INPUT PARAMETERS
*   PMCo   		PM Co to validate against
*   Project    	Project to validate
*
* OUTPUT PARAMETERS
*  @vendorgroup
*  @custgroup
*  @taxgroup
*  @phasegroup
*  @matlgroup
*  @prco
*  @msg            error message if error
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@pmco bCompany = 0, @project bJob = null, @vendorgroup bGroup output, @custgroup bGroup output,
@taxgroup bGroup output, @phasegroup bGroup output, @matlgroup bGroup output, @prco bCompany output,
@country varchar(60) output, @msg varchar(255) output)

   as
   set nocount on
   
   declare @rcode int, @apco bCompany, @validcnt int
   
   select @rcode = 0

	select @country = (select DefaultCountry from HQCO with (nolock) 
						left join PMCO with (nolock) on @pmco = PMCO.PMCo
	where HQCO.HQCo = isnull(PMCO.PRCo, @pmco))  

   
   if @pmco is null
       begin
    	select @msg = 'Missing PM Company!', @rcode = 1
    	goto bspexit
    	end
   
   select @apco=APCo, @prco=PRCo from bPMCO where PMCo=@pmco
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
   
   select @validcnt=count(*) from bJCJM where JCCo=@pmco and Job=@project
   if @validcnt <> 0
       begin
       select @msg = 'Invalid Project - must not be set up in JCJM!', @rcode = 1
       goto bspexit
       end
   
   --start: DC 4/11/03  issue 20818
   select @custgroup=h.CustGroup
   from bHQCO h JOIN bJCCO j ON (h.HQCo = j.ARCo)
   where j.JCCo = @pmco
   if @@rowcount <> 1
       begin
       select @msg='Invalid HQ Company ' + convert(varchar(3),@pmco) + '!', @rcode=1
       goto bspexit
       end
   --  End
   
   select @phasegroup=PhaseGroup, @matlgroup=MatlGroup, @taxgroup=TaxGroup
   from bHQCO where HQCo=@pmco
   if @@rowcount <> 1
       begin
       select @msg='Invalid HQ Company ' + convert(varchar(3),@pmco) + '!', @rcode=1
       goto bspexit
       end
   
   select @vendorgroup=VendorGroup from bHQCO where HQCo=@apco
   if @@rowcount <> 1
       begin
       select @msg='Missing vendor group for HQ Company ' + convert(varchar(3),@apco) + '!', @rcode = 1
       goto bspexit
       end
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg = isnull(@msg,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjCopyDestVal] TO [public]
GO
