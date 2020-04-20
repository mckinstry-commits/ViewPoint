SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCompanyVal    Script Date: 8/28/99 9:34:25 AM ******/
   CREATE   proc [dbo].[bspEMCompanyVal]
   /***********************************************************
    * CREATED BY: bc 12/7/98
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *				MV 04/12/06 - APCompany 6X recode-change err msg
    *
    * USAGE:
    * validates EM Company number
    *
    * INPUT PARAMETERS
    *   EMCo   EM Co to Validate
    * OUTPUT PARAMETERS
    *   @msg If Error, error message, otherwise description of Company
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   	(@emco bCompany = 0, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @emco = 0
   	begin
   	select @msg = 'Missing EM Company#', @rcode = 1
   	goto bspexit
   	end
   
   if exists(select * from EMCO where @emco = EMCo)
   	begin
   	select @msg = Name from bHQCO where HQCo = @emco
   	goto bspexit
   	end
   else
   	begin
   	select @msg = 'Not a valid EM Company', @rcode = 1
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCompanyVal] TO [public]
GO
