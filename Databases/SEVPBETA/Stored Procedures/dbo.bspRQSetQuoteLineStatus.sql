SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                 PROC [dbo].[bspRQSetQuoteLineStatus]
    /************************************************************
    *Created:  GWC 09/23/2004
    *Modified: GWC 01/05/2005 Modified so that status does not automatically switch to 
    *			   'Ready for Purchase' if no reviewers are assigned. No reviewers
    *			   must be assigned AND the status must be set to 'Quoted'. This 
    *			   allows users to specify that records are 'Ready for Vendor' 
    *			DC 1/12/05 #26749 - Modified so it would not set the status of a 
    *								RQ Line that was completed to something else
    *	    GWC 02/16/2005 Issue 26715 Modified Quote status logic to only set Quote Lines that have no reviewers
    *				and requite no reviewers to Approved for Purchase if their status has been set to Quoted already 
	*			DC 10/16/07 - 125773 - Invalid Vendor error when trying to initialize PO from RQ with no vendor
	*			DC 02/28/08 - 127117 - SQL error on PO initialization
	*			DC 12/22/2008 - #130129 - Combine RQ and PO into a single module
	*
    *Usage:
    *	Updates the Quote Line status for a given Quote Line 
    *
    * Inputs:
    *	@co			RQ Co#
    *	@rqid			RQ ID #
    *	@rqline			RQ Line#
    *************************************************************/
    (@rqco bCompany, @quote as varchar(10), @quoteline bItem, @msg varchar(255) output)
    
    AS
     
    SET NOCOUNT ON
    
    DECLARE @rcode int, @status int
    
    --Initialize the return code
    SELECT @rcode = 0
    
    --Verify that a company value has been passed in
    IF @rqco IS NULL
    	BEGIN
    	SELECT @msg = 'Missing Company', @rcode = 1
    	GOTO bspexit
    	END --@co is null
    
    --Verify that a Quote value has been passed in
    IF @quote IS NULL
    	BEGIN
    	SELECT @msg = 'Missing Quote', @rcode = 1
    	GOTO bspexit
    	END --@quote is null
    
    --Verify that a Quote Line value has been passed in
    IF @quoteline IS NULL
    	BEGIN
    	SELECT @msg = 'Missing Quote Line', @rcode = 1
    	GOTO bspexit
    	END --@quoteline is null
    
    
    --Check to see if all of the RQ Lines that make up this Quote Line are currently
    --on a PO, if they are then the status must be completed for the Quote line and the
    --status can be updated immediately.
    IF NOT EXISTS (SELECT TOP 1 1 FROM RQRL WHERE RQCo = @rqco AND Quote = @quote
    AND QuoteLine = @quoteline AND PO IS NULL)
   	BEGIN
   	IF NOT EXISTS (SELECT TOP 1 1 FROM RQRL WHERE RQCo = @rqco AND Quote = @quote
    	AND QuoteLine = @quoteline) 
   		BEGIN
   		SELECT @status = 0
   		GOTO bspupdatestatus
   		END
   	ELSE
		BEGIN
		SELECT @status = 4 --Completed
		GOTO bspupdatestatus
   		END 	
   	END --All RQ Lines have a PO value

	--DC #127117 - SQL error on PO initialization
	--If the quote line has a status of 4=Complete but all of the RQ Lines 
	--have a status of 3=Approved for Purchase, then reset the quote line status
	--to 3=Ready for Purchase
	IF EXISTS(SELECT TOP 1 1 
				FROM RQQL l
				join RQRL r on l.RQCo = r.RQCo and l.Quote = r.Quote and l.QuoteLine = r.QuoteLine 
				where l.RQCo = @rqco 
					and l.Quote = @quote 
					and l.QuoteLine = @quoteline 
					and r.Status = 4) --Approved for purchase
		AND
		NOT EXISTS(SELECT TOP 1 1 
					FROM RQRL
					where RQCo = @rqco 
					and Quote = @quote 
					and QuoteLine = @quoteline 
					and Status <> 4) --Approved for purchase
		BEGIN
		SELECT @status = 3 --Ready for Purchase
		GOTO bspupdatestatus
   		END 	
 
    --Check if at least one reviewer has denied (status = 3) the Quote Line, if they have
    --then the Quote Line status gets set to 5 - Denied and the status can
    --be immediately updated for the Quote Line
    IF EXISTS (SELECT TOP 1 1 FROM RQQR WHERE RQCo = @rqco AND Quote = @quote
    AND QuoteLine = @quoteline AND Status = 3)
    	BEGIN
    	SELECT @status = 5 --Denied
    	GOTO bspupdatestatus
    	END --At least one Reviewer has denied the Quote Line
    
    --Check if at least one reviewer has request the line to be re-quouted (status = 2) 
    --if they have then the Quote Line status gets set to 1 - Ready for Vendor and the status can
    --be immediately updated for the Quote Line
    IF EXISTS (SELECT TOP 1 1 FROM RQQR WHERE RQCo = @rqco AND Quote = @quote
    AND QuoteLine = @quoteline AND Status = 2)
    	BEGIN
    	SELECT @status = 1 --Ready for Vendor
    	GOTO bspupdatestatus
    	END --At least one Reviewer has asked that the Quote line be re-quoted
    
    --Check if at least one reviewer has not reviewed the Quote Line (status = 0) 
    --then the Quote Line status gets set to 0, 1 or 2 and the status can
    --be immediately updated for the Quote Line
    IF EXISTS (SELECT TOP 1 1 FROM RQQR WHERE RQCo = @rqco AND Quote = @quote
    AND QuoteLine = @quoteline AND Status = 0)
    	BEGIN
    	SELECT @status = 99 --Don't change status if current status is Open, Ready or Quoted
    	GOTO bspupdatestatus
    	END --At least one Reviewer has not reviewed the line
    
    --Initialize the Status for the Quote Line
    SELECT @status = 3
    
    --Check if Reviewers for Purchase are required
    IF EXISTS (SELECT TOP 1 1 FROM POCO WHERE POCo = @rqco AND ApprforPurchase = 'Y')  --DC #130129
    	BEGIN
    	--Check that all the reviewers have Approved the Quote Line, if a Reviewer exists,
    	--we know they approved it because it already made it through the previous three checks
    	--to see if a Reviewer denied, re-quoted request or haven't reviewed it.
    	IF EXISTS (SELECT TOP 1 1 FROM RQQR WHERE RQCo = @rqco AND Quote = @quote 
    	AND QuoteLine = @quoteline)
    		BEGIN  --DC 125773	  
			--Check to make sure all of the required info is supplied before we set 
			-- the status to = 3.  Vendor is required.
			IF EXISTS(SELECT TOP 1 1 FROM RQQL WHERE RQCo = @rqco AND Quote = @quote 
    			AND QuoteLine = @quoteline and Vendor is not null)
				BEGIN
    			SELECT @status = 3 --Approved for Purchase
    			GOTO bspupdatestatus
				END
			ELSE
    			BEGIN
    			SELECT @status = 99 --Don't change status if current status is Open, Ready or Quoted
    			GOTO bspupdatestatus
    			END		
			END
    	ELSE
    		BEGIN
    		SELECT @status = 99 --Don't change status if current status is Open, Ready or Quoted
    		GOTO bspupdatestatus
    		END		
    	END --Review for Purchase is required
    --Reviewers for Purchase are not required 
    ELSE
    	BEGIN
    	IF EXISTS (SELECT TOP 1 1 FROM RQQL WHERE RQCo = @rqco AND Quote = @quote
   					AND QuoteLine = @quoteline AND Status = 2 and Vendor is not NULL)  --DC 125773
   		BEGIN
   			SELECT @status = 3 --Approved for Purchase
    		GOTO bspupdatestatus
   		END
   	ELSE
   		BEGIN
   		--IF EXISTS (SELECT TOP 1 1 FROM RQQR WHERE RQCo = @rqco AND Quote = @quote
   		--AND QuoteLine = @quoteline AND Status <> 1)
   		--	BEGIN
   			SELECT @status = 99
   		--	END
   		--ELSE		
   		--	BEGIN
   		--	SELECT @status = 3
   		--	GOTO bspupdatestatus
   		--	END
   		END
   	END --Review for Purchase is NOT required	
    
    --Exit the stored procedure if code gets to here this will prevent bspupdatestatus 
    --code from firing if for some unknown reason code execution reaches here
    GOTO bspexit
    
    --Update the Status of the Quote Line
    bspupdatestatus:
    	IF @status <> 99
    		BEGIN
    		UPDATE RQQL SET Status = @status WHERE RQCo = @rqco AND Quote = @quote AND
    		QuoteLine = @quoteline AND Status <> @status
     		END
    	ELSE
    		BEGIN
    		UPDATE RQQL SET Status = 0 WHERE RQCo = @rqco AND Quote = @quote AND
    		QuoteLine = @quoteline AND Status <> 0 AND Status <> 1 AND Status <> 2
   		--AND Status <> 3 
    		END
     
    	--Update the associated RQ Line statuses
    	SELECT @status = Status FROM RQQL WHERE RQCo = @rqco AND Quote = @quote AND
    		QuoteLine = @quoteline
    
    	IF @status = 0 OR @status = 1
    		BEGIN
    		UPDATE RQRL SET Status = 2 WHERE RQCo = @rqco AND Quote = @quote AND
    		QuoteLine = @quoteline AND Status <> 2 AND Status <> 5  --DC #26749
    		END
    	ELSE IF @status = 2
    		BEGIN
    		UPDATE RQRL SET Status = 3 WHERE RQCo = @rqco AND Quote = @quote AND
    		QuoteLine = @quoteline AND Status <> 3 AND Status <> 5 --DC #26749
    		END
    	ELSE IF @status = 3
    		BEGIN
    		UPDATE RQRL SET Status = 4 WHERE RQCo = @rqco AND Quote = @quote AND
    		QuoteLine = @quoteline AND Status <> 4 AND Status <> 5 --DC #26749
    		END
    	ELSE IF @status = 4
    		BEGIN
    		UPDATE RQRL SET Status = 5 WHERE RQCo = @rqco AND Quote = @quote AND
    		QuoteLine = @quoteline AND Status <> 5
    		END
    	ELSE IF @status = 5
    		BEGIN
    		UPDATE RQRL SET Status = 6 WHERE RQCo = @rqco AND Quote = @quote AND
    		QuoteLine = @quoteline AND Status <> 6
    		END
    
    
    bspexit:
    	--Check if an error has occurred
        IF @rcode <> 0 
    		BEGIN
    		SELECT @msg = @msg + CHAR(13) + CHAR(10) + '[bspRQSetQuoteLineStatus]'
    		END -- @rcode <> 0
    
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRQSetQuoteLineStatus] TO [public]
GO
