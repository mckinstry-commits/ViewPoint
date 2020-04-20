SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspJobRequest] /** User Defined Validation Procedure **/
(@@Company varchar(100), @@JobReq varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udJobRequest] with (nolock) where   @@Company = [Co] And  @@JobReq = [RequestNum] )
begin
select @msg = isnull([QueueDate],@msg) from [udJobRequest] with (nolock) where   @@Company = [Co] And  @@JobReq = [RequestNum] 
end
else
begin
select @msg = '', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspJobRequest] TO [public]
GO
