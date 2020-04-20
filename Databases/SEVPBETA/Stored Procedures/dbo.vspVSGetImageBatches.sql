SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
*	Created by: ???
*	Modified by: JonathanP 09-26-07 - Uncommented "h.InUseBy" in the select statement. Now, Ithe nUseBy column will be returned in the result 
*									  set. This was for issue 125563.										
*/


CREATE proc [dbo].[vspVSGetImageBatches]
/********************************
********************************/
(@onlycurrentuser bYN)
as


select h.BatchId, h.Description, h.CreatedDate, h.CreatedBy, h.InUseBy, h.Restricted, 
(Select count(*) from VSBD where BatchId=h.BatchId) as DocCount, 
(select count(*) from VSBD where BatchId=h.BatchId and Attached='N') as UnattachedCount
from VSBH h 
where h.CreatedBy = case @onlycurrentuser when 'Y' then suser_sname() else h.CreatedBy end








GO
GRANT EXECUTE ON  [dbo].[vspVSGetImageBatches] TO [public]
GO
