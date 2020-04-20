SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspIMAutoImportPickupDirectoryVal]
/**************************************************
Created By: RM 07/01/09

Purpose: Validate the directory to make sure it doesn't already exist in another record.
***************************************************/
(@profilename varchar(20), @directoryname varchar(1024), @msg varchar(255) = null output)
as 

declare @rcode int
select @rcode = 0

if exists(select top 1 1 from IMAutoImportProfiles where PickupDirectory=@directoryname and ProfileName<>@profilename)
begin
	select @msg = 'Pickup directory already exists in another Import Profile.  Pickup directories must be unique.', @rcode=1
	goto vspexit
end
	
	
vspexit:
return @rcode

	
	

GO
GRANT EXECUTE ON  [dbo].[vspIMAutoImportPickupDirectoryVal] TO [public]
GO
