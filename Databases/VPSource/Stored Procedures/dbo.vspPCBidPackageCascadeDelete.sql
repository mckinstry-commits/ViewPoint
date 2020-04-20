SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPCBidPackageCascadeDelete    Script Date: 12/01/2010 10:43:00 ******/
   
   CREATE  proc [dbo].[vspPCBidPackageCascadeDelete]
    	(@JCCo bCompany, @PotentialProject VARCHAR(20), @msg varchar(255) output)
    as
    set nocount on
    /***********************************************************
     * CREATED BY:		JG 12/1/2010
     * MODIFIED By :
     *
     * USAGE:
     *	Removes the BidPackage records for cascade delete.
     *
     * INPUT PARAMETERS
     *  JCCo					Company of the Project
	 *	PotentialProject		Potential Project to a remove bid packages.
     *
     * OUTPUT PARAMETERS
     *  @msg		Error message
	 *
     * RETURN VALUE
     *   0			Success
     *   1			Failure
     *****************************************************/
    declare @rcode int
   
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
    
	-------------------------------
	-- Delete BidPackage Records --
	-------------------------------
	
	begin try
		begin transaction

		delete vPCBidPackageScopes where JCCo=@JCCo and PotentialProject=@PotentialProject
        delete vPCBidPackageBidList where JCCo=@JCCo and PotentialProject=@PotentialProject
        delete vPCBidPackageScopeNotes where JCCo=@JCCo and PotentialProject=@PotentialProject
        delete vPCBidPackage where JCCo=@JCCo and PotentialProject=@PotentialProject

		commit transaction
	end try

	begin catch
		select @msg = error_message(), @rcode = 1
		rollback transaction
	end catch
	
    vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCBidPackageCascadeDelete] TO [public]
GO
