SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create proc [dbo].[cvsp_CMS_GL_RebuildIndexes] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as

/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title: Defragment GL Table Indices
  	Created on:	9.2.09
	Created by:         
	Revisions:	1. None
**/



set @errmsg=''
set @rowcount=0

alter index ALL on bGLBD  REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
alter index ALL on bGLFY  REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
alter index ALL on bGLYB  REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
alter index ALL on bGLDT  REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
alter index ALL on bGLAS  REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
alter index ALL on bGLRB  REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
alter index ALL on bGLRF  REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
alter index ALL on bGLBR  REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
alter index ALL on bGLAC  REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
alter index ALL on bGLAJ  REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
alter index ALL on bGLBL  REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);

return @@error

GO
