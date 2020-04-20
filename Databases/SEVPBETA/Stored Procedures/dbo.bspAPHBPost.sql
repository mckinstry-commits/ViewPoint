SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Stored Procedure dbo.bspAPHBPost    Script Date: 8/28/99 9:36:40 AM ******/
    CREATE          procedure [dbo].[bspAPHBPost]
     /***********************************************************
     * CREATED BY: SE 7/17/97
     * MODIFIED By : GG 07/02/99
     *             : GR 8/13/99 - added comptype and component to insert or update APTL
     *               GG 09/15/99 - pass PrePaidYN to bspAPHBPostAddDetail
     *               kb 12/14/99 - changed name of bcAPLB to bcAPLBcursor because this
     *                             cursor is used by the APLB triggers and error occurs
     *                             when it tries to open a cursor with the same name.
     *               EN 1/22/00 - expand dimension of @payname and include additional payname info when insert/update bAPTH
     *               GR 4/17/00 - added taxtype parameter for bspAPHBPostPOSL in order to update
     *                            InvCost in SLIT for sl type based on taxtype
     *               GR 5/10/00 - added DocName to insert into APTH
     *               GG 5/16/00 - update Stored Matls in bSLIT with SMChange from bAPLB
     *               GR 9/14/00 - added code for attachments
     *               GG 11/27/00 - changed datatype from bAPRef to bAPReference
     *               kb 12/4/00 - issue #11450, wasn't updating PrePaidSeq on a changed record
     *               DANF 05/14/01 - Added Update for Receipt Expense
     *               MV 05/30/01 - Issue 12769 - BatchUserMemoUpdate to APTH, APTL
     *               DANF 08/7/01 - Change order in which Receipt are backed out.
     *			    GG 08/10/01 - #14237 MS Intercompany Invoices
     *              MV 08/31/01 - #10997 EFT tax and child support payment addendas
     *         		kb 10/24/1 - Issue #15028
     *              TV 11/08/01 - Fix attachment ID
     *              kb 1/02/02 - Issue #15190
     *              kb 1/16/2 - Issue #14871
     *				GG 01/21/02 - #14022 - update bAPTH.ChkRev
     *              kb 1/31/2 - Issue #14871
     *              TV/RM 02/22/02 - Reworking the Attachments
     *				GG 03/19/02 - #16702 - UserMemo update fix, cleanup
     *              MV 03/27/02 - #14164 allow changes to paid transactions
     *              CMW 04/03/02 - increased InvId from 5 to 10 char (issue # 16366)
     *              CMW 04/04/02 - Added bHQBC.Notes interface levels update (issue # 16692)
     *              TV  04/05/02 - Added code to pass the APTrans back to bAPUR
     *				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
     *              TV 04/08/02 - Added note transfer from batch to transaction
     *			  	MV 07/15/02 - #17663 - pass @chkrev to bspAPHBPostAddDetail
     *              kb 10/28/2 - issue #18878 - fix double quotes
     *			  	MV 11/04/02 - #18037 insert or update AddressSeq in bAPTH
     *			  	RM 11/04/02 - Added code to refresh indexes on post or 'A' and 'C' records
     *			 	RM 03/12/03 - Took Attachment Index Refresh Code out of Transaction (Issue# 20697)
     *			 	RM 03/21/03 - Took out unnecessary update to HQAT.  20697
     *				MV 04/16/03 - #20940 update memos in paid transactions.
     *				MV 05/16/03	- #18763 - insert or update POPayType in bAPTL
     *				MV 07/08/03	- #21776 - old tax amt was not getting backed out of bAPVA on changed lines
     *				GF 08/11/03 - issue #22112 - performance improvements
     *				DF 09/23/03 - 22303 - Added update of AP transaction number to PO distribution tables.
     *				GF 10/29/03 - issue #22825 - added user memo check to only update when user memos exist.
     *				MV 11/26/03 - #23061 isnull wrap
     *				GF 12/10/2003 - issue #23067 - change way user memos are updated, and now updates APTrans
     *								in one update statement before cursor. Performance purposes.
     *				MV 02/10/04 - #18769 - Pay Category
     *				ES 03/11/04 - #23061 - isnull wrap
     *				MV 05/26/04 - #24655 - pass @oldtaxtype,@oldtaxtype to bspAPHBPostPOSL
	 *				MV 03/12/08 - #127347 - International addresses
     *              MV 07/01/08 - #128288 - pass taxtype,taxcode to bspAPHBPostDetail
     *              MV 07/15/08 - #128288 - add taxamt to gross if taxtype 1, 3
	 *				MV 08/20/08 - #127994 - update bAPVM with LastInvDate, '01/01/1999' 4 digit year
	 *				GP 10/30/08 - #130576 - changed text datatype to varchar(max)
	 *				MV 12/03/08 - #131314 - delete bHQAT only if @guid is not null
	 *				MV 02/09/09 - #123778 - insert/update Receiver# from bAPLB to bAPTL
	 *				MV 02/17/09 - #132257 - When deleting a line, amt in bAPVA was getting backed out but then readded 
	 *				TJL 03/06/09 - #129889 - SL Claims and Certifications
	 *				TJL 03/25/09 - #132888 - Only last line in APUL gets deleted upon posting to APTL
	 *				MV 06/01/09 - #133431 - commented out delete of attachid in HQAT per issue #127603
	 *				MV 11/17/09 - #133119 - update bAPTD.AuditYN flag before deleting hold codes.
	 *				DC 12/30/09 - #130175 - SLIT needs to match POIT
	 *				GP 6/28/10 - #135813 change bSL to varchar(30) 
	 *				MH 03/21/11 - TK-02793
	 *				GF 08/04/2011 - TK-07144 expand PO
	 *				MH 08/09/11 - TK-07482 Replace MiscellaneousType with SMCostType
	 *				MV 08/10/11 - TK-07621 AP project to use POItemLine
	 *				JVH 9/6/11 - TK-08137 Capture cost for PO Lines for transfering cost
	 *				JG 01/23/2012  - TK-11971 - Added JCCostType and PhaseGroup
	 *				MV 01/25/12 - TK-11876 - AP On-Cost
	 *				CHS	01/27/2012 - TK-11876 - AP On-Cost
	 *				MV 03/22/12 - TK-13268 AP OnCost SchemeID, MembershipNbr.
	 *				TRL 04/12/2 - TK-13994 Add Column SM Phase
	 *				MV 04/26/12 - TK-14041 handle changes to SubjToOnCostYN
	 *				GF 11/15/2012 TK-19327 SL Claim Work add column SLKeyID
	 *				GF 11/21/2012 TK-19414 SL Claim Status/Certify on delete
	 *				
     *
     * USAGE:
     *
     * Called from AP Batch Processing form to post a validated
     * batch of AP transactions.  Calls bspAPHBPostJC, bspAPHBPostGL,
     * bspAPHBPostEM, and bspAPHBPostIN to update other modules.
     *
     * INPUT PARAMETERS:
    
     *   @co             AP Co#
     *   @mth            Batch Month
     *   @batchid        Batch Id
     *   @dateposted     Posting date
     *
     * OUTPUT PARAMETERS
     *   @errmsg         error message if something went wrong
     *
     * RETURN VALUE:
     *   0               success
     *   1               fail
     *****************************************************/
    (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(100) output)
    as
    set nocount on
     
    declare @rcode int, @opencursor tinyint, @openAPLBcursor tinyint, @retholdcode bHoldCode,
     	@seq int,@transtype char(1), @description bDesc, @discdate bDate, @duedate bDate, @invtotal bDollar,
     	@holdcode bHoldCode, @paycontrol varchar(10), @paymethod char(1), @cmco bCompany, @cmacct bCMAcct,
     	@prepaidyn bYN, @prepaidmth bMonth, @prepaiddate bDate, @prepaidchk bCMRef, @v1099yn bYN,
     	@v1099type varchar(10), @v1099box tinyint, @payoverrideyn bYN, @payname varchar(60),
     	@payaddinfo varchar(60), @payaddress varchar(60),
     	@paycity varchar(30), @paystate varchar(4), @payzip bZip, @invid char(10), @uimth bMonth, @uiseq smallint,
     	@oldholdcode bHoldCode, @jcco bCompany, @job bJob, @sl varchar(30), @slitem bItem, @po VARCHAR(30), @poitem bItem,
     	@POItemLine INT, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @units bUnits, @matlgroup bGroup,
     	@um bUM, @glco bCompany, @glacct bGLAcct, @ecm bECM, @retpaytype tinyint, @errorstart varchar(50),
     	@aptdstatus tinyint, @apline smallint, @aptrans bTrans, @vendorgroup bGroup, @vendor bVendor,
     	@oldvendorgroup bGroup, @oldvendor bVendor, @invdate bDate, @apref bAPReference, @linetype tinyint,
     	@linedesc bDesc, @emco bCompany, @equipment bEquip, @emgroup bGroup, @costcode bCostCode,
     	@emctype bEMCType, @comptype varchar(10), @component bEquip,
     	@inco bCompany, @loc bLoc, @polinetype tinyint, @msg varchar(60), @linetranstype char(1),
     	@itemtype tinyint, @oldpo VARCHAR(30), @wo bWO, @paytype tinyint, @oldsl varchar(30), @oldpoitem bItem, @OldPOItemLine INT,
     	@woitem bItem,@discount bDollar, @oldslitem bItem, @grossamt bDollar, @amt bDollar, @oldgrossamt bDollar, @equip bEquip,
     	@svendorgroup bGroup, @supplier bVendor, @oldunits bUnits, @miscyn bYN, @matl bMatl, @unitcost bUnitCost, @miscamt bDollar,
     	@oldmiscamt bDollar, @taxgroup bGroup, @taxtype tinyint, @oldmiscyn bYN, @taxcode bTaxCode, @taxamt bDollar,
     	@oldtaxamt bDollar, @oldlinetype tinyint, @oldtaxtype tinyint, @taxbasis bDollar, @retainage bDollar,
     	@burunitcost bUnitCost, @becm bECM, @olditemtype tinyint, @oldpaytype tinyint, @oldretainage bDollar, @prepaidseq tinyint,
     	@docname varchar(128), @smchange bDollar, @keyfield varchar(255), @updatekeyfield varchar(255),
     	@deletekeyfield varchar(128), @msco bCompany, @msinv varchar(10),@addendatypeid tinyint, @prco bCompany,
     	@employee bEmployee, @dlcode bEDLCode, @taxformcode varchar (10), @taxperiodenddate bDate,@amounttype varchar (10),
     	@amount bDollar, @amttype2 varchar (10), @amount2 bDollar, @amttype3 varchar(10), @amount3 bDollar,
     	@separatepayyn bYN, @chkrev bYN, @guid uniqueidentifier, @headerpaidyn bYN, @linepaidyn bYN, @Notes varchar(256),
        @batchnotes varchar(2000), @popaytypeyn bYN, @aptlud_flag bYN, @apthud_flag bYN,
    	@h_join varchar(2000),  @h_where varchar(2000), @h_update varchar(2000), @l_join varchar(2000),
    	@l_where varchar(2000), @l_update varchar(2000), @sql varchar(8000), @aphb_count bTrans, @aphb_trans bTrans,
    	@paycategory int, @APretpaytype tinyint, @paycountry char(2),@oldtaxgroup bGroup, @oldtaxcode bTaxCode, @receiver# varchar(20),
		@aplbslkeyid bigint,
		@oldtaxbasis bDollar,  --DC #130175
		@smco bCompany, @smworkorder int, @scope int, @smcosttype smallint, @smstandarditem varchar(20), 
		@oldsmco bCompany, @oldsmworkorder int, @oldscope int, @oldsmcosttype smallint, @oldsmstandarditem varchar(20),
		@aptlkeyid BIGINT, @smjccosttype dbo.bJCCType, @oldsmjccosttype dbo.bJCCType, @smphasegroup dbo.bGroup, @oldsmphasegroup dbo.bGroup,
		@smphase dbo.bPhase, @oldsmphase dbo.bPhase,
		@SubjToOnCostYN bYN, @OldSubjToOnCostYN bYN, 
		@ocApplyMth bMonth, @ocApplyTrans bTrans, @ocApplyLine smallint, @ATOCategory varchar(4),@ocSchemeID smallint,
		@ocMembership# VARCHAR(60),@OnCostStatus tinyint
		----TK-19327
		,@SLKeyID BIGINT
     
    select @rcode = 0, @opencursor = 0, @openAPLBcursor = 0, @aptlud_flag = 'N', @apthud_flag = 'N',
    	   @aphb_count = 0, @aphb_trans = 0
     
    -- call bspUserMemoQueryBuild to create update, join, and where clause
    -- pass in source and destination. Remember to use views only unless working
    -- with a Viewpoint (bidtek) connection. FOR APHB -> APTH
    exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'APHB', 'APTH', @apthud_flag output,
    			@h_update output, @h_join output, @h_where output, @errmsg output
    if @rcode <> 0 goto bspexit
     
    -- call bspUserMemoQueryBuild to create update, join, and where clause
    -- pass in source and destination. Remember to use views only unless working
    -- with a Viewpoint (bidtek) connection. FOR APLB -> APTL
    exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'APLB', 'APTL', @aptlud_flag output,
    			@l_update output, @l_join output, @l_where output, @errmsg output
    if @rcode <> 0 goto bspexit
    
    --Make sure the batch can be posted and set it as posting in progress.
	EXEC @rcode = dbo.vspHQBatchPosting @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @Source = 'AP Entry', @TableName = 'APHB', @DatePosted = @dateposted, @msg = @errmsg OUTPUT
	IF @rcode <> 0 goto bspexit
    
    -- get count of APTB rows that need a APTrans
    select @aphb_count = count(*) from bAPHB with (nolock)
    where Co=@co and Mth=@mth and BatchId=@batchid and BatchTransType = 'A' and APTrans is null
    -- only update HQTC and APHB if there are APHB rows that need updating
    if @aphb_count <> 0
    	begin
      	-- get next available Transaction # for MS Trans Detail
      	exec @aptrans = dbo.bspHQTCNextTransWithCount 'bAPTH', @co, @mth, @aphb_count, @msg output
      	if @aptrans = 0
      		begin
      		select @errmsg = 'Unable to get APTrans from HQTC!', @rcode = 1
      		goto bspexit
      		end
      
      	-- set @mstb_trans to last transaction from bHQTC as starting point for update
      	set @aphb_trans = @aptrans - @aphb_count
      	
      	-- update bAPHB and set APTrans
      	update bAPHB set @aphb_trans = @aphb_trans + 1, APTrans = @aphb_trans
      	where Co=@co and Mth=@mth and BatchId=@batchid and BatchTransType = 'A' and APTrans is null
      	-- compare count from update with MSTB rows that need to be updated
      	if @@rowcount <> @aphb_count
      		begin
      		select @errmsg = 'Error has occurred updating APTrans in APHB batch!', @rcode = 1
      		goto bspexit
      		end
      
      	-- have now successfully updated APTrans to APHB, now update distribution tables
    	-- update bAPGL
    	update bAPGL set APTrans = b.APTrans
    	from bAPGL a join bAPHB b on b.Co=a.APCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
    	where a.APCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.BatchSeq=b.BatchSeq and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
    	-- update bAPJC
    	update bAPJC set APTrans = b.APTrans
    	from bAPJC a join bAPHB b on b.Co=a.APCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
    	where a.APCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.BatchSeq=b.BatchSeq and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
    	-- update bAPEM
    	update bAPEM set APTrans = b.APTrans
    	from bAPEM a join bAPHB b on b.Co=a.APCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
    	where a.APCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.BatchSeq=b.BatchSeq and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
    	-- update bAPIN
    	update bAPIN set APTrans = b.APTrans
    	from bAPIN a join bAPHB b on b.Co=a.APCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
    	where a.APCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.BatchSeq=b.BatchSeq and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
    
        -- update POTrans with APTrans to PO distribution for PO Receipt Expenses
    	-- update bPORG
    	update bPORG set POTrans = b.APTrans
    	from bPORG a join bAPHB b on b.Co=a.POCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
    	where a.POCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.BatchSeq=b.BatchSeq and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
    	-- update bPORJ
    	update bPORJ set POTrans = b.APTrans
    	from bPORJ a join bAPHB b on b.Co=a.POCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
    	where a.POCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.BatchSeq=b.BatchSeq and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
    	-- update bPORE
    	update bPORE set POTrans = b.APTrans
    	from bPORE a join bAPHB b on b.Co=a.POCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
    	where a.POCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.BatchSeq=b.BatchSeq and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
    	-- update bPORN
    	update bPORN set POTrans = b.APTrans
    	from bPORN a join bAPHB b on b.Co=a.POCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
    	where a.POCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.BatchSeq=b.BatchSeq and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
       	end

--TK-02798
	update vAPSM set APTrans = b.APTrans
	from vAPSM a join bAPHB b on b.Co=a.APCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
	where a.APCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.BatchSeq=b.BatchSeq and b.Co=@co and b.Mth=@mth
  	and b.BatchId=@batchid and b.BatchTransType='A'
    
    --None of the batch gl entries get the trans set even though the may be for a change record because the trans is not
    --passed to the procs that create the gl entries so we update all records regardless of whether they are an 'A' or not.
	UPDATE vGLEntryBatch
	SET Trans = bAPHB.APTrans
	FROM dbo.bAPHB
		INNER JOIN dbo.vGLEntryBatch ON bAPHB.Co = vGLEntryBatch.Co AND bAPHB.Mth = vGLEntryBatch.Mth AND bAPHB.BatchId = vGLEntryBatch.BatchId AND bAPHB.BatchSeq = vGLEntryBatch.BatchSeq
	WHERE bAPHB.Co = @co AND bAPHB.Mth = @mth AND bAPHB.BatchId = @batchid
    
    -- get AP company info
    select @APretpaytype = RetPayType, @retholdcode = RetHoldCode
    from bAPCO with (nolock) where APCo = @co
     
    -- declare cursor on AP Header Batch
    declare bcAPHB cursor local fast_forward for
    select BatchSeq, BatchTransType, APTrans, VendorGroup, Vendor, APRef, Description, InvDate,
    	DiscDate, DueDate, InvTotal, HoldCode, PayControl, PayMethod, CMCo, CMAcct, PrePaidYN,
    	PrePaidMth, PrePaidDate, PrePaidChk, PrePaidSeq, V1099YN, V1099Type, V1099Box, PayOverrideYN,
    	PayName, PayAddInfo, PayAddress, PayCity, PayState,PayZip, InvId, OldHoldCode, UIMth, UISeq, OldVendorGroup, OldVendor,
    	DocName, MSCo, MSInv, AddendaTypeId, PRCo,Employee, DLcode, TaxFormCode,TaxPeriodEndDate,
    	AmountType, Amount, AmtType2, Amount2, AmtType3, Amount3, SeparatePayYN, ChkRev, UniqueAttchID, 
    	PaidYN, PayCountry
		----TK-19327
		,SLKeyID
    from bAPHB 
    where Co = @co and Mth = @mth and BatchId = @batchid
     
    -- open AP Batch Header cursor
    open bcAPHB
    select @opencursor = 1
     
    -- loop through all rows in AP Header Batch cursor
    ap_posting_loop:
    fetch next from bcAPHB into @seq, @transtype, @aptrans, @vendorgroup, @vendor, @apref,
             @description, @invdate, @discdate, @duedate, @invtotal, @holdcode, @paycontrol,
      	    @paymethod, @cmco, @cmacct, @prepaidyn, @prepaidmth, @prepaiddate,
      	    @prepaidchk, @prepaidseq, @v1099yn, @v1099type, @v1099box, @payoverrideyn, @payname,
           	@payaddinfo, @payaddress, @paycity, @paystate, @payzip, @invid, @oldholdcode, @uimth,
     		@uiseq, @oldvendorgroup, @oldvendor, @docname, @msco, @msinv, @addendatypeid, @prco,
           	@employee, @dlcode, @taxformcode, @taxperiodenddate, @amounttype, @amount, @amttype2,
           	@amount2, @amttype3, @amount3, @separatepayyn, @chkrev, @guid, @headerpaidyn,@paycountry
			----TK-19327
			,@SLKeyID

    if @@fetch_status = -1 goto ap_posting_end
    if @@fetch_status <> 0 goto ap_posting_loop
     
    select @errorstart = 'Seq#: ' + isnull(convert(varchar(6),@seq),'') --#23061
     
    -- determine detail status - 1 = open, 2 = hold
    select @aptdstatus = 1
    if @holdcode is not null and @prepaidyn = 'N' -- issue #15190
         	begin
           	select @aptdstatus = 2    -- transaction is on hold
           	end
    
    -- check for Vendor Hold codes
    if exists(select 1 from bAPVH with (nolock) where APCo = @co and VendorGroup = @vendorgroup
    		and Vendor = @vendor and @prepaidyn = 'N') --issue #15190
    	begin
    	select @aptdstatus = 2
    	end
     
    begin transaction       -- start a transaction, commit after all lines have been processed
     
    if @transtype = 'A'	    -- new AP transaction header
    	begin
    -- 	-- get next available Transaction # for APTH
    -- 	exec @aptrans = bspHQTCNextTrans 'bAPTH', @co, @mth, @msg output
    -- 	if @aptrans = 0 goto ap_posting_error
     
    	-- add AP Transaction Header
    	insert bAPTH(APCo, Mth, APTrans, VendorGroup, Vendor, InvId, APRef, Description,
    			InvDate, DiscDate, DueDate, InvTotal, HoldCode, PayControl, PayMethod,
    			CMCo, CMAcct, PrePaidYN, PrePaidMth, PrePaidDate, PrePaidChk, PrePaidSeq, PrePaidProcYN,
    			V1099YN, V1099Type, V1099Box, PayOverrideYN, PayName, PayAddInfo, PayAddress, PayCity, PayState,
    			PayZip, PayCountry, OpenYN, BatchId, Purge, InPayControl, DocName, AddendaTypeId, PRCo, Employee, DLcode,
    			TaxFormCode, TaxPeriodEndDate, AmountType, Amount, AmtType2, Amount2, AmtType3, Amount3,
    			SeparatePayYN, ChkRev, UniqueAttchID,Notes, AddressSeq
				----TK-19327
				,SLKeyID)
    	select Co, Mth, @aptrans, VendorGroup, Vendor, InvId, APRef, Description,
    			InvDate, DiscDate, DueDate, InvTotal, HoldCode, PayControl, PayMethod,
    			CMCo, CMAcct, PrePaidYN, PrePaidMth, PrePaidDate, PrePaidChk, PrePaidSeq, PrePaidProcYN,
    			V1099YN, V1099Type, V1099Box, PayOverrideYN, PayName, PayAddInfo, PayAddress, PayCity, PayState,
    			PayZip, PayCountry,'Y', BatchId, 'N', 'N', DocName, AddendaTypeId, PRCo, Employee, DLcode,
    			TaxFormCode, TaxPeriodEndDate, AmountType, Amount, AmtType2, Amount2, AmtType3, Amount3,
    			SeparatePayYN, ChkRev, UniqueAttchID, Notes, AddressSeq
				----TK-19327
				,SLKeyID
    	from bAPHB with (nolock)
    	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    	if @@rowcount = 0
    		begin
    		select @errmsg = 'Unable to add AP Transaction Header.'
    		goto ap_posting_error
    		end
     
    -- 	-- update AP Trans# to distribution tables
    -- 	update bAPGL set APTrans = @aptrans where APCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    -- 	update bAPJC set APTrans = @aptrans where APCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    -- 	update bAPEM set APTrans = @aptrans where APCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    -- 	update bAPIN set APTrans = @aptrans where APCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    -- 	-- AP Trans# to batch header for BatchUserMemoUpdate 
    -- 	update bAPHB set APTrans = @aptrans where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    -- 
    --     -- update PO Trans# With AP transaction to PO distribution for PO Receipt Expenses.
    --     update bPORG set POTrans = @aptrans where POCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    --     update bPORJ set POTrans = @aptrans where POCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    --     update bPORE set POTrans = @aptrans where POCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    --     update bPORN set POTrans = @aptrans where POCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    
    
    	--Pass the APTrans # back to the bAPUR table
    	if @uiseq is not null
    		begin
    		update bAPUR set APTrans = @aptrans, ExpMonth = @mth
    		where APCo = @co and UIMth = @uimth and UISeq = @uiseq and APTrans is null and ExpMonth is null
    		end
    
		---- TK-19327 update claim header reference and invoice info
		IF @SLKeyID IS NOT NULL
			BEGIN      
			UPDATE dbo.vSLClaimHeader SET APRef = h.APRef, InvoiceDesc = h.[Description], InvoiceDate = h.InvDate
			from dbo.bAPTH h with (nolock)
			INNER JOIN dbo.vSLClaimHeader c ON c.KeyID = h.SLKeyID
			WHERE h.SLKeyID = @SLKeyID
			END        
        
    	--update Attachments
    	/*update bHQAT set FormName='APEntry', TableName = 'APTH'
    	from bHQAT t join bAPHB b
    	on t.UniqueAttchID = b.UniqueAttchID
    	where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid*/
     
    	-- update Last Invoice Date in Vendor Master
    	update bAPVM set LastInvDate = @invdate
    	where VendorGroup = @vendorgroup and Vendor = @vendor and isnull(LastInvDate,'01/01/1999') < @invdate
     
    	-- use cursor to process all lines for the new transaction
    	declare bcAPLBcursor cursor local fast_forward for
    	select APLine, BatchTransType, LineType, PO, POItem, POItemLine, ItemType, SL, SLItem, JCCo, Job, PhaseGroup, Phase,
                 	JCCType, EMCo, WO, WOItem, Equip, EMGroup, CostCode, EMCType, CompType, Component, INCo, Loc, MatlGroup,
                 	Material, GLCo, GLAcct, Description, UM, Units, UnitCost, ECM, VendorGroup, Supplier, PayType, GrossAmt,
                 	MiscAmt, MiscYN, TaxGroup, TaxCode, TaxType, TaxBasis, OldTaxBasis, TaxAmt, Retainage, Discount, BurUnitCost, BECM, --DC #130175
					SMChange, Notes, POPayTypeYN, PayCategory, Receiver#, SLKeyID, SMCo, SMWorkOrder, Scope, SMCostType, SMStandardItem,
					SMJCCostType, SMPhaseGroup,SMPhase,
					SubjToOnCostYN, ocApplyMth, ocApplyTrans, ocApplyLine, ATOCategory,ocSchemeID,ocMembershipNbr
    	from bAPLB
    	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
     
    	-- open AP Line cursor
    	open bcAPLBcursor
    	select @openAPLBcursor = 1
     
    	-- loop through all rows in AP Line cursor
    	ap_addline_loop:
    	fetch next from bcAPLBcursor into @apline, @linetranstype, @linetype, @po, @poitem, @POItemLine, @itemtype,
     				@sl, @slitem, @jcco, @job, @phasegroup, @phase, @jcctype, @emco, @wo, @woitem, @equip, @emgroup,
     				@costcode, @emctype, @comptype, @component, @inco, @loc, @matlgroup, @matl, @glco, @glacct,
     				@linedesc, @um, @units, @unitcost, @ecm, @svendorgroup, @supplier, @paytype, @grossamt, @miscamt,
     				@miscyn, @taxgroup, @taxcode, @taxtype, @taxbasis, @oldtaxbasis, @taxamt, @retainage, @discount, @burunitcost,  --DC#130175
     				@becm, @smchange, @batchnotes, @popaytypeyn, @paycategory, @receiver#, @aplbslkeyid, @smco, @smworkorder, 
     				@scope, @smcosttype, @smstandarditem, @smjccosttype, @smphasegroup, @smphase, @SubjToOnCostYN,
     				@ocApplyMth, @ocApplyTrans, @ocApplyLine, @ATOCategory,@ocSchemeID,@ocMembership#

    	if @@fetch_status = -1 goto ap_addline_end
    	if @@fetch_status <> 0 goto ap_addline_loop

  
    	-- add a new AP Line
    	insert bAPTL (APCo, Mth, APTrans, APLine, LineType, PO, POItem, POItemLine, ItemType,
     	            SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType, EMCo, WO, WOItem, Equip,
     	        	EMGroup, CostCode, EMCType, CompType, Component, INCo, Loc, MatlGroup, Material, GLCo, GLAcct,
     	        	Description, UM, Units, UnitCost, ECM, VendorGroup, Supplier, PayType,
     	        	GrossAmt, MiscAmt, MiscYN, TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt,
     	        	Retainage, Discount, BurUnitCost, BECM, Notes, POPayTypeYN, PayCategory, Receiver#, SLKeyID,
     	        	SMCo, SMWorkOrder, Scope, SMCostType, SMStandardItem, SMJCCostType, SMPhaseGroup,SMPhase,
					SubjToOnCostYN, OnCostStatus, ocApplyMth, ocApplyTrans, ocApplyLine, ATOCategory,ocSchemeID,ocMembershipNbr)
     	        	
    	values(@co, @mth, @aptrans, @apline, @linetype, @po, @poitem, @POItemLine, @itemtype, @sl, @slitem,
     	            @jcco, @job, @phasegroup, @phase, @jcctype, @emco, @wo, @woitem, @equip, @emgroup,
     	            @costcode, @emctype, @comptype, @component, @inco, @loc, @matlgroup, @matl, @glco, @glacct, @linedesc,
     	           	@um, @units, @unitcost, @ecm, @svendorgroup, @supplier, @paytype, @grossamt, @miscamt,
     	            @miscyn, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt, @retainage, @discount, @burunitcost, 
                    @becm, @batchnotes, @popaytypeyn, @paycategory, @receiver#, @aplbslkeyid, @smco, @smworkorder, 
     				@scope, @smcosttype, @smstandarditem, @smjccosttype, @smphasegroup,@smphase,
					@SubjToOnCostYN, CASE @SubjToOnCostYN WHEN 'Y' THEN 0 ELSE NULL END,
					@ocApplyMth, @ocApplyTrans, @ocApplyLine, @ATOCategory, @ocSchemeID,@ocMembership#)
     				
     	
    	--18769 get retpaytype from PayCategory else use APCO retpaytype
    	if @paycategory is not null
    		begin
    		select @retpaytype=RetPayType from bAPPC with (nolock)
    			where APCo=@co and PayCategory=@paycategory
    		end
    	else
    		begin
    		select @retpaytype=@APretpaytype
    		end
    
    	-- add Trans and Hold Detail
    	exec @rcode = dbo.bspAPHBPostAddDetail @co, @mth, @aptrans, @apline, @paytype, @discount,
     	              	@duedate, @aptdstatus, @svendorgroup, @supplier, @holdcode, @grossamt, @miscamt,
     	              	@miscyn, @taxtype, @taxamt, @retainage, @retpaytype, @retholdcode, @vendorgroup,
     	             	@vendor, @prepaidyn, @chkrev, @paycategory, @taxgroup, @taxcode
    	if @rcode <> 0
    		begin
    		select @errmsg = isnull(@errorstart,'') + ' Unable to add AP Transaction Detail.'
    		goto ap_posting_error
    		end

    	-- update PO and SL Items
    	select @oldpo = null, @oldsl = null
    	exec @rcode = dbo.bspAPHBPostPOSL @co, @errorstart, @linetranstype, @oldpo, @oldpoitem, @OldPOItemLine, @oldsl, @oldslitem,
     	            	@oldunits, @oldgrossamt, @oldmiscamt, @oldmiscyn, @oldtaxtype,@oldtaxamt, @po, @poitem, @POItemLine, @sl,
     	            	@slitem, @units, @grossamt, @miscamt, @miscyn, @taxamt, @taxtype, @smchange,
     	            	@taxbasis, @oldtaxbasis, --DC #130175
     	            	@errmsg output
    	if @rcode <> 0 goto ap_posting_error
     
    	-- update Recurring Invoice Header info - may include Misc Amount and Sales Tax
    	if @invid is not null
    		begin
    		select @amt = @grossamt + case @miscyn when 'Y' then @miscamt else 0 end
                         	+ case @taxtype when 2 then 0 else @taxamt end
--     	                	+ case @taxtype when 1 then @taxamt else 0 end
    		update bAPRH set InvToDate = InvToDate + @amt, LastMth = @mth
    		where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor and InvId = @invid
    		if @@rowcount = 0
    			begin
    			select @errmsg = isnull(@errorstart,'') + '  Unable to update Recurring Invoice information for Vendor ' + isnull(convert(varchar(10),@vendor), '')
     	                                             + ' and Invoice ID ' + isnull(convert(varchar(10),@invid), '') --#23061
    			goto ap_posting_error
    			end
    		end
     
    	-- update Vendor Activity - Invoiced Amount may include Misc Amount and Sales Tax
    	select @amt = @grossamt + case @miscyn when 'Y' then @miscamt else 0 end
                        + case @taxtype when 2 then 0 else @taxamt end
--     	            	+ case @taxtype when 1 then @taxamt else 0 end
    	if @amt <> 0
    		begin
    		update bAPVA set InvAmt = InvAmt + @amt, AuditYN = 'N'
    		where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor and Mth = @mth
    		if @@rowcount = 0
    			begin
    			insert bAPVA(APCo, VendorGroup, Vendor, Mth, InvAmt, PaidAmt, DiscOff, DiscTaken, AuditYN)
    			values(@co, @vendorgroup, @vendor, @mth, @amt, 0, 0, 0, 'N')
    			end
    		-- reset audit flag
    		update bAPVA set AuditYN = 'Y'
    		where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor and Mth = @mth
    		if @@rowcount = 0
    			begin
    			select @errmsg = isnull(@errorstart,'') + ' Unable to update Vendor Activity audit flag'
    			goto ap_posting_error
    			end
    		end
    
    
    	 	if @aptlud_flag = 'Y'
    	   		begin
    	   		-- update where clause with BatchSeq, APTrans, and APLine, create @sql and execute
    	 		set @sql = @l_update + @l_join + @l_where 
    						+ ' and b.BatchSeq = ' + isnull(convert(varchar(10),@seq), '') --#23061
    						+ ' and b.APLine = ' + isnull(convert(varchar(6),@apline), '')
    						+ ' and APTL.APTrans = ' + isnull(convert(varchar(10),@aptrans), '')
    						+ ' and APTL.APLine = ' + isnull(convert(varchar(6),@apline), '')
    	 		exec (@sql)
    	 		end
    
    -- 		--  update user memos in bAPTL before deleting the detail batch record
    -- 		if @aptlud_flag = 'Y'
    -- 			begin
    -- 			exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'AP Entry Detail', @errmsg output
    -- 			if @rcode <> 0 goto ap_posting_error
    -- 			end
     
    		-- remove current Line from batch
    		delete bAPLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and APLine = @apline

    		goto ap_addline_loop    -- next AP Line

    	ap_addline_end:     -- all AP Lines have been processed for the current Transaction
    		close bcAPLBcursor
    		deallocate bcAPLBcursor
    		select @openAPLBcursor = 0
     
    	-- if Transaction created from an Unapproved Invoice, remove the Invoice
    	if @uimth is not null and @uiseq is not null
    		begin
    		--We now want to save reviewer 
    		-- delete bAPUR where APCo = @co and UIMth = @uimth and UISeq = @uiseq	-- reviewers
    		delete bAPUL where APCo = @co and UIMth = @uimth and UISeq = @uiseq		-- lines
			if not exists(select 1 from bAPUL where APCo = @co and UIMth = @uimth and UISeq = @uiseq)
				begin
				delete bAPUI where APCo = @co and UIMth = @uimth and UISeq = @uiseq	-- header
				end  
    		end
     
    	-- delete MS Intercompany Invoices
    	if @msco is not null and @msinv is not null
    		begin
    		delete bMSIX where MSCo = @msco and MSInv = @msinv	-- lines
    		delete bMSII where MSCo = @msco and MSInv = @msinv	-- header
    		end
    
    
       	if @apthud_flag = 'Y'
       		begin
       		-- update where clause with APTrans, create @sql and execute
     		set @sql = @h_update + @h_join + @h_where + ' and b.APTrans = ' + 
    			isnull(convert(varchar(10), @aptrans), '') + ' and APTH.APTrans = ' +  --#23061
    			isnull(convert(varchar(10),@aptrans), '')
     		exec (@sql)
     		end
    
    -- 	-- update user memos in bAPHB before deleting the batch record
    -- 	if @apthud_flag = 'Y'
    -- 		begin
    -- 		exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'AP Entry', @errmsg output
    -- 		if @rcode <> 0 goto ap_posting_error
    -- 		end
    
    	--Get UniqueAttchID from record, indexes will be refreshed if not null
    	--
    -- 	select @hqatid = UniqueAttchID from APHB with (nolock)
    -- 	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
     
    	-- remove current Transaction from batch
    	delete bAPHB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
     
    	commit transaction
    
    	--Refresh indexes for this header if attachments exist
    	if @guid is not null
    		exec dbo.bspHQRefreshIndexes null, null, @guid, null
    		goto ap_posting_loop
    		end
     
    if @transtype = 'C'	    -- update existing transaction
    	begin
    	update bAPTH
             set VendorGroup = b.VendorGroup, Vendor = b.Vendor, InvId = b.InvId, APRef = b.APRef,
                 Description = b.Description, InvDate = b.InvDate, DiscDate = b.DiscDate, DueDate = b.DueDate,
                 InvTotal = b.InvTotal, HoldCode = b.HoldCode, PayControl = b.PayControl, PayMethod = b.PayMethod,
                 CMCo = b.CMCo, CMAcct = b.CMAcct, PrePaidYN = b.PrePaidYN, PrePaidMth = b.PrePaidMth,
                 PrePaidDate = b.PrePaidDate, PrePaidChk = b.PrePaidChk,
                 PrePaidSeq = case b.PrePaidYN when 'N' then null else b.PrePaidSeq end, --issue #14871
                 V1099YN = b.V1099YN, V1099Type = b.V1099Type,
                 V1099Box = b.V1099Box, PayOverrideYN = b.PayOverrideYN, PayName = b.PayName,
                 PayAddInfo = b.PayAddInfo, PayAddress = b.PayAddress,
                 PayCity = b.PayCity, PayState = b.PayState, PayZip = b.PayZip, PayCountry = b.PayCountry, BatchId = b.BatchId, DocName = b.DocName,
                 AddendaTypeId = b.AddendaTypeId, PRCo = b.PRCo, Employee = b.Employee, DLcode = b.DLcode,
                 TaxFormCode = b.TaxFormCode, TaxPeriodEndDate = b.TaxPeriodEndDate, AmountType = b.AmountType,
                 Amount = b.Amount, AmtType2 = b.AmtType2, Amount2 = b.Amount2, AmtType3 = b.AmtType3, Amount3 = b.Amount3,
     			 SeparatePayYN = b.SeparatePayYN, UniqueAttchID = b.UniqueAttchID, Notes = b.Notes, AddressSeq= b.AddressSeq
    	from bAPHB b with (nolock)
    	join bAPTH h with (nolock) on b.Co = h.APCo and b.Mth = h.Mth and b.APTrans = h.APTrans
    	where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @seq
    	if @@rowcount = 0
    		begin
    		select @errmsg = isnull(@errorstart,'') + ' Unable to update existing AP Transaction Header.'
    		goto ap_posting_error
    		end
     
		---- TK-19327 update claim header reference and invoice info
		IF @SLKeyID IS NOT NULL
			BEGIN      
			UPDATE dbo.vSLClaimHeader SET APRef = h.APRef, InvoiceDesc = h.[Description], InvoiceDate = h.InvDate
			from dbo.bAPTH h with (nolock)
			INNER JOIN dbo.vSLClaimHeader c ON c.KeyID = h.SLKeyID
			WHERE h.SLKeyID = @SLKeyID
			END

    	-- use cursor to process all lines for the transaction
    	declare bcAPLBcursor cursor local fast_forward for
    	select APLine, BatchTransType, LineType, PO, POItem, POItemLine, ItemType, SL, SLItem, JCCo, Job, PhaseGroup,
					Phase, JCCType, EMCo, WO, WOItem, Equip, EMGroup, CostCode, EMCType, CompType, Component, INCo, Loc, MatlGroup,
					Material, GLCo, GLAcct, Description, UM, Units, UnitCost, ECM, VendorGroup, Supplier, PayType, GrossAmt,
					MiscAmt, MiscYN, TaxGroup, TaxCode, TaxType, TaxBasis, OldTaxBasis, TaxAmt, Retainage, Discount, BurUnitCost,  --DC #130175
					BECM, Receiver#, OldLineType, OldPO, OldPOItem, OldPOItemLine, OldItemType, OldSL, OldSLItem, OldUnits, OldPayType,OldGrossAmt,
					OldMiscAmt, OldMiscYN, OldTaxType, OldTaxAmt, OldRetainage, PaidYN, Notes, POPayTypeYN, PayCategory,
					OldTaxGroup, OldTaxCode, SMCo, SMWorkOrder, Scope, SMCostType, SMStandardItem, OldSMCo, OldSMWorkOrder,
					OldScope, OldSMCostType, OldSMStandardItem, 
					SMJCCostType, OldSMJCCostType, SMPhaseGroup, OldSMPhaseGroup, SMPhase, OldSMPhase, 
					OldSubjToOnCostYN, SubjToOnCostYN, ocApplyMth, ocApplyTrans, ocApplyLine, ATOCategory,ocSchemeID,ocMembershipNbr  
    	from bAPLB
    	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
     
    	-- open AP Line cursor
    	open bcAPLBcursor
    	select @openAPLBcursor = 1
     
    	-- loop through all rows in AP Line cursor
    	ap_changeline_loop:
    		fetch next from bcAPLBcursor into @apline, @linetranstype, @linetype, @po, @poitem, @POItemLine, @itemtype,
    			@sl, @slitem, @jcco, @job, @phasegroup, @phase, @jcctype, @emco, @wo, @woitem, @equip,
    			@emgroup, @costcode, @emctype, @comptype, @component, @inco, @loc, @matlgroup, @matl, @glco, @glacct,
    			@linedesc, @um, @units, @unitcost, @ecm, @svendorgroup, @supplier, @paytype, @grossamt, @miscamt,
    			@miscyn, @taxgroup, @taxcode, @taxtype, @taxbasis, @oldtaxbasis, @taxamt, @retainage, @discount, @burunitcost,  --DC #130175
    			@becm, @receiver#, @oldlinetype, @oldpo, @oldpoitem, @OldPOItemLine, @olditemtype, @oldsl, @oldslitem, @oldunits, @oldpaytype,
    			@oldgrossamt, @oldmiscamt, @oldmiscyn, @oldtaxtype, @oldtaxamt, @oldretainage, @linepaidyn, @batchnotes,
    			@popaytypeyn, @paycategory, @oldtaxgroup, @oldtaxcode, @smco, @smworkorder, @scope, @smcosttype,
    			@smstandarditem, @oldsmco, @oldsmworkorder, @oldscope, @oldsmcosttype, @oldsmstandarditem,
    			@smjccosttype, @oldsmjccosttype, @smphasegroup, @oldsmphasegroup, @smphase,@oldsmphase,@OldSubjToOnCostYN, @SubjToOnCostYN, 
     			@ocApplyMth, @ocApplyTrans, @ocApplyLine, @ATOCategory,@ocSchemeID,@ocMembership#
     
    	if @@fetch_status = -1 goto ap_changeline_end
    	if @@fetch_status <> 0 goto ap_changeline_loop
     
    	-- add new AP Line
    	if @linetranstype = 'A'
    		begin
    		insert bAPTL (APCo, Mth, APTrans, APLine, LineType, PO, POItem, POItemLine, ItemType,
    				SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType, EMCo, WO, WOItem, Equip,
    				EMGroup, CostCode, EMCType, CompType, Component, INCo, Loc, MatlGroup, Material, GLCo, GLAcct,
    				Description, UM, Units, UnitCost, ECM, VendorGroup, Supplier, PayType,
    				GrossAmt, MiscAmt, MiscYN, TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt,
    				Retainage, Discount, BurUnitCost, BECM, Notes, POPayTypeYN, PayCategory, Receiver#,
    				SMCo, SMWorkOrder, Scope, SMCostType, SMStandardItem, SMJCCostType, SMPhaseGroup, SMPhase,
					SubjToOnCostYN, OnCostStatus, ocApplyMth, ocApplyTrans, ocApplyLine, ATOCategory,ocSchemeID,ocMembershipNbr)
    				
     	        	
    				
    		values(@co, @mth, @aptrans, @apline, @linetype, @po, @poitem, @POItemLine, @itemtype, @sl, @slitem,
    				@jcco, @job, @phasegroup, @phase, @jcctype, @emco, @wo, @woitem, @equip, @emgroup,
    				@costcode, @emctype, @comptype, @component, @inco, @loc, @matlgroup, @matl, @glco,
    				@glacct, @linedesc, @um, @units, @unitcost, @ecm, @svendorgroup, @supplier, @paytype,
    				@grossamt, @miscamt, @miscyn, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt,
    				@retainage, @discount, @burunitcost, @becm, @batchnotes, @popaytypeyn, @paycategory, @receiver#,
    				@smco, @smworkorder, @scope, @smcosttype, @smstandarditem, @smjccosttype, @smphasegroup, @smphase,
					@SubjToOnCostYN, CASE @SubjToOnCostYN WHEN 'Y' THEN 0 ELSE NULL END,
					@ocApplyMth, @ocApplyTrans, @ocApplyLine, @ATOCategory, @ocSchemeID,@ocMembership#)
    				
     		-- if header is paid, update bAPTH.OpenYN = 'Y' so the new line can be paid
     		if @headerpaidyn = 'Y'
     			begin
     			update bAPTH set OpenYN='Y' where APCo=@co and Mth=@mth and APTrans=@aptrans
     			if @@rowcount = 0
    				begin
    				select @errmsg = isnull(@errorstart,'') + ' Unable to update OpenYN in existing AP Transaction header.'
    				goto ap_posting_error
    				end
    			end
     		end
     
    	-- update existing AP Line
    	if @linetranstype = 'C'
    		begin
    		-- handle OnCostStatus on a changed line
    		SELECT @OnCostStatus = NULL -- initialize OnCostStatus to NULL
    		IF @SubjToOnCostYN = 'Y' OR @OldSubjToOnCostYN = 'Y'
    		BEGIN
    			SELECT @OnCostStatus = OnCostStatus
    			FROM dbo.bAPTL
    			WHERE APCo=@co AND Mth=@mth AND APTrans=@aptrans AND APLine=@apline
    			-- if SubjToOnCostYN is changed to "Y" set status to 0
    			IF (@SubjToOnCostYN = 'Y' AND @OldSubjToOnCostYN = 'N') 
    			BEGIN
    				SELECT @OnCostStatus = 0
    			END 
    			-- if SubjToOnCostYN is changed to "N" set status to null
    			IF (@SubjToOnCostYN = 'N' AND @OldSubjToOnCostYN = 'Y') 
    			BEGIN
    				SELECT @OnCostStatus = NULL
    			END
    			-- if both old and new SubjToOnCostYN are the same OnCostStatus remains the same
    		END
    		update bAPTL
    			set LineType = @linetype, PO = @po, POItem = @poitem, POItemLine = @POItemLine,ItemType = @itemtype, SL = @sl,
    				SLItem = @slitem, JCCo = @jcco, Job = @job, PhaseGroup = @phasegroup, Phase = @phase,
    				JCCType = @jcctype, EMCo = @emco, WO = @wo, WOItem = @woitem, Equip = @equip,
    				EMGroup = @emgroup, CostCode = @costcode, EMCType = @emctype,
    				CompType=@comptype, Component=@component, INCo = @inco, Loc = @loc,
    				MatlGroup = @matlgroup, Material = @matl, GLCo = @glco, GLAcct = @glacct,
    				Description = @linedesc, UM = @um, Units = @units, UnitCost = @unitcost, ECM = @ecm,
    				VendorGroup = @svendorgroup, Supplier = @supplier, PayType = @paytype, GrossAmt = @grossamt,
    				MiscAmt = @miscamt, MiscYN = @miscyn, TaxGroup = @taxgroup, TaxCode = @taxcode,
    				TaxType = @taxtype, TaxBasis = @taxbasis, TaxAmt = @taxamt, Retainage = @retainage,
    				Discount = @discount, BurUnitCost = @burunitcost, BECM = @becm, Notes = @batchnotes,
    				POPayTypeYN = @popaytypeyn, PayCategory = @paycategory, Receiver#=@receiver#,
    				SMCo = @smco, SMWorkOrder = @smworkorder, Scope = @scope, SMStandardItem = @smstandarditem,
    				SMCostType = @smcosttype, SMJCCostType = @smjccosttype, SMPhaseGroup = @smphasegroup, SMPhase = @smphase, 
    				SubjToOnCostYN = @SubjToOnCostYN, OnCostStatus = @OnCostStatus,
     				ocApplyMth = @ocApplyMth, ocApplyTrans = @ocApplyTrans, ocApplyLine = @ocApplyLine, @ATOCategory = @ATOCategory,
     				ocSchemeID = @ocSchemeID,ocMembershipNbr = @ocMembership#				
    		where APCo = @co and Mth = @mth and APTrans = @aptrans and APLine = @apline
    		if @@rowcount = 0
    			begin
    			select @errmsg = isnull(@errorstart,'') + ' Unable to update existing AP Line.'
    			goto ap_posting_error
    			end
    		end
     
                
    	--#14164 Clear hold detail, trans detail and add new hold and trans detail only if line is unpaid.
    	if @linepaidyn = 'N'
    		begin
			--#133119 - update APTD AuditYN flag here before deleting hold codes 
			update bAPTD set AuditYN = 'N' where APCo = @co and Mth = @mth and APTrans = @aptrans and APLine = @apline
    		-- clear Hold Detail - all trans types - any Hold info entered through Payment Control will be lost
     		delete bAPHD where APCo = @co and Mth = @mth and APTrans = @aptrans and APLine = @apline
    		-- clear Trans Detail - all trans types -  any partial payment splits created through Payment Control will be lost
     		delete bAPTD where APCo = @co and Mth = @mth and APTrans = @aptrans and APLine = @apline
     
    		--18769 get retpaytype from PayCategory else use APCO retpaytype
    		if @paycategory is not null
    			begin
    			select @retpaytype=RetPayType from bAPPC with (nolock)
    				where APCo=@co and PayCategory=@paycategory
    			end
    		else
    			begin
    			select @retpaytype=@APretpaytype
    			end
    
    		-- add new Trans and Hold Detail
    		if @linetranstype in ('A','C')
    			begin
    			exec @rcode = dbo.bspAPHBPostAddDetail @co, @mth, @aptrans, @apline, @paytype, @discount,
                     @duedate, @aptdstatus, @svendorgroup, @supplier, @holdcode, @grossamt, @miscamt,
                     @miscyn, @taxtype, @taxamt, @retainage, @retpaytype, @retholdcode, @vendorgroup,
                     @vendor, @prepaidyn, @chkrev,@paycategory,@taxgroup,@taxcode
    			if @rcode <> 0
    				begin
    				select @errmsg = isnull(@errorstart,'') + ' Unable to add AP Transaction Detail.'
             	    goto ap_posting_error
    				end
    			end
    		end
     
    	 -- delete existing AP Line
    	if @linetranstype = 'D'
    		begin
    		delete bAPTL where APCo = @co and Mth = @mth and APTrans = @aptrans and APLine = @apline
    		end
     
    	   
    	-- update PO & SL, back out/add new amounts to vendor activity only to unpaid lines 
    	if @linepaidyn = 'N'
    		begin
    		-- update PO and SL Items
    		select @smchange = 0  -- no update to SL Stored Matls on changed trans
    		
    		exec @rcode = dbo.bspAPHBPostPOSL @co, @errorstart, @linetranstype, @oldpo, @oldpoitem, @OldPOItemLine, @oldsl, @oldslitem,
                     @oldunits, @oldgrossamt, @oldmiscamt, @oldmiscyn, @oldtaxtype,@oldtaxamt, @po, @poitem, @POItemLine, @sl,
                     @slitem, @units, @grossamt, @miscamt, @miscyn, @taxamt, @taxtype, @smchange,
                     @taxbasis, @oldtaxbasis,--DC #130175
                     @errmsg output
    		if @rcode <> 0 goto ap_posting_error
     
    		-- back out old amounts from Vendor Activity for both Deleted and Changed lines - Invoiced Amount may include Misc Amount and Sales Tax
    		select @amt = @oldgrossamt + case @oldmiscyn when 'Y' then @oldmiscamt else 0 end
                        + case @oldtaxtype when 2 then 0 else @oldtaxamt end
--                     + case @oldtaxtype when 1 then @oldtaxamt else 0 end
    		if isnull(@amt,0) <> 0
    			begin
    			update bAPVA set InvAmt = InvAmt - @amt
    			where APCo = @co and VendorGroup = @oldvendorgroup and Vendor = @oldvendor and Mth = @mth
    			if @@rowcount = 0
    				begin
    				insert bAPVA(APCo, VendorGroup, Vendor, Mth, InvAmt, PaidAmt, DiscOff, DiscTaken, AuditYN)
    				values(@co, @oldvendorgroup, @oldvendor, @mth, -(@amt), 0, 0, 0, 'N')
    				end
    			end
    
    		-- add new amounts to Vendor Activity for changed lines - Invoiced Amount may include Misc Amount and Sales Tax
			if @linetranstype = 'C'
				begin
    			select @amt = @grossamt + case @miscyn when 'Y' then @miscamt else 0 end
							+ case @taxtype when 2 then 0 else @taxamt end
	--                     + case @taxtype when 1 then @taxamt else 0 end
    			if @amt <> 0
    				begin
    				update bAPVA set InvAmt = InvAmt + @amt
    				where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor and Mth = @mth
    				if @@rowcount = 0
    					begin
    					insert bAPVA(APCo, VendorGroup, Vendor, Mth, InvAmt, PaidAmt, DiscOff, DiscTaken, AuditYN)
    					values(@co, @vendorgroup, @vendor, @mth, @amt, 0, 0, 0, 'N')
    					end
    				end
				end
     	    end	-- end PO & SL update and back out/add new amounts in vendor activity
     
    -- 	-- update user memos in bAPTL before deleting the detail batch record if line is not paid
    -- 	if @linetranstype in ('A','C') and @aptlud_flag = 'Y' -- and @linepaidyn='N' --#20940
    -- 		begin
    -- 		exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'AP Entry Detail', @errmsg output
    -- 		if @rcode <> 0 goto ap_posting_error
    -- 		end
    
    	if @linetranstype in ('A','C') and @aptlud_flag = 'Y'
    	   		begin
    	   		-- update where clause with BatchSeq, APTrans, and APLine, create @sql and execute
    	 		set @sql = @l_update + @l_join + @l_where 
    						+ ' and b.BatchSeq = ' + isnull(convert(varchar(10),@seq), '')  --#23061
    						+ ' and b.APLine = ' + isnull(convert(varchar(6),@apline), '')
    						+ ' and APTL.APTrans = ' + isnull(convert(varchar(10),@aptrans), '')
    						+ ' and APTL.APLine = ' + isnull(convert(varchar(6),@apline), '')
    	 		exec (@sql)
    	 		end
     
    	-- remove current Line from batch
    	delete bAPLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and APLine = @apline
     
    	goto ap_changeline_loop    -- next AP Line
    
     
    	ap_changeline_end:     -- all AP Lines have been processed for the current Transaction
    		close bcAPLBcursor
    		deallocate bcAPLBcursor
    		select @openAPLBcursor = 0
     
     
       	if @apthud_flag = 'Y'
   
       		begin
       		-- update where clause with APTrans, create @sql and execute
     		set @sql = @h_update + @h_join + @h_where + ' and b.APTrans = ' 
    			+ isnull(convert(varchar(10), @aptrans), '') + ' and APTH.APTrans = '  --#23061
    			 + isnull(convert(varchar(10),@aptrans), '')
     		exec (@sql)
     		end
    	
    	--Get UniqueAttchID from record, indexes will be refreshed if not null
    -- 	--do not need to read, already read in cursor fetch next @guid
    -- 	select @hqatid = UniqueAttchID from APHB with (nolock)
    -- 	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    	
    	-- remove current Transaction from batch
    	delete bAPHB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    	commit transaction
    			
    	--Refresh indexes for this header if attachments exist
    	if @guid is not null
    		exec dbo.bspHQRefreshIndexes null, null ,@guid, null
    	  
    	goto ap_posting_loop    -- next batch entry
    end
     
     
    if @transtype = 'D'     -- delete existing transaction
    	begin
    	-- use cursor to process all lines for the transaction
    	declare bcAPLBcursor cursor local fast_forward for
    	select APLine, BatchTransType, OldLineType, OldPO, OldPOItem, OldPOItemLine,OldItemType, OldSL, OldSLItem,
                 OldUnits, OldPayType, OldGrossAmt, OldMiscAmt, OldMiscYN, OldTaxAmt, OldRetainage, 
                 OldTaxGroup, OldTaxCode,
                 OldTaxBasis, APTLKeyID
    	from bAPLB
    	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
     
    	-- open AP Line cursor
    	open bcAPLBcursor
    	select @openAPLBcursor = 1
     
    	-- loop through all rows in AP Line cursor
    	ap_deleteline_loop:
    		fetch next from bcAPLBcursor into @apline, @linetranstype, @oldlinetype, @oldpo, @oldpoitem, @OldPOItemLine,
                     @olditemtype, @oldsl, @oldslitem, @oldunits, @oldpaytype, @oldgrossamt, @oldmiscamt,
                     @oldmiscyn, @oldtaxamt, @oldretainage,@oldtaxgroup, @oldtaxcode,
                     @oldtaxbasis, @aptlkeyid
     
    	if @@fetch_status = -1 goto ap_deleteline_end
    	if @@fetch_status <> 0 goto ap_deleteline_loop
     
		--#133119 - update APTD AuditYN flag before deleting hold codes 
		update bAPTD set AuditYN = 'N' where APCo = @co and Mth = @mth and APTrans = @aptrans and APLine = @apline
    	-- clear Hold Detail
    	delete bAPHD where APCo = @co and Mth = @mth and APTrans = @aptrans and APLine = @apline
    	-- clear Trans Detail
    	delete bAPTD where APCo = @co and Mth = @mth and APTrans = @aptrans and APLine = @apline
    	-- delete existing AP Line 
    	delete bAPTL where APCo = @co and Mth = @mth and APTrans = @aptrans and APLine = @apline
    	
    	--update vAPSM to flag the transaction as a delete.  SM will have conditional logic to deal with the 
    	--corresponding Work Completed record.
		UPDATE vAPSM SET TransType = @transtype WHERE APKeyID = @aptlkeyid
	
    	-- update PO and SL Items
    	select @smchange = 0  -- no update to SL Stored Matls on delete
    	exec @rcode = dbo.bspAPHBPostPOSL @co, @errorstart, @linetranstype, @oldpo, @oldpoitem, @OldPOItemLine, @oldsl, @oldslitem,
                     @oldunits, @oldgrossamt, @oldmiscamt, @oldmiscyn,@oldtaxtype, @oldtaxamt, @po, @poitem, @POItemLine, @sl,
                     @slitem, @units, @grossamt, @miscamt, @miscyn, @taxamt, @taxtype, @smchange,
                     @taxbasis, @oldtaxbasis, --DC #130175
                     @errmsg output
    	if @rcode <> 0 goto ap_posting_error

    	-- back out old amounts from Vendor Activity - Invoiced Amount may include Misc Amount and Sales Tax
    	select @amt = @oldgrossamt + case @oldmiscyn when 'Y' then @oldmiscamt else 0 end
                        + case @oldtaxtype when 2 then 0 else @oldtaxamt end
--                   	+ case @oldtaxtype when 1 then @oldtaxamt else 0 end
    	if @amt <> 0
    		begin
    		update bAPVA set InvAmt = InvAmt - @amt
    		where APCo = @co and VendorGroup = @oldvendorgroup and Vendor = @oldvendor and Mth = @mth
    		if @@rowcount = 0
    			begin
    			insert into bAPVA(APCo, VendorGroup, Vendor, Mth, InvAmt, PaidAmt, DiscOff, DiscTaken, AuditYN)
    			values(@co, @oldvendorgroup, @oldvendor, @mth, -(@amt), 0, 0, 0, 'N')
    			end
    		end
     
    	-- remove current Line from batch
    	delete bAPLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and APLine = @apline
     
    	goto ap_deleteline_loop    -- next AP Line
     
    	ap_deleteline_end:     -- all AP Lines have been processed for the current Transaction
    		close bcAPLBcursor
    		deallocate bcAPLBcursor
    		select @openAPLBcursor = 0
     
    	-- remove Batch Header
    	delete bAPHB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    	if @@rowcount = 0
    		begin
    		select @errmsg = isnull(@errorstart, '') + ' Unable to remove AP Batch Header.'
    		goto ap_posting_error
    		END

		---- TK-19414 update claim header set back to pending
		IF @SLKeyID IS NOT NULL
			BEGIN      
			UPDATE dbo.vSLClaimHeader
					SET ClaimStatus = 10, CertifiedBy = NULL, CertifyDate = NULL
			FROM dbo.vSLClaimHeader h
			INNER JOIN dbo.bSLHD s ON s.SLCo = h.SLCo AND s.SL = h.SL                  
			WHERE h.KeyID = @SLKeyID
				AND s.ApprovalRequired = 'Y'
			END 
			      
    	-- remove AP Transaction Header
    	delete bAPTH where APCo = @co and Mth = @mth and APTrans = @aptrans
    	if @@rowcount = 0
    		begin
    		select @errmsg = isnull(@errorstart, '') + ' Unable to remove AP Transaction Header.'
    		goto ap_posting_error
    		end
             

 
    	commit transaction
     
    	goto ap_posting_loop    -- next batch entry
     
    end
    
    
    ap_posting_error:
    	rollback transaction
    	select @rcode = 1
    	goto bspexit
     
    ap_posting_end:			-- no more Transactions to process
    	if @opencursor=1
    		begin
    		close bcAPHB
    		deallocate bcAPHB
    		select @opencursor = 0
    		end
     
    jc_update:
    exec @rcode = dbo.bspPORBExpPostJC @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
     
    -- make sure all JC Distributions have been processed
    if exists(select 1 from bPORJ with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to JC were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
     
    exec @rcode = dbo.bspAPHBPostJC @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
     
    -- make sure all JC Distributions have been processed
    if exists(select 1 from bAPJC with (nolock) where APCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to JC were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end

	--TK02798 --This is where we would distribute to SM
	sm_update:

	EXEC @rcode = dbo.vspAPHBPostSM @co, @mth, @batchid, @dateposted, @errmsg OUTPUT
	IF @rcode <> 0 GOTO bspexit

    IF exists(SELECT 1 FROM vAPSM WITH (NOLOCK) WHERE APCo = @co and Mth = @mth and BatchId = @batchid)
    BEGIN
    	select @errmsg = 'Not all updates to SM were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    END	      
     
    gl_update:
    exec @rcode = dbo.bspPORBExpPostGL @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
     
    -- make sure all GL Distributions have been processed
    if exists(select 1 from bPORG with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
     
    exec @rcode = dbo.bspAPHBPostGL @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
    
     
    -- make sure all GL Distributions have been processed
    if exists(select 1 from bAPGL with (nolock) where APCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
    	
    DECLARE @GLEntryToProcess TABLE (APCo bCompany, Mth bMonth, APTrans bTrans, APLine smallint, GLEntryID bigint, APTLGLID bigint NULL)

	INSERT @GLEntryToProcess (APCo, Mth, APTrans, APLine, GLEntryID)
	SELECT Co, Mth, Trans, Line, GLEntryID
	FROM dbo.vGLEntryBatch
	WHERE Co = @co AND Mth = @mth AND BatchId = @batchid

	IF EXISTS(SELECT 1 FROM @GLEntryToProcess)
	BEGIN
		--Update the description for the gl entries if they have Trans# still in it. Also update the actdate with the dateposted since
		--that is what is passed to GLDT
		UPDATE vGLEntryTransaction
		SET [Description] = REPLACE([Description], 'Trans#', dbo.vfToString(APTrans)), ActDate = @dateposted
		FROM dbo.vGLEntryTransaction
			INNER JOIN @GLEntryToProcess GLEntryToProcess ON vGLEntryTransaction.GLEntryID = GLEntryToProcess.GLEntryID
	
		--Create all APTLGL records that don't currently exist
		INSERT dbo.vAPTLGL (APCo, Mth, APTrans, APLine)
		SELECT DISTINCT GLEntryToProcess.APCo, GLEntryToProcess.Mth, GLEntryToProcess.APTrans, GLEntryToProcess.APLine
		FROM @GLEntryToProcess GLEntryToProcess
			LEFT JOIN dbo.vAPTLGL ON GLEntryToProcess.APCo = vAPTLGL.APCo AND GLEntryToProcess.Mth = vAPTLGL.Mth AND GLEntryToProcess.APTrans = vAPTLGL.APTrans AND GLEntryToProcess.APLine = vAPTLGL.APLine
		WHERE vAPTLGL.APTLGLID IS NULL

		--Update our table variable APTLGLID so that we can then update the APTLGLEntries
		UPDATE GLEntryToProcess
		SET APTLGLID = vAPTLGL.APTLGLID
		FROM @GLEntryToProcess GLEntryToProcess
			INNER JOIN dbo.vAPTLGL ON GLEntryToProcess.APCo = vAPTLGL.APCo AND GLEntryToProcess.Mth = vAPTLGL.Mth AND GLEntryToProcess.APTrans = vAPTLGL.APTrans AND GLEntryToProcess.APLine = vAPTLGL.APLine

		--Update the APTLGLEntries with their APTLGLID so we know what AP Transaction the GL Entry was created for
		UPDATE vAPTLGLEntry
		SET APTLGLID = GLEntryToProcess.APTLGLID
		FROM @GLEntryToProcess GLEntryToProcess
			INNER JOIN dbo.vAPTLGLEntry ON GLEntryToProcess.GLEntryID = vAPTLGLEntry.GLEntryID

		--Update the PORDGLEntries with their APTLGLID so we know what AP Transaction the GL Entry was created for
		UPDATE vPORDGLEntry
		SET APTLGLID = GLEntryToProcess.APTLGLID
		FROM @GLEntryToProcess GLEntryToProcess
			INNER JOIN dbo.vPORDGLEntry ON GLEntryToProcess.GLEntryID = vPORDGLEntry.GLEntryID
		
		DECLARE @GLEntriesToDelete TABLE (GLEntryID bigint)
		
		--Update AP Transaction GL records with their current APTLGLEntries
		UPDATE vAPTLGL
		SET CurrentAPInvoiceCostGLEntryID = GLEntryToProcess.GLEntryID
			OUTPUT DELETED.CurrentAPInvoiceCostGLEntryID
				INTO @GLEntriesToDelete
		FROM dbo.vAPTLGL
			INNER JOIN @GLEntryToProcess GLEntryToProcess ON vAPTLGL.APTLGLID = GLEntryToProcess.APTLGLID
			INNER JOIN vAPTLGLEntry ON GLEntryToProcess.GLEntryID = vAPTLGLEntry.GLEntryID

		--Update AP Transaction GL records with their current PORDGLEntries
		UPDATE vAPTLGL
		SET CurrentPOReceiptGLEntryID = GLEntryToProcess.GLEntryID
			OUTPUT DELETED.CurrentPOReceiptGLEntryID
				INTO @GLEntriesToDelete
		FROM dbo.vAPTLGL
			INNER JOIN @GLEntryToProcess GLEntryToProcess ON vAPTLGL.APTLGLID = GLEntryToProcess.APTLGLID
			INNER JOIN vPORDGLEntry ON GLEntryToProcess.GLEntryID = vPORDGLEntry.GLEntryID

		--Get rid of the GL Entries that are no longer pointed to
		DELETE dbo.vGLEntry
		WHERE GLEntryID IN (SELECT GLEntryID FROM @GLEntriesToDelete)

		--Get rid of entries in the batch table.
		DELETE dbo.vGLEntryBatch
		WHERE Co = @co AND Mth = @mth AND BatchId = @batchid
	END
     
    em_update:
    exec @rcode = dbo.bspPORBExpPostEM @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
     
    -- make sure all EM Distributions have been processed
    if exists(select 1 from bPORE with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to EM were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
     
    exec @rcode = dbo.bspAPHBPostEM @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
     
    -- make sure all EM Distributions have been processed
    if exists(select 1 from bAPEM with (nolock) where APCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to EM were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
     
    in_update:
    exec @rcode = dbo.bspPORBExpPostIN @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
     
    -- make sure all IN Distributions have been processed
    if exists(select 1 from bPORN with (nolock)where POCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to IN were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
     
    exec @rcode = dbo.bspAPHBPostIN @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
     
    -- make sure all IN Distributions have been processed
    if exists(select 1 from bAPIN with (nolock) where APCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to IN were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
	     
    -- set interface levels note string
    select @Notes=Notes from bHQBC with (nolock)
    where Co = @co and Mth = @mth and BatchId = @batchid
    if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
    select @Notes=@Notes +
             'GL Expense Interface Level set at: ' + isnull(convert(char(1), a.GLExpInterfaceLvl), '') + char(13) + char(10) +  --#23061
             'GL Payment Interface Level set at: ' + isnull(convert(char(1), a.GLPayInterfaceLvl), '') + char(13) + char(10) +
             'CM Interface Level set at: ' + isnull(convert(char(1), a.CMInterfaceLvl), '') + char(13) + char(10) +
             'EM Interface Level set at: ' + isnull(convert(char(1), a.EMInterfaceLvl), '') + char(13) + char(10) +
             'IN Interface Level set at: ' + isnull(convert(char(1), a.INInterfaceLvl), '') + char(13) + char(10) +
             'JC Interface Level set at: ' + isnull(convert(char(1), a.JCInterfaceLvl), '') + char(13) + char(10)
    
    from bAPCO a with (nolock) where APCo=@co

	--Capture notes, set Status to posted and cleanup HQCC records
	EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @Notes = @Notes, @msg = @errmsg OUTPUT
	IF @rcode <> 0 GOTO bspexit

    bspexit:
    	if @opencursor = 1
    		begin
    		close bcAPHB
    		deallocate bcAPHB
    		end
    
    	if @openAPLBcursor = 1
    		begin
    		close bcAPLBcursor
    		deallocate bcAPLBcursor
    		end
     
    	if @rcode <> 0 select @errmsg = isnull(@errmsg,'') + char(13) + char(10) + '[bspAPHBPost]'
    	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspAPHBPost] TO [public]
GO
