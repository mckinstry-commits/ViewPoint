SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspBITargetDDFIVal]
/***********************************************************
* CREATED BY:	HH	01/11/2013 TK-20362
* MODIFIED BY:	
*				
* USAGE:
* Used in BI Operation Target to validate the Grouping Level 
* and Filter Field
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

(@TargetType varchar(30), @Seq int, @msg varchar(255) output)
as
set nocount on

declare @rcode int
set @rcode = 0


--Validate
if @TargetType is null or @TargetType = ''
begin
	select @msg = 'Missing Target Type.', @rcode = 1
	goto vspexit
end

if @Seq is null
begin
	select @msg = 'Missing Sequence.', @rcode = 1
	goto vspexit
end

if not exists(select * from BITargetDDFILookup where TargetType = @TargetType and Seq = @Seq)
begin
	select @msg = 'Seq ' + cast(@Seq as varchar(5)) + ' does not exists for Target Type ' + @TargetType, @rcode = 1
	goto vspexit
end

	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspBITargetDDFIVal] TO [public]
GO
