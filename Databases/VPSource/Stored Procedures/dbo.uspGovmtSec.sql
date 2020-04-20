SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspGovmtSec] /** User Defined Validation Procedure **/
(@@GvmntSec varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udGovmtSec] with (nolock) where   @@GvmntSec = [GSID] )
begin
select @msg = isnull([Description],@msg) from [udGovmtSec] with (nolock) where   @@GvmntSec = [GSID] 
end
else
begin
select @msg = 'Invalid Government Sector', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspGovmtSec] TO [public]
GO
