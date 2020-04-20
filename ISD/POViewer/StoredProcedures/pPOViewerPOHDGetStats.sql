if exists (select * from sysobjects where id = object_id(N'pPOViewerPOHDGetStats') and sysstat & 0xf = 4) drop procedure pPOViewerPOHDGetStats 
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Runs a SQL function against a column
-- and returns the result back giving the current 
-- page number and batch size.  SQL functions can include 
-- sum, avg, max, etc
CREATE PROCEDURE pPOViewerPOHDGetStats
        @p_select_str nvarchar(4000),
        @p_join_str nvarchar(4000),
        @p_where_str nvarchar(4000),
        @p_sort_str nvarchar(4000),
        @p_page_number integer,
        @p_batch_size integer
    AS
    DECLARE
        @l_query nvarchar(4000),
        @l_from_str nvarchar(4000),
        @l_join_str nvarchar(4000),
        @l_sort_str nvarchar(4000),
        @l_where_str nvarchar(4000),
        @l_count_query nvarchar(4000),
        @l_end_gen_row_num integer,
        @l_start_gen_row_num integer,
        @l_select_str nvarchar(4000),
        @l_insert_to_temp nvarchar(4000),
        @l_create_temp nvarchar(4000),
        @l_temp_col nvarchar(4000),
        @l_temp_col_name nvarchar(200),
        @l_temp_col_type nvarchar(20),
        @l_temp_col_precision nvarchar(10),
        @l_temp_col_scale nvarchar(10),
        @l_temp_col_type_query nvarchar(500),
        @l_temp_col_type_query_params nvarchar(200)
    BEGIN

        SET NOCOUNT ON

        -- Extract the col only that we need to run statistics on.
        -- First extract the content in the function call.
        SET @l_temp_col = @p_select_str
        SET @l_temp_col = SUBSTRING(@l_temp_col, 
                    PATINDEX('%(%', @l_temp_col) + 1,
                    PATINDEX('%)%', @l_temp_col) - PATINDEX('%(%', @l_temp_col) - 1)

        -- Then extract the column from the distinct clause.
        SET @l_temp_col = LTRIM(RTRIM(@l_temp_col))
        IF PATINDEX('%DISTINCT %', UPPER(@l_temp_col)) = 1
            SET @l_temp_col = SUBSTRING(@l_temp_col, PATINDEX('% %', @l_temp_col) + 1, LEN(@l_temp_col))

        -- Get the select column name without alias
        SET @l_select_str = SUBSTRING(@l_temp_col, PATINDEX('%.%', @l_temp_col) + 1, LEN(@l_temp_col))

        -- Get the select column name without brackets
        SET @l_temp_col_name = REPLACE(REPLACE(@l_select_str, '[', ''), ']', '')

        -- Run a query to get the select column type
        SET @l_temp_col_type_query = N'SELECT @data_type_out = DATA_TYPE, @precision_out = NUMERIC_PRECISION, @scale_out = NUMERIC_SCALE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=''POHD'' and COLUMN_NAME = ' + '''' + @l_temp_col_name + ''''
        SET @l_temp_col_type_query_params = N'@data_type_out varchar(20) OUTPUT, @precision_out varchar(10) OUTPUT, @scale_out varchar(10) OUTPUT'
        EXECUTE sp_executesql
        @l_temp_col_type_query,
        @l_temp_col_type_query_params,
        @data_type_out = @l_temp_col_type OUTPUT,
        @precision_out = @l_temp_col_precision OUTPUT,
        @scale_out = @l_temp_col_scale OUTPUT

        IF @l_temp_col_type = 'numeric' OR @l_temp_col_type = 'decimal'
            SET @l_temp_col_type = @l_temp_col_type + '(' + @l_temp_col_precision + ',' + @l_temp_col_scale + ')'

        -- Set up the from string.
        SET @l_from_str = '[dbo].[POHD] POHD_'

        -- Set up the join string.
        SET @l_join_str = @p_join_str
        IF @p_join_str IS NULL
            SET @l_join_str = ' '

        -- Set up the search string.
        SET @l_where_str = ' '
        IF @p_where_str IS NOT NULL
            SET @l_where_str = @l_where_str + 'WHERE ' + @p_where_str

        -- Get the list.
        IF @p_page_number > 0 AND @p_batch_size > 0
        BEGIN
            -- If the caller did not pass a sort string use a default
            IF @p_sort_str IS NOT NULL
                SET @l_sort_str = 'ORDER BY ' + @p_sort_str;
            ELSE
                SET @l_sort_str = ' '

            -- Calculate the rows to be included in the list
            SET @l_end_gen_row_num = @p_page_number * @p_batch_size
            SET @l_start_gen_row_num = @l_end_gen_row_num - (@p_batch_size-1)

            -- Create a table variable to keep row numbering
            SET @l_create_temp = 'DECLARE @IS_TEMP_FROM TABLE
                (
                IS_ROWNUM_COL int identity(1,1), ' + 
                @l_select_str + ' ' + @l_temp_col_type + 
                '); '

            -- Insert into the table variable from the base table
            SET @l_insert_to_temp = 
                'INSERT INTO @IS_TEMP_FROM ' + 
                '(' + @l_select_str + ') ' + 
                'SELECT ' + @l_temp_col + 
                ' FROM ' + @l_from_str + ' ' + @l_join_str + ' ' + 
                @l_where_str + ' ' + 
                @l_sort_str

            -- Construct the query for the current page
            SET @l_query = 
                'SELECT ' + @p_select_str + ' ' +
                'FROM ( ' +
                'SELECT ' + @l_select_str + ', IS_ROWNUM_COL ' +
                'FROM @IS_TEMP_FROM ' +
                'WHERE IS_ROWNUM_COL >= ' + convert(varchar, @l_start_gen_row_num) +
                ' AND IS_ROWNUM_COL <= ' + convert(varchar, @l_end_gen_row_num) +
                ') ' + 'POHD_'

            -- Run the query and get the result for the current page
            EXECUTE (@l_create_temp + '     ' + @l_insert_to_temp + '     ' + @l_query + ' ');

        END
        ELSE
        -- Return empty result if page number or batch size has invalid number
        BEGIN
            SET @l_query = 
                'SELECT count(*) from ' + '[dbo].[POHD] POHD_ ' +
                'WHERE 1=2;'
            EXECUTE (@l_query)
        END
        SET NOCOUNT OFF

    END

