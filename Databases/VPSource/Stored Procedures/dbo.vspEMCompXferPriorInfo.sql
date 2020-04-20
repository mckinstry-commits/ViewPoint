SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            procedure [dbo].[vspEMCompXferPriorInfo]
/***********************************************************
* CREATED BY: TV 5/12/05
* MODIFIED By : 
*
* USAGE:
*	returns the proper prior equip info for the component
*
* INPUT PARAMETERS
*	@EMCo			EM Company to be validated against
*	@Component		Component to be validated
*
* RETURN VALUE
*	0 success
*	1 error
*	
***********************************************************/
(@EMCo bCompany = null, @Component bEquip = null,@Seq varchar(20) = null, @Prior_Master_Equip bEquip = null output, 
@Prior_Master_Equip_Desc bItemDesc = null output, @errmsg varchar(255) output)

as

set nocount on

declare @rcode int

select @rcode = 0

if @EMCo is null
	begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto bspexit
	end

if @Component is null
	begin
	select @errmsg = 'Missing Component!', @rcode = 1
	goto bspexit
	end


if exists (select top 1 1 from bEMHC where EMCo = @EMCo and Component = @Component)
	begin
	if @Seq <> 1 
		begin
		select @Prior_Master_Equip = h.ComponentOfEquip, @Prior_Master_Equip_Desc = e.Description  
		from bEMHC h join bEMEM e on h.EMCo = e.EMCo and h.ComponentOfEquip = e.Equipment
		where h.Component = @Component and 
		h.Seq = case when @Seq = -1 then (select max(Seq) from bEMHC h2 where h2.Component = @Component) else (@Seq - 1) end
		end
	else
		begin
		select @Prior_Master_Equip = 'No Info', @Prior_Master_Equip_Desc = 'No Info' 
		end
	end
else
	begin
	select @Prior_Master_Equip = e.CompOfEquip, @Prior_Master_Equip_Desc = e2.Description  
	from bEMEM e join bEMEM e2 on e.EMCo = e2.EMCo and e2.Equipment = e.CompOfEquip
	where e.EMCo = @EMCo and e.Equipment = @Component
	end
	


bspexit:
if @rcode<>0 select @errmsg=isnull(@errmsg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCompXferPriorInfo] TO [public]
GO
