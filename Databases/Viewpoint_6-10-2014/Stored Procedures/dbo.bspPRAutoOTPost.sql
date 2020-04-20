SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPRAutoOTPost]
 /************************************************************************************
 * CREATED: GG 4/30/99
 * MODIFIED: EN 11/29/99 - fixed to not copy equipment posting info into new timecard postings so as not to duplicate EM repORting
 *  			KB 12/21/99 - fixed previous modIFication so that it does copy equip info IF it is a Maintenance type line.
 * 			kb 4/4/00 - issue #6709
 *  			kb 4/12/00 - issue #5736
 * 			kb 4/17/00 - issue #5736
 *           EN 9/12/00 - issue #9834 - call bspPRAutoOTRateDefault to look fOR variable earnings rate override
 *           GH 11/21/00 - issue #11410 - changed @vearnrate check FROM IS NOT NULL to <> 0
 *			MV 08/16/02 - #18191 - BatchUserMemoInsertExisting
 *			EN 8/22/02 - issue 18183 make sure variable earnings rate is figured into bPRTB Amount
 *			MV 09/04/02 - #18390 - Memo field not getting INSERTed into bPRTB FROM bPRTH
 *			EN 10/04/02 - issue 18453  EquipPhase not being written to bPRTB fOR BatchTransType 'C' entries
 *			EN 10/7/02 - issue 18877 change double quotes to single
 *			EN 10/24/02 - issue 19112  when split posting to post remainder of OT, UPDATE cORrect batch posting
 *			GG 02/04/03 - #18703 - Weighted average overtime
 *			EN 12/03/03 - issue 23061  added ISNULL check, WITH (NOLOCK), AND dbo
 *			EN 9/13/05 - issue 29635  track whether recORds were added to bPRTB AND pass info back to bspPRAutoOTWeekly
 *			EN 9/15/06 - issue 122491  changed PRTB UPDATE to locate specIFic entry to UPDATE in case there are multiple cANDidates
 *			EN 3/7/08 - #127081  in DECLARE statements change State declarations to varchar(4)
 *			EN 11/24/08 - #126931  replaced code to add a 'Change' type bPRTB entry WITH call to vspPRTBAddCEntry 
 *									AND included UniqueAttachID in PRTB 'Add' lines when split a timecard in ORder to post OT
 *          ECV 04/20/11 - TK-04385 Add SM Fields to PRTB recORds that are created.
 *			EN/KK 05/10/11  TK-04978 / #143502 apply best practice standard to code used to call bspPRAutoOTRateDefault
 *			ECV 06/06/11 - TK-14637 Add SMCostType and SMJCCostType to new record.
 *			EN 7/11/2012  B-09337/#144937 accept PRCO additional rate options (AutoOTUseVariableRatesYN and AutoOTUseHighestRateYN))
 *										  as input params and pass as params to bspPRAutoOTRateDefault
 *
 * USAGE:
 * Called by bspPRAutoOTWeekly to add entries to Timecard batch fOR weekly overtime.  Existing timecard is
 * either changed to overtime, OR its hours are reduced AND a new overtime entry is added.
 *
 * INPUT PARAMETERS
 *  	@co      	  	PR Company
 *  	@mth            Batch Month
 *  	@batchid        Batch ID#
 *  	@prgroup        PR Group
 *  	@prENDdate      Pay Period Ending Date
 *  	@employee       Employee
 *  	@payseq         Payment Sequence
 *  	@begindate      Pay Period bdginning date
 *  	@postseq        Timecard posting sequence
 *  	@postdate       Timecard posted date
 *  	@postedhrs      Timecard posted hours
 *  	@postedrate     Timecard posted rate
 *  	@otearncode     Overtime earnings code
 *  	@otfactor       Overtime earnings code factOR
 *  	@otremain       # of overtime hours remaining to be added
 *		@otrateadj		Weighted Average Overtime Rate Adjustment	- #18703 - added
 *      @autootusevariableratesyn	PRCO flag; if 'Y' look up/use variable earnings rate based on craft/class/template
 *      @autootusehighestrateyn		PRCO flag; if 'Y' when posting overtime use highest of employee rate, posted rate and if @autootusevariableratesyn='Y', variable rate
 *
 * OUTPUT PARAMETERS
 *		@PRTBAddedYN	='Y' IF any timecards were added to bPRTB
 *		@msg      error message IF error occurs
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 ************************************************************************************/
(@co bCompany = NULL, 
 @mth bMonth = NULL,  
 @batchid bBatchID = NULL,  
 @prgroup bGroup = NULL, 
 @prenddate bDate = NULL,  
 @employee bEmployee = NULL,  
 @payseq tinyint = NULL,
 @begindate bDate = NULL,  
 @postseq smallint = NULL,  
 @postdate bDate = NULL,
 @postedhrs bHrs = NULL,  
 @postedrate bUnitCost = NULL,  
 @otearncode bEDLCode = NULL,
 @otfactor bRate = NULL,  
 @otremain bHrs = NULL,  
 @otrateadj bUnitCost = NULL, 
 @autootusevariableratesyn bYN = NULL,
 @autootusehighestrateyn bYN = NULL,
 @PRTBAddedYN bYN OUTPUT,  
 @msg varchar(255) OUTPUT) --#29635
 
AS
 
SET NOCOUNT ON
 
DECLARE @rcode int, 
		@seq int,  
		@daynum smallint,  
		@rate bUnitCost,  
		@amt bDollar,  
		@hrs bHrs,
  		@craft bCraft,  
		@class bClass,  
		@shift tinyint,  
		@jcco bCompany,  
		@job bJob,  
		@otrate bUnitCost,
  		@phase bPhase, 
		@taxstate varchar(4),  
		@localcode bLocalCode,  
		@unempstate varchar(4),  
		@insstate varchar(4),
 		@inscode bInsCode,  
		@errmsg varchar(100),  
		@jcwghtavgot bYN,  
		@prwghtavgot bYN,
		@prtbud_flag bYN,  
		@otamt bDollar, --#126931 added @prtbud_flag AND @otamt
		@batchseq int,
		@template smallint



SELECT  @rcode = 0, 
		@prtbud_flag = 'N' --#126931 added @prtbud_flag

-- get day number
SELECT @daynum = datediff(day,@begindate,@postdate) + 1

-- #126931 check Timecard Batch table fOR custom fields
IF EXISTS(SELECT TOP 1 1 FROM sys.syscolumns (NOLOCK) WHERE name LIKE 'ud%' AND id = object_id('dbo.PRTB'))
BEGIN
	SET @prtbud_flag = 'Y'	-- bPRTB has custom fields
END

-- #18703 - get info FROM existing Timecard needed to search fOR overtime rates
SELECT  @craft = Craft, 
		@class = Class, 
		@shift = Shift, 
		@jcco = JCCo, 
		@job = Job
FROM dbo.bPRTH WITH (NOLOCK)
WHERE	PRCo = @co 
		AND PRGroup = @prgroup  
		AND PREndDate = @prenddate  
		AND Employee = @employee  
		AND PaySeq = @payseq  
		AND PostSeq = @postseq
IF @@rowcount = 0
BEGIN
	SELECT @msg = 'Unable find existing Timecard entry.'
	RETURN 1
END

-- get Weighted Avg Overtime option FROM Job AND Craft/Class
SELECT  @jcwghtavgot = 'N', 
		@prwghtavgot = 'N'
IF @jcco IS NOT NULL AND @job IS NOT NULL
BEGIN
	SELECT @jcwghtavgot = WghtAvgOT 
	FROM dbo.bJCJM WITH (NOLOCK) 
	WHERE JCCo = @jcco AND Job = @job
END
IF @craft IS NOT NULL AND @class IS NOT NULL
BEGIN
	SELECT @prwghtavgot = WghtAvgOT 
	FROM dbo.bPRCC WITH (NOLOCK) 
	WHERE PRCo = @co AND Craft = @craft AND Class = @class
END
 
-- check to see if hours posted on existing timecard exceeds remaining overtime
IF @otremain < @postedhrs
BEGIN
 	-- #18703 - use Weighted Avg OT OR get rate		
 	IF @otrateadj <> 0 AND @jcwghtavgot = 'Y' AND @prwghtavgot = 'Y'
	BEGIN
 		SELECT @otrate = @postedrate + @otrateadj	-- use weighted average overtime adjustment
	END
 	ELSE
	BEGIN
 		EXEC @rcode = bspPRAutoOTRateDefault 
				@co,  
				@employee,  
				@postdate,  
				@craft,  
				@class,  
				@jcco,  
				@job,
        		@shift,  
				@otearncode,  
				@otfactor,  
				@postedrate,  
				@autootusevariableratesyn,
				@autootusehighestrateyn,
				@otrate output,  
				@errmsg output
	END
 
	-- full amount of remaining overtime will be added as new timecard entry
	SELECT @hrs = @otremain

	-- read bPRTH info
	SELECT  @phase = Phase, 
			@taxstate = TaxState, 
			@localcode = LocalCode, 
			@unempstate = UnempState,
			@insstate = InsState, 
			@inscode = InsCode
	FROM dbo.bPRTH (NOLOCK)
	WHERE	PRCo = @co 
			AND PRGroup = @prgroup  
			AND PREndDate = @prenddate
 			AND Employee = @employee  
			AND PaySeq = @payseq  
			AND PostSeq = @postseq

	-- issue 122342 deterMINe specIFic entry to UPDATE in case of multiple possibilities LIKE IF there is an equipment attachment timecard
	SELECT @batchseq = MIN(BatchSeq) 
	FROM dbo.bPRTB
	WHERE	Co = @co  
			AND Mth = @mth  
			AND BatchId = @batchid  
			AND BatchTransType = 'A'  
			AND Employee = @employee  
			AND PostDate = @postdate  
			AND PaySeq = @payseq
			AND EarnCode = @otearncode  
			AND ISNULL(Craft,'') = ISNULL(@craft,'')
			AND ISNULL(Class,'') = ISNULL(@class,'')  
			AND Shift = @shift 
			AND ISNULL(JCCo,0) = ISNULL(@jcco,0)  
			AND ISNULL(Job,'') = ISNULL(@job,'')
			AND ISNULL(Phase,'') = ISNULL(@phase,'')  
			AND TaxState = @taxstate
			AND ISNULL(LocalCode,'') = ISNULL(@localcode,'')  
			AND UnempState = @unempstate
			AND InsState = @insstate  
			AND ISNULL(InsCode,'') = ISNULL(@inscode,'') 
			AND Hours > 0
	IF @batchseq IS NOT NULL
	BEGIN
		UPDATE dbo.bPRTB
		SET Hours = Hours + @hrs, Amt = (Hours + @hrs) * @otrate
		WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq=@batchseq
	END
	ELSE
	BEGIN
		-- get next sequence #
		SELECT @seq = ISNULL(MAX(BatchSeq),0) + 1
		FROM dbo.bPRTB WITH (NOLOCK)
		WHERE Co = @co AND Mth = @mth AND BatchId = @batchid

		-- add new entry to batch fOR overtime hours
		INSERT dbo.bPRTB 
			(Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, Type, DayNum,
			PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, 
			EMCo, 
			WO, WOItem, 
			Equipment,
			EMGroup, CostCode, CompType, Component, 
			RevCode, 
			EquipCType, 
			UsageUnits, 
			TaxState, LocalCode, UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class,
			EarnCode, Shift, Hours, Rate, Amt, Memo, 
			SMCo, SMWorkOrder, SMScope, SMPayType, SMCostType, SMJCCostType,
			UniqueAttchID) --#126931
		SELECT @co, @mth, @batchid, @seq, 'A', Employee, PaySeq, Type, @daynum,
			PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, 
			CASE Type WHEN 'J' THEN NULL WHEN 'M' THEN EMCo END,
			WO, WOItem, 
			CASE Type WHEN 'J' THEN NULL WHEN 'M' THEN Equipment END,
			EMGroup, CostCode, CompType, Component, 
			CASE Type WHEN 'J' THEN NULL WHEN 'M' THEN RevCode END,
			EquipCType, 
			CASE Type WHEN 'J' THEN NULL WHEN 'M' THEN UsageUnits END, 
			TaxState, LocalCode, UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class,
			@otearncode, Shift, @hrs, @otrate, @hrs*@otrate /*issue 18183*/, Memo, 
			SMCo, SMWorkOrder, SMScope, SMPayType, SMCostType, SMJCCostType,
			UniqueAttchID --#126931
		FROM dbo.bPRTH WITH (NOLOCK)
		WHERE	PRCo = @co 
				AND PRGroup = @prgroup  
				AND PREndDate = @prenddate
				AND Employee = @employee  
				AND PaySeq = @payseq  
				AND PostSeq = @postseq
		IF @@rowcount = 0
     	BEGIN
       		SELECT @msg = 'Unable to add new overtime entry to Timecard batch.'
       		RETURN 1
       	END
		ELSE
		BEGIN
			SELECT @PRTBAddedYN = 'Y' --#29635
		END
 	END
 
	-- existing Timecard will be added to batch, it's hours reduced by full amount of remaining overtime
	SELECT @hrs = (@postedhrs - @otremain)
	SELECT @amt = (@hrs * @postedrate)

	-- Timecard may already be in batch, attempt UPDATE first
	UPDATE dbo.bPRTB 
	SET Hours = @hrs, Amt = @hrs * Rate
	WHERE	Co = @co 
			AND Mth = @mth  
			AND BatchId = @batchid
			AND Employee = @employee  
			AND BatchTransType = 'C'  
			AND PaySeq = @payseq
			AND PostDate= @postdate  
			AND PostSeq = @postseq
	IF @@rowcount = 0
	BEGIN
		--#126931 replaced get seq# AND INSERT bPRTB code WITH call to vspPRTBAddCEntry
		EXEC @rcode = vspPRTBAddCEntry  
						@co, 
						@prgroup,  
						@prenddate,  
						@mth,  
						@batchid,  
						@prtbud_flag,
						@employee,  
						@payseq,  
						@postseq,  
						@daynum,  
						'N',  
						'Y',  
						NULL,  
						@amt,  
						NULL,  
						'Y',  
						@hrs,  
						@msg OUTPUT
		IF @rcode = 2 
		BEGIN
			SELECT @msg = 'Unable to add UPDATEd regular earnings entry to Timecard batch.'
			RETURN 1
		END

		SELECT @PRTBAddedYN = 'Y' --#29635

	END
END
ELSE
BEGIN 
	-- Remaining overtime exceeds OR equals Posted hours - add existing Timecard to batch as Overtime entry
	-- #18703 - use Weighted Avg OT OR get rate		
	IF @otrateadj <> 0 AND @jcwghtavgot = 'Y' AND @prwghtavgot = 'Y'
	BEGIN
		SELECT @otrate = @postedrate + @otrateadj	-- use weighted average overtime adjustment
	END
	ELSE
	BEGIN
 		EXEC @rcode = bspPRAutoOTRateDefault 
				@co,  
				@employee,  
				@postdate,  
				@craft,  
				@class,  
				@jcco,  
				@job,
        		@shift,  
				@otearncode,  
				@otfactor,  
				@postedrate,  
				@autootusevariableratesyn,
				@autootusehighestrateyn,
				@otrate output,  
				@errmsg output
	END
 

	-- ORiginal posted hrs will be changed to overtime
	SELECT @hrs = @postedhrs

	--#126931 replaced get seq# AND INSERT bPRTB code WITH call to vspPRTBAddCEntry
	SELECT @otamt = @hrs * @otrate
	EXEC @rcode = vspPRTBAddCEntry  
					@co,   
					@prgroup,   
					@prenddate,   
					@mth,   
					@batchid,   
					@prtbud_flag,
					@employee,   
					@payseq,   
					@postseq,   
					@daynum,   
					'N',   
					'Y',   
					@otrate,   
					@otamt,   
					@otearncode,   
					'Y',   
					@hrs,   
					@msg OUTPUT
	IF @rcode = 2 
	BEGIN
		SELECT @msg = 'Unable to add UPDATEd overtime entry to Timecard batch.'
		RETURN 1
	END

	SELECT @PRTBAddedYN = 'Y' --#29635
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[bspPRAutoOTPost] TO [public]
GO
