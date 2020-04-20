SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     PROCEDURE [dbo].[bspBatchUserMemoUpdateAPHBadd]
    /***********************************************************
       * CREATED BY: MV 08/01/01
       * MODIFIED By : RM/TV 03/05/03 Issue 20612 (fixed quotes for Month joins)
       *				DANF 04/02/08 Issue 125049 Corrected update statement to use variables in the update statement.
	   *				MV 07/29/08 - 129197 - @updatestring shld be nvarchar
	   *				DC 1/26/09 - #131969 - Variable length insufficient
	   *				MV 04/30/09 - #133429 - joins for APUL source
	   *				DC 04/23/10 - #139103 - Insufficient relational integrity on updating UD fields between APUL and APLB
	   *				AMR - 6/27/11 - TK-06411, Fixing performance issue by using an inline table function.
	   *
       * USAGE:     Updates APHB or APLB batch tables with
       *            user memo data from reoccuring or unapproved
       *            invoices in a batch.
       *
       * INPUT:
       *
       * OUTPUT:
       *   @errmsg     if something went wrong
    
       * RETURN VALUE
       *   0   success
       *   1   fail
       *****************************************************/
    (
      @co bCompany,
      @mth bMonth,
      @batchid bBatchID,
      @batchseq INT,
      @source VARCHAR(255),
      @errmsg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
    
    /*DC #131969
     declare @rcode int, @updatestring nvarchar(1000), @columnname varchar(30),
       @formname varchar(30), @Mainttable varchar(30), @batchtable varchar(30),
       @joins varchar(1000), @whereclause varchar(1000), @formname2 varchar (30),
		@paramsin nvarchar(200)
	*/

    DECLARE @rcode INT,
        @updatestring NVARCHAR(MAX),
        @columnname VARCHAR(30),
        @formname VARCHAR(30),
        @Mainttable VARCHAR(30),
        @batchtable VARCHAR(30),
        @joins VARCHAR(MAX),
        @whereclause VARCHAR(MAX),
        @formname2 VARCHAR(30),
        @paramsin NVARCHAR(200)
  
 
	-- -- -- define parameters for exec sql statement 
    SET @paramsin = N'@co tinyint, @mth bMonth, @batchid int, @batchseq int'

    SELECT  @rcode = 0
    
    IF @source = 'APUI' 
        BEGIN
            SELECT  @Mainttable = 'APUI',
                    @formname = 'APUnappInv',
                    @formname2 = 'APEntry',
                    @batchtable = 'APHB',
                    @joins = ' join APHB d on d.Co = b.APCo and d.UIMth = b.UIMth and '
                    + 'd.UISeq = b.UISeq',
                    @whereclause = ' where d.Co = @co and d.Mth = @mth and d.BatchId = @batchid and d.BatchSeq = @batchseq'
        END
    
    IF @source = 'APUL' 
        BEGIN
            SELECT  @Mainttable = 'APUL',
                    @formname = 'APUnappInvItems',
                    @formname2 = 'APEntryDetail',
                    @batchtable = 'APLB',
--         @joins =' join APLB d on d.Co = b.APCo and d.APLine = b.Line and d.LineType = b.LineType' + 
--                 ' join APUI h on b.APCo = h.APCo and b.UIMth = h.UIMth and b.UISeq = h.UISeq', 
                    @joins = ' join APHB h on h.Co=b.APCo and h.UIMth=b.UIMth and h.UISeq=b.UISeq'
                    + ' join APLB d on h.Co=d.Co and h.Mth=d.Mth and d.BatchId=h.BatchId and d.APLine=b.Line and d.LineType=b.LineType and h.BatchSeq=d.BatchSeq', --DC #139103
                    @whereclause = ' where d.Co = @co and d.Mth = @mth and d.BatchId = @batchid and d.BatchSeq = @batchseq'
        END
    
    IF @source = 'APRH' 
        BEGIN
            SELECT  @Mainttable = 'APRH',
                    @formname = 'APRecurInv',
                    @formname2 = 'APEntry',
                    @batchtable = 'APHB',
                    @joins = ' join APHB d on d.Co = b.APCo and d.VendorGroup = b.VendorGroup and '
                    + 'd.Vendor = b.Vendor and d.InvId = b.InvId',
                    @whereclause = ' where d.Co = @co and d.Mth = @mth and d.BatchId = @batchid and d.BatchSeq = @batchseq'
        END
    
    IF @source = 'APRL' 
        BEGIN
            SELECT  @Mainttable = 'APRL',
                    @formname = 'APRecurInvItems',
                    @formname2 = 'APEntryDetail',
                    @batchtable = 'APLB',
                    @joins = ' join APLB d on d.Co = b.APCo and d.APLine = b.Line and d.LineType = b.LineType'
                    + ' and d.VendorGroup = b.VendorGroup'
                    + ' join APRH h on h.APCo = b.APCo and h.VendorGroup = b.VendorGroup and'
                    + ' h.Vendor = b.Vendor and h.InvId = b.InvId',
                    @whereclause = ' where d.Co = @co and d.Mth = @mth and d.BatchId = @batchid and d.BatchSeq = @batchseq'
        END
    
    SELECT  @columnname = MIN(ColumnName)
    FROM    dbo.vfDDFIShared(@formname)
			-- use inline table func for perf
    WHERE   FieldType = 4
            AND ColumnName LIKE 'ud%'
    WHILE @columnname IS NOT NULL 
        BEGIN
            IF EXISTS ( SELECT  *
						-- use inline table func for perf
                        FROM    dbo.vfDDFIShared(@formname2)
                        WHERE   ColumnName = @columnname ) 
                BEGIN
                    SELECT  @updatestring = NULL
                    SELECT  @updatestring = 'update ' + @batchtable + ' set '
                            + @columnname + ' =  b.' + @columnname + ' from '
                            + @Mainttable + ' b' + @joins + @whereclause
		

                    SELECT  @paramsin '@paramsin',
                            @co '@co',
                            @mth '@mth',
                            @batchid '@batchid',
                            @batchseq '@batchseq'

                    EXEC sp_executesql @updatestring, @paramsin, @co, @mth,
                        @batchid, @batchseq
             --exec (@updatestring)
                    IF @@rowcount = 0 
                        BEGIN
                            SELECT  @rcode = 1
                            RETURN @rcode
                        END
                END
    
            SELECT  @columnname = MIN(ColumnName)
				-- use inline table func for perf
            FROM    dbo.vfDDFIShared(@formname)
            WHERE   FieldType = 4
                    AND ColumnName LIKE 'ud%'
                    AND ColumnName > @columnname
        END
    
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspBatchUserMemoUpdateAPHBadd] TO [public]
GO
