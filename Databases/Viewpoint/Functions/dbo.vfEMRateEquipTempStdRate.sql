SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfEMRateEquipTempStdRate]
(@emco bCompany = null, @emgroup bGroup = null, @equip bEquip = null,
@revcode bRevCode = null) 

returns bDollar
/***********************************************************
* CREATED BY	: TJL 11/08/06 - Issue #27973, 6x Rewrite
* MODIFIED BY	
*
* USAGE:
* 	Evaluates and returns StdRate default to the EMRevRateEquipTemp form
*	
*
* INPUT PARAMETERS:
*	EMCo
*	EMGroup
*	RevTemplate 
*	Equipment
*	RevCode
*
* OUTPUT PARAMETERS:
*	StdRate Default
*	
*
*****************************************************/
as
begin

declare @stdrate bDollar, @emrhrate bDollar, @emrrrate bDollar, @emrhoriderateyn bYN,
	@catgy bCat
select @stdrate = 0, @emrhrate = 0, @emrrrate = 0, @emrhoriderateyn = 'N'

if @equip is not null
   	begin
   	select @catgy = Category
   	from bEMEM with (nolock)
   	where EMCo = @emco and Equipment = @equip
   
   	select @emrhrate = Rate, @emrhoriderateyn = ORideRate
   	from bEMRH with (nolock)
   	where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
   	if @@rowcount = 0
   		begin
		/* There are no Records in EMRH.  Only option is to use Rate from EMRR if present. */
   	    select @emrrrate = Rate
   	    from bEMRR	with (nolock)
   	    where EMCo = @emco and EMGroup = @emgroup and Category = @catgy and RevCode = @revcode
        if @@rowcount = 0
			begin
			select @stdrate = 0
   			goto exitfunction
   			end

		select @stdrate = @emrrrate
		goto exitfunction
		end
	else
		begin
		/* EMRH rate does exist but further evaluation is necessary. */
		if @emrhoriderateyn = 'Y'
			begin
			/* OK to use EMRH rate. */
			select @stdrate = @emrhrate
			goto exitfunction
			end
		else
			begin
			/* Not OK to use EMRH rate.  Go get EMRR rate if present. */
   			select @emrrrate = Rate
   			from bEMRR	with (nolock)
   			where EMCo = @emco and EMGroup = @emgroup and Category = @catgy and RevCode = @revcode
			if @@rowcount = 0
				begin
				select @stdrate = 0
   				goto exitfunction
   				end
	
			select @stdrate = @emrrrate
			goto exitfunction
			end
		end
	end

exitfunction:
  			
return @stdrate
end

GO
GRANT EXECUTE ON  [dbo].[vfEMRateEquipTempStdRate] TO [public]
GO
