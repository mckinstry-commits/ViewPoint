SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPInPayControlFlagSet    Script Date: 8/28/99 9:34:00 AM ******/
   CREATE procedure [dbo].[bspAPInPayControlFlagSet]
   
      
   /***********************************************************
    * CREATED BY: EN 10/23/97
    * MODIFIED By : EN 10/23/97
    *              kb 10/28/2 - issue #18878 - fix double quotes
    *
    * USAGE:
    * This procedure sets the InPayControl flag in APTH to the value 
    * specified in the input parameters.
    * 
    *  INPUT PARAMETERS
    *   @apco	AP company number
    *   @mth	expense month
    *   @aptrans	transaction number  
    *   @flag	value to set the InPayControl flag to
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs 
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
   *******************************************************************/ 
   (@apco bCompany, @mth bMonth, @aptrans bTrans, @flag bYN, 
   	@msg varchar(90) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode=0
   
   
   update bAPTH
   	set InPayControl=@flag from bAPTH 
   	where APCo=@apco and Mth=@mth and APTrans=@aptrans
   if @@rowcount = 0
   	select @msg = 'Invalid Transaction!', @rcode = 1
   	
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPInPayControlFlagSet] TO [public]
GO
