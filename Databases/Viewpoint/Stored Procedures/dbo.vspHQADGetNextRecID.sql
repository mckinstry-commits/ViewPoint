SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--select * from bHQAD\


CREATE proc [dbo].[vspHQADGetNextRecID]
/***********************************
Created: RM 01/30/07

Use: Generates the next RecID for HQAD

***********************************/
(@newrecid int output)
as

set nocount on
declare @rcode int
select @rcode = 1

select @newrecid = isnull(Max(RecID), 0) + 1, @rcode = 0 from bHQAD

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQADGetNextRecID] TO [public]
GO
