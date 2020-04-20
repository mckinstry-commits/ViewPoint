SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspJCSIRegionCodeVal]
   /*************************************
   * Created By:   Unknown
   * Modified By:  GF 07/03/2001 - Use AddJCSICode flag from JCCO
   *				TV - 23061 added isnulls
   * validates JC SI Region and SI Code
   *
   * Pass:
   *	JC SI Region and SI Code to be validated
   *
   * Success returns:
   *	0 and Group Description from bJCSI
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@jcco bCompany, @region char(6) = null, @code char(16) = null, @um bUM output, @mum bUM output,
    @desc bItemDesc = null output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @addjcsicode bYN
   
   select @rcode = 0, @um = null, @mum=null, @addjcsicode = 'N'
   
   if @region is null
   	begin
   	select @msg = 'Missing JC SI Region', @rcode = 1
   	goto bspexit
   	end
   
   if @code is null
   	begin
   	select @msg = 'Missing JC SI Code', @rcode = 1
   	goto bspexit
   	end
   
   -- read flag from JCCO
   select @addjcsicode=AddJCSICode
   from bJCCO where JCCo=@jcco
   
select @desc=Description, @msg = Description, @um=UM, @mum=MUM
from bJCSI
where SIRegion = @region and SICode = @code
   if @@rowcount = 0
       begin
       if @addjcsicode <> 'Y'
           begin
           select @msg = 'Not a valid Std Item Code.', @rcode = 1
           goto bspexit
           end
       else
           begin
           select @msg = 'New Std Item Code', @um = null, @mum = null
           end
       end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCSIRegionCodeVal] TO [public]
GO
