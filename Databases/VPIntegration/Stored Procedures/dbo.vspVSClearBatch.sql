SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspVSClearBatch]
/*****************************
*****************************/
(@batchid int)
as


delete vVSBI where BatchID=@batchid
delete bVSBD where BatchId=@batchid
delete bVSBH where BatchId=@batchid








GO
GRANT EXECUTE ON  [dbo].[vspVSClearBatch] TO [public]
GO
