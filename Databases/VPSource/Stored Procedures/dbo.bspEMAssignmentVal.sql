SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMAssignmentVal    Script Date: 8/28/99 9:32:40 AM ******/
   CREATE   procedure [dbo].[bspEMAssignmentVal]
   /*************************************
   * Created:      04/09/98  bc
   * Modified:     05/10/00 bc
   *				TV 02/11/04 - 23061 added isnulls
   *				TRL 08/13/2008 - 126196 check to see Equipment code is being Changed 
   *
   * validates Component or an Attachment of Equipment
   *
   * Pass:
   *	EMCO, Component of Equipment OR Attachment of equipment, Current Equipment
   *
   * Return:
   *	Description of component or attachment
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   @emco bCompany, @assignment bEquip, @curr_equip bEquip, @msg varchar(255) output
   as
   	set nocount on
   	declare @rcode int, @status char(1), @type varchar(1), @attachment bEquip
   	select @rcode = 0, @attachment = null
   
   if @assignment = @curr_equip
   	begin
   	select @msg = 'Cannot assign equipment to itself.', @rcode = 1
   	goto bspexit
   	end
   
	-- Return if Equipment Change in progress for New Equipment Code, 126196.
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @curr_equip, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end

   select @msg = Description, @type = Type, @status = Status, @attachment = AttachToEquip
   from bEMEM
   where EMCo = @emco and Equipment = @assignment
   
   if @@rowcount = 0
     begin
     select @msg = 'Not a valid piece of equipment', @rcode = 1
     goto bspexit
     end
	   
   /* Check the type option of the primary equipment */
   if @type = 'C'
     begin
     select @msg = 'Cannot assign a component or an attachment to a component.', @rcode = 1
     goto bspexit
     end
   
   if @type <> 'C' and	@attachment is not null
     begin
     select @msg = 'Cannot assign a component or an attachment to another attachment.', @rcode =1
     end
   
   if @status <> 'A'
     begin
     select @msg = 'Cannot assign a component or an attachment to a non active equipment.', @rcode =1
     goto bspexit
     end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMAssignmentVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMAssignmentVal] TO [public]
GO
