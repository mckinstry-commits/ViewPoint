SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspIMGetNotificationInfo]
/**************************************************
Created By: RM 07/01/09

Purpose: Returns notification info, based on the template, and whether the import was successful.
***************************************************/
(@template varchar(10), @successfulimport char(1) )
as 


	select  ISNULL(p.EMail, n.DestinationName) as DestinationName, NotifyOnSuccess, NotifyOnFailure, AttachLogFile
	from IMNotifications n 
		left outer join DDUP p 
		on n.DestinationName=p.VPUserName 
			and n.DestinationType='V' 
	where n.ImportTemplate=@template 
		and 'Y' = case @successfulimport when 'Y' then NotifyOnSuccess else NotifyOnFailure end
	

GO
GRANT EXECUTE ON  [dbo].[vspIMGetNotificationInfo] TO [public]
GO
