SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create proc [dbo].[cvsp_CMS_MASTER_GLPI] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
===========================================================================
	Title:		GL Part Instances
	Created:	02.05.10
	Created by: JJH
	Revisions:	1. None
**/


set @errmsg=''
set @rowcount=0

-- delete existing trans
alter table bGLPI disable trigger all;

alter table bGLPI NOCHECK CONSTRAINT FK_bGLPI_bGLPD_GLCoPartNo;


BEGIN tran
delete from bGLPI where GLCo=@toco
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bGLPI (GLCo, PartNo, Instance, Description,udSource,udConv)

--Part 1
select distinct @toco
	, PartNo=1
	, Instance=GLAC.Part1
	, Description=GLAC.Part1
	, udSource ='MASTER_GLPI'
	, udConv='Y'
from bGLAC GLAC 
where GLAC.GLCo=@toco
	and GLAC.Part1 is not null

union all

--Part 2
select distinct @toco
	, PartNo=2
	, Instance=GLAC.Part2
	, Description=GLAC.Part2
	, udSource ='MASTER_GLPI'
	, udConv='Y'
from bGLAC GLAC 
where GLAC.GLCo=@toco 
	and GLAC.Part2 is not null

union all

--Part 3
select distinct @toco
	, PartNo=3
	, Instance=GLAC.Part3
	, Description=GLAC.Part3
	, udSource ='MASTER_GLPI'
	, udConv='Y'
from bGLAC GLAC 
where GLAC.GLCo=@toco 
	and GLAC.Part3 is not null

union all

--Part 4
select distinct @toco
	, PartNo=4
	, Instance=GLAC.Part4
	, Description=GLAC.Part4
	, udSource ='MASTER_GLPI'
	, udConv='Y'
from bGLAC GLAC 
where GLAC.GLCo=@toco 
	and GLAC.Part4 is not null

union all

--Part 5
select distinct @toco
	, PartNo=5
	, Instance=GLAC.Part5
	, Description=GLAC.Part5
	, udSource ='MASTER_GLPI'
	, udConv='Y'
from bGLAC GLAC 
where GLAC.GLCo=@toco 
	and GLAC.Part5 is not null

union all

--Part 6
select distinct @toco
	, PartNo=6
	, Instance=GLAC.Part6
	, Description=GLAC.Part6
	, udSource ='MASTER_GLPI'
	, udConv='Y'
from bGLAC GLAC 
where GLAC.GLCo=@toco 
	and GLAC.Part6 is not null
	


select @rowcount=@@rowcount


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bGLPI enable trigger all;
alter table bGLPI CHECK CONSTRAINT FK_bGLPI_bGLPD_GLCoPartNo;

return @@error

GO
