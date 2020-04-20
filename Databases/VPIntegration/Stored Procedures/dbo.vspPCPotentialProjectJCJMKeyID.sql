SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPCPotentialProjectJCJMKeyID]
  /***********************************************************
   * CREATED BY:		GP		01/20/2011
   * CODE REVIEWED BY:	DanSo	01/20/2011
   * MODIFIED BY:				
   *				
   * USAGE:
   * Used in PC Potential Projects to return the PM Project/JC Job KeyID
   *
   * INPUT PARAMETERS
   *   PotentialProjectKeyID
   *
   * OUTPUT PARAMETERS
   *   
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@PotentialProjectKeyID bigint, @ProjectKeyID bigint = null output)
  as
  set nocount on
  
  -- Get PM Project KeyID from bJCJM
  select @ProjectKeyID = KeyID from dbo.JCJM where PotentialProjectID = @PotentialProjectKeyID
 
 
 
GO
GRANT EXECUTE ON  [dbo].[vspPCPotentialProjectJCJMKeyID] TO [public]
GO
