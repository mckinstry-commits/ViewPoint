SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspBITargetDestinationVal]
/***********************************************************
* CREATED BY:	HH	12/17/2012 TK-20362
* MODIFIED BY:	
*				
* USAGE:
* Used in BI Operation Target Copy to validate the Target Destination
*
* INPUT PARAMETERS
*   Company
*   TargetDestination
*
* OUTPUT PARAMETERS
*   @msg		error message
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@Company bCompany, @TargetDestination varchar(50), @msg varchar(255) output)
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

if @TargetDestination is null
begin
	select @msg = 'Missing Destination Target.', @rcode = 1
	goto vspexit
end

if exists(select * from BITargetHeader where BICo = @Company and TargetName = @TargetDestination)
begin
	select @msg = 'Destination Target ' + @TargetDestination + ' already exists.', @rcode = 1
	goto vspexit
end

	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspBITargetDestinationVal] TO [public]
GO
