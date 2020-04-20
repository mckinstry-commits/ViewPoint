SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRQLineReviewerGet    Script Date: 3/26/2004 12:41:34 PM ******/
   CREATE               proc [dbo].[bspRQLineReviewerGet]
   /************************************************************
    * Created: DC 3/26/04
    * Modified:		DC #130129 - Combine RQ and PO into a single module
    *				GF 09/09/2010 - issue #141031 changed to use vfDateOnly
    * 
    * Usage:
    *	Adds default Reviewer(s) to RQRR based on information from
    *	RQ Line 
    *
    * Inputs:
    *	@co			RQ Co#
    *	@line			RQ Line#
    *	@jcco			JC Co# 
    *	@job			Job	
    *	@emco			EM Co#	
    *	@equip			Equipment
    *	@totalcost		Total Cost	
    *	@route			Route
    *
    *************************************************************/
    	(@co bCompany, @rqid bRQ, @rqline bItem, @jcco bCompany = null, 
   	 @job bJob = null,@emco bCompany = null, @equip bEquip = null, @totalcost bDollar = null,
   	@route int = null, @inco bCompany = null, @inloc bLoc = null, @msg varchar(255) output)
   as
    
   set nocount on 
   declare @rcode int
   
   select @rcode = 0
   
   if @co is null
   	begin
   	select @msg = 'Missing Company', @rcode = 1
   	goto bspexit
   	end
   
   if @rqid is null
   	begin
   	select @msg = 'Missing RQ ID', @rcode = 1
   	goto bspexit
   	end
   
   if @rqline is null
   	begin
   	select @msg = 'Missing RQ Line', @rcode = 1
   	goto bspexit
   	end
   
   --Add the default Reviewer(s) setup in RQCo
   
   --Add Review for Quote Reviewer if a Quote Reviewer has been entered in RQCo
   INSERT RQRR (RQCo, RQID, RQLine, Reviewer, AssignedDate, Status)
   	SELECT @co, @rqid, @rqline, r.QuoteReviewer, dbo.vfDateOnly(), 0 ----#141031
   	FROM POCO r WITH (NOLOCK)  --DC #130129
   	WHERE r.POCo = @co 
   		AND r.QuoteReviewer IS NOT NULL
   		AND r.QuoteReviewer NOT IN(select Reviewer 
   									from RQRR with (NOLOCK)
   									where RQCo = @co 
   										and RQID = @rqid 
   										and RQLine = @rqline)
   
   /* REMOVED BECAUSE PURCHASE REVIEWERS GET ADDED TO QUOTE REVIEWER TABLE 
   --Add Review for Purchase Reviewer if a Purchase Reviewer has been entered in RQCo
   INSERT RQRR (RQCo, RQID, RQLine, Reviewer)
   	SELECT @co, @rqid, @rqline, r.PurchaseReviewer
   	FROM RQCO r WITH (NOLOCK)
   	WHERE r.RQCo = @co AND r.PurchaseReviewer IS NOT NULL
   */
   
   --Add threshold Reviewer if route = Purchase and Total Cost is greater then Threshold amount
   IF @route = 1   --1 = Purchase
   	BEGIN
   	IF exists(select top 1 1 from POCO WITH (NOLOCK)where Threshold is not null and POCo = @co)  --DC #130129
   		BEGIN
   		If @totalcost > (select Threshold from POCO WITH (NOLOCK) where POCo = @co)  --DC #130129
   			BEGIN
   				INSERT RQRR (RQCo, RQID, RQLine, Reviewer, AssignedDate, Status)
   					SELECT @co, @rqid, @rqline, r.ThresholdReviewer, dbo.vfDateOnly(), 0 ----#141031
   					FROM POCO r WITH (NOLOCK)  --DC #130129
   					WHERE r.POCo = @co 
   						AND r.ThresholdReviewer IS NOT NULL
   						AND r.ThresholdReviewer NOT IN(select Reviewer 
   														from RQRR with (NOLOCK)
   														where RQCo = @co 
   															and RQID = @rqid 
   															and RQLine = @rqline)
   			END
   		END
   
   	--Add Purchase Reviewer to RQRR if a Purchase Reviewer has been entered in RQCo
   	INSERT RQRR (RQCo, RQID, RQLine, Reviewer)
   		SELECT @co, @rqid, @rqline, r.PurchaseReviewer
   		FROM POCO r WITH (NOLOCK)  --DC #130129
   		WHERE r.POCo = @co 
   			AND r.PurchaseReviewer IS NOT NULL
   			AND r.PurchaseReviewer NOT IN(select Reviewer 
   											from RQRR with (NOLOCK)
   											where RQCo = @co 
   												and RQID = @rqid 
   												and RQLine = @rqline)
   	END
    
   -- add default Reviewer(s) for Job
   if @job is not null 
   	begin
   	    INSERT RQRR (RQCo, RQID, RQLine, Reviewer, AssignedDate, Status)
   	    SELECT @co, @rqid, @rqline, j.Reviewer, dbo.vfDateOnly(), 0 ----#141031
   	    FROM JCJR j with (NOLOCK)
   	    WHERE j.JCCo = @jcco 
   			and j.Job = @job 
   			and j.ReviewerType in (2,3)
   			AND j.Reviewer NOT IN(select Reviewer 
   											from RQRR with (NOLOCK)
   											where RQCo = @co 
   												and RQID = @rqid 
   												and RQLine = @rqline)
   	    GROUP BY j.JCCo, j.Job, j.Reviewer
   	end
    
   -- add default Reviewer for Equipment
   if @equip is not null 
   	begin
   		INSERT RQRR (RQCo, RQID, RQLine, Reviewer, AssignedDate, Status)
   		SELECT @co, @rqid, @rqline, d.PurchReviewer, dbo.vfDateOnly(), 0 ----#141031
   		FROM EMDM d with (NOLOCK)
   			JOIN EMEM e WITH (NOLOCK) on e.EMCo = d.EMCo and d.Department = e.Department
   		WHERE d.EMCo = @emco 
   			and e.Equipment = @equip 
   			and isnull(d.PurchReviewer,'') <> ''
   			AND d.PurchReviewer NOT IN(select Reviewer 
   											from RQRR with (NOLOCK)
   											where RQCo = @co 
   												and RQID = @rqid 
   												and RQLine = @rqline)
   
   	end
   
   --add default Reviewer for IN Location (future release)
   if @inloc is not null 
   	begin
   		INSERT RQRR (RQCo, RQID, RQLine, Reviewer, AssignedDate, Status)
   		SELECT @co, @rqid, @rqline, i.PurReviewer, dbo.vfDateOnly(), 0 ----#141031
   		FROM INLM i with (NOLOCK)
   		WHERE i.INCo = @inco 
   			and i.Loc = @inloc 
   			and isnull(i.PurReviewer,'') <> ''
   			AND i.PurReviewer NOT IN(select Reviewer 
   											from RQRR with (NOLOCK)
   											where RQCo = @co 
   												and RQID = @rqid 
   												and RQLine = @rqline)
   	end
    
   return @rcode
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRQLineReviewerGet] TO [public]
GO
