SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPPDRecordCheck]
/***********************************************************
 * CREATED BY:  	DRC  01/14/08  - for APPayHistory recode
 * MODIFIED By :
 *
 * USAGE:
 *
 * INPUT PARAMETERS
 *		APCo, 
 *		CMCo, 
 *		CMAcct, 
 *		PayMethod, 
 *		CMRef, 
 *		CMRefSeq, 
 *		EFTSeq
 *
 * RETURN VALUE
 *   Record count from APPD filtered from Input parameters.
 *   
 *****************************************************/

(@apco bCompany = null, @cmco bCompany = null, @cmacct bCMAcct = null, @paymethod char(1) = null,
	@cmref bCMRef = null, @cmrefseq tinyint = null, @eftseq smallint = null, @msg varchar(255) output)

as
set nocount on

declare @rcode int

select @rcode = 1, @msg = 'No AP Payment History items set up for this AP Payment History header record.'

if exists(select 1
			from bAPPD with (nolock)
			where APCo = @apco 
				AND CMCo = @cmco
				AND CMAcct = @cmacct
				AND PayMethod = @paymethod
				AND CMRef = @cmref 
				AND CMRefSeq = @cmrefseq
				AND EFTSeq = @eftseq)
	BEGIN
		select @rcode = 0, @msg = ''
	END


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPPDRecordCheck] TO [public]
GO
