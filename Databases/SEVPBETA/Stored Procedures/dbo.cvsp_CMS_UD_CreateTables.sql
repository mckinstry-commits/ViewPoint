SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Create all UD cross reference tables 
	Created:	01.30.12
	Created by:	CR
	Revisions:	1. 03/20/2012 BBA - Added cvsp_CMS_UD_xrefAPVendor.
	            2. 03/28/13 changed calls to match script we have seems to be issue with  non updated ud scripts
*/



Create proc [dbo].[cvsp_CMS_UD_CreateTables]
as

DECLARE @rc INT

DECLARE @Today SMALLDATETIME

SET @Today = GETDATE()

exec   dbo.cvsp_UD_ConversionTracker ;

exec   dbo.cvsp_CMS_UD_xrefCustomerDefaults @Today;
                  
exec  dbo.cvsp_CMS_UD_xrefCostType @Today;

exec  dbo.cvsp_CMS_UD_xrefEMCostCodes @Today;

exec dbo.cvsp_CMS_UD_xrefEMCostType @Today;

exec  dbo.cvsp_CMS_UD_xrefGLAcct @Today;

exec @rc= dbo.cvsp_CMS_UD_xrefGLAcctTypes @Today;

exec @rc= dbo.cvsp_CMS_UD_xrefGLJournals @Today;

exec @rc= dbo.cvsp_CMS_UD_xrefInsState @Today;

exec @rc= dbo.cvsp_CMS_UD_xrefJCDept @Today;

exec @rc= dbo.cvsp_CMS_UD_xrefPhase @Today;

exec @rc= dbo.cvsp_CMS_UD_xrefPRDedLiab @Today;

exec @rc= dbo.cvsp_CMS_UD_xrefPRDept @Today;

exec @rc= dbo.cvsp_CMS_UD_xrefPREarn @Today;

exec @rc= dbo.cvsp_CMS_UD_xrefPRGroup @Today;

exec @rc= dbo.cvsp_CMS_UD_xrefUnions ;

exec @rc= dbo.cvsp_CMS_UD_xrefUM @Today;











GO
