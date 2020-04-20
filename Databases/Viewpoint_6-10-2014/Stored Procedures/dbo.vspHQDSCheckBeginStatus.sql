SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHQDSCheckBeginStatus]
/*************************************
* Created:	Robertt 
* Modified:	TJL 10/16/06 - Issue #26203, 6x Rewrite
*
* Checks for existing beginning status in HQDS.
*
* Pass:
*	Begin Status chkBox value
*	Status Code
*
* Success returns:
*	0 and status code Description from HQDS
*
* Error returns:
*	1 and error message
**************************************/
(@beginstatusyn bYN, @statuscode bStatus, @msg varchar(300) output)
as 
set nocount on

declare @rcode int, @dupseqcode bStatus, @dupseqdesc bDesc
select @rcode = 0

if @statuscode is null
	begin
	select @msg = 'Missing Status Code.', @rcode = 1
	goto vspexit
	end

if @beginstatusyn = 'Y'
	begin
	select @dupseqcode = Status, @dupseqdesc = Description
	from HQDS 
	where YNBeginStatus = 'Y' and rtrim(Status) <> @statuscode
	if @@rowcount > 0
		begin
		select @msg = 'Status Code [' + rtrim(@dupseqcode) + ' - ' + rtrim(@dupseqdesc) + '] is already set as the default Beginning Status Code.  '
		select @msg = @msg + 'Only one Status Code may be set as the Beginning Status Code.'
		select @msg = @msg + char(10) + char(13) + char(10) + char(13)
		select @msg = @msg + 'You must uncheck "Beginning Status" for that Status Code before setting "Beginning Status" on another.', @rcode = 1
		goto vspexit
		end
	end	  
  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQDSCheckBeginStatus] TO [public]
GO
