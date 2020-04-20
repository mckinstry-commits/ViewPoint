SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMWOMixedItemsCheck    ******/
CREATE proc [dbo].[vspEMWOMixedItemsCheck]
/***********************************************************
* CREATED BY:  TJL 06/28/07- Issue #27980, 6x Recode EMWOItemUpdate. 
* MODIFIED BY:	JVH 10/20/10- Issue #141030 Added a check for component = '' since a lot of records are set to ''
*
*
* USAGE:
*  This is a check to see if on a given Work Order whether or not the WOItems contain
*  some Items with a Component value and some Items without.  (This would be consider Mixed Items)
*  Also if all WOItems contain Components, are they all the same?  (If not this would be Mixed Items)
*
* INPUT PARAMETERS
*   @emco		EM Company to validate against
*   @workorder	WorkOrder being tested
*
*
* OUTPUT PARAMETERS
*	@mixeditemsflag		Y - When mixed Items exist, otherwise N
*	@compallsameflag	Y - When components exist on all items, Y if they are all the same.
*   @msg      error message if error occurs otherwise Description of EM
*
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@emco bCompany = 0, @workorder bWO = null, @mixeditemsflag bYN output, @compallsameflag bYN output, @errmsg varchar(255) output)

as
set nocount on

declare @rcode int, @itemswithcomp int, @totalitems int, @component bEquip, @samecompcount int

select @rcode = 0, @mixeditemsflag = 'N', @compallsameflag = 'N', @itemswithcomp = 0, @totalitems = 0,
	@samecompcount = 0

if @workorder is null
	begin
	select @errmsg = 'Work Order is missing.', @rcode = 1
	goto vspexit
	end

/* Test #1 for mixed items - Do any WOItems have Components? 
   If no, then we do NOT have Mixed WOItems. */
select @itemswithcomp = Count(*) 
from bEMWI with (nolock)
where EMCo = @emco and WorkOrder = @workorder and Component is not null and Component <> ''
if isnull(@itemswithcomp, 0) = 0
	begin
	select @mixeditemsflag = 'N'
	select @compallsameflag = 'N'
	goto vspexit
	end

/* Test #2 for mixed items - Do some WOItems have Components and others not? 
   If yes, then we have Mixed WOItems. */
select @totalitems = Count(*) 
from bEMWI with (nolock)
where EMCo = @emco and WorkOrder = @workorder

If isnull(@totalitems, 0) > isnull(@itemswithcomp, 0)
	begin
	/* Some WOItems have Components and others do NOT */
    select @mixeditemsflag = 'Y'
	select @compallsameflag = 'N'
	goto vspexit
	end
Else
	begin
	/* Test #3 for Components all the same. - We don't have Mixed Items yet but are all Components the same? */
	select top 1 @component = Component			--At this point, first record will always have a Component.
	from bEMWI with (nolock)
	where EMCo = @emco and WorkOrder = @workorder

	select @samecompcount = Count(*)			--At least one must exist.
	from bEMWI with (nolock)
	where EMCo = @emco and WorkOrder = @workorder and Component = @component

	if isnull(@samecompcount, 0) = isnull(@totalitems, 0)
		begin
		select @mixeditemsflag = 'N'
		select @compallsameflag = 'Y'
		end
	else
		begin
		select @mixeditemsflag = 'Y'
		select @compallsameflag = 'N'
		end
	end

vspexit:
if @rcode <> 0 select @errmsg = @errmsg
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOMixedItemsCheck] TO [public]
GO
