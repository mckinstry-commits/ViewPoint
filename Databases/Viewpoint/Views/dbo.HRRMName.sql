SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /**************************
   *
   *	Created by MH
   *	Created 2004
   *
   *	Purpose:  Returns Full name from HRRM.
   *
   *
   *
   *
   ***************************/
   
--   ALTER    VIEW [dbo].[HRRMName]
--   AS
--   SELECT     top 100 percent HRCo, HRRef, ISNULL(LastName, '') + ', ' + ISNULL(FirstName, '') +  ISNULL(', ' + MiddleName, '') AS FullName
--   FROM         dbo.bHRRM with (nolock) order by HRCo, HRRef
--   

	CREATE    VIEW [dbo].[HRRMName]
	AS
	select top 100 percent HRCo, HRRef, 		   
	(case when Suffix is null then isnull(LastName, '') + ', ' + isnull(FirstName, '') + ' ' + isnull(MiddleName, '')
	else isnull(LastName, '') + ' ' + Suffix + ', ' + isnull(FirstName,'') + ' ' + isnull(MiddleName,'') end) as FullName
	FROM dbo.bHRRM with (nolock) order by HRCo, HRRef

GO
GRANT SELECT ON  [dbo].[HRRMName] TO [public]
GRANT INSERT ON  [dbo].[HRRMName] TO [public]
GRANT DELETE ON  [dbo].[HRRMName] TO [public]
GRANT UPDATE ON  [dbo].[HRRMName] TO [public]
GO
