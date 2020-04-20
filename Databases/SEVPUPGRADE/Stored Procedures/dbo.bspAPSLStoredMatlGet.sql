SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPSLStoredMatlGet]
   /***********************************************************
    * CREATED BY	: MV 03/16/04
    * MODIFIED BY	:	GP 6/28/10 - #135813 change bSL to varchar(30)  
    *                
    *              
    *
    * USAGE:
    * Called by AP Invoice Program to return Stored Material from Subcontract Item
    *
    * INPUT PARAMETERS
    *   @slco              SL Co# - this is the same as the AP Co
    *   @sl                Subcontract
    *   @slitem            SL Item#
    *
    * OUTPUT PARAMETERS
    *   @storedmatls       Stored Materials
    *   @msg               error message
    *
    * RETURN
    *   0 = success, 1 = error
    ******************************************************/
       (@slco bCompany = 0, @sl varchar(30) = null, @slitem bItem=null, @storedmatls bDollar output,@msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- get Item information from bSLIT
   select @storedmatls = StoredMatls
   from SLIT
   where SLCo=@slco and SL=@sl and SLItem=@slitem
   if @@rowcount=0
   	begin
   	select @msg = 'Invalid SL Item!', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPSLStoredMatlGet] TO [public]
GO
