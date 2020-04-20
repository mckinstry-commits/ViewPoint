SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspLegDocs] /** User Defined Validation Procedure **/
(@DocValue varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udLegalDoc] with (nolock) where   @DocValue = [DocValue] )
begin
select @msg = isnull([Description],@msg) from [udLegalDoc] with (nolock) where   @DocValue = [DocValue] 
end
else
begin
select @msg = 'Not a valid legal document.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspLegDocs] TO [public]
GO
