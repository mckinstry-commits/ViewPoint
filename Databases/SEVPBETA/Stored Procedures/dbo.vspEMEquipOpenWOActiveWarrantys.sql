SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMEquipOpenWOActiveWarrantys]
 /**************************************************************************
   * CREATED: 02/01/07 TRL
   * MODIFIED: TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
   *
   *USAGE:
   * returns next available shop to EMWOEdit
   *
   *   Inputs:
   *	EMCo
   *	Equipment Number
   *	
   *   Outputs:
   *	Open WO Exits Y/N
   *	
   *
   *
   *   RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *
   ***************************************************************************/
   (@emco bCompany,  @equip varchar(10), @workorder varchar(10), @openwoexist varchar(1) output, @activewarrantys varchar(2) output, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @changeerrmsg varchar(256)
   select @rcode = 0



If Isnull(@emco,0)=0
 begin 
	select @msg = 'Invalid EM Company:  ' + isnull(convert(varchar,@emco),'') , @rcode = 1
	goto vspexit
 end 
 if (select EMCo from EMCO where  EMCo = @emco) is null	
 begin 
	select @msg = 'Invalid  EM Company:  ' + isnull(convert(varchar,@emco),''), @rcode = 1
	goto vspexit
 end 

 if (select Count(Equipment) from EMEM where Equipment = @equip and EMCo = @emco)  = 0	
 begin 
	select @msg = 'Invalid Equipment Number: ' + @equip, @rcode = 1
	goto vspexit
 end 

----Return if Equipment Change in progress for New Equipment Code - 126196
--exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @changeerrmsg output
--If @rcode = 1
--begin
--	  select @msg = @changeerrmsg
--      goto vspexit
--end


select   @openwoexist = 'N',  @activewarrantys = 'N'
   
	select Complete from dbo.EMWH where EMCo = @emco and Equipment = @equip and Complete = 'N'  and WorkOrder <> @workorder
	If @@rowcount >=1 
	begin
		select @openwoexist = 'Y'
	end	

--Check for Warranties first
	select Equipment from dbo.EMWF where EMCo = @emco and Equipment = @equip
	If @@rowcount >=1 
	begin
		select @activewarrantys = 'YN'
	end	

--Check for Active Warranties second
	select Equipment from dbo.EMWF where EMCo = @emco and Equipment = @equip and Status = 'A' 
	If @@rowcount >=1 
	begin
		select @activewarrantys = 'YA'
	end	
vspexit:
 
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipOpenWOActiveWarrantys] TO [public]
GO
