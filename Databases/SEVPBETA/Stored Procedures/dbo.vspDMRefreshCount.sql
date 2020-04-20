SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDMRefreshCount]
/*************************************************
Created: JonathanP 06/05/07 - Adapted from bspHQRefreshCount   	
History: JonathanP 06/13/07 - Now returns the number of attachments to refresh, not the number of indexes.
		 JonathanP 03/27/08 - See issue #127602. Only attachments with a current state of 'A' (attached) 
							  will be counted, since we can only refresh attached attachments.
		 CC			06/09/09 - Issue #133883, modified query to return set based results, removed unused parameters

History from bspHQRefreshCount:
Created: 08/20/02 - RM
Modified: 08/03/06 - RM Issue 122067

Usage:
	Returns a count of how many records will be reindexed.

Pass-in:

Returns: 


*************************************************/
AS 
BEGIN   
	SELECT	  COUNT (*) AS 'AttachmentCount'
			, UPPER(LEFT(T.TableName,2)) AS 'Mod'
	FROM HQAT T 		
	WHERE T.CurrentState = 'A'
	GROUP BY UPPER(LEFT(T.TableName,2))
 
END
GO
GRANT EXECUTE ON  [dbo].[vspDMRefreshCount] TO [public]
GO
