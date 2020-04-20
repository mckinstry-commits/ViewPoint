if exists (select * from sysobjects where id = object_id(N'pPOViewerPOITExport') and sysstat & 0xf = 4) drop procedure pPOViewerPOITExport 
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns the query result set in a CSV format
-- so that the data can be exported to a CSV file
CREATE PROCEDURE pPOViewerPOITExport
        @p_separator_str nvarchar(15),
        @p_title_str nvarchar(4000),
        @p_select_str nvarchar(4000),
        @p_join_str nvarchar(4000),
        @p_where_str nvarchar(4000),
        @p_num_exported int output
    AS
    DECLARE
        @l_title_str1 nvarchar(4000),
        @l_title_str2 nvarchar(4000),
        @l_select_str1 nvarchar(4000),
        @l_select_str2 nvarchar(4000),
        @l_select_str3 nvarchar(4000),
        @l_from_str nvarchar(4000),
        @l_join_str nvarchar(4000),
        @l_where_str nvarchar(4000),
        @l_query_select nvarchar(4000),
        @l_query_union nvarchar(4000),
        @l_query_from nvarchar(4000)
    BEGIN
        -- Set up the title string from the column names.  Excel 
        -- will complain if the first column value is ID. So wrap
        -- the value with "".
        SET @l_title_str1 = @p_title_str + char(13)
        SET @l_title_str2 = ''
        IF @p_title_str IS NULL
            BEGIN
            SET @l_title_str1 = 
                N'"POCo"' + @p_separator_str +
                N'"PO"' + @p_separator_str +
                N'"POItem"' + @p_separator_str +
                N'"ItemType"' + @p_separator_str +
                N'"MatlGroup"' + @p_separator_str +
                N'"Material"' + @p_separator_str +
                N'"VendMatId"' + @p_separator_str +
                N'"Description"' + @p_separator_str +
                N'"UM"' + @p_separator_str +
                N'"RecvYN"' + @p_separator_str +
                N'"PostToCo"' + @p_separator_str +
                N'"Loc"' + @p_separator_str +
                N'"Job"' + @p_separator_str +
                N'"PhaseGroup"' + @p_separator_str +
                N'"Phase"' + @p_separator_str +
                N'"JCCType"' + @p_separator_str +
                N'"Equip"' + @p_separator_str +
                N'"CompType"' + @p_separator_str +
                N'"Component"' + @p_separator_str +
                N'"EMGroup"' + @p_separator_str +
                N'"CostCode"' + @p_separator_str +
                N'"EMCType"' + @p_separator_str +
                N'"WO"' + @p_separator_str +
                N'"WOItem"' + @p_separator_str +
                N'"GLCo"' + @p_separator_str +
                N'"GLAcct"' + @p_separator_str +
                N'"ReqDate"' + @p_separator_str +
                N'"TaxGroup"' + @p_separator_str +
                N'"TaxCode"' + @p_separator_str +
                N'"TaxType"' + @p_separator_str +
                N'"OrigUnits"' + @p_separator_str +
                N'"OrigUnitCost"' + @p_separator_str +
                N'"OrigECM"' + @p_separator_str +
                N'"OrigCost"' + @p_separator_str +
                N'"OrigTax"' + @p_separator_str +
                N'"CurUnits"' + @p_separator_str +
                N'"CurUnitCost"' + @p_separator_str +
                N'"CurECM"' + @p_separator_str +
                N'"CurCost"' + @p_separator_str +
                N'"CurTax"' + @p_separator_str +
                N'"RecvdUnits"' + @p_separator_str +
                N'"RecvdCost"' + @p_separator_str +
                N'"BOUnits"' + @p_separator_str +
                N'"BOCost"' + @p_separator_str +
                N'"TotalUnits"' + @p_separator_str +
                N'"TotalCost"' + @p_separator_str +
                N'"TotalTax"' + @p_separator_str +
                N'"InvUnits"' + @p_separator_str +
                N'"InvCost"' + @p_separator_str +
                N'"InvTax"' + @p_separator_str +
                N'"RemUnits"' + @p_separator_str +
                N'"RemCost"' + @p_separator_str +
                N'"RemTax"' + @p_separator_str +
                N'"InUseMth"' + @p_separator_str +
                N'"InUseBatchId"' + @p_separator_str +
                N'"PostedDate"' + @p_separator_str +
                N'"RequisitionNum"' + @p_separator_str +
                N'"AddedMth"' + @p_separator_str +
                N'"AddedBatchID"' + @p_separator_str +
                N'"UniqueAttchID"' + @p_separator_str +
                N'"PayCategory"' + @p_separator_str +
                N'"PayType"' + @p_separator_str +
                N'"KeyID"' + @p_separator_str +
                N'"INCo"' + @p_separator_str +
                N'"EMCo"' + @p_separator_str +
                N'"JCCo"' + @p_separator_str +
                N'"JCCmtdTax"' + @p_separator_str +
                N'"Supplier"' + @p_separator_str +
                N'"SupplierGroup"' + @p_separator_str +
                N'"JCRemCmtdTax"' + @p_separator_str +
                N'"TaxRate"' + @p_separator_str +
                N'"GSTRate"' + @p_separator_str +
                N'"SMCo"' + @p_separator_str +
                N'"SMWorkOrder"' + @p_separator_str +
                N'"InvMiscAmt"' + @p_separator_str +
                N'"SMScope"' + @p_separator_str +
                N'"SMPhaseGroup"' + @p_separator_str 
            SET @l_title_str2 = 
                N'"SMPhase"' + @p_separator_str +
                N'"SMJCCostType"' + @p_separator_str +
                N'"udSource"' + @p_separator_str +
                N'"udConv"' + @p_separator_str +
                N'"udCGCTable"' + @p_separator_str +
                N'"udCGCTableID"' + @p_separator_str +
                N'"udOnDate"' + @p_separator_str +
                N'"udPlnOffDate"' + @p_separator_str +
                N'"udActOffDate"' + @p_separator_str +
                N'"udRentalNum"' + ' ';
            END
        ELSE IF SUBSTRING(@l_title_str1, 1, 2) = 'ID'
            SET @l_title_str1 = 
                '"' + 
                SUBSTRING(@l_title_str1, 1, PATINDEX('%,%', @l_title_str1)-1) + 
                '"' + 
                SUBSTRING(@l_title_str1, PATINDEX('%,%', @l_title_str1), LEN(@l_title_str1)); 

        -- Set up the select string
        SET @l_select_str1 = @p_select_str
        SET @l_select_str2 = @p_select_str
        SET @l_select_str3 = @p_select_str
        IF @p_select_str IS NULL
            BEGIN
            SET @l_select_str1 = 
                N'IsNULL(Convert(nvarchar, POIT_.[POCo]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[PO], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[POItem]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[ItemType]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[MatlGroup]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[Material], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[VendMatId], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[Description], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[UM], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[RecvYN], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[PostToCo]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[Loc], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[Job], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[PhaseGroup]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[Phase], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[JCCType]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[Equip], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[CompType], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[Component], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[EMGroup]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[CostCode], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[EMCType]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[WO], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[WOItem]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[GLCo]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[GLAcct], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[ReqDate], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[TaxGroup]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[TaxCode], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[TaxType]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[OrigUnits]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[OrigUnitCost]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[OrigECM], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[OrigCost]), '''') + ''' + @p_separator_str + ''' +' 
            SET @l_select_str2 = 
                N'IsNULL(Convert(nvarchar, POIT_.[OrigTax]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[CurUnits]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[CurUnitCost]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[CurECM], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[CurCost]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[CurTax]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[RecvdUnits]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[RecvdCost]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[BOUnits]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[BOCost]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[TotalUnits]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[TotalCost]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[TotalTax]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[InvUnits]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[InvCost]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[InvTax]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[RemUnits]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[RemCost]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[RemTax]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[InUseMth], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[InUseBatchId]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[PostedDate], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[RequisitionNum], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[AddedMth], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[AddedBatchID]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(varchar(36), POIT_.[UniqueAttchID]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[PayCategory]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[PayType]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[KeyID]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[INCo]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[EMCo]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[JCCo]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[JCCmtdTax]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[Supplier]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[SupplierGroup]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[JCRemCmtdTax]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[TaxRate]), '''') + ''' + @p_separator_str + ''' +' 
            SET @l_select_str3 = 
                N'IsNULL(Convert(nvarchar, POIT_.[GSTRate]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[SMCo]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[SMWorkOrder]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[InvMiscAmt]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[SMScope]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[SMPhaseGroup]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[SMPhase], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[SMJCCostType]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[udSource], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[udConv], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[udCGCTable], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[udCGCTableID]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[udOnDate], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[udPlnOffDate], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POIT_.[udActOffDate], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POIT_.[udRentalNum], ''''), N''"'', N''""'') + N''"''  + '' ''';
            END

        -- Set up the from string (with table alias) and the join string
        SET @l_from_str = '[dbo].[POIT] POIT_';

        SET @l_join_str = @p_join_str
        if @p_join_str is null
            SET @l_join_str = ' ';

        -- Set up the where string
        SET @l_where_str = ' ';
        IF @p_where_str IS NOT NULL
            SET @l_where_str = @l_where_str + 'WHERE ' + @p_where_str;

        -- Construct the query string.  Append the result set with the title.
        SET @l_query_select = 
                'SELECT '''
        SET @l_query_union = 
                ''' UNION ALL ' +
                'SELECT '
        SET @l_query_from = 
                ' FROM ' + @l_from_str + ' ' + @l_join_str + ' ' +
                @l_where_str;

        -- Run the query
        EXECUTE (@l_query_select + @l_title_str1 + @l_title_str2 + @l_query_union + @l_select_str1 + @l_select_str2 + @l_select_str3+ @l_query_from)

        -- Return the total number of rows of the query
        SELECT @p_num_exported = @@rowcount
    END

