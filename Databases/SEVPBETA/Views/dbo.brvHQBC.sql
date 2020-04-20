SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE View [dbo].[brvHQBC] as

select Co, Mth, BatchId, Source, TableName, InUseBy, DateCreated, CreatedBy, Status, PRGroup, PREndDate,
 DatePosted, DateClosed, Adjust, Rstrict, suser_sname() as username, UniqueAttchID

from HQBC
where (suser_sname() = CreatedBy or suser_sname() = InUseBy) and UniqueAttchID is not null


GO
GRANT SELECT ON  [dbo].[brvHQBC] TO [public]
GRANT INSERT ON  [dbo].[brvHQBC] TO [public]
GRANT DELETE ON  [dbo].[brvHQBC] TO [public]
GRANT UPDATE ON  [dbo].[brvHQBC] TO [public]
GO
