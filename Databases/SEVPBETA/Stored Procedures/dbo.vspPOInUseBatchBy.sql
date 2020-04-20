SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[vspPOInUseBatchBy]
/**************************************************************
* Created: Dan So 09/26/2011 - TK-08576 - allow Distribution Line updates 
* Modified: Dan So 10/19/2011 - D-03270 - implement 6.4.1 behavior
*			
*
* 6.4.1 -> called from frmPOItemDistribution_CanItemBeDistributed
*			If the PO Item is in a batch with a Source of POClose, POEntry, POChange
*			Then 
*				no updates to the Item are allowed
*				Return Error message - return 2
*			Else
*				Allow updates 
*				no error - return 0
*
* 6.5.0 -> *** THIS MAY CHANGE *** may be base on each PO Item Distribution Line
*
*
* Called from: frmPOItemDistribution
*
* Inputs:
*	@Co			Company
*	@Mth		Batch Month
*	@BatchID	Batch ID#
*
* Outputs:
*	@BatchInUseBy	User who has the batch
*	@errmsg			Error message
*
* Return Code:
*	@rcode		0 = success, 1 = error, 2 = success, but @CurrUser <> @BatchInUseBy
*
***************************************************************/
   
@Co bCompany = NULL, @Mth bMonth = NULL, @BatchID bBatchID = NULL, 
@errmsg varchar(255) output
   
   
AS
SET NOCOUNT ON
  
  
	DECLARE	@BatchInUseBy	bVPUserName,
			@Source			bSource,
			@rcode			int 

	----------------------------
	-- VERIFY INPUT PARAMTERS --
	----------------------------
	IF @Co IS NULL
		BEGIN
			SET @errmsg = 'Missing Company!'
			SET @rcode = 1
			GOTO vspExit
		END

	IF @Mth IS NULL
		BEGIN
			SET @errmsg = 'Missing Batch Month!'
			SET @rcode = 1
			GOTO vspExit
		END
		
	IF @BatchID IS NULL
		BEGIN
			SET @errmsg = 'Missing Batch ID!'
			SET @rcode = 1
			GOTO vspExit
		END
		

	------------------
	-- PRIME VALUES --
	------------------
	SET @rcode = 0
   	

	-- GET BATCH INFO --
	SELECT	@BatchInUseBy = ISNULL(InUseBy, 'N/A'), @Source = ISNULL(Source, 'N/A')
	  FROM	dbo.bHQBC
	 WHERE	Co = @Co
	   AND	Mth = @Mth
	   AND	BatchId = @BatchID
	   
	-- DETERMINE IF PO Item Distibution Line CAN BE UPDATED --
	IF @Source IN ('PO Entry  ', 'PO Close  ', 'PO Change ') -- bSource is type Char(10)
		BEGIN
			SET @errmsg = 'Cannot update PO Item Line!' + CHAR(13)+CHAR(10) +
			              'Locked in: ' + @Source + CHAR(13)+CHAR(10) +
			              'User: ' + @BatchInUseBy
			SET @rcode = 2
			GOTO vspExit
		END



-- RETURN --
	
vspExit:
   	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPOInUseBatchBy] TO [public]
GO
