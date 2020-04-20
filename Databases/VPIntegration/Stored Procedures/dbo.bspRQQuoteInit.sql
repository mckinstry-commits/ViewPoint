SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspRQQuoteInit    Script Date: 6/9/2004 2:29:17 PM ******/
   CREATE          PROCEDURE [dbo].[bspRQQuoteInit]
   /***********************************************************
   *CREATED BY: 	GWC 04/26/04
   *MODIFIED BY:	 DC 7/16/07 - 6.x re-code. Added UnitCost of 0.00 since Unit Cost can not be null
   *				DC 12/4/08 - #130129 - Combine RQ and PO into a single module
   *				DC 8/20/2009 - #131288 - Quote Added to completed Quote Header
   *				GF 10/26/2010 - issue #141031 change to use vfDateOnly function
   *
   *
   *USAGE:
   *	Used by the RQ Quote Initialize to populate RQQH and RQQL with Quotes 
   * 	to be sent to vendors.
   * 
   *INPUT PARAMETERS
   *	RQCo		RQ Co to validate against
   *	UserName	LoginName of user, used to track who created the Quote
   *
   *OUTPUT PARAMETERS
   *	@msg		Error message 
   *
   *RETURN VALUE
   *   0			Success
   *   1			Failure
   *****************************************************/
   (@rqco bCompany, @username varchar(50), @inco bCompany = NULL, @location bLoc = NULL,
    @locgrp bGroup = NULL, @emco bCompany = NULL, @emshop varchar(20) = NULL, @matlcat varchar(10) = NULL,
    @jcco bCompany = NULL, @job bJob = NULL, @shiplocation bLoc = NULL, @requireddate bDate = NULL,
    @rqid bRQ = NULL, @quote int = NULL, @desc bDesc = NULL, @matlgrpby int = 0, @reviewer varchar(3) = null,
    @msg varchar(255)OUTPUT)
     
	AS
	 
	SET NOCOUNT ON
	 
	DECLARE @quoteline int, 
 			@status int, 
 			@route int,
			@createheader int, 
 			@rc int,
			@unitcost bUnitCost,
			@vendorgroup bGroup
     
	--Verify an RQ Company has been passed in
	IF @rqco IS NULL
		BEGIN
		SELECT @msg = 'Missing PO Company!', @rc = 1
		GOTO bspexit
		END
     
	--Verify a UserName has been passed in
	IF @username IS null
		BEGIN
		SELECT @msg = 'Missing User Name!', @rc = 1
		GOTO bspexit
		END
     
	--Table variable to hold records from RQRL
	DECLARE @RQRL_temp TABLE (
 			RQCo tinyint, 
 			RQID varchar(10),
 			RQLine smallint,
 			Quote int,
 			QuoteLine int,
 			MatlGroup tinyint,
 			Material varchar(20),
 			INCo tinyint,
 			Location varchar(10),
 			JCCo tinyint,
 			Job varchar(10),
 			EMCo tinyint,
 			ShipLoc varchar(20),
 			RequiredDate smalldatetime,
 			Units numeric(12,3),
 			UM varchar(3),
 			ECM char(1),
 			Description varchar(60)) 
   
	SELECT @createheader = 0 --Don't create a header  
	SELECT @status = 1  	 --Approved for Quote
	SELECT @route = 0   	 --Rout is Quote
	SELECT @rc = 0			 --Success
	SELECT @unitcost = 0
	SELECT @vendorgroup = VendorGroup from bHQCO with (nolock) where HQCo = @rqco
     
	--Retrieve the next QuoteID from RQQH
	IF @quote IS NULL
		BEGIN
		SELECT @quote = ISNULL(Max(Quote),0) + 1 FROM RQQH WITH (NOLOCK) WHERE RQCo = @rqco
		SELECT @createheader = 1 --Create the header
		END
     
	--Obtain the next QuoteLine value from RQQL
	SELECT @quoteline = ISNULL(MAX(QuoteLine),0) FROM RQQL WITH (NOLOCK)
	WHERE RQCo = @rqco AND Quote = @quote
     
	IF ISNULL(@matlcat, '') = ''
		BEGIN
		--Populate the temp table with the Requisition lines that the are to
		--be grouped into Quotes
		INSERT INTO @RQRL_temp (RQCo, RQID, RQLine, Quote, QuoteLine, MatlGroup,
  					Material, INCo, Location, JCCo, Job, EMCo, ShipLoc, RequiredDate,
  					Units, UM, ECM, Description)
		  
		--Get all the requisition lines (filtered by the passed in filters) 
		--that aren't on a Quote and whose Status is 1-Approved for Quote
		SELECT @rqco, l.RQID, l.RQLine, @quote, @quoteline, l.MatlGroup, l.Material, 
		l.INCo, l.Loc, l.JCCo, l.Job, l.EMCo, l.ShipLoc, l.ReqDate, l.Units, 
		l.UM, l.ECM, l.Description
		FROM RQRL l
		--INNER JOIN HQMT t ON l.Material = t.Material and l.MatlGroup = t.MatlGroup
		LEFT JOIN INLM m ON l.INCo = m.INCo and l.Loc = m.Loc
		LEFT JOIN EMWH w ON w.EMCo = l.EMCo and w.WorkOrder = l.WO
		WHERE 
			l.RQCo = @rqco
			AND l.Quote IS NULL 
			AND l.PO IS NULL
			AND l.Route = @route
			AND ISNULL(l.Status,@status) = @status

			--Filters passed in by the user
			AND ISNULL(l.INCo, '') = ISNULL(@inco,ISNULL(l.INCo,''))
			AND ISNULL(l.Loc, '') = ISNULL(@location,ISNULL(l.Loc,''))
			AND ISNULL(m.LocGroup,'') = ISNULL(@locgrp,ISNULL(m.LocGroup,''))
			AND ISNULL(l.EMCo, '') = ISNULL(@emco,ISNULL(l.EMCo,''))
			AND ISNULL(w.Shop, '') = ISNULL(@emshop,ISNULL(w.Shop,''))

			--AND ISNULL(t.Category,'') = ISNULL(@matlcat,ISNULL(t.Category,''))
			AND ISNULL(l.JCCo, '') = ISNULL(@jcco,ISNULL(l.JCCo,''))
			AND ISNULL(l.Job, '') = ISNULL(@job,ISNULL(l.Job,''))
			AND ISNULL(l.ShipLoc, '') = ISNULL(@shiplocation,ISNULL(l.ShipLoc,''))
			AND ISNULL(l.ReqDate, '') <= ISNULL(@requireddate,ISNULL(l.ReqDate,''))
			AND ISNULL(l.RQID, '') = ISNULL(@rqid,ISNULL(l.RQID,''))

		END
	ELSE
		BEGIN
		--Populate the temp table with the Requisition lines that the are to
		--be grouped into Quotes
		INSERT INTO @RQRL_temp (RQCo, RQID, RQLine, Quote, QuoteLine, MatlGroup,
  					Material, INCo, Location, JCCo, Job, EMCo, ShipLoc, RequiredDate,
  					Units, UM, ECM, Description)
		  
		--Get all the requisition lines (filtered by the passed in filters) 
		--that aren't on a Quote and whose Status is 1-Approved for Quote
		SELECT @rqco, l.RQID, l.RQLine, @quote, @quoteline, l.MatlGroup, l.Material, 
		l.INCo, l.Loc, l.JCCo, l.Job, l.EMCo, l.ShipLoc, l.ReqDate, l.Units, 
		l.UM, l.ECM, l.Description
		FROM RQRL l
		INNER JOIN HQMT t ON l.Material = t.Material and l.MatlGroup = t.MatlGroup
		LEFT JOIN INLM m ON l.INCo = m.INCo and l.Loc = m.Loc
		LEFT JOIN EMWH w ON w.EMCo = l.EMCo and w.WorkOrder = l.WO
		WHERE 
			l.RQCo = @rqco
			AND l.Quote IS NULL 
			AND l.PO IS NULL
			AND l.Route = @route
			AND ISNULL(l.Status,@status) = @status

			--Filters passed in by the user
			AND ISNULL(l.INCo, '') = ISNULL(@inco,ISNULL(l.INCo,''))
			AND ISNULL(l.Loc, '') = ISNULL(@location,ISNULL(l.Loc,''))
			AND ISNULL(m.LocGroup,'') = ISNULL(@locgrp,ISNULL(m.LocGroup,''))
			AND ISNULL(l.EMCo, '') = ISNULL(@emco,ISNULL(l.EMCo,''))
			AND ISNULL(w.Shop, '') = ISNULL(@emshop,ISNULL(w.Shop,''))
			AND ISNULL(t.Category,'') = ISNULL(@matlcat,ISNULL(t.Category,''))
			AND ISNULL(l.JCCo, '') = ISNULL(@jcco,ISNULL(l.JCCo,''))
			AND ISNULL(l.Job, '') = ISNULL(@job,ISNULL(l.Job,''))
			AND ISNULL(l.ShipLoc, '') = ISNULL(@shiplocation,ISNULL(l.ShipLoc,''))
			AND ISNULL(l.ReqDate, '') <= ISNULL(@requireddate,ISNULL(l.ReqDate,''))
			AND ISNULL(l.RQID, '') = ISNULL(@rqid,ISNULL(l.RQID,''))

		END         
   
	--Check to see if there are any requistions in the table, if not notify the calling 
	--procedure that there are not any requistion lines currently ready to be grouped in a Quote.
	IF NOT EXISTS (SELECT TOP 1 1 FROM @RQRL_temp)
		BEGIN
		SELECT @msg = 'No Requistions Lines meeting the criteria are ready to place in a Quote at this time.', @rc = 0
		GOTO bspexit
		END
   
	--Check if a new header should be created or if the user is adding to an existing Quote header
	IF @createheader = 1 
		BEGIN
		--Insert new Quote Header into RQQH 
		INSERT INTO RQQH (RQCo, Quote, UserName, CreateDate, Locked, Description) 
		----#141031
		VALUES (@rqco, @quote, @username, dbo.vfDateOnly(), 'N', @desc)
		END
     
	--Table variable to hold records from RQQL
	DECLARE @RQQL_temp TABLE (
			QuoteLine int,
			MatlGroup tinyint,
			Material varchar(20),
			Units numeric(12,3),
			UM varchar(3),
			ECM char(1),
			Description varchar(60))
     
	--Insert records from the RQRL temp table to the RQQL temp table grouped by 
	--MatlGroup and Material with the Units summed.
	IF @matlgrpby = 0 
		BEGIN
		INSERT INTO @RQQL_temp (QuoteLine, MatlGroup, Material, Units, UM)
			SELECT @quoteline, r.MatlGroup, r.Material, SUM(r.Units) AS Units, 
			r.UM FROM @RQRL_temp r GROUP BY r.MatlGroup, r.Material, r.UM

		UPDATE @RQQL_temp SET Description = r.Description 
			FROM @RQRL_temp r INNER JOIN @RQQL_temp l ON ISNULL(r.MatlGroup, '') =
			ISNULL(l.MatlGroup,'') AND ISNULL(r.Material,'') = ISNULL(l.Material,'') AND
			ISNULL(r.UM,'') = ISNULL(l.UM,'')
		END
	ELSE
		BEGIN
		INSERT INTO @RQQL_temp (QuoteLine, MatlGroup, Material, Units, UM, Description)
			SELECT @quoteline, r.MatlGroup, r.Material, SUM(r.Units) AS Units, 
			r.UM, r.Description FROM @RQRL_temp r 
			GROUP BY r.MatlGroup, r.Material, r.UM, r.Description
		END
    
	--Update existing like materials first if they have the same Material Group, Material, 
	--Description and UM
	IF @matlgrpby = 0 
		BEGIN
		UPDATE RQQL
		SET Units = l.Units + t.Units
		FROM @RQQL_temp t
			INNER JOIN RQQL l ON ISNULL(t.MatlGroup,'') = ISNULL(l.MatlGroup,'') AND ISNULL(t.Material,'') = ISNULL(l.Material,'') 
			AND ISNULL(t.UM,'') = ISNULL(l.UM,'') 
		WHERE Quote = @quote AND RQCo = @rqco 
			AND l.Status <> 4  --DC #131288
		END
	ELSE
		BEGIN
		UPDATE RQQL
		SET Units = l.Units + t.Units
		FROM @RQQL_temp t
			INNER JOIN RQQL l ON ISNULL(t.MatlGroup,'') = ISNULL(l.MatlGroup,'') AND ISNULL(t.Material,'') = ISNULL(l.Material,'') 
			AND ISNULL(t.UM,'') = ISNULL(l.UM,'') 
		WHERE Quote = @quote AND RQCo = @rqco AND ISNULL(t.Description,'') = ISNULL(l.Description, '')
			AND l.Status <> 4  --DC #131288
		END
   
	IF @matlgrpby = 0
		BEGIN
		--Need to somehow identify those records that have been updated and placed on existing Quote Lines...
		UPDATE @RQQL_temp 
		SET QuoteLine = -1
		FROM RQQL l
		INNER JOIN @RQQL_temp t ON ISNULL(l.MatlGroup,'') = ISNULL(t.MatlGroup,'') 
		AND ISNULL(l.Material,'') = ISNULL(t.Material,'') AND
		ISNULL(l.UM,'') = ISNULL(t.UM,'') 
		WHERE Quote = @quote 
			AND l.Status <> 4  --DC #131288
		END
	ELSE
		BEGIN
		UPDATE @RQQL_temp 
		SET QuoteLine = -1
		FROM RQQL l
		INNER JOIN @RQQL_temp t ON ISNULL(l.MatlGroup,'') = ISNULL(t.MatlGroup,'') 
		AND ISNULL(l.Material,'') = ISNULL(t.Material,'') AND
		ISNULL(l.UM,'') = ISNULL(t.UM,'') AND ISNULL(l.Description,'') = ISNULL(t.Description,'') 
		WHERE Quote = @quote 
			AND l.Status <> 4  --DC #131288
		END
   
	--Update the QuoteLine id's, this will give every QuoteLine a unique value in the table.
	UPDATE @RQQL_temp SET QuoteLine = @quoteline, @quoteline = @quoteline + 1  WHERE QuoteLine <> -1
   
	--Insert the records with the new QuoteLine Id's into RQQL
	INSERT INTO RQQL (RQCo, Quote, QuoteLine, Status, MatlGroup, Material, Loc, INCo, EMCo, JCCo,
		Job, ShipLoc, ReqDate, Units, UnitCost, UM, ECM, Description, VendorGroup ) 
	SELECT @rqco, @quote, t.QuoteLine, @status, t.MatlGroup, t.Material, @location, @inco, @emco, @jcco,
		@job, @shiplocation, @requireddate, t.Units, @unitcost, t.UM, t.ECM, t.Description, @vendorgroup
	FROM @RQQL_temp t 
	WHERE t.QuoteLine <> -1
   
	IF @@Error <> 0
		BEGIN
		GOTO ERR_INSERT
		END
     
	--If @reviewer is not NULL, insert reviewers for each RQ Lines into RQRR
	IF ISNULL(@reviewer,'') <> '' 
		BEGIN
		INSERT INTO RQQR (RQCo, Reviewer, Quote, QuoteLine, AssignedDate, Status)
		----#141031
		SELECT @rqco, @reviewer, @quote, t.QuoteLine, dbo.vfDateOnly(), 0
		FROM @RQQL_temp t WHERE @reviewer NOT IN (SELECT Reviewer FROM RQQR WITH (NOLOCK)
		WHERE RQCo = @rqco AND Quote = @quote AND QuoteLine = t.QuoteLine)				
		END
   
	IF @@Error <> 0
		BEGIN
		GOTO ERR_INSERT
		END
     
	IF @matlgrpby = 0
		BEGIN
		--Update RQRL temp with the generated QuoteLine
		UPDATE @RQRL_temp 
		Set QuoteLine = q.QuoteLine 
		FROM RQQL q
			JOIN @RQRL_temp r ON q.RQCo = r.RQCo AND q.Quote = r.Quote
		WHERE ISNULL(q.MatlGroup,'') = ISNULL(r.MatlGroup,'') AND 
			ISNULL(q.Material,'') = ISNULL(r.Material,'')  
			AND q.UM = r.UM AND ISNULL(q.ECM,'') = ISNULL(r.ECM,'')
			AND q.Status <> 4 --DC #131288
		END
	ELSE
		BEGIN
		--Update RQRL temp with the generated QuoteLine
		UPDATE @RQRL_temp 
		Set QuoteLine = q.QuoteLine 
		FROM RQQL q
			JOIN @RQRL_temp r ON q.RQCo = r.RQCo AND q.Quote = r.Quote
		WHERE ISNULL(q.MatlGroup,'') = ISNULL(r.MatlGroup,'') AND 
			ISNULL(q.Material,'') = ISNULL(r.Material,'')  
			AND q.UM = r.UM AND ISNULL(q.ECM,'') = ISNULL(r.ECM,'')
			AND ISNULL(q.Description,'') = ISNULL(r.Description,'')
			AND q.Status <> 4 --DC #131288
		END
   
	IF @@Error <> 0
		BEGIN
		GOTO ERR_INSERT
		END
   
	IF ISNULL(@matlcat, '') = ''
		BEGIN
		IF @matlgrpby = 0 
			BEGIN
			UPDATE RQRL Set Quote = @quote, QuoteLine = q.QuoteLine 
			FROM RQRL r 
			INNER JOIN RQQL q ON ISNULL(r.MatlGroup,'') = ISNULL(q.MatlGroup,'') AND
				ISNULL(r.Material,'') = ISNULL(q.Material,'') AND ISNULL(r.UM,'') = ISNULL(q.UM,'') 
			LEFT JOIN INLM m ON r.INCo = m.INCo and r.Loc = m.Loc
			LEFT JOIN EMWH w ON w.EMCo = r.EMCo and w.WorkOrder = r.WO
			WHERE r.RQCo = @rqco AND q.Quote = @quote AND r.PO IS NULL AND r.Status = 1
			AND r.Quote IS NULL 
			AND r.Route = @route
			AND ISNULL(r.Status,@status) = @status
			AND q.Status <> 4 --DC #131288
			--Filters passed in by the user
			AND ISNULL(r.INCo, '') = ISNULL(@inco,ISNULL(r.INCo,''))
			AND ISNULL(r.Loc, '') = ISNULL(@location,ISNULL(r.Loc,''))
			AND ISNULL(m.LocGroup,'') = ISNULL(@locgrp,ISNULL(m.LocGroup,''))
			AND ISNULL(r.EMCo, '') = ISNULL(@emco,ISNULL(r.EMCo,''))
			AND ISNULL(w.Shop, '') = ISNULL(@emshop,ISNULL(w.Shop,''))
			AND ISNULL(r.JCCo, '') = ISNULL(@jcco,ISNULL(r.JCCo,''))
			AND ISNULL(r.Job, '') = ISNULL(@job,ISNULL(r.Job,''))
			AND ISNULL(r.ShipLoc, '') = ISNULL(@shiplocation,ISNULL(r.ShipLoc,''))
			AND ISNULL(r.ReqDate, '') <= ISNULL(@requireddate,ISNULL(r.ReqDate,''))
			AND ISNULL(r.RQID, '') = ISNULL(@rqid,ISNULL(r.RQID,''))
			END
		ELSE
			BEGIN
			UPDATE RQRL Set Quote = @quote, QuoteLine = q.QuoteLine 
			FROM RQRL r 
			INNER JOIN RQQL q ON ISNULL(r.MatlGroup,'') = ISNULL(q.MatlGroup,'') AND
				ISNULL(r.Material,'') = ISNULL(q.Material,'') AND ISNULL(r.UM,'') = ISNULL(q.UM,'') 
				AND ISNULL(r.Description,'') = ISNULL(q.Description,'')
			LEFT JOIN INLM m ON r.INCo = m.INCo and r.Loc = m.Loc
			LEFT JOIN EMWH w ON w.EMCo = r.EMCo and w.WorkOrder = r.WO
			WHERE r.RQCo = @rqco AND q.Quote = @quote AND r.PO IS NULL AND r.Status = 1
			AND r.Quote IS NULL 
			AND r.Route = @route
			AND ISNULL(r.Status,@status) = @status
			AND q.Status <> 4 --DC #131288
			--Filters passed in by the user
			AND ISNULL(r.INCo, '') = ISNULL(@inco,ISNULL(r.INCo,''))
			AND ISNULL(r.Loc, '') = ISNULL(@location,ISNULL(r.Loc,''))
			AND ISNULL(m.LocGroup,'') = ISNULL(@locgrp,ISNULL(m.LocGroup,''))
			AND ISNULL(r.EMCo, '') = ISNULL(@emco,ISNULL(r.EMCo,''))
			AND ISNULL(w.Shop, '') = ISNULL(@emshop,ISNULL(w.Shop,''))
			AND ISNULL(r.JCCo, '') = ISNULL(@jcco,ISNULL(r.JCCo,''))
			AND ISNULL(r.Job, '') = ISNULL(@job,ISNULL(r.Job,''))
			AND ISNULL(r.ShipLoc, '') = ISNULL(@shiplocation,ISNULL(r.ShipLoc,''))
			AND ISNULL(r.ReqDate, '') <= ISNULL(@requireddate,ISNULL(r.ReqDate,''))
			AND ISNULL(r.RQID, '') = ISNULL(@rqid,ISNULL(r.RQID,''))
			END
		END
	ELSE
		BEGIN
		IF @matlgrpby = 0 
			BEGIN
			--Populate the temp table with the Requisition lines that the are to
			--be grouped into Quotes
			UPDATE RQRL Set Quote = @quote, QuoteLine = q.QuoteLine 
			FROM RQRL r 
			INNER JOIN RQQL q ON ISNULL(r.MatlGroup,'') = ISNULL(q.MatlGroup,'') AND
				ISNULL(r.Material,'') = ISNULL(q.Material,'') AND ISNULL(r.UM,'') = ISNULL(q.UM,'') 
			INNER JOIN HQMT t ON r.Material = t.Material and r.MatlGroup = t.MatlGroup
			LEFT JOIN INLM m ON r.INCo = m.INCo and r.Loc = m.Loc
			LEFT JOIN EMWH w ON w.EMCo = r.EMCo and w.WorkOrder = r.WO
			WHERE r.RQCo = @rqco AND q.Quote = @quote AND r.PO IS NULL AND r.Status = 1
			AND r.Quote IS NULL 
			AND r.Route = @route
			AND ISNULL(r.Status,@status) = @status
			AND q.Status <> 4 --DC #131288
			--Filters passed in by the user
			AND ISNULL(r.INCo, '') = ISNULL(@inco,ISNULL(r.INCo,''))
			AND ISNULL(r.Loc, '') = ISNULL(@location,ISNULL(r.Loc,''))
			AND ISNULL(m.LocGroup,'') = ISNULL(@locgrp,ISNULL(m.LocGroup,''))
			AND ISNULL(r.EMCo, '') = ISNULL(@emco,ISNULL(r.EMCo,''))
			AND ISNULL(w.Shop, '') = ISNULL(@emshop,ISNULL(w.Shop,''))
			AND ISNULL(t.Category,'') = ISNULL(@matlcat,ISNULL(t.Category,''))
			AND ISNULL(r.JCCo, '') = ISNULL(@jcco,ISNULL(r.JCCo,''))
			AND ISNULL(r.Job, '') = ISNULL(@job,ISNULL(r.Job,''))
			AND ISNULL(r.ShipLoc, '') = ISNULL(@shiplocation,ISNULL(r.ShipLoc,''))
			AND ISNULL(r.ReqDate, '') <= ISNULL(@requireddate,ISNULL(r.ReqDate,''))
			AND ISNULL(r.RQID, '') = ISNULL(@rqid,ISNULL(r.RQID,''))
			END
		ELSE
			BEGIN
			--Populate the temp table with the Requisition lines that the are to
			--be grouped into Quotes
			UPDATE RQRL Set Quote = @quote, QuoteLine = q.QuoteLine 
			FROM RQRL r 
			INNER JOIN RQQL q ON ISNULL(r.MatlGroup,'') = ISNULL(q.MatlGroup,'') AND
				ISNULL(r.Material,'') = ISNULL(q.Material,'') AND ISNULL(r.UM,'') = ISNULL(q.UM,'') 
				AND ISNULL(r.Description,'') = ISNULL(q.Description,'')
			INNER JOIN HQMT t ON r.Material = t.Material and r.MatlGroup = t.MatlGroup
			LEFT JOIN INLM m ON r.INCo = m.INCo and r.Loc = m.Loc
			LEFT JOIN EMWH w ON w.EMCo = r.EMCo and w.WorkOrder = r.WO
			WHERE r.RQCo = @rqco AND q.Quote = @quote AND r.PO IS NULL AND r.Status = 1
			AND r.Quote IS NULL 
			AND r.Route = @route
			AND ISNULL(r.Status,@status) = @status
			AND q.Status <> 4 --DC #131288
			--Filters passed in by the user
			AND ISNULL(r.INCo, '') = ISNULL(@inco,ISNULL(r.INCo,''))
			AND ISNULL(r.Loc, '') = ISNULL(@location,ISNULL(r.Loc,''))
			AND ISNULL(m.LocGroup,'') = ISNULL(@locgrp,ISNULL(m.LocGroup,''))
			AND ISNULL(r.EMCo, '') = ISNULL(@emco,ISNULL(r.EMCo,''))
			AND ISNULL(w.Shop, '') = ISNULL(@emshop,ISNULL(w.Shop,''))
			AND ISNULL(t.Category,'') = ISNULL(@matlcat,ISNULL(t.Category,''))
			AND ISNULL(r.JCCo, '') = ISNULL(@jcco,ISNULL(r.JCCo,''))
			AND ISNULL(r.Job, '') = ISNULL(@job,ISNULL(r.Job,''))
			AND ISNULL(r.ShipLoc, '') = ISNULL(@shiplocation,ISNULL(r.ShipLoc,''))
			AND ISNULL(r.ReqDate, '') <= ISNULL(@requireddate,ISNULL(r.ReqDate,''))
			AND ISNULL(r.RQID, '') = ISNULL(@rqid,ISNULL(r.RQID,''))
			END
		END
   
	IF @@Error <> 0
		BEGIN
		GOTO ERR_INSERT
		END
   
	--Create the success message to be returned.
	SELECT @msg = 'Requisition Quote Initialized' + char(13) + 'PO Company: ' + LTRIM(@rqco) + ' Quote #: ' + CAST(@quote AS varchar(5)), @rc = 0
	GOTO bspexit	
     
	ERR_INSERT:
		ROLLBACK TRANSACTION
		SELECT @rc = 1
		SELECT @msg = 'Error inserting into RQRH and RQRL'
		GOTO bspexit
     
   bspexit:
   	IF @rc<>0 
   		BEGIN
   		SELECT @msg= @msg + CHAR(13) + CHAR(10) + '[bspRQQuoteInit]'
   		RETURN @rc
   		END
   	ELSE
   		BEGIN
   		RETURN @rc
   		END

GO
GRANT EXECUTE ON  [dbo].[bspRQQuoteInit] TO [public]
GO
