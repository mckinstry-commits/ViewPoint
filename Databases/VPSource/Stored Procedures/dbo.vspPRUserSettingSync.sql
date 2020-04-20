SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.vspPRUserSettingSync    Script Date: 8/28/08 9:36:48 AM ******/
   
CREATE   procedure [dbo].[vspPRUserSettingSync]
/************************************************************
* CREATED BY:	EN	08/28/2008
*				CHS	11/16/2010	- 141179
*				MH	01/20/2011	- 131640/142827 - Added support for Service Mgmt.
*				AMR 01/24/2011	- #142350, making case insensitive by renaming variables
*               ECV 09/12/2011	- TK-08101. Add SMCostType
*				CHS	09/15/2011	- TK-08460 fixed @crew3 problem
*				MH 02/07/2012 - TK-12390 Add SMJCCostType
*
* USAGE:
* Called by PRTimeCards to synchronize user settings in DDUI and PRUP with each other.
*
* INPUT PARAMETERS
*   @prco         PR Company
*   @timecardtype	"J" if calling PRTimeCards form is in Job timecard mode or "M" if in Mechanic timecard mode
*   @updatetable  "P" if updating PRUP using DDUI settings or "D" if updating DDUI from PRUP
*   @equipclassoverride  used if @timecardtype="J" ... "Y" if equip class override feature is in use, otherwise "N"
*
* OUTPUT PARAMETERS
*   @errmsg       error message
*
* RETURN VALUE
*   0   success
*   1   fail
************************************************************/

	@prco bCompany, @timecardtype char(1), @updatetable char(1), @equipclassoverride bYN, @errmsg varchar(255) output

	as
	set nocount on

	declare @rcode int, @seq smallint
	--#142350 - renaming @glco 	
	DECLARE @payseq1 tinyint,
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
			@GLCoPRUP tinyint,
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
			@type1 tinyint,
			@skiptype1 bYN,
			@type2 tinyint,
			@skiptype2 bYN
			
		--Issue 142827 - Service changes
		--Using the following as constants to represent the PRTimeCard DDFI Sequences for the fields having skip input values in PRUP.
		--More meaningful then '12' when calling vspPRDDUIUpdate and vspPRUPConvert.
		DECLARE @TYPE tinyint, @PAYSEQ tinyint, @INSSTATE tinyint, 
		@TAXSTATE tinyint, @UNEMPSTATE tinyint, @GLCO tinyint, @EMCO tinyint, @SHIFT tinyint, 
		@RATE tinyint, @AMT tinyint, @EMCO2 tinyint, @SMCO tinyint, @CERT tinyint, @MEMO tinyint,
		@PRDEPT tinyint, @CREW tinyint, @LOCALCODE tinyint, @INSCODE tinyint, @EQUIPMENT tinyint,   
		@CRAFT tinyint, @CCLASS tinyint, @EQUIPMENT2 tinyint, @EQUIPPHASE tinyint, @EQUIPCOSTTYPE tinyint, 
		@REVCODE tinyint, @SMCOSTYPE tinyint, @SMJCCOSTTYPE tinyint

		SELECT @TYPE = 12, @PAYSEQ = 15, @INSSTATE = 23, 
		@TAXSTATE = 24, @UNEMPSTATE = 26, @GLCO = 30, @EMCO = 29, @SHIFT = 40,
		@RATE = 41, @AMT = 43, @EMCO2 = 44, @SMCO = 51, @CERT = 50, @MEMO = 98,
		@PRDEPT = 17, @CREW = 18, @LOCALCODE = 25, @INSCODE = 27, @EQUIPMENT = 34,
		@CRAFT = 28, @CCLASS = 38, @EQUIPMENT2 = 45, @EQUIPPHASE = 46, @EQUIPCOSTTYPE = 47, @REVCODE = 48,
		@SMCOSTYPE = 55, @SMJCCOSTTYPE = 56
	
		--Variables to hold the PRUP/DDUI settings.	
		--#142350 - renaming @crew 	
		DECLARE @type3 tinyint,
				@payseq3 tinyint,
				@prdept3 tinyint,
				@crew3 tinyint,
				@insstate3 tinyint,
				@taxstate3 tinyint,
				@local3 tinyint,
				@unempstate3 tinyint,
				@inscode3 tinyint,
				@craft3 tinyint,
				@emco4 tinyint,
				@glco3 tinyint,
				@equip3 tinyint,
				@class3 tinyint,
				@shift3 tinyint,
				@rate3 tinyint,
				@amt3 tinyint,
				@equipphase3 tinyint,
				@costtype3 tinyint,
				@revcode3 tinyint,
				@cert3 tinyint,
				@smco3 tinyint,
				@smwo3 tinyint,
				@smscope3 tinyint,
				@smpaytype3 tinyint,
				@smcosttype3 tinyint,
				@smjccosttype3 tinyint,
				@memo3 tinyint,
				@CrewPRUP tinyint,
				@skiptype3 bYN,
				@skippayseq3 bYN,
				@skipprdept3 bYN,
				@skipinsstate3 bYN,
				@skiptaxstate3 bYN,
				@skiplocal3 bYN,
				@skipunempstate3 bYN,
				@skipinscode3 bYN,
				@skipcraft3 bYN,
				@skipemco4 bYN,
				@skipglco3 bYN,
				@skipequip3 bYN,
				@skipclass3 bYN,
				@skipshift3 bYN,
				@skiprate3 bYN,
				@skipamt3 bYN,
				@skipequipphase3 bYN,
				@skipcosttype3 bYN,
				@skiprevcode3 bYN,
				@skipcert3 bYN,
				@skipsmco3 bYN,
				@skipmemo3 bYN,
				@skipcrew3 bYN,
	--end Issue 142827
				@skipsmcosttype3 bYN,
				@skipsmjccosttype3 bYN

	-- Synopsis:
	--	For job timecard or for mech timecard
	--		read current PRUP settings   
	--		if updating PRUP, try reading DDUI settings for each field in PRUP for which the skip/show on grid settings 
	--			can be controlled and modify the PRUP setting variables if needed to match DDUI ... after all fields have
	--			been evaluated in this way, write them all to PRUP
	--		if updating DDUI, for each field in PRUP for which the skip/show on grid settings can be controlled, 
	--			invoke vspPRDDUIUpdate which reads the existing DDUI settings and checks to see if the skip/show on grid
	--			setting in DDUI should be modified ... if so then vspDDUIUpdate is used to update them.

	if @timecardtype = 'J'
		begin
		select @payseq1=PaySeq1, @prdept1=PRDept1, @crew1=Crew1, @jcco1=JCCo1, @GLCoPRUP=GLCo, @insstate1=InsState1,
   		 @taxstate1=TaxState1, @local1=Local1, @unempstate1=UnempState1, @inscode1=InsCode1, @emco1=EMCo1, 
   		 @equip=Equip, @craft1=Craft1, @class1=Class1, @shift1=Shift1, @rate1=Rate1, @amt1=Amt1,
   		 @equipphase1=EquipPhase1, @costtype1=CostType1, @revcode1=RevCode1, @memo1=Memo1, @cert1=Cert1, 
		 @skippayseq1=SkipPaySeq1, @skipprdept1=SkipPRDept1, @skipcrew1=SkipCrew1, @skipjcco1=SkipJCCo1,
		 @skipinsstate1=SkipInsState1, @skiptaxstate1=SkipTaxState1, @skiplocal1=SkipLocal1,
		 @skipunempstate1=SkipUnempState1, @skipinscode1=SkipInsCode1, @skipglco1=SkipGLCo1, @skipemco1=SkipEMCo1,
		 @skipequip1=SkipEquip1, @skipcraft1=SkipCraft1, @skipclass1=SkipClass1, @skipshift1=SkipShift1,
		 @skiprate1=SkipRate1, @skipamt1=SkipAmt1, @skipequipphase1=SkipEquipPhase1, @skipcosttype1=SkipCostType1,
		 @skiprevcode1=SkipRevCode1, @skipcert1=SkipCert1, @skipmemo1=SkipMemo1, 
		 @type1=Type1, @skiptype1=SkipType1, @type2=Type2, @skiptype2=SkipType2
		from dbo.PRUP with (nolock) where PRCo = @prco and UserName = suser_sname()

		if @@rowcount = 0 goto bspexit --do not continue if PRUP has not been initialized for this user

		if @updatetable = 'P'
			begin
			--Updating PRUP for job timecards

			--first determine any changes needed to PRUP field settings based on DDUI settings
			exec @rcode = vspPRUPConvert 12, @skiptype1, @type1, 1, 
				@return_skip=@skiptype1 output, @return_setting=@type1 output, @errmsg=@errmsg output			
			
			exec @rcode = vspPRUPConvert 15, @skippayseq1, @payseq1, 1, 
				@return_skip=@skippayseq1 output, @return_setting=@payseq1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 17, @skipprdept1, @prdept1, 2, 
				@return_skip=@skipprdept1 output, @return_setting=@prdept1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 18, @skipcrew1, @crew1, 2, 
				@return_skip=@skipcrew1 output, @return_setting=@crew1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 19, @skipjcco1, @jcco1, 1, 
				@return_skip=@skipjcco1 output, @return_setting=@jcco1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 23, @skipinsstate1, @insstate1, 1, 
				@return_skip=@skipinsstate1 output, @return_setting=@insstate1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 24, @skiptaxstate1, @taxstate1, 1, 
				@return_skip=@skiptaxstate1 output, @return_setting=@taxstate1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 25, @skiplocal1, @local1, 2, 
				@return_skip=@skiplocal1 output, @return_setting=@local1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 26, @skipunempstate1, @unempstate1, 1, 
				@return_skip=@skipunempstate1 output, @return_setting=@unempstate1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 27, @skipinscode1, @inscode1, 2, 
				@return_skip=@skipinscode1 output, @return_setting=@inscode1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 30, @skipglco1, @GLCoPRUP, 1, 
				@return_skip=@skipglco1 output, @return_setting=@GLCoPRUP output, @errmsg=@errmsg output

			if @equipclassoverride = 'Y'
				exec @rcode = vspPRUPConvert 29, @skipemco1, @emco1, 1, 
					@return_skip=@skipemco1 output, @return_setting=@emco1 output, @errmsg=@errmsg output
			else
				exec @rcode = vspPRUPConvert 44, @skipemco1, @emco1, 1, 
					@return_skip=@skipemco1 output, @return_setting=@emco1 output, @errmsg=@errmsg output

			if @equipclassoverride = 'Y'
				exec @rcode = vspPRUPConvert 34, @skipequip1, @equip, 2, 
					@return_skip=@skipequip1 output, @return_setting=@equip output, @errmsg=@errmsg output
			else
				exec @rcode = vspPRUPConvert 45, @skipequip1, @equip, 2, 
					@return_skip=@skipequip1 output, @return_setting=@equip output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 28, @skipcraft1, @craft1, 2, 
				@return_skip=@skipcraft1 output, @return_setting=@craft1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 38, @skipclass1, @class1, 2, 
				@return_skip=@skipclass1 output, @return_setting=@class1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 40, @skipshift1, @shift1, 1, 
				@return_skip=@skipshift1 output, @return_setting=@shift1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 41, @skiprate1, @rate1, 1, 
				@return_skip=@skiprate1 output, @return_setting=@rate1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 43, @skipamt1, @amt1, 1, 
				@return_skip=@skipamt1 output, @return_setting=@amt1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 46, @skipequipphase1, @equipphase1, 2, 
				@return_skip=@skipequipphase1 output, @return_setting=@equipphase1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 47, @skipcosttype1, @costtype1, 2, 
				@return_skip=@skipcosttype1 output, @return_setting=@costtype1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 48, @skiprevcode1, @revcode1, 2, 
				@return_skip=@skiprevcode1 output, @return_setting=@revcode1 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 50, @skipcert1, @cert1, 1, 
				@return_skip=@skipcert1 output, @return_setting=@cert1 output, @errmsg=@errmsg output

			--TK-12390 Corrected Skip Memo Seq parameter.
			exec @rcode = vspPRUPConvert 51, @skipmemo1, @memo1, 1, 
				@return_skip=@skipmemo1 output, @return_setting=@memo1 output, @errmsg=@errmsg output

			--then write updates (if any) to PRUP
			update dbo.bPRUP set PaySeq1=@payseq1, PRDept1=@prdept1, Crew1=@crew1, JCCo1=@jcco1, GLCo=@GLCoPRUP, 
				InsState1=@insstate1, TaxState1=@taxstate1, Local1=@local1, UnempState1=@unempstate1, InsCode1=@inscode1, 
				EMCo1=@emco1, Equip=@equip, Craft1=@craft1, Class1=@class1, Shift1=@shift1, Rate1=@rate1, Amt1=@amt1,
   				EquipPhase1=@equipphase1, CostType1=@costtype1, RevCode1=@revcode1, Memo1=@memo1, Cert1=@cert1, 
				SkipPaySeq1=@skippayseq1, SkipPRDept1=@skipprdept1, SkipCrew1=@skipcrew1, SkipJCCo1=@skipjcco1,
				SkipInsState1=@skipinsstate1, SkipTaxState1=@skiptaxstate1, SkipLocal1=@skiplocal1,
				SkipUnempState1=@skipunempstate1, SkipInsCode1=@skipinscode1, SkipGLCo1=@skipglco1, SkipEMCo1=@skipemco1,
				SkipEquip1=@skipequip1, SkipCraft1=@skipcraft1, SkipClass1=@skipclass1, SkipShift1=@skipshift1,
				SkipRate1=@skiprate1, SkipAmt1=@skipamt1, SkipEquipPhase1=@skipequipphase1, SkipCostType1=@skipcosttype1,
				SkipRevCode1=@skiprevcode1, SkipCert1=@skipcert1, SkipMemo1=@skipmemo1, 
				Type1=@type1, SkipType1=@skiptype1, Type2=@type2, SkipType2=@skiptype2
			where PRCo = @prco and UserName = suser_sname()

			end --end if @updatetable = 'P'

		if @updatetable = 'D'
			begin
			--Updating DDUI for job timecards

			--for each job timecard field represented in PRUP, update PRUP based on DDUI settings if needed
			exec @rcode = vspPRDDUIUpdate 12, @skiptype1, @type1, 1, @errmsg output
			if @rcode = 1 goto bspexit
						
			exec @rcode = vspPRDDUIUpdate 15, @skippayseq1, @payseq1, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 17, @skipprdept1, @prdept1, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 18, @skipcrew1, @crew1, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 19, @skipjcco1, @jcco1, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 23, @skipinsstate1, @insstate1, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 24, @skiptaxstate1, @taxstate1, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 25, @skiplocal1, @local1, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 26, @skipunempstate1, @unempstate1, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 27, @skipinscode1, @inscode1, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 30, @skipglco1, @GLCoPRUP, 1, @errmsg output
			if @rcode = 1 goto bspexit

			if @equipclassoverride = 'Y'
				exec @rcode = vspPRDDUIUpdate 29, @skipemco1, @emco1, 1, @errmsg output
			else
				exec @rcode = vspPRDDUIUpdate 44, @skipemco1, @emco1, 1, @errmsg output
			if @rcode = 1 goto bspexit

			if @equipclassoverride = 'Y'
				exec @rcode = vspPRDDUIUpdate 34, @skipequip1, @equip, 2, @errmsg output
			else
				exec @rcode = vspPRDDUIUpdate 45, @skipequip1, @equip, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 28, @skipcraft1, @craft1, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 38, @skipclass1, @class1, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 40, @skipshift1, @shift1, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 41, @skiprate1, @rate1, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 43, @skipamt1, @amt1, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 46, @skipequipphase1, @equipphase1, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 47, @skipcosttype1, @costtype1, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 48, @skiprevcode1, @revcode1, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 50, @skipcert1, @cert1, 1, @errmsg output
			if @rcode = 1 goto bspexit

			--TK-12390 Corrected Skip Memo Seq number
			exec @rcode = vspPRDDUIUpdate 51, @skipmemo1, @memo1, 1, @errmsg output
			if @rcode = 1 goto bspexit

			end --end if @updatetable = 'D'

		end --end if @timecardtype = 'J'

	if @timecardtype = 'M'
		begin
		select @payseq2=PaySeq2, @prdept2=PRDept2, @crew2=Crew2, @emco3=EMCo3, @wo=WO, @woitem=WOItem, @comptype=CompType, 
   		 @comp=Comp, @insstate2=InsState2, @taxstate2=TaxState2, @local2=Local2, @unempstate2=UnempState2,
   		 @craft2=Craft2, @inscode2=InsCode2, @class2=Class2, @shift2=Shift2, @rate2=Rate2, @amt2=Amt2,
   		 @cert2=Cert2, @jcco2=JCCo2, @job=Job, @memo2=Memo2, 
		 @skippayseq2=SkipPaySeq2, @skipprdept2=SkipPRDept2, @skipcrew2=SkipCrew2, @skipjcco2=SkipJCCo2,
		 @skipjob2=SkipJob2, @skipinsstate2=SkipInsState2, @skiptaxstate2=SkipTaxState2,
		 @skiplocal2=SkipLocal2, @skipunempstate2=SkipUnempState2, @skipinscode2=SkipInsCode2,
		 @skipwo2=SkipWO2, @skipwoitem2=SkipWOItem2, @skipemco2=SkipEMCo2, 
		 @skipcomptype2=SkipCompType2, @skipcomp2=SkipComp2, @skipcraft2=SkipCraft2,
		 @skipclass2=SkipClass2, @skipshift2=SkipShift2, @skiprate2=SkipRate2, @skipamt2=SkipAmt2,
		 @skipcert2=SkipCert2, @skipmemo2=SkipMemo2, 
		 @type1=Type1, @skiptype1=SkipType1, @type2=Type2, @skiptype2=SkipType2
		from dbo.PRUP with (nolock) where PRCo = @prco and UserName = suser_sname()

		if @updatetable = 'P'
			begin
			--Updating PRUP for mechanic timecards

			--first determine any changes needed to PRUP field settings based on DDUI settings
			exec @rcode = vspPRUPConvert 12, @skiptype2, @type2, 1, 
				@return_skip=@skiptype2 output, @return_setting=@type2 output, @errmsg=@errmsg output
			
			exec @rcode = vspPRUPConvert 15, @skippayseq2, @payseq2, 1, 
				@return_skip=@skippayseq1 output, @return_setting=@payseq2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 17, @skipprdept2, @prdept2, 2, 
				@return_skip=@skipprdept2 output, @return_setting=@prdept2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 18, @skipcrew2, @crew2, 2, 
				@return_skip=@skipcrew2 output, @return_setting=@crew2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 19, @skipjcco2, @jcco2, 1, 
				@return_skip=@skipjcco2 output, @return_setting=@jcco2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 20, @skipjob2, @job, 2, 
				@return_skip=@skipjob2 output, @return_setting=@job output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 23, @skipinsstate2, @insstate2, 1, 
				@return_skip=@skipinsstate2 output, @return_setting=@insstate2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 24, @skiptaxstate2, @taxstate2, 1, 
				@return_skip=@skiptaxstate2 output, @return_setting=@taxstate2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 25, @skiplocal2, @local2, 2, 
				@return_skip=@skiplocal2 output, @return_setting=@local2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 26, @skipunempstate2, @unempstate2, 1, 
				@return_skip=@skipunempstate2 output, @return_setting=@unempstate2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 27, @skipinscode2, @inscode2, 2, 
				@return_skip=@skipinscode2 output, @return_setting=@inscode2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 31, @skipwo2, @wo, 2, 
				@return_skip=@skipwo2 output, @return_setting=@wo output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 32, @skipwoitem2, @woitem, 2, 
				@return_skip=@skipwoitem2 output, @return_setting=@woitem output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 29, @skipemco2, @emco3, 1, 
				@return_skip=@skipemco2 output, @return_setting=@emco3 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 36, @skipcomptype2, @comptype, 2, 
				@return_skip=@skipcomptype2 output, @return_setting=@comptype output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 37, @skipcomp2, @comp, 2, 
				@return_skip=@skipcomp2 output, @return_setting=@comp output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 28, @skipcraft2, @craft2, 2, 
				@return_skip=@skipcraft2 output, @return_setting=@craft2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 38, @skipclass2, @class2, 2, 
				@return_skip=@skipclass2 output, @return_setting=@class2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 40, @skipshift2, @shift2, 1, 
				@return_skip=@skipshift2 output, @return_setting=@shift2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 41, @skiprate2, @rate2, 1, 
				@return_skip=@skiprate2 output, @return_setting=@rate2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 43, @skipamt2, @amt2, 1, 
				@return_skip=@skipamt2 output, @return_setting=@amt2 output, @errmsg=@errmsg output

			exec @rcode = vspPRUPConvert 50, @skipcert2, @cert2, 1, 
				@return_skip=@skipcert2 output, @return_setting=@cert2 output, @errmsg=@errmsg output

			--TK-12390 Correct Seq parameter to Memo DDFI Seq 58
			exec @rcode = vspPRUPConvert 51, @skipmemo2, @memo2, 1, 
				@return_skip=@skipmemo2 output, @return_setting=@memo2 output, @errmsg=@errmsg output

			--then write updates (if any) to PRUP
			update dbo.bPRUP set PaySeq2=@payseq2, PRDept2=@prdept2, Crew2=@crew2, EMCo3=@emco3, WO=@wo, WOItem=@woitem, 
				CompType=@comptype, Comp=@comp, InsState2=@insstate2, TaxState2=@taxstate2, Local2=@local2, 
				UnempState2=@unempstate2, Craft2=@craft2, InsCode2=@inscode2, Class2=@class2, Shift2=@shift2, 
				Rate2=@rate2, Amt2=@amt2, Cert2=@cert2, JCCo2=@jcco2, Job=@job, Memo2=@memo2, 
				SkipPaySeq2=@skippayseq2, SkipPRDept2=@skipprdept2, SkipCrew2=@skipcrew2, SkipJCCo2=@skipjcco2,
				SkipJob2=@skipjob2, SkipInsState2=@skipinsstate2, SkipTaxState2=@skiptaxstate2, SkipLocal2=@skiplocal2, 
				SkipUnempState2=@skipunempstate2, SkipInsCode2=@skipinscode2, SkipWO2=@skipwo2, SkipWOItem2=@skipwoitem2, 
				SkipEMCo2=@skipemco2, SkipCompType2=@skipcomptype2, SkipComp2=@skipcomp2, SkipCraft2=@skipcraft2,
				SkipClass2=@skipclass2, SkipShift2=@skipshift2, SkipRate2=@skiprate2, SkipAmt2=@skipamt2,
				SkipCert2=@skipcert2, SkipMemo2=@skipmemo2, 
				Type1=@type1, SkipType1=@skiptype1, Type2=@type2, SkipType2=@skiptype2
			where PRCo = @prco and UserName = suser_sname()

			end --end if @updatetable = 'P'

		if @updatetable = 'D'
			begin
			--Updating DDUI for mechanic timecards

			--for each mechanic timecard field represented in PRUP, update PRUP based on DDUI settings if needed
			exec @rcode = vspPRDDUIUpdate 12, @skiptype2, @type2, 1, @errmsg output
			if @rcode = 1 goto bspexit
						
			exec @rcode = vspPRDDUIUpdate 15, @skippayseq2, @payseq2, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 17, @skipprdept2, @prdept2, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 18, @skipcrew2, @crew2, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 19, @skipjcco2, @jcco2, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 20, @skipjob2, @job, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 23, @skipinsstate2, @insstate2, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 24, @skiptaxstate2, @taxstate2, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 25, @skiplocal2, @local2, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 26, @skipunempstate2, @unempstate2, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 27, @skipinscode2, @inscode2, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 31, @skipwo2, @wo, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 32, @skipwoitem2, @woitem, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 29, @skipemco2, @emco3, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 36, @skipcomptype2, @comptype, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 37, @skipcomp2, @comp, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 28, @skipcraft2, @craft2, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 38, @skipclass2, @class2, 2, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 40, @skipshift2, @shift2, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 41, @skiprate2, @rate2, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 43, @skipamt2, @amt2, 1, @errmsg output
			if @rcode = 1 goto bspexit

			exec @rcode = vspPRDDUIUpdate 50, @skipcert2, @cert2, 1, @errmsg output
			if @rcode = 1 goto bspexit

			--TK-12390 
			exec @rcode = vspPRDDUIUpdate 51, @skipmemo2, @memo2, 1, @errmsg output
			if @rcode = 1 goto bspexit

			end --end if @updatetable = 'D'

		end --end if @timecardtype = 'M'

		--Issue 131640/142827 
		IF @timecardtype = 'S'
		BEGIN
			--select @type3 = Type3, @payseq3 = PaySeq3, @prdept3 = PRDept3, @CrewPRUP = Crew3, @insstate3 = InsState3,
			select @type3 = Type3, @payseq3 = PaySeq3, @prdept3 = PRDept3, @crew3 = Crew3, @insstate3 = InsState3,
			@taxstate3 = TaxState3, @local3 = Local3, @unempstate3 = UnempState3, @inscode3 = InsCode3, @glco3 = GLCo3,
			@emco4 = EMCo4, @equip3 = Equip3, @craft3 = Craft3, @class3 = Class3, @shift3 = Shift3, @rate3 = Rate3,
			@amt3 = Amt3, @equipphase3 = EquipPhase3, @costtype3 = CostType3, @revcode3 = RevCode3, @smco3 = SMCo3,
			@cert3 = Cert3, @memo3 = Memo3, @smcosttype3 = SMCostType3, @smjccosttype3 = SMJCCostType3
			from dbo.PRUP with (nolock) where PRCo = @prco and UserName = suser_sname()

			--Select from PRUP
			IF @updatetable = 'P'
			BEGIN
				--first determine any changes needed to PRUP field settings based on DDUI settings
				exec @rcode = vspPRUPConvert @TYPE, @skiptype3, @type3, 1, 
				@return_skip=@skiptype3 output, @return_setting=@type3 output, @errmsg=@errmsg output				
								
				exec @rcode = vspPRUPConvert @PAYSEQ, @skippayseq3, @payseq3, 1, 
				@return_skip=@skippayseq3 output, @return_setting=@payseq3 output, @errmsg=@errmsg output				
				
				exec @rcode = vspPRUPConvert @INSSTATE, @skipinsstate3, @insstate3, 1, 
				@return_skip=@skipinsstate3 output, @return_setting=@insstate3 output, @errmsg=@errmsg output				
				
				exec @rcode = vspPRUPConvert @TAXSTATE, @skiptaxstate3, @taxstate3, 1, 
				@return_skip=@skiptaxstate3 output, @return_setting=@taxstate3 output, @errmsg=@errmsg output
				
				exec @rcode = vspPRUPConvert @UNEMPSTATE, @skipunempstate3, @unempstate3, 1, 
				@return_skip=@skipunempstate3 output, @return_setting=@unempstate3 output, @errmsg=@errmsg output					
				
				exec @rcode = vspPRUPConvert @GLCO, @skipglco3, @glco3, 1, 
				@return_skip=@skipglco3 output, @return_setting=@glco3 output, @errmsg=@errmsg output					
				
				IF @equipclassoverride = 'Y'
				BEGIN
					exec @rcode = vspPRUPConvert @EMCO, @skipemco4, @emco4, 1, 
					@return_skip=@skipemco4 output, @return_setting=@emco4 output, @errmsg=@errmsg output					
				END
				ELSE
				BEGIN
					exec @rcode = vspPRUPConvert @EMCO2, @skipemco4, @emco4, 1, 
					@return_skip=@skipemco4 output, @return_setting=@emco4 output, @errmsg=@errmsg output
				END
				
				exec @rcode = vspPRUPConvert @SHIFT, @skipshift3, @shift3, 1, 
				@return_skip=@skipshift3 output, @return_setting=@shift3 output, @errmsg=@errmsg output						
				
				exec @rcode = vspPRUPConvert @RATE, @skiprate3, @rate3, 1, 
				@return_skip=@skiprate3 output, @return_setting=@rate3 output, @errmsg=@errmsg output				
				
				exec @rcode = vspPRUPConvert @AMT, @skipamt3, @amt3, 1, 
				@return_skip=@skipamt3 output, @return_setting=@amt3 output, @errmsg=@errmsg output

				exec @rcode = vspPRUPConvert @SMCO, @skipcert3, @smco3, 1, 
				@return_skip=@skipsmco3 output, @return_setting=@smco3 output, @errmsg=@errmsg output					

				exec @rcode = vspPRUPConvert @CERT, @skipcert3, @cert3, 1, 
				@return_skip=@skipcert3 output, @return_setting=@cert3 output, @errmsg=@errmsg output				

				exec @rcode = vspPRUPConvert @MEMO, @skipmemo3, @memo3, 1, 
				@return_skip=@skipmemo3 output, @return_setting=@memo3 output, @errmsg=@errmsg output					

				exec @rcode = vspPRUPConvert @PRDEPT, @skipprdept3, @prdept3, 2, 
				@return_skip=@skipprdept3 output, @return_setting=@prdept3 output, @errmsg=@errmsg output	
								
				exec @rcode = vspPRUPConvert @CREW, @skipcrew3, @crew3, 2, 
				@return_skip=@skipcrew3 output, @return_setting=@crew3 output, @errmsg=@errmsg output	
				
				exec @rcode = vspPRUPConvert @LOCALCODE, @skiplocal3, @local3, 2, 
				@return_skip=@skiplocal3 output, @return_setting=@local3 output, @errmsg=@errmsg output				
				
				exec @rcode = vspPRUPConvert @INSCODE, @skipinscode3, @inscode3, 2, 
				@return_skip=@skipinscode3 output, @return_setting=@inscode3 output, @errmsg=@errmsg output

				IF @equipclassoverride = 'Y'
				BEGIN				
					exec @rcode = vspPRUPConvert @EQUIPMENT, @skipequip3, @equip3, 2, 
					@return_skip=@skipequip3 output, @return_setting=@equip3 output, @errmsg=@errmsg output
				END
				ELSE
				BEGIN
					exec @rcode = vspPRUPConvert @EQUIPMENT2, @skipequip3, @equip3, 2, 
					@return_skip=@skipequip3 output, @return_setting=@equip3 output, @errmsg=@errmsg output				
				END
				
				exec @rcode = vspPRUPConvert @CRAFT, @skipcraft3, @craft3, 2, 
				@return_skip=@skipcraft3 output, @return_setting=@craft3 output, @errmsg=@errmsg output

				exec @rcode = vspPRUPConvert @CCLASS, @skipclass3, @class3, 2, 
				@return_skip=@skipclass3 output, @return_setting=@class3 output, @errmsg=@errmsg output

				exec @rcode = vspPRUPConvert @EQUIPPHASE, @skipequipphase3, @equipphase3, 2, 
				@return_skip=@skipequipphase3 output, @return_setting=@equipphase3 output, @errmsg=@errmsg output

				exec @rcode = vspPRUPConvert @EQUIPCOSTTYPE, @skipcosttype3, @costtype3, 2, 
				@return_skip=@skipcosttype3 output, @return_setting=@costtype3 output, @errmsg=@errmsg output			
								
				exec @rcode = vspPRUPConvert @REVCODE, @skiprevcode3, @revcode3, 2, 
				@return_skip=@skiprevcode3 output, @return_setting=@revcode3 output, @errmsg=@errmsg output
				
				exec @rcode = vspPRUPConvert @SMCOSTYPE, @skipsmcosttype3, @smcosttype3, 2, 
				@return_skip=@skipsmcosttype3 output, @return_setting=@smcosttype3 output, @errmsg=@errmsg output
				
				--TK-12390 
				exec @rcode = vspPRUPConvert @SMJCCOSTTYPE, @skipsmjccosttype3, @smjccosttype3, 2, 
				@return_skip=@skipsmjccosttype3 output, @return_setting=@smjccosttype3 output, @errmsg=@errmsg output
				
				--update bPRUP
				UPDATE dbo.bPRUP SET Type3 = @type3, SkipType3 = @skiptype3, PaySeq3 = @payseq3, SkipPaySeq3 = @skippayseq3,
				InsState3 = @insstate3, SkipInsState3 = @skipinsstate3, TaxState3 = @taxstate3, SkipTaxState3 = @skiptaxstate3,
				UnempState3 = @unempstate3, SkipUnempState3 = @skipunempstate3, GLCo3 = @glco3, SkipGLCo3 = @skipglco3,
				EMCo4 = @emco4, SkipEMCo4 = @skipemco4, Shift3 = @shift3, SkipShift3 = @skipshift3, Rate3 = @rate3, SkipRate3 = @skiprate3, 
				Amt3 = @amt3, SkipAmt3 = @skipamt3, SMCo3 = @smco3, SkipSMCo3 = @skipsmco3, Cert3 = @cert3, SkipCert3 = @skipcert3,
				PRDept3 = @prdept3, SkipPRDept3 = @skipprdept3, Crew3 = @crew3, SkipCrew3 = @skipcrew3, Local3 = @local3,
				SkipLocal3 = @skiplocal3, InsCode3 = @inscode3, SkipInsCode3 = @skipinscode3, Equip3 = @equip3, 
				SkipEquip3 = @skipequip3, Craft3 = @craft3, SkipCraft3 = @skipcraft3, Class3 = @class3, SkipClass3 = @skipclass3,
				EquipPhase3 = @equipphase3, SkipEquipPhase3 = @skipequipphase3, CostType3 = @costtype3, SkipCostType3 = @skipcosttype3,
				RevCode3 = @revcode3, SkipRevCode3 = @skiprevcode3, SMCostType3 = @smcosttype3, SkipSMCostType3 = @skipsmcosttype3,
				SMJCCostType3 = @smjccosttype3, SkipSMJCCostType3 = @skipsmjccosttype3 
				WHERE PRCo = @prco and UserName = suser_sname()
				
				
			END
			IF @updatetable = 'D'
			BEGIN
				--exec vspPRDDUIUpdate
				
				exec @rcode = vspPRDDUIUpdate @TYPE, @skiptype3, @type3, 1, @errmsg output
								
				exec @rcode = vspPRDDUIUpdate @PAYSEQ, @skippayseq3, @payseq3, 1, @errmsg output
				
				exec @rcode = vspPRDDUIUpdate @INSSTATE, @skipinsstate3, @insstate3, 1, @errmsg output
				
				exec @rcode = vspPRDDUIUpdate @TAXSTATE, @skiptaxstate3, @taxstate3, 1, @errmsg output
				
				exec @rcode = vspPRDDUIUpdate @UNEMPSTATE, @skipunempstate3, @unempstate3, 1, @errmsg output
				
				exec @rcode = vspPRDDUIUpdate @GLCO, @skipglco3, @glco3, 1, @errmsg output
				
				IF @equipclassoverride = 'Y'
				BEGIN
					exec @rcode = vspPRDDUIUpdate @EMCO, @skipemco4, @emco4, 1, @errmsg output
				END
				ELSE
				BEGIN
					exec @rcode = vspPRDDUIUpdate @EMCO2, @skipemco4, @emco4, 1, @errmsg output
				END
				
				exec @rcode = vspPRDDUIUpdate @SHIFT, @skipshift3, @shift3, 1, @errmsg output
				
				exec @rcode = vspPRDDUIUpdate @RATE, @skiprate3, @rate3, 1, @errmsg output
				
				exec @rcode = vspPRDDUIUpdate @AMT, @skipamt3, @amt3, 1, @errmsg output

				exec @rcode = vspPRDDUIUpdate @SMCO, @skipcert3, @smco3, 1, @errmsg output

				exec @rcode = vspPRDDUIUpdate @CERT, @skipcert3, @cert3, 1, @errmsg output

				exec @rcode = vspPRDDUIUpdate @MEMO, @skipmemo3, @memo3, 1, @errmsg output

				exec @rcode = vspPRDDUIUpdate @PRDEPT, @skipprdept3, @prdept3, 2, @errmsg output
								
				exec @rcode = vspPRDDUIUpdate @CREW, @skipcrew3, @crew3, 2, @errmsg output
				
				exec @rcode = vspPRDDUIUpdate @LOCALCODE, @skiplocal3, @local3, 2, @errmsg output
				
				exec @rcode = vspPRDDUIUpdate @INSCODE, @skipinscode3, @inscode3, 2, @errmsg output

				IF @equipclassoverride = 'Y'
				BEGIN				
					exec @rcode = vspPRDDUIUpdate @EQUIPMENT, @skipequip3, @equip3, 2, @errmsg output
				END
				ELSE
				BEGIN
					exec @rcode = vspPRDDUIUpdate @EQUIPMENT2, @skipequip3, @equip3, 2, @errmsg output
				END
				
				exec @rcode = vspPRDDUIUpdate @CRAFT, @skipcraft3, @craft3, 2, @errmsg output

				exec @rcode = vspPRDDUIUpdate @CCLASS, @skipclass3, @class3, 2, @errmsg output

				exec @rcode = vspPRDDUIUpdate @EQUIPPHASE, @skipequipphase3, @equipphase3, 2, @errmsg output

				exec @rcode = vspPRDDUIUpdate @EQUIPCOSTTYPE, @skipcosttype3, @costtype3, 2, @errmsg output
								
				exec @rcode = vspPRDDUIUpdate @REVCODE, @skiprevcode3, @revcode3, 2, @errmsg output
				
				exec @rcode = vspPRDDUIUpdate @SMCOSTYPE, @skipsmcosttype3, @smcosttype3, 2, @errmsg output
				
				--TK12390
				exec @rcode = vspPRDDUIUpdate @SMJCCOSTTYPE, @skipsmjccosttype3, @smjccosttype3, 2, @errmsg output
			
			END
		END
		
	bspexit:
     	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRUserSettingSync] TO [public]
GO
