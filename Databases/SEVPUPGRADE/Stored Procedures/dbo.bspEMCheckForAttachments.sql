SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCheckForAttachments    Script Date: 8/28/99 9:32:40 AM ******/
CREATE procedure [dbo].[bspEMCheckForAttachments]
   
/***********************************************************
* CREATED BY: bc  09/04/99
* MODIFIED By : TV 02/11/04 - 23061 added isnulls
*		TJL 03/09/07 - Issue #27815, EMEquipment 6x Rewrite.  Added EMHCCount output
*
* USAGE:
*	checks to see if any attachments exist for a piece of equipment or for any equipment falling under a specific category
*
*
* INPUT PARAMETERS
*  @emco		EM Company
*  @equip		Equipment to search on
*
* OUTPUT PARAMETERS
*  @found		Yes if there is at least one attachment.  No if there are no attachments
*  @emhccount	Component History record count.
*  @msg			Description or Error msg if error
*
* RETURN VALUE:
*  0 	    Success
*  1 & message Failure
 **********************************************************/
   
(@emco bCompany, @equip bEquip = null, @found bYN output, @emhccount int output, @msg varchar(255) output)
   
as

set nocount on
declare @rcode int, @cnt int
select @rcode = 0, @found = 'N', @emhccount = 0
   
if @emco is null
	begin
	select @msg = 'Missing EM Company!', @rcode = 1
	goto bspexit
	end
	
/* Validate Equipment */
select @msg = Description
from bEMEM with (nolock)
where EMCo = @emco and Equipment = @equip
if @@rowcount = 0
	begin
	select @msg = 'Equipment invalid!', @rcode = 1
	goto bspexit
	end

/* Attachments check */  
select @cnt = isnull(count(*), 0)
from bEMEM with (nolock)
where EMCo = @emco and AttachToEquip = @equip
if @cnt <> 0 select @found = 'Y'
   
/* Component History check */
select @emhccount = isnull(count(*), 0)
from bEMHC with (nolock)
where EMCo = @emco and Component = @equip

bspexit:
if @rcode <> 0 select @msg= isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMCheckForAttachments]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCheckForAttachments] TO [public]
GO
