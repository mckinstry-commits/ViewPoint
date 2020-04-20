SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspVAPurgeSecurityEntries]
/****************************************************************************
* Created: 	DANF 04/20/2004
* Modified: AL 3/19/07 - Ported to V6. changed table names to reflect new tables
*			AL 4/26/07 - Added If statement prior to exec to ensure the proper columns exist
*			GG 06/18/07 - rewritten to delete vDDDS entries for specific datatype, qualifier, and instance
*
* Used by VA Data Security Purge to remove unused vDDDS entries.  Qualifier and Instance no
* longer exist in any linked table for the Datatype and can be deleted from vDDDS. 
*
* Inputs:
*	@datatype			Datatype
*	@qualifier			Qualifier (Co#)
*	@instance			Datatype value
*
* Outputs:
*	@msg				Error message
*
* Return code:
*	0 = success, 1 = error
*
**************************************************/

	(@datatype varchar(30) = null, @qualifier tinyint = null, @instance varchar(30) = null, @msg varchar(255) output)
 
AS

SET NOCOUNT ON

declare @rcode int
select @rcode = 0

-- delete any data security entries for the datatype, qualifier, and instance
delete dbo.vDDDS 
where Datatype = @datatype and Qualifier = @qualifier and Instance = @instance 

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVAPurgeSecurityEntries] TO [public]
GO
