if exists (select * from sysobjects where id = object_id(N'pPOViewerPOHDExport') and sysstat & 0xf = 4) drop procedure pPOViewerPOHDExport 
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns the query result set in a CSV format
-- so that the data can be exported to a CSV file
CREATE PROCEDURE pPOViewerPOHDExport
        @p_separator_str nvarchar(15),
        @p_title_str nvarchar(4000),
        @p_select_str nvarchar(4000),
        @p_join_str nvarchar(4000),
        @p_where_str nvarchar(4000),
        @p_num_exported int output
    AS
    DECLARE
        @l_title_str nvarchar(4000),
        @l_select_str1 nvarchar(4000),
        @l_select_str2 nvarchar(4000),
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
        SET @l_title_str = @p_title_str + char(13)
        IF @p_title_str IS NULL
            BEGIN
            SET @l_title_str = 
                N'"POCo"' + @p_separator_str +
                N'"PO"' + @p_separator_str +
                N'"VendorGroup"' + @p_separator_str +
                N'"Vendor"' + @p_separator_str +
                N'"Description"' + @p_separator_str +
                N'"OrderDate"' + @p_separator_str +
                N'"OrderedBy"' + @p_separator_str +
                N'"ExpDate"' + @p_separator_str +
                N'"Status"' + @p_separator_str +
                N'"JCCo"' + @p_separator_str +
                N'"Job"' + @p_separator_str +
                N'"INCo"' + @p_separator_str +
                N'"Loc"' + @p_separator_str +
                N'"ShipLoc"' + @p_separator_str +
                N'"Address"' + @p_separator_str +
                N'"City"' + @p_separator_str +
                N'"State"' + @p_separator_str +
                N'"Zip"' + @p_separator_str +
                N'"ShipIns"' + @p_separator_str +
                N'"HoldCode"' + @p_separator_str +
                N'"PayTerms"' + @p_separator_str +
                N'"CompGroup"' + @p_separator_str +
                N'"MthClosed"' + @p_separator_str +
                N'"InUseMth"' + @p_separator_str +
                N'"InUseBatchId"' + @p_separator_str +
                N'"Approved"' + @p_separator_str +
                N'"ApprovedBy"' + @p_separator_str +
                N'"Purge"' + @p_separator_str +
                N'"AddedMth"' + @p_separator_str +
                N'"AddedBatchID"' + @p_separator_str +
                N'"UniqueAttchID"' + @p_separator_str +
                N'"Attention"' + @p_separator_str +
                N'"PayAddressSeq"' + @p_separator_str +
                N'"POAddressSeq"' + @p_separator_str +
                N'"Address2"' + @p_separator_str +
                N'"KeyID"' + @p_separator_str +
                N'"Country"' + @p_separator_str +
                N'"POCloseBatchID"' + @p_separator_str +
                N'"udSource"' + @p_separator_str +
                N'"udConv"' + @p_separator_str +
                N'"udCGCTable"' + @p_separator_str +
                N'"udCGCTableID"' + @p_separator_str +
                N'"udOrderedBy"' + @p_separator_str +
                N'"DocType"' + @p_separator_str +
                N'"udMCKPONumber"' + @p_separator_str +
                N'"udShipToJobYN"' + @p_separator_str +
                N'"udPRCo"' + @p_separator_str +
                N'"udAddressName"' + @p_separator_str +
                N'"udPOFOB"' + @p_separator_str +
                N'"udShipMethod"' + @p_separator_str +
                N'"udPurchaseContact"' + @p_separator_str +
                N'"udPMSource"' + ' ';
            END
        ELSE IF SUBSTRING(@l_title_str, 1, 2) = 'ID'
            SET @l_title_str = 
                '"' + 
                SUBSTRING(@l_title_str, 1, PATINDEX('%,%', @l_title_str)-1) + 
                '"' + 
                SUBSTRING(@l_title_str, PATINDEX('%,%', @l_title_str), LEN(@l_title_str)); 

        -- Set up the select string
        SET @l_select_str1 = @p_select_str
        SET @l_select_str2 = @p_select_str
        IF @p_select_str IS NULL
            BEGIN
            SET @l_select_str1 = 
                N'IsNULL(Convert(nvarchar, POHD_.[POCo]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[PO], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[VendorGroup]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[Vendor]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[Description], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[OrderDate], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[OrderedBy], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[ExpDate], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[Status]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[JCCo]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[Job], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[INCo]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[Loc], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[ShipLoc], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[Address], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[City], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[State], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[Zip], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[ShipIns], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[HoldCode], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[PayTerms], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[CompGroup], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[MthClosed], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[InUseMth], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[InUseBatchId]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[Approved], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[ApprovedBy], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[Purge], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[AddedMth], 21), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[AddedBatchID]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(varchar(36), POHD_.[UniqueAttchID]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[Attention], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[PayAddressSeq]), '''') + ''' + @p_separator_str + ''' +' 
            SET @l_select_str2 = 
                N'IsNULL(Convert(nvarchar, POHD_.[POAddressSeq]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[Address2], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[KeyID]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[Country], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[POCloseBatchID]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[udSource], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[udConv], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[udCGCTable], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[udCGCTableID]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[udOrderedBy]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[DocType], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[udMCKPONumber], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[udShipToJobYN], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[udPRCo]), '''') + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[udAddressName], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[udPOFOB], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'N''"'' + REPLACE(IsNULL(POHD_.[udShipMethod], ''''), N''"'', N''""'') + N''"''  + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[udPurchaseContact]), '''') + ''' + @p_separator_str + ''' +' +
                N'IsNULL(Convert(nvarchar, POHD_.[udPMSource]), '''') + '' ''';
            END

        -- Set up the from string (with table alias) and the join string
        SET @l_from_str = '[dbo].[POHD] POHD_';

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
        EXECUTE (@l_query_select + @l_title_str + @l_query_union + @l_select_str1 + @l_select_str2+ @l_query_from)

        -- Return the total number of rows of the query
        SELECT @p_num_exported = @@rowcount
    END

