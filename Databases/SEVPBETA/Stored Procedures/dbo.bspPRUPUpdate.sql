SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUPUpdate    Script Date: 8/28/99 9:35:39 AM ******/
    
    CREATE        procedure [dbo].[bspPRUPUpdate]
    /***********************************************************
     * CREATED BY: EN 3/23/07
     * MODIFIED BY:	
     *
     * USAGE:
     * Called by PRTimeCards to update PRUP cusomize grid data for specified user.
     *
     *  INPUT PARAMETERS
     *   @prco - company
     *   @user - user name
	 *	 PRUP values for all fields
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs
     *
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
    (@prco bCompany = null, 
	@user bVPUserName, 
	@payseq1 tinyint, 
	@prdept1 tinyint, 
	@crew1 tinyint, 
	@jcco1 tinyint,
	@job1 tinyint, 
	@phase1 tinyint,
	@insstate1 tinyint, 
	@taxstate1 tinyint, 
	@local1 tinyint, 
	@unempstate1 tinyint,
    @inscode1 tinyint, 
	@glco tinyint, 
	@emco1 tinyint, 
	@equip tinyint, 
	@craft1 tinyint,
   	@class1 tinyint, 
	@shift1 tinyint, 
	@rate1 tinyint, 
	@amt1 tinyint,
   	@equipphase1 tinyint, 
	@costtype1 tinyint, 
	@revcode1 tinyint,
	@memo1 tinyint,
   	@cert1 tinyint, 
	@payseq2 tinyint, 
	@prdept2 tinyint, 
	@crew2 tinyint,
    @emco3 tinyint, 
	@wo tinyint, 
	@woitem tinyint, 
	@comptype tinyint,
    @comp tinyint, 
	@insstate2 tinyint, 
	@taxstate2 tinyint, 
	@local2 tinyint,
   	@unempstate2 tinyint, 
	@craft2 tinyint, 
	@inscode2 tinyint, 
	@class2 tinyint,
   	@shift2 tinyint, 
	@rate2 tinyint, 
	@amt2 tinyint, 
	@cert2 tinyint,
   	@jcco2 tinyint, 
	@job tinyint, 
	@memo2 tinyint, 
	@equip2 tinyint,
	@costcode2 tinyint,
	@skippayseq1 bYN, 
	@skipprdept1 bYN, 
	@skipcrew1 bYN, 
	@skipjcco1 bYN,
	@skipinsstate1 bYN, 
	@skiptaxstate1 bYN, 
	@skiplocal1 bYN,
	@skipunempstate1 bYN, 
	@skipinscode1 bYN, 
	@skipglco1 bYN, 
	@skipemco1 bYN,
	@skipequip1 bYN, 
	@skipcraft1 bYN, 
	@skipclass1 bYN, 
	@skipshift1 bYN,
	@skiprate1 bYN, 
	@skipamt1 bYN, 
	@skipequipphase1 bYN, 
	@skipcosttype1 bYN,
	@skiprevcode1 bYN, 
	@skipcert1 bYN, 
	@skipmemo1 bYN,
	@skippayseq2 bYN, 
	@skipprdept2 bYN, 
	@skipcrew2 bYN, 
	@skipjcco2 bYN,
	@skipjob2 bYN, 
	@skipinsstate2 bYN, 
	@skiptaxstate2 bYN,
	@skiplocal2 bYN, 
	@skipunempstate2 bYN, 
	@skipinscode2 bYN,
	@skipwo2 bYN, 
	@skipwoitem2 bYN, 
	@skipemco2 bYN, 
	@skipcomptype2 bYN, 
	@skipcomp2 bYN, 
	@skipcraft2 bYN,
	@skipclass2 bYN, 
	@skipshift2 bYN, 
	@skiprate2 bYN, 
	@skipamt2 bYN,
	@skipcert2 bYN, 
	@skipmemo2 bYN,
	@msg varchar(60) output)
    as
    set nocount on
    
    declare @rcode int
    
    select @rcode = 0
    
    update PRUP 
	set PaySeq1=@payseq1, PRDept1=@prdept1, Crew1=@crew1, JCCo1=@jcco1, Job1=@job, 
	 Phase1=@phase1, GLCo=@glco, InsState1=@insstate1, 
	 TaxState1=@taxstate1, Local1=@local1, UnempState1=@unempstate1, InsCode1=@inscode1, EMCo1=@emco1, 
   	 Equip=@equip, Craft1=@craft1, Class1=@class1, Shift1=@shift1, Rate1=@rate1, Amt1=@amt1,
   	 EquipPhase1=@equipphase1, CostType1=@costtype1, RevCode1=@revcode1, Memo1=@memo1, 
	 Cert1=@cert1, PaySeq2=@payseq2,
   	 PRDept2=@prdept2, Crew2=@crew2, EMCo3=@emco3, WO=@wo, WOItem=@woitem, CompType=@comptype, 
   	 Comp=@comp, InsState2=@insstate2, TaxState2=@taxstate2, Local2=@local2, UnempState2=@unempstate2,
   	 Craft2=@craft2, InsCode2=@inscode2, Class2=@class2, Shift2=@shift2, Rate2=@rate2, Amt2=@amt2,
   	 Cert2=@cert2, JCCo2=@jcco2, Job=@job, Memo2=@memo2, Equip2=@equip2, CostCode2=@costcode2,
	 SkipPaySeq1=@skippayseq1, SkipPRDept1=@skipprdept1, SkipCrew1=@skipcrew1, SkipJCCo1=@skipjcco1,
	 SkipInsState1=@skipinsstate1, SkipTaxState1=@skiptaxstate1, SkipLocal1=@skiplocal1,
	 SkipUnempState1=@skipunempstate1, SkipInsCode1=@skipinscode1, SkipGLCo1=@skipglco1, SkipEMCo1=@skipemco1,
	 SkipEquip1=@skipequip1, SkipCraft1=@skipcraft1, SkipClass1=@skipclass1, SkipShift1=@skipshift1,
	 SkipRate1=@skiprate1, SkipAmt1=@skipamt1, SkipEquipPhase1=@skipequipphase1, SkipCostType1=@skipcosttype1,
	 SkipRevCode1=@skiprevcode1, SkipCert1=@skipcert1, SkipMemo1=@skipmemo1,
	 SkipPaySeq2=@skippayseq2, SkipPRDept2=@skipprdept2, SkipCrew2=@skipcrew2, SkipJCCo2=@skipjcco2,
	 SkipJob2=@skipjob2, SkipInsState2=@skipinsstate2, SkipTaxState2=@skiptaxstate2,
	 SkipLocal2=@skiplocal2, SkipUnempState2=@skipunempstate2, SkipInsCode2=@skipinscode2,
	 SkipWO2=@skipwo2, SkipWOItem2=@skipwoitem2, SkipEMCo2=@skipemco2, 
	 SkipCompType2=@skipcomptype2, SkipComp2=@skipcomp2, SkipCraft2=@skipcraft2,
	 SkipClass2=@skipclass2, SkipShift2=@skipshift2, SkipRate2=@skiprate2, SkipAmt2=@skipamt2,
	 SkipCert2=@skipcert2, SkipMemo2=@skipmemo2
    where PRCo = @prco and UserName = @user
    
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUPUpdate] TO [public]
GO
