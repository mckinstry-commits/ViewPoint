SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRQQuoteInit    Script Date: 6/9/2004 2:29:17 PM ******/
   CREATE PROCEDURE [dbo].[bspRQAddToQuoteLine]
   /***********************************************************
   *CREATED BY: 	GWC 04/26/04
   *MODIFIED BY:	 DC 12/04/08  #130129 - Combine RQ and PO into a single module
   *
   *PURPOSE:	
   *	Adds an RQ Line to a Quote Line if the RQ Line is the same material and the
   *	RQ Line is not currently on a PO, Quote.
   *
   *RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   (@rqco bCompany, @rqid bRQ, @rqline bItem, @quote int, @quoteline int, @shiplocation bLoc, 
     @material bMatl, @msg varchar(255)OUTPUT)
     
   AS
     
   SET NOCOUNT ON
     
   DECLARE @rc int, @count int
     
   --Verify an RQ Company has been passed in
   IF @rqco IS NULL
   	BEGIN
   	SELECT @msg = 'Missing PO Company!', @rc = 1
   	GOTO bspexit
   	END
   
   --Verify RQ ID is not NULL
   IF @rqid IS NULL
   	BEGIN
   	SELECT @msg = 'Missing RQID!', @rc = 1
   	GOTO bspexit
   	END
   
   --Verify RQ Line is not NULL
   IF @rqline IS NULL
   	BEGIN
   	SELECT @msg = 'Missing RQ Line!', @rc = 1
   	GOTO bspexit
   	END
   
   --Verify Quote is not NULL
   IF @quote IS NULL
   	BEGIN
   	SELECT @msg = 'Missing Quote ID!', @rc = 1
   	GOTO bspexit
   	END
     
   --Verify QuoteLine is not NULL
   IF @quoteline IS NULL
   	BEGIN
   	SELECT @msg = 'Missing Quote Line!', @rc = 1
   	GOTO bspexit
   	END
   
   --Verify Material is not NULL
   IF @material IS NULL
   	BEGIN
   	SELECT @msg = 'Missing Material!', @rc = 1
   	GOTO bspexit
   	END
   
   --Update the RQ Line with the Quote and Quote Line values if the RQ Line is not
   --on a PO, already on a Quote and has the same material  
   UPDATE RQRL SET Quote = @quote, QuoteLine = @quoteline 
   	WHERE Quote IS NULL 
   		AND QuoteLine IS NULL 
   		AND PO IS NULL 
   		AND POItem IS NULL 
   		AND RQID = @rqid 
   		AND RQLine = @rqline 
   		AND Material = @material
   
   --Check if the RQ Line was successfully added to the Quote Line  
   IF EXISTS (SELECT Quote FROM RQRL WHERE Quote = @quote and QuoteLine = @quoteline
   AND RQCo = @rqco AND RQID = @rqid AND RQLine = @rqline)
   	BEGIN
   	--If the Quote and Quote Line columns were successsfully updated, then update the
   	--units for RQQL  and return a success message
   	UPDATE RQQL SET Units = q.Units + r.Units FROM RQQL q INNER JOIN
   	RQRL r ON q.RQCo = r.RQCo AND q.Quote = r.Quote AND q.QuoteLine = r.QuoteLine
   	WHERE r.RQID = @rqid AND RQLine = @rqline
   	 
     	SELECT @msg = 'RQ Line was successfully added to the Quote Line', @rc = 0
     	END
   ELSE
   	--The RQ Line was not added to the Quote Line, return the error message
     	BEGIN 
     	SELECT @msg = 'RQ Line was not added to the Quote Line',@rc = 0
     	END
   	
     
   bspexit:
   	IF @rc <> 0 
   		BEGIN
   		SELECT @msg= @msg + CHAR(13) + CHAR(10) + '[bspRQQuoteInit]'
   		return @rc
   		END
     	ELSE
     		BEGIN
     		return @rc
     		END

GO
GRANT EXECUTE ON  [dbo].[bspRQAddToQuoteLine] TO [public]
GO
