SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc dbo.vspVSGetBatchImage
/********************************

********************************/
(@batchid int, @imageid int)
as


select ImageData from vVSBI where BatchID=@batchid and ImageID=@imageid
GO
GRANT EXECUTE ON  [dbo].[vspVSGetBatchImage] TO [public]
GO
