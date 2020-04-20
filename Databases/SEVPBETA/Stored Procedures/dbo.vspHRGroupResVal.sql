SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE procedure [dbo].[vspHRGroupResVal]
CREATE procedure [dbo].[vspHRGroupResVal]
/************************************************************************
* CREATED:	Dan Sochacki 01/25/2008     
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*   Validate Resources within an Approval Group OR under a specific Approver.
*    
*           
* Notes about Stored Procedure
* 
* Inputs
*	HRCo		- Company
*	AppRes		- ApproversResource Number
*	AppGroup	- Approver Group Number
*	ReqRes		- Requester Resource Number
*
* Outputs
*	rcode		- (0)Success - (1)Failure
*	errmsg		- Error Message
*
*************************************************************************/

    (@HRCo bCompany = NULL, @AppRes bHRRef = NULL,
	 @AppGroup bGroup = NULL, @ReqRes varchar(15) = NULL, @ReqResOut bHRRef output, 
	 @msg varchar(80) = '' output)

AS
SET NOCOUNT ON

    DECLARE	@position	varchar(10),
			@TempResOut	varchar(10),
			@TempMsg	varchar(75),
			@rcode		int

    SET @rcode = 0

	-----------------------------------
	-- CHECK FOR INCOMING PARAMETERS --
	-----------------------------------
	IF (@HRCo IS NULL) OR (@AppRes IS NULL) OR (@ReqRes IS NULL)
		BEGIN
			SET @msg = 'Missing input parameter(s).'
			SET @rcode = 1
			GOTO vspexit
		END

	----------------------------------------------------
	-- CALL TO GET HRREF/NAME BY EITHER HRREF OR NAME --
	----------------------------------------------------
	EXECUTE @rcode = bspHRResVal @HRCo, @ReqRes, @TempResOut output, @position output, @TempMsg output

	-----------------------------------------------
	-- CHECK FOR A VALID RETURN FROM bspHRResVal --
	-----------------------------------------------
	IF @rcode = 0
		BEGIN

			-----------------------------------------------
			-- CHECK TO MAKE SURE THE RESOURCE EXISTS IN --
			-- A SPECIFIC APPROVER AND/OR IN AN APPROVAL --
			-- GROUP (if Approval Group is supplied)     --
			----------------------------------------------- 
			IF EXISTS (SELECT *
					      FROM HRRM h WITH (NOLOCK)
						  JOIN HRAG g WITH (NOLOCK)
						    ON h.HRCo = g.HRCo AND h.PTOAppvrGrp = g.PTOAppvrGrp
						 WHERE h.HRCo = @HRCo
						   AND h.HRRef = @TempResOut
						   AND (g.PriAppvr = @AppRes OR g.SecAppvr = @AppRes)
						   AND (g.PTOAppvrGrp = @AppGroup OR @AppGroup IS NULL))

				BEGIN
					---------------------
					-- RESOURCE EXISTS --	
					---------------------
					SET @ReqResOut = @TempResOut
					SET @msg = @TempMsg
				END

			ELSE
				BEGIN
					-----------------------------
					-- RESOURCE DOES NOT EXIST --
					-----------------------------
					SET @ReqResOut = @TempResOut
					SET @msg = 'Not a valid Resource within Group OR Approver!'
					--SET @rcode = 1
				END
		END

	ELSE
		BEGIN
			-------------------------------
			-- COULD NOT FIND A RESOURCE --
			-------------------------------
			SET @ReqResOut = @TempResOut
			SET @msg = @TempMsg
		END


vspexit:

     RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRGroupResVal] TO [public]
GO
