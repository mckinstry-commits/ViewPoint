SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPLBValWO    Script Date: 8/28/99 9:34:01 AM ******/
   CREATE procedure [dbo].[bspAPLBValWO]
   /*********************************************
    * Created: GG 6/5/99
    * Modified: GH 12/20/00 Added @wocostcodechg to check if cost code is allowed to be changed
    *              kb 10/28/2 - issue #18878 - fix double quotes
    *
    * Usage:
    *  Called from the AP Transaction Batch validation procedure (bspAPLBVal)
    *  to validate Work Order Item information.
    *
    * Input:
    *  @emco       EM Co#
    *  @wo         Work Order
    *  @woitem     Work Order Item
    *  @equip      Equipment
    *  @comptype   Component Type
    *  @component  Component
    *  @emgroup    EM Group
    *  @costcode   Cost code
    *
    * Output:
    *  @errmsg     Error message
    *
    * Return:
    *  0           success
    *  1           error
    *************************************************/
   
       @emco bCompany, @wo bWO, @woitem bItem, @equip bEquip, @comptype varchar(10),
       @component bEquip, @emgroup bGroup, @costcode bCostCode, @errmsg varchar(255) output
   
   as
   
   set nocount on
   
   declare @rcode int, @wopostfinal bYN, @wocostcodechg bYN, @woequip bEquip, @wocomptype varchar(10), @wocomp bEquip,
   @wocostcode bCostCode, @wostatus varchar(10)
   
   select @rcode = 0
   
   -- get 'allow posting to finalized Work Orders' flag
   select @wopostfinal = WOPostFinal,@wocostcodechg = WOCostCodeChg
   from bEMCO
   where EMCo = @emco
   if @@rowcount = 0
       begin
       select @errmsg = ' Invalid EM Co#: ' + convert(varchar(3),@emco), @rcode = 1
       goto bspexit
       end
   
   -- validate WO Item
   select @woequip = Equipment, @wocomptype = ComponentTypeCode, @wocomp = Component, @wocostcode = CostCode,
       @wostatus = StatusCode
   from bEMWI
   where EMCo = @emco and WorkOrder = @wo and WOItem = @woitem
   if @@rowcount = 0
       begin
       select @errmsg = ' Invalid Work Order: ' + @wo + ' Item:' + convert(varchar(6),@woitem), @rcode = 1
       goto bspexit
       end
   
   -- match posted info with WO Item
   if @woequip <> @equip or isnull(@wocomptype,'') <> isnull(@comptype,'')
       or isnull(@wocomp,'') <> isnull(@component,'') or ((@wocostcode <> @costcode) and @wocostcodechg='N')
       begin
       select @errmsg = ' Does not match setup information on Work Order: ' + @wo + ' Item:' + convert(varchar(6),@woitem)
       select @rcode = 1
       goto bspexit
       end
   
   -- validate Status
   if @wopostfinal = 'N'   -- cannot post to WOs that are final
       begin
       if exists(select * from bEMWS where EMGroup = @emgroup and StatusCode = @wostatus and StatusType = 'F')
           begin
           select @errmsg = ' Final status on Work Order: ' + @wo + ' Item:' + convert(varchar(6),@woitem), @rcode = 1
           goto bspexit
           end
       end
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPLBValWO] TO [public]
GO
