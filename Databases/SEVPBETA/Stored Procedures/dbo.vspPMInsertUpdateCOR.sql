SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE proc [dbo].[vspPMInsertUpdateCOR]
CREATE proc [dbo].[vspPMInsertUpdateCOR]
/*************************************
* CREATED BY:	DAN SO	03/24/2011
* MODIFIED BY:	GP		05/05/2011 - TK-04860 Added @Details from PCO to insert of new COR
*				GP		06/28/2011 - TK-06479 Added execute stored proc to update COR totals
*
*	Insert or update COR with PCO information
*
*
* INPUT
*	@PMCo			- PM Compnay
*	@Contract		- Contract
*	@VendorGroup	- Vendor Group from PCO data
*	@CORState		- (N)ew or (E)xists
*	@Project		- Project
*	@PCOType		- PCOType
*	@PCO			- PCO
*	@PCODescription	- Description
*	
* OUTPUT
*	@CORKeyID	- COR KeyID used to launch and find correct COR record in form code
*	@msg		- Failure -> Error Message
*
**************************************/
   (@PMCo bCompany = NULL, @Contract bContract = NULL, @COR smallint = NULL,
    @VendorGroup bGroup = NULL, @CORState char(1) = NULL,
    @Project bProject = NULL, @PCOType bPCOType = NULL, @PCO bPCO = NULL,
    @PCODescription bItemDesc = NULL, @Details varchar(max) = NULL,
    @CORKeyID bigint output, @msg varchar(255) output)
      
	AS
	
	SET NOCOUNT ON 
	
	DECLARE	@rcode		int,
			@UpdateOK	bYN,
			@Successful	bYN
	
	
	------------------
	-- PRIME VALUES --
	------------------
	SET @rcode = 0
	SET @CORKeyID = 0
	SET @UpdateOK = 'N'
	SET @Successful = 'N'
	SET @msg = ''
	 
	 
	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @PMCo IS NULL
		BEGIN
			SET @msg = 'Missing PM Company!'
			SET @rcode = 1
			GOTO vspexit
		END
	
	IF @Contract IS NULL
		BEGIN
			SET @msg = 'Missing Contract!'
			SET @rcode = 1
			GOTO vspexit
		END
		
	IF @COR IS NULL
		BEGIN
			SET @msg = 'Missing COR value!'
			SET @rcode = 1
			GOTO vspexit
		END
		
	IF @VendorGroup IS NULL
		BEGIN
			SET @msg = 'Missing Vendor Group!'
			SET @rcode = 1
			GOTO vspexit
		END	
   
   	IF (@CORState IS NULL) OR (@CORState NOT IN ('N','E'))
		BEGIN
			SET @msg = 'Missing or Unknown COR State!'
			SET @rcode = 1
			GOTO vspexit
		END	
		
	--------------------------
	-- INSERT OR UPDATE COR --	
	--------------------------
	
	-- INSERT COR --
	IF @CORState = 'N'
		BEGIN
			-- DOES THE COR ALREADY EXIST --
			IF EXISTS (SELECT 1 FROM dbo.vPMChangeOrderRequest
						WHERE PMCo = @PMCo AND [Contract] = @Contract AND COR = @COR)
				BEGIN
					SET @msg = 'COR Already Exists!'
					SET @rcode = 1
					GOTO vspexit
				END
			ELSE
				BEGIN 	
					INSERT dbo.vPMChangeOrderRequest 
						(PMCo, [Contract], COR, ChangeInDaysOverride, VendorGroup, [Description], Details)
					VALUES
						(@PMCo, @Contract, @COR, 'N', @VendorGroup, @PCODescription, @Details)
				
					SET @CORKeyID = SCOPE_IDENTITY()
				
					-- CHECK FOR SUCCESSFUL INSERT
					IF @@ROWCOUNT = 0
						BEGIN
							SET @msg = 'Error creating new COR record!'
							SET @rcode = 1
							GOTO vspexit
						END
						
				END -- IF EXISTS
		END --IF @CORState = 'N'


	-- ADD TO EXISTING COR  --
	IF @CORState IN ('N','E') 
		BEGIN
		
			-- CHECK FOR ALL NEEDED PCO INFO --
			IF @Project IS NULL OR @PCOType IS NULL OR @PCO IS NULL
				BEGIN 
					SET @msg = 'Missing Data - cannot Add To an Existing COR record!'
					SET @rcode = 1
					GOTO vspexit
				END
			ELSE
				BEGIN
					-- DOES THE PCO INFO ALREADY EXIST --
					IF EXISTS (SELECT 1 FROM dbo.vPMChangeOrderRequestPCO 
								WHERE PMCo = @PMCo AND [Contract] = @Contract AND COR = @COR 
								  AND Project = @Project AND PCOType = @PCOType AND PCO = @PCO)
						BEGIN
							SET @msg = 'PCO Information already exits for COR: ' + CAST(@COR AS VARCHAR(10))
							SET @rcode = 1
							GOTO vspexit
						END
					ELSE
						BEGIN 
							-- INSERT PCO INFO --
							INSERT	dbo.vPMChangeOrderRequestPCO
								(PMCo, [Contract], COR, Project, PCOType, PCO)
							VALUES
								(@PMCo, @Contract, @COR, @Project, @PCOType, @PCO)
									
							-- CHECK FOR SUCCESSFUL UPDATE --
							IF @@ROWCOUNT = 0
								BEGIN
									SET @msg = 'Error Adding To an Existing COR record!'
									SET @rcode = 1
									GOTO vspexit
								END
								
							-- GET KeyID OF PARENT RECORD --
							SELECT	@CORKeyID = KeyID 
							  FROM	dbo.vPMChangeOrderRequest with (NOLOCK)
							 WHERE	PMCo = @PMCo AND [Contract] = @Contract AND COR = @COR
								
								
						END -- IF EXISTS ..
				END -- IF @Project IS ....
		END -- IF @CORState IN ('N','E')
   
   
   --Update totals on COR
   exec @rcode = dbo.vspPMChangeOrderRequestTotalUpdate @PMCo, @Contract, @COR, 'Y', @msg output

 
	vspexit:
   		RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMInsertUpdateCOR] TO [public]
GO
