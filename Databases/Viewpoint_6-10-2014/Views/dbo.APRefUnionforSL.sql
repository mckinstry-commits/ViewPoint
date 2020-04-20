SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************************
*	Created by:	 DC  02/10/2009
*	Modified by:
*	Purpose:	 to display APRef from APHB, APTH, APUI
*	
*	
*	
*	
*	
*	
*****************************************************/

CREATE VIEW [dbo].[APRefUnionforSL]
AS

SELECT Co as APCo, APRef
	FROM APHB
	WHERE isnull(APRef,'') <> ''
UNION
SELECT APCo, APRef  
	FROM APTH
	WHERE isnull(APRef,'') <> ''
UNION
SELECT APCo, APRef  
	FROM APUI
	WHERE isnull(APRef,'') <> ''



GO
GRANT SELECT ON  [dbo].[APRefUnionforSL] TO [public]
GRANT INSERT ON  [dbo].[APRefUnionforSL] TO [public]
GRANT DELETE ON  [dbo].[APRefUnionforSL] TO [public]
GRANT UPDATE ON  [dbo].[APRefUnionforSL] TO [public]
GRANT SELECT ON  [dbo].[APRefUnionforSL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APRefUnionforSL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APRefUnionforSL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APRefUnionforSL] TO [Viewpoint]
GO
