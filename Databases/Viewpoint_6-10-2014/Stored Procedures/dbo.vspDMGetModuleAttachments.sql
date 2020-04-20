SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Created:
	05/24/07 JonathanP - Returns a result set of all the AttachmentIDs in HQAT for the given module list.

History:
	06/14/07 JonathanP - added "and UnqiueAttchID is not null" to the where clause to not include records that have a null UniqueAttchID.
	03/27/08 JonathanP - added "and CurrentState = 'A'" to the where clause to only include attached attachments.

	Inputs:
		@modulelist - should have this format: "AP,EM"
*/

CREATE  proc [dbo].[vspDMGetModuleAttachments]

(@modulelist as varchar(255), @msg as varchar(255) = '' output)
as

declare @rcode as int
select @rcode = 0

Select * From HQAT 
Where Left(TableName, 2) in (select Names from dbo.vfTableFromArray(@modulelist)) and UniqueAttchID is not null and CurrentState = 'A'
order by AttachmentID

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDMGetModuleAttachments] TO [public]
GO
