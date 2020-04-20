SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspIMInsertAutoImportQueueItem]
/**************************************************
Created By: RM 07/01/09

Purpose: Inserts an ImportQueue item.
***************************************************/
(@profile varchar(20), @filename varchar(256))
as 

--Prevent duplicate entries for the same file, since the file will be removed once processed.
if not exists(select top 1 1 from IMAutoImportQueue where FileName=@filename)
begin
	insert IMAutoImportQueue(ImportProfile, FileName) values(@profile, @filename)
end	
	

GO
GRANT EXECUTE ON  [dbo].[vspIMInsertAutoImportQueueItem] TO [public]
GO
