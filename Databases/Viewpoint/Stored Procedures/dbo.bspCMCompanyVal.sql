SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMCompanyVal    Script Date: 8/28/99 9:34:16 AM ******/
   CREATE  proc [dbo].[bspCMCompanyVal]
   /***********************************************************
    * CREATED BY: SE   8/20/96
    * MODIFIED By : SE 8/20/96
    *
    * USAGE:
    * validates CM Company number
    * 
    * INPUT PARAMETERS
    *   CMCo   CM Co to Valideat  
    * OUTPUT PARAMETERS
    *   @msg If Error, error message, otherwise description of Company
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/ 
   	(@cmco bCompany = 0, @msg varchar(60) output)
   as
   
   set nocount on
   
   
   declare @rcode int
   select @rcode = 0
   	
   if @cmco = 0
   	begin
   	select @msg = 'Missing CM Company#', @rcode = 1
   	goto bspexit
   	end
   
   if exists(select * from CMCO where @cmco = CMCo)
   	begin
   	select @msg = Name from bHQCO where HQCo = @cmco
   	goto bspexit
   	end
   else
   	begin
   	select @msg = 'Not a valid CM Company', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMCompanyVal] TO [public]
GO
