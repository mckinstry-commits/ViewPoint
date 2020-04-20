SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPOEquipTypeVal    Script Date: 8/28/99 9:33:09 AM ******/
   CREATE  procedure [dbo].[bspPOEquipTypeVal]
   /***********************************************************
    * CREATED BY: SE   4/30/97
    * MODIFIED By : SE 4/30/97
    *
    * USAGE:
    * Validates PO Equipment type information
    *
    * This is used in PORBVal, POCBVal and POHBVal to validate
    * information about an Equipment type po.
    * 
    * Must be a valid EM company, Equipmentm, CostCode and CostType.
    *
    * PASS IN
    *   EMCo         inventory company
    *   Equipemnt    Equipment on PO item
    *   EMGroup      Equipment group
    *   CostCode     Cost Code
    *   CostType     Eqipment CostType
    * 
    * OUTPUT PARAMETERS
    *   ERRMSG       if error then message about error
    *
    * RETURNS
    *   0 on SUCCESS, 
    *   1 on FAILURE, see MSG for failure
    *
    *****************************************************/ 
   
    @emco bCompany, @equip bEquip, @emgroup bGroup, @costcod bCostCode, @costtype bEMCType, @errmsg varchar(255) output 
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode=0, @errmsg='Valid'
   /*
   if not exists(select * from bEMCO where EMCo=@emco)
      begin
       select @errmsg = 'Company ' + convert(varchar(3),@emco) + ' must be a valid Equipment Company'
       goto bspexit
      end
   */
      
   bspexit:
   
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOEquipTypeVal] TO [public]
GO
