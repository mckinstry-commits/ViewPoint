SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE             proc  [dbo].[bspJCCDRollup_Month]
   
   /*********************************************************
   *	Created:	TV 06/23/03
   *	Modified:	TV 2/19/04 23843 Use the GLCo from JCCo
   *				TV 2/19/04 23843 Use the GLCo from JCCo + speed issues
   *				TV - 23061 added isnulls
*				CHS 1/22/08 - 29740 added JBBillStatus = '2' to insert
*				GF 09/10/2010 - issue #141031 changed to use vfDateOnly
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
*
*
   *	Purpose:  Called by JCCD  Roll-up form to summarize data in bJCCD into
   *		one transaction per unique Month 
   *
   *	Input: 
   *	@co				JC Company
   * @code           Roll up procedure to run.
   *	@Begin         	Begining job or contract
   *	@ending        	Ending Job or Contract
   *   @RollupOption   Job/Contract Status to roll-up
   *
   *	Output:
   *	@msg			Message - error text or rollup summary
   *
   *	Return Code:
   *	0 = success, 1 = failure
   *
   **********************************************************/
   (@co bCompany = null, @code varchar(5), @begin varchar(10) = null, @end Varchar(10) = null, @option char,
   @rowcount int output, @errmsg varchar(255) output)
   
   as
   
   SET NOCOUNT ON
    --#142350	-- removing @contract bContract,
	DECLARE @rolluptype char(1),
			@rollupsel char(1),
			@rollupsourceap char(1),
			@rollupsourcems char(1),
			@rollupsourcein char(1),
			@rollupsourcepr char(1),
			@rollupsourcear char(1),
			@rollupsourcejc char(1),
			@rollupsourceem char(1),
			@summarylevel char(1),
			@monthback int,
			@query varchar(300),
			@count int,
			@table varchar(15),
			@lastclosedmth bMonth,
			@JCCo bCompany,
			@Mth bMonth,
			@Job bJob,
			@Phase bPhase,
			@CostType bJCCType,
			@Source bSource,
			@CostTrans bTrans,
			@PhaseGroup bGroup,
			@um varchar(5),
			@date bDate,
			@vendor bVendor,
			@equip bEquip,
			@material varchar(10),
			@payrolldate bMonth,
			@Contract bContract,
			@ContractItem bContractItem,
			@ARCo bCompany,
			@ARTrans bTrans,
			@rcode int,
			@ActualUnits bUnits,
			@EstUnits bUnits,
			@ProjUnits bUnits,
			@ForecastUnits bUnits,
			@PostTotCmUnits bUnits,
			@TotalCmtdUnits bUnits,
			@RemainCmtdUnits bUnits
   
   declare @jccdcursor int, @jcidcursor int, @compmth bMonth--, @rowcount int
   
   select @rcode = 0, @rowcount = 0
   ----#141031
   set @date = dbo.vfDateOnly()
   
   --first select the Rollup info from JCRU
   select @rolluptype = RollupType, @rollupsel = RollupSel, @rollupsourceap = RollupSourceAP, @rollupsourcems = RollupSourceMS,
   @rollupsourcein = RollupSourceIN, @rollupsourcepr = RollupSourcePR, @rollupsourcear =RollupSourceAR, 
   @rollupsourcejc =RollupSourceJC, @rollupsourceem = RollupSourceEM, @summarylevel = SummaryLevel,
   @monthback = MonthsBack
   from bJCRU u
   where u.JCCo = @co and u.RollupCode = @code
   
   --make sure @begin and @end are null if they are empty strings
   if (select len(@begin)) < 1 
       select @begin = ''
   if (select len(@end)) < 1 
       select @end = '~~~~~~~~~~~'
   
   --get the last closed subcontract month form GL
   -- TV 2/19/04 23843 Use the GLCo from JCCo
   select @lastclosedmth = (select LastMthSubClsd from bGLCO g join bJCCO j on g.GLCo = j.GLCo 
   						  where j.JCCo = @co) --where GLCo = @co   
   
   --TV 2/19/04 23843 Use the GLCo from JCCo + speed issues
   select @compmth = dateadd(Month,-1 * @monthback,@lastclosedmth )
   
   If @rolluptype = 'C'--JCCD By Month!
       begin --Begin JCCD
       
       --Create a Cursor to go thought the table
       declare bcJCCDRollup cursor for 
       select distinct d.JCCo, d.Mth, d.Job, d.PhaseGroup, d.Phase, d.CostType, h.UM 
       from bJCCD d 
       join bJCJM m on m.JCCo = d.JCCo and m.Job = d.Job 
       join bJCCH h on d.JCCo = h.JCCo and d.Job = h.Job and d.PhaseGroup = h.PhaseGroup and  d.Phase =h.Phase
       and d.CostType = h.CostType
       where (d.Mth <= @compmth) and d.JCCo = @co and 
       (d.JCTransType not in ('OE', 'CV','CO','RU') and 
       (((select UseJobBilling from bJCCO where JCCo = @co) <> 'Y' or 
       (select DefaultBillType from bJCCO where JCCo = @co) <> 'T')or
       isnull(d.JBBillStatus,1) in (1,2))) and (select count(*) from bJCCD d2 where d.JCCo = d2.JCCo and  
       d.Mth = d2.Mth and d.Job = d2.Job and d.Phase = d2.Phase and d.CostType = d2.CostType and 
       d2.JCCo = @co) > 1 and --Make sure there is more than one record to even consider it for Roll-Up
       d.Job >= @begin and  d.Job <= @end and
       (m.JobStatus = case when @option = 'O' then 1 end or --Open
       m.JobStatus = case when @option = 'C' then 2 end or --Closed
       m.JobStatus = case when @option = 'C' then 3 end or --Closed
       m.JobStatus = case when @option = 'B' then 1 end or --Both
       m.JobStatus = case when @option = 'B' then 2 end or 
       m.JobStatus = case when @option = 'B' then 3 end) --Both
       
       open bcJCCDRollup
   
       Fetch_Next_JCCD:
       fetch next from bcJCCDRollup into  @JCCo, @Mth, @Job, @PhaseGroup, @Phase, @CostType, @um 
                            
       if @@fetch_status <> 0 goto Fetch_End_JCCD
       select @jccdcursor = 1
       begin transaction
       select @CostTrans = 0
       
       exec @CostTrans = bspHQTCNextTrans bJCCD, @JCCo, @Mth, @errmsg output
       if @CostTrans = 0 goto Posting_Error_JCCD
   
       select @ActualUnits = isnull(sum(ActualUnits),0), @EstUnits = isnull(sum(EstUnits),0), 
       @ProjUnits = isnull(sum(ProjUnits),0), @ForecastUnits = isnull(sum(ForecastUnits),0),
       @PostTotCmUnits = isnull(sum(PostTotCmUnits),0), @TotalCmtdUnits = isnull(sum(TotalCmtdUnits),0),
       @RemainCmtdUnits = isnull(sum(RemainCmtdUnits),0)
       from bJCCD
       where JCCo = @JCCo and  Mth = @Mth and Job = @Job and Phase = @Phase and CostType = @CostType 
             and JCTransType not in ('OE', 'CV','CO','RU')and UM = @um
       
       CTCheck:
       if exists (select top 1 CostTrans from bJCCD where JCCo = @JCCo and Mth = @Mth and CostTrans = @CostTrans) 
           begin
           exec @CostTrans = bspHQTCNextTrans bJCCD, @JCCo, @Mth, @errmsg output
           select @rowcount = @rowcount + 1
           goto CTCheck
           end
       
       --Insert the new single rolled up record
       insert bJCCD (JCCo,Mth,Job,CostTrans,PhaseGroup,Phase,CostType,JCTransType,Source,Description,UM,
          ActualHours,ActualUnits,ActualCost,EstHours,EstUnits,EstCost,ProjHours,ProjUnits,ProjCost,ForecastHours,ForecastUnits,
          ForecastCost,PostTotCmUnits,PostRemCmUnits,TotalCmtdUnits,TotalCmtdCost,RemainCmtdUnits,RemainCmtdCost,
          TaxBasis,TaxAmt,INStdUnitCost,DeleteFlag,PostedUnitCost,PostedUnits,ProgressCmplt,ActualUnitCost,
          ReversalStatus,ActualDate,PostedDate,JBBillStatus)
          
          select @JCCo, @Mth, @Job, @CostTrans,@PhaseGroup,@Phase,@CostType,'RU','Roll Up','Roll Up',@um,
          isnull(sum(ActualHours),0),@ActualUnits/*isnull(sum(ActualUnits),0)*/, isnull(sum(ActualCost),0), 
          isnull(sum(EstHours),0),@EstUnits/*isnull(sum(EstUnits),0)*/,isnull(sum(EstCost),0),
          isnull(sum(ProjHours),0),@ProjUnits/* isnull(sum(ProjUnits),0)*/,isnull(sum(ProjCost),0),
          isnull(sum(ForecastHours),0),@ForecastUnits,--isnull(sum(ForecastUnits),0),
          isnull(sum(ForecastCost),0),isnull(sum(PostTotCmUnits),0),
          @PostTotCmUnits/*isnull(sum(PostRemCmUnits),0)*/,@TotalCmtdUnits,--isnull(sum(TotalCmtdUnits),0),
          isnull(sum(TotalCmtdCost),0),@RemainCmtdUnits,--isnull(sum(RemainCmtdUnits),0),
          isnull(sum(RemainCmtdCost),0),isnull(sum(TaxBasis),0),
          isnull(sum(isnull(TaxAmt,0)),0),0,'N',0,0,0,0,0, @date,@date,'2'
          from bJCCD where JCCo = @JCCo and  Mth = @Mth and Job = @Job and Phase = @Phase and CostType = @CostType 
          and JCTransType not in ('OE', 'CV','CO','RU')and CostTrans <> @CostTrans  
       
       --delete all but rolled-up entries in JCCD
       delete bJCCD where JCCo = @JCCo and  Mth = @Mth and Job = @Job and Phase = @Phase and CostType = @CostType 
       and CostTrans <> @CostTrans and JCTransType not in ('OE', 'CV','CO','RU')
       select @rowcount = @rowcount + @@rowcount    
       
       
       commit transaction
       goto Fetch_Next_JCCD
       Posting_Error_JCCD:
       Fetch_End_JCCD:
       close bcJCCDRollup
       deallocate  bcJCCDRollup
       select @jccdcursor = 0
       end --End JCCD
   
   If @rolluptype = 'R'--JCID By Month
       begin --begin JCID
       --Create a Cursor to go thought the table
       declare bcJCIDRollup cursor local fast_forward for 
       
       
       select distinct d.JCCo, d.Mth, d.Contract, d.Item, 
          case when @summarylevel = 'S' then d.TransSource else 'Roll up' end
       from bJCID d
       join bJCCM m on m.JCCo = d.JCCo and m.Contract = d.Contract 
       where (d.Mth <= @lastclosedmth and @lastclosedmth >=dateadd(Month,-1 * @monthback,@lastclosedmth )) and 
       d.JCCo = @co and d.JCTransType not in ('OC','CO','RU') and(
       (((select UseJobBilling from bJCCO where JCCo = @co) <> 'Y' or 
       (select DefaultBillType from bJCCO where JCCo = @co) <> 'T')or
       isnull(m.ContractStatus,1) in (1,2))) and 
       (select count(*) 
       from bJCID d2
       join bJCCM m2 on m2.JCCo = d2.JCCo and m2.Contract = d2.Contract
   
       where d.JCCo = d2.JCCo and  
       d.Mth = d2.Mth and d.Contract = d2.Contract and  d.Item = d2.Item and 
       (d.TransSource = d2.TransSource or d.JCTransType = d2.JCTransType) and
       d2.JCCo = @co and d2.JCTransType not in ('OC','CO','RU')) > 1 and 
       d.Contract >= isnull(@begin,d.Contract) and d.Contract <= isnull(@end, d.Contract) and --when source is JC
       (m.ContractStatus = case when @option = 'O' then 1 end or --Open
       m.ContractStatus = case when @option = 'C' then  2 end or --Closed
       m.ContractStatus = case when @option = 'C' then 3 end or --Closed
       m.ContractStatus = case when @option = 'B' then 1 end or --Both
       m.ContractStatus = case when @option = 'B' then 2 end or --Both
       m.ContractStatus = case when @option = 'B' then 3 end) --Both
       group by d.JCCo, d.Mth,d.TransSource, d.Contract, d.Item, 
       d.ARCo, d.ARTrans, d.TransSource
       
       
       open bcJCIDRollup
       Fetch_Next_JCID:
       fetch next from bcJCIDRollup into @JCCo, @Mth, @Contract, @ContractItem, @Source
       
       if @@fetch_status <> 0 goto Fetch_End_JCID
       begin transaction
       select @jcidcursor = 1
       select @CostTrans = 0
       
       --get new CostTrans for Rollup entry
       exec @CostTrans = bspHQTCNextTrans bJCID, @JCCo, @Mth, @errmsg output
       if @CostTrans = 0 goto Posting_Error_JCID
       
       if (select @summarylevel) = 'M'--By Month level
           begin
           insert bJCID
           (JCCo,Mth,ItemTrans,Contract,Item,JCTransType,TransSource,Description,PostedDate,ActualDate,ContractAmt,
           ContractUnits,UnitPrice,BilledUnits,BilledAmt,ReceivedAmt,CurrentRetainAmt,ReversalStatus)
           
           select @JCCo,@Mth,@CostTrans,@Contract,@ContractItem,'RU','Roll Up','Roll Up',
           ----#141031
           dbo.vfDateOnly(), dbo.vfDateOnly(),
           isnull(sum(d.ContractAmt),0),isnull(sum(d.ContractUnits),0),isnull(sum(d.UnitPrice),0),isnull(sum(d.BilledUnits),0),
           isnull(sum(d.BilledAmt),0),isnull(sum(d.ReceivedAmt),0),isnull(sum(d.CurrentRetainAmt),0),0 
           from bJCID d
           where d.JCCo = @JCCo and d.Mth = @Mth and d.Contract = @Contract and d.Item = @ContractItem 
           and d.JCTransType not in ('OC','CO','RU') 
           end
           
       delete bJCID  where JCCo = @JCCo and Mth = @Mth and Contract = @Contract and Item = @ContractItem 
       and ItemTrans <> @CostTrans and JCTransType not in ('OC','CO','RU')
       select @rowcount = @rowcount + @@rowcount    
       
       commit transaction
       goto Fetch_Next_JCID
       Posting_Error_JCID:
       Fetch_End_JCID:
       close bcJCIDRollup
       deallocate  bcJCIDRollup
       select @jcidcursor = 0
       end--end JCID
   
   bspexit:
   
   if  @jcidcursor = 1
   begin
   close bcJCIDRollup
   deallocate  bcJCIDRollup
   end
   
   if  @jccdcursor = 1
   begin
   close bcJCCDRollup
   deallocate  bcJCCDRollup
   end
   
   
   if @rcode = 0 
   begin 
   select @errmsg = isnull(convert(Varchar(10),@rowcount),'') + ' Detail records were successfully rolled up.'
   end
   else 
   begin
   select @errmsg = isnull(@errmsg,'')
   end
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCDRollup_Month] TO [public]
GO
