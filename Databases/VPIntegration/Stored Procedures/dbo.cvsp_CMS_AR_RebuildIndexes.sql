SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create proc [dbo].[cvsp_CMS_AR_RebuildIndexes] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as

/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Rebuild AR and JCID Indexes
  	Created:	9.2.09
	Created by: JRE        
	Revisions:	1. None
**/



set @errmsg=''
set @rowcount=0

ALTER INDEX ALL ON bJCID
REBUILD WITH (FILLFACTOR = 90, SORT_IN_TEMPDB = ON,  STATISTICS_NORECOMPUTE = ON);

ALTER INDEX ALL ON bCMDT
REBUILD WITH (FILLFACTOR = 90, SORT_IN_TEMPDB = ON,  STATISTICS_NORECOMPUTE = ON);

ALTER INDEX ALL ON bARTL
REBUILD WITH (FILLFACTOR = 90, SORT_IN_TEMPDB = ON,  STATISTICS_NORECOMPUTE = ON);

ALTER INDEX ALL ON bARTH
REBUILD WITH (FILLFACTOR = 90, SORT_IN_TEMPDB = ON,  STATISTICS_NORECOMPUTE = ON);

ALTER INDEX ALL ON CV_CMS_SOURCE.dbo.ARTOPC
REBUILD WITH (FILLFACTOR = 90, SORT_IN_TEMPDB = ON,  STATISTICS_NORECOMPUTE = ON);

ALTER INDEX ALL ON CV_CMS_SOURCE.dbo.ARTOPD
REBUILD WITH (FILLFACTOR = 90, SORT_IN_TEMPDB = ON,  STATISTICS_NORECOMPUTE = ON);


ALTER INDEX ALL ON CV_CMS_SOURCE.dbo.APTOPC REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON CV_CMS_SOURCE.dbo.APTOPD REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);


return @@error

GO
