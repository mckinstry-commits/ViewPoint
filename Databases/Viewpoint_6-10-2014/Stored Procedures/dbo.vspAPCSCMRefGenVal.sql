SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAPCSCMRefGenVal    Script Date: 4/02/12 9:32:34 AM ******/
CREATE    proc [dbo].[vspAPCSCMRefGenVal]
/*************************************
* Created by:	EN 04/02/12 - B-08617/TK-13167
* Modified by:	KK 04/04/12 - B-08616/TK-12875 Modified to run from AP Credit Service Export File Generate form code. 
*											   Checks for special characters nnd/or non-numeric entries.
*											   Begins with "1" when searching for next valid CM Ref if user enters non-numeric 
*
* Usage:
*	Called from CreditServiceProcessing.cs routines in CreditService_Data_Processing in the data layer APCommon
*
*	The objective of the Unique Payment ID Generator is to find the first available CM Ref # based on 
*	the combination of entries in bAPPB, bAPPH and bCMDT with a potential beginning reference point 
*	provided by the user.
*
*	The Generator searches the 3 tables for entries matching the specified CM Company and CM Account.  
*	The bAPPB and bAPPH tables are searched for entries with Pay Method 'S' while bCMDT is searched for 
*	entries with CM Trans Type '4'.  Up until now CM Trans Type '4' has been for EFT payments but it has 
*	been deemed to not be a problem sharing with Credit Service payments since a unique Credit Service 
*	CM Account will be used.
*
* Suggested tests:
*	1) pass in a null requestedcmref where no records exist for the cmco/cmacct ... nextcmref should return 1
*	2) pass in a requestedcmref where no records exist for the cmco/cmacct ... nextcmref should return requestedcmref
*	3) pass in a null requestedcmref where records exist for the cmco/cmacct and cmref 1 is NOT in use ... nextcmref should return 1
*	4) pass in a null requestedcmref where records exist for the cmco/cmacct and cmref 1 IS in use ... nextcmref should return the first available cmref
*	5) pass in a requestedcmref that exists for the cmco/cmacct ... nextcmref should return the next available cmref to come after the requestedcmref
*	6) pass in a requestedcmref that does not exist for the cmco/cmacct ... nextcmref should return requestedcmref 
*	7) pass in month and batchid of an existing batch with a CMRef passing the CMRef in using requestedcmref that exists in the specified batch ... nextcmref should return requestedcmref
*	8) pass in month and batchid of an existing batch with a CMRef passing the CMRef in using requestedcmref that DOES NOT exist in the specified batch ... nextcmref should return next available cmref to come after the requestedcmref
*	9) all available CMRef numbers are in use ... nextcmref should return null
*
* Input params:
*	@cmco		CM Company #
*	@cmacct		CM Account 
*	@begincmref	CM Ref # to use as beginning reference point for validation/next available CM Ref# search
*	@overlookbatch	='Y' when @mth and @batchid are used to ignore a batch when searching for unique CM Ref#
*	@mth		Month of batch to ignore when searching for unique CM Ref#
*	@batchid	Batch ID to ignore when searching for unique CM Ref#
*
* Output params:
*	@nextcmref	next unique CM Ref#
*				if no @begincmref was specified this will be the first available CM Ref#
*				if @begincmref was specified and not already in use, this will equal @begincmref
*				if @begincmref was specified and IS already in use, this will be the next available CM Ref# and an error will be returned
*	@msg		Error message
*
* Return code:
*	0=success, 1=failure
**************************************/
(@cmco bCompany,
 @cmacct bCMAcct = NULL, 
 @begincmref bCMRef = NULL,
 @overlookbatch bYN = NULL,
 @mth bMonth = NULL,
 @batchid bBatchID = NULL,
 @nextcmref bCMRef OUTPUT,
 @msg varchar(255) OUTPUT)	
 
AS
SET NOCOUNT ON
	
DECLARE @fromcmref bigint

IF @overlookbatch = 'Y'
BEGIN
	--user plans to override CMRef's for the indicated mth and batchid so confirm that they were provided
	IF @mth IS NULL OR @batchid IS NULL
	BEGIN
		SELECT @msg = 'Month and BatchId to override have not been provided'
		RETURN 1
	END
END
ELSE IF @overlookbatch = 'N'
BEGIN
	--user does not plan to override CMRef's for the batch so set input month and batchid to NULL to ensure that
	--all existing CMRef's are searched to ensure uniqueness of the provided CMRef
	SELECT @mth = NULL, @batchid = NULL
END

SELECT @begincmref = LTRIM(RTRIM(@begincmref))
--User did not enter a numeric value, or included invalid characters 
IF @begincmref IS NOT NULL 
   AND(   ISNUMERIC(@begincmref) = 0 
	   OR CHARINDEX('+',@begincmref) > 0
	   OR CHARINDEX('-',@begincmref) > 0
	   OR CHARINDEX('.',@begincmref) > 0
	   OR CHARINDEX(' ',@begincmref) > 0
	   OR CHARINDEX('$',@begincmref) > 0)
BEGIN --start with 1
	SELECT @fromcmref = 1
END
--User did not specify a CM Ref to try
ELSE
BEGIN --start with 1
	SELECT @fromcmref = CONVERT(bigint, ISNULL(@begincmref, '1'))
END

--If the user specified a requested cmref and it is not already in use, return that cmref.  
--If the requested cmref IS already in use in all other cases, find the next available cmref

--the first "IF" condition determines if requestedcmref does not exist in bAPPB, bAPPH or bCMDT
-- includes option to ignore existence of requestedcmref in bAPPB for a specified month/batchid
IF NOT EXISTS 
	(
	 SELECT NULL 
	 FROM dbo.bAPPB 
	 WHERE	CMCo = @cmco AND 
			PayMethod = 'S' AND 
			CMAcct = @cmacct AND 
			CMRef IS NOT NULL AND 
			ISNUMERIC(CMRef) = 1 AND 
			CMRef = STR(@fromcmref, 10) AND
			NOT (
				 (@mth IS NOT NULL AND Mth = @mth) AND 
				 (@batchid IS NOT NULL AND BatchId = @batchid)
				) 
	 UNION
	 SELECT NULL 
	 FROM dbo.bAPPH 
	 WHERE	CMCo = @cmco AND 
			PayMethod = 'S' AND 
			CMAcct = @cmacct AND 
			CMRef IS NOT NULL AND 
			ISNUMERIC(CMRef) = 1 AND 
			CMRef = STR(@fromcmref, 10)
	 UNION
	 SELECT NULL
	 FROM dbo.bCMDT
	 WHERE	CMCo = @cmco AND 
			CMTransType = '4' AND 
			CMAcct = @cmacct AND 
			ISNUMERIC(CMRef) = 1 AND 
			CMRef = STR(@fromcmref, 10)
	)
BEGIN
	SELECT @nextcmref = STR(@fromcmref, 10)
END
--this "ELSE" gets hit if the requestedcmref is in use or there was no requestedcmref
--this condition results in finding the next available cmref
ELSE
BEGIN
	;
	WITH CMRefList(CMCo, CMAcct, CMRef)
	AS
	(
		SELECT CMCo, CMAcct, CMRef 
		FROM dbo.bAPPB 
		WHERE	CMCo = @cmco AND 
				PayMethod = 'S' AND 
				CMAcct = @cmacct AND 
				CMRef IS NOT NULL AND 
				ISNUMERIC(CMRef) = 1 AND 
				CMRef >= STR(@fromcmref, 10)
		UNION
		SELECT CMCo, CMAcct, CMRef 
		FROM dbo.bAPPH 
		WHERE	CMCo = @cmco AND 
				PayMethod = 'S' AND 
				CMAcct = @cmacct AND 
				CMRef IS NOT NULL AND 
				ISNUMERIC(CMRef) = 1 AND 
				CMRef >= STR(@fromcmref, 10)
		UNION
		SELECT CMCo, CMAcct, CMRef
		FROM dbo.bCMDT
		WHERE	CMCo = @cmco AND 
				CMTransType = '4' AND 
				CMAcct = @cmacct AND 
				ISNUMERIC(CMRef) = 1 AND 
				CMRef >= STR(@fromcmref, 10)
	)

	--find the first available cmref from the union of bAPPB and bAPPH defaulting to 1 if no records exist
	SELECT @nextcmref = (CASE WHEN MIN(t.CMRef) IS NULL 
							  THEN '1' 
							  ELSE CONVERT(varchar(10), CONVERT(bigint, MIN(t.CMRef)) + 1) 
						 END)
	FROM CMRefList t 
	WHERE NOT EXISTS 
			(
			 SELECT NULL FROM CMRefList n WHERE n.CMRef = STR(CONVERT(varchar(10), CONVERT(bigint, t.CMRef) + 1), 10)
			)
END

--ALL CM Reference numbers are in use
IF @nextcmref IS NULL
BEGIN
	SELECT @msg = 'All CM Reference numbers are in use.'
	SELECT @nextcmref = ''
END

--Right-justify the generated CM Ref
SELECT @nextcmref = STR(CONVERT(bigint, @nextcmref), 10)

--User requested a non-numeric CM Ref, we return the next valid CM Ref available.
IF @begincmref IS NOT NULL AND ( ISNUMERIC(@begincmref) = 0 
								   OR CHARINDEX('+',@begincmref) > 0
								   OR CHARINDEX('-',@begincmref) > 0
								   OR CHARINDEX('.',@begincmref) > 0
								   OR CHARINDEX(' ',@begincmref) > 0
								   OR CHARINDEX('$',@begincmref) > 0)
BEGIN
	SELECT @msg = 'Your requested CM Reference is not numeric. The next available numeric CM Reference is ' + CONVERT(varchar, @nextcmref) + ' '
END
--The user requested CM Ref is in use, we return the next valid CM Ref available.
ELSE IF (@begincmref IS NOT NULL) AND STR(CONVERT(bigint, @begincmref), 10) <> @nextcmref
BEGIN
	SELECT @msg = 'Requested CM Reference is not available. The next available CM Reference is ' + CONVERT(varchar, @nextcmref) + ' '
END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspAPCSCMRefGenVal] TO [public]
GO
