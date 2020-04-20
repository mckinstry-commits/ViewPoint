SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          Proc [dbo].[bspJCCDRollup]
     
/*********************************************************
*	Created:	TV 08/20/02
*	Modified:	TV 01/17/03 - roll-up to month only.
*				TV 04/24/03 - Added double check for CostTrans
*				TV 06/23/03 - Moved month to it's own proc.
*				TV 2/19/04 23843 Use the GLCo from JCCo + speed issues
*				TV - 23061 added isnulls
*				CHS 1/22/08 - 29740 added JBBillStatus = '2' to insert
*				AMR 01/17/11 - #142350, making incase sensitive by removing unused vars and renaming same named variables
*
*	Purpose:  Called by JCCD  Roll-up form to summarize data in bJCCD into
*		one transaction per unique Month or Month/detail.
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
     	 @errmsg varchar(255) output)
     
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
			@rcode int 
     
     declare @jccdcursor int, @jcidcursor int, @rowcount int, @compmth bMonth
     
     select @rcode = 0, @rowcount = 0 , @date = getdate()
     
     --first select the Rollup info from JCRU
     select @rolluptype = RollupType, @rollupsel = RollupSel, @rollupsourceap = RollupSourceAP, @rollupsourcems = RollupSourceMS,
            @rollupsourcein = RollupSourceIN, @rollupsourcepr = RollupSourcePR, @rollupsourcear =RollupSourceAR, 
            @rollupsourcejc =RollupSourceJC, @rollupsourceem = RollupSourceEM, @summarylevel = SummaryLevel,
            @monthback = MonthsBack
     from bJCRU u
     where u.JCCo = @co and u.RollupCode = @code
   
     -- If Roll-Up by Month, Jump to another Proc..
     if (select @summarylevel) = 'M'
       begin
       exec @rcode = bspJCCDRollup_Month @co, @code, @begin, @end, @option, @rowcount output, @errmsg output
       goto  bspexit
       end
   
     --make sure @begin and @end are null if they are empty strings
     if (select len(@begin)) < 1 
         select @begin = ''
     if (select len(@end)) < 1 
         select @end = '~~~~~~~~~~'
     
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
         select distinct d.JCCo, d.Mth, d.Job, d.PhaseGroup, d.Phase, d.CostType, d.Source,
                          Case when @summarylevel = 'D' and d.Source like '%AP%' then d.Vendor end , --only for Detail roll-up
                          Case when @summarylevel = 'D' and d.Source like '%EM%' then d.EMEquip end, --only for Detail roll-up
                          Case when @summarylevel = 'D' and (d.Source like '%MS%' or d.Source like '%IN%') then d.Material end , --only for Detail roll-up
                          Case when @summarylevel = 'D' and d.Source like '%PR%' then d.ActualDate end, --only for Detail roll-up
                          h.UM 
         from bJCCD d 
         join bJCJM m on m.JCCo = d.JCCo and m.Job = d.Job 
         join bJCCH h on d.JCCo = h.JCCo and d.Job = h.Job and d.PhaseGroup = h.PhaseGroup and  d.Phase =h.Phase
         and d.CostType = h.CostType
         where (d.Mth <= @compmth ) and d.JCCo = @co and 
         (d.JCTransType not in ('OE', 'CV','CO','RU') and 
         (((select UseJobBilling from bJCCO where JCCo = @co) <> 'Y' or 
         (select DefaultBillType from bJCCO where JCCo = @co) <> 'T')or
         isnull(d.JBBillStatus,1) in (1,2))) and (select count(*) from bJCCD d2 where d.JCCo = d2.JCCo and  
         d.Mth = d2.Mth and d.Job = d2.Job and d.Phase = d2.Phase and d.CostType = d2.CostType and 
         d.Source = d2.Source and  d2.JCCo = @co and
         isnull(d2.Vendor,'') = Case when @summarylevel = 'D' and d.Source like '%AP%' then isnull(d.Vendor,'')else isnull(d2.Vendor,'') end and
         isnull(d2.EMEquip,'') = Case when @summarylevel = 'D' and d.Source like '%EM%' then isnull(d.EMEquip,'')else isnull(d2.EMEquip,'') end and 
         isnull(d2.Material,'') = Case when @summarylevel = 'D' and (d.Source like '%MS%' or d.Source like '%IN%') 
                                  then isnull(d.Material,'') else isnull(d2.Material,'')end  
         ) > 1 and --Make sure there is more than one record to even consider it for Roll-Up
         d.Job >= @begin and  d.Job <= @end and
         (isnull(d.Source,'') Like case when /*@summarylevel <> 'M' and */@rollupsourceap = 'Y' then '%AP%' /*else d.Source*/ end or --when source is AP
         isnull(d.Source,'') Like case when /*@summarylevel <> 'M' and*/ @rollupsourceem = 'Y'  then '%EM%' /*else isnull(d.Source,'')*/ end or --when source is EM
         isnull(d.Source,'') Like case when /*@summarylevel <> 'M' and*/ @rollupsourcems = 'Y'  then '%MS%' /*else isnull(d.Source,'')*/ end or --when source is MS
         isnull(d.Source,'') Like case when /*@summarylevel <> 'M' and*/ @rollupsourcein = 'Y'  then '%IN%' /*else isnull(d.Source,'')*/ end or --when source is IN
         isnull(d.Source,'') Like case when /*@summarylevel <> 'M' and*/ @rollupsourcejc = 'Y'  then '%JC%' /*else isnull(d.Source,'')*/ end or --when source is JC
         isnull(d.Source,'') Like case when /*@summarylevel <> 'M' and*/ @rollupsourcear = 'Y'  then '%AR%' /*else isnull(d.Source,'')*/ end or
         isnull(d.Source,'') Like case when /*@summarylevel <> 'M' and*/ @rollupsourcepr = 'Y'  then '%PR%' /*else isnull(d.Source,'')*/ end)  and  --when source is PR
         (m.JobStatus = case when @option = 'O' then 1 end or --Open
          m.JobStatus = case when @option = 'C' then 2 end or --Closed
          m.JobStatus = case when @option = 'C' then 3 end or --Closed
          m.JobStatus = case when @option = 'B' then 1 end or --Both
          m.JobStatus = case when @option = 'B' then 2 end or 
          m.JobStatus = case when @option = 'B' then 3 end) --Both
         
         open bcJCCDRollup
         Fetch_Next_JCCD:
         fetch next from bcJCCDRollup into  @JCCo, @Mth, @Job, @PhaseGroup, @Phase, @CostType, @Source,
                                            @vendor, @equip, @material,@payrolldate, @um 
                                            
         if @@fetch_status <> 0 goto Fetch_End_JCCD
         select @jccdcursor = 1
         begin transaction
         select @CostTrans = 0
         
         --get new CostTrans for Rollup entry
         exec @CostTrans = bspHQTCNextTrans bJCCD, @JCCo, @Mth, @errmsg output
         	if @CostTrans = 0 goto Posting_Error_JCCD
               
         
         if (select @summarylevel) = 'S'--By Month/Source level
              begin
              if exists (select 1 from bJCCD where JCCo = @JCCo and Mth = @Mth and CostTrans = @CostTrans) 
                  begin
                  exec @CostTrans = bspHQTCNextTrans bJCCD, @JCCo, @Mth, @errmsg output
         	      end
              --Insert the new sigle rolled up record
              insert bJCCD (JCCo,Mth,Job,CostTrans,PhaseGroup,Phase,CostType,JCTransType,Source,Description,UM,
              ActualHours,ActualUnits,ActualCost,EstHours,EstUnits,EstCost,ProjHours,ProjUnits,ProjCost,ForecastHours,ForecastUnits,
              ForecastCost,PostTotCmUnits,PostRemCmUnits,TotalCmtdUnits,TotalCmtdCost,RemainCmtdUnits,RemainCmtdCost,
              TaxBasis,TaxAmt,INStdUnitCost,DeleteFlag,PostedUnitCost,PostedUnits,ProgressCmplt,ActualUnitCost,
              ReversalStatus,ActualDate,PostedDate,JBBillStatus)
              
              select @JCCo, @Mth, @Job, @CostTrans,@PhaseGroup,@Phase,@CostType,'RU',@Source,'Roll Up',@um,
              isnull(sum(ActualHours),0),isnull(sum(ActualUnits),0), isnull(sum(ActualCost),0), 
              isnull(sum(EstHours),0),isnull(sum(EstUnits),0),isnull(sum(EstCost),0),
              isnull(sum(ProjHours),0), isnull(sum(ProjUnits),0),isnull(sum(ProjCost),0),
              isnull(sum(ForecastHours),0),isnull(sum(ForecastUnits),0),
              isnull(sum(ForecastCost),0),isnull(sum(PostTotCmUnits),0),
              isnull(sum(PostRemCmUnits),0),isnull(sum(TotalCmtdUnits),0),
              isnull(sum(TotalCmtdCost),0),isnull(sum(RemainCmtdUnits),0),
              isnull(sum(RemainCmtdCost),0),isnull(sum(TaxBasis),0),
              isnull(sum(isnull(TaxAmt,0)),0),0,'N',0,0,0,0,0, @date,@date,'2'
              from bJCCD where JCCo = @JCCo and  Mth = @Mth and Job = @Job and Phase = @Phase and CostType = @CostType and 
              Source = @Source and JCTransType not in ('OE', 'CV','CO','RU')
              end        
             
         if (select @summarylevel) = 'D'  --by Detail Level
              begin
              --double check the costtrans existence.
              if exists (select 1 from bJCCD where JCCo = @JCCo and Mth = @Mth and CostTrans = @CostTrans) 
                  begin
                  exec @CostTrans = bspHQTCNextTrans bJCCD, @JCCo, @Mth, @errmsg output
         	       end
    
              --Insert the new single rolled up record
              Insert bJCCD (JCCo,Mth,Job,CostTrans,PhaseGroup,Phase,CostType,JCTransType,Source,Description,
              Vendor,UM,Material,EMEquip,
              ActualHours,ActualUnits,ActualCost,EstHours,EstUnits,EstCost,ProjHours,ProjUnits,ProjCost,
              ForecastHours,ForecastUnits,ForecastCost,PostTotCmUnits,PostRemCmUnits,TotalCmtdUnits,TotalCmtdCost,
              RemainCmtdUnits,RemainCmtdCost,TaxBasis,TaxAmt,INStdUnitCost,DeleteFlag,PostedUnitCost,PostedUnits,
              ProgressCmplt,ActualUnitCost,ReversalStatus,ActualDate,PostedDate,JBBillStatus)
                     
              select @JCCo, @Mth, @Job, @CostTrans,@PhaseGroup,@Phase,@CostType,'RU',@Source,'Roll Up',
              @vendor,@um,@material,@equip,
              isnull(sum(ActualHours),0),isnull(sum(ActualUnits),0), isnull(sum(ActualCost),0), 
              isnull(sum(EstHours),0),isnull(sum(EstUnits),0),isnull(sum(EstCost),0),
              isnull(sum(ProjHours),0), isnull(sum(ProjUnits),0),isnull(sum(ProjCost),0),
              isnull(sum(ForecastHours),0),isnull(sum(ForecastUnits),0),
              isnull(sum(ForecastCost),0),isnull(sum(PostTotCmUnits),0),
              isnull(sum(PostRemCmUnits),0),isnull(sum(TotalCmtdUnits),0),
              isnull(sum(TotalCmtdCost),0),isnull(sum(RemainCmtdUnits),0),
              isnull(sum(RemainCmtdCost),0),isnull(sum(TaxBasis),0),
              isnull(sum(isnull(TaxAmt,0)),0),0,'N',0,0,0,0,0, 
              isnull(@payrolldate,@date),@date,'2'
				
              from bJCCD where JCCo = @JCCo and  Mth = @Mth and Job = @Job and Phase = @Phase and CostType = @CostType and
              Source = @Source And 
              isnull(Vendor,'') = case when @Source like '%AP%' then @vendor else isnull(Vendor,'') end and
              isnull(EMEquip,'') = case when @Source like '%EM%' then  @equip else isnull(EMEquip,'') end and
              isnull(Material,'') = case when @Source like '%MS%' then @material else isnull(Material,'') end and
              isnull(Material,'') = case when Source like '%IN%' then @material else isnull(Material,'') end and
              isnull(ActualDate,'') = Case when @Source like '%PR%' then @payrolldate else  isnull(ActualDate,'') end and
              (isnull(Source,'') = case when @Source like '%JC%' then  'JC CostAdj' else isnull(Source,'') end or
              isnull(Source,'') = case when @Source like '%JC%' then  'JC Progres' else isnull(Source,'') end and
              isnull(ActualUnits,'') > case when @Source like '%JC%' then  0 else isnull(ActualUnits,'') end and
              isnull(ActualCost,'') = case when @Source like '%JC%' then  0 else isnull(ActualCost,'') end)
              and JCTransType not in ('OE', 'CV','CO','RU')
              end 
         
         
         --delete all but rolled-up entries in JCCD
         delete bJCCD where JCCo = @JCCo and  Mth = @Mth and Job = @Job and Phase = @Phase and CostType = @CostType and
         isnull(Vendor,'') = case when @summarylevel = 'D' and @Source like '%AP%' then @vendor else isnull(Vendor,'') end and --only for Detail roll-up
         isnull(EMEquip,'') = case when @summarylevel = 'D' and @Source like '%EM%' then @equip else isnull(EMEquip,'') end and --only for Detail roll-up
         isnull(Material,'') = case when @summarylevel = 'D' and @Source like '%MS%' then @material else isnull(Material,'') end and --only for Detail roll-up
         isnull(Material,'') = case when @summarylevel = 'D' and @Source like '%IN%' then @material else isnull(Material,'') end and --only for Detail roll-up
         isnull(ActualDate,'') = Case when @summarylevel = 'D' and @Source like '%PR%' then @payrolldate else  isnull(ActualDate,'') end and --only for Detail roll-up
         (isnull(Source,'') = case when @summarylevel = 'D' and @Source like '%JC%' then  'JC CostAdj' else isnull(Source,'') end or --only for Detail roll-up
         isnull(Source,'') = case when @summarylevel = 'D' and @Source like '%JC%' then  'JC Progres' else isnull(Source,'') end and --only for Detail roll-up
         isnull(ActualUnits,'') > case when @summarylevel = 'D' and @Source like '%JC%' then  0 else isnull(ActualUnits,'') end and --only for Detail roll-up
         isnull(ActualCost,'') = case when @summarylevel = 'D' and @Source like '%JC%' then  0 else isnull(ActualCost,'') end)--only for Detail roll-up
         and isnull(Source,'') = @Source  --only for Detail or Source roll-up
         and JCTransType <> 'RU' and CostTrans <> @CostTrans and JCTransType not in ('OE', 'CV','CO')
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
         where (d.Mth <= dateadd(Month,-1 * @monthback,@lastclosedmth )) and 
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
         d2.JCCo = @co and d2.JCTransType not in ('OC','CO')) > 1 and 
         d.Contract >= isnull(@begin,d.Contract) and d.Contract <= isnull(@end, d.Contract) and
         (isnull(d.TransSource,'') Like case when @rollupsourcear = 'Y'  then '%AR%' end or --when source is AR
         isnull(d.TransSource,'') Like case when @rollupsourcejc = 'Y'  then '%JC RevAdj%'  end) and --when source is JC
         (m.ContractStatus = case when @option = 'O' then 1 end or --Open
   
         m.ContractStatus = case when @option = 'C' then  2 end or --Closed
         m.ContractStatus = case when @option = 'C' then 3 end or --Closed
         m.ContractStatus = case when @option = 'B' then 1 end or --Both
         m.ContractStatus = case when @option = 'B' then 2 end or --Both
         m.ContractStatus = case when @option = 'B' then 3 end) --Both
         and d.JCTransType <> 'RU' 
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
                 
         if (select @summarylevel) = 'S'--By Month/Source level
              begin
              insert bJCID
              (JCCo,Mth,ItemTrans,Contract,Item,JCTransType,TransSource,Description,PostedDate,ActualDate,ContractAmt,
   
              ContractUnits,UnitPrice,BilledUnits,BilledAmt,ReceivedAmt,CurrentRetainAmt,ReversalStatus)
              
              select @JCCo,@Mth,@CostTrans,@Contract,@ContractItem,'RU',@Source,'Roll Up',GetDate(),GetDate(),
              isnull(sum(d.ContractAmt),0),isnull(sum(d.ContractUnits),0),isnull(sum(d.UnitPrice),0),isnull(sum(d.BilledUnits),0),
              isnull(sum(d.BilledAmt),0),isnull(sum(d.ReceivedAmt),0),isnull(sum(d.CurrentRetainAmt),0),0 
              from bJCID d
              where d.JCCo = @JCCo and d.Mth = @Mth and d.Contract = @Contract and d.Item = @ContractItem
              and TransSource = @Source and d.JCTransType not in ('OC','CO','RU')
              end
         
         
         --delete all but rolled-up entries in JCID
         delete bJCID  where JCCo = @JCCo and Mth = @Mth and Contract = @Contract and Item = @ContractItem 
         and isnull(TransSource,'') = case when @summarylevel = 'S'  then @Source else isnull(TransSource,'') end
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
      select @errmsg = @errmsg + ' [bspJCCDRollup]'
      end
     
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCDRollup] TO [public]
GO
