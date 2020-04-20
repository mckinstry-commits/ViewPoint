SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMWPMatlInvStatusOK] 
(@emco int = 0, @workorder bWO =null, @woitem bItem = null, @seq int=null, @equipment bEquip, 
@matlgroup bGroup =null, @material bMatl = null, @errmsg varchar (255)=nul output)
as
/*******************************
*Created By: TerryL 05/22/07
*Modified By: TRL 04/28/08 - Issue 127683 re-wrote stored procedure
*			  TRL 11/24/08 - Issue 131197 fixed validation for multiple parts
*
*Purpose: Used by EM Work Order Edit Parts, no duplicate
*material from same IN Co/IN Loc or Non Inventory Partcode/material
*
*Input Paramaters:
*EMCo
*WorkOrder
*WOItem
*INCo
*Loc
*MatlGroup
*Material
*
*Output
*Error Messages
*
*********************************/
declare @rcode int, @existingseq int, @msg varchar(255)

select @rcode = 0 

If IsNull(@emco,0)=0
begin
	select @errmsg ='Missing EM Company!',@rcode =1
	goto vspexit
end

If IsNull(@workorder,'') = ''
begin
	select @errmsg ='Missing Work Order!',@rcode =1
	goto vspexit
end

If @woitem is null
begin
	select @errmsg ='Missing Work Order Item!',@rcode =1
	goto vspexit
end


If @seq is null
begin
	select @errmsg ='Missing WO Item Part Seq!',@rcode =1
	goto vspexit
end

If @matlgroup is null
begin
	select @errmsg ='Missing Material Group!',@rcode =1
	goto vspexit
end

If IsNull(@material,'') = ''
begin
	select @errmsg ='Missing Part Code!',@rcode =1
	goto vspexit
end

If exists (select top 1 1 from EMWP Where EMCo=@emco  and WorkOrder = @workorder and WOItem = @woitem  and Seq=@seq)
	BEGIN
		--Handles PartCodes on exisiting records > 1
		If (select Count(*) from EMWP Where EMCo=@emco  and WorkOrder = @workorder and WOItem = @woitem 
			and Equipment = @equipment and MatlGroup = @matlgroup and Material = @material)> 1
		Begin
			select @existingseq = Max(Seq) from dbo.EMWP with(nolock)
			Where EMCo=@emco and WorkOrder = @workorder and WOItem = @woitem and Equipment = @equipment 
			and MatlGroup = @matlgroup and Material = @material and Seq <> @seq

			select @errmsg = 'Part Code already used on Seq: '+ convert(varchar,IsNull(@existingseq,'')),@rcode = 1
			goto vspexit 
		End
	END
ELSE
	BEGIN
		--Handles part codes that are being added on a new seq >= 1
		If (select Count(*) from EMWP Where EMCo=@emco  and WorkOrder = @workorder and WOItem = @woitem 
			and Equipment = @equipment and MatlGroup = @matlgroup and Material = @material)>= 1
		Begin
			select @existingseq = Max(Seq) from dbo.EMWP with(nolock)
			Where EMCo=@emco and WorkOrder = @workorder and WOItem = @woitem and Equipment = @equipment 
			and MatlGroup = @matlgroup and Material = @material and Seq <> @seq
	
			select @errmsg = 'Part Code already used on Seq: '+ convert(varchar,IsNull(@existingseq,'')),@rcode = 1
			goto vspexit 
		End
	END

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWPMatlInvStatusOK] TO [public]
GO
