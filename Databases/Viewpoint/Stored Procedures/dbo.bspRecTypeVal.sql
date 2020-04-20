SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRecTypeVal    Script Date: 8/28/99 9:35:45 AM ******/
   /****** Object:  Stored Procedure dbo.bspRecTypeVal    Script Date: 3/28/99 12:00:39 AM ******/
   CREATE   proc [dbo].[bspRecTypeVal]
   /* validates Receivable Type
    * pass in Co# and Receivable Type
    * returns Receivable Type description
   */
   	(@arco bCompany = 0, @rectype tinyint = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @arco = 0
   	begin
   	select @msg = 'Missing AR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @arco is null
   	begin
   	select @msg = 'Missing AR Account!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bARRT
   	where ARCo = @arco and RecType = @rectype
   if @@rowcount = 0
   	begin
   	select @msg = 'Receivable type not on file!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRecTypeVal] TO [public]
GO
