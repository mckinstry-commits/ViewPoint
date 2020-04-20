SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Created:
	10/03/07 JonathanP - Sets the InUseBy column for VSBH.

History:
	
	Inputs:
		@batchID - The batch ID of the record to set.
		@inUseBy - The value to set inUseBy to.
		@errorMessage - A string containing an error message if one occurred.

	Returns:
		@returnCode - 0 on success, 1 on failure.
*/

CREATE  proc [dbo].[vspVSSetInUseByColumnForVSBH]

(@batchID as int, @inUseBy as bVPUserName = null, @errorMessage as varchar(255) output)
as

declare @returnCode as int
select @returnCode = 0

-- Make sure the batchID is not null and that it exist in the table.
if @batchID is null 
begin
	select @errorMessage = 'Error: The specified Batch ID is null. Could not update the InUseBy column.'
	select @returnCode = 1
	goto vspExit
end

-- Update the InUseBy column for the passed in batchID.
update bVSBH set InUseBy = @inUseBy where BatchId = @batchID

-- If no rows were changed, set the error message.
if @@rowcount = 0
begin
	select @errorMessage = 'Error: The specified Batch ID does not exist. Could not update the InUseBy column.'
	select @returnCode = 1
	goto vspExit
end

vspExit:
	return @returnCode


GO
GRANT EXECUTE ON  [dbo].[vspVSSetInUseByColumnForVSBH] TO [public]
GO
