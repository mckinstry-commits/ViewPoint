SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspBITargetSourceVal]
/***********************************************************
* CREATED BY:	HH	12/17/2012 TK-20362
* MODIFIED BY:	
*				
* USAGE:
* Used in BI Operation Target Copy to validate the Target Source
*
* INPUT PARAMETERS
*   Company
*   TargetSource
*
* OUTPUT PARAMETERS
*   @msg		error message
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@Company bCompany, @TargetSource varchar(50), @msg varchar(255) output)
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

if @TargetSource is null
begin
	select @msg = 'Missing Source Target.', @rcode = 1
	goto vspexit
end

if not exists(select * from BITargetHeader where BICo = @Company and TargetName = @TargetSource)
begin
	select @msg = 'Source Target ' + @TargetSource + ' does not exist.', @rcode = 1
	goto vspexit
end

	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspBITargetSourceVal] TO [public]
GO
