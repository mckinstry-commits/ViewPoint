SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPRAutoOTPostLevels]
   /************************************************************************************
    * CREATED: EN 6/1/01  for issue 11870 (post overtime for levels 1, 2 & 3)
    * MODIFIED:EN 8/24/01 issue 14443
    *			MV 08/16/02 - #18191 BatchUserMemoInsertExisting
    *			EN 8/22/02 - issue 18183 make sure variable earnings rate is figured into bPRTB Amount
    *			MV 09/04/02 - #18390 - Memo field not getting inserted into bPRTB from bPRTH 
    *			EN 10/04/02 - issue 18453  EquipPhase not being written to bPRTB for BatchTransType 'C' entries
    *			EN 10/7/02 - issue 18877 change double quotes to single
    *			GG 02/04/03 - #18703 - rewritten for weighted average overtime, fix shift override logic,
    *									and aggregate daily hours by OT schedule
    *			EN 9/13/05 - issue 29635  track whether records were added to bPRTB and pass info back to bspPRAutoOT
	*			EN 11/24/08 - #126931  replaced code to add a 'Change' type bPRTB entry with call to vspPRTBAddCEntry
	*									and included UniqueAttachID in PRTB 'Add' lines when split a timecard in order to post OT
    *           ECV 04/20/11 - TK-04385 Add SM Fields to PRTB records that are created.
    *			ECV 06/06/12 - TK-14637 Add SMCostType and SMJCCostType fields to PRTB records that are created.
    *			EN 7/11/2012  B-09337/#144937 accept PRCO additional rate options (AutoOTUseVariableRatesYN and AutoOTUseHighestRateYN))
    *										  as input params and pass as params to bspPRAutoOTRateDefault
    *
    * USAGE:
    * Called by daily overtime processing procedure(bspPRAutoOT) to add entries to Timecard batch
    * for daily overtime.  Existing timecard is either changed to overtime, or its hours are reduced 
    * and a new overtime entry is added.
    *
    * INPUT PARAMETERS
    *  @co      	  	PR Company
    *  @mth            Batch Month
    *  @batchid        Batch ID#
    *  @prgroup        PR Group
    *  @prenddate      Pay Period Ending Date
    *	@begindate		Pay Period beginning date
    *  @employee       Employee
    *  @payseq         Payment Sequence
    *  @postseq        Timecard posting sequence
    *  @postdate       Timecard posted date
    *	@craft			Timecard Craft
    *	@class			Timecard Class
    *	@jcco			Timecard JC Co#
    *	@job			Timecard Job
    *	@shift			Max Shift posted for the day
    *  @postedrate     Timecard posted rate
    *  @postedhrs     	Timecard posted hours
    *	@otrateadj		Weighted Average Overtime Rate Adjustment	- #18703 - added
    *	@lvl1earncode	Level 1 Overtime earnings code
    *	@lvl2earncode	Level 2 Overtime earnings code
    *	@lvl3earncode	Level 3 Overtime earnings code
    *  @ot1factor      Level 1 Overtime earnings code factor
    *  @ot2factor      Level 2 Overtime earnings code factor
    *  @ot3factor      Level 3 Overtime earnings code factor
    *  @lvl1ot			# of level 1 overtime hours to post
    *  @lvl2ot			# of level 2 overtime hours to post
    *  @lvl3ot			# of level 3 overtime hours to post
    *  @autootusevariableratesyn	PRCO flag; if 'Y' look up/use variable earnings rate based on craft/class/template
    *  @autootusehighestrateyn		PRCO flag; if 'Y' when posting overtime use highest of employee rate, posted rate and if @autootusevariableratesyn='Y', variable rate
    *
    * OUTPUT PARAMETERS
    *  @lvl1ot			# of level 1 overtime hours to post as adjusted here
    *  @lvl2ot			# of level 2 overtime hours to post as adjusted here
    *  @lvl3ot			# of level 3 overtime hours to post as adjusted here
    *	@PRTBAddedYN	='Y' if any timecards were added to bPRTB
    *  @msg      error message if error occurs
    *
    * RETURN VALUE
    *  @rcode		0 = success, 1 = error
    ************************************************************************************/
   	(@co bCompany = NULL, 
   	 @mth bMonth = NULL, 
   	 @batchid bBatchID = NULL, 
   	 @prgroup bGroup = NULL,
   	 @prenddate bDate = NULL, 
   	 @begindate bDate = NULL, 
   	 @employee bEmployee = NULL, 
   	 @payseq tinyint = NULL,
   	 @postseq smallint = NULL, 
   	 @postdate bDate = NULL, 
   	 @craft bCraft = NULL, 
   	 @class bClass = NULL,
   	 @jcco bCompany = NULL, 
   	 @job bJob = NULL, 
   	 @shift tinyint = 0, 
   	 @postedrate bUnitCost = 0,
   	 @postedhrs bHrs = 0, 
   	 @otrateadj bUnitCost = 0, 
   	 @lvl1earncode bEDLCode = NULL, 
   	 @lvl2earncode bEDLCode = NULL, 
   	 @lvl3earncode bEDLCode = NULL,
   	 @ot1factor bRate = 0, 
   	 @ot2factor bRate = 0, 
   	 @ot3factor bRate = 0,
   	 @autootusevariableratesyn bYN = NULL,
	 @autootusehighestrateyn bYN = NULL,
   	 @lvl1ot bHrs OUTPUT, 
   	 @lvl2ot bHrs OUTPUT, 
   	 @lvl3ot bHrs OUTPUT, 
   	 @PRTBAddedYN bYN OUTPUT, 
   	 @msg varchar(255) OUTPUT) --#29635
    
   as
   
   set nocount on
   
   declare @rcode int, @seq int, @daynum smallint, @otrate bUnitCost, @jcwghtavgot bYN,
   	@prwghtavgot bYN, @prtbud_flag bYN, @otamt bDollar, @errmsg varchar(100) --#126931 added @prtbud_flag and @otamt
   
   select @rcode = 0, @prtbud_flag = 'N' --#126931 added @prtbud_flag
   
   -- get day number
   select @daynum = datediff(day,@begindate,@postdate) + 1
   
   -- #126931 check Timecard Batch table for custom fields
   if exists(select top 1 1 from sys.syscolumns (nolock) where name like 'ud%' and id = object_id('dbo.PRTB'))
		set @prtbud_flag = 'Y'	-- bPRTB has custom fields

   -- get Weighted Avg Overtime option from Job and Craft/Class
   select @jcwghtavgot = 'N', @prwghtavgot = 'N'
   if @jcco is not null and @job is not null
   	select @jcwghtavgot = WghtAvgOT from bJCJM (nolock) where JCCo = @jcco and Job = @job
   if @craft is not null and @class is not null
   	select @prwghtavgot = WghtAvgOT from bPRCC (nolock) where PRCo = @co and Craft = @craft and Class = @class
   
   -- process level 3 overtime first
   IF @lvl3ot > 0 
   BEGIN
		-- use either Weighted Avg OT or get rate		
		IF @otrateadj <> 0 AND @jcwghtavgot = 'Y' AND @prwghtavgot = 'Y'
		BEGIN
			SELECT @otrate = @postedrate + @otrateadj	-- use weighted average overtime adjustment
		END
		ELSE
		BEGIN
			EXEC @rcode = bspPRAutoOTRateDefault @co,			@employee,	@postdate,	@craft, 
												 @class,		@jcco,		@job,		@shift, 
												 @lvl3earncode, @ot3factor, @postedrate, 
												 @autootusevariableratesyn,	@autootusehighestrateyn,
												 @otrate OUTPUT, 
												 @errmsg OUTPUT
		END
	END
   
   if @postedhrs <= @lvl3ot	-- all hours on existing timecard will be changed to level 3 overtime
   	begin
   	-- add batch entry for changed timecard, all posted hours changed to level 3 overtime
	--#126931 replaced get seq# and insert bPRTB code with call to vspPRTBAddCEntry
	select @otamt = @postedhrs * @otrate
	exec @rcode = vspPRTBAddCEntry @co, @prgroup, @prenddate, @mth, @batchid, @prtbud_flag,
		@employee, @payseq, @postseq, @daynum, 'N', 'Y', @otrate, @otamt, 
		@lvl3earncode, 'Y', @postedhrs, @msg output
	if @rcode = 2 select @msg = 'Unable to change existing timecard while processing Level 3 overtime for Employee:' + convert(varchar,@employee), @rcode = 1
	if @rcode <> 0 goto bspexit

   	select @PRTBAddedYN = 'Y' --#29635
   	
   	-- adjust remaining level 3 overtime to distribute
   	set @lvl3ot = @lvl3ot - @postedhrs
   	goto bspexit	-- next timecard
   	end
   
   if @postedhrs > @lvl3ot and @lvl3ot > 0  -- timecard hours greater than remaining level 3 OT, split existing entry
   	begin
   	-- get next sequence #
   	select @seq = isnull(max(BatchSeq),0) + 1
   	from bPRTB
   	where Co = @co and Mth = @mth and BatchId = @batchid
   	
   	-- first add new entry for remaining level 3 overtime
   	insert bPRTB(Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, Type, DayNum,
   		PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment,
   	    EMGroup, CostCode, CompType, Component, RevCode, EquipCType, UsageUnits, TaxState,
   	    LocalCode, UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class,
   	    EarnCode, Shift, Hours, Rate, Amt, Memo, EquipPhase,SMCo,SMWorkOrder,SMScope,SMPayType,SMCostType,SMJCCostType
   	    , UniqueAttchID) --#126931
   	select @co, @mth, @batchid, @seq, 'A', Employee, PaySeq, Type, @daynum,
   	    PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo,	WO, WOItem, Equipment,
   		EMGroup, CostCode, CompType, Component, RevCode, EquipCType, 0, TaxState,
   		LocalCode, UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class,
   		@lvl3earncode, Shift, @lvl3ot, @otrate, @lvl3ot*@otrate, Memo, EquipPhase,bPRTH.SMCo,bPRTH.SMWorkOrder,bPRTH.SMScope,bPRTH.SMPayType,bPRTH.SMCostType,bPRTH.SMJCCostType
   		, bPRTH.UniqueAttchID --#126931
   	from bPRTH
   	where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate
   	     and Employee = @employee and PaySeq = @payseq and PostSeq = @postseq
   	if @@rowcount = 0
   		begin
   	  	select @msg = 'Unable to add Timecard Batch entry while processing Level 3 overtime for Employee:' + convert(varchar,@employee), @rcode = 1
   	  	goto bspexit
   	  	end
   	
   	select @PRTBAddedYN = 'Y' --#29635
   	
   		
   	-- adjust remaining timecard hours, reset level 3 overtime
   	select @postedhrs = @postedhrs - @lvl3ot, @lvl3ot = 0
   	end
   	
   -- process level 2 overtime
   IF @lvl2ot > 0
   BEGIN
	   -- use either Weighted Avg OT or get rate		
	   IF @otrateadj <> 0 AND @jcwghtavgot = 'Y' AND @prwghtavgot = 'Y'
	   BEGIN
   			SELECT @otrate = @postedrate + @otrateadj	-- use weighted average overtime adjustment
   	   END
   	   ELSE
   	   BEGIN
			EXEC @rcode = bspPRAutoOTRateDefault @co,			@employee,	@postdate,	@craft, 
												 @class,		@jcco,		@job,		@shift, 
												 @lvl2earncode, @ot2factor, @postedrate, 
												 @autootusevariableratesyn,	@autootusehighestrateyn,
												 @otrate OUTPUT, 
												 @errmsg OUTPUT
	   END
   END
   
   if @postedhrs <= @lvl2ot	-- remaining hours on existing timecard will be changed to level 2 overtime
   	begin
   	-- add batch entry for changed timecard, all posted hours changed to level 2 overtime
	--#126931 replaced get seq# and insert bPRTB code with call to vspPRTBAddCEntry
	select @otamt = @postedhrs * @otrate
	exec @rcode = vspPRTBAddCEntry @co, @prgroup, @prenddate, @mth, @batchid, @prtbud_flag,
		@employee, @payseq, @postseq, @daynum, 'N', 'Y', @otrate, @otamt, 
		@lvl2earncode, 'Y', @postedhrs, @msg output
	if @rcode = 2 select @msg = 'Unable to change existing timecard while processing Level 2 overtime for Employee:' + convert(varchar,@employee), @rcode = 1
	if @rcode <> 0 goto bspexit

   	select @PRTBAddedYN = 'Y' --#29635
   
   	-- adjust remaining level 2 overtime to distribute
   	set @lvl2ot = @lvl2ot - @postedhrs
   	goto bspexit		-- next timecard
   	end
   
   if @postedhrs > @lvl2ot and @lvl2ot > 0 -- timecard hours greater than remaining level 2 OT, split existing entry
   	begin
   	-- get next sequence #
   	select @seq = isnull(max(BatchSeq),0) + 1
   	from bPRTB
   	where Co = @co and Mth = @mth and BatchId = @batchid
   
   	-- first add new entry for remaining level 3 overtime
   	insert bPRTB(Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, Type, DayNum,
   		PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment,
   	    EMGroup, CostCode, CompType, Component, RevCode, EquipCType, UsageUnits, TaxState,
   	    LocalCode, UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class,SMCo,SMWorkOrder,SMScope,SMPayType,
   	    EarnCode, Shift, Hours, Rate, Amt, Memo, EquipPhase, SMCostType, SMJCCostType, UniqueAttchID) --#126931
   	select @co, @mth, @batchid, @seq, 'A', Employee, PaySeq, Type, @daynum,
   	    PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo,	WO, WOItem, Equipment,
   		EMGroup, CostCode, CompType, Component, RevCode, EquipCType, 0, TaxState,
   		LocalCode, UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class,bPRTH.SMCo,bPRTH.SMWorkOrder,bPRTH.SMScope,bPRTH.SMPayType,
   		@lvl2earncode, Shift, @lvl2ot, @otrate, @lvl2ot*@otrate, Memo, EquipPhase, SMCostType, SMJCCostType, bPRTH.UniqueAttchID --#126931
   	from bPRTH
   	where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate
   	     and Employee = @employee and PaySeq = @payseq and PostSeq = @postseq
   	if @@rowcount = 0
   		begin
   	  	select @msg = 'Unable to add Timecard Batch entry while processing Level 2 overtime for Employee:' + convert(varchar,@employee), @rcode = 1
   	  	goto bspexit
   	  	end
   	
   	select @PRTBAddedYN = 'Y' --#29635
   	
   	
   	-- adjust remaining timecard hours, reset level 2 overtime
   	select @postedhrs = @postedhrs - @lvl2ot, @lvl2ot = 0
   	end
   
   -- process level 1 overtime
   IF @lvl1ot > 0
   BEGIN
	   -- use either Weighted Avg OT or get rate		
	   IF @otrateadj <> 0 AND @jcwghtavgot = 'Y' AND @prwghtavgot = 'Y'
	   BEGIN
   			SELECT @otrate = @postedrate + @otrateadj	-- use weighted average overtime adjustment
	   END
	   ELSE
	   BEGIN
			EXEC @rcode = bspPRAutoOTRateDefault @co,			@employee,	@postdate,	@craft, 
												 @class,		@jcco,		@job,		@shift, 
												 @lvl1earncode, @ot1factor, @postedrate, 
												 @autootusevariableratesyn,	@autootusehighestrateyn,
												 @otrate OUTPUT, 
												 @errmsg OUTPUT
	   END
   END
   
   if @postedhrs <= @lvl1ot	-- all remaining hours on existing timecard will be changed to level 1 overtime
   	begin
   	-- add batch entry for changed timecard, all posted hours changed to level 3 overtime
	--#126931 replaced get seq# and insert bPRTB code with call to vspPRTBAddCEntry
	select @otamt = @postedhrs * @otrate
	exec @rcode = vspPRTBAddCEntry @co, @prgroup, @prenddate, @mth, @batchid, @prtbud_flag,
		@employee, @payseq, @postseq, @daynum, 'N', 'Y', @otrate, @otamt, 
		@lvl1earncode, 'Y', @postedhrs, @msg output
	if @rcode = 2 select @msg = 'Unable to change existing timecard while processing Level 1 overtime for Employee:' + convert(varchar,@employee), @rcode = 1
	if @rcode <> 0 goto bspexit

   	select @PRTBAddedYN = 'Y' --#29635
   	
   	-- adjust remaining level 1 overtime to distribute
   	set @lvl1ot = @lvl1ot - @postedhrs
   	goto bspexit	-- next timecard
   	end
   
   if @postedhrs > @lvl1ot and @lvl1ot > 0 -- timecard hours greater than remaining level 1 OT, split existing entry
   	begin
   	-- get next sequence #
   	select @seq = isnull(max(BatchSeq),0) + 1
   	from bPRTB
   	where Co = @co and Mth = @mth and BatchId = @batchid
   
   	-- first add new entry for remaining level 3 overtime
   	insert bPRTB(Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, Type, DayNum,
   		PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment,
   	    EMGroup, CostCode, CompType, Component, RevCode, EquipCType, UsageUnits, TaxState,
   	    LocalCode, UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class,SMCo,SMWorkOrder,SMScope,SMPayType,
   	    EarnCode, Shift, Hours, Rate, Amt, Memo, EquipPhase, SMCostType, SMJCCostType, UniqueAttchID) --#126931
   	select @co, @mth, @batchid, @seq, 'A', Employee, PaySeq, Type, @daynum,
   	    PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo,	WO, WOItem, Equipment,
   		EMGroup, CostCode, CompType, Component, RevCode, EquipCType, 0, TaxState,
   		LocalCode, UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class,bPRTH.SMCo,bPRTH.SMWorkOrder,bPRTH.SMScope,bPRTH.SMPayType,
   		@lvl1earncode, Shift, @lvl1ot, @otrate, @lvl1ot*@otrate, Memo, EquipPhase, SMCostType, SMJCCostType, bPRTH.UniqueAttchID --#126931
   	from bPRTH
   	where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate
   	     and Employee = @employee and PaySeq = @payseq and PostSeq = @postseq
   	if @@rowcount = 0
   		begin
   	  	select @msg =  'Unable to add Timecard Batch entry while processing Level 1 overtime for Employee:' + convert(varchar,@employee), @rcode = 1
   	  	goto bspexit
   	  	end
   	
   	select @PRTBAddedYN = 'Y' --#29635
   	
   	
   	-- adjust remaining timecard hours
   	select @postedhrs = @postedhrs - @lvl1ot, @lvl1ot = 0
   
   	-- all overtime has been distributed, any remaining hours on timecard will use posted rate
   	-- add batch entry for changed timecard, remaining hours at posted rate
	--#126931 replaced get seq# and insert bPRTB code with call to vspPRTBAddCEntry
	select @otamt = @postedhrs * @postedrate
	exec @rcode = vspPRTBAddCEntry @co, @prgroup, @prenddate, @mth, @batchid, @prtbud_flag,
		@employee, @payseq, @postseq, @daynum, 'N', 'Y', @postedrate, @otamt, 
		null, 'Y', @postedhrs, @msg output
	if @rcode = 2 select @msg =  'Unable to change regular earnings on existing timecard for Employee:' + convert(varchar,@employee), @rcode = 1
	if @rcode <> 0 goto bspexit

   	select @PRTBAddedYN = 'Y' --#29635
   	
   	end
   
    
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAutoOTPostLevels] TO [public]
GO
