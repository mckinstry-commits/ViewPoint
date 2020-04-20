SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDMOVal    Script Date: 8/28/99 9:34:21 AM ******/
CREATE   proc [dbo].[vspDDSGVal]
/***********************************************************
* CREATED: MJ 3/21/05
* MODIFIED: GG 08/03/07 - added GroupType validation
*			JonathanP 04/21/08 - See issue #127475. Added attachment type group check.
* 
* Usage:
*	validates Security Group, pass in a Group Type if limited to a single type
*
* INPUT PARAMETERS
*   @securitygroup       Security Group to validate
*	@type				Group Type (0=data,1=form,2=reports,3=attachment types,null=any type)
*
* INPUT PARAMETERS
*   @msg        error message if something went wrong, otherwise description
*
* RETURN VALUE
*   0 Success
*   1 fail
************************************************************************/
  	(@securitygroup int = null, @type tinyint = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @xtype tinyint
select @rcode = 0

if @securitygroup is null
	begin
	select @msg = 'Missing Security Group!', @rcode = 1
	goto vspexit
	end
if @type is not null and @type not in(0,1,2,3)
	begin
	select @msg = 'Invalid Group Type, must be 0,1,2,3 or null!', @rcode = 1
	goto vspexit
	end
  
select @msg = Name, @xtype = GroupType
from dbo.DDSG (nolock)
where SecurityGroup = @securitygroup
if @@rowcount = 0
  	begin
  	select @msg = 'Security Group not on file!', @rcode = 1
  	end
if @type is null or @type = @xtype goto vspexit

select @msg = 'Invalid Security Group, must be a ', @rcode = 1
if @type = 0 select @msg = @msg + '0 = Data Group type!'
if @type = 1 select @msg = @msg + '1 = Form Group type!'
if @type = 2 select @msg = @msg + '2 = Reports Group type!'
if @type = 3 select @msg = @msg + '3 = Attachment Type Group type!'
   
vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDSGVal] TO [public]
GO
