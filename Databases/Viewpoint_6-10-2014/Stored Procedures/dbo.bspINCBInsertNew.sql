SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINCBInsertNew    Script Date: 12/29/2003 2:58:00 PM ******/
   
   
   CREATE   Proc [dbo].[bspINCBInsertNew]
   /****************************
   	Created: 05/02/02 RM
   	Modified:	
   		DC #23088 12/29/03 - Getting error & kicked out of VP if try to init without date
   	
   	Usage:
   		
   *****************************/
   (@co bCompany,@mo bMO,@moitem int,@batchmth bMonth,@batchid int,@confirmdate bDate,@confirmunits bUnits,
   @remainunits bUnits,@msg varchar(255) = null output)
   as
   
   declare @nextseq int,@matlgroup bGroup, @rcode int,@msgout varchar(255),
   @costmethod int,@category varchar(30),@stkum bUM,@loc bLoc,@material bMatl,
   @um bUM,@unitprice bUnitCost,@stkunitcost bUnitCost,@ecm bECM,@stkECM bECM,
   @convfactor bUnitCost
   
   
   Declare @currentremainunits bUnits
   
   --DC #23088  START
   if @confirmdate is null
       begin
       select @msg='Missing Confirmation Date', @rcode=1
       goto bspexit
       end
   
   if @co is null
       begin
       select @msg='Missing Company', @rcode=1
       goto bspexit
       end
   
   if @mo is null
       begin
       select @msg='Missing Material Order', @rcode=1
       goto bspexit
       end
   
   if @moitem is null
       begin
       select @msg='Missing Material Order Item', @rcode=1
       goto bspexit
       end
   
   if @batchmth is null
       begin
       select @msg='Missing Batch Month', @rcode=1
       goto bspexit
       end
   
   if @batchid is null
       begin
       select @msg='Missing Batch ID', @rcode=1
       goto bspexit
       end
   
   if @confirmunits is null
       begin
       select @msg='Missing Confirmation Units', @rcode=1
       goto bspexit
       end
   
   if @remainunits is null
       begin
       select @msg='Missing Remaining Units', @rcode=1
       goto bspexit
       end
   
   --DC #23088 END
   
   select @currentremainunits=sum(RemainUnits)
   from dbo.INCB with (nolock) where Co=@co and MO=@mo and MOItem=@moitem
   
   select @currentremainunits=isnull(@currentremainunits,0)+RemainUnits from dbo.INMI with(nolock)
   where INCo=@co and MO=@mo and MOItem=@moitem
   
   select @rcode = 0
   
   select @nextseq=isnull(Max(BatchSeq),0) + 1 from dbo.INCB with (nolock) where Co=@co and Mth=@batchmth and BatchId=@batchid
   
   select @matlgroup=MatlGroup from dbo.HQCO with (nolock) where HQCo=@co
   
   
   
   
   select @loc = Loc,@matlgroup=MatlGroup,@material=Material,@um=UM,
   @unitprice=UnitPrice,@ecm=ECM from dbo.INMI with(nolock)
   where INCo=@co and MO=@mo and MOItem=@moitem
   if @@rowcount=0
   begin
   	select @msg='MO Item does not exist.',@rcode = 1
   	goto bspexit
   end
   
   Select @stkum=StdUM,@category=Category from dbo.HQMT with (nolock)where MatlGroup=@matlgroup and Material = @material

   --Check IN Location Category Override for costmethod
   select @costmethod = IsNull(CostMethod,0) from dbo.INLO with (nolock) where INCo=@co and Loc=@loc and MatlGroup=@matlgroup and Category=@category
  --Check IN Location for cost methond
   if isnull(@costmethod,0) = 0
   begin
   		select @costmethod = CostMethod from dbo.INLM with (nolock) where INCo=@co and Loc=@loc	
   end
   --Check IN Company over ride if no cost override
   if isnull(@costmethod,0)=0
   begin
   	select @costmethod = CostMethod from dbo.INCO with (nolock) where INCo=@co
   end
   
   --Issue 126608
   select @stkunitcost=case @costmethod when 1 then IsNull(AvgCost,0) when 2 then IsNull(LastCost,0) when 3 then IsNull(StdCost,0) else 0 end,
   @stkECM=case @costmethod when 1 then AvgECM when 2 then LastECM when 3 then StdECM end
   from dbo.INMT with (nolock) where INCo=@co and Loc=@loc and MatlGroup=@matlgroup and Material=@material
   If @@rowcount = 0 
   begin
		select @msg='Material: ' + @material + ' doesnot exist for Location: ' + @loc + '!',@rcode = 1
   		goto bspexit
   end
   
   
   
   exec @rcode = dbo.bspINMatlUMVal  @material, @matlgroup, @um, @convfactor output, null, null, null, null, @msgout output
   
   
   
   insert dbo.INCB(Co,Mth,BatchId,BatchSeq,BatchTransType,INTrans,MO,MOItem,Loc,MatlGroup,
   Material,UM,ConfirmDate,Description,ConfirmUnits,RemainUnits,UnitPrice,ECM,
   ConfirmTotal,StkUM,StkUnits,StkUnitCost,StkECM,
   StkTotalCost)
   
   select @co,@batchmth,@batchid,@nextseq,'A',null,@mo,@moitem,Loc,MatlGroup,
   Material,UM,@confirmdate,Description,@confirmunits,-(@currentremainunits - @remainunits),UnitPrice,ECM,
   (UnitPrice * @confirmunits * case ECM when 'E' then 1 when 'C' then 100 when 'M' then 1000 end), @stkum,
   @confirmunits * @convfactor,@stkunitcost,@stkECM,
   ((@confirmunits * @convfactor) * @stkunitcost * case ECM when 'E' then 1 when 'C' then 100 when 'M' then 1000 end)
   from dbo.INMI with (nolock) where INCo=@co and MO=@mo and MOItem=@moitem
   
   bspexit:
   --	if @rcode = 1 select @msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINCBInsertNew] TO [public]
GO
