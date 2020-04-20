SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfEMEquipHasAttachments]
(@emco bCompany = null, @equip bEquip = null) 

returns bYN
/***********************************************************
* CREATED BY	: TJL 01/23/07 - Issue #27822, 6x Rewrite
* MODIFIED BY	
*
* USAGE:
* 	Evaluates if Equipment in sequence has Attachment Equipment to it.
*	
*
* INPUT PARAMETERS:
*	EMCo
*	Equipment
*
* OUTPUT PARAMETERS:
*	Y or N
*	
*
*****************************************************/
as
begin

declare @equipattachmentsyn bYN

select @equipattachmentsyn = 'N'

if @equip is not null
   	begin
	/* Look for Equipments attached to this Equipment */
	if exists(select top 1 1 from bEMEM with (nolock) where EMCo = @emco and AttachToEquip = @equip)
		begin
		select @equipattachmentsyn = 'Y'
		end
	end

exitfunction:
  			
return @equipattachmentsyn
end

GO
GRANT EXECUTE ON  [dbo].[vfEMEquipHasAttachments] TO [public]
GO
