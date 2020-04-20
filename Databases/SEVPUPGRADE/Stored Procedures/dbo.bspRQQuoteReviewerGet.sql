SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROCEDURE [dbo].[bspRQQuoteReviewerGet]
    /************************************************************
    *Created: 	GWC 09/26/2004
    *Modified:	DC #130129 - Combine RQ and PO into a single module
    *			GF 09/09/2010 - issue #141031 changed to use function vfDateOnly
    * 
    *Usage:
    *	Adds default Reviewer(s) to bRQQR based on information from Quote and Company 
    *
    *Inputs:
    *	@co				RQ Co#
    *	@quote			Quote #
    *	@quoteline		Quote Line#
    *	@totalcost		Total Cost	
    *************************************************************/
    (@rqco bCompany, @quote int, @quoteline int, @totalcost bDollar, @msg varchar(255) output)
    
    AS
     
    SET NOCOUNT ON
    
    DECLARE @rcode int
    
    SELECT @rcode = 0
    
    IF @rqco IS NULL
    	BEGIN
    	SELECT @msg = 'Missing Company', @rcode = 1
    	GOTO bspexit
    	END
    
    IF @quote IS NULL
    	BEGIN
    	SELECT @msg = 'Missing Quote', @rcode = 1
    	GOTO bspexit
    	END
    
    IF @quoteline IS NULL
    	BEGIN
    	SELECT @msg = 'Missing Quote Line', @rcode = 1
    	GOTO bspexit
    	END
    
   
    --Add Review for Quote Reviewer if a Quote Reviewer has been entered in RQCo
    INSERT RQQR (RQCo, Quote, QuoteLine, Reviewer, AssignedDate, Status)
    	SELECT @rqco, @quote, @quoteline, r.PurchaseReviewer, dbo.vfDateOnly(), 0 ----#141031
    	FROM POCO r WITH (NOLOCK) WHERE r.POCo = @rqco --DC #130129
    	AND r.PurchaseReviewer IS NOT NULL AND r.PurchaseReviewer NOT IN (SELECT Reviewer 
    	FROM RQQR WITH (NOLOCK) WHERE RQCo = @rqco AND Quote = @quote AND QuoteLine = @quoteline)
   
    
    --Add Threshold Reviewer if route = Purchase and Total Cost is greater then Threshold amount
    IF EXISTS (SELECT TOP 1 1 FROM POCO WITH (NOLOCK) WHERE Threshold IS NOT NULL AND POCo = @rqco)  --DC #130129
    	BEGIN
    	IF @totalcost > (SELECT Threshold FROM POCO WITH (NOLOCK) WHERE POCo = @rqco)  --DC #130129
    		BEGIN
    		INSERT RQQR (RQCo, Quote, QuoteLine, Reviewer, AssignedDate, Status)
    			SELECT @rqco, @quote, @quoteline, r.ThresholdReviewer, dbo.vfDateONly(), 0 ----#141031
    			FROM POCO r WITH (NOLOCK) WHERE r.POCo = @rqco --DC #130129
    			AND r.ThresholdReviewer IS NOT NULL AND r.ThresholdReviewer 
    			NOT IN (SELECT Reviewer FROM RQQR WITH (NOLOCK) WHERE RQCo = @rqco 
    			AND Quote = @quote AND QuoteLine = @quoteline)
    		END
    	END
     
    RETURN @rcode
    
    bspexit:
        IF @rcode <> 0 
    		BEGIN
    		SELECT @msg = ISNULL(@msg,'')
    		END
    	
    	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRQQuoteReviewerGet] TO [public]
GO
