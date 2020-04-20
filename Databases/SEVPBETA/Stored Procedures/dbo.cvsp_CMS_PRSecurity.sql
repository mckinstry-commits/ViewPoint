SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_PRSecurity] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Copies PR Security and adds it back after refresh
	Created:	12.18.09
	Created by: JJH  
	Revisions:	1. None
**/


set @errmsg=''
set @rowcount=0


--delete existing records in holding table
if  exists (select name from CV_CMS_SOURCE.dbo.sysobjects where name='bPRGS2')
--delete existing records in holding table
delete bPRGS2 where PRCo=@toco;

--Insert records into temp table
insert into bPRGS2 select PRCo, PRGroup, VPUserName, UniqueAttchID 
from bPRGS;


--Delete records in VP table
delete bPRGS where PRCo=@toco;
insert into bPRGS 
select PRCo, PRGroup, VPUserName, UniqueAttchID 
from bPRGS2
where PRCo=@toco;



return @@error

GO
