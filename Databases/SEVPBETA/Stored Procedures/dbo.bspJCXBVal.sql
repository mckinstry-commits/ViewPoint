SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCXBVal    Script Date: 8/28/99 9:36:23 AM ******/
CREATE procedure [dbo].[bspJCXBVal]
/************************************************************************
* Created: CJW 04/22/1997
* Modified: GR 08/18/1999	- Added EMBF and EMLB
*			GR 10/21/1999	- changed the error messages to be more informative
*			GR 11/11/1999	- got batchid and mth if the job is in use and displayed in the error message
*			GR 12/04/1999	- Added more tables to check whether the Job/contract
*                                    is in use as per discussion with Gary and Carol
*                                    Checks in Batch tables of AP, PO, SL, AR, JBIN, PMMF,
*                                    PMSL, PMOH, PRTH, EMBF, EMLB and JC tables
*			JE 12/8/1999	- changed the syntax in the join for 'put revenue into temp table'.
*			JE 12/28/1999	- Modified insert from using @tmpcontract to @Contract to prevent doubling cost when the next Contract has no jobs.
*			DANF 01/24/2000 - Correct reversed the sign on the GLDT entries for closed vrs. open.
*			GILF 02/14/2000 - Added another table PRTB whether the Job/Contract is in use.
*			GILF 02/14/2000 - Remmed out check for APRL.
*			GR 04/18/2000	- commented the check for bJCAJ as per issue# 6720
*			GR 05/08/2000	- changed the error message for PO and SL
*           GR	06/15/2000	- corrected the where clause for POIT check
*           GF	03/15/2001	- added additional restrictions for PMSL and PMMF
*			allenn 02/25/2002 - Added check for any GL account Phase Overrides. Issue 14175
*			danf 04/12/2002	- Clean up while's, Added fetch for GLAcct cusor, and change the default for the Phase override account.
*			GF 05/07/2002	- Added check for MO'S in PMMF and INIB
*			GF 05/21/2002	- Added SendFlag to PMMF for MO'S
*			gf 05/21/2002	- Added check for INXJ and INMI if PostClosedJobs='N'
*			CMW 07/08/2002	- Modified validation/error message for PRPC/JC interface (issue # 17648).
*           DANF 09/18/2002	- Only insert accounts into JCXA if the closed account is different than the Open account 18587.
*           RM 02/21/2001	-  Changed So that does not make any GL entries on Soft close per issue # 12100
*		    RBT 05/05/2003	- Changed error message when uninterfaced bill exists to say Month and BILL #, not BatchID (Issue 21167).
*			DANF 07/30/2003	- issue #21733 Validate Gl Accounts.
*			DANF 10/21/2003	- issue #22339 Corrected HQBE Insert Error
*			DANF 10/30/2003	- issue #22786 Added Phase GL Account valid part over ride.
*			TJL/DANF 03/09/04 - Issue #24001, Use Correct GLCo for this JCCo
*			TV				- 23061 added isnulls
*			DANF 01/14/2003	- Issue 24307 Correct errors in contract close validation.
*			DANF 01/19/2005	- Issue 26882 Correct IN MO Valdation.
*			DANF 02/01/2005	- Issue 26989 Add reformatting of phase for Inputmasks of R and L.
*			DANF 06/6/2005	- Issue 29215 Change Error message to uninterface payroll periods.
*			DANF 02/14/2006	- Issue 120217 Correct join clause  to improve preformance.
*			DANF 10/06/2006 - Recode 6.x
*			GF	06/25/2007	- issue #124895 added item is not null check for PMMF and PMSL
*			GG	10/16/2007	- issue #125791 - fix for DDDTShared
*			GF	12/12/2007	- issue #25569 use separate post closed job flags in JCCO enhancement
*			GF	01/08/2008	- issue #122261 added cost type to open/closed wip gl acct error message
*			GF	01/13/2008	- issue #123524 changes to PMSL and PMMF checks for PCO records
*			GF	09/02/2008	- issue #129581 only logs errors dependent on the post closed flags
*			CHS	10/02/2008	- issues #126236
*			GP	01/21/2009	- Issue #131945, only validate final close jobs, added @SoftFinal='F' to validation.
*			CHS	04/05/2009	- issue #132789 Allow soft close when postings exist in future months.
*			CHS	05/06/2009	- issue #130924 - Don't allow closing if Job is in an SL Worksheet.
*			CHS 06/02/2009	- issue #133892
*			GF	09/15/2009	- issue #135567 - added batch company to error messages for accounting modules
*			CHS 12/08/2009	- issues #136968
*			CHS 12/08/2009	- issues #136405
*			GF  06/25/2010  - issue #135813 - expanded SL to varchar(30)
*			AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-
*			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*
* Validates each entry in bJCXB for a selected batch - must be called
* prior to posting the batch.
*
* After initial Batch and JC checks, bHQBC Status set to 1 (validation in progress)
*
*
* Creates a cursor on bJCXB to validate each entry individually.
* Spins through all Jobs first- then takes care of contract
*
* Errors in batch added to bHQBE using bspHQBEInsert
*
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
*
* pass in Co, Month, and BatchId
* returns 0 if successfull (even if entries addeed to bHQBE)
* returns 1 and error msg if failed
*
*************************************************************************/
   	@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(60) output
   
   as
   set nocount on
   
  
declare 
	--Declares for cursor crs_GLAcctCostOverrides
	--#142350 - renaming @glcloselevel
	@crs_jcco bCompany, @crs_department bDept, @crs_contract bContract,
	@crs_glco bCompany, @crs_openwipacct bGLAcct, @crs_closedexpacct bGLAcct,
	@crs_actualcost bDollar, @crs_phase bPhase, @crs_validphasechars int, @crs_pphase bPhase,
	@crs_openrevacct bGLAcct, @crs_closedrevacct bGLAcct,
  
	@Contract bContract, @Job bJob, @LastContractMth bMonth, @LastJobMth bMonth, @CloseDate bMonth,
	@SoftFinal varchar(1), @TmpContract bContract, @ContractOK bYN, @startmonth bMonth,
   
	@rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName, @status tinyint,
	@adj bYN, @opencursor tinyint, @lastglmth bMonth, @lastsubmth bMonth,
	@unbal bYN,@fy bMonth, @jrnl bJrnl, @glref bGLRef, @dbsource bSource, @actdate bDate, @description bTransDesc,
	@amt bDollar,
	@oldglacct bGLAcct, @oldactdate bDate, @olddesc bTransDesc,
	@errortext varchar(255),@errorhdr varchar(60),
	@dtsource bSource, @dtactdate bDate, @dtdesc bTransDesc, @errno int, @maxopen int,

	@JCCo bCompany, @BatchCount int, @GLCloseLevel int, @PostClosedJobs bYN, @GLCloseJrnl bJrnl, @TmpCount int, @errormsg varchar(60),
	@OpenRevAcct bGLAcct, @ClosedRevAcct bGLAcct, @Department bDept, @glco bCompany, @SumBilledAmt float, @SumActualCost float,
	@ClosedExpAcct bGLAcct, @OpenWIPAcct bGLAcct,@dateposted bDate,
	@glRevSummaryDesc varchar(60), @glCostSummaryDesc varchar(60),
	@glRevDetailDesc varchar(60),  @glRevinterfacelvl int,@glCostinterfacelvl int, @SkipFlag varchar(1),
	@po varchar(30), @poitem bItem, @openpoitem int, @openslitem int, @sl VARCHAR(30), @slitem bItem, @slunits float,
	@batchmth bMonth, @batchid2 bBatchID, @seq int, @crs_costtype bJCCType, 
	@JCXB_status int, @GLAcct_status int, @openmoitem int, @mo bMO, @moitem bItem,
	@PRCo bCompany, @PRGroup bGroup, @PREndDate bDate, @GLCloseLvl int, @rc int,
	@InputMask varchar(30), @InputType tinyint, @validphase bPhase, @validphasechars int, @pphase bPhase, 
 	@JCGLCo bCompany, @InputLength int, @lstMthCost bMonth, @lstMthRevenue bMonth,
	@postsoftclosedjobs bYN, @ctopenwipflag bYN, @ctclosewipflag bYN, @poco bCompany,
	@errco bCompany


select @rcode = 0, @openpoitem=0, @openslitem=0, @openmoitem = 0, @rc =0

--Get date for postedDate
select @dateposted = dbo.vfDateOnly()        --ajw issue 141031

--get GL interface info from JC Company
select @glRevDetailDesc = GLRevDetailDesc, @glCostSummaryDesc = GLCostSummaryDesc, @glRevSummaryDesc = GLRevSummaryDesc,
   	   @glRevinterfacelvl = GLRevLevel, @glCostinterfacelvl = GLCostLevel, @GLCloseLvl = GLCloseLevel, @validphasechars = ValidPhaseChars,
		@JCGLCo = GLCo
from JCCO with (nolock) where JCCo = @co

-- get Phase Format 
select @InputMask = InputMask, @InputType= InputType, @InputLength = InputLength
from dbo.DDDTShared (nolock) where Datatype ='bPhase'

--set open cursor flag to false
select @opencursor = 0

--validate HQ Batch
select @source = Source, @tablename = TableName, @inuseby = InUseBy, @status = Status, @adj = Adjust
from bHQBC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
   	begin --
   	select @errmsg = 'Invalid Batch - missing from HQ Batch Control!', @rcode = 1
   	goto bspexit
   	end --
if @source <> 'JC Close'
   	begin --
     select @errmsg = 'Invalid Batch source - must be (JC Close)!', @rcode = 1
   	goto bspexit
   	end --
if @tablename <> 'JCXB'
   	begin --
   	select @errmsg = 'Invalid Batch table name - must be (bJCXB)!', @rcode = 1
   	goto bspexit
   	end --
if @inuseby is null
   	begin --
   	select @errmsg = 'HQ Batch Control must first be updated as (In Use)!', @rcode = 1
   	goto bspexit
   	end --
if @inuseby <> SUSER_SNAME()
   	begin --
   	select @errmsg = 'Batch already in use by ' + isnull(@inuseby,''), @rcode = 1
   	goto bspexit
   	end --
if @status < 0 or @status > 3
   	begin --
   	select @errmsg = 'Invalid Batch status!', @rcode = 1
   	goto bspexit
   	end --

--validate GL Company and Month
select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen,
   	   @unbal = Unbal from bGLCO with (nolock) where GLCo = @JCGLCo			--@co
if @@rowcount = 0
   	begin --
   	select @errmsg = 'Invalid GL Company #', @rcode = 1
   	goto bspexit
   	end --

if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
   	begin --
   	select @errmsg = 'Not an open month', @rcode = 1
   	goto bspexit
   	end --

--set HQ Batch status to 1 (validation in progress)
update bHQBC set Status = 1 
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
   	begin --
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end --

-- clear HQ Batch Errors
delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid

-- clear GL Audit
delete bJCXA where Co = @co and Mth = @mth and BatchId = @batchid

--Get Flags in JCCO
select @PostClosedJobs=PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs, @GLCloseLevel=GLCloseLevel,
		@GLCloseJrnl=GLCloseJournal
from JCCO with (nolock) where JCCo=@co

-- Check for valid GL Journal
if @GLCloseLevel>=2
	begin--
	select @TmpCount = count(*) from bGLJR  with (nolock) where Jrnl=@GLCloseJrnl and GLCo= @JCGLCo --@co
   	if @TmpCount=0
		begin --
		select @errortext = 'Invalid GL Close Journal - ' + isnull(@GLCloseJrnl,'')
		exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
		end --
	if @rc<>0 goto bspexit
	end --


/************* Create tempory tables for GL distributions ***************/
create table #GL_SUM
      (JCCo tinyint null, Department char(10) null,
       Contract char(10) null, GLCo tinyint null,
       GLOpenAcct varchar(20) null,
       GLClosedAcct varchar(20) null,
       GLAmt numeric(12,2) null)
   
   -- declare cursor on GL Detail Batch for validation
   declare bcJCXB cursor local fast_forward for select Co, Contract, Job, LastContractMth, LastJobMth, CloseDate, SoftFinal 
	from bJCXB where Co = @co and Mth = @mth and BatchId = @batchid
   	order by Contract, Job desc
   
   open bcJCXB      -- open cursor
   
   select @opencursor = 1     --set open cursor flag to true
   
   select @ContractOK='Y'                    --get first row
   fetch next from bcJCXB into @JCCo, @Contract, @Job, @LastContractMth, @LastJobMth, @CloseDate, @SoftFinal
   select @JCXB_status = @@fetch_status
   while (@JCXB_status = 0)--loop through all rows
      begin -- @JCXB_status
         if @TmpContract<>@Contract
            begin --
            select @ContractOK='Y'				--Starting on a new Contract
            end --
   
         select @errorhdr = 'Job ' + @Job + ' exists in '
   
         if isnull(@Job, '') <> '' 				--If we are working on a Job
            begin       -- @Job


			-- #130924 Don't allow closing if Job is in an SL Worksheet.
			declare @slexists varchar(10), @slexistsusername varchar(10)
			select top 1 @slexists = w.SL, @slexistsusername = UserName from SLWH w with (nolock) where w.JCCo = @JCCo and w.Job = @Job
            if @@rowcount>0
				begin
   				select @errortext = 'Job ' + @Job + '  exists in SL Worksheet for user: ' + @slexistsusername + ' on SL: ' + @slexists + '. Unable to close.' , @rcode = 1
				exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
				select @ContractOK='N'
				if @rc<>0 goto bspexit
				end


			select @lstMthCost = max(JCCP.Mth) from JCCP with (nolock)
				where JCCP.JCCo= @JCCo and JCCP.Job= @Job and 
				(isnull(JCCP.ActualHours,0) <> 0 or isnull(JCCP.ActualUnits,0) <> 0 or isnull(JCCP.ActualCost,0) <> 0 or 
				isnull(JCCP.OrigEstHours,0) <> 0 or isnull(JCCP.OrigEstUnits,0) <> 0 or isnull(JCCP.OrigEstCost,0) <> 0 or 
				isnull(JCCP.CurrEstHours,0) <> 0 or isnull(JCCP.CurrEstUnits,0) <> 0 or isnull(JCCP.CurrEstCost,0) <> 0 or 
				isnull(JCCP.ProjHours,0) <> 0 or isnull(JCCP.ProjUnits,0) <> 0 or isnull(JCCP.ProjCost,0) <> 0 or 
				isnull(JCCP.ForecastHours,0) <> 0 or isnull(JCCP.ForecastUnits,0) <> 0 or isnull(JCCP.ForecastCost,0) <> 0 or 
				isnull(JCCP.TotalCmtdUnits,0) <> 0 or isnull(JCCP.TotalCmtdCost,0) <> 0 or isnull(JCCP.RemainCmtdUnits,0) <> 0 or 
				isnull(JCCP.RemainCmtdCost,0) <> 0 or isnull(JCCP.RecvdNotInvcdUnits,0) <> 0 or isnull(JCCP.RecvdNotInvcdCost,0) <> 0 )

		 -- #132789 Allow soft close when postings exist in future months.
         --If @mth < @lstMthCost
         If (@mth < @lstMthCost and @SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@mth < @lstMthCost and @SoftFinal = 'F')
			begin
			select @errortext = 'Job ' + @Job + ' Cost postings in future months.  Unable to close.'
			exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
			select @ContractOK='N'
			if @rc<>0 goto bspexit
			end
			
			--APLB
            select @errco=Co, @batchmth=Mth, @batchid2=BatchId from bAPLB with (nolock)
            where ((Job = @Job and JCCo = @JCCo) or (OldJob = @Job and OldJCCo = @JCCo)) and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
            if @@rowcount>0
   	          begin --
   	          select @errortext = @errorhdr +
   									' APLB for Co: ' + convert(varchar(3),@errco) + ' Month: ' + convert(varchar(3),@batchmth,1) + substring(convert(varchar(8),@batchmth,1),7,2) +
									' and BatchId: ' + convert(varchar(6), @batchid2)
   	           exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	           select @ContractOK='N'
   	           end --
				if @rc<>0 goto bspexit
   
              --APUL
               select @errco=APCo, @batchmth=UIMth, @seq=UISeq from bAPUL with (nolock)
               where Job = @Job and JCCo=@JCCo and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
				if @@rowcount>0
                       begin --
						   select @errortext = @errorhdr +
									'APUL for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
									isnull(convert(varchar(3),@batchmth,1),'') +
									isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
									' and Seq: ' + isnull(convert(varchar(6), @seq),'')
   	                exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	                select @ContractOK='N'
   	                end --
   	  if @rc<>0 goto bspexit
   
   
              --bAPJC
               select @errco=APCo, @batchmth=Mth, @batchid2=BatchId from bAPJC with (nolock)
               where Job = @Job and JCCo = @JCCo and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	               begin --
   	               select @errortext = @errorhdr +
   									'APJC for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                          isnull(convert(varchar(3),@batchmth,1),'') +
   		                               isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
  
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
  
              --bARBJ
               select @errco=ARCo, @batchmth=Mth, @batchid2=BatchId from bARBJ with (nolock)
               where JCCo = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	               begin --
   	               select @errortext = @errorhdr +
   							'ARBJ for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                          isnull(convert(varchar(3),@batchmth,1),'') +
   		                               isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   				   select @ContractOK='N'
   	               end --
   	    if @rc<>0 goto bspexit
   
              --bARBL
               select @errco=Co, @batchmth=Mth, @batchid2=BatchId from bARBL with (nolock)
               where ((JCCo = @JCCo and Job = @Job) or (oldJCCo = @JCCo and oldJob = @Job)) and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	               begin --
   	               select @errortext = @errorhdr +
   									'ARBL for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                          isnull(convert(varchar(3),@batchmth,1),'') +
   		                               isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
  
   	   --bEMBF
   	   select @errco=Co, @batchmth=Mth, @batchid2=BatchId from bEMBF with (nolock)
          where ((JCCo = @JCCo and Job = @Job) or (OldJCCo = @JCCo and OldJob = @Job)) and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
   	       if @@rowcount>0
   	           begin --
				select @errortext = @errorhdr +
						'EMBF for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
    							isnull(convert(varchar(3),@batchmth,1),'') +
   		    				isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                              ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	           exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	        select @ContractOK='N'
   	           end --
   	    if @rc<>0 goto bspexit
   	  --bEMLB
   	   select @errco=Co, @batchmth=Mth, @batchid2=BatchId from bEMLB with (nolock)
          where ((FromJCCo = @JCCo and FromJob = @Job) or (ToJCCo = @JCCo and ToJob = @Job) or
                (OldFromJCCo = @JCCo and OldFromJob = @Job) or
                (OldToJCCo = @JCCo and OldToJob = @Job)) and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
   	           if @@rowcount>0
   	               begin --
   	               select @errortext = @errorhdr +
   							'EMLB for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                         isnull(convert(varchar(3),@batchmth,1),'') +
   		        						isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                           				' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
   
              --bJCPB
               select @batchmth = Mth, @batchid2 = BatchId from bJCPB with (nolock)
               where Co = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
                       begin --
                       select @errortext = @errorhdr + 'JCPB for Month: ' +
                                          isnull(convert(varchar(3),@batchmth,1),'') +
   		                                 isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
              --bJCPP
               select @batchmth = Mth, @batchid2 = BatchId from bJCPP with (nolock)
               where Co = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
                       begin --
                       select @errortext = @errorhdr + 'JCPP for Month: ' +
                                          isnull(convert(varchar(3),@batchmth,1),'') +
   		                               isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	         exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
              --bJCCB
               select @batchmth=Mth, @batchid2=BatchId from bJCCB with (nolock)
               where ((Co = @JCCo and Job = @Job) or (Co = @JCCo and OldJob = @Job)) and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	               begin --
   	               select @errortext = @errorhdr + 'JCCB for Month: ' +
                                          isnull(convert(varchar(3),@batchmth,1),'') +
   		                               	 isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
               --bJCDA
               select @batchmth=Mth, @batchid2=BatchId from bJCDA with (nolock)
               where JCCo = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	       			begin  --
   	               	select @errortext = @errorhdr + 'JCDA for Month: ' +
                 						isnull(convert(varchar(3),@batchmth,1),'') +
   		                                isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	 				end --
   	               if @rc<>0 goto bspexit
 
              --MSTB
               select @errco=Co, @batchmth = Mth, @batchid2 = BatchId from dbo.bMSTB with (nolock)
               where JCCo = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                  if @@rowcount>0
   	               begin --
   	               		select @errortext = @errorhdr +
   	               				'MSTB for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                 isnull(convert(varchar(3),@batchmth,1),'') +
   		                isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                 ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	         		exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               		select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
              --POCA
               select @errco=POCo, @batchmth = Mth, @batchid2 = BatchId from bPOCA with (nolock)
               where JCCo = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                  if @@rowcount>0
   	               begin --
   	               select @errortext = @errorhdr + 
   							'POCA for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                        isnull(convert(varchar(3),@batchmth,1),'') +
   		                             isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                        ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	         exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
              --PORA
               select @errco=POCo, @batchmth = Mth, @batchid2 = BatchId from bPORA with (nolock)
               where JCCo = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	               begin --
   	               select @errortext = @errorhdr +
   							'PORA for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                        isnull(convert(varchar(3),@batchmth,1),'') +
   		                             isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                        ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
              --POXA
               select @errco=POCo, @batchmth = Mth, @batchid2 = BatchId from bPOXA with (nolock)
               where JCCo = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	               begin --
   	               select @errortext = @errorhdr +
   							'POXA for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                        isnull(convert(varchar(3),@batchmth,1),'') +
   		                             isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                        ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
              --POIB
               select @errco=Co, @batchmth=Mth, @batchid2=BatchId from bPOIB with (nolock)
               where ((PostToCo = @JCCo and Job = @Job) or (OldPostToCo = @JCCo and OldJob = @Job))  and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	               begin --
   				   select @errortext = @errorhdr +
   							'POIB for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                          isnull(convert(varchar(3),@batchmth,1),'') +
   		                               isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
			---- PMMF - PO's check originals
			select @BatchCount=count(*) from bPMMF with (nolock)
			where PMCo = @JCCo and Project = @Job and PO is not null and POItem is not null
			and InterfaceDate is null and SendFlag='Y' and RecordType = 'O' and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
			if @BatchCount > 0
				begin
				select @errortext = 'Project ' + isnull(@Job,'') + ' PM Material Detail Original records exist in PMMF for a PO that are not interfaced '
				exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
				select @ContractOK='N'
				end
			if @rc<>0 goto bspexit
   
			---- PMMF - PO's check ACO
			select @BatchCount=count(*) from bPMMF with (nolock)
			where PMCo = @JCCo and Project = @Job and PO is not null and POItem is not null
			and InterfaceDate is null and SendFlag = 'Y' and RecordType = 'C'
			and ACOItem is not null and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
			if @BatchCount > 0
				begin
				select @errortext = 'Project: ' + isnull(@Job,'') + ' PM Material Detail ACO records exist in PMMF for a PO that are not interfaced '
				exec @rc = bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
				select @ContractOK='N'
				end
			if @rc <> 0 goto bspexit

			---- PMMF - PO's check PCO
			select @BatchCount=count(*) from bPMMF s with (nolock)
			where s.PMCo = @JCCo and s.Project = @Job and s.PO is not null and s.POItem is not null
			and s.InterfaceDate is null and s.SendFlag = 'Y' and s.RecordType = 'C'
			and s.PCOItem is not null and s.ACOItem is null and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
			and exists(select p.PMCo from bPMOI p with (nolock) where p.PMCo=s.PMCo
					and p.Project=s.Project and p.PCOType=s.PCOType and p.PCO=s.PCO
					and p.PCOItem=s.PCOItem and p.Status in (select f.Status from bPMSC f with (nolock)
							where f.Status=p.Status and f.CodeType <> 'F'))
			if @BatchCount > 0
				begin
				select @errortext = 'Project: ' + isnull(@Job,'') + ' PM Material Detail PCO records exist in PMMF for a PO that are not interfaced '
				exec @rc = bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
				select @ContractOK='N'
				end
			if @rc <> 0 goto bspexit

			---- PMMF - MO's check originals
			select @BatchCount=count(*) from bPMMF with (nolock)
			where PMCo = @JCCo and Project = @Job and MO is not null and MOItem is not null
			and InterfaceDate is null and SendFlag = 'Y' and RecordType = 'O' and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
			if @BatchCount > 0
				begin
				select @errortext = 'Project ' + isnull(@Job,'') + ' PM Material Detail Original records exist in PMMF for a MO that are not interfaced '
				exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
				select @ContractOK='N'
				end
			if @rc<>0 goto bspexit

			---- PMMF - MO's check ACO
			select @BatchCount=count(*) from bPMMF with (nolock)
			where PMCo = @JCCo and Project = @Job and MO is not null and MOItem is not null
			and InterfaceDate is null and SendFlag = 'Y' and RecordType = 'C'
			and ACOItem is not null and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
			if @BatchCount > 0
				begin
				select @errortext = 'Project: ' + isnull(@Job,'') + ' PM Material Detail ACO records exist in PMMF for a MO that are not interfaced '
				exec @rc = bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
				select @ContractOK='N'
				end
			if @rc <> 0 goto bspexit

			---- PMMF - PO's check PCO
			select @BatchCount=count(*) from bPMMF s with (nolock)
			where s.PMCo = @JCCo and s.Project = @Job and s.MO is not null and s.MOItem is not null
			and s.InterfaceDate is null and s.SendFlag = 'Y' and s.RecordType = 'C'
			and s.PCOItem is not null and s.ACOItem is null and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
			and exists(select p.PMCo from bPMOI p with (nolock) where p.PMCo=s.PMCo
					and p.Project=s.Project and p.PCOType=s.PCOType and p.PCO=s.PCO
					and p.PCOItem=s.PCOItem and p.Status in (select f.Status from bPMSC f with (nolock)
							where f.Status=p.Status and f.CodeType <> 'F'))
			if @BatchCount > 0
				begin
				select @errortext = 'Project: ' + isnull(@Job,'') + ' PM Material Detail PCO records exist in PMMF for a MO that are not interfaced '
				exec @rc = bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
				select @ContractOK='N'
				end
			if @rc <> 0 goto bspexit

			---- PMSL - SL's check originals first
			select @BatchCount=count(*) from bPMSL with (nolock)
			where PMCo = @JCCo and Project = @Job and SL is not null and SLItem is not null
			and InterfaceDate is null and SendFlag = 'Y' and RecordType = 'O' and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
			if @BatchCount > 0
				begin
				select @errortext = 'Project: ' + isnull(@Job,'') + ' PM Subcontract Detail original records exist in PMSL for a SL that are not interfaced '
				exec @rc = bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
				select @ContractOK='N'
				end
			if @rc <> 0 goto bspexit

			---- PMSL - SL's check approved first
			select @BatchCount=count(*) from bPMSL with (nolock)
			where PMCo = @JCCo and Project = @Job and SL is not null and SLItem is not null
			and InterfaceDate is null and SendFlag = 'Y' and RecordType = 'C'
			and ACOItem is not null and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968

			-- issue #129937
--			select @BatchCount=count(*) from bPMSL with (nolock)
--				left join bJCCO on bPMSL.PMCo = bJCCO.JCCo
--				where PMCo = 1 and Project = ' 1000-' and SL is not null and SLItem is not null
--				and InterfaceDate is null and SendFlag = 'Y' and RecordType = 'O' and bJCCO.PostClosedJobs = 'N'


			if @BatchCount > 0
				begin
				select @errortext = 'Project: ' + isnull(@Job,'') + ' PM Subcontract Detail ACO records exist in PMSL for a SL that are not interfaced '
				exec @rc = bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
				select @ContractOK='N'
				end
			if @rc <> 0 goto bspexit

			---- PMSL - SL's check pending change orders
			select @BatchCount=count(*) from bPMSL s with (nolock)
			where s.PMCo = @JCCo and s.Project = @Job and s.SL is not null and s.SLItem is not null
			and s.InterfaceDate is null and s.SendFlag = 'Y' and s.RecordType = 'C'
			and s.PCOItem is not null and s.ACOItem is null and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
			and exists(select p.PMCo from bPMOI p with (nolock) where p.PMCo=s.PMCo
					and p.Project=s.Project and p.PCOType=s.PCOType and p.PCO=s.PCO
					and p.PCOItem=s.PCOItem and p.Status in (select f.Status from bPMSC f with (nolock)
							where f.Status=p.Status and f.CodeType <> 'F'))
			if @BatchCount > 0
				begin
				select @errortext = 'Project: ' + isnull(@Job,'') + ' PM Subcontract Detail PCO records exist in PMSL for a SL that are not interfaced '
				exec @rc = bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
				select @ContractOK='N'
				end
			if @rc <> 0 goto bspexit




  			--INIB
               select @errco=Co, @batchmth=Mth, @batchid2=BatchId from bINIB with (nolock)
               where ((JCCo = @JCCo and Job = @Job) or (OldJCCo = @JCCo and OldJob = @Job)) and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
               	if @@rowcount>0
  					begin --
   	          		select @errortext = @errorhdr +
   	          					'INIB for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                          isnull(convert(varchar(3),@batchmth,1),'') +
   		                                 isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               	exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               	select @ContractOK='N'
   	               	end --
   	               if @rc<>0 goto bspexit
  
              --INXJ
               select @errco=INCo, @batchmth = Mth, @batchid2 = BatchId from bINXJ with (nolock)
               where JCCo = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	               begin --
   	               select @errortext = @errorhdr + 
   								'INXJ for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                        isnull(convert(varchar(3),@batchmth,1),'') +
   		                              isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                        ' and BatchId: ' + isnull(convert(varchar(8), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
  
  			--bPRTB
               select @errco=Co, @batchmth=Mth, @batchid2=BatchId from bPRTB with (nolock)
               where JCCo = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	               begin -- 
   	               select @errortext = @errorhdr + 
   								'PRTB for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                          isnull(convert(varchar(3),@batchmth,1),'') +
   		                               isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   

  			--bPRPC (CMW 07/08/02 - issue # 17648)
  			 select @batchid2 = bPRTH.BatchId, @batchmth=bPRPC.BeginMth,
  				@PRCo=bPRPC.PRCo, @PRGroup=bPRPC.PRGroup, @PREndDate=bPRPC.PREndDate
  			 from bPRTH  with (nolock) join bPRPC  with (nolock) on
               bPRPC.PRCo = bPRTH.PRCo and bPRPC.PRGroup = bPRTH.PRGroup and bPRPC.PREndDate = bPRTH.PREndDate
               where bPRTH.JCCo = @JCCo and bPRTH.Job = @Job and bPRPC.JCInterface = 'N' and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
                      begin --
  					select @errortext = @errorhdr + --'PR batch: ' + isnull(convert(varchar(6), @batchid2),'') + #29215
  										'PRCo: ' + isnull(convert(varchar(3),@PRCo),'') +
                                          ' PRGroup: ' + isnull(convert(varchar(3),@PRGroup),'') +
  										' PREndDate: ' + isnull(convert(varchar(10),@PREndDate,1),'') +                                        
                                          ' needs final interface to Job Cost.'
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
              --bSLCA
               select @errco=SLCo, @batchmth=Mth, @batchid2=BatchId from bSLCA with (nolock)
               where JCCo = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	               begin --
   	               select @errortext = @errorhdr + 
   								'SLCA for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                          isnull(convert(varchar(3),@batchmth,1),'') +
   		                               isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
              --bSLXA
               select @errco=SLCo, @batchmth=Mth, @batchid2=BatchId from bSLXA with (nolock)
               where JCCo = @JCCo and Job = @Job and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
                   if @@rowcount>0
   	               begin --
   	               select @errortext = @errorhdr + 
   								'SLXA for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                          isnull(convert(varchar(3),@batchmth,1),'') +
   		                               isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                          ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
   	               exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	               select @ContractOK='N'
   	               end --
   	               if @rc<>0 goto bspexit
   
              --bSLIB
        		select @errco=Co, @batchmth=Mth, @batchid2=BatchId from bSLIB with (nolock)
              where ((JCCo = @JCCo and Job = @Job) or (OldJCCo = @JCCo and OldJob = @Job)) and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
              if @@rowcount>0
   	        	begin --
   	            select @errortext = @errorhdr + 
   							'SLIB for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                                      isnull(convert(varchar(3),@batchmth,1),'') +
   		                            isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                                      ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
  				exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   	        	select @ContractOK='N'
   	            end --
   	            if @rc<>0 goto bspexit
  
		---- issue #129581 only logs errors dependent on the post closed flags
		if @postsoftclosedjobs = 'N' or @PostClosedJobs='N'	--Check jobs in POIT, SLIT, and INMI if Posted to closed jobs is 'N'
			begin  --@PostClosedJobs
			--Allow the Job to close only if RemUnits, RemCost, RemTax is zero and Job is not in use
			select @TmpCount = count(*) from bPOIT with (nolock)
   			join bPOHD  with (nolock) on bPOHD.POCo=bPOIT.POCo and bPOHD.PO=bPOIT.PO
   			where bPOIT.PostToCo=@JCCo and bPOIT.Job = @Job and bPOHD.Status <> 2
			and (bPOIT.RemUnits <> 0 or bPOIT.RemCost <> 0 or bPOIT.RemTax <> 0)
   
   	        if @TmpCount <> 0
				begin -- @TmpCount
				declare poitem_cursor cursor local fast_forward for
				select bPOIT.POCo, bPOIT.PO, bPOIT.POItem from bPOIT
				join bPOHD  on bPOHD.POCo=bPOIT.POCo and bPOHD.PO=bPOIT.PO
				where bPOIT.PostToCo=@JCCo and bPOIT.Job = @Job and bPOHD.Status <> 2
				and (bPOIT.RemUnits <> 0 or bPOIT.RemCost <> 0 or bPOIT.RemTax <> 0)
   
				open poitem_cursor
				select @openpoitem=1
   
				poitem_cursor_loop:             --loop through all the records
				fetch next from poitem_cursor into @poco, @po, @poitem
				if @@fetch_status=0
					begin --
					if @postsoftclosedjobs = 'N'
						begin
						select @errortext = 'Post to soft-closed jobs flag = N for Job ' + isnull(@Job,'') +
								' and PO#: ' + isnull(@po,'') + ', Item: ' + isnull(convert(varchar(6), @poitem),'') + ', and PO Co: ' + isnull(convert(varchar(6), @poco),'') + ' is incomplete!'
   						exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   						select @ContractOK='N'
						if @rc <> 0 goto bspexit
						end
					if @PostClosedJobs = 'N' and @SoftFinal='F'
						begin
						select @errortext = 'Post to hard-closed jobs flag = N for Job ' + isnull(@Job,'') +
								' and PO#: ' + isnull(@po,'') + ', Item: ' + isnull(convert(varchar(6), @poitem),'') + ', and PO Co: ' + isnull(convert(varchar(6), @poco),'') + ' is incomplete!'
   						exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
   						select @ContractOK='N'
						if @rc <> 0 goto bspexit
						end
----   		            exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
----   		            select @ContractOK='N'
----					if @rc<>0 goto bspexit
					goto poitem_cursor_loop             --get the next record
					end --
				--close and deallocate cursor
				if @openpoitem=1
					begin --
					close poitem_cursor
					deallocate poitem_cursor
					select @openpoitem=0
					end --
				end -- @TmpCount


				--Allow closing only if CurUnits - InvUnits is zero if UM is not equal to LS
				--otherwise CurCost_InvCost is zero if LS
				select @TmpCount = count(*) from bSLIT with (nolock)
				join bSLHD on bSLHD.SLCo=bSLIT.SLCo and bSLHD.SL=bSLIT.SL and bSLHD.Status<>2
				where bSLIT.JCCo=@JCCo and bSLIT.Job = @Job
				if @TmpCount<>0
					begin -- @TmpCount


					declare sl_cursor cursor local fast_forward for
						select bSLIT.SLCo, bSLIT.SL, bSLIT.SLItem,
                      	'Units' = case bSLIT.UM  when 'LS' then (bSLIT.CurCost - bSLIT.InvCost)
									else (bSLIT.CurUnits - bSLIT.InvUnits) end
					from bSLIT
   			        join bSLHD on bSLHD.SLCo=bSLIT.SLCo and bSLHD.SL=bSLIT.SL and bSLHD.Status<>2
   			        where bSLIT.JCCo=@JCCo and bSLIT.Job = @Job

					open sl_cursor
					select @openslitem=1


					sl_cursor_loop:             --loop through all the records
					fetch next from sl_cursor into @errco, @sl, @slitem, @slunits


					if @@fetch_status=0
						begin --
						if @slunits <> 0
							begin --
							if @postsoftclosedjobs = 'N'
								begin
								select @errortext = 'Post to soft-closed jobs flag = N for Job ' + isnull(@Job,'') +
										' and SL#: ' + isnull(@sl,'') + ', Item: ' + isnull(convert(varchar(6), @slitem),'') + ', and SLCo: ' + isnull(convert(varchar(6), @errco),'') + ' is incomplete!'
   		                		exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
								select @ContractOK='N'
								if @rc<>0 goto bspexit
								end
							if @PostClosedJobs = 'N' and @SoftFinal='F'
								begin
								select @errortext = 'Post to hard-closed jobs flag = N for Job ' + isnull(@Job,'') +
										' and SL#: ' + isnull(@sl,'') + ', Item: ' + isnull(convert(varchar(6), @slitem),'') + ', and SLCo: ' + isnull(convert(varchar(6), @errco),'') + ' is incomplete!'
   		                		exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
								select @ContractOK='N'
								if @rc<>0 goto bspexit
								end
----   		                	exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
----							select @ContractOK='N'
----							if @rc<>0 goto bspexit
							end --
						goto sl_cursor_loop           --get next record
						end --
					--close and deallocate cursor
					if @openslitem=1
						begin --
						close sl_cursor
						deallocate sl_cursor
						select @openslitem=0
						end --
					end -- @TmpCount


				--Allow the Job to close only if RemainUnits is zero and Job is not in use
				select @TmpCount = count(*) from bINMI with (nolock)
				join bINMO with (nolock) on bINMO.INCo=bINMI.INCo and bINMO.MO=bINMI.MO
				where bINMI.JCCo=@JCCo and bINMI.Job = @Job and bINMO.Status <> 2 and bINMI.RemainUnits <> 0
				if @TmpCount<>0
					begin -- @TmpCount
					declare moitem_cursor cursor local fast_forward for
					select bINMI.INCo, bINMI.MO, bINMI.MOItem from bINMI
					join bINMO on bINMO.INCo=bINMI.INCo and bINMO.MO=bINMI.MO
					where bINMI.JCCo=@JCCo and bINMI.Job = @Job and bINMO.Status<>2 and bINMI.RemainUnits <> 0

					open moitem_cursor
					select @openmoitem=1

					moitem_cursor_loop:             --loop through all the records
					fetch next from moitem_cursor into @errco, @mo, @moitem
					if @@fetch_status=0
						begin --
						if @postsoftclosedjobs = 'N'
							begin
							select @errortext = 'Post to soft-closed jobs flag = N for Job ' + isnull(@Job,'') +
									' and MO#: ' + isnull(@mo,'') + ', Item: ' + isnull(convert(varchar(6), @moitem),'') + ', and INCo: ' + isnull(convert(varchar(6), @errco),'') + ' is incomplete!'
							exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
							select @ContractOK='N'
							if @rc<>0 goto bspexit
							end
						if @PostClosedJobs = 'N' and @SoftFinal='F'
							begin
							select @errortext = 'Post to hard-closed jobs flag = N for Job ' + isnull(@Job,'') +
									' and MO#: ' + isnull(@mo,'') + ', Item: ' + isnull(convert(varchar(6), @moitem),'') + ', and INCo: ' + isnull(convert(varchar(6), @errco),'') + ' is incomplete!'
							exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
							select @ContractOK='N'
							if @rc<>0 goto bspexit
							end
----						exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
----						select @ContractOK='N'
----						if @rc<>0 goto bspexit
						goto moitem_cursor_loop             --get the next record
						end --

					--close and deallocate cursor
					if @openmoitem=1
						begin --
						close moitem_cursor
						deallocate moitem_cursor
						select @openmoitem=0
						end --
					end -- @TmpCount
				end --@PostClosedJobs
			end			 -- @Job Done working on Jobs
 
   
         If isnull(@Contract,'')<>''		/* if we are working on the contract */
           begin --@Contract

			Select @lstMthRevenue = max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= @JCCo and JCIP.Contract= @Contract and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968 and
				and (isnull(JCIP.OrigContractAmt,0) <> 0 or isnull(JCIP.OrigContractUnits,0) <> 0 or 
				isnull(JCIP.ContractAmt,0) <> 0 or isnull(JCIP.ContractUnits,0) <> 0 or 
				isnull(JCIP.BilledAmt,0) <> 0 or isnull(JCIP.CurrentRetainAmt,0) <> 0 or isnull(JCIP.BilledTax,0) <> 0)

			 -- #132789 Allow soft close when postings exist in future months.
			 --If @mth < @lstMthRevenue 
			 If (@mth < @lstMthRevenue and @SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@mth < @lstMthRevenue and @SoftFinal = 'F')
					begin
					select @errortext = 'Contract ' + @Contract + ' Revenue postings in future months.  Unable to close.'
   		   			exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
	              	select @ContractOK='N'
					end

           	--ARBI
   	    	select @batchmth=Mth, @batchid2=BatchId from bARBI with (nolock)
           	where JCCo=@JCCo and Contract=@Contract and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
   	    	if @@rowcount>0
   		  	begin --
             	select @errortext = 'Contract ' + isnull(@Contract,'') + ' exists in ARBI for Month: ' +
                 isnull(convert(varchar(3),@batchmth,1),'') +
   		        isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                 ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
 
 				if not exists(select 1 from bHQBE
 				WHERE Co = @co and Mth = @mth and BatchId = @batchid and ErrorText = @errortext)
 				begin
   		   			exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
 				end
              	select @ContractOK='N'
     		end --
   	       	if @rc<>0 goto bspexit
   
          	--ARBH
           	select @errco=Co, @batchmth=Mth, @batchid2=BatchId from bARBH with (nolock)
           	where JCCo = @JCCo and Contract = @Contract and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
           	if @@rowcount>0
   		   	begin --
             	select @errortext = 'Contract ' + isnull(@Contract,'') +
             		' exists in ARBH for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
					isnull(convert(varchar(3),@batchmth,1),'') +
   					isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
					' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
 
 				if not exists(select 1 from bHQBE
 				WHERE Co = @co and Mth = @mth and BatchId = @batchid and ErrorText = @errortext)
 				begin
   		   			exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
 				end
              	select @ContractOK='N'
     		end --
   	       	if @rc<>0 goto bspexit
 
           	--ARBL
           	select @errco=Co, @batchmth=Mth, @batchid2=BatchId from dbo.bARBL with (nolock)
           	where JCCo = @JCCo and Contract = @Contract and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
           	if @@rowcount>0
   		   	begin --
             	select @errortext = 'Contract ' + isnull(@Contract,'') + 
             		' exists in ARBL for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                 isnull(convert(varchar(3),@batchmth,1),'') +
   		        isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                 ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
 
 				if not exists(select 1 from bHQBE
 				WHERE Co = @co and Mth = @mth and BatchId = @batchid and ErrorText = @errortext)
 				begin
   		   			exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
 				end
              	select @ContractOK='N'
     		end --
   	       	if @rc<>0 goto bspexit
 
           	--JBAR
           	select @errco=Co, @batchmth=Mth, @batchid2=BatchId from dbo.bJBAR with (nolock)
           	where Co = @JCCo and Contract = @Contract and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
           	if @@rowcount>0
   		   	begin --
             	select @errortext = 'Contract ' + isnull(@Contract,'') +
             			' exists in JBAR for Co: ' + convert(varchar(3),@errco) +  + ' Month: ' +
                 isnull(convert(varchar(3),@batchmth,1),'') +
   		        isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                 ' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
 
 				if not exists(select 1 from bHQBE
 				WHERE Co = @co and Mth = @mth and BatchId = @batchid and ErrorText = @errortext)
 				begin
   		   			exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
 				end
              	select @ContractOK='N'
     		end --
   	       	if @rc<>0 goto bspexit
 
           	--JBIN
            	select @errco=JBCo, @batchmth = BillMonth, @batchid2 = BillNumber from dbo.bJBIN with (nolock)
            	where JBCo = @JCCo and Contract = @Contract and InvStatus in ('A', 'C', 'D') and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
            	if @@rowcount>0
             	begin --
  			 	/* Issue 21167 - errortext fixed to say 'Bill #' instead of 'BatchId'. */
               	select @errortext = 'Contract ' + isnull(@Contract,'') + 
               			' exists in JBIN for Co: ' + convert(varchar(3),@errco) + ' Month: ' +
                 isnull(convert(varchar(3),@batchmth,1),'') +
   		        isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                 ' and Bill #: ' + isnull(convert(varchar(6), @batchid2),'')
 
 				if not exists(select 1 from bHQBE
 				WHERE Co = @co and Mth = @mth and BatchId = @batchid and ErrorText = @errortext)
 				begin
   		   			exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
 				end
              	select @ContractOK='N'
     		end --
   	       	if @rc<>0 goto bspexit
   
           	--JCIB
            	select @batchmth = Mth, @batchid2 = BatchId from bJCIB with (nolock)
            	where Co = @JCCo and Contract = @Contract and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
            	if @@rowcount>0
               	begin --
               	select @errortext = 'Contract ' + isnull(@Contract,'') + ' exists in JCIB for Month: ' +
                	isnull(convert(varchar(3),@batchmth,1),'') +
 
   		       	isnull(substring(convert(varchar(8),@batchmth,1),7,2),'') +
                	' and BatchId: ' + isnull(convert(varchar(6), @batchid2),'')
 
 				if not exists(select 1 from bHQBE
 				WHERE Co = @co and Mth = @mth and BatchId = @batchid and ErrorText = @errortext)
 				begin
   		   			exec @rc=bspHQBEInsert @co, @mth, @batchid, @errortext, @errormsg output
 				end
              	select @ContractOK='N'
     		end --
   	       	if @rc<>0 goto bspexit
   
           end --@Contract
   
   --Done Checking Contracts

   --check to see whether JC Contract close month is before the Contract start month
   select @startmonth=StartMonth from bJCCM with (nolock)
   where JCCo=@co and Contract=@Contract and ContractStatus=1 --#136405 and ((@SoftFinal = 'S' and @postsoftclosedjobs <> 'Y') or (@SoftFinal = 'F')) -- #136968
   if @@rowcount <> 0
      begin -- @@rowcount
      if @startmonth > @mth
           begin --
           select @errmsg = 'Month Closed may not be earlier than the start month', @rcode = 1
   		goto bspexit
   	    end --
      end -- @@rowcount
   --Done checking month
 
   
       if (@Job='' or @Job is null) and @ContractOK='Y' and @SoftFinal <> 'S'	--If all jobs and contract passed tests then add to distribution file if they are final closing them.
           begin -- @SoftFinal <> 'S'
  --Issue 14175
 
            set nocount on
  
            declare crs_GLAcctCostOverrides cursor local fast_forward
            for
            select JCCI.JCCo, JCCI.Department, JCCI.Contract, isnull(convert (numeric(12,2),sum(JCCP.ActualCost)),0), JCJP.Phase, JCCP.CostType
            from JCCI
            join JCJP on JCJP.JCCo = JCCI.JCCo and JCJP.Contract=JCCI.Contract and JCJP.Item=JCCI.Item
            join JCCP on JCCP.JCCo = JCJP.JCCo and JCCP.PhaseGroup=JCJP.PhaseGroup and JCCP.Job = JCJP.Job and JCCP.Phase=JCJP.Phase  
            where JCCI.JCCo=@co and JCCI.Contract=@Contract
            group by JCCI.JCCo, JCCI.Department, JCCI.Contract, JCCP.ActualCost, JCJP.Phase, JCCP.CostType
            having isnull(convert (numeric(12,2), (JCCP.ActualCost)),0)<>0
  
            open crs_GLAcctCostOverrides
  
            fetch crs_GLAcctCostOverrides into
            @crs_jcco, @crs_department , @crs_contract, @crs_actualcost, @crs_phase, @crs_costtype
            select @GLAcct_status = @@Fetch_Status
            while @GLAcct_status = 0
            begin -- @GLAcct_status
                 select @crs_openwipacct = null, @crs_closedexpacct = null
  
                 select @crs_openwipacct = d.OpenWIPAcct, @crs_closedexpacct = d.ClosedExpAcct, @crs_glco = d.GLCo
                 from JCDO d with (nolock)
                 where d.JCCo = @crs_jcco and d.Department = @crs_department and d.Phase = @crs_phase
                 if @@rowcount = 0
                 begin --@@rowcount
                      select @crs_validphasechars = ValidPhaseChars
                      from JCCO  with (nolock) where JCCo = @crs_jcco
                      if @@rowcount <> 0
                      begin --@@rowcount
                           if @crs_validphasechars > 0
                           begin --
                                	--select @crs_pphase = substring(@crs_phase,1,@crs_validphasechars) + '%'
 								select @crs_pphase  = substring(@crs_phase,1,@validphasechars)
 								if @InputMask = 'R'
 									begin
 									select @pphase = SPACE(@InputLength-DATALENGTH(@crs_pphase)) + @crs_pphase
 									end
 
 								if @InputMask = 'M'
 									begin
     								exec @rc = bspHQFormatMultiPart @crs_pphase, @InputMask, @pphase output
 									end
 
                                	select @crs_openwipacct = d.OpenWIPAcct, @crs_closedexpacct = d.ClosedExpAcct, @crs_glco = d.GLCo
                                	from JCDO d  with (nolock)
                                	where d.JCCo = @crs_jcco and d.Department = @crs_department and d.Phase = @pphase
                           end --
                      end --@@rowcount
                 end --@@rowcount

				-- No Phase Override Account found then use the Account from the Department
				set @ctclosewipflag = 'N'
				set @ctopenwipflag = 'N'
				if isnull(@crs_openwipacct,'') = ''
					begin --@crs_openwipacct
					select @crs_openwipacct = d.OpenWIPAcct, @crs_glco = d.GLCo
					from JCDC d  with (nolock)
					where d.JCCo = @crs_jcco and d.Department = @crs_department and CostType = @crs_costtype
					if @@rowcount <> 0 select @ctopenwipflag = 'Y'
                 end --@crs_openwipacct
  
				if isnull(@crs_closedexpacct,'') = ''
					begin --@crs_closedexpacct
					select @crs_closedexpacct = d.ClosedExpAcct, @crs_glco = d.GLCo
					from JCDC d  with (nolock)
					where d.JCCo = @crs_jcco and d.Department = @crs_department and CostType = @crs_costtype
					if @@rowcount <> 0 select @ctclosewipflag = 'Y'
					end --@crs_closedexpacct

  				-- validate GL Accounts only on Final close and the Close Interface level is greater than 0
  				if isnull(@GLCloseLvl,0)>0
  					begin --@GLCloseLvl
					exec @rc = bspGLACfPostable @crs_glco, @crs_openwipacct, 'J', @errmsg output
					if @rc <> 0
						begin
						select @errortext = 'Department: ' + isnull(@crs_department,'') 
						if @ctopenwipflag = 'Y'
							begin
							select @errortext = @errortext + ' Cost Type: ' + isnull(convert(varchar(3),@crs_costtype),'')
							end
						select @errortext = @errortext + ' Open Expense Account:' + isnull(@crs_openwipacct,'') + ' ' + isnull(@errmsg,'')
						exec @rc = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
						end

					exec @rc = bspGLACfPostable @crs_glco, @crs_closedexpacct, 'J', @errmsg output
					if @rc <> 0
						begin
						select @errortext = 'Department: ' + isnull(@crs_department,'') 
						if @ctclosewipflag = 'Y'
							begin
							select @errortext = @errortext + ' Cost Type: ' + isnull(convert(varchar(3),@crs_costtype),'')
							end
						select @errortext = @errortext + ' Close Expense account: ' + isnull(@crs_closedexpacct,'') + ' ' + isnull(@errmsg,'')
						exec @rc = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
						end
					end --@GLCloseLvl
  

  				if isnull(@crs_openwipacct,'') <> isnull(@crs_closedexpacct,'')
  					begin --
  		               insert into #GL_SUM
  		               select @crs_jcco, @crs_department, @crs_contract, @crs_glco, @crs_openwipacct, @crs_closedexpacct, @crs_actualcost
  					end --
  
  	        fetch next from crs_GLAcctCostOverrides into 
  			@crs_jcco, @crs_department , @crs_contract, @crs_actualcost, @crs_phase, @crs_costtype
  	        select @GLAcct_status = @@Fetch_Status
  		end -- @GLAcct_status End While GL Account Status
            close crs_GLAcctCostOverrides
            deallocate crs_GLAcctCostOverrides
 
          
  			-- validate GL Accounts only on Final clase and the Close Interface level is greater than 0
  			if isnull(@GLCloseLvl,0)>0
  				begin --@GLCloseLvl
  
  				declare crs_GLAcctRevenue cursor local fast_forward
            		for
            		select JCCO.JCCo, JCCI.Department, JCCI.Contract,	JCDM.GLCo, JCDM.OpenRevAcct, JCDM.ClosedRevAcct
            		from JCCI  
            		join JCCO on JCCO.JCCo=JCCI.JCCo
            		join JCIP on JCIP.JCCo = JCCI.JCCo and JCIP.Contract=JCCI.Contract and JCCI.Item=JCIP.Item
            		join JCDM on JCDM.JCCo = JCCI.JCCo and JCDM.Department = JCCI.Department
            		where JCCI.JCCo=@co and JCCI.Contract=@Contract
            		group by JCCO.JCCo, JCCI.Department, JCCO.GLCloseLevel, JCCI.Contract,
    		  		JCDM.GLCo, JCDM.OpenRevAcct, JCDM.ClosedRevAcct, JCIP.BilledAmt
            		having JCDM.OpenRevAcct <> JCDM.ClosedRevAcct and isnull(convert (numeric(12,2), (JCIP.BilledAmt)),0)<>0
   	    
  
  				open crs_GLAcctRevenue
  
  		        fetch crs_GLAcctRevenue into
  				@crs_jcco, @crs_department , @crs_contract, @crs_glco, @crs_openrevacct, @crs_closedrevacct
  				select @GLAcct_status = @@Fetch_Status
            		while @GLAcct_status = 0
           		 	begin  --@GLAcct_status
  
  						exec @rc = bspGLAcctVal @crs_glco, @crs_openrevacct, @errmsg output
          				if @rc <> 0
           					begin --
    	    						select @errortext = 'Department ' + isnull(@crs_department,'') + ' Open Revenue Account:' + isnull(@crs_openrevacct,'') + ' ' + isnull(@errmsg,'')
    	    						exec @rc = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  								if @rc <> 0 goto bspexit
    	    					end --
  
  						exec @rc = bspGLAcctVal @crs_glco, @crs_closedrevacct, @errmsg output
          				if @rc <> 0
           					begin --
    	    						select @errortext = 'Department ' + isnull(@crs_department,'') + ' Close Revenue account:' + isnull(@crs_closedrevacct,'') + ' ' + isnull(@errmsg,'')
    	    						exec @rc = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  								if @rc <> 0 goto bspexit
    	    					end --
  			        fetch next from crs_GLAcctRevenue into 
  					@crs_jcco, @crs_department , @crs_contract, @crs_glco, @crs_openrevacct, @crs_closedrevacct
  	        		select @GLAcct_status = @@Fetch_Status
  					end --@GLAcct_status End While
  
            		close crs_GLAcctRevenue
            		deallocate crs_GLAcctRevenue 
  				end -- @GLCloseLvl End GL Close Level
  
  
      -- Create GL Distributions for revenue
   
       --put revenue into temp table
            insert into #GL_SUM
            select JCCO.JCCo, JCCI.Department, JCCI.Contract,
               JCDM.GLCo, JCDM.OpenRevAcct, JCDM.ClosedRevAcct,
               isnull (convert (numeric(12,2), -(sum(JCIP.BilledAmt))),0)
            from JCCI  with (nolock)
            join JCCO with (nolock) on JCCO.JCCo=JCCI.JCCo
            join JCIP  with (nolock) on JCIP.JCCo = JCCI.JCCo and JCIP.Contract=JCCI.Contract and JCCI.Item=JCIP.Item
            join JCDM  with (nolock) on JCDM.JCCo = JCCI.JCCo and JCDM.Department = JCCI.Department
            where JCCI.JCCo=@co and JCCI.Contract=@Contract
            group by JCCO.JCCo, JCCI.Department, JCCO.GLCloseLevel, JCCI.Contract,
    		  JCDM.GLCo, JCDM.OpenRevAcct, JCDM.ClosedRevAcct, JCIP.BilledAmt
            having JCDM.OpenRevAcct <> JCDM.ClosedRevAcct and isnull(convert (numeric(12,2), (JCIP.BilledAmt)),0)<>0
  
         end
   
   /****** Get next record  *****/
   
      nextrec:
         select @TmpContract = @Contract
         fetch next from bcJCXB into @JCCo, @Contract, @Job, @LastContractMth, @LastJobMth, @CloseDate, @SoftFinal
    	   select @JCXB_status = @@fetch_status
   
   end
   --Put contents of temp table into audit table
   --select * from #GL_SUM
  
       insert into bJCXA(Co, Mth, BatchId, GLCo, GLAcct, Department, Contract, ActDate, Description, Amount)
            select #GL_SUM.JCCo, @mth, @batchid, #GL_SUM.GLCo, #GL_SUM.GLOpenAcct, Department, Contract, @dateposted, null, -(sum(GLAmt))
            from #GL_SUM
            join JCCO with (nolock) on JCCO.JCCo = #GL_SUM.JCCo
 			where #GL_SUM.GLOpenAcct is not null
   	     group by #GL_SUM.JCCo, #GL_SUM.GLCo, #GL_SUM.GLOpenAcct, Department, Contract
   
            insert into bJCXA(Co, Mth, BatchId, GLCo, GLAcct, Department, Contract, ActDate, Description, Amount)
            select #GL_SUM.JCCo, @mth, @batchid, #GL_SUM.GLCo, #GL_SUM.GLClosedAcct, Department, Contract, @dateposted, null, sum(GLAmt)
            from #GL_SUM
            join JCCO with (nolock) on JCCO.JCCo = #GL_SUM.JCCo
 			where #GL_SUM.GLClosedAcct is not null
   	     group by #GL_SUM.JCCo, #GL_SUM.GLCo, #GL_SUM.GLClosedAcct, Department, Contract
  
   
   
   --check HQ Batch Errors and update HQ Batch Control status
   
   select @status = 3	-- valid - ok to post
   if exists(select * from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
   	begin --
   	select @status = 2	--validation errors
   	end --
   
   update bHQBC
   	set Status = @status
   	where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
   	begin --
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end --
   
   bspexit:
   	if @opencursor = 1
   		begin--
   		close bcJCXB
    		deallocate bcJCXB
 		select @opencursor =0
   		end --
   
        if @openslitem=1
           begin --
           close sl_cursor
           deallocate sl_cursor
           select @openslitem=0
           end --
   
       if @openpoitem=1
           begin --
           close poitem_cursor
           deallocate poitem_cursor
   		 select @openpoitem=0
           end --
  
       if @openmoitem=1
           begin --
           close moitem_cursor
           deallocate moitem_cursor
   		 select @openmoitem=0
           end --
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCXBVal] TO [public]
GO
