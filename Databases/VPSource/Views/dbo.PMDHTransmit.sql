SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Document History for transmittals
 *
 *****************************************/
 
CREATE  view [dbo].[PMDHTransmit] as
select a.Document as [Transmittal], a.*
From dbo.PMDH a where a.DocCategory = 'TRANSMIT'

GO
GRANT SELECT ON  [dbo].[PMDHTransmit] TO [public]
GRANT INSERT ON  [dbo].[PMDHTransmit] TO [public]
GRANT DELETE ON  [dbo].[PMDHTransmit] TO [public]
GRANT UPDATE ON  [dbo].[PMDHTransmit] TO [public]
GO
