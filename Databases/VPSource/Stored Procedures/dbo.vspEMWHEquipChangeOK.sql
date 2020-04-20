SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMWHEquipChangeOK] 
(@emco int = 0, @workorder bWO =null, @equip varchar(10) = null, @errmsg varchar (255)=nul output)
as
/*******************************
*Created By: TerryL 06/06/07
*Modified By:
*
*Purpose: Used by EM Work Order Edit  to verify Equipment can be changed
*
*
*Input Paramaters:
*EMCo
*WorkOrder
*Equip
*
*Output
*Error Messages
*
*********************************/
declare @rcode int

select @rcode = 0 

If IsNull(@emco,0)=0
begin
	select @errmsg ='Missing EM Company!',@rcode =1
	goto vspexit
end

If @workorder is null
begin
	select @errmsg ='Missing Work Order!',@rcode =1
	goto vspexit
end

If @equip is null
begin
	select @errmsg ='Missing Eqiupment!',@rcode =1
	goto vspexit
end

Select * From dbo.EMWI with (nolock) 
Where EMCo=@emco and WorkOrder =@workorder and Equipment <> @equip
	If @@rowcount >= 1
	begin
		select @errmsg = 'Cannot change Equipment when WO Items exist!',@rcode = 5
		goto vspexit
	end


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWHEquipChangeOK] TO [public]
GO
