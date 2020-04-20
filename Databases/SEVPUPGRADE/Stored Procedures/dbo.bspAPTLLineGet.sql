SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPTLLineGet    Script Date: 8/28/99 9:32:33 AM *****
   modified by: kb 10/29/2 - issue #18878 - fix double quotes
   
   *******************/
   CREATE proc [dbo].[bspAPTLLineGet]
   (@apco bCompany = 0, @mth bMonth = null, @aptrans bTrans = 0, @apline smallint = 0,
   @msg varchar(60) output)
   
   as 
   
   set nocount on
   declare @rcode int
   	
   if @apco = 0
   	begin
   	select @msg = 'Missing AP Company#', @rcode = 1
   	goto bspexit
   	end
   
   if @mth is null
   	begin
   	select @msg = 'Missing expense month', @rcode = 1
   	goto bspexit
   	end
   	
   if @aptrans = 0
   	begin
   	select @msg = 'Missing transaction #', @rcode = 1
   	goto bspexit
   	end
   	
   if @apline = 0
   	begin
   	select @msg = 'Missing line #', @rcode = 1
   	goto bspexit
   	end
   	
   select @msg=Description from APTL
   	where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@apline
   
   if @@rowcount = 1 
      select @rcode=0
   else
      select @msg='Line does not exist', @rcode=1
   
   
   	  
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPTLLineGet] TO [public]
GO
