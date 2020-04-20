SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create proc [dbo].[cvs_CMS_TriggerCheck] 

as



/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Check to see if any triggers are disabled
	Created:	11.25.09
	Created by:	JJH
	Revisions:	1. None
**/



select * from Viewpoint.sys.triggers where is_disabled=1









GO
