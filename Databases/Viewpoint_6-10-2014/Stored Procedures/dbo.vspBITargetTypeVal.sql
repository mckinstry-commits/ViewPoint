SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspBITargetTypeVal]
/***********************************************************
* CREATED BY:	HH	12/17/2012 TK-20362
* MODIFIED BY:	
*				
* USAGE:
* Used in BI Operation Target to validate the Target Type
*
* INPUT PARAMETERS
*   Company
*   TargetType
*
* OUTPUT PARAMETERS
*   @msg		error message
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@Company bCompany, @TargetType varchar(40), @msg varchar(255) output)
as
set nocount on

declare @rcode int
set @rcode = 0


--Validate
if @Company is null
begin
	select @msg = 'Missing Company.', @rcode = 1
	goto vspexit
end

if @TargetType is null
begin
	select @msg = 'Missing Target Type.', @rcode = 1
	goto vspexit
end

if not exists(select * from DDFHShared where Form = @TargetType)
begin
	select @msg = 'Target Type ' + @TargetType + ' does not exist.', @rcode = 1
	goto vspexit
end

	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspBITargetTypeVal] TO [public]
GO
