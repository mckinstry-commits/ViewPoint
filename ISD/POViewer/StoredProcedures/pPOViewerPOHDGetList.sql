if exists (select * from sysobjects where id = object_id(N'pPOViewerPOHDGetList') and sysstat & 0xf = 4) drop procedure pPOViewerPOHDGetList 
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns a query resultset from table [dbo].[POHD]
-- given the search criteria and sorting condition.
-- It will return a subset of the data based
-- on the current page number and batch size.  Table joins can
-- be performed if the join clause is specified.
-- 
-- If the resultset is not empty, it will return:
--    1) The total number of rows which match the condition;
--    2) The resultset in the current page
-- If nothing matches the search condition, it will return:
--    1) count is 0 ;
--    2) empty resultset.
CREATE PROCEDURE pPOViewerPOHDGetList
        @p_join_str nvarchar(4000),
        @p_where_str nvarchar(4000),
        @p_sort_str nvarchar(4000),
        @p_page_number int,
        @p_batch_size int
AS
DECLARE
    @l_temp_table nvarchar(4000),
    @l_temp_insert nvarchar(4000),
    @l_temp_select nvarchar(max),
    @l_temp_from nvarchar(4000),
    @l_final_sort nvarchar(4000),
    @l_temp_cols nvarchar(4000),
    @l_temp_colsWithAlias nvarchar(4000),
    @l_query_select nvarchar(max),
    @l_query_select2 nvarchar(max),
    @l_query_rownum nvarchar(4000),
    @l_query_from nvarchar(4000),
    @l_query_where nvarchar(max),
    @l_query_cols nvarchar(4000),
    @l_from_str nvarchar(4000),
    @l_join_str nvarchar(4000),
    @l_sort_str nvarchar(4000),
    @l_where_str nvarchar(4000),
    @l_count_query nvarchar(4000),
    @l_end_gen_row_num integer,
    @l_start_gen_row_num integer
BEGIN
    SET NOCOUNT ON

    -- Set up the from string as the base table
    SET @l_from_str = '[dbo].[POHD] POHD_'

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
        SET @l_count_query = 
            'SELECT count(*) ' +
            'FROM ' + @l_from_str + ' ' + @l_join_str + ' ' +
            @l_where_str + ' '

        -- Run the count query
        EXECUTE (@l_count_query)
    END

    -- Get the list
    IF @p_page_number > 0 AND @p_batch_size > 0
    BEGIN
        -- If the caller did not pass a sort string, use a default value
        IF @p_sort_str IS NOT NULL
            SET @l_sort_str = 'ORDER BY ' + @p_sort_str
        ELSE
            SET @l_sort_str = ' '

        -- Calculate the rows to be included in the list
        SET @l_end_gen_row_num = @p_page_number * @p_batch_size;
        SET @l_start_gen_row_num = @l_end_gen_row_num - (@p_batch_size-1);

        -- Construct the main query
        SET @l_query_select = 'WITH POHD_ AS ( SELECT  '
        SET @l_query_rownum = 'ROW_NUMBER() OVER(' + @l_sort_str + ') AS IS_ROWNUM_COL,'
        SET @l_query_cols = 
            N'POHD_.[POCo],
            POHD_.[PO],
            POHD_.[VendorGroup],
            POHD_.[Vendor],
            POHD_.[Description],
            POHD_.[OrderDate],
            POHD_.[OrderedBy],
            POHD_.[ExpDate],
            POHD_.[Status],
            POHD_.[JCCo],
            POHD_.[Job],
            POHD_.[INCo],
            POHD_.[Loc],
            POHD_.[ShipLoc],
            POHD_.[Address],
            POHD_.[City],
            POHD_.[State],
            POHD_.[Zip],
            POHD_.[ShipIns],
            POHD_.[HoldCode],
            POHD_.[PayTerms],
            POHD_.[CompGroup],
            POHD_.[MthClosed],
            POHD_.[InUseMth],
            POHD_.[InUseBatchId],
            POHD_.[Approved],
            POHD_.[ApprovedBy],
            POHD_.[Purge],
            POHD_.[Notes],
            POHD_.[AddedMth],
            POHD_.[AddedBatchID],
            POHD_.[UniqueAttchID],
            POHD_.[Attention],
            POHD_.[PayAddressSeq],
            POHD_.[POAddressSeq],
            POHD_.[Address2],
            POHD_.[KeyID],
            POHD_.[Country],
            POHD_.[POCloseBatchID],
            POHD_.[udSource],
            POHD_.[udConv],
            POHD_.[udCGCTable],
            POHD_.[udCGCTableID],
            POHD_.[udOrderedBy],
            POHD_.[DocType],
            POHD_.[udMCKPONumber],
            POHD_.[udShipToJobYN],
            POHD_.[udPRCo],
            POHD_.[udAddressName],
            POHD_.[udPOFOB],
            POHD_.[udShipMethod],
            POHD_.[udPurchaseContact],
            POHD_.[udPMSource]'

        SET @l_query_from = 'FROM ' + @l_from_str + ' ' + @l_join_str + + ' ' + @l_where_str + ') '
        SET @l_query_select2 = 'SELECT * FROM POHD_ '
        SET @l_query_where = 'WHERE IS_ROWNUM_COL BETWEEN ' + convert(varchar, @l_start_gen_row_num) + ' AND ' + convert(varchar, @l_end_gen_row_num) +  ';'

        -- Run the query
        EXECUTE (@l_query_select + @l_query_rownum + @l_query_cols + @l_query_from + @l_query_select2 + @l_query_where)

    END
    ELSE
    BEGIN
        -- If page number and batch size are not valid numbers return an empty result set
        SET @l_query_select = 'SELECT '
        SET @l_query_cols = 
            N'POHD_.[POCo],
            POHD_.[PO],
            POHD_.[VendorGroup],
            POHD_.[Vendor],
            POHD_.[Description],
            POHD_.[OrderDate],
            POHD_.[OrderedBy],
            POHD_.[ExpDate],
            POHD_.[Status],
            POHD_.[JCCo],
            POHD_.[Job],
            POHD_.[INCo],
            POHD_.[Loc],
            POHD_.[ShipLoc],
            POHD_.[Address],
            POHD_.[City],
            POHD_.[State],
            POHD_.[Zip],
            POHD_.[ShipIns],
            POHD_.[HoldCode],
            POHD_.[PayTerms],
            POHD_.[CompGroup],
            POHD_.[MthClosed],
            POHD_.[InUseMth],
            POHD_.[InUseBatchId],
            POHD_.[Approved],
            POHD_.[ApprovedBy],
            POHD_.[Purge],
            POHD_.[Notes],
            POHD_.[AddedMth],
            POHD_.[AddedBatchID],
            POHD_.[UniqueAttchID],
            POHD_.[Attention],
            POHD_.[PayAddressSeq],
            POHD_.[POAddressSeq],
            POHD_.[Address2],
            POHD_.[KeyID],
            POHD_.[Country],
            POHD_.[POCloseBatchID],
            POHD_.[udSource],
            POHD_.[udConv],
            POHD_.[udCGCTable],
            POHD_.[udCGCTableID],
            POHD_.[udOrderedBy],
            POHD_.[DocType],
            POHD_.[udMCKPONumber],
            POHD_.[udShipToJobYN],
            POHD_.[udPRCo],
            POHD_.[udAddressName],
            POHD_.[udPOFOB],
            POHD_.[udShipMethod],
            POHD_.[udPurchaseContact],
            POHD_.[udPMSource]'
        SET @l_query_from = 
            ' FROM [dbo].[POHD] POHD_ ' + 
            'WHERE 1=2;'
        EXECUTE (@l_query_select + @l_query_cols + @l_query_from);
    END

    SET NOCOUNT OFF

END

