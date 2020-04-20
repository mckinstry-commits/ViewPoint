SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPCPotentialProjectDesc]
  /***********************************************************
   * CREATED BY:	GP	08/04/2009
   * MODIFIED BY:	JVH	2/3/2010
   *				
   * USAGE:
   * Used in PM Potential Projects to return the a description to the key field and in 
   * PC Bid Package to validate a valid Potential Project
   *
   * INPUT PARAMETERS
   *   JCCo   
   *   PotentialProject
   *   ExistingPotentialProjectRequired - Used to require a valid potential project when
   *		used in PC Bid Package
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Department if found.
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@JCCo bCompany, @PotentialProject varchar(20), @UniqueAttchID uniqueidentifier output, @ProjectHasBidders bit OUTPUT, @msg varchar(255) output)
  as
  set nocount on

	--Get Description
	select @msg = Description, @UniqueAttchID = lower(UniqueAttchID) 
	from dbo.PCPotentialWork with (nolock)
	where JCCo = @JCCo and PotentialProject = @PotentialProject
	
	-- Check for existence
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Potential project not on file!'
		RETURN 1
	END

	SELECT @ProjectHasBidders = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
	FROM PCBidPackageBidList
	WHERE JCCo = @JCCo AND PotentialProject = @PotentialProject

	bspexit:
		RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPCPotentialProjectDesc] TO [public]
GO
