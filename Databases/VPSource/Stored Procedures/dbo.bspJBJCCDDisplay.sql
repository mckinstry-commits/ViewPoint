SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBJCCDDisplay]
/****************************************************************************************
* CREATED BY: bc   06/22/00
* MODIFIED By : GR 11/21/00 - changed datatype from bAPRef to bAPReference
*   	bc 09/23/02 - Issue #18672
*		TJL 02/26/03 - Issue #19765, Category returning as NULL for Material from HQMT. Fix bspJBTandMGetCategory 
*		TJL 04/12/04 - Issue #24240, Added 'with (nolock)', added 'b' to Table names (bJBIN), Correct Alias use.
*		TJL 04/29/04 - Issue #24472, In JB Source really represents JCCD.JCTransType.  Use JCTransType in Display
*		TJL 04/14/06 - Issue #28232, 6x Rewrite.  Added additional returned JCCD values.
*		TJL 10/08/07 - Issue #125078, TransTypes 'IC' from 'JC CostAdj' need to be processed as JCTransTypes 'JC'
*		TJL 01/11/08 - Issue #123452, TransTypes 'MI' from 'JC MatlUse' need to be processed as JCTransTypes 'JC'
*		DAN SO 05/29/2012 - TK-15229 - SM JC Integration
*
*
* USED IN:
*	JB JCDetail - All Form
*	JB JCDetail Form
*
* USAGE:
* 	Returns values to Lables from bJCCD for each JC Transaction
*
*****************************************************************************************/
   
(@jbco bCompany = 0, @billmth bMonth, @billnumber int,
@line int = null, @seq int = null, @jcmth bMonth, @jctrans bTrans,
@msg varchar(255) output)

as
set nocount on

declare @rcode int 
select @rcode = 0



/* Other working variables */
declare @billcategory bCat, @template varchar(10), @ctcategory char(1), @matlgroup bGroup,
	@prco bCompany, @empl bEmployee, @craft bCraft, @class bClass, @earntype bEarnType, @factor bRate, 
	@shift int, @emco bCompany, @equip bEquip, @matl bMatl, @revcode bRevCode, @source char(2)

/* Retrieve Billing Category for display. */ 
select @template = Template
from JBIN with (nolock)
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber

select @ctcategory = JCCT.JBCostTypeCategory, @matlgroup = d.MatlGroup,
	@source = case d.JCTransType when 'CA' then 'JC'
	when 'IC' then 'JC' 
	when 'MI' then 'JC'
	when 'MO' then 'IN'
	else d.JCTransType end,
	@prco = d.PRCo, @empl = d.Employee, @craft = d.Craft, @class = d.Class, @earntype = d.EarnType, 
	@factor = d.EarnFactor, @shift = d.Shift, @emco = d.EMCo, @equip = d.EMEquip, @matl = d.Material,
	@revcode = d.EMRevCode 
from JCCD d with (nolock)
left join JCCT with (nolock) on JCCT.PhaseGroup = d.PhaseGroup and JCCT.CostType = d.CostType
where d.JCCo = @jbco and d.Mth = @jcmth and d.CostTrans = @jctrans

exec bspJBTandMGetCategory  @jbco, @prco, @empl, @craft,
	@class, @earntype, @factor, @shift, @emco, @equip, @matlgroup, @matl,
	@revcode, @source, @template, @ctcategory, @billcategory output, @msg output

/* Output values back to calling code */
select JBIL.Item, case d.JCTransType when 'CA' then 'JC' 
	when 'IC' then 'JC' 
	when 'MI' then 'JC'
	when 'MO' then 'IN'
	else d.JCTransType end as Source,
	d.PRCo, d.Employee, PREHFullName.FullName, d.Craft, d.Class,
	d.EarnType, d.EarnFactor, d.Shift, d.LiabilityType,
	d.APCo, d.Vendor, APVM.Name as VendorName, d.APRef,
	d.SL, case when d.SL is not null then SLHD.Description else null end as SLDesc,
		d.SLItem, case when d.SL is not null then SLIT.Description else null end as SLItemDesc,
	d.PO, case when d.PO is not null then POHD.Description else null end as PODesc,
		d.POItem, case when d.PO is not null then POIT.Description else null end as POItemDesc,
	d.INCo, d.Loc, d.Material, 
		case when d.Material is not null then HQMT.Description else null end as MatlDesc, d.MSTicket,
	d.EMCo, d.EMEquip, 
		case when d.EMEquip is not null then EMEM.Description else null end as EquipDesc, d.EMRevCode,
	d.JCTransType, d.ActualDate as JCDate, d.Job, d.Phase, d.CostType,
	d.Description as JCDescription, d.UM, @billcategory as BillCategory,
	-- TK-15229 --
	d.SMCo, d.SMWorkOrder, case when d.SMWorkOrder is not null then SMWorkOrder.Description else null end as SMWorkOrderDesc,
	d.SMScope, case when d.SMScope is not null then SMWorkOrderScope.Description else null end as SMScopeDesc
from JCCD d with (nolock) 
left join JCCT with (nolock) on JCCT.PhaseGroup = d.PhaseGroup and JCCT.CostType = d.CostType
left join HQMT with (nolock) on HQMT.MatlGroup = d.MatlGroup and HQMT.Material = d.Material
left join EMEM with (nolock) on EMEM.EMCo = d.EMCo and EMEM.Equipment = d.EMEquip
left join SLHD with (nolock) on SLHD.SLCo = d.APCo and SLHD.SL = d.SL
left join SLIT with (nolock) on SLIT.SLCo = d.APCo and SLIT.SL = d.SL and SLIT.SLItem = d.SLItem
left join POHD with (nolock) on POHD.POCo = d.APCo and POHD.PO = d.PO
left join POIT with (nolock) on POIT.POCo = d.APCo and POIT.PO = d.PO and POIT.POItem = d.POItem
left join JBIL with (nolock) on JBIL.JBCo = @jbco and JBIL.BillMonth = @billmth and JBIL.BillNumber = @billnumber and JBIL.Line = @line
left join PREHFullName with (nolock) on PREHFullName.PRCo = d.PRCo and PREHFullName.Employee = d.Employee
left join APVM with (nolock) on APVM.VendorGroup = d.VendorGroup and APVM.Vendor = d.Vendor
-- TK-15229 --
LEFT JOIN SMWorkOrder on SMWorkOrder.SMCo=d.SMCo AND SMWorkOrder.WorkOrder=d.SMWorkOrder 
LEFT JOIN SMWorkOrderScope on SMWorkOrderScope.SMCo=d.SMCo AND SMWorkOrderScope.WorkOrder=d.SMWorkOrder AND SMWorkOrderScope.Scope=d.SMScope
where d.JCCo = @jbco and d.Mth = @jcmth and d.CostTrans = @jctrans
if @@rowcount = 0
	begin	
	select @msg = 'Cost Transaction display values could not be retrieved', @rcode = 1
	goto bspexit
	end
   
bspexit:
if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[bspJBJCCDDisplay]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBJCCDDisplay] TO [public]
GO
