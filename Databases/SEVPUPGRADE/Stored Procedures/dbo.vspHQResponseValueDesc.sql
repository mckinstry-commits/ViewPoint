SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspHQResponseValueDesc]
/***********************************************************
* CREATED BY:	GP	03/19/2011 - V1# B-03634
* MODIFIED BY:	
*				
* USAGE:
* Used in HQ Response Values to return the desc for existing records.
*
* INPUT PARAMETERS
*   PMCo   
*   Contract
*
* OUTPUT PARAMETERS
*   @msg      Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@ValueCode varchar(20), @msg varchar(255) output)
as
set nocount on

declare @rcode int
set @rcode = 0


--Validate
if @ValueCode is null
begin
	select @msg = 'Missing Value Name.', @rcode = 1
	goto vspexit
end


--Get Description
select @msg = [Description] from dbo.HQResponseValue where @ValueCode = ValueCode

	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQResponseValueDesc] TO [public]
GO
