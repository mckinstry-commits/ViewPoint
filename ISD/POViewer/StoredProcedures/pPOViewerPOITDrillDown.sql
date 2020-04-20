if exists (select * from sysobjects where id = object_id(N'pPOViewerPOITDrillDown') and sysstat & 0xf = 4) drop procedure pPOViewerPOITDrillDown 
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- This stored procedure will return query result based on 
-- the passed in select, search and ORDER BY clauses.
CREATE PROCEDURE pPOViewerPOITDrillDown
        @p_select_str nvarchar(4000),
        @p_is_distinct int,
        @p_select_str_b nvarchar(4000),
        @p_join_str nvarchar(4000),
        @p_where_str nvarchar(4000),
        @p_sort_str nvarchar(4000),
        @p_page_number int,
        @p_batch_size int
AS
DECLARE
    @l_create_temp nvarchar(4000),
    @l_temp_insert nvarchar(4000),
    @l_temp_select nvarchar(max),
    @l_temp_from nvarchar(4000),
    @l_final_sort nvarchar(4000),
    @l_query_select nvarchar(max),
    @l_query_from nvarchar(4000),
    @l_query_where nvarchar(max),
    @l_from_str nvarchar(4000),
    @l_join_str nvarchar(4000),
    @l_sort_str nvarchar(4000),
    @l_where_str nvarchar(4000),
    @l_count_query nvarchar(4000),
    @l_end_gen_row_num integer,
    @l_start_gen_row_num integer,
    @l_select_str nvarchar(4000),
    @l_temp_col nvarchar(4000),
    @l_insert_to_temp nvarchar(4000),
    @l_temp_col_name nvarchar(200),
    @l_temp_col_type nvarchar(20),
    @l_temp_col_precision nvarchar(10),
    @l_temp_col_scale nvarchar(10),
    @l_temp_col_char_max nvarchar(10),
    @l_temp_col_type_query nvarchar(500),
    @l_temp_col_type_query_params nvarchar(200)
BEGIN
    SET NOCOUNT ON

        -- Extract the select column.
        SET @l_temp_col = @p_select_str_b
        -- Get the select column name without alias
        SET @l_select_str = SUBSTRING(@l_temp_col, PATINDEX('%.%', @l_temp_col) + 1, LEN(@l_temp_col))

        -- Get the select column name without brackets
        SET @l_temp_col_name = REPLACE(REPLACE(@l_select_str, '[', ''), ']', '')

        -- Run a query to get the select column type
        SET @l_temp_col_type_query = N'SELECT @data_type_out = DATA_TYPE, @precision_out = NUMERIC_PRECISION, @scale_out = NUMERIC_SCALE, @max_out = CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=''POIT'' and COLUMN_NAME = ' + '''' + @l_temp_col_name + ''''
        SET @l_temp_col_type_query_params = N'@data_type_out varchar(20) OUTPUT, @precision_out varchar(10) OUTPUT, @scale_out varchar(10) OUTPUT, @max_out varchar(10) OUTPUT'
        EXECUTE sp_executesql
        @l_temp_col_type_query,
        @l_temp_col_type_query_params,
        @data_type_out = @l_temp_col_type OUTPUT,
        @precision_out = @l_temp_col_precision OUTPUT,
        @scale_out = @l_temp_col_scale OUTPUT,
        @max_out = @l_temp_col_char_max OUTPUT

        IF @l_temp_col_type = 'numeric' OR @l_temp_col_type = 'decimal'
            SET @l_temp_col_type = @l_temp_col_type + '(' + @l_temp_col_precision + ',' + @l_temp_col_scale + ')'

        IF (@l_temp_col_type = 'varchar' OR @l_temp_col_type = 'nvarchar' OR @l_temp_col_type = 'varbinary') AND @l_temp_col_char_max = '-1'
            SET @l_temp_col_type = @l_temp_col_type + '(max)'

        IF (@l_temp_col_type = 'char' OR @l_temp_col_type = 'nchar' OR @l_temp_col_type = 'varchar' OR @l_temp_col_type = 'nvarchar') AND @l_temp_col_char_max != '-1'
            SET @l_temp_col_type = @l_temp_col_type + '(' + @l_temp_col_char_max + ')'

    -- Set up the from string as the base table.
    SET @l_from_str = '[dbo].[POIT] POIT_'

    -- Set up the join string
    SET @l_join_str = @p_join_str
    IF @p_join_str is null
        SET @l_join_str = ' '

    -- Set up the where string
    SET @l_where_str = ' '
        IF @p_where_str is not null
        SET @l_where_str = 'WHERE ' + @p_where_str

    -- Get the total count of rows the query will return
    IF @p_page_number > 0 and @p_batch_size >= 0
    BEGIN
        IF @p_is_distinct = 0
        BEGIN
            SET @l_count_query = 
                'SELECT count(*) FROM ( SELECT ' + @p_select_str + 
                ' As __Two FROM ' + @l_from_str + ' ' + @l_join_str + ' ' +
                @l_where_str + ' ) countAlias'

        END
        ELSE
        BEGIN
            SET @l_count_query = 
                'SELECT COUNT(*) FROM ( SELECT DISTINCT ' + @p_select_str + ' As __Two, 1 As __One  ' +
                'FROM ' + @l_from_str + ' ' + @l_join_str + ' ' +
                @l_where_str + ' ) pass1 '

        END
    END

    ELSE

    BEGIN
        SET @l_count_query = ' '
    END

    -- Get the list
    IF @p_page_number > 0 AND @p_batch_size > 0
    BEGIN
        -- If the caller did not pass a sort string, use a default value
        IF @p_sort_str IS NULL OR LTRIM(RTRIM(@p_sort_str)) = ''
            SET @l_sort_str = 'ORDER BY 1 '

        ELSE
            SET @l_sort_str = 'ORDER BY ' + @p_sort_str
        -- Calculate the rows to be included in the list
        SET @l_end_gen_row_num = @p_page_number * @p_batch_size;
        SET @l_start_gen_row_num = @l_end_gen_row_num - (@p_batch_size-1);

        -- Create a table variable to keep row numbering
        SET @l_create_temp = 'DECLARE @IS_TEMP_T_GETLIST TABLE
            (
            IS_ROWNUM_COL int identity(1,1), ' + 
            ' __Two ' + @l_temp_col_type  +
            '); '

        -- Copy column data into the table variable
        SET @l_temp_insert = 
            'INSERT INTO @IS_TEMP_T_GETLIST ( __Two ) ' 
        IF @p_is_distinct = 0 OR @p_sort_str IS NULL OR LTRIM(RTRIM(@p_sort_str)) = ''
        BEGIN
            IF @p_is_distinct = 0
            BEGIN
                SET @l_temp_select = 
                    'SELECT '
            END
            ELSE
            BEGIN
                SET @l_temp_select = 
                    'SELECT DISTINCT '
            END
        SET @l_temp_select = 
            @l_temp_select + 
            'TOP ' + convert(varchar, @l_end_gen_row_num) + ' ' + 
            @p_select_str
        END
        ELSE
        BEGIN
                -- Need to construct query differently when sorting by expanded DFKA, 
                -- So get the TOP DISTINCT values after selecting, joining, and sorting ALL the values 
                SET @l_temp_select = 
                    'SELECT __ReturnCol FROM ( ' + 
                    'SELECT ' + 
                    'DISTINCT ' + 
                    'TOP ' + convert(varchar, @l_end_gen_row_num) + ' ' + 
                    @p_select_str + 
                    ' As __ReturnCol, ' + 
                    @p_select_str_b
                -- Close and alias the outer FROM clause after the inner ORDER BY clause 
                SET @l_sort_str = 
                    @l_sort_str + 
                    ' ) pass1 '
        END
        SET @l_temp_from = 
            ' FROM ' + @l_from_str + ' ' + @l_join_str
        -- Construct the main query
        SET @l_query_select = 'SELECT '
        SET @l_query_from = 
            'FROM @IS_TEMP_T_GETLIST ' +
            'AS [POIT_]' +
            ' WHERE IS_ROWNUM_COL >= '+ convert(varchar, @l_start_gen_row_num) 

        SET @l_final_sort = 'ORDER BY IS_ROWNUM_COL Asc '

        -- Run all the queries as a batch so the temp tables won't lose scope
        EXECUTE (@l_count_query + '     ' + @l_create_temp + '     ' + @l_temp_insert + @l_temp_select + @l_temp_from + ' ' + @l_where_str + ' ' + @l_sort_str + '     ' + @l_query_select + ' __Two ' + @l_query_from + @l_query_where + @l_final_sort)

    END
    ELSE
    BEGIN
        -- If page number and batch size are not valid numbers return the empty result set
        SET @l_query_select = 'SELECT '
        SET @l_query_from = 
            ' FROM [dbo].[POIT] POIT_ ' + 
            'WHERE 1=2;'
        EXECUTE (@l_query_select + @p_select_str + @l_query_from);
    END

    SET NOCOUNT OFF

END

