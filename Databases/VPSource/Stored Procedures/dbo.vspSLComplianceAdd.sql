SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspSLComplianceAdd    Script Date: 8/28/99 9:36:37 AM ******/
	CREATE proc [dbo].[vspSLComplianceAdd]          
	/***********************************************************
	* CREATED BY:	DC 2/3/09
	* MODIFIED By:  GF 06/26/2010 - issue #135318 expanded SL to varchar(30)
	*				GF 11/16/2010 - issue #141535 do not copy supplier
	*
	*			
	* USAGE:
	* Called by the SL Compliance Initialize form to add a compliance code to a range
	* of Subcontracts.
	*
	*
	* INPUT PARAMETERS
	*	@slco			SL Co#
	*	@compcode		Compliance Code
	*	@beginJCCo		Beginning JC Co#
	*	@endJCCo		Ending JC Co#
	*	@beginjob		Beginning Job
	*	@endjob			Ending Job
	*	@beginSL		Beginning Subcontract
	*	@endSL			Ending Subcontract
	*	@includepending Apply compliance codes to pending subcontracts.
	*	@vendor			Vendor
	*	@vendorgrp		Vendor Group
	*
	*
	* OUTPUT PARAMETERS
	*	@numrows	# of Subcontracts updated
	*  	@msg      	error message if error occurs
	*
	* RETURN VALUE
	*   	0        	success
	*   	1         	Failure
	*****************************************************/
	(@slco bCompany, @compcode bCompCode, @beginJCCo bCompany, @endJCCo bCompany, @beginjob bJob,
	@endjob bJob, @beginSL VARCHAR(30), @endSL VARCHAR(30), @includepending char(1),@vendor bVendor,@vendorgrp bGroup,
	@numrows int output, @msg varchar(255) output)
		
	as
	set nocount on
	
	DECLARE @rcode int, @seq int, @sl VARCHAR(30), @nextseq int, @verify bYN, @desc bItemDesc
	
	DECLARE @iNextRowId int,
            @iCurrentRowId int,
            @iLoopControl int
            
	IF @endSL is null SELECT @endSL = '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'  --DC #135813
	IF @beginSL is null SELECT @beginSL = ''
	IF @endJCCo is null SELECT @endJCCo = 255
	IF @beginJCCo is null SELECT @beginJCCo = 0
	IF @endjob is null SELECT @endjob = '~~~~~~~~~'
	IF @beginjob is null SELECT @beginjob = ''
		
	SELECT @iLoopControl = 1, @rcode = 0, @numrows = 0	 
				
	IF not exists(SELECT 1 FROM bHQCP WHERE CompCode = @compcode)
   		BEGIN
   		SELECT @msg = 'Not a valid compliance code.', @rcode = 1
   		GOTO vspexit
   		END
   	ELSE
   		BEGIN
   		SELECT @verify = Verify, @desc = Description FROM bHQCP WHERE CompCode = @compcode
   		END
   		
   	--Table variable to hold records to be inserted into bSLCT
   	DECLARE @SLCT_temp TABLE (keyid bigint,
   		slco tinyint, 
   		sl VARCHAR(30),  --DC #135813
   		compcode varchar(10),
   		seq int,
   		description VARCHAR(60),  --DC #135813
   		verify char(1),
   		vendor int,
   		vendorgrp tinyint)   		   		
   		
   	IF @includepending = 'Y' 
   		BEGIN
		insert into @SLCT_temp(keyid, slco, sl, compcode, seq, description, verify, vendor, vendorgrp)
		----#141535
		SELECT KeyID, @slco, SL, @compcode, 1, @desc, @verify, @vendor, VendorGroup
		FROM SLHD	
		WHERE SLCo = @slco 
			and SL >= @beginSL and SL<=@endSL
			and JCCo>=@beginJCCo and JCCo<=@endJCCo
			and Job >=@beginjob and Job<=@endjob
			and (Status = 0 or Status = 3)  
			and Vendor = isnull(@vendor,Vendor) and VendorGroup = isnull(@vendorgrp,VendorGroup)
		select @numrows = @@rowcount
				
   		END
   	ELSE
   		BEGIN
		insert into @SLCT_temp(keyid, slco, sl, compcode, seq, description, verify,vendor,vendorgrp)
		----#141535
		SELECT KeyID, @slco, SL, @compcode, 1, @desc, @verify, @vendor, VendorGroup
		FROM SLHD	
		WHERE SLCo = @slco 
			and SL >= @beginSL and SL<=@endSL
			and JCCo>=@beginJCCo and JCCo<=@endJCCo
			and Job >=@beginjob and Job<=@endjob
			and Status = 0	
			and Vendor = isnull(@vendor,Vendor) and VendorGroup = isnull(@vendorgrp,VendorGroup)
		select @numrows = @@rowcount				 
		
   		END
   		
	SELECT @iNextRowId = MIN(keyid)
	FROM   @SLCT_temp
	
	IF ISNULL(@iNextRowId,0) = 0
		BEGIN
        SELECT 'No matching data found in SLHD!'
        GOTO vspexit
		END	
		
	SELECT @iCurrentRowId = keyid,
			@sl = sl	
	FROM @SLCT_temp
	WHERE keyid = @iNextRowId
	
	IF exists (SELECT 1 FROM bSLCT WHERE SLCo=@slco and SL=@sl and CompCode=@compcode)
		BEGIN		
		SELECT @nextseq = isnull(max(Seq),0)+1 
		FROM bSLCT 
		WHERE SLCo=@slco and SL=@sl and CompCode=@compcode
		
		UPDATE @SLCT_temp
		SET seq = @nextseq
		WHERE keyid = @iNextRowId 		
		END	
	
	-- start the main processing loop.
	WHILE @iLoopControl = 1
		BEGIN						
		-- Reset looping variables.           
		SELECT   @iNextRowId = NULL
		          
        -- get the next iRowId
		SELECT @iNextRowId = MIN(keyid)
		FROM @SLCT_temp
        WHERE keyid > @iCurrentRowId

		-- did we get a valid next row id?
		IF ISNULL(@iNextRowId,0) = 0
			BEGIN
			BREAK
			END						

		-- get the next row.
		SELECT @iCurrentRowId = keyid,
				@sl = sl
		FROM @SLCT_temp
		WHERE keyid = @iNextRowId   
		
		IF exists (SELECT 1 FROM bSLCT WHERE SLCo=@slco and SL=@sl and CompCode=@compcode)
			BEGIN
			SELECT @nextseq = isnull(max(Seq),0)+1 FROM bSLCT WHERE SLCo=@slco and SL=@sl and CompCode=@compcode
			UPDATE @SLCT_temp
			SET seq = @nextseq
			WHERE keyid = @iNextRowId 		
			END			        
		END
	
	
	--insert values from @SLCT_temp to bSLCT
	INSERT INTO bSLCT(SLCo, SL, CompCode, Seq, Description, Verify, Vendor, VendorGroup)
	SELECT slco, sl, compcode, seq, description, verify, vendor, vendorgrp
	FROM @SLCT_temp
	
     
	vspexit:   
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLComplianceAdd] TO [public]
GO
