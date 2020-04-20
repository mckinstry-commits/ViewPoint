SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspIMDeleteAutoImportQueueItem]
/**************************************************
Created By: RM 07/01/09

Purpose: Deletes an ImportQueue record
***************************************************/
(@seq int)
as 

delete from IMAutoImportQueue where Seq=@seq
	

GO
GRANT EXECUTE ON  [dbo].[vspIMDeleteAutoImportQueueItem] TO [public]
GO
