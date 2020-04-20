SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   procedure [dbo].[bspAPHBHeaderVal]
/***********************************************************
* CREATED BY:   SE 09/10/97
* MODIFIED By : SE 09/10/97
*               kb 10/28/02 - #18878 - fix double quotes
*				MV 11/26/03 - #23061 - isnull wrap
*				KK 01/17/12 - TK-11581 Modified to allow for Pay Method to be "S" per the Credit Service enhancement
*									   Reformatted code to meet standard practices
*				CHS	05/30/2012	- B-08928 make 1099 changes to Australia
*				MV 06/11/12 - TK-15560 fixed logic for V1099Box and Country = US
*				GF 05/14/2013 TFS-47315 no 1099 type for CA also
*
* USAGE:
* Validates header information of an Invoice 
*
* USED IN :
*   APHBVal  
*
* PASS IN
*   Co           AP Company
*   Mth          Batch Month
*   BatchId      BatchID
*   ErrorStart   If error add this to error string
*   PayMethod    Payment Method
*   PrepaidYN    Is this prepaid or not
*   Prepaiddate  Prepaid Date
*   PrepaidMth	 If prepaid the mth
*   PrepaidChk   If prepaid the check
*   CMAcct       CMAccount used in prepaid
*   V1099YN	  
*   V1099Type
*   V1099Box
* 
* OUTPUT PARAMETERS
*   ERRMSG       If error then message about error
*
* RETURNS
*   0 on SUCCESS if successfully validated and Error were able to be added to HQBE
*   1 on FAILURE, failure is only if faild to add error to HQBE
*
*****************************************************/ 
    
@co bCompany, 
@mth bMonth, 
@batchid bBatchID, 
@errorstart varchar(100),
@holdcode bHoldCode, 
@paymethod char(1), 
@prepaidyn bYN, 
@prepaiddate bDate, 
@prepaidmth bMonth,
@prepaidchk bCMRef, 
@cmacct bCMAcct, 
@v1099yn bYN, 
@v1099type varchar(10),
@v1099box tinyint, 
@errmsg varchar(255) OUTPUT
    
AS 
SET NOCOUNT ON
    
DECLARE @errortext varchar(255)
DECLARE @rcode int, @Country char(2), @FormType varchar(20)
/* 23061 wrap errorstart in isnull in case it comes in null */
SELECT @errortext = ''
IF @errorstart IS NULL
BEGIN
	SELECT @errorstart = ''
END

SELECT @Country = DefaultCountry FROM bHQCO h WHERE h.HQCo = @co

SET @FormType = '1099'
    
 /* validate hold code */
IF NOT @holdcode IS NULL
BEGIN
	EXEC @rcode = bspHQHoldCodeVal @holdcode, @msg=@errmsg OUTPUT
	IF @rcode <> 0 
    BEGIN
		SELECT @errortext = @errorstart + isnull(@errmsg,'')
		EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
		IF @rcode <> 0 RETURN 0
	END
END
    	    
/* Validate Payment method, can be C(Check), M(Manual), E(EFT) or S(Credit Service), if Prepaid must be C */
IF NOT (@paymethod in ('C', 'M', 'E', 'S')) 
BEGIN
	SELECT @errortext = @errorstart + 'payment method must be C, M, or E'
	EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
	IF @rcode <> 0 RETURN 0
END
 
/* If prepaid, then a number of things must be true */
IF @prepaidyn='Y'
BEGIN
	IF @paymethod<>'C' 
    BEGIN
		SELECT @errortext = @errorstart + 'payment method must be (C)heck for prepaids!'
		EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
		IF @rcode <> 0 RETURN 0
    END
     
	IF @prepaiddate IS NULL 
    BEGIN
		SELECT @errortext = @errorstart + 'must have paid date for prepaids!'
	    EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
		IF @rcode <> 0 RETURN 0
    END

	IF @prepaidmth IS NULL 
    BEGIN
		SELECT @errortext = @errorstart + 'must have paid month for prepaids!'
		EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
		IF @rcode <> 0 RETURN 0
    END
        
	IF @prepaidchk IS NULL 
    BEGIN
		SELECT @errortext = @errorstart + 'must have check for prepaid invoice!'
		EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
		IF @rcode <> 0 RETURN 0
    END
        
	IF @cmacct IS NULL 
   	BEGIN
		SELECT @errortext = @errorstart + 'must have CM Account for prepaid invoice!'
		EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
		IF @rcode <> 0 RETURN 0
    END
END  /*prepaid */

ELSE /*if not prepaid then cannot have value in Paid date , praid mtm */
BEGIN
	IF NOT @prepaiddate IS NULL 
    BEGIN
		SELECT @errortext = @errorstart + 'paid date only valid for prepaid invoices!'
		EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
		IF @rcode <> 0 RETURN 0
    END

	IF NOT @prepaidmth IS NULL 
    BEGIN
		SELECT @errortext = @errorstart + 'paid month only valid for prepaid invoices!'
		EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
		IF @rcode <> 0 RETURN 0
    END
       
	IF NOT @prepaidchk IS NULL 
    BEGIN
		SELECT @errortext = @errorstart + 'check is only valid for prepaid invoice!'
		EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
		IF @rcode <> 0 RETURN 0
    END
END /* not prepaid */

/* now validate 1099 */
IF @v1099yn = 'N' 
BEGIN
	IF NOT @v1099type IS NULL
	BEGIN
		SELECT @errortext = @errorstart + @FormType + ' type is only valid on ' + @FormType + ' invoices.'
	    EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
	    IF @rcode <> 0 RETURN 0
	END
	      
	IF NOT @v1099box IS NULL
	BEGIN
		SELECT @errortext = @errorstart + @FormType + ' box is only valid on ' + @FormType + ' invoices.'
	    EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
	    IF @rcode <> 0 RETURN 0
	END
END /*v1099*/ 

ELSE /*v1099 is Yes*/
BEGIN
	----TFS-47315
	IF @v1099type IS NULL AND @Country = 'US'
	BEGIN
		SELECT @errortext = @errorstart + 'must have ' + @FormType + ' type if total is included on ' + @FormType + ' invoices.'
	    EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
	    IF @rcode <> 0 RETURN 0
	END
	   
	IF (@v1099box IS NULL AND @Country = 'US') --CHS	05/30/2012	- B-08928 make 1099 changes to Australia
	BEGIN
		SELECT @errortext = @errorstart + 'must have ' + @FormType + ' box if total is included on ' + @FormType + ' invoices.'
	    EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
	    IF @rcode <> 0 RETURN 0
	END
END /*v1099 else*/

/*if we got this far return success */
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspAPHBHeaderVal] TO [public]
GO
