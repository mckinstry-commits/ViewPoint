SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspBatchUserMemoInsertExisting    Script Date: 8/28/99 9:36:28 AM ******/
CREATE PROCEDURE [dbo].[bspBatchUserMemoInsertExisting]
    /***********************************************************
    * CREATED BY: kb 3/13/01
    * MODIFIED By : GG 04/13/01 - replaced table references with views
    *             : MV 07/01/01 - Issue 12769 added @source coding
    *				GG 04/15/02 - added IN MO Confirmation
    *				GF 12/17/02 - issue #19696 fix for single quotes.
    *				RM 01/07/03 - Issue 18281 - Add capabilities for EMMilesByState form.
    *				RM 01/08/02 - Added check to make sure that there are records before trying to update
    *				GF 01/21/03 - Issue #20100 missing source = 'EMFuel' when setting EM Cost Adjustment
    *				GF 04/22/2003 - trigger errors not flowing back to front-end. Caused by select 1 statement
    *								to check for record to update. Changed to use a temp table, then check
    *								temp table value to see if user memo update should occur.
    *				GF 07/10/2003 - issue #21814 missing batch forms 'MO Entry' and 'MO Entry Items'. Added
    *				GF 09/30/2003 - issue #22600 missing source causes invalid object error. Exit if no source.
	*			    DANF 02/13/08 - Issue 125049 Improve user memo update process.
	*				EN 09/29/08 - #129874  resolve error, "Unable to update custom fields(s) to PR Timecard Batch!"
	*				AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function.
    *
    *
    * USAGE:
    *	Copies user memo column values from detail tables to batch tables
    *	as existing entries are pulled into a batch.
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
      @source VARCHAR(30),
      @trans INT,
      @errmsg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
    
    DECLARE @rcode INT,
        @validcnt INT,
        @updatestring NVARCHAR(4000),
        @columnname VARCHAR(30),
        @formname VARCHAR(30),
        @postedtable VARCHAR(30),
        @batchtable VARCHAR(30),
        @joins VARCHAR(1000),
        @whereclause VARCHAR(4000),
        @numrows INT,
        @paramsin NVARCHAR(200),
        @rowcountparamsin NVARCHAR(200),
        @paramsintrans NVARCHAR(200),
        @rowcountparamsintrans NVARCHAR(200)
   
    SELECT  @rcode = 0

   -- -- -- define parameters for exec sql statement 125049
    SET @paramsin = N'@co tinyint, @mth bMonth, @batchid int, @batchseq int'
    SET @rowcountparamsin = N'@co tinyint, @mth bMonth, @batchid int, @batchseq int, @validcnt int OUTPUT'

    SET @paramsintrans = N'@co tinyint, @mth bMonth, @batchid int, @batchseq int, @trans int'
    SET @rowcountparamsintrans = N'@co tinyint, @mth bMonth, @batchid int, @batchseq int,  @trans int, @validcnt int OUTPUT'

   
    IF @source IS NULL 
        RETURN @rcode
    
    IF @source = 'AP Entry' 
        BEGIN
            SELECT  @postedtable = 'APTH',
                    @formname = 'APEntry',
                    @batchtable = 'APHB',
                    @joins = ' join APHB b on b.Co = d.APCo and b.Mth = d.Mth and b.APTrans = d.APTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AP Entry Detail' 
        BEGIN
            SELECT  @postedtable = 'APTL',
                    @formname = 'APEntryDetail',
                    @batchtable = 'APLB',
                    @joins = ' join APLB b on b.Co = d.APCo and b.Mth = d.Mth and b.APLine = d.APLine '
                    + ' join APHB h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId and h.BatchSeq = b.BatchSeq'
                    + ' and h.Co = d.APCo and h.Mth = d.Mth and h.APTrans = d.APTrans',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AR CashReceipts' 
        BEGIN
            SELECT  @postedtable = 'ARTH',
                    @formname = 'ARCashReceipts',
                    @batchtable = 'ARBH',
                    @joins = ' join ARBH b on b.Co = d.ARCo and b.Mth = d.Mth and b.ARTrans = d.ARTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AR FinanceCharge' 
        BEGIN
            SELECT  @postedtable = 'ARTH',
                    @formname = 'ARFinChg',
                    @batchtable = 'ARBH',
                    @joins = ' join ARBH b on b.Co = d.ARCo and b.Mth = d.Mth and b.ARTrans = d.ARTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AR FinanceChargeDetail' 
        BEGIN
            SELECT  @postedtable = 'ARTL',
                    @formname = 'ARFinChgLines',
                    @batchtable = 'ARBL',
                    @joins = ' join ARBL b on b.Co = d.ARCo and b.Mth = d.Mth and b.ARLine = d.ARLine '
                    + ' join ARBH h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId and h.BatchSeq = b.BatchSeq'
                    + ' and h.Co = d.ARCo and h.Mth = d.Mth and h.ARTrans = d.ARTrans',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AR InvoiceEntry' 
        BEGIN
            SELECT  @postedtable = 'ARTH',
                    @formname = 'ARInvoiceEntry',
                    @batchtable = 'ARBH',
                    @joins = ' join ARBH b on b.Co = d.ARCo and b.Mth = d.Mth and b.ARTrans = d.ARTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AR InvoiceEntryDetail' 
        BEGIN
            SELECT  @postedtable = 'ARTL',
                    @formname = 'ARInvoiceEntryLines',
                    @batchtable = 'ARBL',
                    @joins = ' join ARBL b on b.Co = d.ARCo and b.Mth = d.Mth and b.ARLine = d.ARLine '
                    + ' join ARBH h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId and h.BatchSeq = b.BatchSeq'
                    + ' and h.Co = d.ARCo and h.Mth = d.Mth and h.ARTrans = d.ARTrans',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AR MiscRec' 
        BEGIN
            SELECT  @postedtable = 'ARTH',
                    @formname = 'ARMiscRec',
                    @batchtable = 'ARBH',
                    @joins = ' join ARBH b on b.Co = d.ARCo and b.Mth = d.Mth and b.ARTrans = d.ARTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AR MiscRecDetail' 
        BEGIN
            SELECT  @postedtable = 'ARTL',
                    @formname = 'ARMiscRecLines',
                    @batchtable = 'ARBL',
                    @joins = ' join ARBL b on b.Co = d.ARCo and b.Mth = d.Mth and b.ARLine = d.ARLine '
                    + ' join ARBH h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId and h.BatchSeq = b.BatchSeq'
                    + ' and h.Co = d.ARCo and h.Mth = d.Mth and h.ARTrans = d.ARTrans',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    
    IF @source = 'CM Post' 
        BEGIN
            SELECT  @postedtable = 'CMDT',
                    @formname = 'CMPOST',
                    @batchtable = 'CMDB',
                    @joins = ' join CMDB b on b.Co = d.CMCo and b.Mth = d.Mth'
                    + ' and b.CMTrans = d.CMTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'CM Trans' 
        BEGIN
            SELECT  @postedtable = 'CMTT',
                    @formname = 'CMTR',
                    @batchtable = 'CMTB',
                    @joins = ' join CMTB b on b.Co = d.CMCo and b.Mth = d.Mth'
                    + ' and b.CMTransferTrans = d.CMTransferTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source IN ( 'EMAdj', 'EMParts', 'EMTime', 'EMFuel' ) 
        BEGIN
            SELECT  @formname = CASE @source
                                  WHEN 'EMAdj' THEN 'EMCostAdj'
                                  WHEN 'EMParts' THEN 'EMWOPartsPosting'
                                  WHEN 'EMTime' THEN 'EMWOTimeCards'
                                  WHEN 'EMFuel' THEN 'EMFuelPosting'
                                END
    
            SELECT  @postedtable = 'EMCD',
                    @batchtable = 'EMBF',
                    @joins = ' join EMBF b on b.Co = d.EMCo and b.Mth = d.Mth'
                    + ' and b.EMTrans = d.EMTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'EM LocXfer' 
        BEGIN
            SELECT  @postedtable = 'EMLH',
                    @formname = 'EMLocXfer',
                    @batchtable = 'EMLB',
                    @joins = ' join EMLB b on b.Co = d.EMCo and b.Mth = d.Month and b.MeterTrans = d.Trans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'EM MeterReadings' 
        BEGIN
            SELECT  @postedtable = 'EMMR',
                    @formname = 'EMMeterReadings',
                    @batchtable = 'EMBF',
                    @joins = ' join EMBF b on b.Co = d.EMCo and b.Mth = d.Mth and b.EMTrans = d.EMTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'EM MilesByState' 
        BEGIN
            SELECT  @postedtable = 'EMSM',
                    @formname = 'EMMilesByState',
                    @batchtable = 'EMMH',
                    @joins = ' join EMMH b on b.Co = d.Co and b.Mth = d.Mth and b.EMTrans = d.EMTrans',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'EM MilesByState Lines' 
        BEGIN
            SELECT  @postedtable = 'EMSD',
                    @formname = 'EMMilesByStateLines',
                    @batchtable = 'EMML'
            SELECT  @joins = ' join EMML b on d.Co = b.Co and d.Mth = b.Mth and d.EMTrans = b.EMTrans and b.Line=d.Line'
            SELECT  @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'EM UsePosting' 
        BEGIN
            SELECT  @postedtable = 'EMRD',
                    @formname = 'EMUsePosting',
                    @batchtable = 'EMBF',
                    @joins = ' join EMBF b on b.Co = d.EMCo and b.Mth = d.Mth and b.EMTrans = d.Trans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'GL JournalEntry' 
        BEGIN
            SELECT  @postedtable = 'GLDT',
                    @formname = 'GLJE',
                    @batchtable = 'GLDB',
                    @joins = ' join GLDB b on b.Co = d.GLCo and b.Mth = d.Mth and b.GLTrans = d.GLTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'IN Adjustments' 
        BEGIN
            SELECT  @postedtable = 'INDT',
                    @formname = 'INAdjustments',
                    @batchtable = 'INAB',
                    @joins = ' join INAB b on b.Co = d.INCo and b.Mth = d.Mth and b.INTrans = d.INTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source IN ( 'JC CostAdj', 'JC MatUse' ) 
        BEGIN
            SELECT  @formname = CASE @source
                                  WHEN 'JC CostAdj' THEN 'JCCOSTADJ'
                                  WHEN 'JC MatUse' THEN 'JCMatUse'
                                END
            SELECT  @postedtable = 'JCCD',
                    @batchtable = 'JCCB',
                    @joins = ' join JCCB b on b.Co = d.JCCo and b.Mth = d.Mth'
                    + ' and b.CostTrans = d.CostTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'JC AdjRev' 
        BEGIN
            SELECT  @postedtable = 'JCID',
                    @formname = 'JCRevAdj',
                    @batchtable = 'JCIB',
                    @joins = ' join JCIB b on b.Co = d.JCCo and b.Mth = d.Mth'
                    + ' and b.ItemTrans = d.ItemTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END

    IF @source = 'MO Confirm' 
        BEGIN
            SELECT  @postedtable = 'INDT',
                    @formname = 'INMOConf',
                    @batchtable = 'INCB',
                    @joins = ' join INCB b on b.Co = d.INCo and b.Mth = d.Mth'
                    + ' and b.INTrans = d.INTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
   
    IF @source = 'MO Entry' 
        BEGIN
            SELECT  @postedtable = 'INMO',
                    @formname = 'INMOEntry',
                    @batchtable = 'INMB',
                    @joins = ' join INMB b on b.Co = d.INCo and b.MO = d.MO ',
                    @whereclause = ' where Co = @co and Mth = @mth and BatchId = @batchid and b.BatchSeq = @batchseq'
        END
   
    IF @source = 'MO Entry Items' 
        BEGIN
            SELECT  @postedtable = 'INMI',
                    @formname = 'INMOEntryItems',
                    @batchtable = 'INIB',
                    @joins = ' left join INMB h on h.Co = d.INCo and h.MO = d.MO '
                    + 'left join INIB b on b.Co = h.Co and b.Mth = h.Mth '
                    + 'and b.BatchId = h.BatchId and b.BatchSeq = h.BatchSeq and b.MOItem = d.MOItem',
                    @whereclause = ' where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @batchseq and d.MOItem = @trans'
        END
   
    IF @source = 'MO Entry Items PM Interface' 
        BEGIN
            SELECT  @postedtable = 'PMMF',
                    @formname = 'INMOEntryItems',
                    @batchtable = 'INIB',
                    @joins = ' left join INMB h on h.Co = d.INCo and h.MO = d.MO '
                    + 'left join INIB b on b.Co = h.Co and b.Mth = h.Mth '
                    + 'and b.BatchId = h.BatchId and b.BatchSeq = h.BatchSeq and b.MOItem = d.MOItem',
                    @whereclause = ' where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @batchseq and d.MOItem = @trans'
        END
   
    IF @source = 'MS Haul' 
        BEGIN
            SELECT  @postedtable = 'MSHH',
                    @formname = 'MSHaulEntry',
                    @batchtable = 'MSHB',
                    @joins = ' join MSHB b on b.Co = d.MSCo and b.Mth = d.Mth and '
                    + 'b.HaulTrans = d.HaulTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'MS HaulDetail' 
        BEGIN
            SELECT  @postedtable = 'MSTD',
                    @formname = 'MSHaulEntryLines',
                    @batchtable = 'MSLB',
                    @joins = ' join MSLB b on b.Co = d.MSCo and b.Mth = d.Mth'
                    + ' and b.MSTrans = d.MSTrans'
                    + ' join MSHH h on h.MSCo = d.MSCo and h.Mth = d.Mth'
                    + ' and h.HaulTrans = d.HaulTrans',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'MS Invoice' 
        BEGIN
            SELECT  @postedtable = 'MSIH',
                    @formname = 'MSInvEdit',
                    @batchtable = 'MSIB',
                    @joins = ' join MSIB b on b.Co = d.MSCo and b.Mth = d.Mth and b.MSInv = d.MSInv',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'MS Tickets' 
        BEGIN
            SELECT  @postedtable = 'MSTD',
                    @formname = 'MSTicEntry',
                    @batchtable = 'MSTB',
                    @joins = ' join MSTB b on b.Co = d.MSCo and b.Mth = d.Mth and b.MSTrans = d.MSTrans ',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'PO ChgOrder' 
        BEGIN
            SELECT  @postedtable = 'POCD',
                    @formname = 'POChgOrder',
                    @batchtable = 'POCB',
                    @joins = ' join POCB b on b.Co = d.POCo and b.Mth = b.Mth and b.POTrans = d.POTrans'
                    + ' and b.PO = d.PO and b.POItem = d.POItem',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
    
        END
    
    IF @source = 'PO Entry' 
        BEGIN
            SELECT  @postedtable = 'POHD',
                    @formname = 'POEntry',
                    @batchtable = 'POHB',
                    @joins = ' join POHB b on b.Co = d.POCo and b.PO = d.PO ',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    IF @source = 'PO Entry Items' 
        BEGIN
            SELECT  @postedtable = 'POIT',
                    @formname = 'POEntryItems',
                    @batchtable = 'POIB',
                    @joins = ' left join POHB h on h.Co = d.POCo and h.PO = d.PO '
                    + 'left join POIB b on b.Co = h.Co and b.Mth = h.Mth '
                    + 'and b.BatchId = h.BatchId and b.BatchSeq = h.BatchSeq and b.POItem = d.POItem',
                    @whereclause = ' where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @batchseq and d.POItem = @trans'
        END

    IF @source = 'PO Receipts' 
        BEGIN
            SELECT  @postedtable = 'PORD',
                    @formname = 'POReceipts',
                    @batchtable = 'PORB',
                    @joins = ' join PORB b on b.Co = d.POCo and b.Mth = b.Mth and b.POTrans = d.POTrans'
                    + ' and b.PO = d.PO and b.POItem = d.POItem',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END

    --if @source= 'PR EmployeeLeave'
    IF @source = 'PR Leave' /*'PR EmployeeLeave'*/ 
        BEGIN
            SELECT  @postedtable = 'PRLH',
                    @formname = 'PRLeaveEntry' /*'PREmplLeave'*/,
                    @batchtable = 'PRAB',
                    @joins = ' join PRAB b on b.Co = d.PRCo and b.Mth = d.Mth and b.Trans = d.Trans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'PR TimeCards' 
        BEGIN
            SELECT  @postedtable = 'PRTH',
                    @formname = 'PRTimeCards',
                    @batchtable = 'PRTB',
                    @joins = ' join PRTB b on b.Co = d.PRCo and b.Employee = d.Employee and '
                    + ' b.PaySeq = d.PaySeq and b.PostSeq = d.PostSeq and b.PostDate = d.PostDate'
                    + ' and b.BatchId=d.InUseBatchId', --#129874 added batchid to join to avoid 1 to many relationship
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'SL Entry' 
        BEGIN
            SELECT  @postedtable = 'SLHD',
                    @formname = 'SLEntry',
                    @batchtable = 'SLHB',
                    @joins = ' join SLHB b on b.Co = d.SLCo and b.SL = d.SL ',
                    @whereclause = ' where Co = @co and Mth = @mth and BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    IF @source = 'SL Entry Items' 
        BEGIN
            SELECT  @postedtable = 'SLIT',
                    @formname = 'SLEntryItems',
                    @batchtable = 'SLIB',
                    @joins = ' left join SLHB h on h.Co = d.SLCo and h.SL = d.SL '
                    + 'left join SLIB b on b.Co = h.Co and b.Mth = h.Mth '
                    + 'and b.BatchId = h.BatchId and b.BatchSeq = h.BatchSeq and b.SLItem = d.SLItem',
                    @whereclause = ' where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and h.BatchSeq = @batchseq and d.SLItem = @trans'
    
        END
    
    IF @source = 'SL ChgOrder' 
        BEGIN
            SELECT  @postedtable = 'SLCD',
                    @formname = 'SLChangeOrders',
                    @batchtable = 'SLCB',
                    @joins = ' join SLCB b on b.Co = d.SLCo and b.SL = d.SL and b.Mth = d.Mth'
                    + ' and b.SLTrans = d.SLTrans',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
   
    IF @postedtable IS NULL 
        RETURN @rcode
    
    ---- check to make sure there are records in this table. If not, then exit

    IF @source = 'SL Entry Items'
        OR @source = 'PO Entry Items'
        OR @source = 'MO Entry Items PM Interface'
        OR @source = 'MO Entry Items' 
        BEGIN
            SELECT  @updatestring = 'select @validcnt=count(*) from '
                    + @postedtable + ' d' + @joins + @whereclause
            EXEC sp_executesql @updatestring, @rowcountparamsintrans, @co,
                @mth, @batchid, @batchseq, @trans, @validcnt = @numrows OUTPUT
        END
    ELSE 
        BEGIN
            SELECT  @updatestring = 'select @validcnt=count(*) from '
                    + @postedtable + ' d' + @joins + @whereclause
            EXEC sp_executesql @updatestring, @rowcountparamsin, @co, @mth,
                @batchid, @batchseq, @validcnt = @numrows OUTPUT
        END
    IF @numrows = 0 
        RETURN @rcode
   
    
  
-- get first user memo field assigned to the Form
    SELECT  @updatestring = NULL
   
    SELECT  @columnname = MIN(ColumnName)
			-- use inline table func for perf
    FROM    dbo.vfDDFIShared(@formname)
    WHERE   FieldType = 4
            AND ColumnName LIKE 'ud%'
    WHILE @columnname IS NOT NULL 
        BEGIN
    	-- make sure the input has a valid column name
            IF EXISTS ( SELECT TOP 1
                                1
                        FROM    syscolumns
                        WHERE   name = @columnname
                                AND id = OBJECT_ID('dbo.' + @postedtable) ) 
                BEGIN
                    IF @updatestring IS NULL --#129874 use 'is null' in 'if' comparisons
                        BEGIN
                            SELECT  @updatestring = 'update ' + @batchtable
                                    + ' set ' + @columnname + ' =  d.'
                                    + @columnname
                        END
                    ELSE 
                        BEGIN
                            SELECT  @updatestring = @updatestring + ','
                                    + @columnname + ' =  d.' + @columnname
                        END 
                END        

   -- get next user memo field
            SELECT  @columnname = MIN(ColumnName)
					-- use inline table func for perf
            FROM    dbo.vfDDFIShared(@formname)
            WHERE   FieldType = 4
                    AND ColumnName LIKE 'ud%'
                    AND ColumnName > @columnname
        END

    IF @updatestring IS NOT NULL 
        BEGIN
            SELECT  @updatestring = @updatestring + ' from ' + @postedtable
                    + ' d' + @joins + @whereclause

		--print @updatestring
            IF @source = 'SL Entry Items'
                OR @source = 'PO Entry Items'
                OR @source = 'MO Entry Items PM Interface'
                OR @source = 'MO Entry Items' 
                BEGIN
                    SELECT  @paramsintrans '@paramsintrans',
                            @co '@co',
                            @mth '@mth',
                            @batchid '@batchid',
                            @batchseq '@batchseq',
                            @trans '@trans'
                    EXEC sp_executesql @updatestring, @paramsintrans, @co,
                        @mth, @batchid, @batchseq, @trans

                    IF @@rowcount <> @numrows 
                        BEGIN
                            SELECT  @errmsg = 'Unable to update '
                                    + @columnname + ' in ' + @postedtable,
                                    @rcode = 1
                            RETURN @rcode
                        END
                END
            ELSE 
                BEGIN
                    SELECT  @updatestring '@updatestring',
                            @paramsin '@paramsin',
                            @co '@co',
                            @mth '@mth',
                            @batchid '@batchid',
                            @batchseq '@batchseq'
                    EXEC sp_executesql @updatestring, @paramsin, @co, @mth,
                        @batchid, @batchseq
                    IF @@rowcount <> @numrows 
                        BEGIN
                            SELECT  @errmsg = 'Unable to update '
                                    + @columnname + ' in ' + @postedtable,
                                    @rcode = 1
                            RETURN @rcode
                        END
                END
        END
  

    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspBatchUserMemoInsertExisting] TO [public]
GO
