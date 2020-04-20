SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[bspBatchUserMemoUpdate]
   /***********************************************************
    * CREATED: kb 12/18/00
    * MODIFIED: GG 04/13/01 - replaced table references with views
    *           MV 05/01 - 06/01 Issue 12769 added @source coding
    *	    	GG 03/19/02 - #16702 - handle MO Entry source, added error message if update fails
    *	    	DF 03/26/02 - #16773 changed @@rowcount to <> to @numrows
    *           GG 04/05/02 - modified joins
    *           GG 04/08/02 - #16702 - remove @trans parameter 
    *           GG 04/15/02 - added IN MO Confirmation source
    *           RM 05/03/02 - Fixed MO Entry Item join string
    *           GG 05/15/02 - #17362 - fixed IN Adjustment source
    *           GG 07/18/02 - #18001 - fixed joins, added Trans where needed
    *           bc 10/17/02 - #19032 - added BatchTransType to statement just prior to destination table update  
    *			EN 10/17/02 - issue 19040  fixed to place quotes correctly in @whereclause around month value
    *			RM 01/07/03 - Issue 18281 - Add capabilities for EMMilesByState form.
    *			GF 04/22/2003 - Issue 21080 trigger errors not flowing back to front-end. Caused by select 1 statement
    *							to check for record to update. Changed to use a temp table, then check
    *							temp table value to see if user memo update should occur.
    *			GF 07/11/2003 - issue #21814 - added code to update 'MO Entry' and 'MO Entry Item' user memos.
    *			GF 09/30/2003 - issue #22600 missing source causes invalid object error. Exit if no source.
    *			MV 05/28/04 - #24687 bAPPB doesn't have TransType or BatchTransType
    *			GC 08/12/04 - #25214 - added check to make sure column exists before updating
    *			GF 01/14/2005 - #25726 changed exec update to sp_executesql statement. changed varchar to nvarchar
    *			DC 8/20/2007 - #125159 - Values for UD item fields not added back to batch
	*			GF 01/28/2008 - issue #126876 - use INTB.INTrans in where clause to update INDT for transfers
	*			GF 01/29/2008 - issue #126923 - do not update IN Production batch user memos.
	*			DC  01/30/2008 - #30175 - Allow UD fields in SLWH to update AP
    *			MH 02/04/2008 - Implemented #30175 for APUI and APUL.
	*			DANF 02/13/08 - Issue 125049 Improve user memo update process.
	*			mh 04/23/08 - Issue 127292 - Corrected update for PR Leave Entry
	*			EN 09/29/08 - #129874  changed '= null' to 'is null' in an 'if' comparison statement
	*			DC 1/26/09  - #131969  - Variable length insufficient
	*			CC 02/25/2009 - #132024 - added no lock to PRTH table HQBC join and the update string
	*			EN 4/15/2009 #133269 added no lock to PRTH table PRTH join in @joins
	*			EN 5/4/2009 #133269 added no lock to batch table 'from' 
	*			AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function.
	*			GF 10/23/2012 TK-18641 implemented update to APHB, APLB from SL Claims
	*			JayR 11/16/2012 TK-16638.  Change how the join is done to bPRTH so deadlocks do not occur.
	*			GF 01/09/2013 TK-20676 implemented update to INDT from INPB
	*
    *
    * USAGE
    *	Called by various batch posting procedures to update user memo
    *	columns as batch entries are posted.  Updates transaction detail
    *	tables with batch values.
    *
    * INPUT
    *	@co			Company
    *	@mth		Batch month
    *	@batchid	Batch ID#
    *	@batchseq	Batch sequence being updated
    *	@source		Batch source - indentifies the tables to update
    *
    * OUTPUT:
    *  @errmsg    	Error message
    *
    * RETURN VALUE
    *  @rcode		0 = success, 1 = error
    *
    *****************************************************/
    (
      @co bCompany = NULL,
      @mth bMonth = NULL,
      @batchid bBatchID = NULL,
      @batchseq INT = NULL,
      @source VARCHAR(255) = NULL,
      @errmsg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
   
   /* DC #131969 
   declare @rcode int, @validcnt int, @updatestring nvarchar(1000), @columnname varchar(30),
    		@formname varchar(30), @postedtable varchar(30), @batchtable varchar(30),
    		@joins varchar(1000), @whereclause varchar(1000), @numrows int,
   			@paramsin nvarchar(200), @rowcountparamsin nvarchar(200)
   	*/
	--DC #131969    			
    DECLARE @rcode INT,
        @validcnt INT,
        @updatestring NVARCHAR(MAX),
        @columnname VARCHAR(30),
        @formname VARCHAR(30),
        @postedtable VARCHAR(30),
        @batchtable VARCHAR(30),
        @joins VARCHAR(MAX),
        @whereclause VARCHAR(MAX),
        @numrows INT,
        @paramsin NVARCHAR(200),
        @rowcountparamsin NVARCHAR(200)
   			
    
    SELECT  @rcode = 0
    
    IF @source IS NULL 
       RETURN @rcode
   
   -- -- -- define parameters for exec sql statement #25726
    SET @paramsin = N'@co tinyint, @mth bMonth, @batchid int, @batchseq int'
    SET @rowcountparamsin = N'@co tinyint, @mth bMonth, @batchid int, @batchseq int, @validcnt int OUTPUT'

    IF @source = 'AP Entry' 
        BEGIN
            SELECT  @postedtable = 'APTH',
                    @formname = 'APEntry',
                    @batchtable = 'APHB',
                    @joins = ' join APTH d with (nolock) on d.APCo = b.Co and d.Mth = b.Mth and d.APTrans = b.APTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AP Entry Detail' 
        BEGIN
            SELECT  @postedtable = 'APTL',
                    @formname = 'APEntryDetail',
                    @batchtable = 'APLB',
                    @joins = ' join APTL d with (nolock) on d.APCo = b.Co and d.Mth = b.Mth and d.APLine = b.APLine '
                    + ' join APHB h with (nolock) on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId and h.BatchSeq = b.BatchSeq'
                    + ' and h.Co = d.APCo and h.Mth = d.Mth and h.APTrans = d.APTrans',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AP PayEdit' 
        BEGIN
            SELECT  @postedtable = 'APPH',
                    @formname = 'APPayEdit',
                    @batchtable = 'APPB',
                    @joins = ' join APPH d on d.APCo = b.Co and d.CMCo = b.CMCo and d.CMAcct = b.CMAcct'
                    + ' and d.PayMethod = b.PayMethod and d.CMRef = b.CMRef and d.CMRefSeq = b.CMRefSeq'
                    + ' and (d.EFTSeq = b.EFTSeq or (d.EFTSeq = 0 and b.EFTSeq is null))',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AR CashReceipts' 
        BEGIN
            SELECT  @postedtable = 'ARTH',
                    @formname = 'ARCashReceipts',
                    @batchtable = 'ARBH',
                    @joins = ' join ARTH d on d.ARCo = b.Co and d.Mth = b.Mth and d.ARTrans = b.ARTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'-- + ' and b.ARTrans = ' + convert(varchar(10),@trans)
        END
    
    IF @source = 'AR FinanceCharge' 
        BEGIN
            SELECT  @postedtable = 'ARTH',
                    @formname = 'ARFinChg',
                    @batchtable = 'ARBH',
                    @joins = ' join ARTH d on d.ARCo = b.Co and d.Mth = b.Mth and d.ARTrans = b.ARTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'-- + ' and b.ARTrans = ' + convert(varchar(10),@trans)
        END
    
    
    IF @source = 'AR FinanceChargeDetail' 
        BEGIN
            SELECT  @postedtable = 'ARTL',
                    @formname = 'ARFinChgLines',
                    @batchtable = 'ARBL',
                    @joins = ' join ARTL d on d.ARCo = b.Co and d.Mth = b.Mth and d.ARLine = b.ARLine '
                    + ' join ARBH h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId and h.BatchSeq = b.BatchSeq'
                    + ' and h.Co = d.ARCo and h.Mth = d.Mth and h.ARTrans = d.ARTrans',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AR InvoiceEntry' 
        BEGIN
            SELECT  @postedtable = 'ARTH',
                    @formname = 'ARInvoiceEntry',
                    @batchtable = 'ARBH',
                    @joins = ' join ARTH d on d.ARCo = b.Co and d.Mth = b.Mth and d.ARTrans = b.ARTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq' -- + ' and b.ARTrans = ' + convert(varchar(10),@trans)
        END
    
    IF @source = 'AR InvoiceEntryDetail' 
        BEGIN
            SELECT  @postedtable = 'ARTL',
                    @formname = 'ARInvoiceEntryLines',
                    @batchtable = 'ARBL',
                    @joins = ' join ARTL d on d.ARCo = b.Co and d.Mth = b.Mth and d.ARLine = b.ARLine '
                    + ' join ARBH h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId and h.BatchSeq = b.BatchSeq'
                    + ' and h.Co = d.ARCo and h.Mth = d.Mth and h.ARTrans = d.ARTrans',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'AR MiscRec' 
        BEGIN
            SELECT  @postedtable = 'ARTH',
                    @formname = 'ARMiscRec',
                    @batchtable = 'ARBH',
                    @joins = ' join ARTH d on d.ARCo = b.Co and d.Mth = b.Mth and d.ARTrans = b.ARTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'-- + ' and b.ARTrans = ' + convert(varchar(10),@trans)
        END
    
    IF @source = 'AR MiscRecDetail' 
        BEGIN
            SELECT  @postedtable = 'ARTL',
                    @formname = 'ARMiscRecLines',
                    @batchtable = 'ARBL',
                    @joins = ' join ARTL d on d.ARCo = b.Co and d.Mth = b.Mth and d.ARLine = b.ARLine '
                    + ' join ARBH h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId and h.BatchSeq = b.BatchSeq'
                    + ' and h.Co = d.ARCo and h.Mth = d.Mth and h.ARTrans = d.ARTrans',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    
    IF @source = 'CM Post' 
        BEGIN
    
            SELECT  @postedtable = 'CMDT',
                    @formname = 'CMPOST',
                    @batchtable = 'CMDB',
                    @joins = ' join CMDT d on d.CMCo = b.Co and d.Mth = b.Mth'
                    + ' and d.CMTrans = b.CMTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'CM Trans' 
        BEGIN
            SELECT  @postedtable = 'CMTT',
                    @formname = 'CMTR',
                    @batchtable = 'CMTB',
                    @joins = ' join CMTT d on d.CMCo = b.Co and d.Mth = b.Mth'
                    + ' and d.CMTransferTrans = b.CMTransferTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source IN ( 'EMCostAdj', 'EMFuelPosting', 'EMWOPartsPosting',
                    'EMWOTimeCards' ) 
        BEGIN
            SELECT  @formname = CASE @source
                                  WHEN 'EMCostAdj' THEN 'EMCostAdj'
                                  WHEN 'EMFuelPosting' THEN 'EMFuelPosting'
                                  WHEN 'EMWOPartsPosting'
                                  THEN 'EMWOPartsPosting'
                                  WHEN 'EMWOTimeCards' THEN 'EMWOTimeCards'
                                END
            SELECT  @postedtable = 'EMCD',
                    @batchtable = 'EMBF',
                    @joins = ' join EMCD d on d.EMCo = b.Co and d.Mth = b.Mth'
                    + ' and d.EMTrans = b.EMTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'EM LocXfer' 
        BEGIN
            SELECT  @postedtable = 'EMLH',
                    @formname = 'EMLocXfer',
                    @batchtable = 'EMLB',
                    @joins = ' join EMLH d on d.EMCo = b.Co and d.Month = b.Mth and d.Trans = b.MeterTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'EM MeterReadings' 
        BEGIN
            SELECT  @postedtable = 'EMMR',
                    @formname = 'EMMeterReadings',
                    @batchtable = 'EMBF',
                    @joins = ' join EMMR d on d.EMCo = b.Co and d.Mth = b.Mth and d.EMTrans = b.EMTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
   
        END
    
    IF @source = 'EM MilesByState' 
        BEGIN
            SELECT  @postedtable = 'EMSM',
                    @formname = 'EMMilesByState',
                    @batchtable = 'EMMH'
            SELECT  @joins = ' join EMSM d on d.Co = b.Co and d.Mth = b.Mth and d.EMTrans = b.EMTrans'
            SELECT  @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'EM MilesByState Lines' 
        BEGIN
            SELECT  @postedtable = 'EMSD',
                    @formname = 'EMMilesByStateLines',
                    @batchtable = 'EMML'
            SELECT  @joins = ' join EMSD d on d.Co = b.Co and d.Mth = b.Mth and d.EMTrans = b.EMTrans and b.Line=d.Line'
            SELECT  @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'EM UsePosting' 
        BEGIN
            SELECT  @postedtable = 'EMRD',
                    @formname = 'EMUsePosting',
                    @batchtable = 'EMBF',
                    @joins = ' join EMRD d on d.EMCo = b.Co and d.Mth = b.Mth and d.Trans = b.EMTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'GL JournalEntry' 
        BEGIN
            SELECT  @postedtable = 'GLDT',
                    @formname = 'GLJE',
                    @batchtable = 'GLDB',
                    @joins = ' join GLDT d on d.GLCo = b.Co and d.Mth = b.Mth and d.GLTrans = b.GLTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'GL Reversal' 
        BEGIN
            SELECT  @postedtable = 'GLDT',
                    @formname = 'GLREVRSL',
                    @batchtable = 'GLRB',
                    @joins = ' join GLDT d on d.GLCo = b.Co and d.Mth = b.Mth and d.BatchId = b.BatchId'
                    + ' and d.GLAcct = b.GLAcct and d.Amount = b.Amount',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'IN MO Confirm' 
        BEGIN
            SELECT  @postedtable = 'INDT',
                    @formname = 'INMOConf',
                    @batchtable = 'INCB',
                    @joins = ' join INDT d on d.INCo = b.Co and d.Mth = b.Mth and d.INTrans = b.INTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'IN Adjustments'	-- added INTrans to join clause
        BEGIN
            SELECT  @postedtable = 'INDT',
                    @formname = 'INAdjustments',
                    @batchtable = 'INAB',
                    @joins = ' join INDT d on d.INCo = b.Co and d.Mth = b.Mth and d.INTrans = b.INTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END

	----TK-20676
    if @source= 'IN Production'	-- may need Trans added to bINPB for join clause
        BEGIN
			SELECT  @postedtable = 'INDT',
					@formname = 'INProduction',
					@batchtable = 'INPB',
					@joins = ' join INDT d on d.INCo = b.Co and d.Mth = b.Mth and d.INTrans = b.INTrans',
					@whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
		END


    IF @source = 'IN Transfer'	-- may need Trans added to bINTB for join clause issue #126876
        BEGIN
            SELECT  @postedtable = 'INDT',
                    @formname = 'INTransfer',
                    @batchtable = 'INTB',
                    @joins = ' join INDT d on d.INCo = b.Co and d.Mth = b.Mth and d.INTrans = b.INTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source IN ( 'JCCOSTADJ', 'JCMatUse' )	-- added CostTrans to join clause
        BEGIN
            SELECT  @formname = CASE @source
                                  WHEN 'JCCOSTADJ' THEN 'JCCOSTADJ'
                                  WHEN 'JCMatUse' THEN 'JCMatUse'
                                END
            SELECT  @postedtable = 'JCCD',
                    @batchtable = 'JCCB',
                    @joins = ' join JCCD d on d.JCCo = b.Co and d.Mth = b.Mth'
                    + ' and d.CostTrans = b.CostTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'JC AdjRev' 
        BEGIN
            SELECT  @postedtable = 'JCID',
                    @formname = 'JCRevAdj',
                    @batchtable = 'JCIB',
                    @joins = ' join JCID d on d.JCCo = b.Co and d.Mth = b.Mth'
                    + ' and d.ItemTrans = b.ItemTrans',
                    @whereclause = ' where Co = @co and b.Mth =  @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'

        END
    
    IF @source = 'MO Entry' 
        BEGIN
            SELECT  @postedtable = 'INMO',
                    @formname = 'INMOEntry',
                    @batchtable = 'INMB',
                    @joins = ' join INMO d on d.INCo = b.Co and d.MO = b.MO',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    IF @source = 'MO Entry Items' 
        BEGIN
            SELECT  @postedtable = 'INMI',
                    @formname = 'INMOEntryItems',
                    @batchtable = 'INIB',
                    @joins = ' join INMI d on d.INCo = b.Co and d.MOItem = b.MOItem '
                    + 'join INMB h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId '
                    + 'and h.BatchSeq = b.BatchSeq and h.Co = d.INCo and h.MO = d.MO ',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'MS Haul' 
        BEGIN
            SELECT  @postedtable = 'MSHH',
                    @formname = 'MSHaulEntry',
                    @batchtable = 'MSHB',
                    @joins = ' join MSHH d on d.MSCo = b.Co and d.Mth = b.Mth and '
                    + 'd.HaulTrans = b.HaulTrans',-- and d.BatchId = b.BatchId',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq' -- + ' and d.HaulTrans =' + convert(varchar(10),@trans)
        END
    
    IF @source = 'MS HaulDetail' 
        BEGIN
            SELECT  @postedtable = 'MSTD',
                    @formname = 'MSHaulEntryLines',
                    @batchtable = 'MSLB',
                    @joins = ' join MSTD d on d.MSCo = b.Co and d.Mth = b.Mth'
                    + ' and d.MSTrans = b.MSTrans and d.BatchId = b.BatchId'
                    + ' join MSHH h on h.MSCo = d.MSCo and h.Mth = d.Mth'
                    + ' and h.HaulTrans = d.HaulTrans and h.BatchId = d.BatchId',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq' -- + ' and d.MSTrans =' + convert(varchar(10),@trans)
        END
    
    IF @source = 'MS Invoice' 
        BEGIN
            SELECT  @postedtable = 'MSIH',
                    @formname = 'MSInvEdit',
                    @batchtable = 'MSIB',
                    @joins = ' join MSIH d with (nolock) on d.MSCo = b.Co and d.Mth = b.Mth and d.MSInv = b.MSInv',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'MS Tickets'	-- added MSTrans to join clause
        BEGIN
            SELECT  @postedtable = 'MSTD',
                    @formname = 'MSTicEntry',
                    @batchtable = 'MSTB',
                    @joins = ' join MSTD d with (nolock) on d.MSCo = b.Co and d.Mth = b.Mth and b.MSTrans = d.MSTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq' -- + ' and d.MSTrans = ' + convert(varchar(10),@trans)
        END
    
    IF @source = 'PO ChgOrder' 
        BEGIN
            SELECT  @postedtable = 'POCD',
                    @formname = 'POChgOrder',
                    @batchtable = 'POCB',
                    @joins = ' join POCD d on d.POCo = b.Co and d.Mth = b.Mth and d.POTrans = b.POTrans'
                    + ' and d.PO = b.PO and d.POItem = b.POItem',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'PO Entry' 
        BEGIN
            SELECT  @postedtable = 'POHD',
                    @formname = 'POEntry',
                    @batchtable = 'POHB',
                    @joins = ' join POHD d on d.POCo = b.Co and d.PO = b.PO',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    IF @source = 'PO Entry Items' 
        BEGIN
            SELECT  @postedtable = 'POIT',
                    @formname = 'POEntryItems',
                    @batchtable = 'POIB',
                    @joins = ' join POIT d on d.POCo = b.Co and d.POItem = b.POItem '
                    + 'join POHB h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId '
                    + 'and h.BatchSeq = b.BatchSeq and h.Co = d.POCo and h.PO = d.PO ',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'PO Receipts' 
        BEGIN
            SELECT  @postedtable = 'PORD',
                    @formname = 'POReceipts',
                    @batchtable = 'PORB',
                    @joins = ' join PORD d on d.POCo = b.Co and d.Mth = b.Mth and d.POTrans = b.POTrans'
                    + ' and d.PO = b.PO and d.POItem = b.POItem',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'

        END

	--Issue 127292 mh 4/23/08  Passing in source from posting proc which is 'PR Leave'.  Corrected @formname from
	--PREmplLeave to PRLeaveEntry
    IF @source = 'PR Leave' /*'PR EmployeeLeave'*/ 
        BEGIN
            SELECT  @postedtable = 'PRLH',
                    @formname = 'PRLeaveEntry',
                    @batchtable = 'PRAB',
                    @joins = ' left join PRLH d on d.PRCo = b.Co and d.Mth = b.Mth and d.Trans = b.Trans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'PR TimeCards'	-- added join with bHQBC
        BEGIN
            SELECT  @postedtable = 'PRTH',
                    @formname = 'PRTimeCards',
                    @batchtable = 'PRTB',
                    @joins = ' join PRTH prth ON prth.PRTBKeyID = b.KeyID ',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'SL Entry' 
        BEGIN
            SELECT  @postedtable = 'SLHD',
                    @formname = 'SLEntry',
                    @batchtable = 'SLHB',
                    @joins = ' join SLHD d on d.SLCo = b.Co and d.SL = b.SL',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END

    IF @source = 'SL Entry Items' 
        BEGIN
            SELECT  @postedtable = 'SLIT',
                    @formname = 'SLEntryItems',
                    @batchtable = 'SLIB',
                    @joins = ' join SLIT d on d.SLCo = b.Co and d.SLItem = b.SLItem '
                    + 'join SLHB h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId '
                    + 'and h.BatchSeq = b.BatchSeq and h.Co = d.SLCo and h.SL = d.SL ',
                    @whereclause = ' where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END
    
    IF @source = 'SL ChgOrder' 
        BEGIN
            SELECT  @postedtable = 'SLCD',
                    @formname = 'SLChangeOrders',
                    @batchtable = 'SLCB',
                    @joins = ' join SLCD d on d.SLCo = b.Co and d.SL = b.SL and d.Mth = b.Mth'
                    + ' and d.SLTrans = b.SLTrans',
                    @whereclause = ' where Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @batchseq'
        END

		--DC - #30175
    IF @source = 'SL Worksheet' 
        BEGIN
            SELECT  @postedtable = 'APHB',
                    @formname = 'SLWorksheet',
                    @batchtable = 'SLWH',
                    @joins = ' join APHB d on d.SLKeyID = b.KeyID',
                    @whereclause = ' where Co = @co and d.Mth = @mth and d.BatchId = @batchid and d.BatchSeq = @batchseq'
        END
		--DC - #30175
    IF @source = 'SL WorksheetDetail' 
        BEGIN
            SELECT  @postedtable = 'APLB',
                    @formname = 'SLWorksheetItem',
                    @batchtable = 'SLWI',
                    @joins = ' join APLB d on d.SLDetailKeyID = b.KeyID',
                    @whereclause = ' where Co = @co and d.Mth = @mth and d.BatchId = @batchid and d.BatchSeq = @batchseq'
        END
        
	--mh - #30175
    IF @source = 'SLWorksheetAPUnapp' 
        BEGIN
            SELECT  @postedtable = 'APUI',
                    @formname = 'SLWorksheet',
                    @batchtable = 'SLWH',
                    @joins = ' join APUI d on d.SLKeyID = b.KeyID'
        END

	--mh - #30175
    IF @source = 'SLWorksheetDetail' 
        BEGIN
            SELECT  @postedtable = 'APUL',
                    @formname = 'SLWorksheetItem',
                    @batchtable = 'SLWI',
                    @joins = ' join APUL d on d.SLDetailKeyID = b.KeyID'
        END

	----TK-18641
    IF @source = 'SLClaim' 
        BEGIN
            SELECT  @postedtable = 'APHB',
                    @formname = 'SLClaims',
                    @batchtable = 'SLClaimHeader',
                    @joins = ' join APHB d on d.SLKeyID = b.KeyID'
        END

    IF @source = 'SLClaimItem' 
        BEGIN
            SELECT  @postedtable = 'APLB',
                    @formname = 'SLClaimsItems',
                    @batchtable = 'SLClaimItem',
                    @joins = ' join APLB d on d.SLDetailKeyID = b.KeyID'
        END

    IF @source = 'SLClaimAPUnapprove' 
        BEGIN
            SELECT  @postedtable = 'APUI',
                    @formname = 'SLClaims',
                    @batchtable = 'SLClaimHeader',
                    @joins = ' join APUI d on d.SLKeyID = b.KeyID'
        END

    IF @source = 'SLClaimItemAPUnapprove' 
        BEGIN
            SELECT  @postedtable = 'APUL',
                    @formname = 'SLClaimsItems',
                    @batchtable = 'SLClaimItem',
                    @joins = ' join APUL d on d.SLDetailKeyID = b.KeyID'
        END
    
    
   
    -- check to make sure there are records in this table. If not, then exit
    SELECT  @updatestring = 'select @validcnt=count(*) from ' + @batchtable
            + ' b with (nolock)' + ISNULL(@joins, '') + ISNULL(@whereclause,
                                                              '')
    -- get number of rows to be updated ('A' and 'C' entries only)
    -- select @updatestring = 'select 1 from ' + @batchtable + ' b ' + @joins + @whereclause
    
    -- #19032
    IF @batchtable IN ( 'ARBL', 'ARBH', 'JCCB', 'JCIB' ) 
        BEGIN
            IF EXISTS ( SELECT TOP 1
                                1
                        FROM    syscolumns
                        WHERE   name = 'TransType'
                                AND id = OBJECT_ID('dbo.' + @batchtable) ) 
                SELECT  @updatestring = @updatestring
                        + ' and b.TransType <> ''D'''
        END
    ELSE 
        IF @batchtable <> 'APPB'	--#24687 
            BEGIN
                IF EXISTS ( SELECT TOP 1
                                    1
                            FROM    syscolumns
                            WHERE   name = 'BatchTransType'
                                    AND id = OBJECT_ID('dbo.' + @batchtable) ) 
                    SELECT  @updatestring = @updatestring
                            + ' and b.BatchTransType <> ''D'''
            END

    EXEC sp_executesql @updatestring, @rowcountparamsin, @co, @mth, @batchid,
        @batchseq, @validcnt = @numrows OUTPUT
    IF @numrows = 0 
       RETURN @rcode
    
    
	-- get first user memo field assigned to the Form
    SELECT  @updatestring = NULL
   
    SELECT  @columnname = MIN(ColumnName)
			-- use inline table function for perf
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
                    IF @updatestring IS NULL --#129874
                        BEGIN
                            SELECT  @updatestring = 'update ' + @postedtable
                                    + ' set ' + @columnname + ' =  b.'
                                    + @columnname
                        END
                    ELSE 
                        BEGIN
                            SELECT  @updatestring = @updatestring + ','
                                    + @columnname + ' =  b.' + @columnname
                        END 
                END        
   
		-- get next user memo field
            SELECT  @columnname = MIN(ColumnName)
					-- use inline table funct for perf
            FROM    dbo.vfDDFIShared(@formname)
            WHERE	FieldType = 4
                    AND ColumnName LIKE 'ud%'
                    AND ColumnName > @columnname
        END	--end loop

    IF @updatestring IS NOT NULL 
        BEGIN
            SELECT  @updatestring = @updatestring + ' 
			from ' + @batchtable + ' b WITH (NOLOCK) ' + ISNULL(@joins,
                                                              '')
                    + ISNULL(@whereclause, '')

            IF @batchtable IN ( 'ARBL', 'ARBH', 'JCCB', 'JCIB' ) 
                BEGIN
   			-- #25214
                    IF EXISTS ( SELECT TOP 1
                                        1
                                FROM    syscolumns
                                WHERE   name = 'TransType'
                                        AND id = OBJECT_ID('dbo.'
                                                           + @batchtable) ) 
                        SELECT  @updatestring = @updatestring
                                + ' and b.TransType <> ''D'''
                END
            ELSE 
                IF @batchtable <> 'APPB'	--#24687 
                    BEGIN
   			-- #25214
                        IF EXISTS ( SELECT TOP 1
                                            1
                                    FROM    syscolumns
                                    WHERE   name = 'BatchTransType'
                                            AND id = OBJECT_ID('dbo.'
                                                              + @batchtable) ) 
                            SELECT  @updatestring = @updatestring
                                    + ' and b.BatchTransType <> ''D'''
                    END
			
            EXEC sp_executesql @updatestring, @paramsin, @co, @mth, @batchid,
                @batchseq

            IF @@rowcount <> @numrows 
                BEGIN
                    SELECT  @errmsg = 'Unable to update ' + @columnname
                            + ' in ' + @postedtable,
                            @rcode = 1
                   RETURN @rcode
                END
        END

    RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[bspBatchUserMemoUpdate] TO [public]
GO
