SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE       procedure [dbo].[bspEMLBInDateVal]
/***********************************************************
* CREATED BY: 	bc 03/19/01
* MODIFIED By :  bc 08/06/01 - Added validation to make sure that no two transfers for a piece of equipment have
*                              the same DateIn/TimeIn combination
*				TV 02/11/04 - 23061 added isnulls	
*				TV 04/01/04 22744 needs to make sure that it is not comparing itself TV 040104 22744
*				GF 08/09/2012 TK-11882 when validating Date/Time In possible that the time is null for start of day
*				GF 01/08/2013 TK-20651 validation added to check earlier date/time in for equip with different from info
* 
*
* USAGE:  the DateIn/TimeIn entered must be after the date in of the most recent transfer in EMLH
*         unless a valid DateOut/TimeOut is supplied.  a valid DateOut/TimeOut must be less than or equal to
*         the most recent transfers DateIn/TimeIn
*
*
*
* INPUT PARAMETERS
* @EMCo        EM Company
* @Mth			EM Batcn Month
* @BatchId		EM Batch Id
* @Seq			EM Batch Sequence
* @Equip		EM Equipment
* @datein		DateIn
* @timein		TimeIn
* @dateout		DateOut
* @timeout		TimeOUt
*
*
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@emco bCompany, @mth bMonth, @batchid bBatchID, @seq int,
@equip bEquip = NULL, @datein bDate = NULL, @timein smalldatetime = NULL,
----TK-20651
@FromJCCo bCompany = NULL, @FromJob bJob = NULL, @FromLoc VARCHAR(10) = NULL,
@dateout bDate = NULL, @timeout SMALLDATETIME = NULL,
@msg varchar(255) output

as
set nocount on
 
declare @rcode int, @max_mth bMonth, @max_trans bTrans, @emlh_datein bDate,
		@emlh_timein smalldatetime, @cnt int,
		@trans bTrans
		----TK-11882
		,@EMLH_Mth bMonth, @EMLB_Mth bMonth, @EMLB_BatchId bBatchID
		,@EMLB_BatchSeq INT, @EMLH_Trans bTrans
		----TK-20651
		,@ToJCCo bCompany, @ToJob bJob, @ToLoc VARCHAR(10)


SET @rcode = 0

----TK-11882
SELECT @trans = MeterTrans
from dbo.bEMLB
WHERE Co = @emco
	AND Mth = @mth
	AND BatchId = @batchid
	AND BatchSeq = @seq


---- TK-11882 validate we have a date in - required
IF @datein IS NULL
	BEGIN
	SELECT @msg = 'Date In must not be empty.', @rcode = 1
	GOTO bspexit
	END

---- TK-11882 check EMLH location transfer history first for duplicate Date/Time In
---- time in may be null for start of day
IF @timein IS NULL
	BEGIN
	SELECT @EMLH_Trans = Trans, @EMLH_Mth = [Month]
	FROM dbo.EMLH
	WHERE EMCo = @emco
		AND Equipment = @equip
		AND DateIn = @datein
		AND TimeIn IS NULL 
		AND Trans <> ISNULL(@trans, -999)
	IF @@ROWCOUNT <> 0
		BEGIN
		SET @msg = 'The Transfer Date/Time in already exists in location history. Equipment: ' + dbo.vfToString(@equip) + ' Month: ' + dbo.vfToString(@EMLH_Mth) + ' Trans: ' + dbo.vfToString(@EMLH_Trans)
		SET @rcode = 1
		GOTO bspexit
		END
	END
ELSE
	BEGIN
	SELECT @EMLH_Trans = Trans, @EMLH_Mth = [Month]
	FROM dbo.EMLH
	WHERE EMCo = @emco
		AND Equipment = @equip
		AND DateIn = @datein
		AND TimeIn = @timein 
		AND Trans <> ISNULL(@trans, -999)
	IF @@ROWCOUNT <> 0
		BEGIN
		SET @msg = 'The Transfer Date/Time in already exists in location history. Equipment: ' + dbo.vfToString(@equip) + ' Month: ' + dbo.vfToString(@EMLH_Mth) + ' Trans: ' + dbo.vfToString(@EMLH_Trans)
		SET @rcode = 1
		GOTO bspexit
		END
	END

---- TK-11882 check EMLB location transfer batch for duplicate Date/Time In
---- not relevant which EMLB Month and Batch Id check all
---- time in may be null for start of day
IF @timein IS NULL
	BEGIN
	SELECT @EMLB_Mth = Mth, @EMLB_BatchId = BatchId, @EMLB_BatchSeq = BatchSeq
	FROM dbo.EMLB
	WHERE Co = @emco
		AND Equipment = @equip
		AND DateIn = @datein
		AND TimeIn IS NULL
		AND Mth = @mth
		AND BatchId = @batchid
		AND BatchSeq <> ISNULL(@seq, -999)
	IF @@ROWCOUNT <> 0
		BEGIN
		SET @msg = 'The Transfer Date/Time in already exists in a Location Transfer Batch. Month: ' + dbo.vfToString(@EMLB_Mth) + ' BatchId: ' + dbo.vfToString(@EMLB_BatchId) + ' Seq: ' + + dbo.vfToString(@EMLB_BatchSeq) + ' Equipment: ' + dbo.vfToString(@equip)
		SET @rcode = 1
		GOTO bspexit
		END
	END
ELSE
	BEGIN
	SELECT @EMLB_Mth = Mth, @EMLB_BatchId = BatchId, @EMLB_BatchSeq = BatchSeq
	FROM dbo.EMLB
	WHERE Co = @emco
		AND Equipment = @equip
		AND DateIn = @datein
		AND TimeIn = @timein
		AND Mth = @mth
		AND BatchId = @batchid
		AND BatchSeq <> ISNULL(@seq, -999)
	IF @@ROWCOUNT <> 0
		BEGIN
		SET @msg = 'The Transfer Date/Time in already exists in a Location Transfer Batch. Month: ' + dbo.vfToString(@EMLB_Mth) + ' BatchId: ' + dbo.vfToString(@EMLB_BatchId) + ' Seq: ' + + dbo.vfToString(@EMLB_BatchSeq) + ' Equipment: ' + dbo.vfToString(@equip)
		SET @rcode = 1
		GOTO bspexit
		END
	END
	


---- TK-11882 the Equipment, DateIn and TimeIn cannot be edited unless the Transaction is an Add
SELECT  @max_mth  = MAX([Month]),
		@max_trans = MAX(Trans)
FROM dbo.bEMLH
WHERE EMCo = @emco
	AND Equipment = @equip
	AND DateOut IS NULL

IF @max_mth IS NOT NULL AND @max_trans IS NOT NULL
	BEGIN
		select @emlh_datein = DateIn, @emlh_timein = TimeIn from bEMLH
		where EMCo = @emco and Equipment = @equip and Month = @max_mth and Trans = @max_trans
		
		if @emlh_datein > @datein and @max_trans <> @trans and--needs to make sure that it is not comparing itself TV 040104 22744
		((@dateout is null) or ((@dateout is not null) and ((@dateout > @emlh_datein) or
		(@dateout = @emlh_datein and isnull(@timeout,@dateout + '00:00') > isnull(@emlh_timein,@emlh_datein + '00:00') ))))
			begin
			select @msg = 'Date In must be after the most recent transfer unless a valid Date Out is supplied.', @rcode = 1
			goto bspexit
			end

		if @emlh_datein = @datein and isnull(@emlh_timein,@emlh_datein + '00:00') > isnull(@timein,@datein + '00:00') and
		((@dateout is null) or ((@dateout is not null) and ((@dateout > @emlh_datein) or 
		(@dateout = @emlh_datein and isnull(@timeout,@dateout + '00:00') > isnull(@emlh_timein,@emlh_datein + '00:00') ))))
			begin
			select @msg = 'Date and Time In must be after the most recent transfer unless a valid Date Out/Time Out is supplied.', @rcode = 1
			goto bspexit
			end

		/* if this transfer is earlier than the most recent transfer but the DateOut/TimeOut info is ok,
		warn them about the To and From locations needing to be sync'd up for perfect posting
		return @rcode of 2 for the warning */
		if ((@emlh_datein > @datein) or (@emlh_datein = @datein and isnull(@emlh_timein,@emlh_datein + '00:00') > isnull(@timein,@datein + '00:00') )) and	
		((@dateout is not null) and ((@dateout < @emlh_datein) or
		(@dateout = @emlh_datein and isnull(@timeout,@dateout + '00:00') <= isnull(@emlh_timein,@emlh_datein + '00:00') )))
			begin
			select @msg = 'Warning!  Manual adjustments must be made to correct From and To information on the transfers surrounding this transfer.'
			select @rcode = 2
			goto bspexit
			end
	END
  
  
---- TK-20651 validate that the from information has not been changed if there is an earlier
---- transfer in the batch for the equipment. If we have 2 batch entries for the equipment
---- with the from changed for the second different from the first we will end up with mulitple
---- EMLH records with no out data, not good.  
IF @timein IS NULL
	BEGIN
	SELECT TOP 1 @ToJCCo = ToJCCo,
			@ToJob = ToJob,
			@ToLoc = ToLocation,
			@EMLB_BatchSeq = BatchSeq
	FROM dbo.EMLB WITH (NOLOCK)
	WHERE Co = @emco
		AND Equipment = @equip
		AND DateIn < @datein
		AND Mth = @mth
		AND BatchId = @batchid
		AND BatchSeq <> ISNULL(@seq, -999)
	ORDER BY DateIn DESC, TimeIn DESC
	IF @@ROWCOUNT <> 0
		BEGIN
		IF ISNULL(@ToJCCo,0) <> ISNULL(@FromJCCo,0)
			OR ISNULL(@ToJob,'') <> ISNULL(@FromJob,'')
			OR ISNULL(@ToLoc,'') <> ISNULL(@FromLoc,'')
			BEGIN
			SELECT @msg = 'Invalid Transfer. An Earlier transfer exists in batch for equipment with the To JCCo: ' + dbo.vfToString(@ToJCCo) + ' To Job: ' + dbo.vfToString(@ToJob) + ' To Location: ' + dbo.vfToString(@ToLoc) + '.'
			SELECT @msg = @msg + ' This transfer from information must match the earlier to information.'
			SET @rcode = 1
			GOTO bspexit
			END
		END          
	END
ELSE
	BEGIN
	SELECT TOP 1 @ToJCCo = ToJCCo,
			@ToJob = ToJob,
			@ToLoc = ToLocation,
			@EMLB_BatchSeq = BatchSeq
	FROM dbo.EMLB WITH (NOLOCK)
	WHERE Co = @emco
		AND Equipment = @equip
		AND DateIn <= @datein
		AND TimeIn < @timein
		AND Mth = @mth
		AND BatchId = @batchid
		AND BatchSeq <> ISNULL(@seq, -999)
	ORDER BY DateIn DESC, TimeIn DESC
	IF @@ROWCOUNT <> 0
		BEGIN
		IF ISNULL(@ToJCCo,0) <> ISNULL(@FromJCCo,0)
			OR ISNULL(@ToJob,'') <> ISNULL(@FromJob,'')
			OR ISNULL(@ToLoc,'') <> ISNULL(@FromLoc,'')
			BEGIN
			SELECT @msg = 'Invalid Transfer. An Earlier transfer exists in batch for equipment with the To JCCo: ' + dbo.vfToString(@ToJCCo) + ' To Job: ' + dbo.vfToString(@ToJob) + ' To Location: ' + dbo.vfToString(@ToLoc) + '.'
			SELECT @msg = @msg + ' This transfer from information must match the earlier to information.'
			SET @rcode = 1
			GOTO bspexit
			END
		END          
	END  





bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMLBInDateVal] TO [public]
GO
