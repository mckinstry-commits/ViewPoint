SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspSpecTermsVal] /** User Defined Validation Procedure **/
(@Code varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/**Special Terms and Conditions for PO validation. **/
if exists(select * from [udSpecTerms] with (nolock) where   @Code = [Code] )
begin
select @msg = isnull(a.Text,@msg)
	from [udSpecTerms] a with (nolock) 
	where @Code = a.[Code] 
end
else
begin
select @msg = 'Not a valid Special Term', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspSpecTermsVal] TO [public]
GO
