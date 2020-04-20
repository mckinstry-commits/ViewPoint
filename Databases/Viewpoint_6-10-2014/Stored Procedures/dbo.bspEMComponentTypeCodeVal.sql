SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[bspEMComponentTypeCodeVal]
/***********************************************************
* CREATED BY: JM 9/20/98
* MODIFIED By : bc 12/8/98
*			JM 4/21/99 - Added input of Equipment so component returned
*				will be restricted to the CompOfEquip for the Equipment
*				entered on the form.
*			JM 4/30/99 - Added input of EMGroup so CostCode will be
*				selected from bEMTY by that tables key.
*			TV 02/11/04 - 23061 added isnulls
*			TJL 06/05/07 - Issue #27993, 6x Rewrite.  PER ANDREWK, Component output dflt returned was NOT
*					limited based upon Company. It is now.  ANDREWK said OK for all modules using this.
*			TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
*			GF 02/24/2010 - issue #136575 invalid component type was not returning error.
*
*
* USAGE:
* 	Validates EM ComponentTypeCode vs EMTY.
*
* 	If user hasnt entered a Component yet, returns the
*	first Component of the ComponentTypeCode from
*	EMEM for the Equip passed in.
*
*	If user has entered a Component, validates that
*	Component vs the ComponentTypeCode. If invalid,
*	returns special invalid err msg warning user that
*	ComponentTypeCode does not match the passed
*	Component.
*
* Error returned if any of the following occurs:
*	No Co, ComponentTypeCode or Equip passed
*	ComponentTypeCode not found in EMTY
*	Existing Component not of ComponentTypeCode
*
* INPUT PARAMETERS

*	@ComponentTypeCode - ComponentTypeCode to validate
*	@compin - Existing Component in Component input
*	@equip - Equipment in Equip input
*	@emgroup
*
* OUTPUT PARAMETERS
*	@compout - Component to install in Component input
*		on form.
*	@costcode - cost code stored in EMTY if there is one.
*   	@msg - Error message if error occurs, otherwise
*		Description of ComponentTypeCode from EMTY
*
* RETURN VALUE

*   0	Success
*   1	Failure
*****************************************************/ 
(@emco bCompany=null,
@ComponentTypeCode varchar(10) = null,
@compin bEquip = null,
@equip bEquip = null,
@emgroup bGroup = null,
@compout bEquip = null output,
@costcode varchar(10) = null output,
@msg varchar(60) output)
   
as

set nocount on
declare @rcode int, @ctc varchar(10)
select @rcode = 0

if @emco is null
	begin
	select @msg = 'Missing EM Company!', @rcode = 1
	goto bspexit
	end
if @ComponentTypeCode is null
	begin
	select @msg = 'Missing Component Type Code!', @rcode = 1
	goto bspexit
	end
if @equip is null
	begin
	select @msg = 'Missing Equipment!', @rcode = 1
	goto bspexit
	end
--dont check @compin for null since it can be passed in as null
if @emgroup is null
	begin
	select @msg = 'Missing EM Group!', @rcode = 1
	goto bspexit
	end
   
--base validation
select @msg = Description, @costcode = CostCode
from dbo.EMTY
where ComponentTypeCode = @ComponentTypeCode and EMGroup = @emgroup
if @@rowcount = 0
	begin
	select @msg = 'Not a valid Component Type Code!', @rcode = 1
	---- #136575
	GOTO bspexit
	end
   

--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
If @rcode = 1
begin
      goto bspexit
end

--if CompTypeCode found, if @compin is null send back 1st Component
--of that Component Type for that Equipment. if @compin is not null, return
--errmsg if its ComponentTypeCode doesnt match the one sent in to be
--validated
if @compin is null
	begin
	select @compout = MIN(Equipment)
	from dbo.EMEM
	where ComponentTypeCode = @ComponentTypeCode
		and CompOfEquip = @equip
		and EMCo = @emco			--TJL:  Added PER ANDREWK on 06/05/07 - Issue #27993, 6x Rewrite.
	end
else
	begin
	--send back existing component, whether it matches ctc or not
	select @compout=@compin
	--see if existing component matches ctc
	select @ctc=ComponentTypeCode
	from dbo.EMEM
	where EMCo=@emco and Equipment=@compin
	if @ctc <> @ComponentTypeCode
		begin
		select @msg='Component Type does not match Component!',@rcode=1
		goto bspexit
		end
	end
   
bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMComponentTypeCodeVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMComponentTypeCodeVal] TO [public]
GO
