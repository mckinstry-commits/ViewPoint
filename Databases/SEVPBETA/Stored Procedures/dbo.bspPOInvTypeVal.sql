SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPOInvTypeVal    Script Date: 8/28/99 9:35:26 AM ******/
   CREATE   procedure [dbo].[bspPOInvTypeVal]
   /***********************************************************
    * CREATED BY: SE   4/30/97
    * MODIFIED By : GG 10/25/99 - Fixes needed for IN table changes
    *				 MV 01/29/03 - #20112 added @matlgroup to bINMT select statement
    * USAGE:
    * Validates PO inventory type information
    *
    * This is used in PORBVal, POCBVal and POHBVal to validate
    * information about an inventory type po.
    *
    * Must be a valid Inventory company, Location and Material.
    * also the Material must be stocked and the UM must be setup in
    * HQMU
    *
    * PASS IN
    *   INCo      inventory company
    *   Loc       location
    *   Matlgroup Material group
    *   Material  Materil posting
    *   UM        unit of measure posting in
    *
    * OUTPUT PARAMETERS
    *   JCUM      Job cost unit of measure
    *   ERRMSG       if error then message about error
    *
    * RETURNS
    *   0 on SUCCESS,
    *   1 on FAILURE, see MSG for failure
    *
    *****************************************************/
   @inco bCompany, @loc bLoc, @matlgroup bGroup, @material bMatl, @um bUM, @errmsg varchar(255) output
   as
   set nocount on
   declare @rcode int, @stocked bYN
   select @rcode=0, @errmsg='Valid'
   select @stocked = Stocked from bHQMT where @matlgroup = MatlGroup and @material=Material
   if @@rowcount = 0
      begin
       select @errmsg='Material ' + @material + ' not setup in HQ for group ' + convert(varchar(3),@matlgroup), @rcode=1
       goto bspexit
      end
   /*for inventory types, material must be valid */
   if @stocked = 'N'
      begin
       select @errmsg='Material ' + @material + ' must be stocked!' , @rcode=1
       goto bspexit
      end
   /*validate inventory company */
   if not exists(select * from bINCO where INCo=@inco)
      begin
       select @errmsg = 'Company ' + convert(varchar(3),@inco) + ' must be a valid Inventory Company!', @rcode=1
       goto bspexit
      end
   /* make sure location is setup*/
   if not exists(select * from bINLM where INCo=@inco and Loc=@loc)
      begin
       select @errmsg = 'Location ' + @loc + ' is not setup in Inventory company ' + convert(varchar(3), @inco) +'!', @rcode=1
       goto bspexit
      end
   /* make sure material is setup for this location */
   --if not exists(select * from bINMT where INCo=@inco and Loc=@loc and Material=@material)
   if not exists(select * from bINMT where INCo=@inco and Loc=@loc and Material=@material and MatlGroup=@matlgroup)
      begin
       select @errmsg = 'Material ' + @material + ' is not setup at location ' + @loc + '!', @rcode=1
       goto bspexit
      end
   bspexit:
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOInvTypeVal] TO [public]
GO
