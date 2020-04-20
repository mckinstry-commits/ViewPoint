SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfEMEquipLastOdo]
(@emco bCompany = null, @equipment bEquip = null)
returns bHrs
/***********************************************************
* CREATED BY	: Toml 04/03/07 - Issue #27992, 6x Rewrite
* MODIFIED BY	
*
* USAGE:
* 	Retrieves the Last Odometer Reading from EMSM for a piece of Equipment
*	based upon the Last Reading Date for same.
*
* INPUT PARAMETERS:
*	EMCo  
*	Equipment
*
* OUTPUT PARAMETERS:
*	LastOdo
*
*****************************************************/
as
begin

declare @lastodo bHrs, @lastreadingdate bDate
select @lastodo = 0
  
if @emco is null
	begin
	goto exitfunction
	end
if @equipment is null
	begin
	goto exitfunction
	end

select @lastreadingdate = max(ReadingDate), @lastodo = max(EndOdo) 
from bEMSM with (nolock)
where Co = @emco and Equipment = @equipment 
	and	EndOdo = (select max(EndOdo) From bEMSM m2 where m2.Co = @emco and m2.Equipment = @equipment and m2.ReadingDate =
			((select max(ReadingDate) From bEMSM m where m.Co = @emco and m.Equipment = @equipment)))
  
if @@rowcount = 0
	begin
	goto exitfunction
	end
 
exitfunction:
  			
return @lastodo
end

GO
GRANT EXECUTE ON  [dbo].[vfEMEquipLastOdo] TO [public]
GO
