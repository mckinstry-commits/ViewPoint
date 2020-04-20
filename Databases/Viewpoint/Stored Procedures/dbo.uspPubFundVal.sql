SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[uspPubFundVal] /** User Defined Validation Procedure **/
(@PFSequence varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udPublicFundTrail] with (nolock) where   @PFSequence = [Seq] )
begin
select @msg = isnull([Description],@msg) from [udPublicFundTrail] with (nolock) where   @PFSequence = [Seq] 
end
else
begin
select @msg = 'Not a valid Public Fund Trail', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspPubFundVal] TO [public]
GO
