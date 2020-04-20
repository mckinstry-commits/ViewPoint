SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    Proc [dbo].[bspINMOItemValForConf]
    /***********************************
    
    Modified By:	GF 08/03/2012 TK-16643 change to get conversion factor from INMU
    ************************************/
    (@co bCompany,
@mo bMO,
@moitem bItem,
@loc bLoc = null output ,
@matlgroup bGroup = null output,
@material bMatl = null output,
@desc bDesc = null output,
@datereq bDate = null output, 
@um bUM = null output,
@unitprice bUnitCost = null output,
@ecm bECM = null output,
@stkum bUM = null output, 
@convfactor bUnitCost = null output,
@stkunitcost bUnitCost = null output,
@stkECM bECM = null output,
@msg varchar(255) output)
    as
    
declare @rcode int, @msgout varchar(255), @costmethod int, @category varchar(30),
		@stdum bUM
		
select @rcode = 0

select @msg = ''
    
   
select @loc = Loc,@matlgroup=MatlGroup,@material=Material,@um=UM,
		@unitprice=UnitPrice,@ecm=ECM,@desc=Description,@datereq=ReqDate, @msg=INMI.Description
from INMI
where INCo=@co and MO=@mo and MOItem=@moitem
if @@rowcount=0
	begin
	select @msg='MO Item does not exist.',@rcode = 1
	goto bspexit
	END

---- TK-16643 get um conversion factor
select @stdum = StdUM, @stkum=StdUM, @category=Category
from bHQMT with (nolock)
where MatlGroup = @matlgroup and Material = @material
if @@rowcount = 0
 	begin
 	select @msg = 'Invalid HQ Material.', @rcode = 1
 	goto bspexit
 	end

SET @convfactor = 1
---- validate in Location Materials
if @stdum <> @um
 	begin	
 	select @convfactor = Conversion
 	from bINMU with (Nolock)
 	where INCo = @co and Loc = @loc and Material = @material and MatlGroup = @matlgroup and UM = @um
 	if @@rowcount = 0
 		begin
 		select @msg = 'Not a valid Unit of Measure: ' + isnull(@um,'') + ' for this material: ' + isnull(@material,'') + ' at the Location: ' + isnull(@loc,'') + '.', @rcode = 1
 		goto bspexit
 		end
 	end

--exec @rcode = bspINMatlUMVal  @material, @matlgroup, @um, @convfactor output, null, null, null, null, @msgout output
--if @rcode = 1
--begin
--	select @msg = @msgout
--	goto bspexit
--end

--Select @stkum=StdUM,@category=Category from HQMT where MatlGroup=@matlgroup and Material = @material
select @costmethod = CostMethod from INLO where INCo=@co and Loc=@loc and MatlGroup=@matlgroup and Category=@category
    
if isnull(@costmethod,0) = 0
Begin
	select @costmethod = CostMethod from INLM where INCo=@co and Loc=@loc
end

 if isnull(@costmethod,0)=0
Begin
	select @costmethod = CostMethod from INCO where INCo=@co
End
    
select @stkunitcost=case @costmethod when 1 then AvgCost when 2 then LastCost when 3 then StdCost end,
	   @stkECM=case @costmethod when 1 then AvgECM when 2 then LastECM when 3 then StdECM end
from INMT where INCo=@co and Loc=@loc and MatlGroup=@matlgroup and Material=@material


bspexit:
    --	if @rcode = 1 select @msg
    	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspINMOItemValForConf] TO [public]
GO
