SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPMSubmitRevVal]
   /*******************************************************************************
   * Created By:	GF 04/13/2000
   * Modified By:
   *
   * Validates submittal revision and returns description. Used in PM Transmittal form.
   *
   *
   * Pass In
   *   PM Company, Project, DocType, Submittal, Revision
   *
   * RETURN PARAMS
   *   msg           Error Message, or description
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   ********************************************************************************/
   (@pmco bCompany = null, @project bJob = null, @doctype bDocType = null,
    @submittal bDocument = null, @revision int = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @codetype varchar(1)
   
   select @rcode=0
   
   if @pmco is null
       begin
       select @msg='Missing PM Company!', @rcode = 1
       goto bspexit
       end
   
   if @project is null
       begin
       select @msg='Missing Project!', @rcode = 1
       goto bspexit
       end
   
   if @doctype is null
       begin
       select @msg='Missing Document Type!', @rcode = 1
       goto bspexit
       end
   
   if @submittal is null
       begin
       select @msg='Missing Submittal!', @rcode = 1
       goto bspexit
       end
   
   select @msg=Description from bPMSM with (nolock) 
   where PMCo=@pmco and Project=@project and SubmittalType=@doctype and Submittal=@submittal and Rev=@revision
   if @@rowcount = 0
       begin
       select @msg='Revision not found!', @rcode = 1
       goto bspexit
       end
   
   
   bspexit:
       if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSubmitRevVal] TO [public]
GO
