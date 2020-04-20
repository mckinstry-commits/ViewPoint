SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*=============================================
--	Author:		JonathanP 
--	Create date: 01/07/2008
	Modified Date: 6/21/2011 - TK-07089 - AR - use sys.columns for a 3x performance increase
	
-- Description:	Checks if the given column is the only who value was updated. Returns 1 if the
--				specified column was the only one that updated.
--
-- To use: This function should only be called from an update trigger. When calling this function, 
--         pass in the result of COLUMNS_UPDATED() for @columnsUpdated, the name of the table that
--		   the trigger is on for @tableName, and the column you want to check for @columnName.
--		   
-- Example: To use this to check if only UniqueAttchID was updated in the update trigger for bEMCD... 
--				IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bEMCD', 'UniqueAttchID') = 1
--				BEGIN 
--					...do what you need to do...
--				END    
---- =============================================*/
CREATE FUNCTION [dbo].[vfOnlyColumnUpdated]
    (
      @columnsUpdated VARBINARY(500) ,
      @tableName VARCHAR(128) ,
      @columnName VARCHAR(128)
    )
RETURNS TINYINT
AS 
    BEGIN
	    DECLARE @OnlyColumnUpdated INT

	-- Check if any row was updated beside @columnName. 
        IF EXISTS ( SELECT  1
                    FROM    ( SELECT    sys.fn_IsBitSetInBitmask(@columnsUpdated,
                                                              COLUMNPROPERTY(OBJECT_ID(@tableName),
                                                              c.[name],
                                                              'ColumnID')) AS ColumnSet
                              FROM      sys.columns c
											
                              WHERE     c.[object_id] = OBJECT_ID(@tableName)
                                        AND c.[name] <> @columnName
                            ) AS UpdatedColumns
                    WHERE   ColumnSet <> 0 ) 
        BEGIN 
            SET @OnlyColumnUpdated = 0 -- Denotes false
        END
        ELSE 
        BEGIN
            SET @OnlyColumnUpdated = 1 -- Denotes true
		END
		
        RETURN @OnlyColumnUpdated
    END

GO
GRANT EXECUTE ON  [dbo].[vfOnlyColumnUpdated] TO [public]
GO
