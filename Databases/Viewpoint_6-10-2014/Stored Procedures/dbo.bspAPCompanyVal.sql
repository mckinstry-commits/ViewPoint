SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPCompanyVal    Script Date: 8/28/99 9:33:57 AM ******/
   CREATE  Procedure [dbo].[bspAPCompanyVal]
   /***********************************************************
    * CREATED BY: KF 3/6/97
    * MODIFIED By : KF 3/6/97
    *              kb 10/28/2 - issue #18878 - fix double quotes
    *
    * USAGE:
    * validates AP Company number
    * 
    * INPUT PARAMETERS
    *   APCo   AP Co to Validate  
   
   
    * OUTPUT PARAMETERS
    *   @msg If Error, error message, otherwise description of Company
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/ 
   	(@apco bCompany = 0, @msg varchar(60)=null output)
   as
   
   set nocount on
   
   
   declare @rcode int
   select @rcode = 0
   	
   if @apco = 0
   	begin
   	select @msg = 'Missing AP Company#', @rcode = 1
   	goto bspexit
   	end
   
   if exists(select * from APCO where @apco = APCo)
   	begin
   	select @msg = 'Not on file!'
   	select @msg = Name from bHQCO where HQCo = @apco
   	goto bspexit
   	end
   else
   	begin
   	select @msg = 'Not a valid AP company ', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCompanyVal] TO [public]
GO
