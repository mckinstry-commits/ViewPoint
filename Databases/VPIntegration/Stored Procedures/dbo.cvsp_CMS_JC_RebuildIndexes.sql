SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure  [dbo].[cvsp_CMS_JC_RebuildIndexes] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Rebuild JC Indexes
	Created:	
	Created by:	JRE 
	Revisions:	1. none


**/


ALTER INDEX ALL ON bJCID REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCIP REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCJM REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCJP REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCOD REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCPB REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCPC REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCPM REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCCD REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCCH REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCCI REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCTI REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCCP REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
ALTER INDEX ALL ON bJCCM REBUILD WITH (FILLFACTOR = 85, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
GO
