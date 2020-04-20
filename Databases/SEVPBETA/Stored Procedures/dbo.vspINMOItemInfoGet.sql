SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[vspINMOItemInfoGet]
( @inco bCompany, @mo varchar(20),  @moitem int, @loc varchar(10) = '', @matlgroup int = 0, @material varchar(20) = '', 
@orderedunits bUnits = 0 output, @unitprice bDollar  = 0 output, @ecm varchar(3) = null  output, @totalprice bDollar =0 output,
@confirmedunits bUnits =0 output, @remainunits bUnits = 0 output,@onhand bUnits = 0 output, @onorder bUnits =0 output ,@alloc bUnits = 0 output,
@msg varchar(255) output)
 as
 /***********************************************************************************
      * CREATED BY:  TRL 11/16/05
      *
      * USAGE:
      * Called from INMOEntryItems
      *
      * INPUT PARAMETERS:
      *   @inco         IN Company
      *   @mo   
      *   @moitem          int
      *  
      * OUTPUT PARAMETERS
      *@orderedunits
      * @unitprice
      *@ecm
      * @totalprice
      *@confirmedunits
      *@remainunits
      *@onhand
      * @onorder
      *@alloc
      *   @msg         error message if something went wrong
      *
      * RETURN VALUE:
      *   0               success
      *   1               fail
      **************************************************************************************/
set nocount on

declare @rcode int

select @rcode = 0, @orderedunits = 0, @unitprice = 0, @ecm = null, @totalprice =0, 
@confirmedunits = 0,@remainunits =0, @onhand = 0, @onorder=0,@alloc =0

If IsNull(@inco,0) =0
	begin
	select @msg = 'Invalid IN Co#!', @rcode = 1
	goto vspexit
	end

 if @mo is null
          begin
          select @msg = 'Missing Material Order!', @rcode = 1
          goto vspexit
          end

 if IsNull(@moitem,0) = 0
          begin
          select @msg = 'Missing Material Order Item!', @rcode = 1 
          goto vspexit
          end

--Gets MO Item information
select @orderedunits= IsNull(i.OrderedUnits,0), @unitprice = IsNull(i.UnitPrice,0), @ecm = i.ECM, @totalprice = IsNull(i.TotalPrice,0), @confirmedunits = IsNull(i.ConfirmedUnits,0),
@remainunits = IsNull(i.RemainUnits,0)
from dbo.INMI i with(nolock)
Left join INMT t with(nolock)on i.INCo=t.INCo and i.Loc = t.Loc and i.MatlGroup = t.MatlGroup and i.Material = t.Material
where i.INCo= @inco and i.MO = @mo and i.MOItem = @moitem

--Gets IN Item information
Select  @onhand = IsNull(t.OnHand,0), @onorder = IsNull(t.OnOrder,0), @alloc =  IsNull(t.Alloc,0)
From dbo.INMT t with(nolock)
Where  t.INCo=@inco and t.Loc = @loc and  t.MatlGroup=@matlgroup and t.Material =@material

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINMOItemInfoGet] TO [public]
GO
