SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPMProjCopyDestCoVal]
   /*******************************************************************************
   * Created By:   GF 05/25/2001
   * Modified By:  GF 06/13/2001 - added ARCO output parameter
   * 		DC 4/11/03  - Added code to get CustGroup based on ARCo from HQCO
   *
   * Validates the destination PM company and returns needed company parameters.
   * Used in the PMProjectCopy form.
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * Pass In
   *	PMCo		    PM Company
   *
   * RETURN PARAMS
   *   VendorGroup
   *   CustGroup
   *   TaxGroup
   *   PhaseGroup
   *   MatlGroup
   *   ARCo
   *   msg           Error Message, or company name from HQCo
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   ********************************************************************************/
   (@pmco bCompany, @vendorgroup tinyint output, @custgroup tinyint output, @taxgroup tinyint output,
    @phasegroup tinyint output, @matlgroup tinyint output, @arco bCompany output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @apco bCompany
   
   select @rcode=0
   
   if @pmco is null
       begin
       select @msg = 'Missing destination PM company', @rcode = 1
       goto bspexit
       end
   
   select @apco=APCo from bPMCO with (nolock) where PMCo=@pmco
   if @@rowcount <> 1
        begin
        select @msg = 'PM Company is Invalid ', @rcode=1
        goto bspexit
        end
   
   -- get ARCo from JCCO
   select @arco=ARCo from bJCCO with (nolock) where JCCo=@pmco
   
   -- get CustGroup using ARCo   DC 4/11/03 issue 20818
   select @custgroup=CustGroup from bHQCO with (nolock) where HQCo=@arco
   
   select @msg=Name, @phasegroup=PhaseGroup, @matlgroup=MatlGroup, @taxgroup=TaxGroup
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
GRANT EXECUTE ON  [dbo].[bspPMProjCopyDestCoVal] TO [public]
GO
