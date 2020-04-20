SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************************************
    * Created By:	Dan So 03/07/08 - Issue #25550 - Copied and modified from bspINLocMatlVal
    * Modified By:  Dan So 04/22/09 - Issue #133340 - Validate Component location (@CompMatlLoc)
	*				GF 02/12/2013 TFS-40695 moved validation for duplicate record to after INMT info
    *
	*
    * Pass:
    *	@INCo           IN Company
    *   @MatlGrp        Material Group
    *   @FinMatlLoc		Finished Material Location
	*	@FinMatl		Finished Material
    *   @CompMatl       Component Material
    *   @activeopt      Active option - Y = must be active, N = may be inactive
    *   @prodmatlYN     Y- only if it is a finished i.e produnction material used in Production Posting program
    *                   and in all other programs it will be N
    *                   (this parameter is hardcoded from wherever the procedure is called)
    *
    * Success returns:
    *	0
    *   UM            Std Unit of Measure
    *   WtConv        Weight Conversion from INMT
    *   Desc		  Description from HQMT
    *   
    * Error returns:
    *	1 and error message
************************************************************************************/
--CREATE PROCEDURE [dbo].[vspINBoMMatlLocVal]
CREATE  PROCEDURE [dbo].[vspINBoMMatlLocVal]

   (@INCo			bCompany = null,
    @MatlGrp		bGroup = null,
    @FinMatlLoc		bLoc = null,
	@FinMatl		bMatl = null,
	@CompMatlLoc	bLoc = null,
	@CompMatl		bMatl = null,
    @activeopt		bYN = null,
	@prodmatlYN		bYN	= null,
    @um				bUM	= null output,
    @wtconv			bUnits = null output,
	@msg			varchar(255) = null output)


AS
SET NOCOUNT ON

   
	DECLARE @DupComLoc	bLoc,
			@active		bYN, 
			@locgroup	bGroup, 
			@validcnt	int, 
			@stocked	bYN, 
   			@category	varchar(10),
			@rcode		int
   
   
	------------------
	-- SET DEFAULTS --
	------------------
	SET @rcode = 0
    
	-------------------------------
	-- CHECK INCOMING PARAMETERS --
	-------------------------------
	IF @INCo IS NULL
		BEGIN
			SELECT @msg = 'Missing IN Company', @rcode=1
			GOTO vspexit
		END
    
	IF @MatlGrp IS NULL
        BEGIN
			SELECT @msg = 'Missing Material Group', @rcode=1
			GOTO vspexit
        END

	IF @FinMatlLoc IS NULL
		BEGIN
			SELECT @msg = 'Missing Finished Material Location', @rcode=1
			GOTO vspexit
        END
    
	IF @FinMatl IS NULL
        BEGIN
			SELECT @msg = 'Missing Finished Material', @rcode=1
			GOTO vspexit
        END
    
	IF @CompMatlLoc IS NULL
		BEGIN
			SELECT @msg = 'Missing Component Material Location', @rcode=1
			GOTO vspexit
        END

	IF @CompMatl IS NULL
        BEGIN
			SELECT @msg = 'Missing Component Material', @rcode=1
			GOTO vspexit
        END
   
	-----------------------
	-- GET LOCATION DATA -- 
	-----------------------
	SELECT @locgroup = LocGroup
	  FROM dbo.INLM WITH (NOLOCK)
     WHERE INCo = @INCo 
       AND Loc = @FinMatlLoc

	-----------------------------------------------------
	-- GET CATEGORY AND COMPONENT MATERIAL DESCRIPTION --
	-----------------------------------------------------
	SELECT	@msg = Description,  
			@um = StdUM, 
   			@stocked = Stocked
      FROM  dbo.HQMT WITH (NOLOCK)
     WHERE  MatlGroup = @MatlGrp 
	   AND  Material=@CompMatl

	IF  @@ROWCOUNT = 0
		BEGIN
			SELECT @msg = 'Component Material not set up in HQ Materials', @rcode=1
			GOTO vspexit
        END
    
   if @stocked = 'N'
        begin
        select @msg = 'Must be a Stocked Material.', @rcode = 1
        goto vspexit
        end
    
	-----------------------------------------------
	-- VALIDATE COMPONENT MATERIAL IN INMT TABLE --
	-----------------------------------------------
	SELECT	@wtconv = i.WeightConv, 
			@active = i.Active
	  FROM	dbo.INMT i WITH (NOLOCK)
	 WHERE  i.INCo = @INCo 
	   AND	i.Loc = @CompMatlLoc	-- ISSUE: #133340 (@FinMatl)
	   AND  i.MatlGroup=@MatlGrp 
	   AND  i.Material=@CompMatl 

	IF @@ROWCOUNT = 0
		BEGIN
			SELECT @msg = 'Component Material not set up in IN Location Materials', @rcode=1
			GOTO vspexit
        END

	IF (@activeopt = 'Y') AND (@active = 'N')
        BEGIN
			SELECT @msg = 'Must be an active Material.', @rcode = 1
			GOTO vspexit
        END
    
	------------------
	-- ISSUE #25550 --
	-------------------------------------------------------
	-- CAN NOT HAVE DUPLICATE MATERIALS AT SAME LOCATION --
	-------------------------------------------------------
	----TFS-40695
	SELECT @DupComLoc = CompLoc
	  FROM bINBO 
     WHERE INCo = @INCo 
       AND MatlGroup = @MatlGrp
       AND Loc = @FinMatlLoc 
	   AND FinMatl = @FinMatl
       AND CompMatl = @CompMatl

	IF @DupComLoc IS NOT NULL
		BEGIN
			SELECT @msg = 'Duplicate Component Material already exists for Component Location ' + CAST(@DupComLoc AS VARCHAR(10)), @rcode = 1
			GOTO vspexit
		END
        
	---------------------------------------------------------------------------------------------------
    -- THIS CHECK IS DONE ONLY IF IT IS A PRODCUTION MATERIAL USED IN THE PRODUCTION POSTING PROGRAM --
	---------------------------------------------------------------------------------------------------
	IF @prodmatlYN = 'Y'
   		BEGIN
			-----------------------------------------------------------------
			-- CHECK WHETHER BILL OF MATERIALS WAS SETUP FOR THIS MATERIAL --
			-----------------------------------------------------------------
			SELECT @validcnt = COUNT(*) 
			  FROM dbo.INBM WITH (NOLOCK)
			 WHERE INCo = @INCo 
			   AND LocGroup = @locgroup 
			   AND MatlGroup = @MatlGrp 
			   AND FinMatl = @FinMatl

			IF @validcnt = 0
				BEGIN
     				SELECT @validcnt = COUNT(*) 
					  FROM dbo.INBO WITH (NOLOCK)
					 WHERE INCo = @INCo 
					   AND Loc = @FinMatlLoc 
                       AND MatlGroup = @MatlGrp 
					   AND FinMatl = @FinMatl

					IF @validcnt=0
           				BEGIN
							SELECT @msg = 'Finished Good not setup with a Bill of Materials', @rcode=1
							GOTO vspexit
						END
				END
		END


vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINBoMMatlLocVal] TO [public]
GO
