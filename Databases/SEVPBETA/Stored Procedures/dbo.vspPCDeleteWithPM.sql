SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPCDeleteWithPM    Script Date: 11/30/2010 13:52:02 ******/
   
   CREATE  proc [dbo].[vspPCDeleteWithPM]
    	(@JCCo bCompany, @PotentialProject VARCHAR(20), @msg varchar(255) output)
    as
    set nocount on
    /***********************************************************
     * CREATED BY:		JG 11/30/2010
     * MODIFIED By :	JG 01/06/2011 - Modified for refactoring the JCJM/PCPotentialWork tables.
     *
     * USAGE:
     *	Removes the PC Potential Project and the PM Project.
     *
     * INPUT PARAMETERS
     *  JCCo					Company of the Project
	 *	PotentialProject		Potential Project tied to a Project to remove.
     *
     * OUTPUT PARAMETERS
     *  @msg		Error message
	 *
     * RETURN VALUE
     *   0			Success
     *   1			Failure
     *****************************************************/
    declare @rcode int, @JCJMKeyID bigint
   
    set @rcode = 0

	----------------
	-- Validation --
	----------------
    if @JCCo is null
    begin
    	select @msg = 'Missing Company!', @rcode = 1
       	goto vspexit
    end
	if @PotentialProject is null
    begin
    	select @msg = 'Missing Potential Project!', @rcode = 1
       	goto vspexit
    end
    
	-- Get JCJM Key ID
    select @JCJMKeyID = j.KeyID 
    from dbo.bJCJM j 
    join dbo.vPCPotentialWork p on p.KeyID = j.PotentialProjectID 
    where p.JCCo = @JCCo AND p.PotentialProject = @PotentialProject
	
	begin try
		begin transaction
	
		-- Delete the PM Record (delete trigger handles clearing out all related records)	
		DELETE bJCJM
		FROM bJCJM 
		WHERE KeyID = @JCJMKeyID
		
		-- Delete the PC Record (delete trigger handles clearing out all related records)	
		DELETE vPCPotentialWork
		FROM vPCPotentialWork
		WHERE JCCo = @JCCo
		AND PotentialProject = @PotentialProject
		
		commit transaction
	end try
	
	begin catch
		select @msg = error_message(), @rcode = 1
		rollback transaction
		goto vspexit
	end catch
	
    vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCDeleteWithPM] TO [public]
GO
