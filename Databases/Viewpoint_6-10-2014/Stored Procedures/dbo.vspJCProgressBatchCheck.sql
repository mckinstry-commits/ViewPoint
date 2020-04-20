SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****************************************************************************/
CREATE  proc [dbo].[vspJCProgressBatchCheck]
/****************************************************************************
 * Created By:	DANF 03/08/07
 * Modified By:	GP 06/13/2008 - Issue 128607, added @FormMode as input parameter. Check for mode
 *									condition before validating BatchSeq. If @FormMode = Update make
 *									sure @BatchSeq <> BatchSeq. 
 *				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
 *				SCOTTP 03/22/13 - TFS44545 - Pass in ActualDate and use the value when getting the Batch Seq record
 *
 *
 * USAGE:
 * Used to retrieve the Batch Seq for a given 
 * Co, Month, BatchId, Job, PhaseGroup, CostType, PRCo, Crew.
 *
 *
 * OUTPUT PARAMETERS:
 * BatchSeq and Message
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@Co bCompany = null, @Mth bMonth = null, @BatchId bBatchID = null, @Job bJob = null, 
 @PhaseGroup bGroup = null, @Phase bPhase = null, @CostType bJCCType = null, @PRCo bCompany = null, 
 @ActualDate bDate = null, @Crew varchar(10) = null, @FormMode char(1) = null,
 @BatchSeq int = null output, @ActualUnits bUnits output, @ProgressCmplt bPct output, @msg varchar(255) output)

as
set nocount on
--#142350 removing @phasegroup
DECLARE @rcode int

select @rcode = 0

 if @Co is null goto bspexit 
 if @Mth is null goto bspexit 
 if @BatchId is null goto bspexit 
 if @Job is null goto bspexit 
 if @PhaseGroup is null goto bspexit 
 if @Phase is null goto bspexit 
 if @CostType is null goto bspexit 
 if @ActualDate is null goto bspexit
 
IF @FormMode = 'A' -- Issue 128607
BEGIN

	-- When JCProgressEntry is in Add mode look for matching record without BatchSeq.
	select top 1 @BatchSeq = BatchSeq, @ActualUnits = ActualUnits, @ProgressCmplt = ProgressCmplt
	from bJCPP 
	where	Co = @Co and Mth = @Mth and BatchId = @BatchId and 
			Job = @Job and PhaseGroup = @PhaseGroup and Phase = @Phase and CostType = @CostType and 
			ActualDate = @ActualDate and isnull(PRCo, 0) = isnull(@PRCo,0) and isnull(Crew,'') = isnull(@Crew,'')
	if @@rowcount <> 0 
		begin
		select @rcode = 1
		if @BatchSeq <> 0 and @ActualUnits = 0 and @ProgressCmplt = 0
			begin
			delete bJCPP where	Co = @Co and Mth = @Mth and BatchId = @BatchId and BatchSeq = @BatchSeq and ActualDate = @ActualDate
			end
		end	
	
END
ELSE
BEGIN

	-- In Update mode look for matching record with BatchSeq.
	select top 1 @BatchSeq = BatchSeq, @ActualUnits = ActualUnits, @ProgressCmplt = ProgressCmplt
	from bJCPP 
	where	Co = @Co and Mth = @Mth and BatchId = @BatchId and 
			Job = @Job and PhaseGroup = @PhaseGroup and Phase = @Phase and CostType = @CostType 
			and ActualDate = @ActualDate and isnull(PRCo, 0) = isnull(@PRCo,0) and isnull(Crew,'') = isnull(@Crew,'')
			and BatchSeq <> @BatchSeq
	if @@rowcount <> 0 
		begin
		select @rcode = 1
		if @BatchSeq <> 0 and @ActualUnits = 0 and @ProgressCmplt = 0
			begin
			delete bJCPP where	Co = @Co and Mth = @Mth and BatchId = @BatchId and BatchSeq = @BatchSeq and ActualDate = @ActualDate
			end
		end			

END



bspexit:
   	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspJCProgressBatchCheck] TO [public]
GO
