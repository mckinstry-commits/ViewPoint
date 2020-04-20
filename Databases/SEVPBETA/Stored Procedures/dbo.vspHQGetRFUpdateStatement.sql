SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.vspHQGetRFUpdateStatement    04/13/2011 16:18:30 ******/
CREATE proc [dbo].[vspHQGetRFUpdateStatement]
/***********************************************************
* CREATED BY	: GarthT 4/13/2011
* MODIFIED BY	: 
* USED IN:
*
* USAGE:
*		Generates dynamic sql update statement using the viewname.columname based 
*		on the predicate keys.
*
* INPUT PARAMETERS
*   @viewname
*	@columnname
*	@predicatekeysxml
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURNS VALUE (3 Result Sets)
*   
*   ResultSet1 Update Statement
*	ResultSet2 Update Predicate Parameters
*	ResultSet3 Update Value Parameter
*	
*****************************************************/
(
	@viewname VARCHAR(30),			--  1
	@columnname VARCHAR(30),		--  3
	@predicatekeysxml VARCHAR(1024),--  4
	@msg VARCHAR(255) OUTPUT		--	5
)		
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    DECLARE @rcode INT,
		@hDoc INT,
		@predicatecount INT,
		@value NVARCHAR(max), 
		@sql NVARCHAR(max), 
		@updateClause NVARCHAR(max), 
		@setClause NVARCHAR(max), 
		@whereClause NVARCHAR(max), 
		@errmsg VARCHAR(255)
    
    DECLARE @PredicateTable TABLE ([ColumnName] VARCHAR(60))
    
	EXEC sp_xml_preparedocument @hDoc OUTPUT, @predicatekeysxml
	
	-- Security: Check to see if viewname is a defined DocumentObject ObjectTable.
    IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.HQWO WHERE [ObjectTable] = @viewname)
    BEGIN
		SELECT @msg = 'No defined HQWO record with ' + QuoteName(@viewname) + 
					  '. Required to be considered a valid target for update.' 
		GOTO vspexit
    END
    
	-- Security: Verify columnname belongs to view.
	IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = @viewname AND c.COLUMN_NAME = @columnname)
    BEGIN
		SELECT @msg = QuoteName(@columnname) + ' not defined in view ' + QuoteName(@viewname)+ '.'
		GOTO vspexit
    END
	
	-- Security: Verify predicateKey columns belong to view.
	
	INSERT INTO @PredicateTable 
	SELECT * FROM OPENXML( @hDoc, '/PredicateKeys/KeyValue',2)
	WITH (  [ColumnName] varchar(60) '@ColumnName')	        
	
	-- Construct where clause
	SELECT @predicatecount = Count(*) FROM @PredicateTable
	SELECT @whereClause = 'WHERE '
	SELECT @whereClause = @whereClause + 
						  QUOTENAME(ColumnName) + ' = @' + ColumnName +
						  CASE WHEN Row_Number() OVER (ORDER BY [ColumnName]) < @predicatecount 
							THEN ' AND ' ELSE '' 
						  END
	FROM @PredicateTable


	-- Construct complete update statement
	SELECT @updateClause = 'UPDATE [dbo].' + QUOTENAME(@viewname)  
	SELECT @setClause = ' SET ' + QUOTENAME(@columnname) + ' = @' + @columnname + ' '	
	SELECT @sql = @updateClause + @setClause + @whereClause	

	-- Return results sets
	-- First set is the Update Statement (SQL)
	SELECT @sql AS UpdateStatement
	
	-- Second set is the Predicate Paramaters
	SELECT [ColumnName] AS Name, 
			c.DATA_TYPE AS [Type],
			c.CHARACTER_MAXIMUM_LENGTH AS [Length],
			c.NUMERIC_PRECISION AS [Precision],
			c.DOMAIN_NAME As [Domain]
	FROM @PredicateTable p
		INNER JOIN INFORMATION_SCHEMA.COLUMNS c 
		ON c.TABLE_NAME = @viewname AND c.COLUMN_NAME = p.ColumnName
	
	-- Third set is the Value Paramaters
	SELECT  @columnname AS Name, 
			c.DATA_TYPE AS [Type],
			c.CHARACTER_MAXIMUM_LENGTH AS [Length],
			c.NUMERIC_PRECISION AS [Precision],
			c.DOMAIN_NAME As [Domain]
	FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = @viewname AND c.COLUMN_NAME = @columnname

vspexit:

	-- Cleanup server XML document resource
	EXEC sp_xml_removedocument @hDoc 

	RETURN @rcode

END


GO
GRANT EXECUTE ON  [dbo].[vspHQGetRFUpdateStatement] TO [public]
GO
