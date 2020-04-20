SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMAddJCTrans Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[vspJBTandMUpdateJBIT]
/***********************************************************
* CREATED BY:  TJL 07/31/08 - Issue #129862, JB International Sales Tax
* MODIFIED BY: TJL 01/06/09 - Issue #129896, Update JBIT UnitsClaimed and AmtClaimed
*		TJL 10/29/10 - Issue #140468, JBIT not update when Total Addon using separate Item gets deleted from JBIL
*		TJL 03/15/11 - Issue #142999, Do not delete JBIT records if Contract Item is B-Both type and T&M Lines get deleted.
*		KK 06/27/11 - TK-06428 Issue #143634, Do not delete JBIT records EVER
*
* USED IN:
*
*	bspJBTandMInit
*	JBIL insert/update/delete triggers
*
* USAGE:
*
*	When Auto initializing T&M bills, in an effort to avoid continuous updates to JBIT 
*	for each JC Transaction being processed, we call this procedure one time only
*	for each Contract processed.  The same procedure call in JBIL triggers gets suspended,
*   during auto initialization by setting JBIN.TMUpdateAddonYN flag to 'N' during the process. 
*	At other times,	(when individual changes to a bill are being made) this update to JBIT is called
*	directly from the JBIL triggers. 
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @errmsg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
(@co bCompany, 
 @mth bMonth, 
 @billnum int, 
 @contract bContract = NULL, 
 @item bContractItem = NULL, 
 @errmsg varchar(275) OUTPUT)
AS

SET NOCOUNT ON
   
DECLARE @openJBITcursor int, 
		@amtbilled bDollar, 
		@retainage bDollar, 
		@retgtax bDollar,
		@retgrel bDollar, 
		@taxbasis bDollar, 
		@taxamount bDollar, 
		@discount bDollar, 
		@unitprice bUnitCost,
		@jbcousecertified bYN, 
		@jbinbillcertified bYN, 
		@setclaimed bYN

SELECT @retgrel = 0, 
	   @setclaimed = 'N',
	   @errmsg = NULL
	   
/* Validate bill month and number and free up if open */
IF @mth IS NULL
BEGIN
	SELECT @errmsg = 'Missing BillMonth.'
	IF @openJBITcursor = 1
	BEGIN
		CLOSE bJBITItem
		DEALLOCATE bJBITItem
		SELECT @openJBITcursor = 0
	END
	RETURN 1
END
IF @billnum IS NULL
BEGIN
	SELECT @errmsg = 'Missing Bill Number.'
		IF @openJBITcursor = 1
	BEGIN
		CLOSE bJBITItem
		DEALLOCATE bJBITItem
		SELECT @openJBITcursor = 0
	END
	RETURN 1
END

/* Get some supporting information. */
SELECT @jbcousecertified = o.UseCertified, 
	   @jbinbillcertified = n.Certified
	   FROM bJBIN n WITH (NOLOCK)
	   JOIN bJBCO o WITH (NOLOCK) on o.JBCo = n.JBCo
	   WHERE n.JBCo = @co 
	     AND n.BillMonth = @mth 
	     AND n.BillNumber = @billnum

IF @jbcousecertified = 'Y' AND @jbinbillcertified = 'N' SELECT @setclaimed = 'Y'

/* Contract bill:  Called from JBIL Triggers. */
IF @contract IS NOT NULL AND @item IS NOT NULL
BEGIN
	SELECT @unitprice = CASE WHEN UM <> 'LS' 
							 THEN UnitPrice 
							 ELSE 0
						END 
	FROM bJCCI WITH (NOLOCK)
	WHERE JCCo = @co 
	  AND Contract = @contract 
	  AND Item = @item

	IF EXISTS(SELECT TOP 1 1 FROM bJBIL WITH (NOLOCK) 
			  WHERE JBCo = @co AND BillMonth = @mth 
							   AND BillNumber = @billnum 
							   AND Item = @item)
	BEGIN
		/* Get values FROM JBIL for all Lines */
		SELECT @amtbilled = (SELECT ISNULL(SUM(Total),0) FROM bJBIL WITH (NOLOCK)
							 WHERE JBCo = @co 
							   AND BillMonth = @mth 
							   AND BillNumber = @billnum 
							   AND Item = @item
							   AND (LineType NOT IN ('D','T') OR 
								   (LineType IN ('D', 'T') AND MarkupOpt NOT IN ('T', 'X')))),
		@retainage = ISNULL(SUM(Retainage),0),
		@retgtax = (SELECT ISNULL(SUM(Total),0) FROM bJBIL WITH (NOLOCK)
					WHERE JBCo = @co 
					  AND BillMonth = @mth 
					  AND BillNumber = @billnum 
					  AND Item = @item 
					  AND LineType IN ('D', 'T') 
					  AND MarkupOpt = 'X'),
		@taxbasis = (SELECT ISNULL(SUM(Basis),0) FROM bJBIL WITH (NOLOCK)
					 WHERE JBCo = @co 
					   AND BillMonth = @mth 
					   AND BillNumber = @billnum 
					   AND Item = @item
					   AND LineType IN ('D', 'T') 
					   AND MarkupOpt = 'T'),
		@taxamount = (SELECT ISNULL(SUM(Total),0) FROM bJBIL WITH (NOLOCK)
					  WHERE JBCo = @co 
						AND BillMonth = @mth 
						AND BillNumber = @billnum 
						AND Item = @item
						AND LineType IN ('D', 'T') 
						AND MarkupOpt = 'T'),
		@discount = ISNULL(SUM(Discount),0)
		FROM bJBIL WITH (NOLOCK)
		WHERE JBCo = @co 
		  AND BillMonth = @mth 
		  AND BillNumber = @billnum	
		  AND Item = @item

		/* Update JBIT accordingly.  There is no need to re-evaluate AR Company "Tax setup" here since all 
		values have already been recorded in JBIL based upon a particular Invoice tax setup. */
		UPDATE t
		SET t.AmtBilled = @amtbilled,
			t.RetgBilled = @retainage + @retgtax,
			t.RetgTax = @retgtax,
			t.TaxBasis = @taxbasis,
			t.TaxAmount = @taxamount,
			t.Discount = @discount,
			t.AmountDue = @amtbilled - @retainage + @taxamount + t.RetgRel,
			t.UnitsBilled = CASE WHEN ISNULL(@unitprice,0) = 0 
								 THEN 0
								 ELSE @amtbilled/@unitprice END,
			t.WC = @amtbilled,
			t.WCUnits = CASE WHEN ISNULL(@unitprice,0) = 0 
							 THEN 0
							 ELSE @amtbilled/@unitprice END,
			t.WCRetg = @retainage,
			t.WCRetPct = CASE WHEN @amtbilled = 0 
							  THEN j.RetainPCT 
							  ELSE @retainage/@amtbilled END,
			t.AmtClaimed = CASE WHEN @setclaimed = 'Y' 
								THEN @amtbilled 
								ELSE t.AmtClaimed END,
			t.UnitsClaimed = CASE WHEN @setclaimed = 'Y' 
							 THEN CASE WHEN ISNULL(@unitprice,0) = 0 
									   THEN 0
									   ELSE @amtbilled/@unitprice END 
							 ELSE t.UnitsClaimed END, 
			t.AuditYN = 'N'
		FROM bJBIT t
		JOIN bJCCI j ON j.JCCo = t.JBCo AND j.Contract = t.Contract AND j.Item = t.Item
		WHERE t.JBCo = @co 
		  AND t.BillMonth = @mth 
		  AND t.BillNumber = @billnum 
		  AND t.Item = @item

		UPDATE bJBIT 
		SET AuditYN = 'Y'
		WHERE JBCo = @co 
		  AND BillMonth = @mth 
		  AND BillNumber = @billnum 
		  AND Item = @item
	END
	ELSE
	BEGIN
	/* TK-06428(KK)- The JBIL line being deleted contains an Item that no longer exists anywhere in JBIL for this 
	   BillNumber; however, the corresponding Item in JBIT should not be removed/deleted. Update it in JBIT*/
		UPDATE t
		SET t.AmtBilled = 0,
			t.RetgBilled = 0,
			t.RetgTax = 0,
			t.TaxBasis = 0,
			t.TaxAmount = 0,
			t.Discount = 0,
			t.AmountDue = 0,
			t.UnitsBilled = 0,
			t.WC = 0,
			t.WCUnits = 0,
			t.WCRetg = 0,
			t.WCRetPct = 0,
			t.AmtClaimed = 0,
			t.UnitsClaimed = 0, 
			t.AuditYN = 'Y'
		FROM bJBIT t
		JOIN bJCCI j ON j.JCCo = t.JBCo AND j.Contract = t.Contract AND j.Item = t.Item
		WHERE t.JBCo = @co 
		  AND t.BillMonth = @mth 
		  AND t.BillNumber = @billnum 
		  AND t.Item = @item
	END
END

/* Contract bill:  Called from JBTandMinit.
   We must cycle through Items and Update JBIT which in turn updates JBIN */
IF @contract IS NOT NULL AND @item IS NULL
BEGIN
	DECLARE bJBITItem cursor local fast_forward FOR
	SELECT Item	
	FROM bJBIT WITH (NOLOCK)
	WHERE JBCo = @co 
	  AND BillMonth = @mth 
	  AND BillNumber = @billnum
	   
	OPEN bJBITItem
	SELECT @openJBITcursor = 1
	   
	FETCH NEXT FROM bJBITItem INTO @item	
	WHILE @@fetch_status = 0
   	BEGIN	
		SELECT @amtbilled = 0, 
			   @retainage = 0, 
			   @retgtax = 0, 
			   @taxbasis = 0, 
			   @taxamount = 0, 
			   @discount = 0	
		SELECT @unitprice = CASE WHEN UM <> 'LS' THEN UnitPrice ELSE 0 END
		FROM bJCCI WITH (NOLOCK)
		WHERE JCCo = @co AND Contract = @contract AND Item = @item

		IF EXISTS(SELECT TOP 1 1 FROM bJBIL WITH (NOLOCK)
			      WHERE JBCo = @co 
			        AND BillMonth = @mth 
			        AND BillNumber = @billnum 
			        AND Item = @item)
		BEGIN
			/* Get values from JBIL for all Lines */
			SELECT @amtbilled = (SELECT ISNULL(SUM(Total),0) FROM bJBIL WITH (NOLOCK)
								 WHERE JBCo = @co 
								   AND BillMonth = @mth 
								   AND BillNumber = @billnum 
								   AND Item = @item
								   AND (LineType NOT IN ('D','T') OR 
									   (LineType IN ('D', 'T') AND MarkupOpt NOT IN ('T', 'X')))),
				   @retainage = ISNULL(SUM(Retainage),0),
				   @retgtax = (SELECT ISNULL(SUM(Total),0) FROM bJBIL WITH (NOLOCK)
							   WHERE JBCo = @co 
							     AND BillMonth = @mth 
							     AND BillNumber = @billnum 
							     AND Item = @item 
        						 AND LineType IN ('D', 'T') AND MarkupOpt = 'X'),
				   @taxbasis = (SELECT ISNULL(SUM(Basis),0) FROM bJBIL WITH (NOLOCK)
								WHERE JBCo = @co 
								  AND BillMonth = @mth 
								  AND BillNumber = @billnum 
								  AND Item = @item
        						  AND LineType IN ('D', 'T') 
        						  AND MarkupOpt = 'T'),
				   @taxamount = (SELECT ISNULL(SUM(Total),0) FROM bJBIL WITH (NOLOCK)
								 WHERE JBCo = @co 
								   AND BillMonth = @mth 
								   AND BillNumber = @billnum 
								   AND Item = @item
        						   AND LineType IN ('D', 'T') 
        						   AND MarkupOpt = 'T'),
				   @discount = ISNULL(SUM(Discount),0)
   			FROM bJBIL WITH (NOLOCK)
			WHERE JBCo = @co 
			  AND BillMonth = @mth 
			  AND BillNumber = @billnum	
			  AND Item = @item

			/* Update JBIT accordingly.  There is no need to re-evaluate AR Company "Tax setup" here since all 
			   values have already been recorded in JBIL based upon a particular Invoice tax setup. */
  			UPDATE t
  			SET t.AmtBilled = @amtbilled,
    			t.RetgBilled = @retainage + @retgtax,
				t.RetgTax = @retgtax,
				t.TaxBasis = @taxbasis,
				t.TaxAmount = @taxamount,
    			t.Discount = @discount,
    			t.AmountDue = @amtbilled - @retainage + @taxamount + t.RetgRel,
				t.UnitsBilled = CASE WHEN ISNULL(@unitprice,0) = 0 
									 THEN 0
									 ELSE @amtbilled/@unitprice END,
    			t.WC = @amtbilled,
				t.WCUnits = CASE WHEN ISNULL(@unitprice,0) = 0 
								 THEN 0
								 ELSE @amtbilled/@unitprice END,
				t.WCRetg = @retainage,
				t.WCRetPct = CASE WHEN @amtbilled = 0 
								  THEN j.RetainPCT 
								  ELSE @retainage/@amtbilled END,
				t.AmtClaimed = CASE WHEN @setclaimed = 'Y' 
									THEN @amtbilled 
								    ELSE t.AmtClaimed END,
				t.UnitsClaimed = CASE WHEN @setclaimed = 'Y' 
									  THEN CASE WHEN ISNULL(@unitprice,0) = 0 
												THEN 0
												ELSE @amtbilled/@unitprice END 
									  ELSE t.UnitsClaimed END, 
				t.AuditYN = 'N'
 			FROM bJBIT t
			JOIN bJCCI j on j.JCCo = t.JBCo AND j.Contract = t.Contract AND j.Item = t.Item
			WHERE t.JBCo = @co 
			  AND t.BillMonth = @mth 
			  AND t.BillNumber = @billnum 
			  AND t.Item = @item

			UPDATE bJBIT 
			SET AuditYN = 'Y'
			WHERE JBCo = @co 
			  AND BillMonth = @mth 
			  AND BillNumber = @billnum 
			  AND Item = @item
			END
		FETCH NEXT FROM bJBITItem INTO @item
	END

	IF @openJBITcursor = 1
	BEGIN
		CLOSE bJBITItem
		DEALLOCATE bJBITItem
		SELECT @openJBITcursor = 0
	END
END

/* Non-Contract bill:  Called from JBTandMInit or JBIL triggers.
   Update JBIN directly */
IF @contract IS NULL AND @item IS NULL
BEGIN
	SELECT @amtbilled = (SELECT ISNULL(SUM(Total),0)FROM bJBIL WITH (NOLOCK)
						 WHERE JBCo = @co 
						   AND BillMonth = @mth 
						   AND BillNumber = @billnum
						   AND (LineType NOT IN ('D','T') OR 
							   (LineType IN ('D', 'T') AND MarkupOpt NOT IN ('T', 'X')))),
		   @retainage = ISNULL(SUM(Retainage),0),
		   @retgtax = (SELECT ISNULL(SUM(Total),0) FROM bJBIL WITH (NOLOCK)
					   WHERE JBCo = @co 
						 AND BillMonth = @mth 
						 AND BillNumber = @billnum
    					 AND LineType IN ('D', 'T') 
    					 AND MarkupOpt = 'X'),
		   @taxbasis = (SELECT ISNULL(SUM(Basis),0) FROM bJBIL WITH (NOLOCK)
						WHERE JBCo = @co 
						  AND BillMonth = @mth 
						  AND BillNumber = @billnum
    					  AND LineType IN ('D', 'T') 
    					  AND MarkupOpt = 'T'),
		   @taxamount = (SELECT ISNULL(SUM(Total),0) FROM bJBIL WITH (NOLOCK)
						 WHERE JBCo = @co 
						   AND BillMonth = @mth 
						   AND BillNumber = @billnum
						   AND LineType IN ('D', 'T') 
						   AND MarkupOpt = 'T'),
		   @discount = ISNULL(SUM(Discount),0)
	FROM bJBIL WITH (NOLOCK)
	WHERE JBCo = @co 
	  AND BillMonth = @mth 
	  AND BillNumber = @billnum

--	SELECT @retgrel = sum(RetgRel)
--	from bJBIT with (NOLOCK)
--	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum

	UPDATE bJBIN 
	SET InvTotal = @amtbilled,
		InvRetg = @retainage + @retgtax,
		RetgTax = @retgtax,
		TaxBasis = @taxbasis,
		InvTax = @taxamount,
		InvDue = @amtbilled - @retainage + @taxamount + @retgrel,-- +RetgRel: Cannot Release Retg on Non-Contract at this time
		InvDisc = @discount, 
		AuditYN = 'N'
	FROM bJBIN
	WHERE JBCo = @co 
	  AND BillMonth = @mth 
	  AND BillNumber = @billnum
    
	UPDATE bJBIN 
	SET AuditYN = 'Y'
	FROM bJBIN
	WHERE JBCo = @co 
	  AND BillMonth = @mth 
	  AND BillNumber = @billnum
END

RETURN 0



GO
GRANT EXECUTE ON  [dbo].[vspJBTandMUpdateJBIT] TO [public]
GO
