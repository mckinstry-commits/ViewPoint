SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspVSMarkImageAttached]
(@batchid int, @imageid int, @isattached bYN, @msg varchar(255) output)
as

declare @rc int
set @rc=0

	update bVSBD set Attached=@isattached where BatchId=@batchid and ImageID=@imageid

return @rc


GO
GRANT EXECUTE ON  [dbo].[vspVSMarkImageAttached] TO [public]
GO
