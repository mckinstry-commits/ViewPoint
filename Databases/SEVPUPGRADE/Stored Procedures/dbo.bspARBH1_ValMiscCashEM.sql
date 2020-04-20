SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH1_ValMiscCashEM    Script Date: 8/10/01 7:36:00 AM ******/
   CREATE procedure [dbo].[bspARBH1_ValMiscCashEM]
   /*********************************************
    * Created: 	TJL  08/10/01
    * Modified: TJL  11/07/01  Added EM CostCode, EM Cost Type validation to match that of bARTL triggers
	*			AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
    *          
    *
    * Usage:
    *  Called from the AR Transaction Batch validation procedure (bspARBHVal_Cash)
    *  to validate Equipment information and Insert into Equip Dist Table bARBE.
    *
    * Input:
    *  @ARCo      	ARCo#
    *  @Mth      	BatchMth
    *  @batchid    	BatchId
    *  @batchseq   	BatchSeq
    *
    * Output:
    *  @msg        Error message
    *
    * Return:
    *  0           success
    *  1           error
    *************************************************/
   
   @ARCo bCompany, @Mth bMonth, @batchid bBatchID, @batchseq int, @msg varchar(255) output
   as
   
   set nocount on
   
   /* Declare Misc variables */
	DECLARE @errortext varchar(255),
			@errorstart varchar(50),
			@errdetail varchar(60),
			@PostAmount bDollar,
			@oldPostAmount bDollar,
			@i tinyint,
			@OldNew tinyint,
			@TaxCostCode bCostCode,
			@TaxCostType bEMCType,
			@SeperateTax bYN,
			@PostTax bDollar,
			@FirstProcess int,
			@LastProcess int,
			@PostToClosedJobs char(1),
			@JobStatus tinyint,
			@TaxGLAcct bGLAcct,
			@CostTypeAbbrev varchar(3),
			@TaxCostTypeAbbrev varchar(3)
   
   /* Declare AR Header variables */
	DECLARE @TransType char(1),
			@ARTrans bTrans,
			@ARTransType char(1),
			@Source bSource,
			@CheckNo char(10),
			@TransDesc bDesc,
			@TransDate bDate,
			@ActDate bDate,
			@oldCheckNo char(10),
			@oldTransDesc bDesc,
			@oldTransDate bDate
   
	/* Declare AR Line variables */
	DECLARE @Co bCompany,
			@ARLine smallint,
			@TransTypeLine char,
			@LineType char,
			@LineDesc bDesc,
			@GLCo bCompany,
			@GLAcct bGLAcct,
			@TaxGroup bGroup,
			@TaxCode bTaxCode,
			@Amount bDollar,
			@TaxBasis bDollar,
			@TaxAmount bDollar,
			@RetgPct bPct,
			@Retainage bDollar,
			@emco bCompany,
			@equip bEquip,
			@emgroup bGroup,
			@emcostcode bCostCode,
			@emctype bEMCType,
			@comptype varchar(10),
			@component bEquip,
			@UM bUM,
			@emum bUM,
			@units bUnits,
			@emunits bUnits,
			@hours bHrs,
			-- old values
			@oldLineType char,
			@oldLineDesc bDesc,
			@oldGLCo bCompany,
			@oldGLAcct bGLAcct,
			@oldTaxGroup bGroup,
			@oldTaxCode bTaxCode,
			@oldAmount bDollar,
			@oldTaxBasis bDollar,
			@oldTaxAmount bDollar,
			@oldRetgPct bPct,
			@oldRetainage bDollar,
			@oldemco bCompany,
			@oldequip bEquip,
			@oldemgroup bGroup,
			@oldemcostcode bCostCode,
			@oldemctype bEMCType,
			@oldcomptype varchar(10),
			@oldcomponent bEquip,
			@oldUM bUM,
			@oldunits bUnits,
			@oldhours bHrs

	DECLARE @rcode int
	DECLARE @type char(1),
			@equipstatus char(1),
			@compofequip bEquip,
			@emcomptype varchar(10)
   
   select @rcode = 0, @emunits = 0
   
   -- Get values from header bARBH
   select @TransType=TransType, @ARTrans=ARTrans, @CheckNo=CheckNo, @Source=Source, @ARTransType=ARTransType,
   	@TransDate=TransDate, @oldTransDate=oldTransDate, @TransDesc = Description
   from bARBH 
   where Co=@ARCo and Mth=@Mth and BatchId=@batchid and BatchSeq = @batchseq
   
   /***************************************/
   /* AR Line Batch loop for validation   */
   /***************************************/
   
   select @ARLine=Min(ARLine) 
   from bARBL
   where Co=@ARCo and Mth=@Mth and BatchId=@batchid and BatchSeq=@batchseq
         	and (Equipment is not null or oldEquipment is not null)
   
   --- get next record
   while @ARLine is not null
   Begin
   	-- Most fields except those directly related to EM are common to other LineTypes 'O' and 'J'
   select  @TransTypeLine= TransType, @ARTrans=ARTrans,
   	@LineType=LineType, @LineDesc= Description,@GLCo=GLCo,@GLAcct=GLAcct,@TaxGroup=TaxGroup,
   	@TaxCode= TaxCode,@Amount=IsNull(-Amount,0), @TaxBasis = IsNull(-TaxBasis,0), @TaxAmount=IsNull(-TaxAmount,0),
   	-- EM only fields/values
   	@emco = EMCo, @equip = Equipment, @emgroup = EMGroup, @emcostcode = CostCode, @emctype = EMCType,
       	@comptype = CompType, @component = Component,
   	-- More common/shared fields
   	@UM= UM, @units = IsNull(-JobUnits,0), @hours = IsNull(-JobHours,0),  
   	--- old values
   	@oldLineType=oldLineType, @oldLineDesc = oldDescription,@oldGLCo=oldGLCo,@oldGLAcct=oldGLAcct,@oldTaxGroup=oldTaxGroup,
   	@oldTaxCode= oldTaxCode, @oldAmount=IsNull(oldAmount,0),@oldTaxAmount=IsNull(oldTaxAmount,0),
   	@oldemco = oldEMCo, @oldequip = oldEquipment, @oldemgroup = oldEMGroup, @oldemcostcode = oldCostCode, @oldemctype = oldEMCType,
       	@oldcomptype = oldCompType, @oldcomponent = oldComponent,
   	@oldUM=oldUM, @oldunits=IsNull(oldJobUnits,0),	@oldhours=IsNull(oldJobHours,0)
   
   from bARBL
   where Co = @ARCo and Mth = @Mth and BatchId=@batchid and BatchSeq=@batchseq and ARLine=@ARLine
   	and (Equipment is not null or oldEquipment is not null)
   
   select @errorstart = 'Seq ' + convert (varchar(6),@batchseq) + ' Line ' + convert(varchar(6),@ARLine)+ ' '
   
   /* loop for once for new transaction (0) and then for old (1) (not to be confused with the OldNew amount which is the opposite) */
   /* if add then loop while 0 thru 0, if delete then loop 1 thru 1, if change then loop 0 thru 1 */
   select @FirstProcess=case when @TransTypeLine='D' then 1 else 0 end,
          	@LastProcess=case when @TransTypeLine='A' then 0 else 1 end
   
   select @i=@FirstProcess
   while @i<=@LastProcess
       begin
       select @OldNew = 1
       if @i = 1
       	select @LineType=@oldLineType, @LineDesc= @oldLineDesc,@TaxGroup=@oldTaxGroup, @OldNew = 0,
   		@TaxCode= @oldTaxCode, @Amount=IsNull(@oldAmount,0),@TaxAmount=IsNull(@oldTaxAmount,0),
   		@emco = @oldemco, @equip = @oldequip, @emgroup = @oldemgroup, @emcostcode = @oldemcostcode, 
   		@emctype = @oldemctype, @comptype = @oldcomptype, @component = @oldcomponent,
   		@UM=@oldUM, @units=IsNull(@oldunits,0),@hours=IsNull(@oldhours,0),
   		@GLCo=@oldGLCo, @GLAcct=@oldGLAcct
   
       /* if this is not a line type then skip over posting to EM */
       if @LineType <> 'E' goto EMWhileLoop 
   
       /* Begin Validation of EM related fields */
       if not exists(select * from bEMCO where EMCo = @emco)
       	begin
           	select @errortext = @errorstart + ' - EMCo:' + isnull(convert(varchar(3),@emco),'') +': is invalid'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
       	end
   
       -- validate Equipment
       select @type = Type, @equipstatus = Status
       from bEMEM
       where EMCo = @emco and Equipment = @equip
       if @@rowcount = 0
       	begin
           	select @errortext = @errorstart + ' - Equipment:' + isnull(@equip,'') +': is invalid'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
       	end
   
       if @type <> 'E'
       	begin
           	select @errortext = @errorstart + ' - Equipment:' + isnull(@equip,'') +': must be type E!'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
       	end
   
       if @equipstatus = 'I'
       	begin
           	select @errortext = @errorstart + ' - Equipment:' + isnull(@equip,'') +': is Inactive!'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
       	end
   
       /*  At the present time, there is no alternative 'CostCode' or 'EMCType' information recorded in HQTX 
           as there is with Job/Phase.  The following has been added/Rem just in case */
   
       /* get the tax CostCode and CType */
       --if @TaxAmount<>0
   	--begin
   	--select @TaxCostCode=CostCode, @TaxCostType=EMCType, @TaxGLAcct=EMGLAcct from bHQTX
   	--where TaxGroup=@TaxGroup and TaxCode=@TaxCode
   	--if @@rowcount=0
   		--begin
           		--select @errortext = @errorstart + ' - TaxCode:' + @TaxCode +': is invalid.'
   	        	--exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
   	       	--if @rcode <> 0 goto bspexit
   	        	--end
   
   	/* if no tax CostCode or EMCType then use the CostCode or EMCType as posted */
   	--select @TaxCostCode=IsNull(@TaxCostCode,@emcostcode), @TaxCostType=IsNull(@TaxCostType,@emctype)
   
   	/* if tax CostCode & EMCType is not same as posted then seperate the tax from the amount */
   	select @SeperateTax = 'N'
   	--select @SeperateTax=case when @TaxCostCode=@emcostcode and @TaxCostType=@emctype then 'N' else 'Y' end
   	--end
   
       /* set the posting amounts credit job expense */
       --select @PostAmount=case @SeperateTax when 'N' then @Amount else (@Amount+@TaxAmount) end,
   	   --@PostTax=case @SeperateTax when 'N' then 0 else @TaxAmount end
       select @PostAmount = @Amount, @PostTax = 0
   
       /* dont post 0 amount */
       if IsNull(@PostAmount,0)=0 and IsNull(@units,0)=0 and IsNull(@hours,0)=0 goto EMTaxRecord
   
       --validate Component Type
       if @comptype is not null
       	begin
       	if not exists (select * from bEMTY where EMGroup = @emgroup and ComponentTypeCode = @comptype)
           		begin
           		select @errortext = @errorstart + ' - Component Type:' + isnull(@comptype,'') +': is invalid!'
           		exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           		if @rcode <> 0 goto bspexit
           		end
      	 end
   
       -- validate Component
       if @component is not null
       begin
       select @compofequip = CompOfEquip, @emcomptype = ComponentTypeCode
       from bEMEM
       where EMCo = @emco and Equipment = @component and Type = 'C'
   
       if @@rowcount = 0
           	begin
           	select @errortext = @errorstart + ' - Component:' + isnull(@component,'') +': is invalid!'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
           	end
   
       if @compofequip <> @equip
           	begin
           	select @errortext = @errorstart + isnull(@component,'') + 'is a component of Equipment: ' + isnull(@compofequip,'')
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
           	end
   
       if isnull(@emcomptype,'') <> isnull(@comptype,'')
           	begin
           	select @errortext = @errorstart + 'Posted Component Type does not match the type assigned to this component.'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
           	end
       end
   
       -- validate Cost Code, Issue #15189
       if not exists(select * from bEMCC where EMGroup = @emgroup and CostCode = @emcostcode)
       	begin
           	select @errortext = @errorstart + ' - EM Cost Code:' + isnull(@emcostcode,'') +': is invalid'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
       	end
   
       -- validate Cost Type,  Issue #15189
       if not exists(select * from bEMCT where EMGroup = @emgroup and CostType = @emctype)
       	begin
           	select @errortext = @errorstart + ' - EM Cost Type:' + isnull(convert(varchar(3),@emctype),'') +': is invalid'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
       	end
   
       -- validate Cost Code and Cost Type Combination - get EM unit of measure,  Issue #15189
       select @emum = UM
       from bEMCH
       where EMCo = @emco and Equipment = @equip and EMGroup = @emgroup
   	and CostCode = @emcostcode and CostType = @emctype
       if @@rowcount = 0
       	begin
       	select @emum = UM
       	from bEMCX
       	where EMGroup = @emgroup and CostCode = @emcostcode and CostType = @emctype
       	if @@rowcount = 0
           		begin
           		select @errortext = @errorstart + 'Cost code: ' + isnull(@emcostcode,'') + ' and Cost Type: ' + isnull(convert(varchar(3),@emctype),'') +
               					' is invalid for Equipment: ' + isnull(@equip,'')
           		exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           		if @rcode <> 0 goto bspexit
           		end
       	end
   
       -- select @UM = @emum */
   
       /* Validate UM */
       exec @rcode=bspHQUMVal @UM, @msg output
       if @rcode<>0
           	begin
           	select @errortext = @errorstart + ' - UM:' + isnull(@UM,'') +': is invalid.'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
           	end
   
       /* insert batch record */
       insert into bARBE(ARCo, Mth, BatchId, EMCo, Equip, EMGroup, CostCode, EMCType, BatchSeq, ARLine, OldNew,
   	ARTrans,TransDesc, TransDate, CompType, Component, MatlGroup, Material, LineDesc, GLCo, GLAcct, UM, Units, UnitCost,
   	ECM, EMUM, EMUnits, TotalCost, TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt)
       values(@ARCo, @Mth, @batchid, @emco, @equip, @emgroup, @emcostcode, @emctype, @batchseq, @ARLine,@OldNew,
   	@ARTrans, @TransDesc, @TransDate, @comptype, @component, null, null, @LineDesc, @GLCo, @GLAcct, null, 0, 0,
   	null, @UM, @units, @PostAmount, @TaxGroup, @TaxCode, null, @TaxBasis, case @SeperateTax when 'Y' then 0 else @TaxAmount end)
       if @@rowcount = 0
   	begin
           	select @errortext = @errorstart + ' Unable to add AR Equipment audit.'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
   	end 
   
   EMTaxRecord:
   
       /* dont post 0 amount */
       if IsNull(@PostTax,0)=0  goto EMWhileLoop /*EMUpdate_End*/
   
       /*  At the present time, there is no alternative 'CostCode' or 'EMCType' information recorded in HQTX 
           as there is with Job/Phase.  The following has been added/Rem just in case */
   
       -- validate Tax Cost Code
       /* Insert validation code here */
   
       -- validate Tax Cost Type
       /* Insert validation code here */
   
       -- validate Tax Cost Code and Tax Cost Type Combination - get EM unit of measure
       /* select @emum = UM
       from bEMCH
       where EMCo = @emco and Equipment = @equip and EMGroup = @emgroup
   	and CostCode = @TaxCostCode and CostType = @TaxCostType
       if @@rowcount = 0
       	begin
       	select @emum = UM
       	from bEMCX
       	where EMGroup = @emgroup and CostCode = @TaxCostCode and CostType = @TaxCostType
       	if @@rowcount = 0
           		begin
           		select @errortext = @errorstart + ' Tax Cost code: ' + @TaxCostCode + ' and Tax Cost Type: ' + convert(varchar(3), @TaxCostType) +
               					' is invalid for Equipment: ' + @equip
           		exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           		if @rcode <> 0 goto bspexit
           		end
       	end
   
       select @UM = @emum  */
   
       /* insert batch record */
       /* insert into bARBE(ARCo, Mth, BatchId, EMCo, Equip, EMGroup, CostCode, EMCType, BatchSeq, ARLine, OldNew,
   	ARTrans,TransDesc, TransDate, CompType, Component, MatlGroup, Material, LineDesc, GLCo, GLAcct, UM, Units, UnitCost,
   	ECM, EMUM, EMUnits, TotalCost, TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt)
       values(@ARCo, @Mth, @batchid, @emco, @equip, @emgroup, @TaxCostCode, @TaxCostType, @batchseq, @ARLine,@OldNew,
   	@ARTrans, @TransDesc, @TransDate, @comptype, @component, null, null, @LineDesc, @GLCo, @TaxGLAcct, null, 0, 0,
   	null, @UM, @units, @PostTax, @TaxGroup, @TaxCode, null, @TaxBasis, @PostTax) 
   
       if @@rowcount = 0
   	begin
           	select @errortext = @errorstart + ' Unable to add AR Equipment audit.'
           	exec @rcode = bspHQBEInsert @ARCo, @Mth, @batchid, @errortext, @msg output
           	if @rcode <> 0 goto bspexit
   	end */
   
   EMWhileLoop:
   
       select @i = @i + 1
       end  -- of @i while loop
   
   EMUpdate_End:
   
   ---- get next line
   select @ARLine=Min(ARLine) 
   from bARBL
   where Co=@ARCo and Mth=@Mth and BatchId=@batchid and BatchSeq=@batchseq and ARLine>@ARLine
   		and (Equipment is not null or oldEquipment is not null)
   
   End
   
   bspexit:
   if @rcode <> 0 select @msg = @msg		--+ char(13) + char(10) + '[bspARBH1_ValMiscCashEM]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARBH1_ValMiscCashEM] TO [public]
GO
