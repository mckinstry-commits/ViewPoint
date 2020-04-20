SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspIMGetAutoImportQueue]
/**************************************************
Created By: RM 07/01/09

Purpose: returns current records in import queue, so that they can be processed.
***************************************************/
as 

select * from IMAutoImportQueue
	

GO
GRANT EXECUTE ON  [dbo].[vspIMGetAutoImportQueue] TO [public]
GO
