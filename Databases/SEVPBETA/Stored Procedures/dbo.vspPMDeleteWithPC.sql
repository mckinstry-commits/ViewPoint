SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDeleteWithPC    Script Date: 11/29/2010 16:36:28 ******/
   
   CREATE  proc [dbo].[vspPMDeleteWithPC]
    	(@JCCo bCompany, @Project bJob, @msg varchar(255) output)
    as
    set nocount on
    /***********************************************************
     * CREATED BY:		JG 11/29/2010
     * MODIFIED By :	JG 01/06/2011 - TFS# 1662 - Updated delete without PC for refactored JCJM.
     *
     * USAGE:
     *	"Removes" the PM Project by deleting all related records.
     *
     * INPUT PARAMETERS
     *  JCCo		Company of the Project
	 *	Project		Project tied to a Potential Project to remove.
     *
     * OUTPUT PARAMETERS
     *  @msg		Error message
	 *
     * RETURN VALUE
     *   0			Success
     *   1			Failure
     *****************************************************/
    declare @rcode int, @PotentialProjectID bigint
   
    set @rcode = 0

	----------------
	-- Validation --
	----------------
    if @JCCo is null
    begin
    	select @msg = 'Missing Company!', @rcode = 1
       	goto vspexit
    end
	if @Project is null
    begin
    	select @msg = 'Missing Project!', @rcode = 1
       	goto vspexit
    end

	-- Check to make sure Project is related to a Potential Project.
	if not exists(select top 1 1 from bJCJM with(nolock) where JCCo = @JCCo AND Job = @Project AND PotentialProjectID IS NOT NULL)
	begin
		select @msg = 'Related Potential Project doesn''t exist.', @rcode = 1
		goto vspexit
	end
	
	begin try
		begin transaction
	
		-- Get the ID from PM
		SELECT @PotentialProjectID = PotentialProjectID
		FROM bJCJM
		WHERE JCCo = @JCCo
		AND Job = @Project
		
		-- Delete the PM Record (delete trigger handles clearing out all related records)	
		DELETE bJCJM
		FROM bJCJM 
		WHERE JCCo = @JCCo
		AND Job = @Project
		
		-- Delete the PC Record
		DELETE vPCPotentialWork
		FROM vPCPotentialWork
		WHERE KeyID = @PotentialProjectID
		
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
GRANT EXECUTE ON  [dbo].[vspPMDeleteWithPC] TO [public]
GO
