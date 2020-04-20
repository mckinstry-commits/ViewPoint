SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPMTransferAdd]
/***************************
*	Created By:		GP 04/24/2008
*	Modified By:	GP 10/14/2008 - Issue 130525, removed update to bHQWD, moved to vspPMTransferUpdate.
*
*
*	This stored procedure validates file info
*	before setting @copy = 'Y' and back to form.
*
***************************/
(@location varchar(10), @filename varchar(60), @copy bYN output, @msg varchar(255) output)

as
set nocount on

declare @rcode int
select @rcode=0, @copy = 'N'


------ valid location
if @location is null
	begin
	select @msg = 'Missing Location!', @rcode = 1
	goto bspexit
	end

------ valid file name
if @filename is null
	begin
	select @msg = 'Missing File Name!', @rcode = 1
	goto bspexit
	end

------ make sure file name already exists
select FileName from bHQWD where FileName = @filename
  if @@rowcount=0
   	begin
   	select @msg = 'One or more of the selected templates are not associated with a PM template. ' + 
	'Templates cannot be copied until set up in PM Document Templates.', @rcode = 1
   	goto bspexit
   	end

set @copy = 'Y'


bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMTransferAdd] TO [public]
GO
