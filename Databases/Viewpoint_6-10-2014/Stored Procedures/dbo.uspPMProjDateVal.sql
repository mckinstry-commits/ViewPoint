SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspPMProjDateVal] /** User Defined Validation Procedure **/
(@InputDate varchar(100), @MaxDate varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [JCJMPM] with (nolock) where   @InputDate <= @MaxDate )
begin
select @msg = isnull(null,@msg) 
end
else
begin
select @msg = 'Must be greater than start date.', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspPMProjDateVal] TO [public]
GO
