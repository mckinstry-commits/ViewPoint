SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspbspINMBTotalGet    Script Date: 3/18/2005  ******/
   CREATE     proc [dbo].[bspINMBTotalGet]
   /********************************************************
   * CREATED BY: 	TerryLis  3/18/05  'Issue 23839
   *
   * USAGE:
   * 	Called by MO Entry form to find the total current cost for a MO.  
   *	Pulls amounts from Items not currently in a Batch, plus amounts from
   *	new and changed Items in a Batch.
   *
   * INPUT PARAMETERS:
   *	@inco		IN Company #
   *	@mo		Material Order
   *
   * OUTPUT PARAMETERS:
   *	@amount	Total current amount for the MO
   *	@msg		Error message 
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 		Failure
   *
   **********************************************************/
   	(@inco  bCompany, @mo bMO, @amount decimal(18,2) output, @msg varchar(60) output)
   as
   	
   set nocount on
   	
declare @rcode int  , @amount1 decimal(18,2), @amount2 decimal(18,2)
     
   select @rcode = 0, @amount1 = 0, @amount2=0
   
   if @inco is null
   	begin
   	select @msg = 'Missing IN Company', @rcode = 1
   	goto bspexit
   	end

   if @mo is null
   	begin
   	select @msg = 'Missing MO#', @rcode = 1
   	goto bspexit
   	end
   
   select @amount = 0

Begin   
   -- total Current Cost of Items not in a Batch
	select @amount2 = isnull(sum(TotalPrice),0)
	from dbo.bINMI
	where INCo = @inco and MO = @mo and InUseMth is null and InUseBatchId is null	
  End

Begin
	-- add in amounts from 'add' or 'change' Items in a Batch, exclude 'delete' Items
	select @amount1 =isnull(sum(TotalPrice),0)
   from dbo.bINMB h
   join dbo.bINIB b on h.Co=b.Co and h.Mth=b.Mth and h.BatchId=b.BatchId and h.BatchSeq=b.BatchSeq
   where h.Co = @inco and h.MO = @mo and b.BatchTransType in ('A','C')
End

Begin
   select @amount = @amount1 + @amount2
End
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMBTotalGet] TO [public]
GO
