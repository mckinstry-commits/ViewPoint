SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspStateExhibitVal] /** User Defined Validation Procedure **/
(@@State varchar(100), @@Exhibit varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udStateExhibits] with (nolock) where   @@State = [State] And  @@Exhibit = [Exhibit] )
begin
select @msg = isnull([Comment],@msg) from [udStateExhibits] with (nolock) where   @@State = [State] And  @@Exhibit = [Exhibit] 
end
else
begin
select @msg = 'Not a valid Exhibit.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspStateExhibitVal] TO [public]
GO
