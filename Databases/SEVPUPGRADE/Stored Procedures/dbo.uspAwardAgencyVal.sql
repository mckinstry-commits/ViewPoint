SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspAwardAgencyVal] /** User Defined Validation Procedure **/
(@AwardAgncy varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udAwardAgcy] with (nolock) where   @AwardAgncy = [AgncyID] )
begin
select @msg = isnull([Description],@msg) from [udAwardAgcy] with (nolock) where   @AwardAgncy = [AgncyID] 
end
else
begin
select @msg = 'Invalid Agency', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspAwardAgencyVal] TO [public]
GO
