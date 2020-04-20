SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPDeleteQueryColumns]
		/***********************************************************
		* CREATED BY:   CC 09/24/2008
		* MODIFIED BY:  
		*
		* Usage: Inserts new columns associated with a query
		*	
		*
		* Input params:
		*	@QueryName
		*	
		*
		* Output params:
		*	
		*
		* Return code:
		*
		*	
		************************************************************/

		@QueryName VARCHAR(50) = NULL		
AS

SET NOCOUNT ON

DELETE FROM VPGridColumns WHERE QueryName = @QueryName


GO
GRANT EXECUTE ON  [dbo].[vspVPDeleteQueryColumns] TO [public]
GO
