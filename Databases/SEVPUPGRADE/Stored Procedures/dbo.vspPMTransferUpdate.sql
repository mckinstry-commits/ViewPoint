SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPMTransferUpdate]
/***************************
*	Created By:		GP 10/14/2008
*	Modified By:
*
*
*	This stored procedure updates bHQWD with 
*	the new template location.
* 
***************************/
(@location varchar(10), @filename varchar(60), @msg varchar(255) output)

as
set nocount on

declare @rcode int
select @rcode=0


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

------ update template record in bHQWD where template Location is not PMStandard
if not exists(select top 1 1 from bHQWD where FileName = @filename and Location = 'PMStandard')
begin
	update bHQWD
	set Location = @location
	where FileName = @filename
end


bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMTransferUpdate] TO [public]
GO
