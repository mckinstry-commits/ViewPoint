SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].vspVPMenuGetSiteSettings
/******************************************************************************
* Created: KSE 05/6/2013
* Last Modified: 
*
* Get the site setting information
*
* Inputs:
*	<none>	
*
* Output:
*	resultset - the row of site settings from DDVS.
*
*******************************************************************************
* Modified:
*******************************************************************************/

as

set nocount on 

select * from DDVS

GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetSiteSettings] TO [public]
GO
