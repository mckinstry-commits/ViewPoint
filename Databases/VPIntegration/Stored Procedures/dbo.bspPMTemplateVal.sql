SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMTemplateVal    Script Date: 8/28/99 9:33:07 AM ******/
   
   CREATE  proc [dbo].[bspPMTemplateVal]
    	(@pmco bCompany = 0, @template varchar(10) = null, @msg varchar(60) output)
    as
    set nocount on
    /***********************************************************
     * CREATED BY: GR 7/15/99
     * MODIFIED By :
     *
     * USAGE:
     * validates Templates from bPMTH
     * and returns the description
     * an error is returned if company and template not passed
     *
     * INPUT PARAMETERS
     *   PMCo   		PM Co to validate against
     *   Template    	Template to validate
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs otherwise Description of Project
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
    	declare @rcode int
   
    	select @rcode = 0
    if @pmco is null
    	begin
    	select @msg = 'Missing PM Company!', @rcode = 1
    	goto bspexit
    	end
    if @template is null
    	begin
    	select @msg = 'Missing Template!', @rcode = 1
   
    	goto bspexit
    	end
    select @msg = Description
    	   from PMTH
    	   where PMCo=@pmco and Template=@template
    if @@rowcount = 0
       begin
          select @msg = 'Template not on file!', @rcode = 1
          goto bspexit
       end
    
    bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMTemplateVal] TO [public]
GO
