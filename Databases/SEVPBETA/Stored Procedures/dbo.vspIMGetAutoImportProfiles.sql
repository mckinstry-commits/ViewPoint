SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspIMGetAutoImportProfiles]
/**************************************************
Created By: RM 07/01/09

Purpose: Returns Auto Import Profiles.  If no profile name is passed, it returns all records.
***************************************************/
(@profilename varchar(20) = null )
as 

select * from IMAutoImportProfiles where ProfileName = ISNULL(@profilename, ProfileName)
	

GO
GRANT EXECUTE ON  [dbo].[vspIMGetAutoImportProfiles] TO [public]
GO
