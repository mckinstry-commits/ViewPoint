SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspVSGetBatchImagePage]
/********************************

********************************/
(@batchid int, @imageid int, @pagenumber int)
as


select ImageData from vVSBI where BatchID=@batchid and ImageID=@imageid and PageNumber=@pagenumber






GO
GRANT EXECUTE ON  [dbo].[vspVSGetBatchImagePage] TO [public]
GO
