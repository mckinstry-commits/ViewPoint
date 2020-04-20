SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspVSGetBatchImagePages]
/********************************

********************************/
(@batchid int, @imageid int)
as


select PageNumber from vVSBI where BatchID=@batchid and ImageID=@imageid order by PageNumber





GO
GRANT EXECUTE ON  [dbo].[vspVSGetBatchImagePages] TO [public]
GO
