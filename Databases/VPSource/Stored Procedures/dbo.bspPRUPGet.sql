SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspPRUPGet    Script Date: 8/28/99 9:35:39 AM ******/    
    CREATE        procedure [dbo].[bspPRUPGet]
/***********************************************************
* CREATED BY:	EN 11/09/06
* MODIFIED BY:	EN 3/6/07 Added @job1, @phase1, @revcode1, @equip2, @costcode2, AND assorted skip fields
*							to the return parameters list
*				EN 8/3/07 Added @employee1 and @employee2 to the return parameters list
*				CHS	11/16/2010	- 141179
*				MH 01/21/11 - 131640/141827 Modified for Service Mgmt
*               ECV 09/13/11 - TK-08101 Added SkipSMCostType3 and SMCostType3
*				MH 02/07/12 - TK-12390 Added SMJCCostType3 and SkipSMCostType3
*
* USAGE:
* Get PRUP cusomize grid data for specified user ... if data not available default all fields to Show (1).
*
*  INPUT PARAMETERS
*   @prco - company
*   @user - user name
*
* OUTPUT PARAMETERS
*	 PRUP values for all fields
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
    (@prco bCompany = null, 
	@user bVPUserName, 
	@payseq1 tinyint output, 
	@prdept1 tinyint output, 
	@crew1 tinyint output, 
	@jcco1 tinyint output,
	@job1 tinyint output, 
	@phase1 tinyint output,
	@insstate1 tinyint output, 
	@taxstate1 tinyint output, 
	@local1 tinyint output, 
	@unempstate1 tinyint output,
    @inscode1 tinyint output, 
	@glco tinyint output, 
	@emco1 tinyint output, 
	@equip tinyint output, 
	@craft1 tinyint output,
   	@class1 tinyint output, 
	@shift1 tinyint output, 
	@rate1 tinyint output, 
	@amt1 tinyint output,
   	@equipphase1 tinyint output, 
	@costtype1 tinyint output, 
	@revcode1 tinyint output,
	@memo1 tinyint output,
   	@cert1 tinyint output, 
	@payseq2 tinyint output, 
	@prdept2 tinyint output, 
	@crew2 tinyint output,
    @emco3 tinyint output, 
	@wo tinyint output, 
	@woitem tinyint output, 
	@comptype tinyint output,
    @comp tinyint output, 
	@insstate2 tinyint output, 
	@taxstate2 tinyint output, 
	@local2 tinyint output,
   	@unempstate2 tinyint output, 
	@craft2 tinyint output, 
	@inscode2 tinyint output, 
	@class2 tinyint output,
   	@shift2 tinyint output, 
	@rate2 tinyint output, 
	@amt2 tinyint output, 
	@cert2 tinyint output,
   	@jcco2 tinyint output, 
	@job tinyint output, 
	@memo2 tinyint output, 
	@equip2 tinyint output,
	@costcode2 tinyint output,
	@skippayseq1 bYN output, 
	@skipprdept1 bYN output, 
	@skipcrew1 bYN output, 
	@skipjcco1 bYN output,
	@skipinsstate1 bYN output, 
	@skiptaxstate1 bYN output, 
	@skiplocal1 bYN output,
	@skipunempstate1 bYN output, 
	@skipinscode1 bYN output, 
	@skipglco1 bYN output, 
	@skipemco1 bYN output,
	@skipequip1 bYN output, 
	@skipcraft1 bYN output, 
	@skipclass1 bYN output, 
	@skipshift1 bYN output,
	@skiprate1 bYN output, 
	@skipamt1 bYN output, 
	@skipequipphase1 bYN output, 
	@skipcosttype1 bYN output,
	@skiprevcode1 bYN output, 
	@skipcert1 bYN output, 
	@skipmemo1 bYN output,
	@skippayseq2 bYN output, 
	@skipprdept2 bYN output, 
	@skipcrew2 bYN output, 
	@skipjcco2 bYN output,
	@skipjob2 bYN output, 
	@skipinsstate2 bYN output, 
	@skiptaxstate2 bYN output,
	@skiplocal2 bYN output, 
	@skipunempstate2 bYN output, 
	@skipinscode2 bYN output,
	@skipwo2 bYN output, 
	@skipwoitem2 bYN output, 
	@skipemco2 bYN output, 
	@skipcomptype2 bYN output, 
	@skipcomp2 bYN output, 
	@skipcraft2 bYN output,
	@skipclass2 bYN output, 
	@skipshift2 bYN output, 
	@skiprate2 bYN output, 
	@skipamt2 bYN output,
	@skipcert2 bYN output, 
	@skipmemo2 bYN output,
	@employee1 tinyint output, 
	@employee2 tinyint output, 
	@type1 tinyint output,
	@skiptype1 bYN output,
	@type2 tinyint output,
	@skiptype2 bYN output,
	
	--Service
	@employee3 tinyint output,
	@type3 tinyint output,
	@skiptype3 bYN output,
	@payseq3 tinyint output,
	@skippayseq3 bYN output,
	@prdept3 tinyint output,	
	@skipprdept3 bYN output,
	@crew3 tinyint output,
	@skipcrew3 bYN output,
	@jcco3 tinyint output,
	@job3 tinyint output,
	@phase3 tinyint output,
	@insstate3 tinyint output,
	@skipinsstate3 bYN output,
	@taxstate3 tinyint output,
	@skiptaxstate3 bYN output,
	@local3 tinyint output,
	@skiplocal3 bYN output,
	@unempstate3 tinyint output,	
	@skipunempstate3 bYN output,
	@inscode3 tinyint output,
	@skipinscode3 bYN output,
	@craft3 tinyint output,
	@skipcraft3 bYN output,
	@emco4 tinyint output,
	@skipemco4 bYN output,
	@glco3 tinyint output,
	@skipglco3 bYN output,
	@equip3 tinyint output,
	@skipequip3 bYN output,
	@class3 tinyint output,
	@skipclass3 bYN output,
	@shift3 tinyint output,
	@skipshift bYN output,
	@rate3 tinyint output,
	@skiprate bYN output,
	@amt3 tinyint output,
	@skipamt3 bYN output,
	@equipphase3 tinyint output,
	@skipequipphase3 bYN output,
	@costtype3 tinyint output,
	@skipcosttype3 bYN output,
	@revcode3 tinyint output,
	@skiprevcode3 bYN output,
	@cert3 tinyint output,
	@skipcert3 bYN output,
	@smco3 tinyint output,
	@skipsmco3 bYN output,
	@smwo3 tinyint output,
	@smscope3 tinyint output,
	@smpaytype3 tinyint output,
	@smcosttype3 tinyint output,
	@memo3 tinyint output,
	@skipmemo3 bYN output,
	@skipsmcosttype3 bYN output,
	@smjccosttype3 tinyint output,
	@skipsmjccosttype3 bYN output,
	@msg varchar(60) output)
    as
    set nocount on
    
    declare @rcode int
    
    select @rcode = 0
    
    select @employee1=Employee1, @payseq1=PaySeq1, @prdept1=PRDept1, @crew1=Crew1, @jcco1=JCCo1, @job1=Job1, 
	 @phase1=Phase1, @glco=GLCo, @insstate1=InsState1,
   	 @taxstate1=TaxState1, @local1=Local1, @unempstate1=UnempState1, @inscode1=InsCode1, @emco1=EMCo1, 
   	 @equip=Equip, @craft1=Craft1, @class1=Class1, @shift1=Shift1, @rate1=Rate1, @amt1=Amt1,
   	 @equipphase1=EquipPhase1, @costtype1=CostType1, @revcode1=RevCode1, @memo1=Memo1, 
	 @cert1=Cert1, @employee2=Employee2, @payseq2=PaySeq2,
   	 @prdept2=PRDept2, @crew2=Crew2, @emco3=EMCo3, @wo=WO, @woitem=WOItem, @comptype=CompType, 
   	 @comp=Comp, @insstate2=InsState2, @taxstate2=TaxState2, @local2=Local2, @unempstate2=UnempState2,
   	 @craft2=Craft2, @inscode2=InsCode2, @class2=Class2, @shift2=Shift2, @rate2=Rate2, @amt2=Amt2,
   	 @cert2=Cert2, @jcco2=JCCo2, @job=Job, @memo2=Memo2, @equip2=Equip2, @costcode2=CostCode2,
	 @skippayseq1=SkipPaySeq1, @skipprdept1=SkipPRDept1, @skipcrew1=SkipCrew1, @skipjcco1=SkipJCCo1,
	 @skipinsstate1=SkipInsState1, @skiptaxstate1=SkipTaxState1, @skiplocal1=SkipLocal1,
	 @skipunempstate1=SkipUnempState1, @skipinscode1=SkipInsCode1, @skipglco1=SkipGLCo1, @skipemco1=SkipEMCo1,
	 @skipequip1=SkipEquip1, @skipcraft1=SkipCraft1, @skipclass1=SkipClass1, @skipshift1=SkipShift1,
	 @skiprate1=SkipRate1, @skipamt1=SkipAmt1, @skipequipphase1=SkipEquipPhase1, @skipcosttype1=SkipCostType1,
	 @skiprevcode1=SkipRevCode1, @skipcert1=SkipCert1, @skipmemo1=SkipMemo1,
	 @skippayseq2=SkipPaySeq2, @skipprdept2=SkipPRDept2, @skipcrew2=SkipCrew2, @skipjcco2=SkipJCCo2,
	 @skipjob2=SkipJob2, @skipinsstate2=SkipInsState2, @skiptaxstate2=SkipTaxState2,
	 @skiplocal2=SkipLocal2, @skipunempstate2=SkipUnempState2, @skipinscode2=SkipInsCode2,
	 @skipwo2=SkipWO2, @skipwoitem2=SkipWOItem2, @skipemco2=SkipEMCo2, 
	 @skipcomptype2=SkipCompType2, @skipcomp2=SkipComp2, @skipcraft2=SkipCraft2,
	 @skipclass2=SkipClass2, @skipshift2=SkipShift2, @skiprate2=SkipRate2, @skipamt2=SkipAmt2,
	 @skipcert2=SkipCert2, @skipmemo2=SkipMemo2, @type1=Type1, @skiptype1=SkipType1, @type2=Type2, @skiptype2=SkipType2,
	 --Service
	 @employee3 = Employee3, @type3 = Type3, @skiptype3 = SkipType3, @payseq3 = PaySeq3, @skippayseq3 = SkipPaySeq3,
	 @prdept3 = PRDept3, @skipprdept3 = SkipPRDept3, @crew3 = Crew3, @skipcrew3 = SkipCrew3, @jcco3 = JCCo3,
	 @job3 = Job3, @phase3 = Phase3, @insstate3 = InsState3, @skipinsstate3 = SkipInsState3, @taxstate3 = TaxState3,
	 @skiptaxstate3 = SkipTaxState3, @local3 = Local3, @skiplocal3 = SkipLocal3, @unempstate3 = UnempState3,
	 @skipunempstate3 = SkipUnempState3, @inscode3 = InsCode3, @skipinscode3 = SkipInsCode3, @craft3 = Craft3,
	 @skipcraft3 = SkipCraft3, @emco4 = EMCo4, @skipemco4 = SkipEMCo4, @glco3 = GLCo3, @skipglco3 = SkipGLCo3,
	 @equip3 = Equip3, @skipequip3 = SkipEquip3, @class3 = Class3, @skipclass3 = SkipClass3, @shift3 = Shift3,
	 @skipshift = SkipShift3, @rate3 = Rate3, @skiprate = SkipRate3, @amt3 = Amt3, @skipamt3 = SkipAmt3,
	 @equipphase3 = EquipPhase3, @skipequipphase3 = SkipEquipPhase3, @costtype3 = CostType3, @skipcosttype3 = SkipCostType3,
	 @revcode3 = RevCode3, @skiprevcode3 = SkipRevCode3, @cert3 = Cert3, @skipcert3 = SkipCert3, @smco3 = SMCo3,
	 @skipsmco3 = SkipSMCo3, @smwo3 = SMWo3, @smscope3 = SMScope3, @smpaytype3 = SMPayType3, @smcosttype3 = SMCostType3, @memo3 = Memo3,
	 @skipmemo3 = SkipMemo3, @skipsmcosttype3 = SkipSMCostType3, @smjccosttype3 = SMJCCostType3, @skipsmjccosttype3 = SkipSMJCCostType3
	
    from PRUP where PRCo = @prco and UserName = @user
    
    if @@rowcount = 0
		begin
        select @employee1=2, @payseq1=2, @prdept1=3, @crew1=3, @jcco1=2, @job1=2, @phase1=2, @glco=2, @insstate1=2, @taxstate1=2,
			@local1=3, @unempstate1=2, @inscode1=3, @emco1=2, @equip=3,
			@craft1=3, @class1=3, @shift1=2, @rate1=2, @amt1=2, 
			@equipphase1=3, @costtype1=3, @revcode1=3, @memo1=2, @cert1=2, @employee2=2,
			@payseq2=2, @prdept2=3, @crew2=3, @emco3=2, @wo=3, @woitem=3, @comptype=3,
			@comp=3, @insstate2=2, @taxstate2=2, @local2=3, @unempstate2=2, @craft2=3, @inscode2=3,
			@class2=3, @shift2=2, @rate2=2, @amt2=2, @cert2=2, @jcco2=2, @job=3, @memo2=2, @equip2=2, @costcode2=2,
			@type1=2, @type2=2,
		    @skippayseq1='N', @skipprdept1='N', @skipcrew1='N', @skipjcco1='N',
		    @skipinsstate1='N', @skiptaxstate1='N', @skiplocal1='N',
		    @skipunempstate1='N', @skipinscode1='N', @skipglco1='N', @skipemco1='N',
		    @skipequip1='N', @skipcraft1='N', @skipclass1='N', @skipshift1='N',
		    @skiprate1='N', @skipamt1='N', @skipequipphase1='N', @skipcosttype1='N',
		    @skiprevcode1='N', @skipcert1='N', @skipmemo1='N',
		    @skippayseq2='N', @skipprdept2='N', @skipcrew2='N', @skipjcco2='N',
		    @skipjob2='N', @skipinsstate2='N', @skiptaxstate2='N',
		    @skiplocal2='N', @skipunempstate2='N', @skipinscode2='N',
		    @skipwo2='N', @skipwoitem2='N', @skipemco2='N', 
		    @skipcomptype2='N', @skipcomp2='N', @skipcraft2='N',
		    @skipclass2='N', @skipshift2='N', @skiprate2='N', @skipamt2='N',
		    @skipcert2='N', @skipmemo2='N', @skiptype1='N', @skiptype2='N',
		    --Service
	    	@type3 = 2, @payseq3 = 2, @insstate3 = 2, @taxstate3 = 2, @unempstate3 = 2, 
	    	@shift3 = 2, @rate3 = 2, @amt3 = 2, @smco3 = 2,@cert3 = 2, @memo3 = 2,
	    	@prdept3 = 3, @local3 = 3, @inscode3 = 3,
	    	@employee3 = 0, @smwo3 = 0,  @smscope3 = 0, @smpaytype3 = 0, @smcosttype3 = 0,
	    	@jcco3 = 0, @job3 = 0, @glco3 = 2, @emco4 = 0, @phase3 = 0, @crew3 = 0,
	    	@equip3 = 0, @craft3 = 3, @class3 = 3, @equipphase3 = 0, @costtype3 = 0, 
	    	@revcode3 = 0, @smjccosttype3 = 0,
			@skiptype3 = 'N', @skippayseq3 = 'N',@skipprdept3 = 'N', @skipcrew3 = 'N', 
			@skipinsstate3 = 'N', @skiptaxstate3 = 'N', @skiplocal3 = 'N', @skipunempstate3 = 'N', 
			@skipinscode3 = 'N', @skipcraft3 = 'N', @skipemco4 = 'N', @skipglco3 = 'N',
			@skipequip3 = 'N', @skipclass3 = 'N', @skipshift = 'N', @skiprate = 'N', 
			@skipamt3 = 'N', @skipequipphase3 = 'N', @skipcosttype3 = 'N', @skiprevcode3 = 'N',  
			@skipcert3 = 'N', @skipsmco3 = 'N', @skipmemo3 = 'N', @skipsmcosttype3 = 'N',
			@skipsmjccosttype3 = 'N'
        end
    
    
    bspexit:
    	return @rcode







GO
GRANT EXECUTE ON  [dbo].[bspPRUPGet] TO [public]
GO
