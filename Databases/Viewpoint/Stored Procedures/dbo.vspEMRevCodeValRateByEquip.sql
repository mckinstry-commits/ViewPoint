SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMRevCodeValEquipRate  Script Date: ******/
CREATE proc [dbo].[vspEMRevCodeValRateByEquip]
   
/******************************************************
* Created By:  TJL  12/28/06 - Issue #27929, 6x Recode EMRevRateEquip.  Based on bspEMRevCodeValEquip
* Modified By: TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
*			   TRL 01/21/2008 - 131677 Fix Rev Code description on validation
*				TRL 02/22/2008	- Add 2 output paramters to RevBdwn Code from EMBG and EMBE
*
* Usage:
*  Validates Revenue code from EMRC.
*  Returns flag and default rate information from EMRR
*
* Input Parameters
*	EMCo		Need company to retreive Allow posting override flag
* 	EMGroup		EM group for this company
*	Equipment	Used to check the equipments category in EMEM
*	RevCode		Revenue code to validate
*
* Output Parameters
*	bYN         3 EMRR override flags
*   @stdrate	EMRR rate
*	@um			EMRR WorkUM
*	@msg		The RevCode description.  Error message when appropriate.
* Return Value
*   0	success
*   1	failure
***************************************************/
(@emco bCompany, @EMGroup bGroup, @equip bEquip, @RevCode bRevCode,
@updatehrmeter bYN output, @stdrate bDollar output, @alloworide bYN output, 
@postworkunits bYN output, @um bUM output,
@catrevbdwncodecount int output,@equiprevbdwncodecount int output, @msg varchar(255) output)
   
as

set nocount on

declare @rcode int, @errmsg varchar(255)
select @rcode = 0, @stdrate = 0 ,@catrevbdwncodecount=0, @equiprevbdwncodecount= 0
   
if @emco is null
begin
	select @msg= 'Missing Company.', @rcode = 1
	goto vspexit
end

if IsNull(@equip,'')=''
begin
	select @msg= 'Missing Equipment.', @rcode = 1
	goto vspexit
end

if IsNull(@RevCode,'')=''
begin
	select @msg= 'Missing Revenue Code.', @rcode = 1
	goto vspexit
end

/* Validate RevCode */
select @msg = c.Description from EMRC c with (nolock)
where c.EMGroup = @EMGroup and c.RevCode = @RevCode
if @@rowcount = 0
begin
	select @msg = 'Revenue code not set up in EM Revenue Codes.', @rcode = 1
	goto vspexit
end

--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @errmsg output
If @rcode = 1
begin
	  /*Issue 131677 Fix output procedure*/
	  select @msg = @errmsg
      goto vspexit
end

/* Get StdRate and other values from EMRR EM Rev Rates By Category table. */
select @stdrate = r.Rate, @updatehrmeter = r.UpdtHrMeter,@postworkunits = r.PostWorkUnits,
@um = r.WorkUM,	@alloworide = r.AllowPostOride
from EMRR r with (nolock)
Inner Join EMEM e with (nolock) on e.EMCo = r.EMCo and e.Category = r.Category				--Narrows EMRR records to single Rate value by input Equip/EquipCategory
where r.EMCo = @emco and r.EMGroup = @EMGroup and e.Equipment = @equip and r.RevCode = @RevCode
if @@rowcount = 0
begin
	select @msg = 'Revenue Code is not set up in EM Revenue Rates by Category.', @rcode = 1
	goto vspexit
end
   
/*Issue 131245 */
select @catrevbdwncodecount = IsNull(count(g.RevCode),0) from dbo.EMRR r with (nolock)
Inner Join dbo.EMEM e with(nolock)on e.EMCo = r.EMCo and e.Category = r.Category				
Left Join dbo.EMBG g with(nolock)on g.EMCo = r.EMCo and g.Category = r.Category	 and g.RevCode=r.RevCode and g.EMGroup=r.EMGroup
where r.EMCo = @emco and r.EMGroup = @EMGroup and e.Equipment = @equip and r.RevCode = @RevCode

/*Issue 131245 */
select @equiprevbdwncodecount = IsNull(count(g.RevCode),0) from dbo.EMRH r with (nolock)
Inner Join dbo.EMEM e with(nolock)on e.EMCo = r.EMCo and e.Equipment = r.Equipment
Left Join dbo.EMBE g with(nolock)on g.EMCo = r.EMCo and g.Equipment = r.Equipment and g.RevCode=r.RevCode and g.EMGroup=r.EMGroup
where r.EMCo = @emco and r.EMGroup = @EMGroup and e.Equipment = @equip and r.RevCode = @RevCode

vspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMRevCodeValRateByEquip] TO [public]
GO
