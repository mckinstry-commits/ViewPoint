SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[bspPMVCColumnNameVal]
/***********************************************************
 * CREATED BY:	GF 03/31/2004
 * MODIFIED BY:	GF 12/30/2008 - issue #131549 do not allow columns that are key fields.
 *				AMR - 6/27/11 - TK-06411, Fixing performance issue by using an inline table function.
 *
 *
 *
 * USAGE:
 * validates PM Grid View Column name to table view
 *
 * PASS:
 * ObjectTable		Grid View Table
 * ColumnName		Column name for table to be validated
 *
 *
 * RETURNS:
 * ErrMsg if any
 * 
 * OUTPUT PARAMETERS
 *   @msg     Error message if invalid, 
 * RETURN VALUE
 *   0 Success
 *   1 fail
 *****************************************************/
    (
      @tableview VARCHAR(20),
      @columnname VARCHAR(128),
      @form VARCHAR(30),
      @viewname VARCHAR(10),
      @msg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON

    DECLARE @rcode INT,
        @object_id INT

    SELECT  @rcode = 0

    IF ISNULL(@columnname, '') = '' 
        BEGIN
            SELECT  @msg = 'Missing column name.',
                    @rcode = 1
            RETURN @rcode
        END


---- validate table view to INFORMATION_SCHEMA.VIEWS
    IF NOT EXISTS ( SELECT  TABLE_NAME
                    FROM    INFORMATION_SCHEMA.VIEWS
                    WHERE   TABLE_NAME = @tableview ) 
        BEGIN
            SELECT  @msg = 'Table view does not exist in information schema views: '
                    + ISNULL(@tableview, '') + ' !',
                    @rcode = 1
            RETURN @rcode
        END

---- validate column name in INFORMATION_SCHEMA.COLUMNS
    IF NOT EXISTS ( SELECT  TABLE_NAME
                    FROM    INFORMATION_SCHEMA.COLUMNS
                    WHERE   TABLE_NAME = @tableview
                            AND COLUMN_NAME = @columnname ) 
        BEGIN
            SELECT  @msg = 'Column does not exist for this table view: '
                    + ISNULL(@tableview, '') + ' Column: '
                    + ISNULL(@columnname, '') + ' .',
                    @rcode = 1
            RETURN @rcode
        END

---- verify that the column title is unique for the grid form
    IF EXISTS ( SELECT	1
                FROM    PMVC
                WHERE   ViewName = @viewname
                        AND Form = @form
                        AND TableView = @tableview
                        AND ColumnName = @columnname ) 
        BEGIN
            SELECT  @msg = 'Column Name: ' + ISNULL(@columnname, '')
                    + ' must be unique for the grid form.',
                    @rcode = 1
            RETURN @rcode
        END

---- check DDFI key field grid column headings
    IF EXISTS ( SELECT	1
				-- use inline table function for perf
                FROM    dbo.vfDDFIShared(@form)
                WHERE   ViewName = @tableview
                        AND ColumnName = @columnname ) 
        BEGIN
            SELECT  @msg = 'Column Name: ' + ISNULL(@columnname, '')
                    + ' already exists as a grid key column.',
                    @rcode = 1
            RETURN @rcode
        END

    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMVCColumnNameVal] TO [public]
GO
