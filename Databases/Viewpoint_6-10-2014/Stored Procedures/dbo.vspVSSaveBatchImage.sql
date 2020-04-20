SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  proc [dbo].[vspVSSaveBatchImage]
/********************************

********************************/
(@batchid int,@imageid int = null output,@pagenumber int = null output, @imagedata image)
as


if @imageid is null or @imageid=-1
	select @imageid = isnull(max(ImageID),0) + 1 from vVSBI where BatchID=@batchid 

if @pagenumber is null or @pagenumber=-1
	select @pagenumber = isnull(max(PageNumber),0) + 1 from vVSBI where BatchID=@batchid and ImageID=@imageid

if not exists(select top 1 1 from bVSBD where BatchId=@batchid and ImageID=@imageid)
		Insert bVSBD(BatchId, ImageID, PageCount, Attached) values(@batchid, @imageid, 0, 'N')


if not exists(select top 1 1 from vVSBI where BatchID=@batchid and ImageID=@imageid and PageNumber=@pagenumber)
	Insert vVSBI(BatchID, ImageID, PageNumber, ImageData) values(@batchid, @imageid, @pagenumber,@imagedata)
else
	update vVSBI
	set ImageData=@imagedata
	where BatchID=@batchid and ImageID=@imageid and PageNumber=@pagenumber


/*Update the Page Count*/
declare @pagecount int
select @pagecount = count(*)
from vVSBI
where BatchID=@batchid and ImageID=@imageid

update bVSBD
set PageCount = @pagecount
where BatchId=@batchid and ImageID=@imageid
GO
GRANT EXECUTE ON  [dbo].[vspVSSaveBatchImage] TO [public]
GO
