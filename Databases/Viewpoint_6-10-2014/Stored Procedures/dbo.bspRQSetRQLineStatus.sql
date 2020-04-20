SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      PROC [dbo].[bspRQSetRQLineStatus]
    /************************************************************
    *Created:  GWC 09/23/2004
    *Modified: DC 10/15/07 - 125773 - Invalid Vendor error when trying to initialize PO from RQ with no vendor
    *			DC 02/28/08 - 127117 - SQL error on PO initialization
    *			DC 12/22/2008 - #130129 - Combine RQ and PO into a single module
    *Usage:
    *	Updates the RQ Line status for a given RQ Line 
    *
    * Inputs:
    *	@co				RQ Co#
    *	@rqid			RQ ID #
    *	@rqline			RQ Line#
    *************************************************************/
    (@rqco bCompany, @rqid bRQ, @rqline bItem, @msg varchar(255) output)
    
    AS
     
    SET NOCOUNT ON
    
    DECLARE @rcode int, @route int, @status int, @quotestatus int
    
    --Initialize the return code
    SELECT @rcode = 0
    
    --Verify that a company value has been passed in
    IF @rqco IS NULL
    	BEGIN
    	SELECT @msg = 'Missing Company', @rcode = 1
    	GOTO bspexit
    	END --@co is null
    
    --Verify that an RQ ID value has been passed in
    IF @rqid IS NULL
    	BEGIN
    	SELECT @msg = 'Missing RQ ID', @rcode = 1
    	GOTO bspexit
    	END --@rqid is null
    
    --Verify that an RQ Line value has been passed in
    IF @rqline IS NULL
    	BEGIN
    	SELECT @msg = 'Missing RQ Line', @rcode = 1
    	GOTO bspexit
    	END --@rqline is null
    
    --Check to see if PO is not NULL, if the RQ Line contains a value for PO then
    --the status must be completed for the RQ Line and the status can be updated immediately
    IF EXISTS (SELECT TOP 1 1 FROM RQRL WHERE RQCo = @rqco AND RQID = @rqid
    AND RQLine = @rqline AND PO IS NOT NULL)
    	BEGIN
    	SELECT @status = 5 --Completed
    	GOTO bspupdatestatus
    	END --The RQ Line is already on a PO
    
    --Check to see if the RQ Line is currently on Quote. If it is then skip to the next
    --section of checks dealing with RQ Lines on Quote
    IF EXISTS (SELECT TOP 1 1 FROM RQRL WHERE RQCo = @rqco AND RQID = @rqid
    AND RQLine = @rqline AND Quote IS NOT NULL)
    	BEGIN
    	SELECT @status = 2 --On Quote
    	GOTO bsponquote
    	END --The RQ Line is already on a Quote
    
    --Check if at least one reviewer has rejected (status = 2) the RQ Line, if they have
    --then the RQ Line status gets set to 6 - Denied and the status can
    --be immediately updated for the RQ Line
    IF EXISTS (SELECT TOP 1 1 FROM RQRR WHERE RQCo = @rqco AND RQID = @rqid
    AND RQLine = @rqline AND Status = 2)
    	BEGIN
    	SELECT @status = 6 --Denied
    	GOTO bspupdatestatus
    	END --At least one Reviewer has rejected the RQ Line
    
    --Check if at least one reviewer has not reviewed (status = 0) the RQ Line, if they have
    --not done a review yet (and no reviewers have rejected it) then the RQ Line status 
    --gets set to 0 - Open and the status can be immediately updated for the RQ Line
    IF EXISTS (SELECT TOP 1 1 FROM RQRR WHERE RQCo = @rqco AND RQID = @rqid
    AND RQLine = @rqline AND Status = 0)
    	BEGIN
    	SELECT @status = 0 --Open
    	GOTO bspupdatestatus
    	END --At least one Reviewer has not reviewed the RQ Line
    
    --Retrieve the Route for the RQ Line
    SELECT @status = 0, @route = Route FROM RQRL WHERE RQCo = @rqco AND RQID = @rqid AND RQLine = @rqline
    
    --Check if the Route is Quote for the RQ Line
    IF @route = 0 --Quote
    	BEGIN
    	--Check if Reviewers for Quote are required
    	IF EXISTS (SELECT TOP 1 1 FROM POCO WHERE POCo = @rqco AND ApprforQuote = 'Y')  --DC #130129
    		BEGIN
    		--Check that at least one Reviewer exists. If a reviewer exists, we know
    		--from the checks above that no reviewers have rejected and all reviewers
    		--have reviewed it so they must all have approved it so the status
    		--can be set to 1 - Approved for Quote for the RQ Line
    		IF EXISTS (SELECT TOP 1 1 FROM RQRR WHERE RQCo = @rqco AND RQID = @rqid 
    		AND RQLine = @rqline)
    			BEGIN
    			SELECT @status = 1 --Approved for Quote
    			GOTO bspupdatestatus
    			END
    		ELSE
    			BEGIN
    			SELECT @status = 0 --Open
    			GOTO bspupdatestatus
    			END		
    		END --Review for Quote is required
    	--Reviewers for Quote are not required and if a reviewer exists then we know from
    	--the checks that were done above that no reviewers have rejected and all the
    	--reviewer has reviewed it so if any reviewers have been added then they must
    	--have approved it so the Status can be set to 1 - Approved for Quote
    	ELSE
    		BEGIN
    		SELECT @status = 1 --Approved for Quote
    		GOTO bspupdatestatus
    		END --Review for Quote is NOT required		
    	END --@route = 0 (Quote)
    
    --Check if the Route is Purchase for the RQ Line
    IF @route = 1 --Purchase
    	BEGIN
    	--Check if Reviewers for Purchase are required
    	IF EXISTS (SELECT TOP 1 1 FROM POCO WHERE POCo = @rqco AND ApprforPurchase = 'Y')  --DC #130129
    		BEGIN
    			--Check that at least one Reviewer exists. If a reviewer exists, we know
    			--from the checks above that no reviewers have rejected and all reviewers
    			--have reviewed it so they must all have approved it so the status
    			--can be set to 4 - Approved for Purchase for the RQ Line
    			IF EXISTS (SELECT TOP 1 1 FROM RQRR WHERE RQCo = @rqco AND RQID = @rqid 
    			AND RQLine = @rqline)
					BEGIN  --DC 125773
					--Check to make sure all of the required info is supplied before we set 
					-- the status to = 4.  Vendor is required.
					IF EXISTS(SELECT TOP 1 1 FROM RQRL WHERE RQCo = @rqco AND RQID = @rqid
						AND RQLine = @rqline AND Vendor is not null)
    					BEGIN
    					SELECT @status = 4 --Approved for Purchase
    					GOTO bspupdatestatus
    					END
					ELSE
						BEGIN
    					SELECT @status = 0 --Open
    					GOTO bspupdatestatus
    					END
					END
    			ELSE
    				BEGIN
    				SELECT @status = 0 --Open
    				GOTO bspupdatestatus
    				END		
    			END --Review for Purchase is required
    		--Reviewers for Purchase are not required and if a reviewer exists then we know from
    		--the checks that were done above that no reviewers have rejected and all the
    		--reviewer has reviewed it so if any reviewers have been added then they must
    		--have approved it so the Status can be set to 4 - Approved for Purchase
    		ELSE
				BEGIN  --DC 125773
				--Check to make sure all of the required info is supplied before we set 
				-- the status to = 4.  Vendor is required.
				IF EXISTS(SELECT TOP 1 1 FROM RQRL WHERE RQCo = @rqco AND RQID = @rqid
					AND RQLine = @rqline AND Vendor is not null)
					BEGIN
					SELECT @status = 4 --Approved for Purchase
					GOTO bspupdatestatus
					END  --Review for Purchase is NOT required	
				ELSE
					BEGIN
					SELECT @status = 0 --Open
					GOTO bspupdatestatus
					END
				END
    		END --@route = 1 (Purchase)
    
    --Check if the Route is Stock for the RQ Line
    IF @route = 2 --Stock
    	BEGIN
    	--Reviewers are never required for Stock and we know that if there are any reviewers
    	--that they all must have approved it so the Status can be set to Completed for this
    	--RQ Line since the Route is Stock and it has nowhere else to go
    	SELECT @status = 5 --Completed
    	GOTO bspupdatestatus
    	END --@route = 2 (Stock)
    
    --Check if an invalid Route is stored for the RQ Line
    IF @route <> 0 AND @route <> 1 AND @route <> 2
    	BEGIN
    	SELECT @msg = 'Invalid Route. Route is not Quote, Purchase or Stock.', @rcode = 1
    	GOTO bspexit
    	END --@route <> 0, 1 or 2 (Route is not Quote, Purchase or Stock)
    
    --Exit the stored procedure if code gets to here this will prevent bsponquote code
    --and bspupdatestatus code from firing if for some unknown reason code execution 
    --reaches here
    GOTO bspexit
    
    --If the RQ Line is already on Quote then execution jumps to here
    bsponquote:
    	SELECT @status = 2 --On Quote
    	
    	--Check the Status of the Quote Line the RQ Line is on to determine what the
    	--current status of the RQ Line should be
    	SELECT @quotestatus = q.Status FROM RQQL q INNER JOIN RQRL r ON 
    	q.RQCo = r.RQCo AND q.Quote = r.Quote and q.QuoteLine = r.QuoteLine
    	WHERE r.RQCo = @rqco AND r.RQID = @rqid AND r.RQLine = @rqline
    		
    	IF @quotestatus = 0 OR @quotestatus = 1 --Open or Ready for Vendor
    		BEGIN
    		--RQ Line status = 2 On Quote
    		SELECT @status = 2 --On Quote
    		GOTO bspupdatestatus
    		END
    
    	IF @quotestatus = 2 --Quoted
    		BEGIN
    		--RQ Line status = 3 Quoted
    		SELECT @status = 3 --Quoted
    		GOTO bspupdatestatus
    		END
    
    	IF @quotestatus = 3 --Ready for Purchase
    		--RQ Line status = 4 Approved for Purchase
			--DC  125773
			--Check to make sure all of the required info is supplied before we set 
			-- the status to = 4.  Vendor is required.
			IF EXISTS(SELECT TOP 1 1 FROM RQRL WHERE RQCo = @rqco AND RQID = @rqid
				AND RQLine = @rqline AND Vendor is not null)
				BEGIN
				SELECT @status = 4 --Approved for Purchase
				GOTO bspupdatestatus
				END  
			ELSE
				BEGIN
				SELECT @status = 3 --Quoted
				GOTO bspupdatestatus
				END  
   
		--DC #127117
		--If the Quoteline status is 4=Complete, but there is no PO, POItem then
		--the po must have been cleared after the RQ was initialized to a PO.  
		--In that case, the RQRL status should be reset to 5-Approved for Purchase
    	IF @quotestatus = 4 --Completed
    		--The RQ Line should already be at completed
    		BEGIN
			IF EXISTS(SELECT TOP 1 1 FROM RQRL with (nolock) WHERE RQCo = @rqco AND RQID = @rqid
				AND RQLine = @rqline AND Status = 5 and PO is null)
    		SELECT @status = 4 ----Approved for Purchase
    		GOTO bspupdatestatus
    		END

    	IF @quotestatus = 4 --Completed
    		--The RQ Line should already be at completed
    		BEGIN
    		SELECT @status = 5 --Completed
    		GOTO bspupdatestatus
    		END
    
    	IF @quotestatus = 5 --Denied
    		--The RQ Line must be denied as well
    		BEGIN
    		SELECT @status = 6 --Denied
    		GOTO bspupdatestatus
    		END
    
    --Update the Status of the RQ Line
    bspupdatestatus:
    	UPDATE RQRL SET Status = @status WHERE RQCo = @rqco AND RQID = @rqid AND
    	RQLine = @rqline AND Status <> @status
     
    bspexit:
    	--Check if an error has occurred
        IF @rcode <> 0 
    		BEGIN
    		SELECT @msg = @msg + CHAR(13) + CHAR(10) + '[bspRQSetRQLineStatus]'
    		END -- @rcode <> 0
    
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRQSetRQLineStatus] TO [public]
GO
