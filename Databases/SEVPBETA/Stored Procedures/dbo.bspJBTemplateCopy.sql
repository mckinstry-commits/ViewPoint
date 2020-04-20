SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspJBTemplateCopy]
   
   /***********************************************************
   * CREATED BY :     bc  08/02/00
   * MODIFIED By :    bc  09/11/00 - added cost types
   *		kb 6/24/2 - issue #16848 - need to add EarnLiabOpt to JBTC insert
   *		kb 7/2/2 - issue #17802 - added to lookup up phasegroup
   *		kb 7/22/2 - issue #18040 allow insert if copying template
   *		TJL 10/22/03 - Issue #22764, Add NoLocks and Use proper Customer Group		
   *		TJL 01/10/05 - Issue #17896, Add EffectiveDate to JBTM and NewRate/NewSpecificPrice to JBLR, JBLO, JBER, JBMO
   *
   *
   **********************************************************/
   (@source_co bCompany, @source_temp varchar(10), @dest_co bCompany, @dest_temp varchar(10), @desc varchar(128),
    @chkCostTypes bYN, @chkAddons bYN, @chkLbrRates bYN, @chkEquipRates bYN, @chkMatlRates bYN,
    @errmsg varchar(255) output)
   
   as
   
   set nocount on
   declare @rcode int, @cnt int, @phasegroup bGroup, @arco bCompany, @custgroup bGroup
   select @rcode = 0, @cnt = 0
   
   if @source_co is null
   	begin
   	select @errmsg = 'Missing Source Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @source_temp is null
   	begin
   	select @errmsg = 'Missing Source Template!', @rcode = 1
   	goto bspexit
   	end
   
   if @dest_co is null
   	begin
   	select @errmsg = 'Missing Destination Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @dest_temp is null
   	begin
   	select @errmsg = 'Missing Destination Template!', @rcode = 1
   	goto bspexit
   	end
   
   if not exists(select 1 from bJBTM with (nolock) where JBCo = @source_co and Template = @source_temp)
   	begin
   	select @errmsg = 'Invalid Source Template!', @rcode = 1
   	goto bspexit
   	end
   
   if exists(select 1 from bJBTM with (nolock) where JBCo = @dest_co and Template = @dest_temp)
   	begin
   	select @errmsg = 'Destination Template already exists!', @rcode = 1
   	goto bspexit
   	end
   
   select @arco = j.ARCo, @custgroup = h.CustGroup
   from bJCCO j with (nolock)
   join bHQCO h with (nolock) on h.HQCo = j.ARCo
   where j.JCCo = @dest_co
   
   select @phasegroup = PhaseGroup 
   from bHQCO with (nolock)
   where HQCo = @dest_co
   
   begin transaction
   
   insert into bJBTM (JBCo,Template,Description,SortOrder,LaborRateOpt,LaborOverrideYN,EquipRateOpt,
     	LaborCatYN,EquipCatYN,MatlCatYN,Notes, CopyInProgress, LaborEffectiveDate, EquipEffectiveDate, MatlEffectiveDate)
   select @dest_co,@dest_temp,@desc,SortOrder,LaborRateOpt,LaborOverrideYN,EquipRateOpt,
     	LaborCatYN,EquipCatYN,MatlCatYN,Notes,'Y',
   	Case @chkLbrRates when 'Y' then LaborEffectiveDate else null end,
   	Case @chkEquipRates when 'Y' then EquipEffectiveDate else null end,
   	Case @chkMatlRates when 'Y' then MatlEffectiveDate else null end
   from bJBTM with (nolock)
   where JBCo = @source_co and Template = @source_temp
   
   if @@rowcount = 0
   	begin
     	select @errmsg = 'Error copying record into JBTM.', @rcode = 1
     	goto error
     	end
   
   /**** Template Sequences ****/
   select @cnt = count(*)
   from bJBTS with (nolock)
   where JBCo = @source_co and Template = @source_temp
   
   insert into bJBTS (JBCo,Template,Seq,Type,GroupNum,Description,APYN,EMYN,INYN,JCYN,MSYN,PRYN,
     Category,SummaryOpt,SortLevel,EarnLiabTypeOpt,LiabilityType,EarnType,CustGroup,MiscDistCode,
     PriceOpt,MarkupOpt,MarkupRate,FlatAmtOpt,AddonAmt,Notes)
   select @dest_co,@dest_temp,Seq,Type,GroupNum,Description,APYN,EMYN,INYN,JCYN,MSYN,PRYN,
     Category,SummaryOpt,SortLevel,EarnLiabTypeOpt,LiabilityType,EarnType,@custgroup,MiscDistCode,
     PriceOpt,MarkupOpt,MarkupRate,FlatAmtOpt,AddonAmt,Notes
   from bJBTS with (nolock)
   where JBCo = @source_co and Template = @source_temp and @cnt <> 0
   
   if @cnt <> @@rowcount
     	begin
     	select @errmsg = 'Error copying record(s) into JBTS.', @rcode = 1
     	goto error
     	end
   
   /**** CostTypes ****/
   select @cnt = count(*)
   from bJBTC with (nolock)
   where JBCo = @source_co and Template = @source_temp
   
   insert into bJBTC (JBCo, Template, Seq, PhaseGroup, CostType, APYN, EMYN, INYN, JCYN, MSYN, PRYN, 
     Category, LiabilityType, EarnType,EarnLiabTypeOpt)
   select @dest_co, @dest_temp, Seq, @phasegroup, CostType, APYN, EMYN, INYN, JCYN, MSYN, PRYN, 
     Category, LiabilityType, EarnType,EarnLiabTypeOpt
   from bJBTC with (nolock)
   where JBCo = @source_co and Template = @source_temp and @chkCostTypes = 'Y' and @cnt <> 0
   
   if @chkCostTypes = 'Y' and @cnt <> @@rowcount
     	begin
     	select @errmsg = 'Error copying record(s) into JBTC.', @rcode = 1
     	goto error
     	end
   
   /**** Addons ****/
   /* becase the JBTS insert trigger potentially inserts JBTA records logically,
      delete any records here to make sure the new template is an exact replica */
   if exists (select 1 from bJBTA with (nolock) where JBCo = @dest_co and Template = @dest_temp)
     	begin
     	delete bJBTA
     	where JBCo = @dest_co and Template = @dest_temp
     	end
   
   select @cnt = count(*)
   from bJBTA with (nolock)
   where JBCo = @source_co and Template = @source_temp
   
   insert into bJBTA(JBCo,Template,Seq,AddonSeq)
   select @dest_co,@dest_temp,Seq,AddonSeq
   from bJBTA with (nolock)
   where JBCo = @source_co and Template = @source_temp and @chkAddons = 'Y' and @cnt <> 0
   
   if @chkAddons = 'Y' and @cnt <> @@rowcount
     	begin
     	select @errmsg = 'Error copying record(s) into JBTA.', @rcode = 1
     	goto error
     	end
   
   /**** Labor Rates & Labor Rate Overrides ****/
   select @cnt = count(*)
   from bJBLR with (nolock)
   where JBCo = @source_co and Template = @source_temp
   
   insert into bJBLR (JBCo,Template,LaborCategory,Seq,RestrictByEarn,EarnType,RestrictByFactor,Factor,
          RestrictByShift,Shift,RateOpt,Rate,Notes,NewRate)
   select @dest_co,@dest_temp,LaborCategory,Seq,RestrictByEarn,EarnType,RestrictByFactor,Factor,
          RestrictByShift,Shift,RateOpt,Rate,Notes,NewRate
   from bJBLR with (nolock)
   where JBCo = @source_co and Template = @source_temp and @chkLbrRates = 'Y' and @cnt <> 0
   
   if @chkLbrRates = 'Y' and @cnt <> @@rowcount
     	begin
     	select @errmsg = 'Error copying record(s) into JBLR.', @rcode = 1
     	goto error
     	end
   
   select @cnt = count(*)
   from bJBLO with (nolock)
   where JBCo = @source_co and Template = @source_temp
   
   insert into bJBLO (JBCo,Template,LaborCategory,Seq,RestrictByEmployee,PRCo,Employee,RestrictByCraft,Craft,
                     RestrictByClass,Class,RestrictByEarn,EarnType,RestrictByFactor,Factor,RestrictByShift,Shift,
                     RateOpt,Rate,Notes,NewRate)
   select @dest_co,@dest_temp,LaborCategory,Seq,RestrictByEmployee,PRCo,Employee,RestrictByCraft,Craft,
          RestrictByClass,Class,RestrictByEarn,EarnType,RestrictByFactor,Factor,RestrictByShift,Shift,
          RateOpt,Rate,Notes,NewRate
   from bJBLO with (nolock)
   where JBCo = @source_co and Template = @source_temp and @chkLbrRates = 'Y' and @cnt <> 0
   
   if @chkLbrRates = 'Y' and @cnt <> @@rowcount
     	begin
     	select @errmsg = 'Error copying record(s) into JBLO.', @rcode = 1
     	goto error
     	end
   
   /**** Equipment Rates ****/
   select @cnt = count(*)
   from bJBER with (nolock)
   where JBCo = @source_co and Template = @source_temp
   
   insert into bJBER (JBCo,Template,EMCo,EquipCategory,Seq,RestrictByEquip,Equipment,
          RestrictByRevCode,EMGroup,RevCode,RateOpt,Rate,Notes,NewRate)
   select @dest_co,@dest_temp,EMCo,EquipCategory,Seq,RestrictByEquip,Equipment,
          RestrictByRevCode,EMGroup,RevCode,RateOpt,Rate,Notes,NewRate
   from bJBER with (nolock)
   where JBCo = @source_co and Template = @source_temp and @chkEquipRates = 'Y' and @cnt <> 0
   
   if @chkEquipRates = 'Y' and @cnt <> @@rowcount
     	begin
     	select @errmsg = 'Error copying record(s) into JBER.', @rcode = 1
     	goto error
     	end
   
   /**** Marerial Rates ****/
   select @cnt = count(*)
   from bJBMO with (nolock)
   where JBCo = @source_co and Template = @source_temp
   
   insert into bJBMO (JBCo,Template,MatlGroup,Material,OverrideOpt,Rate,SpecificPrice,CostOpt,Notes,NewSpecificPrice)
   select @dest_co,@dest_temp,MatlGroup,Material,OverrideOpt,Rate,SpecificPrice,CostOpt,Notes,NewSpecificPrice
   from bJBMO with (nolock)
   where JBCo = @source_co and Template = @source_temp and @chkMatlRates = 'Y' and @cnt <> 0
   
   if @chkMatlRates = 'Y' and @cnt <> @@rowcount
     	begin
     	select @errmsg = 'Error copying record(s) into JBMO.', @rcode = 1
     	goto error
     	end
   
   update bJBTM 
   set CopyInProgress = 'N' 
   from bJBTM with (nolock) 
   where JBCo = @dest_co and Template = @dest_temp
   
   commit transaction
   goto bspexit
   
   error:
       rollback transaction
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTemplateCopy] TO [public]
GO
