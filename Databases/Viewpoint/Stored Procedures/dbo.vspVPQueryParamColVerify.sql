SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPQueryParamColVerify]

/******************************************************  
* CREATED BY:  DK   
* MODIFIED By: HH 5/30/2012 TK-15193 added ExcludeFromQuery check  
*  
* Usage:  Validates a Column input on the Params entry
*   
*  
* Input params:  
* @QueryName - Query Name 
* @ColName -  Column Name 
*   
*   
* Output params:  
* @msg  Code description or error message  
*  
* Return code:  
* 0 = success, 1 = failure  
*******************************************************/  
  
@QueryName VARCHAR(50), @ColName VARCHAR(150), @msg VARCHAR(100) OUTPUT  
AS  
BEGIN  
	SET NOCOUNT ON  

	IF @QueryName IS NULL 
		BEGIN
			SET @msg = @QueryName + ' is not a valid Query'
			RETURN 1
		END 

	IF @ColName IS NULL 
		BEGIN
			SET @msg = 'Value may not be blank'
			RETURN 1
		END;
		
	-- Verification Query 
	-- Get all columns and then filter based on @ColName
	WITH GetAllColumns AS
	(
		SELECT	ColumnName 
		FROM	VPGridColumns 
		WHERE	QueryName = @QueryName
				AND ExcludeFromQuery = 'N'
		
		UNION 
		
		SELECT	'Default' AS ColumnName
	)
	SELECT	ColumnName 
	FROM	GetAllColumns
	WHERE	ColumnName = @ColName

	IF @@rowcount = 0  
    BEGIN  
		SET @msg = @ColName + ' is not a valid Value.'  
		RETURN 1  
    END 
	
	RETURN 0
END 
GO
GRANT EXECUTE ON  [dbo].[vspVPQueryParamColVerify] TO [public]
GO
