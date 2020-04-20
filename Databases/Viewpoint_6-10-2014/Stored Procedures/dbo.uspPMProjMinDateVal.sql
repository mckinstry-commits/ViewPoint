SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspPMProjMinDateVal] /** User Defined Validation Procedure **/
(@InputDate varchar(100), @MinDate varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0

IF @InputDate < @MinDate
BEGIN
SET @msg = 'Must be less than end date'
SET @rcode=1
GOTO spexit
END

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspPMProjMinDateVal] TO [public]
GO
